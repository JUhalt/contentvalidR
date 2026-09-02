# Internal helpers for the stable workflow-object API.

.workflow_status_levels <- c("Supported", "Review", "Insufficient data", "Descriptive only")

.workflow_status_from_recommendation <- function(recommendation) {
  rec <- as.character(recommendation)
  out <- rep(NA_character_, length(rec))

  out[rec %in% c("Retain", "Strong support", "Support", "Supported", "Target favored")] <- "Supported"
  out[rec %in% c("Review", "Tie / review")] <- "Review"
  out[rec %in% c("Insufficient data", "Insufficient panel")] <- "Insufficient data"
  out[rec %in% c("Descriptive only", "Target described")] <- "Descriptive only"

  # Compatibility fallback for older saved workflow objects with closely related
  # recommendation wording.
  missing <- is.na(out) & !is.na(rec)
  out[missing & grepl("insufficient", rec, ignore.case = TRUE)] <- "Insufficient data"
  out[missing & grepl("review", rec, ignore.case = TRUE)] <- "Review"
  out[missing & grepl("support|retain|favou?r", rec, ignore.case = TRUE)] <- "Supported"
  out[missing & grepl("descriptive|described", rec, ignore.case = TRUE)] <- "Descriptive only"
  out
}

.with_workflow_status <- function(results) {
  if (!is.data.frame(results)) {
    stop("Workflow `results` must be a data.frame.", call. = FALSE)
  }
  if (!"status" %in% names(results)) {
    if (!"recommendation" %in% names(results)) {
      stop("Workflow results must contain a `recommendation` or `status` column.", call. = FALSE)
    }
    results$status <- .workflow_status_from_recommendation(results$recommendation)
  }
  bad <- !is.na(results$status) & !results$status %in% .workflow_status_levels
  if (any(bad)) {
    stop("Workflow `status` values must be one of: ",
         paste(.workflow_status_levels, collapse = ", "), ".", call. = FALSE)
  }
  results
}

.new_contentvalid_workflow <- function(subclass,
                                       workflow,
                                       results,
                                       scale_summary,
                                       settings,
                                       design,
                                       details = list(),
                                       mode = NULL,
                                       legacy = list()) {
  results <- .with_workflow_status(results)
  if (!is.data.frame(scale_summary)) {
    stop("Workflow `scale_summary` must be a data.frame.", call. = FALSE)
  }
  if (!is.list(settings) || !is.list(design)) {
    stop("Workflow `settings` and `design` must be lists.", call. = FALSE)
  }
  if (is.null(details)) details <- list()
  if (!is.list(details)) stop("Workflow `details` must be a list.", call. = FALSE)

  out <- list(workflow = workflow)
  if (!is.null(mode)) out$mode <- mode
  out$results <- results
  out$scale_summary <- scale_summary
  out$settings <- settings
  out$design <- design
  out$details <- details

  if (length(legacy)) {
    for (nm in names(legacy)) {
      if (!nm %in% names(out)) out[[nm]] <- legacy[[nm]]
    }
  }

  class(out) <- c(subclass, "contentvalid_workflow")
  out
}

.workflow_name <- function(x) {
  if (!is.null(x$workflow)) return(as.character(x$workflow)[1])
  if (inherits(x, "contentvalid_sort")) return("item-sort")
  if (inherits(x, "contentvalid_rating")) return("construct-rating")
  if (inherits(x, "contentvalid_expert")) return("expert-panel")
  NA_character_
}

.workflow_scale_summary <- function(x) {
  if (!is.null(x$scale_summary)) return(x$scale_summary)
  if (!is.null(x$scale)) return(x$scale) # pre-v0.0.6 expert objects
  data.frame()
}


.workflow_design <- function(x) {
  if (is.list(x$design)) return(x$design)

  # Compatibility for expert objects created before v0.0.6, which did not
  # include a top-level design component.
  if (inherits(x, "contentvalid_expert")) {
    r <- x$results
    sc <- .workflow_scale_summary(x)
    mode <- if (is.null(x$mode)) NA_character_ else x$mode
    if (identical(mode, "relevance") && nrow(sc)) {
      return(list(
        type = "expert-panel relevance",
        n_items = sc$n_items[1],
        n_judges = NA_integer_,
        n_judges_min = sc$n_experts_min[1],
        n_judges_max = sc$n_experts_max[1],
        n_missing = NA_integer_
      ))
    }
    if (identical(mode, "essentiality")) {
      return(list(
        type = "expert-panel essentiality",
        n_items = nrow(r),
        n_judges = if (nrow(r) && length(unique(r$N)) == 1L) unique(r$N) else NA_integer_,
        n_judges_min = if (nrow(r)) min(r$N) else 0L,
        n_judges_max = if (nrow(r)) max(r$N) else 0L,
        n_missing = NA_integer_
      ))
    }
    cells <- if (is.list(x$details)) x$details$cells else NULL
    return(list(
      type = "expert-panel congruence",
      n_items = if ("item" %in% names(r)) length(unique(r$item)) else nrow(r),
      n_judges = NA_integer_,
      n_judges_min = if (is.data.frame(cells) && nrow(cells)) min(cells$n_judges) else NA_integer_,
      n_judges_max = if (is.data.frame(cells) && nrow(cells)) max(cells$n_judges) else NA_integer_,
      n_missing = if (is.data.frame(cells)) sum(cells$n_missing) else NA_integer_,
      n_objectives = if (is.data.frame(cells)) length(unique(cells$objective)) else NA_integer_
    ))
  }

  list()
}

.workflow_summary_core <- function(object) {
  results <- .with_workflow_status(object$results)
  design <- .workflow_design(object)
  n_items <- design$n_items
  if (is.null(n_items)) {
    n_items <- if ("item" %in% names(results)) length(unique(results$item)) else nrow(results)
  }

  status <- results$status
  reviewed <- results[status %in% c("Review", "Insufficient data"), , drop = FALSE]

  list(
    workflow = .workflow_name(object),
    n_items = as.integer(n_items),
    n_results = nrow(results),
    n_supported = sum(status == "Supported", na.rm = TRUE),
    n_review = sum(status == "Review", na.rm = TRUE),
    n_insufficient = sum(status == "Insufficient data", na.rm = TRUE),
    n_descriptive = sum(status == "Descriptive only", na.rm = TRUE),
    scale_summary = .workflow_scale_summary(object),
    reviewed_items = reviewed,
    settings = object$settings,
    design = design
  )
}

.validate_digits <- function(digits) {
  if (!is.numeric(digits) || length(digits) != 1L || !is.finite(digits) ||
      digits < 0 || digits != floor(digits)) {
    stop("`digits` must be one nonnegative integer.", call. = FALSE)
  }
  invisible(as.integer(digits))
}

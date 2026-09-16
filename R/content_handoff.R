#' Carry content-validity decisions into empirical validation
#'
#' @description
#' Packages the item decisions from a finished content-validity workflow so they
#' can be carried into an empirical scale-development workflow without retyping
#' item names or losing the record of why each item was kept.
#'
#' The result holds three things: the item names that survived content review,
#' a per-item evidence table, and the provenance of the analysis that produced
#' them. It is plain data, so a downstream package can read it without
#' contentvalidR being installed.
#'
#' @details
#' Item-level workflows are accepted: [sort_validity()], [rating_validity()],
#' and [expert_validity()]. [judge_validity()] and [domain_validity()] are
#' refused, because their rows are judges and blueprint cells rather than items,
#' so there is no item set to carry forward.
#'
#' Items that do not meet `keep` are not dropped from the record. They stay in
#' `item_evidence` with `carried = FALSE`, so a reader can see what was held
#' back and why. Review is not deletion.
#'
#' In congruence mode without a target mapping, `expert_validity()` returns one
#' row per item-objective cell, so an item can appear in `item_evidence` more
#' than once. `items` is always unique.
#'
#' @section What a handoff does and does not establish:
#' Surviving content review is evidence about relevance, representation, and
#' expert judgment. It does not establish that an item will behave well
#' empirically. An item can be clearly relevant and still correlate poorly with
#' its construct or load on an unintended factor. That is what the downstream
#' empirical analysis tests, which is why the item set travels with its
#' evidence rather than as a bare list of names.
#'
#' @param fit A fitted `contentvalid_sort`, `contentvalid_rating`, or
#'   `contentvalid_expert` object.
#' @param keep Statuses that travel forward, defaulting to `"Supported"`. Any of
#'   `"Supported"`, `"Review"`, `"Insufficient data"`, or `"Descriptive only"`.
#'
#' @return An object of class `contentvalid_handoff`: a list with
#'   \describe{
#'     \item{`items`}{character vector of unique item names that survived
#'       content review, in the order they appear in `fit$results`.}
#'     \item{`item_evidence`}{data frame with one row per result row: `item`,
#'       `status`, `recommendation`, `carried`, and the workflow's key indices.}
#'     \item{`provenance`}{list recording the workflow, mode, the `keep` rule,
#'       settings, design, the contentvalidR version, and the date.}
#'   }
#'
#' @seealso [as.data.frame.contentvalid_workflow()] for the full results table,
#'   and [content_report()] for manuscript tables.
#'
#' @examples
#' relevance <- matrix(
#'   c(4,4,4,3, 4,4,3,4, 3,4,4,4, 2,2,1,2),
#'   nrow = 4,
#'   dimnames = list(NULL, paste0("Item", 1:4))
#' )
#' fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
#'                        agreement = "none")
#' handoff <- content_handoff(fit)
#' handoff
#' handoff$items
#' handoff$item_evidence
#'
#' # Carry items flagged for review as well, when the study protocol says so.
#' content_handoff(fit, keep = c("Supported", "Review"))$items
#' @export
content_handoff <- function(fit, keep = "Supported") {
  item_classes <- c("contentvalid_sort", "contentvalid_rating", "contentvalid_expert")
  if (!inherits(fit, item_classes, which = FALSE)) {
    stop("`fit` must be a sort, rating, or expert-panel workflow object. ",
         "judge_validity() and domain_validity() results describe judges and ",
         "blueprint cells rather than items, so they carry no item set.",
         call. = FALSE)
  }

  valid <- .status_definitions()$status
  if (!is.character(keep) || !length(keep) || anyNA(keep) || !all(keep %in% valid)) {
    stop("`keep` must be one or more of: ", paste(valid, collapse = ", "), ".",
         call. = FALSE)
  }

  results <- .with_workflow_status(fit$results)
  if (!"item" %in% names(results)) {
    stop("This workflow's results have no `item` column, so there is no item ",
         "set to carry forward.", call. = FALSE)
  }

  indices <- setdiff(.report_columns(fit), "item")
  evidence <- data.frame(
    item = as.character(results$item),
    status = as.character(results$status),
    recommendation = if ("recommendation" %in% names(results)) {
      as.character(results$recommendation)
    } else {
      NA_character_
    },
    stringsAsFactors = FALSE
  )
  evidence$carried <- evidence$status %in% keep
  if (length(indices)) {
    evidence <- cbind(evidence, results[indices], stringsAsFactors = FALSE)
  }
  rownames(evidence) <- NULL

  out <- list(
    items = unique(evidence$item[evidence$carried]),
    item_evidence = evidence,
    provenance = list(
      package = "contentvalidR",
      version = as.character(getNamespaceVersion("contentvalidR")),
      workflow = .workflow_name(fit),
      mode = if (is.null(fit$mode)) NA_character_ else fit$mode,
      keep = keep,
      settings = fit$settings,
      design = .workflow_design(fit),
      created = format(Sys.Date())
    )
  )
  class(out) <- "contentvalid_handoff"
  out
}

#' @export
print.contentvalid_handoff <- function(x, ...) {
  p <- x$provenance
  cat("contentvalidR handoff\n")
  cat(strrep("-", 21), "\n", sep = "")
  cat("Workflow: ", p$workflow, sep = "")
  if (!is.na(p$mode)) cat(" (", p$mode, ")", sep = "")
  cat("   contentvalidR ", p$version, "   ", p$created, "\n", sep = "")
  cat("Items carried forward: ", length(x$items), " of ",
      length(unique(x$item_evidence$item)), "\n", sep = "")
  cat("Carried when status is: ", paste(p$keep, collapse = ", "), "\n", sep = "")

  held <- x$item_evidence[!x$item_evidence$carried, , drop = FALSE]
  if (nrow(held)) {
    cat("\nHeld back:\n")
    print(held[intersect(c("item", "status", "recommendation"), names(held))],
          row.names = FALSE)
  }

  cat("\n")
  cat(strwrap(paste(
    "Carry these items into the empirical workflow once response data are",
    "collected. In nomologR that is nomo_screen(data, items = <handoff>$items),",
    "which screens the same items you retained here."
  ), width = 76), sep = "\n")

  cat("\n")
  cat(strwrap(paste(
    "Surviving content review is evidence about relevance, representation, and",
    "expert judgment. It does not establish that an item will behave well",
    "empirically: an item can be clearly relevant and still correlate poorly",
    "with its construct or load on an unintended factor. Items held back are",
    "listed above rather than deleted, so the record stays complete."
  ), width = 76), sep = "\n")
  cat("\n")
  invisible(x)
}

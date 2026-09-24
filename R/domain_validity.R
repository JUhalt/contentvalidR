.domain_cell_labels <- function(d, cell_col, facet_col) {
  cells <- as.character(d[[cell_col]])
  if (!is.null(facet_col)) {
    cells <- paste(cells, as.character(d[[facet_col]]), sep = " / ")
  }
  cells
}

#' Analyze content-domain coverage and structure
#'
#' @description
#' Answers two questions that item-level relevance indices cannot: whether the
#' item set actually spans the intended content domain, and whether experts
#' perceive the items as grouping the way the blueprint says they should.
#'
#' Coverage is assessed against a blueprint, or table of specifications: the
#' cells of the domain the instrument is meant to represent. Cells with no
#' items, or too few, are content gaps that no amount of item-level relevance
#' evidence will reveal, because an item can only be rated if it exists.
#'
#' Structure is assessed with the multidimensional scaling and cluster analysis
#' procedure of Sireci and Geisinger (1992), and is run when expert similarity
#' data is supplied. See [content_structure()].
#'
#' @param assignments A data frame mapping items to blueprint cells.
#' @param item_col Column naming each item.
#' @param cell_col Column naming each item's blueprint cell, typically the
#'   construct or content area.
#' @param facet_col Optional second column. When supplied, cells are the
#'   crossing of `cell_col` and `facet_col`, as in a construct-by-facet table of
#'   specifications.
#' @param domain Optional character vector of every cell the blueprint intends
#'   to cover. Supplying it is what makes **empty** cells detectable; without it
#'   only the cells that already contain items can be reported.
#' @param min_items Fewest items a cell may hold before it is flagged as thinly
#'   covered.
#' @param over_factor A cell holding more than this multiple of its expected
#'   share is flagged as over-represented. This is an attention-drawing
#'   heuristic, not a standard.
#' @param targets Optional named numeric vector giving the intended number of
#'   items per cell. When supplied, expected shares come from it rather than
#'   from an assumption of equal cells.
#' @param similarity Optional square item-by-item expert similarity matrix. When
#'   supplied, the content-structure analysis is run and reported alongside
#'   coverage.
#' @param ... Further arguments passed to [content_structure()].
#'
#' @return An object of class `contentvalid_domain` and `contentvalid_workflow`.
#'   `results` has **one row per blueprint cell**. `details$structure` holds the
#'   content-structure analysis when similarity data was supplied.
#'
#' @section What coverage evidence can and cannot establish:
#' A fully covered blueprint shows that items exist for every intended cell. It
#' does not show that those items are good ones, that the blueprint itself is
#' the right description of the domain, or that the cells are equally important.
#' Coverage is evidence about the item set's reach, and is properly read
#' alongside item-level relevance evidence and expert judgment about the
#' blueprint itself.
#'
#' @references
#' Sireci, S. G. (1998). The construct of content validity. *Social Indicators
#' Research, 45*(1-3), 83-117. \doi{10.1023/A:1006985528729}
#'
#' Sireci, S. G., & Geisinger, K. F. (1992). Analyzing test content using
#' cluster analysis and multidimensional scaling. *Applied Psychological
#' Measurement, 16*(1), 17-31. \doi{10.1177/014662169201600102}
#'
#' Rovinelli, R. J., & Hambleton, R. K. (1977). On the use of content
#' specialists in the assessment of criterion-referenced test item validity.
#' *Dutch Journal of Educational Research, 2*, 49-60.
#'
#' @seealso [content_structure()], [similarity_from_sort()], [ioc()].
#'
#' @examples
#' assignments <- data.frame(
#'   item = paste0("I", 1:7),
#'   construct = c("Autonomy", "Autonomy", "Autonomy", "Autonomy",
#'                 "Competence", "Competence", "Relatedness")
#' )
#' domain_validity(
#'   assignments,
#'   cell_col = "construct",
#'   domain = c("Autonomy", "Competence", "Relatedness", "Belonging")
#' )
#' @export
domain_validity <- function(assignments,
                            item_col = "item",
                            cell_col = "cell",
                            facet_col = NULL,
                            domain = NULL,
                            min_items = 2,
                            over_factor = 2,
                            targets = NULL,
                            similarity = NULL,
                            ...) {
  if (!is.data.frame(assignments) || !nrow(assignments)) {
    stop("`assignments` must be a data.frame with at least one row.", call. = FALSE)
  }
  if (is.null(facet_col)) {
    .validate_column_names(item_col, cell_col)
  } else {
    .validate_column_names(item_col, cell_col, facet_col)
  }
  needed <- c(item_col, cell_col, facet_col)
  missing_cols <- setdiff(needed, names(assignments))
  if (length(missing_cols)) {
    stop("`assignments` is missing required column(s): ",
         paste(missing_cols, collapse = ", "), ".", call. = FALSE)
  }
  if (!is.numeric(min_items) || length(min_items) != 1L || !is.finite(min_items) ||
      min_items < 1 || min_items != floor(min_items)) {
    stop("`min_items` must be one positive integer.", call. = FALSE)
  }
  if (!is.numeric(over_factor) || length(over_factor) != 1L ||
      !is.finite(over_factor) || over_factor <= 1) {
    stop("`over_factor` must be one number greater than 1.", call. = FALSE)
  }

  d <- assignments[, needed, drop = FALSE]
  .validate_labels(d[[item_col]], "item")
  .validate_labels(d[[cell_col]], "cell")
  if (!is.null(facet_col)) .validate_labels(d[[facet_col]], "facet")

  items <- as.character(d[[item_col]])
  if (anyDuplicated(items)) {
    stop("Each item may appear only once. Duplicate item(s): ",
         paste(unique(items[duplicated(items)]), collapse = ", "), ".", call. = FALSE)
  }
  cells <- .domain_cell_labels(d, cell_col, facet_col)

  observed <- unique(cells)
  if (!is.null(domain)) {
    .validate_labels(domain, "domain")
    domain <- unique(as.character(domain))
    unknown <- setdiff(observed, domain)
    if (length(unknown)) {
      stop("These cells appear in `assignments` but not in `domain`: ",
           paste(unknown, collapse = ", "),
           ". Add them to `domain` or correct the assignments.", call. = FALSE)
    }
    all_cells <- domain
  } else {
    all_cells <- sort(observed)
  }

  n_items <- length(items)
  n_cells <- length(all_cells)
  counts <- vapply(all_cells, function(z) sum(cells == z), integer(1))

  if (!is.null(targets)) {
    if (!is.numeric(targets) || is.null(names(targets)) || anyNA(targets) ||
        any(targets < 0) || any(!is.finite(targets))) {
      stop("`targets` must be a named, non-negative numeric vector.", call. = FALSE)
    }
    missing_targets <- setdiff(all_cells, names(targets))
    if (length(missing_targets)) {
      stop("`targets` is missing entries for: ",
           paste(missing_targets, collapse = ", "), ".", call. = FALSE)
    }
    target_n <- as.numeric(targets[all_cells])
    expected_share <- if (sum(target_n) > 0) target_n / sum(target_n) else rep(NA_real_, n_cells)
  } else {
    target_n <- rep(NA_real_, n_cells)
    expected_share <- rep(1 / n_cells, n_cells)
  }

  share <- counts / n_items
  empty <- counts == 0L
  thin <- !empty & counts < min_items
  over <- !empty & !is.na(expected_share) & share > over_factor * expected_share

  recommendation <- ifelse(empty, "Not covered",
                    ifelse(thin, "Thinly covered",
                    ifelse(over, "Over-represented", "Covered")))
  status <- ifelse(empty | thin | over, "Review", "Supported")

  interpretation <- vapply(seq_len(n_cells), function(i) {
    if (empty[i]) {
      return(paste(
        "No item addresses this cell. Item-level relevance evidence cannot",
        "reveal this gap, because there is no item here to rate. Either write",
        "items for this cell or state explicitly why the blueprint no longer",
        "requires it."
      ))
    }
    if (thin[i]) {
      return(sprintf(paste(
        "Only %d item(s) address this cell, below the minimum of %d set for",
        "this analysis. Thin coverage limits how well the cell can be",
        "represented, and leaves the cell's contribution dependent on very few",
        "items."
      ), counts[i], min_items))
    }
    if (over[i]) {
      return(sprintf(paste(
        "This cell holds %.0f%% of the items, more than %.1f times its expected",
        "share of %.0f%%. Over-representation is not an error, but it weights",
        "the instrument toward this cell, which should be a deliberate choice",
        "rather than an accident of item writing."
      ), share[i] * 100, over_factor, expected_share[i] * 100))
    }
    sprintf("This cell holds %d item(s), %.0f%% of the instrument, which meets the coverage criteria set for this analysis.",
            counts[i], share[i] * 100)
  }, character(1))

  results <- data.frame(
    cell = all_cells,
    n_items = as.integer(counts),
    share = share,
    target_items = target_n,
    expected_share = expected_share,
    recommendation = recommendation,
    status = status,
    interpretation = interpretation,
    stringsAsFactors = FALSE
  )
  rownames(results) <- NULL

  structure_fit <- NULL
  if (!is.null(similarity)) {
    sim_mat <- as.matrix(similarity)
    sim_items <- rownames(sim_mat)
    if (!is.null(sim_items)) {
      unknown_items <- setdiff(sim_items, items)
      if (length(unknown_items)) {
        stop("`similarity` refers to item(s) with no blueprint assignment: ",
             paste(unknown_items, collapse = ", "), ".", call. = FALSE)
      }
      membership <- cells[match(sim_items, items)]
    } else {
      # Without row names the only defensible pairing is positional, which
      # requires the two to be the same length.
      if (nrow(sim_mat) != n_items) {
        stop("`similarity` has no row names and its size does not match the ",
             "number of items, so item positions cannot be matched. Add item ",
             "names to `similarity`.", call. = FALSE)
      }
      membership <- cells
    }
    structure_fit <- content_structure(similarity, membership = membership, ...)
  }

  scale_summary <- data.frame(
    n_items = n_items,
    n_cells = n_cells,
    n_covered = sum(!empty & !thin & !over),
    n_empty = sum(empty),
    n_thin = sum(thin),
    n_over = sum(over),
    domain_supplied = !is.null(domain),
    adjusted_rand = if (is.null(structure_fit)) NA_real_ else structure_fit$adjusted_rand,
    stringsAsFactors = FALSE
  )

  settings <- list(
    method = "Blueprint coverage with optional Sireci-Geisinger content structure",
    min_items = as.integer(min_items),
    over_factor = over_factor,
    targets_supplied = !is.null(targets),
    domain_supplied = !is.null(domain),
    structure_analyzed = !is.null(structure_fit)
  )
  design <- list(
    type = "content-domain coverage",
    n_items = n_items,
    n_cells = n_cells,
    faceted = !is.null(facet_col)
  )

  .new_contentvalid_workflow(
    subclass = "contentvalid_domain",
    workflow = "domain-coverage",
    results = results,
    scale_summary = scale_summary,
    settings = settings,
    design = design,
    details = list(
      structure = structure_fit,
      item_cells = data.frame(item = items, cell = cells, stringsAsFactors = FALSE)
    )
  )
}

#' @export
print.contentvalid_domain <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  s <- x$scale_summary
  st <- x$settings
  r <- x$results
  pct <- function(p) ifelse(is.na(p), "NA",
                            paste0(formatC(100 * p, format = "f", digits = 0),
                                   "%"))
  cat("contentvalidR content-domain coverage\n")
  cat(strrep("-", 37), "\n", sep = "")
  cat("Items: ", s$n_items, " | Blueprint cells: ", s$n_cells, "\n", sep = "")
  .say(paste0(
    "Criteria: at least ", st$min_items, " item", if (st$min_items != 1L) "s",
    " per cell, and no cell above ", format(st$over_factor),
    " times its expected share",
    if (isTRUE(st$targets_supplied)) " (from `targets`)" else
      " (an equal share when no `targets` are given)", "."
  ))
  cat("\n")
  .say(paste0(s$n_covered, " of ", s$n_cells,
              " cells meet the coverage criteria."))
  flagged <- r$status == "Review"
  if (any(flagged)) {
    .say("Flagged for review:",
         paste0(r$cell[flagged], " (", r$recommendation[flagged], ")",
                collapse = ", "))
  }

  cat("\nCells\n")
  show <- data.frame(cell = r$cell, decision = r$recommendation,
                     items = r$n_items, share = pct(r$share),
                     expected = pct(r$expected_share),
                     stringsAsFactors = FALSE, check.names = FALSE)
  .print_table(show)

  if (!isTRUE(s$domain_supplied)) {
    cat("\n")
    .say("No `domain` was supplied, so only cells that already contain items",
         "could be reported. Cells intended by the blueprint but holding no",
         "items cannot be detected this way.")
  }

  if (!is.null(x$details$structure)) {
    cs <- x$details$structure
    cat("\nContent structure: adjusted Rand index ",
        .fmt(cs$adjusted_rand, digits), " (", cs$status, ")\n", sep = "")
  }

  if (.show_key()) {
    terms <- "share"
    if (!is.null(x$details$structure)) terms <- c(terms, "adjusted_rand", "stress")
    .print_key(terms, headings = c("share", "adjusted Rand", "stress")[
      seq_along(terms)])
    cat("\nWhat the cell labels mean\n")
    labels <- c(
      "Covered -- the cell met the coverage criteria set for this analysis.",
      "Thinly covered -- fewer items than the minimum you set.",
      "Over-represented -- a larger share of the instrument than expected.",
      "Not covered -- the blueprint intends this cell but no item addresses it."
    )
    for (lab in labels) .say(lab, indent = 2L, exdent = 6L)
    .print_key_footer()
  }

  cat("\n")
  .say("Coverage shows that items exist for each cell. It does not show that",
       "those items are good ones, or that the blueprint is the right",
       "description of the domain.")
  invisible(x)
}

#' @export
summary.contentvalid_domain <- function(object, ...) {
  core <- .workflow_summary_core(object)
  core$n_cells <- object$design$n_cells
  core$structure <- object$details$structure
  core$domain_supplied <- object$scale_summary$domain_supplied
  core$gaps <- object$results[object$results$status == "Review", , drop = FALSE]
  class(core) <- "summary.contentvalid_domain"
  core
}

#' @export
print.summary.contentvalid_domain <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  cat("Summary: content-domain coverage\n")
  cat("Items: ", x$n_items, " | Blueprint cells: ", x$n_cells, "\n", sep = "")
  cat("Cells meeting coverage criteria: ", x$n_supported, " | Flagged: ",
      x$n_review, "\n", sep = "")

  if (nrow(x$gaps)) {
    cat("\nCells needing attention\n")
    for (i in seq_len(nrow(x$gaps))) {
      row <- x$gaps[i, ]
      cat(sprintf("\n  %s (%s, %d item%s)\n", row$cell, row$recommendation,
                  row$n_items, if (row$n_items == 1L) "" else "s"))
      .say(row$interpretation, indent = 4L)
    }
  } else {
    cat("\nEvery blueprint cell met the coverage criteria set for this analysis.\n")
  }

  if (!is.null(x$structure)) {
    cat("\nContent structure\n")
    .say(x$structure$interpretation, indent = 2L)
  }

  if (!isTRUE(x$domain_supplied)) {
    cat("\n")
    .say("Note: no `domain` was supplied, so empty cells could not be",
         "detected.")
  }
  invisible(x)
}

#' Plot an expert content map
#'
#' @description
#' Plots the multidimensional scaling content map from [content_structure()],
#' with each item positioned by expert-perceived similarity and labeled by its
#' blueprint cell. Items that sit away from others sharing their cell are the
#' ones experts did not group as the blueprint expects.
#'
#' @param x A `contentvalid_structure` object.
#' @param show_legend Draw the blueprint-cell key.
#' @param ... Passed to [graphics::plot()].
#'
#' @return `x`, invisibly. Called for the plot.
#' @examples
#' items <- paste0("I", 1:6)
#' blueprint <- c(rep("Autonomy", 3), rep("Competence", 3))
#' sim <- matrix(1, 6, 6, dimnames = list(items, items))
#' sim[1:3, 1:3] <- 5
#' sim[4:6, 4:6] <- 5
#' diag(sim) <- 5
#' plot(content_structure(sim, membership = blueprint))
#' @export
plot.contentvalid_structure <- function(x, show_legend = TRUE, ...) {
  .validate_flag(show_legend, "show_legend")
  pts <- x$coordinates
  cl <- x$clusters

  if (ncol(pts) < 2L) {
    y <- rep(0, nrow(pts))
    graphics::plot(pts[, 1], y, yaxt = "n", ylab = "",
                   xlab = "Dimension 1", pch = 19, ...)
    graphics::text(pts[, 1], y, labels = rownames(pts), pos = 3, cex = 0.7)
    return(invisible(x))
  }

  group <- if (!is.null(cl$blueprint_cell)) factor(cl$blueprint_cell) else factor(cl$cluster)
  pch <- (as.integer(group) - 1L) %% 25L + 1L

  xr <- range(pts[, 1]); yr <- range(pts[, 2])
  pad <- 0.15 * c(diff(xr), diff(yr))
  pad[!is.finite(pad) | pad == 0] <- 1

  graphics::plot(pts[, 1], pts[, 2], pch = pch,
                 xlim = xr + c(-pad[1], pad[1]),
                 ylim = yr + c(-pad[2], pad[2] * 1.6),
                 xlab = "Dimension 1", ylab = "Dimension 2", ...)
  graphics::text(pts[, 1], pts[, 2], labels = rownames(pts), pos = 3, cex = 0.7)

  if (isTRUE(show_legend)) {
    graphics::legend("top", legend = levels(group),
                     pch = (seq_along(levels(group)) - 1L) %% 25L + 1L,
                     bty = "n", horiz = TRUE, cex = 0.68, x.intersp = 0.7)
  }
  invisible(x)
}

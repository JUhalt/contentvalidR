.domain_cell_labels <- function(d, cell_col, facet_col) {
  # Labels are compared as trimmed text, as in the other workflows.
  cells <- .as_label(d[[cell_col]])
  if (!is.null(facet_col)) {
    cells <- paste(cells, .as_label(d[[facet_col]]), sep = " / ")
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
#' Structure is assessed with a multidimensional scaling and cluster analysis
#' adapted from Sireci and Geisinger (1992, 1995), run when expert similarity
#' data is supplied. See [content_structure()] for what differs from their
#' procedure.
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
#'   only the cells that already contain items, or that `targets` names, can
#'   be reported.
#' @param min_items Fewest items a cell may hold before it is flagged as thinly
#'   covered. With `targets`, a cell is compared with the smaller of
#'   `min_items` and its own target, so a cell the blueprint gives one item is
#'   not thin with one.
#' @param over_factor A cell holding more than this multiple of its expected
#'   share is flagged as over-represented. With `targets`, a cell holding less
#'   than its expected share divided by `over_factor` is flagged as
#'   under-represented. This is an attention-drawing heuristic, not a
#'   standard. With few cells no share can exceed the multiple (two equal
#'   cells at the default of 2), and the printout says so.
#' @param targets Optional named numeric vector giving the intended number of
#'   items per cell. When supplied, expected shares come from it rather than
#'   from an assumption of equal cells, and cells far below their intended
#'   share are flagged. Without it under-representation is not judged,
#'   because an equal share is an assumption, not a blueprint. A cell named
#'   in `targets` is part of the blueprint, so it is reported (as not
#'   covered) even when no item is assigned to it. With `domain`, every cell
#'   `targets` names must be in `domain`. A fractional target is rounded up
#'   where it sets the thin-coverage floor.
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
#' The coverage tally itself (`min_items`, `over_factor`, `targets`) is this
#' package's blueprint check, not a published index: it counts items per
#' cell and draws attention to cells that are empty, thin, or out of
#' proportion. Sireci (1998) discusses why domain representation belongs in
#' a content-validity argument alongside item relevance.
#'
#' @references
#' Sireci, S. G. (1998). The construct of content validity. *Social Indicators
#' Research, 45*(1–3), 83–117. \doi{10.1023/A:1006985528729}
#'
#' Sireci, S. G., & Geisinger, K. F. (1992). Analyzing test content using
#' cluster analysis and multidimensional scaling. *Applied Psychological
#' Measurement, 16*(1), 17–31. \doi{10.1177/014662169201600102}
#'
#' Sireci, S. G., & Geisinger, K. F. (1995). Using subject-matter experts to
#' assess content representation: An MDS analysis. *Applied Psychological
#' Measurement, 19*(3), 241–255. \doi{10.1177/014662169501900303}
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

  items <- .as_label(d[[item_col]])
  if (anyDuplicated(items)) {
    stop("Each item may appear only once. Duplicate item(s): ",
         paste(unique(items[duplicated(items)]), collapse = ", "), ".", call. = FALSE)
  }
  cells <- .domain_cell_labels(d, cell_col, facet_col)

  if (!is.null(targets)) {
    if (!is.numeric(targets) || is.null(names(targets)) || anyNA(targets) ||
        any(targets < 0) || any(!is.finite(targets))) {
      stop("`targets` must be a named, non-negative numeric vector.", call. = FALSE)
    }
    names(targets) <- .as_label(names(targets))
    if (anyDuplicated(names(targets))) {
      stop("`targets` names a cell more than once: ",
           paste(unique(names(targets)[duplicated(names(targets))]),
                 collapse = ", "), ".", call. = FALSE)
    }
  }

  observed <- unique(cells)
  if (!is.null(domain)) {
    .validate_labels(domain, "domain")
    domain <- unique(.as_label(domain))
    unknown <- setdiff(observed, domain)
    if (length(unknown)) {
      stop("These cells appear in `assignments` but not in `domain`: ",
           paste(unknown, collapse = ", "),
           ". Add them to `domain` or correct the assignments.", call. = FALSE)
    }
    extra <- setdiff(names(targets), domain)
    if (length(extra)) {
      stop("`targets` names cells that are not in `domain`: ",
           paste(extra, collapse = ", "),
           ". Add them to `domain` or remove them from `targets`.",
           call. = FALSE)
    }
    all_cells <- domain
  } else {
    # A cell with a target is part of the blueprint, so a target cell that
    # holds no item is reported as not covered rather than left out.
    all_cells <- sort(union(observed, names(targets)))
  }

  n_items <- length(items)
  n_cells <- length(all_cells)
  counts <- vapply(all_cells, function(z) sum(cells == z), integer(1))

  if (!is.null(targets)) {
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
  # Shares in the interpretations are written as the printed table writes
  # them.
  pct <- function(p) .fmt_pct(p, base = n_items)
  empty <- counts == 0L
  # A cell the blueprint gives one item is not thin with one: with targets,
  # the floor is the smaller of `min_items` and the cell's own target.
  thin_floor <- if (is.null(targets)) {
    rep(min_items, n_cells)
  } else {
    # Rounded up: a cell cannot hold part of an item.
    pmin(min_items, pmax(ceiling(target_n - 1e-9), 1))
  }
  thin <- !empty & counts < thin_floor
  over <- !empty & !is.na(expected_share) & share > over_factor * expected_share
  # Under-representation is judged only against stated targets. Without them
  # the expected share is an assumption of equal cells, not a blueprint.
  under <- !is.null(targets) & !empty & !thin & !is.na(expected_share) &
    share < expected_share / over_factor

  recommendation <- ifelse(empty, "Not covered",
                    ifelse(thin, "Thinly covered",
                    ifelse(over, "Over-represented",
                    ifelse(under, "Under-represented", "Covered"))))
  status <- ifelse(empty | thin | over | under, "Review", "Supported")

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
        "Only %s this cell, below the minimum of %d set for",
        "this analysis. Thin coverage limits how well the cell can be",
        "represented, and leaves the cell's contribution dependent on very few",
        "items."
      ), .n_noun(counts[i], "item addresses", "items address"),
         as.integer(thin_floor[i])))
    }
    if (under[i]) {
      return(sprintf(paste(
        "This cell holds %s of the items, less than 1/%s of its intended",
        "share of %s (a target of %s). The blueprint weights this cell",
        "more heavily than the item set does. Either write more items for it",
        "or revise the target."
      ), pct(share[i]), format(over_factor), pct(expected_share[i]),
         .n_noun(format(target_n[i]), "item")))
    }
    if (over[i]) {
      return(sprintf(paste(
        "This cell holds %s of the items (%s), more than %.1f times its",
        "expected share of %s. Over-representation is not an error, but it",
        "weights the instrument toward this cell, which should be a deliberate",
        "choice rather than an accident of item writing."
      ), pct(share[i]), .n_noun(counts[i], "item"), over_factor,
         pct(expected_share[i])))
    }
    sprintf("This cell holds %s, %s of the instrument, which meets the coverage criteria set for this analysis.",
            .n_noun(counts[i], "item"), pct(share[i]))
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
    # Item names are compared as trimmed text, as the assignments are.
    if (!is.null(rownames(sim_mat))) rownames(sim_mat) <- .as_label(rownames(sim_mat))
    if (!is.null(colnames(sim_mat))) colnames(sim_mat) <- .as_label(colnames(sim_mat))
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
    structure_fit <- content_structure(sim_mat, membership = membership, ...)
  }

  scale_summary <- data.frame(
    n_items = n_items,
    n_cells = n_cells,
    n_covered = sum(status == "Supported"),
    n_empty = sum(empty),
    n_thin = sum(thin),
    n_over = sum(over),
    n_under = sum(under),
    domain_supplied = !is.null(domain),
    adjusted_rand = if (is.null(structure_fit)) NA_real_ else structure_fit$adjusted_rand,
    stringsAsFactors = FALSE
  )

  settings <- list(
    method = paste("Blueprint coverage with optional content structure",
                   "adapted from Sireci and Geisinger"),
    min_items = as.integer(min_items),
    over_factor = over_factor,
    targets_supplied = !is.null(targets),
    # Whether any cell could be flagged as over-represented at all: with two
    # equal cells and a factor of 2 a share would have to exceed 100%.
    over_possible = any(!is.na(expected_share) & over_factor * expected_share < 1),
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
  pct <- function(p) .fmt_pct(p, base = s$n_items)
  .print_header(x, "Content-domain coverage")
  cat("Items: ", s$n_items, " | Blueprint cells: ", s$n_cells, "\n", sep = "")
  .say(paste0(
    "Criteria: at least ", st$min_items, " item", if (st$min_items != 1L) "s",
    " per cell",
    if (isTRUE(st$targets_supplied) && st$min_items > 1L) {
      " (or the cell's target, if smaller)"
    },
    ", and no cell above ", format(st$over_factor),
    " times its expected share",
    if (isTRUE(st$targets_supplied)) {
      paste0(" or below 1/", format(st$over_factor),
             " of it (expected shares from `targets`)")
    } else {
      " (an equal share when no `targets` are given)"
    }, ".",
    if (identical(st$over_possible, FALSE)) {
      paste(" With these cells no share can exceed that multiple, so no",
            "cell can be flagged as over-represented.")
    },
    " These criteria are contentvalidR conventions, not published standards."
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

  .section("Cells")
  show <- data.frame(cell = r$cell, decision = r$recommendation,
                     items = r$n_items, share = pct(r$share),
                     expected = pct(r$expected_share),
                     stringsAsFactors = FALSE, check.names = FALSE)
  .print_table(show)

  if (!isTRUE(s$domain_supplied)) {
    cat("\n")
    if (isTRUE(st$targets_supplied)) {
      .say("No `domain` was supplied, so the cells reported are those holding",
           "items and those named in `targets`. A cell intended by the",
           "blueprint but named in neither cannot be detected this way.")
    } else {
      .say("No `domain` was supplied, so only cells that already contain items",
           "could be reported. Cells intended by the blueprint but holding no",
           "items cannot be detected this way.")
    }
  }

  if (!is.null(x$details$structure)) {
    cs <- x$details$structure
    cat("\nContent structure: adjusted Rand index ",
        if (is.na(cs$adjusted_rand)) "not defined" else
          .fmt(cs$adjusted_rand, digits), " (", cs$status, ")\n", sep = "")
  }

  if (.show_key()) {
    # Only what this printout shows: the map's fit is in the structure
    # object's own print.
    terms <- "share"
    if (!is.null(x$details$structure)) terms <- c(terms, "adjusted_rand")
    .print_key(terms, headings = c("share", "adjusted Rand")[seq_along(terms)])
    .print_decision_legend(x$results$recommendation, "domain")
    .print_key_footer()
  }

  .closing(c("Coverage shows that items exist for each cell. It does not show that",
             "those items are good ones, or that the blueprint is the right",
             "description of the domain."),
           "See summary(x) for the cells needing attention.")
  invisible(x)
}

#' @export
summary.contentvalid_domain <- function(object, ...) {
  core <- .workflow_summary_core(object)
  core$n_cells <- object$design$n_cells
  core$structure <- object$details$structure
  core$domain_supplied <- object$scale_summary$domain_supplied
  core$targets_supplied <- isTRUE(object$settings$targets_supplied)
  core$gaps <- object$results[object$results$status == "Review", , drop = FALSE]
  class(core) <- "summary.contentvalid_domain"
  core
}

#' @export
print.summary.contentvalid_domain <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  .print_header(x, "Content-domain coverage")
  cat("Items: ", x$n_items, " | Blueprint cells: ", x$n_cells, "\n", sep = "")
  cat("Cells meeting coverage criteria: ", x$n_supported, " | Flagged: ",
      x$n_review, "\n", sep = "")

  if (nrow(x$gaps)) {
    .section("Flagged")
    g <- x$gaps
    .say_flagged(g$cell, g$recommendation, g$interpretation)
  } else {
    .end_section()
    cat("\n")
    .say("Every blueprint cell met the coverage criteria set for this analysis.")
  }

  if (!is.null(x$structure)) {
    .section("Content structure")
    .say(x$structure$interpretation, indent = 2L)
  }

  if (!isTRUE(x$domain_supplied)) {
    cat("\n")
    .say(if (isTRUE(x$targets_supplied)) {
      paste("Note: no `domain` was supplied, so only cells named in `targets`",
            "could be detected as empty.")
    } else {
      "Note: no `domain` was supplied, so empty cells could not be detected."
    })
  }
  .closing(pointer = "See x$gaps for the cells needing attention as a data frame.")
  invisible(x)
}

# The point symbols and colours of a content map, and those of its key. A
# symbol or colour given once per cell is applied by cell, so the key still
# matches the points. A symbol given any other way leaves no key, which could
# no longer tell the cells apart. NULL colours leave the defaults in place.
.structure_symbols <- function(group, user) {
  n <- nlevels(group)
  at <- as.integer(group)
  key_pch <- (seq_len(n) - 1L) %% 25L + 1L
  pch <- key_pch[at]
  if (!is.null(user$pch)) {
    if (length(user$pch) == n) {
      key_pch <- user$pch
      pch <- user$pch[at]
    } else {
      key_pch <- NULL
      pch <- user$pch
    }
  }
  col <- NULL
  key_col <- NULL
  if (!is.null(user$col)) {
    if (length(user$col) == n) {
      key_col <- user$col
      col <- user$col[at]
    } else {
      if (length(user$col) == 1L) key_col <- user$col
      col <- user$col
    }
  }
  list(pch = pch, col = col, key_pch = key_pch, key_col = key_col)
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
#' @param type `"map"`, the only view, accepted so that every plot method
#'   takes `type`.
#' @param ... Passed to [graphics::plot()]. An argument given here, such as
#'   `xlab`, `xlim` or `main`, replaces the one the method would set. A `pch`
#'   or `col` with one value per blueprint cell (or cluster) is applied cell
#'   by cell and shown in the key; a `pch` of any other length leaves the key
#'   out, because it could no longer tell the cells apart.
#'
#' @return `x`, invisibly. Called for the plot.
#' @examples
#' items <- paste0("I", 1:9)
#' blueprint <- rep(c("Autonomy", "Competence", "Relatedness"), each = 3)
#' sim <- matrix(c(
#'   5, 4, 3, 2, 2, 1, 1, 2, 1,
#'   4, 5, 4, 3, 1, 2, 2, 1, 1,
#'   3, 4, 5, 1, 2, 2, 1, 1, 3,
#'   2, 3, 1, 5, 4, 3, 2, 2, 1,
#'   2, 1, 2, 4, 5, 4, 1, 3, 2,
#'   1, 2, 2, 3, 4, 5, 2, 1, 2,
#'   1, 2, 1, 2, 1, 2, 5, 3, 4,
#'   2, 1, 1, 2, 3, 1, 3, 5, 4,
#'   1, 1, 3, 1, 2, 2, 4, 4, 5
#' ), 9, 9, dimnames = list(items, items))
#' plot(content_structure(sim, membership = blueprint))
#' @export
plot.contentvalid_structure <- function(x, show_legend = TRUE, type = "map", ...) {
  .validate_flag(show_legend, "show_legend")
  type <- .choose(type, "map")
  user <- list(...)
  op <- .plot_margins(user)
  on.exit(graphics::par(op), add = TRUE)
  pts <- x$coordinates
  cl <- x$clusters

  group <- if (!is.null(cl$blueprint_cell)) factor(cl$blueprint_cell) else factor(cl$cluster)
  sym <- .structure_symbols(group, user)
  user$pch <- NULL
  user$col <- NULL
  # A map with one usable dimension is a strip: every item at height 0.
  one_dim <- ncol(pts) < 2L
  px <- pts[, 1]
  py <- if (one_dim) rep(0, nrow(pts)) else pts[, 2]

  xr <- range(px); yr <- range(py)
  pad <- 0.15 * c(diff(xr), diff(yr))
  pad[!is.finite(pad) | pad == 0] <- 1

  # What the caller passes replaces what the method would set, so `xlab`
  # or `xlim` never collide with it.
  args <- list(
    x = px, y = py, pch = sym$pch,
    xlim = xr + c(-pad[1], pad[1]),
    ylim = yr + c(-pad[2], pad[2] * 1.6),
    xlab = "Dimension 1", ylab = if (one_dim) "" else "Dimension 2"
  )
  if (!is.null(sym$col)) args$col <- sym$col
  if (one_dim) args$yaxt <- "n"
  args[names(user)] <- user
  do.call(graphics::plot, args)
  graphics::text(px, py, labels = rownames(pts), pos = 3, cex = 0.7)

  if (isTRUE(show_legend) && !is.null(sym$key_pch)) {
    # Name what the symbols stand for: the blueprint's cells when one was
    # supplied, otherwise the clusters recovered from the similarities.
    key <- list("top", legend = levels(group), pch = sym$key_pch,
                title = if (!is.null(cl$blueprint_cell)) "Blueprint cell" else "Cluster",
                bty = "n", horiz = TRUE, cex = 0.72, x.intersp = 0.7)
    if (!is.null(sym$key_col)) key$col <- sym$key_col
    do.call(graphics::legend, key)
  }
  invisible(x)
}

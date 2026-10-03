.workflow_id_col <- function(x) {
  if (inherits(x, "contentvalid_judge")) return("judge")
  if (inherits(x, "contentvalid_domain")) return("cell")
  "item"
}

# Ordered from weakest to strongest evidential standing. "Descriptive only" is
# deliberately unranked: it reflects an analysis that applied no decision rule,
# so calling it better or worse than a decision would be meaningless.
.status_rank <- function(status) {
  ranks <- c("Insufficient data" = 1L, "Review" = 2L, "Supported" = 3L)
  out <- unname(ranks[as.character(status)])
  out[is.na(out)] <- NA_integer_
  out
}

# Settings that govern resampling for an interval. They cannot move an item's
# status, so two rounds that differ only in these are still comparable.
.resampling_settings <- c("seed", "B", "agreement_B")

# Whether the criterion a unit must meet moves with the number of judges. It
# does for the exact tests (item sort, essentiality) and for Lynn's criterion
# (relevance). It does not where the rule is a fixed share or cut: a Delphi
# consensus threshold, the rating workflow's alpha, the judge and domain cuts,
# the congruence margin.
.criterion_depends_on_panel <- function(fit) {
  if (inherits(fit, "contentvalid_sort")) return(TRUE)
  inherits(fit, "contentvalid_expert") &&
    isTRUE(fit$mode %in% c("relevance", "essentiality"))
}

# The number of judges behind a fit, as text: "6", or "5-6" when items differ.
# Where the criterion depends on it, a changed panel size is a changed
# decision rule even when every setting is the same. Elsewhere it is NA: the
# rule did not move, so the size is not compared.
.round_panel_size <- function(fit) {
  if (!.criterion_depends_on_panel(fit)) return(NA_character_)
  d <- .workflow_design(fit)
  lo <- d$n_judges_min
  hi <- d$n_judges_max
  if (is.numeric(lo) && is.numeric(hi) && length(lo) == 1L && length(hi) == 1L &&
      is.finite(lo) && is.finite(hi)) {
    return(if (lo == hi) format(lo) else paste0(format(lo), "-", format(hi)))
  }
  n <- if (!is.null(d$n_judges)) d$n_judges else d$n_raters
  if (is.numeric(n) && length(n) == 1L && is.finite(n)) format(n) else NA_character_
}

.settings_diff <- function(a, b) {
  keys <- union(names(a), names(b))
  keys <- setdiff(keys, c("method", .resampling_settings))
  rows <- list()
  for (k in keys) {
    va <- a[[k]]
    vb <- b[[k]]
    same <- isTRUE(all.equal(va, vb))
    if (same) next
    fmt <- function(v) {
      if (is.null(v)) return("(not set)")
      if (is.atomic(v) && length(v) <= 4L) return(paste(format(v), collapse = ", "))
      paste0("<", class(v)[1], ">")
    }
    rows[[length(rows) + 1L]] <- data.frame(
      setting = k, previous = fmt(va), current = fmt(vb),
      stringsAsFactors = FALSE
    )
  }
  if (!length(rows)) {
    return(data.frame(setting = character(0), previous = character(0),
                      current = character(0), stringsAsFactors = FALSE))
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Compare content-validity evidence across pretest rounds
#'
#' @description
#' Compares two or more fitted workflow objects from successive rounds of the
#' same pretest, reporting which items changed status, which held steady, and
#' which entered or left the item set.
#'
#' Scale development is iterative: items get revised and re-tested. The risk in
#' reporting that process is attributing a status change to improved items when
#' it actually came from a changed decision rule, a different panel size, or a
#' different criterion. This function makes that distinction visible by
#' comparing the `settings` of each round alongside its results and flagging
#' rounds that differ. For the item sort and for expert relevance and
#' essentiality it compares the panel size too, because the exact tests and
#' Lynn's criterion depend on the number of judges: 5 of 6 does not meet the
#' item-sort criterion, while the same share, 10 of 12, does. Where the rule
#' is a fixed share or cut, as in a Delphi fit, the panel size is not
#' compared: the criterion did not move.
#'
#' @param ... Two or more fitted workflow objects, in round order. All must come
#'   from the same workflow, and from the same mode of [expert_validity()],
#'   since status labels from different workflows rest on different criteria
#'   and are not comparable.
#' @param labels Optional round labels. Defaults to `Round 1`, `Round 2`, and so
#'   on, or to the names supplied in `...`. A label cannot be the name of the
#'   unit column (`item`, `judge` or `cell`) or `change`.
#'
#' @return An object of class `contentvalid_rounds`, a list containing:
#'   \describe{
#'     \item{transitions}{One row per unit, with its status in each round and
#'       the direction of any change.}
#'     \item{summary}{Counts of stable, improved, weakened, added, and removed
#'       units for each consecutive pair of rounds.}
#'     \item{settings_changes}{Analysis settings that differ between consecutive
#'       rounds, and a changed panel size, which is the audit trail for whether
#'       a status change can be read as an evidence change at all.}
#'     \item{comparable}{`FALSE` when any consecutive pair differs in settings
#'       or, where the criterion depends on it, in panel size. The seed and
#'       the number of bootstrap resamples are ignored, because they cannot
#'       change a status.}
#'     \item{panel_compared}{Whether the panel size was part of the
#'       comparison: `TRUE` for the item sort and for expert relevance and
#'       essentiality.}
#'   }
#'
#' @section Reading a comparison:
#' A status change means the evidence crossed a criterion, not that an item
#' improved by a measurable amount. An item can move from `Review` to
#' `Supported` on a small change in one judge's rating if it was sitting near
#' the boundary. Read the transitions together with the underlying index values
#' in each round's own results.
#'
#' When `comparable` is `FALSE`, the rounds were analyzed under different rules,
#' and a status change may reflect only that. Where a setting differs,
#' re-analyze the earlier round under the current settings before reporting a
#' change as progress. Where the panel size differs, compare the index values
#' themselves, since the criterion moved with the panel.
#'
#' The fits in `delphi_validity()$details$round_fits` are relevance fits, so
#' comparing them reads each round against Lynn's I-CVI criterion, not against
#' the consensus threshold of the Delphi.
#'
#' @seealso [reproducibility_phi()] for agreement between two independent judge
#'   samples analyzed under identical settings.
#'
#' @examples
#' round1 <- data.frame(
#'   item = rep(c("I1", "I2"), each = 6),
#'   rater = rep(1:6, times = 2),
#'   assigned_construct = c(rep("A", 5), "B", rep("A", 3), rep("B", 3)),
#'   target_construct = "A",
#'   stringsAsFactors = FALSE
#' )
#' round2 <- round1
#' round2$assigned_construct <- c(rep("A", 6), rep("A", 5), "B")
#' compare_rounds(sort_validity(round1), sort_validity(round2))
#' @export
compare_rounds <- function(..., labels = NULL) {
  rounds <- list(...)
  if (length(rounds) < 2L) {
    stop("`compare_rounds()` needs at least two fitted workflow objects.",
         call. = FALSE)
  }
  ok <- vapply(rounds, inherits, logical(1), what = "contentvalid_workflow")
  if (!all(ok)) {
    stop("Every argument must be a fitted contentvalidR workflow object.",
         call. = FALSE)
  }

  classes <- vapply(rounds, function(z) class(z)[1], character(1))
  if (length(unique(classes)) != 1L) {
    stop("All rounds must come from the same workflow. Status labels from ",
         "different workflows rest on different criteria and are not ",
         "comparable. Received: ", paste(unique(classes), collapse = ", "), ".",
         call. = FALSE)
  }
  # The three expert-panel modes share a class but not a criterion.
  modes <- vapply(rounds, function(z) {
    if (is.null(z$mode)) NA_character_ else as.character(z$mode)[1]
  }, character(1))
  if (length(unique(modes)) != 1L) {
    stop("All rounds must use the same expert-panel mode. Received: ",
         paste(unique(modes), collapse = ", "), ".", call. = FALSE)
  }

  if (is.null(labels)) {
    supplied <- names(rounds)
    labels <- if (!is.null(supplied) && all(nzchar(supplied))) {
      supplied
    } else {
      paste("Round", seq_along(rounds))
    }
  }
  if (length(labels) != length(rounds)) {
    stop("`labels` must have one entry per round.", call. = FALSE)
  }
  labels <- as.character(labels)
  if (anyNA(labels) || any(!nzchar(trimws(labels)))) {
    stop("`labels` must not be missing or empty.", call. = FALSE)
  }
  if (anyDuplicated(labels)) {
    stop("`labels` must be distinct.", call. = FALSE)
  }

  id_col <- .workflow_id_col(rounds[[1]])
  # Labels become column names beside the unit and the change.
  reserved <- labels[labels %in% c(id_col, "change")]
  if (length(reserved)) {
    stop("A round cannot be labeled ",
         paste0("\"", reserved, "\"", collapse = " or "),
         ": the comparison table already has a column of that name.",
         call. = FALSE)
  }
  per_round <- lapply(rounds, function(z) {
    r <- z$results
    if (!id_col %in% names(r)) {
      stop("Expected an `", id_col, "` column in the workflow results.",
           call. = FALSE)
    }
    data.frame(
      id = as.character(r[[id_col]]),
      status = as.character(r$status),
      recommendation = as.character(r$recommendation),
      stringsAsFactors = FALSE
    )
  })

  ids <- unique(unlist(lapply(per_round, function(z) z$id), use.names = FALSE))
  transitions <- data.frame(id = ids, stringsAsFactors = FALSE)
  names(transitions) <- id_col
  for (i in seq_along(per_round)) {
    idx <- match(ids, per_round[[i]]$id)
    transitions[[labels[i]]] <- per_round[[i]]$status[idx]
  }

  first <- transitions[[labels[1]]]
  last <- transitions[[labels[length(labels)]]]
  rank_first <- .status_rank(first)
  rank_last <- .status_rank(last)

  direction <- rep(NA_character_, length(ids))
  direction[is.na(first) & !is.na(last)] <- "Added"
  direction[!is.na(first) & is.na(last)] <- "Removed"
  both <- !is.na(first) & !is.na(last)
  direction[both & first == last] <- "Unchanged"
  comparable_rank <- both & !is.na(rank_first) & !is.na(rank_last)
  direction[comparable_rank & rank_last > rank_first] <- "Strengthened"
  direction[comparable_rank & rank_last < rank_first] <- "Weakened"
  direction[both & first != last & !comparable_rank] <- "Changed"
  transitions$change <- direction

  settings_changes <- list()
  pair_rows <- list()
  for (i in seq_len(length(rounds) - 1L)) {
    a <- transitions[[labels[i]]]
    b <- transitions[[labels[i + 1L]]]
    ra <- .status_rank(a)
    rb <- .status_rank(b)
    cmp <- !is.na(a) & !is.na(b) & !is.na(ra) & !is.na(rb)

    diff <- .settings_diff(rounds[[i]]$settings, rounds[[i + 1L]]$settings)
    size_a <- .round_panel_size(rounds[[i]])
    size_b <- .round_panel_size(rounds[[i + 1L]])
    if (!is.na(size_a) && !is.na(size_b) && !identical(size_a, size_b)) {
      diff <- rbind(diff, data.frame(setting = "panel size", previous = size_a,
                                     current = size_b,
                                     stringsAsFactors = FALSE))
    }
    if (nrow(diff)) {
      diff$from <- labels[i]
      diff$to <- labels[i + 1L]
      settings_changes[[length(settings_changes) + 1L]] <-
        diff[c("from", "to", "setting", "previous", "current")]
    }

    pair_rows[[i]] <- data.frame(
      from = labels[i],
      to = labels[i + 1L],
      n_compared = sum(!is.na(a) & !is.na(b)),
      n_unchanged = sum(!is.na(a) & !is.na(b) & a == b),
      n_strengthened = sum(cmp & rb > ra),
      n_weakened = sum(cmp & rb < ra),
      n_added = sum(is.na(a) & !is.na(b)),
      n_removed = sum(!is.na(a) & is.na(b)),
      settings_changed = nrow(diff) > 0L,
      stringsAsFactors = FALSE
    )
  }

  pair_summary <- do.call(rbind, pair_rows)
  rownames(pair_summary) <- NULL
  settings_changes <- if (length(settings_changes)) {
    out <- do.call(rbind, settings_changes)
    rownames(out) <- NULL
    out
  } else {
    data.frame(from = character(0), to = character(0), setting = character(0),
               previous = character(0), current = character(0),
               stringsAsFactors = FALSE)
  }

  comparable <- !any(pair_summary$settings_changed)

  out <- list(
    transitions = transitions,
    summary = pair_summary,
    settings_changes = settings_changes,
    comparable = comparable,
    # Whether the panel size was part of the comparison at all.
    panel_compared = .criterion_depends_on_panel(rounds[[1]]),
    labels = labels,
    id_col = id_col,
    workflow = .workflow_name(rounds[[1]]),
    n_rounds = length(rounds)
  )
  class(out) <- "contentvalid_rounds"
  out
}

#' @export
print.contentvalid_rounds <- function(x, ...) {
  cat("contentvalidR comparison across pretest rounds\n")
  cat(strrep("-", 46), "\n", sep = "")
  cat("Workflow: ", x$workflow, " | Rounds: ", x$n_rounds,
      " | Units compared: ", nrow(x$transitions), "\n", sep = "")

  # The verdict first: how many units ended somewhere other than they began.
  change <- x$transitions$change
  moved <- sum(change %in% c("Strengthened", "Weakened", "Changed"))
  both <- sum(change %in% c("Strengthened", "Weakened", "Changed", "Unchanged"))
  cat("\n")
  .say(sprintf("%d of %s in both the first and last round changed status%s.",
               moved, .n_noun(both, "unit"),
               if (moved > 0L) {
                 sprintf(" (%d stronger, %d weaker%s)",
                         sum(change %in% "Strengthened"),
                         sum(change %in% "Weakened"),
                         if (any(change %in% "Changed")) {
                           sprintf(", %d otherwise", sum(change %in% "Changed"))
                         } else {
                           ""
                         })
               } else {
                 ""
               }))

  if (!x$comparable) {
    size <- x$settings_changes$setting == "panel size"
    cat("\n!! The rounds were not analyzed under the same decision rule.\n")
    size_text <- paste(
      "The panel changed size, and the criterion an item must meet depends",
      "on the number of judges. A change in status may reflect the changed",
      "criterion rather than changed evidence, so compare each round's index",
      "values before reporting a change as progress."
    )
    if (all(size)) {
      .say(size_text)
    } else {
      .say("A change in status may reflect the changed rule rather than",
           "changed evidence. Re-analyze the earlier round under the current",
           "settings before reporting any change as progress.")
      # Re-analysis cannot undo a changed panel, so that part is said too.
      if (any(size)) .say(size_text)
    }
    cat("\nWhat differs\n")
    .print_table(x$settings_changes)
  }

  cat("\nStatus by round\n")
  .print_table(x$transitions)

  cat("\nRound-to-round summary\n")
  s <- x$summary
  .print_table(data.frame(
    from = s$from, to = s$to, compared = s$n_compared,
    unchanged = s$n_unchanged, stronger = s$n_strengthened,
    weaker = s$n_weakened, added = s$n_added, removed = s$n_removed,
    `same rule` = ifelse(s$settings_changed, "no", "yes"),
    stringsAsFactors = FALSE, check.names = FALSE
  ))

  if (x$comparable) {
    cat("\n")
    # The panel size is named only where it was compared. An object from an
    # earlier version has no such field; it compared the settings only.
    .say(if (isTRUE(x$panel_compared)) {
      "The settings and the panel size were the same in every round,"
    } else {
      "The settings were the same in every round,"
    }, "so these transitions can be read as changes in evidence.")
  }

  cat("\n")
  .say("A status change means the evidence crossed a criterion, not that an",
       "item improved by a measurable amount. An item sitting near a boundary",
       "can move on a very small change. Read transitions alongside each",
       "round's index values.")
  invisible(x)
}

#' @export
summary.contentvalid_rounds <- function(object, ...) {
  t <- object$transitions
  out <- list(
    workflow = object$workflow,
    n_rounds = object$n_rounds,
    labels = object$labels,
    n_units = nrow(t),
    comparable = object$comparable,
    changed = t[!t$change %in% c("Unchanged", NA_character_), , drop = FALSE],
    summary = object$summary,
    settings_changes = object$settings_changes
  )
  class(out) <- "summary.contentvalid_rounds"
  out
}

#' @export
print.summary.contentvalid_rounds <- function(x, ...) {
  cat("Summary: comparison across pretest rounds\n")
  cat(strrep("-", 41), "\n", sep = "")
  cat("Workflow: ", x$workflow, " | Rounds: ", x$n_rounds, " | Units: ",
      x$n_units, "\n", sep = "")
  cat("Comparable across rounds: ", if (x$comparable) "yes" else "no", "\n",
      sep = "")

  if (!x$comparable) {
    cat("\nWhat differs between rounds\n")
    .print_table(x$settings_changes)
  }

  if (nrow(x$changed)) {
    cat("\nUnits whose status changed\n")
    .print_table(x$changed)
  } else {
    cat("\nNo unit changed status between the first and last round.\n")
  }
  invisible(x)
}

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

.settings_diff <- function(a, b) {
  keys <- union(names(a), names(b))
  keys <- setdiff(keys, "method")
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
#' comparing the `settings` of each round alongside its results, and flagging
#' rounds whose analysis settings differ.
#'
#' @param ... Two or more fitted workflow objects, in round order. All must come
#'   from the same workflow, since status labels from different workflows rest
#'   on different criteria and are not comparable.
#' @param labels Optional round labels. Defaults to `Round 1`, `Round 2`, and so
#'   on, or to the names supplied in `...`.
#'
#' @return An object of class `contentvalid_rounds`, a list containing:
#'   \describe{
#'     \item{transitions}{One row per unit, with its status in each round and
#'       the direction of any change.}
#'     \item{summary}{Counts of stable, improved, weakened, added, and removed
#'       units for each consecutive pair of rounds.}
#'     \item{settings_changes}{Analysis settings that differ between consecutive
#'       rounds, which is the audit trail for whether a status change can be
#'       read as an evidence change at all.}
#'     \item{comparable}{`FALSE` when any consecutive pair differs in settings.}
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
#' and a status change may reflect only that. Re-analyze the earlier round under
#' the current settings before reporting a change as progress.
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
  if (anyDuplicated(labels)) {
    stop("`labels` must be distinct.", call. = FALSE)
  }

  id_col <- .workflow_id_col(rounds[[1]])
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
  cat("Comparison across pretest rounds\n")
  cat(sprintf("Workflow: %s   Rounds: %d   Units compared: %d\n",
              x$workflow, x$n_rounds, nrow(x$transitions)))

  if (!x$comparable) {
    cat("\n!! Rounds were analyzed under different settings.\n")
    cat(strwrap(paste(
      "A change in status may reflect the changed rule rather than changed",
      "evidence. Re-analyze the earlier round under the current settings",
      "before reporting any change as progress."
    ), width = 76), sep = "\n")
    cat("\nSettings that differ\n")
    print(x$settings_changes, row.names = FALSE)
  }

  cat("\nStatus by round\n")
  print(x$transitions, row.names = FALSE)

  cat("\nRound-to-round summary\n")
  print(x$summary, row.names = FALSE)

  if (x$comparable) {
    cat(strwrap(paste(
      "\nSettings were identical across rounds, so these transitions can be",
      "read as changes in evidence."
    ), width = 76), sep = "\n")
  }

  cat(strwrap(paste(
    "\nA status change means the evidence crossed a criterion, not that an item",
    "improved by a measurable amount. An item sitting near a boundary can move",
    "on a very small change. Read transitions alongside each round's index",
    "values."
  ), width = 76), sep = "\n")
  cat("\n")
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
  cat(sprintf("Workflow: %s   Rounds: %d   Units: %d\n",
              x$workflow, x$n_rounds, x$n_units))
  cat(sprintf("Comparable across rounds: %s\n", if (x$comparable) "yes" else "no"))

  if (!x$comparable) {
    cat("\nSettings that differ between rounds\n")
    print(x$settings_changes, row.names = FALSE)
  }

  if (nrow(x$changed)) {
    cat("\nUnits whose status changed\n")
    print(x$changed, row.names = FALSE)
  } else {
    cat("\nNo unit changed status between the first and last round.\n")
  }
  invisible(x)
}

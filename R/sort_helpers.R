# Internal helpers for item-sort workflows ---------------------------------

.prepare_sort_assignments <- function(assignments,
                                      item_col,
                                      rater_col,
                                      assigned_col,
                                      target_col) {
  if (!is.data.frame(assignments)) {
    stop("`assignments` must be a data.frame.", call. = FALSE)
  }

  if (nrow(assignments) < 1L) {
    stop("`assignments` must contain at least one response row.", call. = FALSE)
  }

  needed <- c(item_col, rater_col, assigned_col, target_col)
  missing_cols <- setdiff(needed, names(assignments))
  if (length(missing_cols) > 0L) {
    stop(
      "`assignments` is missing required column(s): ",
      paste(missing_cols, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  d <- assignments[, needed, drop = FALSE]
  names(d) <- c("item", "rater", "assigned", "target")

  if (anyNA(d$item)) {
    stop("`item` identifiers cannot be missing.", call. = FALSE)
  }
  if (anyNA(d$rater)) {
    stop("`rater` identifiers cannot be missing.", call. = FALSE)
  }
  if (anyNA(d$target)) {
    stop("`target_construct` cannot be missing.", call. = FALSE)
  }

  dup <- duplicated(d[c("item", "rater")])
  if (any(dup)) {
    bad <- unique(d$item[dup])
    stop(
      "Each item-rater pair must appear only once. Duplicate response(s) found for item(s): ",
      paste(bad, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  by_item_target <- split(d$target, d$item, drop = TRUE)
  inconsistent <- names(by_item_target)[vapply(
    by_item_target,
    function(x) length(unique(x)) != 1L,
    logical(1)
  )]
  if (length(inconsistent) > 0L) {
    stop(
      "Each item must map to exactly one target construct. Inconsistent target(s) found for item(s): ",
      paste(inconsistent, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  d
}

.critical_target_count <- function(N, p0 = 0.5, alpha = 0.05) {
  if (length(N) != 1L || is.na(N) || N < 1 || N != floor(N)) {
    stop("`N` must be a positive integer.", call. = FALSE)
  }
  if (length(p0) != 1L || is.na(p0) || p0 <= 0 || p0 >= 1) {
    stop("`p0` must be a single probability strictly between 0 and 1.", call. = FALSE)
  }
  if (length(alpha) != 1L || is.na(alpha) || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be a single probability strictly between 0 and 1.", call. = FALSE)
  }

  candidates <- seq.int(0L, N)
  tail_p <- stats::pbinom(candidates - 1L, size = N, prob = p0, lower.tail = FALSE)
  passing <- candidates[tail_p <= alpha]
  if (length(passing) == 0L) NA_integer_ else min(passing)
}

.signed_phi <- function(tp, tn, fp, fn) {
  denom <- sqrt((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn))
  if (denom == 0) return(NA_real_)
  (tp * tn - fp * fn) / denom
}

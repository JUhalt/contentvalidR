# Internal helpers for item-sort workflows ---------------------------------

.prepare_sort_assignments <- function(assignments,
                                      item_col,
                                      rater_col,
                                      assigned_col,
                                      target_col) {
  .validate_column_names(item_col, rater_col, assigned_col, target_col)

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

  .validate_labels(d$item, "item")
  .validate_labels(d$rater, "rater")
  .validate_labels(d$target, "target_construct")
  .validate_labels(d$assigned, "assigned_construct", allow_na = TRUE)

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
  if (!is.numeric(N) || length(N) != 1L || !is.finite(N) || N < 1 || N != floor(N)) {
    stop("`N` must be a positive finite integer.", call. = FALSE)
  }
  if (!is.numeric(p0) || length(p0) != 1L || !is.finite(p0) || p0 <= 0 || p0 >= 1) {
    stop("`p0` must be one finite probability strictly between 0 and 1.", call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be one finite probability strictly between 0 and 1.", call. = FALSE)
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

# Internal plotting helpers -------------------------------------------------

.map_scale_label_y <- function(x,
                               y,
                               base_offset = -0.06,
                               cluster_gap = 0.055,
                               x_tolerance = 0.06,
                               y_tolerance = 0.10,
                               limits = c(-0.94, 0.94)) {
  if (length(x) != length(y)) {
    stop("`x` and `y` must have the same length.", call. = FALSE)
  }
  if (length(y) == 0L) return(numeric(0))

  out <- y + base_offset
  ok <- is.finite(x) & is.finite(y)
  idx <- which(ok)
  if (length(idx) > 1L) {
    # Build proximity components so labels for nearby scale means are
    # deterministically staggered instead of printed on top of one another.
    adj <- outer(x[idx], x[idx], function(a, b) abs(a - b) <= x_tolerance) &
      outer(y[idx], y[idx], function(a, b) abs(a - b) <= y_tolerance)
    diag(adj) <- TRUE

    seen <- rep(FALSE, length(idx))
    for (start in seq_along(idx)) {
      if (seen[start]) next
      component <- integer(0)
      frontier <- start
      while (length(frontier)) {
        current <- frontier[1]
        frontier <- frontier[-1]
        if (seen[current]) next
        seen[current] <- TRUE
        component <- c(component, current)
        neighbours <- which(adj[current, ] & !seen)
        frontier <- unique(c(frontier, neighbours))
      }

      if (length(component) > 1L) {
        original <- idx[component]
        # Stable ordering keeps the same targets in the same relative label
        # positions across devices and repeated plots.
        ord <- order(x[original], y[original], original)
        original <- original[ord]
        offsets <- (seq_along(original) - (length(original) + 1) / 2) * cluster_gap
        center <- mean(y[original]) + base_offset
        out[original] <- center + offsets
      }
    }
  }

  pmin(limits[2], pmax(limits[1], out))
}

.critical_psa_curve <- function(N, p0 = 0.5, alpha = 0.05) {
  N <- as.integer(N)
  N_full <- seq.int(min(N), max(N))
  critical <- vapply(
    N_full,
    .critical_target_count,
    integer(1),
    p0 = p0,
    alpha = alpha
  )
  data.frame(
    N = N_full,
    critical_n_target = critical,
    minimum_observed_psa = critical / N_full,
    row.names = NULL
  )
}

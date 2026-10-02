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

  # Labels are compared as text. A construct coded as a number would index a
  # table of counts by position, two factors with different levels cannot be
  # compared at all, and a stray space would split one construct into two.
  item_order <- if (is.factor(d$item)) {
    .as_label(levels(droplevels(d$item)))
  } else {
    unique(.as_label(d$item))
  }
  d$item <- .as_label(d$item)
  d$rater <- .as_label(d$rater)
  d$assigned <- .as_label(d$assigned)
  d$target <- .as_label(d$target)

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

  # Items keep the order of the data (or of a factor's levels), so numbered
  # items are not rearranged as text (Q1, Q10, Q2).
  attr(d, "item_order") <- unique(item_order)
  d
}

# A label as text, whatever it was stored as. A number is written without
# scientific notation, so the integer 100000 and the double 1e5 are one label,
# and one value at a time, so 1 is "1" whether or not 2.5 appears beside it.
# Missing values, NaN included, stay missing. Leading and trailing whitespace
# of any kind, non-breaking spaces included, is removed.
.as_label <- function(x) {
  missing <- is.na(x)
  out <- if (is.numeric(x)) {
    vapply(x, function(v) {
      format(v, scientific = FALSE, trim = TRUE, digits = 15, decimal.mark = ".")
    }, character(1), USE.NAMES = FALSE)
  } else {
    as.character(x)
  }
  out <- trimws(out, whitespace = "[\\h\\v]")
  out[missing] <- NA_character_
  out
}

# Splits prepared assignments by item, in the order the items were given.
.split_by_item <- function(d) {
  split(d, factor(d$item, levels = attr(d, "item_order")), drop = TRUE)
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

# "4 or fewer judges": if no count can reach alpha with n judges, none can
# with fewer, because the smallest attainable p value is p0^n.
.or_fewer_judges <- function(n) {
  if (n <= 1L) "1 judge" else paste(n, "or fewer judges")
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

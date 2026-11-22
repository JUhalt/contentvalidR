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
  # read.csv() reads a judge's blank cell as "", not NA, so the message says
  # how to code a skipped item rather than leaving the user to guess.
  .validate_labels(
    d$assigned, "assigned_construct", allow_na = TRUE,
    empty_hint = paste0("Code an item a judge did not sort as NA, for ",
                        "example read.csv(file, na.strings = c(\"\", \"NA\")).")
  )

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

  .check_target_coding(d, assigned_col, target_col)

  # Items keep the order of the data (or of a factor's levels), so numbered
  # items are not rearranged as text (Q1, Q10, Q2).
  attr(d, "item_order") <- unique(item_order)
  d
}

# Target and assigned labels are compared as text, so two columns coded
# differently ("A" and "a", or 1 and "1.0") match nowhere: every target count
# is 0, and every item is reviewed for a reason that is not in the data. A
# target label that never appears among the assignments, but matches one
# ignoring case or as a number, is that mistake, so it stops. When not one
# assignment equals its item's target, the coding may differ in some other
# way (numbers against letters), or the judges may have rejected every
# target, so it warns.
.check_target_coding <- function(d, assigned_col, target_col) {
  valid <- !is.na(d$assigned)
  if (!any(valid)) return(invisible(NULL))
  assigned <- unique(d$assigned[valid])
  absent <- setdiff(unique(d$target), assigned)
  if (length(absent)) {
    assigned_num <- suppressWarnings(as.numeric(assigned))
    near <- vapply(absent, function(t) {
      t_num <- suppressWarnings(as.numeric(t))
      any(tolower(assigned) == tolower(t)) ||
        (!is.na(t_num) && any(!is.na(assigned_num) & assigned_num == t_num))
    }, logical(1))
    if (any(near)) {
      stop(sprintf(
        paste0("Target construct(s) %s never appear in `%s`, which uses %s. ",
               "Code both columns the same way."),
        .list_some(absent[near], 10L), assigned_col, .list_some(assigned, 10L)
      ), call. = FALSE)
    }
  }
  if (!any(d$assigned[valid] == d$target[valid])) {
    if (!isTRUE(.cv_state$quiet_target_check)) {
      warning(sprintf(
        paste0("Not one assignment in `%s` equals its item's `%s`, so every ",
               "item's target count is 0. Check that both columns code the ",
               "constructs the same way."),
        assigned_col, target_col
      ), call. = FALSE)
    }
  }
  invisible(NULL)
}

# sort_validity() prepares the same assignments through compute_psa(),
# compute_csv() and its own call, so it runs the first two without the
# warning above, which its own call then gives once.
.without_target_warning <- function(code) {
  old <- .cv_state$quiet_target_check
  .cv_state$quiet_target_check <- TRUE
  on.exit(.cv_state$quiet_target_check <- old, add = TRUE)
  code
}

# A label as text, whatever it was stored as. A number is written without
# scientific notation, so the integer 100000 and the double 1e5 are one label,
# and one value at a time, so 1 is "1" whether or not 2.5 appears beside it.
# Missing values, NaN included, stay missing. Leading and trailing whitespace
# of any kind, non-breaking spaces included, is removed.
.as_label <- function(x) {
  missing <- is.na(x)
  out <- if (is.numeric(x)) {
    # Each distinct value is formatted once and mapped back: a column of
    # rater numbers repeats a few values many thousands of times.
    u <- unique(x)
    txt <- vapply(u, function(v) {
      format(v, scientific = FALSE, trim = TRUE, digits = 15, decimal.mark = ".")
    }, character(1), USE.NAMES = FALSE)
    txt[match(x, u)]
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

# The fewest target assignments whose upper-tail probability is at or below
# alpha, the rule csv_binom_test() decides by: a p equal to alpha meets the
# criterion. Anderson and Gerbing's critical count (.ag_critical_count())
# asks for a tail below alpha, as their Equation 5 does. The two differ only
# when a tail probability equals alpha exactly, which never happens at
# p0 = .5 and alpha = .05, where every tail probability is a multiple of
# 1 / 2^N.
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
  # Doubles, because the product of four integer margins overflows past
  # about 430 items.
  tp <- as.numeric(tp); tn <- as.numeric(tn)
  fp <- as.numeric(fp); fn <- as.numeric(fn)
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
      # A label joins the frontier only while unseen, once, and is seen
      # only when it leaves, so every label taken from it is unseen.
      while (length(frontier)) {
        current <- frontier[1]
        frontier <- frontier[-1]
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

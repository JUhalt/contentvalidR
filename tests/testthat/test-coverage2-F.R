# Tests for the construct-rating helpers, rating_validity(), anova_content()
# and the Q-factor comparator: the overflow refusal in anova_content() and
# the branches covr 4.0.0 still found no test running. They are grouped by
# the function they exercise.

# ---------------------------------------------------------------------------
# anova_content(): ratings whose sums of squares overflow
# ---------------------------------------------------------------------------

# One item rated by six judges against three definitions, A at 5, B at 2 and
# C at 1 in units of `unit`, with each judge's ratings moved by a different
# number of tenths of a unit so the profiles are not parallel.
scaled_item <- function(unit) {
  d <- expand.grid(item = "I1", rater = 1:6, construct = c("A", "B", "C"),
                   stringsAsFactors = FALSE)
  d$target_construct <- "A"
  d$rating <- rep(c(5, 2, 1), each = 6) * unit +
    c(0:5, 5:0, 1, 0, 2, 0, 3, 1) * unit / 10
  d
}

test_that("ratings whose sums of squares overflow are refused, naming them", {
  msg <- paste("The ratings of item 'I1' are too far apart to analyze: their",
               "sums of squares overflow double precision. Rescale them, for",
               "example to the units of the rating scale.")
  # The input of the report: squares near 1e308 and beyond. The
  # within-judge test used to stop with "missing value where TRUE/FALSE
  # needed".
  d <- expand.grid(item = "I1", rater = 1:6, construct = c("A", "B", "C"),
                   stringsAsFactors = FALSE)
  d$target_construct <- "A"
  d$rating <- rep(c(5, 2, 1), each = 6) * 1e154 + rep(0:5, 3) * 1e153
  expect_error(anova_content(d), msg, fixed = TRUE)
  expect_error(anova_content(scaled_item(1e160)), msg, fixed = TRUE)
  # The between-judge test used to return an F of NaN for the same ratings.
  between <- scaled_item(1e160)
  between$rater <- paste0(between$rater, between$construct)
  expect_error(anova_content(between), msg, fixed = TRUE)
  # Short of overflow the omnibus test is computed, and matches the same
  # ratings in ordinary units.
  big <- anova_content(scaled_item(1e153))
  small <- anova_content(scaled_item(1))
  expect_equal(big$F, small$F)
  expect_equal(big$p, small$p)
  expect_equal(big$partial_eta2, small$partial_eta2)
})

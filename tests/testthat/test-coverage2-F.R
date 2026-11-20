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

# The package's construct-rating example: six items, two per target
# construct A, B and C, rated by 24 judges against all three definitions.
rating_example <- function() {
  utils::read.csv(system.file("extdata", "rating_example.csv",
                              package = "contentvalidR"),
                  stringsAsFactors = FALSE)
}

# A printout as one line with single spaces, so a phrase can be matched
# wherever the console width wraps it.
one_line <- function(x) {
  gsub("\\s+", " ", paste(utils::capture.output(print(x)), collapse = " "))
}

# ---------------------------------------------------------------------------
# Rating-scale checks used by htc(), htd() and rating_validity()
# ---------------------------------------------------------------------------

test_that("endpoints off whole numbers in opposite directions are refused", {
  rat <- rating_example()
  # Each endpoint alone is within rounding of a whole number, so the
  # endpoint check passes it, and the run stops later, at the ratings.
  expect_error(
    rating_validity(rat, scale_min = 1 + 1e-8, scale_max = 5),
    "Observed ratings must fall between `scale_min` and `scale_max`.",
    fixed = TRUE
  )
  # Together the two errors leave 5 - 2e-8 anchors, which is not a whole
  # number of anchors.
  msg <- paste("The Hinkin-Tracey indices require equally spaced integer",
               "anchors (for example, 1 to 5 or 1 to 7).")
  expect_error(rating_validity(rat, scale_min = 1 + 1e-8,
                               scale_max = 5 - 1e-8), msg, fixed = TRUE)
  expect_error(htc(rat, scale_min = 1 + 1e-8, scale_max = 5 - 1e-8), msg,
               fixed = TRUE)
})

# ---------------------------------------------------------------------------
# .gg_epsilon(), the Greenhouse-Geisser epsilon of .rm_anova_oneway()
# ---------------------------------------------------------------------------

test_that("the epsilon helper gives NA for fewer than two judges or columns", {
  gg <- contentvalidR:::.gg_epsilon
  expect_identical(gg(matrix(c(4, 5, 3, 4), ncol = 1)), NA_real_)
  expect_identical(gg(matrix(c(4, 2, 1), nrow = 1)), NA_real_)
  # Two columns always give 1, the only value epsilon can take there.
  expect_identical(gg(cbind(c(4, 5, 3), c(2, 2, 1))), 1)
})

test_that("the epsilon helper gives NA when a covariance is missing", {
  y <- cbind(c(4, 5, NA, 4), c(2, 2, 1, 3), c(1, 2, 1, 1))
  expect_true(anyNA(stats::cov(y)))
  expect_identical(contentvalidR:::.gg_epsilon(y), NA_real_)
})

test_that("the epsilon helper gives NA for parallel judge profiles", {
  # Every column is the first plus a constant, so the double-centered
  # covariance matrix is exactly zero (each variance is 1, and k = 4 keeps
  # the centering weights exact) and epsilon would be 0 / 0.
  y <- cbind(1:3, 2:4, 3:5, 5:7)
  expect_identical(unname(stats::cov(y)), matrix(1, 4, 4))
  expect_identical(contentvalidR:::.gg_epsilon(y), NA_real_)
})

# ---------------------------------------------------------------------------
# .rating_scale_summary(): the definition counts behind the caution
# ---------------------------------------------------------------------------

# The example with target B's items rated against A and B only.
two_definitions_for_b <- function() {
  rat <- rating_example()
  rating_validity(rat[!(rat$target_construct == "B" & rat$construct == "C"), ],
                  scale_min = 1, scale_max = 5)
}

test_that("the scale summary without definition counts adds no caution", {
  fit <- two_definitions_for_b()
  caution <- "items here were rated against 2"
  # The workflow passes the counts by target, and B gets the caution.
  expect_identical(fit$scale_summary$n_definitions, c(3L, 2L, 3L))
  expect_identical(grepl(caution, fit$scale_summary$evidence, fixed = TRUE),
                   c(FALSE, TRUE, FALSE))
  # Called without counts, the summary records none and cautions no scale.
  bare <- contentvalidR:::.rating_scale_summary(fit$results)
  expect_identical(bare$n_definitions, rep(NA_integer_, 3))
  expect_false(any(grepl("These bands come from tasks", bare$evidence,
                         fixed = TRUE)))
  # The scale means and bands do not depend on the counts.
  keep <- c("target", "mean_htc", "htc_strength", "mean_htd", "htd_strength")
  expect_identical(bare[keep], fit$scale_summary[keep])
})

test_that("one unnamed definition count applies to every target scale", {
  fit <- two_definitions_for_b()
  one <- contentvalidR:::.rating_scale_summary(fit$results, n_definitions = 2)
  expect_identical(one$n_definitions, rep(2L, 3))
  expect_true(all(grepl("items here were rated against 2", one$evidence,
                        fixed = TRUE)))
})

# ---------------------------------------------------------------------------
# print.contentvalid_rating(): the benchmark set
# ---------------------------------------------------------------------------

test_that("a benchmark set the print does not know is shown as stored", {
  fit <- rating_validity(rating_example())
  expect_identical(fit$scale_summary$benchmark_set, rep("overall", 3))
  expect_match(one_line(fit),
               "Benchmark set: Overall (not correlation-normed)", fixed = TRUE)
  # A code edited into the object has no label, so its code is printed.
  edited <- fit
  edited$scale_summary$benchmark_set <- "custom norms"
  out <- one_line(edited)
  expect_match(out, "Benchmark set: custom norms", fixed = TRUE)
  expect_false(grepl("Overall (not correlation-normed)", out, fixed = TRUE))
  # A missing set is printed as missing rather than stopping the print.
  edited$scale_summary$benchmark_set <- NA_character_
  expect_match(one_line(edited), "Benchmark set: NA", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# .rating_profile_layout(), the profile view of plot.contentvalid_rating()
# ---------------------------------------------------------------------------

test_that("a profile without complete-judge means draws the target mean", {
  rat <- rating_example()
  # Judge 1 leaves out item A1's rating against B, so A1's mean over the
  # judges with complete ratings differs from its mean over every rating.
  rat$rating[rat$rater == 1 & rat$item == "A1" & rat$construct == "B"] <- NA
  r <- rating_validity(rat)$results
  a1 <- r$item == "A1"
  expect_false(isTRUE(all.equal(r$target_mean_complete[a1],
                                r$target_mean[a1])))
  lay <- contentvalidR:::.rating_profile_layout(r)
  expect_identical(lay$target, r$target_mean_complete)
  # Without the column, the target end of each gap is the mean over every
  # target rating.
  old <- r
  old$target_mean_complete <- NULL
  old_lay <- contentvalidR:::.rating_profile_layout(old)
  expect_identical(old_lay$target, r$target_mean)
  expect_identical(old_lay$both, lay$both)
})

# ---------------------------------------------------------------------------
# .parallel_eigen(), the parallel analysis of qfactor_content()
# ---------------------------------------------------------------------------

test_that("parallel analysis stops when no simulated correlation is usable", {
  # The second item has no rating, so no simulated correlation with it is
  # defined and no simulation can be kept.
  mat <- cbind(I1 = c(4, 2, 5), I2 = NA_real_)
  expect_error(
    contentvalidR:::.parallel_eigen(mat, n_iter = 5L, seed = 1),
    paste("Parallel analysis could not simulate usable correlation",
          "matrices; supply `k_factors` or provide more complete ratings."),
    fixed = TRUE
  )
})

test_that("a scale with more anchors than R can count is refused", {
  # 1 to 1e10 is 1e10 anchors, past the largest integer R holds. It used to
  # be cut to NA and fail with "missing value where TRUE/FALSE needed".
  expect_error(contentvalidR:::.validate_rating_scale(1, 1e10),
               "more anchors than R can count", fixed = TRUE)
  expect_identical(contentvalidR:::.validate_rating_scale(1, 7), 7L)
})

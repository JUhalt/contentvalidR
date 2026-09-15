# Worked example from Krippendorff (2011), "Computing Krippendorff's
# Alpha-Reliability", sections C and D: 4 observers by 12 units, 7 values missing.
krippendorff_example <- function() {
  rbind(
    A = c(1, 2, 3, 3, 2, 1, 4, 1, 2, NA, NA, NA),
    B = c(1, 2, 3, 3, 2, 2, 4, 1, 2, 5, NA, 3),
    C = c(NA, 3, 3, 3, 2, 3, 4, 2, 2, 5, 1, NA),
    D = c(1, 2, 3, 3, 2, 4, 4, 1, 2, 5, 1, NA)
  )
}

test_that("the coincidence matrix matches Krippendorff (2011) entry by entry", {
  cm <- contentvalidR:::.coincidence_matrix(krippendorff_example())
  expected <- matrix(c(
    7,   4/3, 1/3, 1/3, 0,
    4/3, 10,  4/3, 1/3, 0,
    1/3, 4/3, 8,   1/3, 0,
    1/3, 1/3, 1/3, 4,   0,
    0,   0,   0,   0,   3
  ), nrow = 5, byrow = TRUE)

  expect_equal(unname(cm$o), expected, tolerance = 1e-12)
  expect_equal(unname(rowSums(cm$o)), c(9, 13, 10, 5, 3))
  expect_equal(sum(cm$o), 40)
})

test_that("a unit with a single value is excluded from pairing", {
  cm <- contentvalidR:::.coincidence_matrix(krippendorff_example())
  # Unit 12 holds one value, so 11 of 12 units contribute.
  expect_equal(cm$n_units, 11L)
  # 8 units with four values (6 pairs each), 2 with three (3 each), 1 with two.
  expect_equal(cm$n_pairs, 55)
})

test_that("alpha reproduces the published values at each measurement level", {
  X <- krippendorff_example()
  published <- c(nominal = 0.743, ordinal = 0.815, interval = 0.849)
  for (lv in names(published)) {
    est <- contentvalidR:::.krippendorff_alpha(X, lv)$estimate
    expect_equal(round(est, 3), published[[lv]], info = lv)
  }
})

test_that("alpha agrees with irr::kripp.alpha to numerical precision", {
  skip_if_not_installed("irr")
  X <- krippendorff_example()
  for (lv in c("nominal", "ordinal", "interval")) {
    ours <- contentvalidR:::.krippendorff_alpha(X, lv)$estimate
    ref <- irr::kripp.alpha(X, lv)$value
    expect_equal(ours, ref, tolerance = 1e-10, info = lv)
  }

  set.seed(31)
  random <- matrix(sample(c(1:4, NA), 6 * 15, replace = TRUE,
                          prob = c(0.2, 0.2, 0.25, 0.25, 0.1)), nrow = 6)
  for (lv in c("nominal", "ordinal", "interval")) {
    expect_equal(contentvalidR:::.krippendorff_alpha(random, lv)$estimate,
                 irr::kripp.alpha(random, lv)$value, tolerance = 1e-10, info = lv)
  }
})

test_that("the ordinal difference function matches the published table", {
  # Krippendorff (2011) uses frequencies 9, 13, 10, 5, 0, 3 for six ranks, with
  # one unused rank to show it does not matter.
  d <- contentvalidR:::.alpha_delta(1:6, c(9, 13, 10, 5, 0, 3), "ordinal")
  expect_equal(d[1, 2], 11^2)
  expect_equal(d[1, 3], 22.5^2)
  expect_equal(d[4, 6], 4^2)
  expect_equal(d[2, 4], 19^2)
  expect_equal(diag(d), rep(0, 6))
  expect_true(isSymmetric(d))
})

test_that("perfect agreement with varied values gives alpha of 1", {
  X <- rbind(c(1, 2, 3, 4), c(1, 2, 3, 4), c(1, 2, 3, 4))
  for (lv in c("nominal", "ordinal", "interval")) {
    expect_equal(contentvalidR:::.krippendorff_alpha(X, lv)$estimate, 1, info = lv)
  }
})

test_that("alpha is undefined, not zero, when no rating varies", {
  X <- matrix(4, nrow = 5, ncol = 6)
  expect_true(is.na(contentvalidR:::.krippendorff_alpha(X, "ordinal")$estimate))
})

test_that("a high-agreement panel can still produce a low alpha", {
  # Nearly every rating is 4, and the few disagreements are scattered. Raw
  # agreement is high, but expected disagreement is tiny, so alpha is low.
  # The package output has to explain this rather than let it read as a poor panel.
  X <- matrix(4, nrow = 6, ncol = 10)
  X[1, 1] <- 3
  X[2, 5] <- 3
  X[3, 9] <- 3
  pct_identical <- mean(X == 4)
  est <- contentvalidR:::.krippendorff_alpha(X, "ordinal")$estimate
  expect_gt(pct_identical, 0.9)
  expect_lt(est, 0.2)
})

ordinal_alpha <- function(M) contentvalidR:::.krippendorff_alpha(M, "ordinal")$estimate

test_that("bootstrap intervals are reproducible and bracket the estimate", {
  X <- krippendorff_example()
  a <- contentvalidR:::.unit_bootstrap(X, ordinal_alpha, B = 500, alpha = 0.05, seed = 7)
  b <- contentvalidR:::.unit_bootstrap(X, ordinal_alpha, B = 500, alpha = 0.05, seed = 7)
  expect_identical(a, b)

  est <- ordinal_alpha(X)
  expect_lte(a$low, est)
  expect_gte(a$high, est)
  expect_lte(a$high, 1)
  expect_gt(a$n_usable, 450L)
})

test_that("a higher confidence level produces a wider interval", {
  X <- krippendorff_example()
  at_80 <- contentvalidR:::.unit_bootstrap(X, ordinal_alpha, B = 500, alpha = 0.20, seed = 3)
  at_99 <- contentvalidR:::.unit_bootstrap(X, ordinal_alpha, B = 500, alpha = 0.01, seed = 3)
  expect_lt(at_99$low, at_80$low)
  expect_gt(at_99$high, at_80$high)
})

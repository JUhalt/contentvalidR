# Long-format Q data from a profile matrix: rows are rater-construct profiles
# (three constructs per rater), columns are items.
q_long <- function(M) {
  profiles <- expand.grid(rater = seq_len(nrow(M) / 3), construct = c("A", "B", "C"),
                          KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  data.frame(
    item = rep(colnames(M), each = nrow(M)),
    rater = rep(profiles$rater, times = ncol(M)),
    construct = rep(profiles$construct, times = ncol(M)),
    rating = as.vector(M),
    stringsAsFactors = FALSE
  )
}

two_factor_data <- function() {
  set.seed(42)
  f1 <- stats::rnorm(60)
  f2 <- stats::rnorm(60)
  M <- cbind(
    vapply(1:4, function(j) 0.8 * f1 + 0.6 * stats::rnorm(60), numeric(60)),
    vapply(1:4, function(j) 0.8 * f2 + 0.6 * stats::rnorm(60), numeric(60))
  )
  colnames(M) <- paste0("I", 1:8)
  q_long(M)
}

noise_data <- function(seed = 7) {
  set.seed(seed)
  M <- matrix(stats::rnorm(60 * 20), nrow = 60, dimnames = list(NULL, paste0("I", 1:20)))
  q_long(M)
}

test_that("parallel analysis is the default and recovers a known two-factor structure", {
  fit <- qfactor_content(two_factor_data(), seed = 1)
  expect_equal(fit$retention, "parallel")
  expect_equal(fit$k, 2L)
  expect_equal(fit$k_suggested, 2L)
  expect_length(fit$parallel_eigen, 8L)
  expect_true(all(diff(fit$parallel_eigen) <= 0))

  # Items 1-4 and 5-8 separate on the two components.
  L <- abs(fit$loadings)
  expect_true(all(apply(L[1:4, ], 1, which.max) == apply(L[1:4, ], 1, which.max)[1]))
  expect_true(all(apply(L[5:8, ], 1, which.max) != apply(L[1:4, ], 1, which.max)[1]))
})

test_that("on pure noise the Kaiser rule overextracts far more than parallel analysis", {
  # Averaged over replications: on any single noise data set, Horn's mean
  # criterion can retain a component or two by chance.
  reps <- vapply(1:10, function(s) {
    d <- noise_data(seed = 100 + s)
    c(parallel = qfactor_content(d, n_iter = 50, seed = s)$k_suggested,
      kaiser = suppressMessages(qfactor_content(d, retention = "kaiser"))$k_suggested)
  }, numeric(2))
  means <- rowMeans(reps)
  expect_lt(means[["parallel"]], 2)
  expect_gt(means[["kaiser"]], means[["parallel"]] + 3)
})

test_that('"kaiser" reproduces the pre-0.3 default exactly and prints the critique', {
  d <- two_factor_data()
  expect_message(old <- qfactor_content(d, retention = "kaiser"),
                 "Zwick and Velicer \\(1986\\)")
  expect_identical(old$k, max(1L, sum(old$eigen > 1)))
  expect_null(old$parallel_eigen)
  expect_equal(old$loadings, qfactor_content(d, k_factors = old$k)$loadings)

  noise <- suppressMessages(qfactor_content(noise_data(), retention = "kaiser", method = "pa"))
  expect_identical(noise$k, max(1L, sum(noise$eigen > 1)))
})

test_that("parallel analysis is reproducible with a seed and handles missing cells", {
  d <- two_factor_data()
  a <- qfactor_content(d, seed = 9)
  b <- qfactor_content(d, seed = 9)
  expect_identical(a$parallel_eigen, b$parallel_eigen)

  d$rating[c(3, 70, 200, 333)] <- NA
  expect_equal(qfactor_content(d, seed = 9)$k, 2L)
})

test_that("a supplied k_factors overrides retention without simulation", {
  fit <- qfactor_content(two_factor_data(), k_factors = 3, retention = "kaiser")
  expect_equal(fit$retention, "fixed")
  expect_equal(fit$k, 3L)
  expect_null(fit$parallel_eigen)
  expect_silent(qfactor_content(two_factor_data(), k_factors = 1, retention = "kaiser"))
})

test_that("a rule that suggests no factors still extracts one", {
  fit <- qfactor_content(noise_data(), seed = 3)
  expect_gte(fit$k, 1L)
  expect_equal(fit$k, max(1L, fit$k_suggested))
})

test_that("retention arguments are validated", {
  d <- two_factor_data()
  expect_error(qfactor_content(d, n_iter = 0), "positive integer")
  expect_error(qfactor_content(d, n_iter = 2.5), "positive integer")
  expect_error(qfactor_content(d, seed = "a"), "NULL or one number")
  expect_error(qfactor_content(d, retention = "scree"), "should be one of")
})

example_ratings <- function() {
  r <- rbind(
    c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
    c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(4, 3, 4, 3, 1, 2),
    c(4, 4, 3, 4, 2, 2), c(3, 3, 3, 2, 1, 1)
  )
  dimnames(r) <- list(paste0("Judge", 1:8), paste0("Item", 1:6))
  r
}

# Independent recomputation of the mean squares from a two-way ANOVA, used as an
# external check rather than a restatement of the package's own arithmetic.
aov_mean_squares <- function(X) {
  long <- data.frame(
    rating = as.vector(X),
    judge = factor(rep(rownames(X), times = ncol(X))),
    item = factor(rep(colnames(X), each = nrow(X)))
  )
  tab <- summary(stats::aov(rating ~ item + judge, data = long))[[1]]
  rn <- trimws(rownames(tab))
  list(
    item = tab[rn == "item", "Mean Sq"],
    judge = tab[rn == "judge", "Mean Sq"],
    residual = tab[rn == "Residuals", "Mean Sq"]
  )
}

test_that("mean squares match an independent two-way ANOVA", {
  X <- example_ratings()
  ms <- contentvalidR:::.gtheory_mean_squares(X)
  ref <- aov_mean_squares(X)

  expect_equal(ms$ms_item, ref$item, tolerance = 1e-10)
  expect_equal(ms$ms_judge, ref$judge, tolerance = 1e-10)
  expect_equal(ms$ms_resid, ref$residual, tolerance = 1e-10)
  expect_equal(ms$df_item, 5L)
  expect_equal(ms$df_judge, 7L)
  expect_equal(ms$df_resid, 35L)
})

test_that("variance components follow the crossed random-effects estimators", {
  X <- example_ratings()
  ref <- aov_mean_squares(X)
  n_j <- nrow(X)
  n_i <- ncol(X)

  g <- gtheory_content(X)
  vc <- g$variance_components

  expect_equal(vc$variance[vc$source == "item"],
               (ref$item - ref$residual) / n_j, tolerance = 1e-10)
  expect_equal(vc$variance[vc$source == "judge"],
               (ref$judge - ref$residual) / n_i, tolerance = 1e-10)
  expect_equal(vc$variance[vc$source == "residual"], ref$residual, tolerance = 1e-10)
  expect_equal(sum(vc$percent), 100, tolerance = 1e-8)
})

test_that("generalizability and dependability coefficients use their defining formulas", {
  X <- example_ratings()
  g <- gtheory_content(X)
  vc <- g$variance_components
  vi <- vc$variance[vc$source == "item"]
  vj <- vc$variance[vc$source == "judge"]
  ve <- vc$variance[vc$source == "residual"]
  n_j <- nrow(X)

  expect_equal(g$coefficients$g_coefficient, vi / (vi + ve / n_j), tolerance = 1e-10)
  expect_equal(g$coefficients$phi_coefficient,
               vi / (vi + (vj + ve) / n_j), tolerance = 1e-10)
  # The absolute coefficient is penalized by judge variance, so it can never
  # exceed the relative coefficient.
  expect_lte(g$coefficients$phi_coefficient, g$coefficients$g_coefficient)
})

test_that("judges_needed is both sufficient and minimal", {
  X <- example_ratings()
  g <- gtheory_content(X, targets = c(0.80, 0.90, 0.95))
  vc <- g$variance_components
  vi <- vc$variance[vc$source == "item"]
  vj <- vc$variance[vc$source == "judge"]
  ve <- vc$variance[vc$source == "residual"]

  phi_at <- function(k) vi / (vi + (vj + ve) / k)
  g_at <- function(k) vi / (vi + ve / k)

  for (i in seq_len(nrow(g$judges_needed))) {
    target <- g$judges_needed$target[i]
    k_abs <- g$judges_needed$n_judges_absolute[i]
    k_rel <- g$judges_needed$n_judges_relative[i]

    expect_gte(phi_at(k_abs), target)
    expect_gte(g_at(k_rel), target)
    if (k_abs > 1L) expect_lt(phi_at(k_abs - 1L), target)
    if (k_rel > 1L) expect_lt(g_at(k_rel - 1L), target)
  }
})

test_that("decision study projections are monotonic in panel size", {
  g <- gtheory_content(example_ratings())
  d <- g$dstudy[order(g$dstudy$n_judges), ]
  expect_true(all(diff(d$phi_coefficient) >= -1e-12))
  expect_true(all(diff(d$g_coefficient) >= -1e-12))
})

test_that("a design with no item variance is reported as descriptive, not as weak generalizability", {
  # Latin square: every item mean and every judge mean is identical, so all
  # variance is residual. Phi is 0, but that must not be described as ratings
  # that "generalize moderately".
  X <- rbind(c(1, 2, 3, 4), c(2, 1, 4, 3), c(3, 4, 1, 2), c(4, 3, 2, 1))
  g <- gtheory_content(X)

  expect_equal(g$status, "Descriptive only")
  expect_equal(g$coefficients$phi_coefficient, 0)
  expect_match(g$interpretation, "did not reliably distinguish")
  # The result must not be misread as a judgement that the items are poor.
  expect_match(g$interpretation, "not a statement that the items are poor")
})

test_that("negative variance estimates are truncated but remain visible", {
  X <- rbind(c(1, 2, 3, 4), c(2, 1, 4, 3), c(3, 4, 1, 2), c(4, 3, 2, 1))
  vc <- gtheory_content(X)$variance_components
  expect_lt(vc$variance_raw[vc$source == "item"], 0)
  expect_equal(vc$variance[vc$source == "item"], 0)
})

test_that("degenerate designs report insufficient data rather than a coefficient", {
  one_judge <- gtheory_content(matrix(c(4, 3, 2), nrow = 1))
  expect_equal(one_judge$status, "Insufficient data")
  expect_true(is.na(one_judge$coefficients$phi_coefficient))

  one_item <- gtheory_content(matrix(c(4, 3, 2), ncol = 1))
  expect_equal(one_item$status, "Insufficient data")
})

test_that("constant ratings yield no partitionable variance", {
  g <- gtheory_content(matrix(3, nrow = 4, ncol = 5))
  expect_equal(g$status, "Descriptive only")
  expect_true(is.na(g$coefficients$phi_coefficient))
})

test_that("missing ratings require explicit handling", {
  X <- example_ratings()
  X[1, 1] <- NA
  expect_error(gtheory_content(X), "missing values")

  g <- gtheory_content(X, na.rm = TRUE)
  expect_equal(g$design$n_judges_dropped, 1L)
  expect_equal(g$design$n_judges, 7L)
  expect_equal(g$design$n_missing, 1L)
})

test_that("malformed inputs are rejected", {
  X <- example_ratings()
  expect_error(gtheory_content(X, targets = 0), "strictly between 0 and 1")
  expect_error(gtheory_content(X, targets = 1), "strictly between 0 and 1")
  expect_error(gtheory_content(X, targets = NA_real_), "strictly between 0 and 1")
  expect_error(gtheory_content(X, max_judges = 0), "positive integer")
  expect_error(gtheory_content(X, max_judges = 2.5), "positive integer")
  expect_error(gtheory_content(X, na.rm = NA), "TRUE or FALSE")

  Xinf <- X
  Xinf[1, 1] <- Inf
  expect_error(gtheory_content(Xinf), "infinite")

  expect_error(
    gtheory_content(matrix(letters[1:12], nrow = 3)),
    "must be numeric"
  )
})

test_that("unnamed input receives stable default labels", {
  X <- example_ratings()
  dimnames(X) <- NULL
  g <- gtheory_content(X)
  expect_equal(g$design$n_items, 6L)
  expect_equal(g$design$n_judges, 8L)
})

test_that("print output states the limits of the coefficient", {
  g <- gtheory_content(example_ratings())
  out <- paste(capture.output(print(g)), collapse = " ")
  expect_match(out, "generalization over judges only")
  expect_match(out, "not evidence that the items cover")
  expect_error(print(g, digits = -1), "nonnegative integer")
})

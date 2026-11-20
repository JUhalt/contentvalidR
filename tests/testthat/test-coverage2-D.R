# Second round of the coverage work on the judge and item-sort workflows:
# the fixes for a judge left in the facets model with no decisions, and for
# an unnamed matrix given to the facets helper.

# Judges A1-A3 rate Q1-Q3 in a cycle: each rates two of the three relevant.
# Judges C1, C3, ..., C21 and items K2, K4, ..., K20 form a chain: judge
# C(p) rates K(p - 1) a 1 and K(p + 1) a 4 where those items exist, and
# every other cell is missing.
d2_chain_panel <- function() {
  judges <- c(paste0("A", 1:3), paste0("C", seq(1, 21, 2)))
  items <- c(paste0("Q", 1:3), paste0("K", seq(2, 20, 2)))
  X <- matrix(NA_real_, length(judges), length(items),
              dimnames = list(judges, items))
  X[1:3, 1:3] <- rbind(c(4, 4, 1), c(4, 1, 4), c(1, 4, 4))
  for (p in seq(1, 21, 2)) {
    if (p > 1) X[paste0("C", p), paste0("K", p - 1)] <- 1
    if (p < 21) X[paste0("C", p), paste0("K", p + 1)] <- 4
  }
  X
}

# Trimming to a stable set ---------------------------------------------------

test_that("trimming goes on until no judge or item without variation is left", {
  X <- d2_chain_panel()
  B <- ifelse(is.na(X), NA_real_, as.numeric(X >= 3))
  dimnames(B) <- dimnames(X)
  # The chain is set aside from both ends, one judge or item a round, and
  # its middle judge, C11, loses its last items in the tenth round. It goes
  # in the eleventh, leaving the cycle of A1-A3 and Q1-Q3.
  trim <- contentvalidR:::.facets_trim_extremes(B)
  expect_identical(trim$keep_judges, rep(c(TRUE, FALSE), c(3L, 11L)))
  expect_identical(trim$keep_items, rep(c(TRUE, FALSE), c(3L, 10L)))
})

test_that("no judge without decisions is placed on the logit scale", {
  fit <- judge_validity(d2_chain_panel(), lo = 1, hi = 4, na.rm = TRUE)
  r <- fit$results
  c11 <- r$judge == "C11"
  expect_identical(r$severity_estimable, rep(c(TRUE, FALSE), c(3L, 11L)))
  expect_true(is.na(r$severity[c11]) && is.na(r$se[c11]))
  expect_identical(r$n_scored[c11], 0L)
  expect_identical(c(fit$details$facets$n_judges_dropped,
                     fit$design$n_items_dropped_from_model), c(11L, 10L))

  # The model holds only the cycle. By symmetry every fitted probability is
  # 2/3 and every judge's severity 0. With information 2/9 per decision, a
  # centred judge effect from three judges and three items has variance
  # (2/3) / (3 * 2/9) = 1, and the correction (3 - 1) / 3 scales it by 2/3.
  # glm() stops within its convergence tolerance, hence the looser check.
  expect_equal(r$severity[1:3], rep(0, 3))
  expect_equal(r$se[1:3], rep(sqrt(2 / 3), 3), tolerance = 1e-6)
  expect_equal(fit$settings$bias_correction, 2 / 3)
})

# The facets helper on an unnamed matrix -------------------------------------

test_that("facets severity fits an unnamed matrix under the default names", {
  B <- rbind(c(1, 1, 0, 1), c(1, 0, 1, 0), c(0, 1, 1, 1), c(1, 0, 0, 1))
  named <- B
  dimnames(named) <- list(paste0("Judge", 1:4), paste0("Item", 1:4))
  fs <- contentvalidR:::.facets_severity(B)
  expect_true(fs$estimable)
  expect_identical(fs$table$judge, paste0("Judge", 1:4))
  expect_identical(fs$table, contentvalidR:::.facets_severity(named)$table)
  # Judge names alone are enough as well.
  rows_only <- B
  rownames(rows_only) <- paste0("Judge", 1:4)
  expect_identical(contentvalidR:::.facets_severity(rows_only)$table,
                   fs$table)
  # The same decisions through judge_validity(), where 4 is relevant and 1
  # is not.
  fit <- judge_validity(ifelse(B == 1, 4, 1), lo = 1, hi = 4)
  expect_equal(fit$results$severity, fs$table$severity)
  expect_equal(fit$results$se, fs$table$se)
})

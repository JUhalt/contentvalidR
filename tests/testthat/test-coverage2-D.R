# Second round of the coverage work on the judge and item-sort workflows:
# the fix for an unnamed matrix given to the facets helper.

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

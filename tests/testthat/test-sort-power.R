test_that("sort_power uses exact Howard-Melloy critical counts", {
  out <- sort_power(N = 20, true_p = .70)
  expect_s3_class(out, "contentvalid_sort_power")
  expect_equal(out$table$critical_n_target, 15L)
  expect_equal(out$table$minimum_observed_psa, .75)
  expect_equal(out$table$power, stats::pbinom(14, 20, .70, lower.tail = FALSE))
})

test_that("sort_power expands N and true probability combinations", {
  out <- sort_power(N = c(20, 30), true_p = c(.60, .80))
  expect_equal(nrow(out$table), 4L)
  expect_true(all(out$table$power >= 0 & out$table$power <= 1))
  expect_output(print(out), "Exact item-sort planning analysis")
})

test_that("sort_power validates planning inputs", {
  expect_error(sort_power(N = 0, true_p = .7), "positive integers")
  expect_error(sort_power(N = 20.5, true_p = .7), "positive integers")
  expect_error(sort_power(N = 20, true_p = 1.2), "between 0 and 1")
})

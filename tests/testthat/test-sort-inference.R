test_that("Howard-Melloy exact test matches published N=20 critical count", {
  pass <- csv_binom_test(n_c = 15, N = 20)
  fail <- csv_binom_test(n_c = 14, N = 20)

  expect_equal(pass$critical_n_target, 15L)
  expect_true(pass$passes_chance)
  expect_equal(pass$decision, "significant")

  expect_equal(fail$critical_n_target, 15L)
  expect_false(fail$passes_chance)
  expect_equal(fail$decision, "n.s.")
})

test_that("exact-test critical counts match selected Howard-Melloy table values", {
  expected <- c(`5` = 5L, `8` = 7L, `10` = 9L, `12` = 10L,
                `15` = 12L, `20` = 15L, `25` = 18L, `30` = 20L,
                `40` = 26L)

  observed <- vapply(names(expected), function(n) {
    csv_binom_test(n_c = expected[[n]], N = as.integer(n))$critical_n_target
  }, integer(1))

  expect_equal(unname(observed), unname(expected))
})

test_that("csv_binom_test validates counts and probabilities", {
  expect_error(csv_binom_test(-1, 20), "between 0 and `N`")
  expect_error(csv_binom_test(21, 20), "between 0 and `N`")
  expect_error(csv_binom_test(10.5, 20), "integer")
  expect_error(csv_binom_test(10, 0), "positive integer")
  expect_error(csv_binom_test(10, 20, p0 = 1), "strictly between")
  expect_error(csv_binom_test(10, 20, alpha = 0), "strictly between")
})

test_that("sort_validity gives informative retain/review recommendations", {
  d <- data.frame(
    item = rep(c("Keep", "Review"), each = 20),
    rater = rep(1:20, 2),
    target_construct = rep("A", 40),
    assigned_construct = c(rep("A", 15), rep("B", 5),
                           rep("A", 14), rep("B", 6))
  )

  fit <- sort_validity(d)

  expect_s3_class(fit, "contentvalid_sort")
  expect_equal(fit$results$recommendation, c("Retain", "Review"))
  expect_equal(fit$results$critical_n_target, c(15L, 15L))
  expect_true(fit$results$passes_chance[1])
  expect_false(fit$results$passes_chance[2])
  expect_match(fit$results$interpretation[2], "review wording")
})

test_that("sort_validity handles an item with no usable assignments", {
  d <- data.frame(
    item = rep(c("I1", "I2"), each = 3),
    rater = rep(1:3, 2),
    target_construct = rep("A", 6),
    assigned_construct = c("A", "A", "B", NA, NA, NA)
  )
  fit <- sort_validity(d)

  expect_equal(fit$results$recommendation[fit$results$item == "I2"], "Insufficient data")
  expect_true(is.na(fit$results$p_value[fit$results$item == "I2"]))
})

test_that("print and summary methods communicate decisions", {
  d <- data.frame(
    item = rep("I1", 20),
    rater = 1:20,
    target_construct = "A",
    assigned_construct = c(rep("A", 15), rep("B", 5))
  )
  fit <- sort_validity(d)

  expect_output(print(fit), "meet the exact target-assignment criterion")
  expect_output(print(fit), "not an automatic deletion decision")
  expect_s3_class(summary(fit), "summary.contentvalid_sort")
  expect_output(print(summary(fit)), "content-validity evidence")
})

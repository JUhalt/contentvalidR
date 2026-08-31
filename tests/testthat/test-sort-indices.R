test_that("Psa and Csv reproduce simple hand calculations", {
  d <- data.frame(
    item = rep(c("I1", "I2", "I3"), each = 4),
    rater = rep(1:4, 3),
    assigned_construct = c(
      "A", "A", "A", "B",
      "B", "B", "B", "B",
      "A", "B", "C", "C"
    ),
    target_construct = rep("A", 12)
  )

  psa <- compute_psa(d)
  csv <- compute_csv(d)

  expect_equal(psa$psa, c(0.75, 0, 0.25))
  expect_equal(csv$csv, c(0.50, -1, -0.25))
  expect_equal(csv$n_other_max, c(1L, 4L, 2L))
})

test_that("Csv is -1 when all judges choose the same wrong construct", {
  d <- data.frame(
    item = "I1",
    rater = 1:5,
    assigned_construct = rep("B", 5),
    target_construct = rep("A", 5)
  )

  out <- compute_csv(d)
  expect_equal(out$n_target, 0L)
  expect_equal(out$n_other_max, 5L)
  expect_equal(out$csv, -1)
})

test_that("missing assignments use an itemwise effective denominator", {
  d <- data.frame(
    item = rep("I1", 4),
    rater = 1:4,
    assigned_construct = c("A", NA, "B", "A"),
    target_construct = rep("A", 4)
  )

  psa <- compute_psa(d)
  csv <- compute_csv(d)

  expect_equal(psa$n_total, 4L)
  expect_equal(psa$n, 3L)
  expect_equal(psa$n_missing, 1L)
  expect_equal(psa$n_target, 2L)
  expect_equal(psa$psa, 2 / 3)
  expect_equal(csv$csv, 1 / 3)
})

test_that("all missing assignments are reported rather than divided by zero", {
  d <- data.frame(
    item = rep("I1", 3),
    rater = 1:3,
    assigned_construct = c(NA, NA, NA),
    target_construct = rep("A", 3)
  )

  expect_true(is.na(compute_psa(d)$psa))
  expect_true(is.na(compute_csv(d)$csv))
})

test_that("sort data validation catches ambiguous or duplicated responses", {
  inconsistent <- data.frame(
    item = c("I1", "I1"),
    rater = 1:2,
    assigned_construct = c("A", "A"),
    target_construct = c("A", "B")
  )
  expect_error(compute_psa(inconsistent), "exactly one target construct")

  duplicate <- data.frame(
    item = c("I1", "I1"),
    rater = c(1, 1),
    assigned_construct = c("A", "B"),
    target_construct = c("A", "A")
  )
  expect_error(compute_csv(duplicate), "item-rater pair")

  missing_rater <- data.frame(
    item = "I1", rater = NA, assigned_construct = "A", target_construct = "A"
  )
  expect_error(compute_psa(missing_rater), "rater.*cannot be missing")

  missing_target <- data.frame(
    item = "I1", rater = 1, assigned_construct = "A", target_construct = NA
  )
  expect_error(compute_psa(missing_target), "target_construct.*cannot be missing")
})

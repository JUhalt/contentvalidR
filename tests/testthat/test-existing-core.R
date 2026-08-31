test_that("Aiken's V reproduces simple bounds", {
  R <- matrix(c(1, 3, 5, 5, 5, 5), nrow = 3,
              dimnames = list(NULL, c("Mixed", "Max")))
  out <- aikens_v(R, lo = 1, hi = 5)
  expect_equal(out$V, c(0.5, 1))
})

test_that("CVR reproduces its defining transformation", {
  out <- cvr(essential = c(12, 9, 6), N = 12)
  expect_equal(out$cvr, c(1, 0.5, 0))
  expect_true(out$pass[1])
})

test_that("IOC reproduces means by item and objective", {
  d <- data.frame(
    item = rep("I1", 6),
    judge = rep(1:3, 2),
    objective = rep(c("A", "B"), each = 3),
    score = c(1, 1, 0, -1, 0, 1)
  )
  out <- ioc(d)
  expect_equal(out$ioc[out$objective == "A"], 2/3)
  expect_equal(out$ioc[out$objective == "B"], 0)
})

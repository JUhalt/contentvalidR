test_that("Aiken V matches hand calculation", {
  x <- matrix(c(4, 4, 3, 2), ncol = 1, dimnames = list(NULL, "I1"))
  out <- aikens_v(x, lo = 1, hi = 4, ci = "none")
  expect_equal(out$V, ((4-1)+(4-1)+(3-1)+(2-1)) / (4 * 3))
  expect_equal(out$N, 4L)
  expect_equal(out$n_missing, 0L)
})

test_that("Aiken score interval follows Penfield-Giacobbi formula", {
  x <- matrix(c(4, 4, 3, 2), ncol = 1, dimnames = list(NULL, "I1"))
  out <- aikens_v(x, lo = 1, hi = 4, ci = "score", alpha = .05)
  V <- out$V
  n <- 4
  k <- 3
  z <- stats::qnorm(.975)
  den <- 2 * (n * k + z^2)
  root <- sqrt(4 * n * k * V * (1 - V) + z^2)
  lo <- (2 * n * k * V + z^2 - z * root) / den
  hi <- (2 * n * k * V + z^2 + z * root) / den
  expect_equal(out$ci_low, lo)
  expect_equal(out$ci_high, hi)
  expect_equal(out$ci_method, "Penfield-Giacobbi score")
})

test_that("Aiken V handles itemwise missingness explicitly", {
  x <- cbind(I1 = c(4, 4, NA, 3), I2 = c(1, 2, 3, 4))
  expect_error(aikens_v(x, lo = 1, hi = 4), "Missing ratings")
  out <- aikens_v(x, lo = 1, hi = 4, na.rm = TRUE)
  expect_equal(out$N, c(3L, 4L))
  expect_equal(out$n_missing, c(1L, 0L))
  expect_true(all(out$V >= 0 & out$V <= 1))
})

test_that("Aiken V rejects invalid scale and ratings", {
  expect_error(aikens_v(matrix(1:4, ncol = 1), lo = 5, hi = 1), "hi > lo")
  expect_error(aikens_v(matrix(c(1, 6), ncol = 1), lo = 1, hi = 5), "outside")
  expect_error(aikens_v(matrix(c("a", "b"), ncol = 1)), "numeric")
})

test_that("bootstrap Aiken intervals remain available", {
  x <- cbind(I1 = c(4, 4, 3, 3, 4), I2 = c(2, 3, 3, 4, 4))
  a <- aikens_v(x, lo = 1, hi = 4, ci = "bootstrap", B = 50, seed = 99)
  b <- aikens_v(x, lo = 1, hi = 4, ci = "bootstrap", B = 50, seed = 99)
  expect_equal(a$ci_low, b$ci_low)
  expect_equal(a$ci_high, b$ci_high)
  expect_equal(a$ci_method, rep("percentile bootstrap", 2))
})

test_that("CVR count input matches hand calculation", {
  out <- cvr(c(8, 10, 5), N = 12)
  expect_equal(out$cvr, c(1/3, 2/3, -1/6))
  expect_equal(out$N, rep(12L, 3))
  expect_equal(out$ne, c(8L, 10L, 5L))
})

test_that("CVR exact p values are binomial upper tails", {
  out <- cvr(10, N = 12)
  expect_equal(out$p_value, stats::pbinom(9, 12, .5, lower.tail = FALSE))
  expect_equal(out$pass, out$ne >= out$critical_ne)
  expect_true(out$critical_ne <= 12)
})

test_that("CVR accepts varying panel sizes", {
  out <- cvr(c(5, 7, 8), N = c(6, 9, 10))
  expect_equal(out$N, c(6L, 9L, 10L))
  expect_equal(nrow(out), 3)
  expect_true(all(is.finite(out$p_value)))
})

test_that("CVR matrix input calculates itemwise N", {
  x <- cbind(I1 = c(1,1,1,1,0), I2 = c(1,1,NA,0,0))
  expect_error(cvr(x), "Missing ratings")
  out <- cvr(x, na.rm = TRUE)
  expect_equal(out$item, c("I1", "I2"))
  expect_equal(out$N, c(5L, 4L))
  expect_equal(out$ne, c(4L, 2L))
})

test_that("CVR validates counts", {
  expect_error(cvr(c(5, 6), N = 5), "essential <= N")
  expect_error(cvr(c(2.5), N = 5), "integers")
  expect_error(cvr(c(3), N = NULL), "required")
})

test_that("IOC matches cell means", {
  d <- data.frame(
    item = rep("I1", 6), judge = rep(1:3, 2),
    objective = rep(c("A", "B"), each = 3),
    score = c(1,1,1, 0,-1,0)
  )
  out <- ioc(d)
  expect_equal(out$ioc[out$objective == "A"], 1)
  expect_equal(out$ioc[out$objective == "B"], -1/3)
  expect_equal(out$n_judges, c(3L, 3L))
})

test_that("IOC rejects duplicates and invalid scores", {
  d <- data.frame(item = "I1", judge = 1, objective = "A", score = 1)
  expect_error(ioc(rbind(d, d)), "Duplicate")
  d2 <- d
  d2$score <- 2
  expect_error(ioc(d2), "Scores must")
})

test_that("IOC handles missingness transparently", {
  d <- data.frame(
    item = rep("I1", 3), judge = 1:3, objective = "A",
    score = c(1, NA, 0)
  )
  expect_error(ioc(d), "Missing scores")
  out <- ioc(d, na.rm = TRUE)
  expect_equal(out$n_total, 3L)
  expect_equal(out$n_judges, 2L)
  expect_equal(out$n_missing, 1L)
  expect_equal(out$ioc, .5)
})

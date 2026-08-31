test_that("HTC reproduces the published transformation", {
  d <- expand.grid(item = "I1", rater = 1:6, construct = c("A", "B", "C"))
  d$rating <- c(5,4,5,4,5,4, 2,2,1,2,1,2, 3,2,2,1,2,1)
  out <- htc(d, target_map = c(I1 = "A"), scale_min = 1, scale_max = 5)
  expect_equal(out$target_mean, 4.5)
  expect_equal(out$htc, .9)
  expect_equal(out$n_target, 6L)
})

test_that("HTC shifts non-1-based integer anchors transparently", {
  d <- expand.grid(item = "I1", rater = 1:4, construct = c("A", "B"))
  d$rating <- c(4,4,4,4, 1,1,1,1)
  out <- htc(d, target_map = c(I1 = "A"), scale_min = 0, scale_max = 4)
  expect_equal(out$htc, 1)
  expect_equal(out$anchors, 5L)
})

test_that("HTD reproduces target-minus-orbiting differences", {
  d <- expand.grid(item = "I1", rater = 1:6, construct = c("A", "B", "C"))
  d$rating <- c(5,4,5,4,5,4, 2,2,1,2,1,2, 3,2,2,1,2,1)
  out <- htd(d, target_map = c(I1 = "A"), scale_min = 1, scale_max = 5)
  expect_equal(out$htd, 0.6875)
  expect_equal(out$n_complete, 6L)
  expect_equal(out$n_pairs, 12L)
  expect_equal(out$strongest_competitor, "C")
})

test_that("HTD can be negative when an orbiting construct is favored", {
  d <- expand.grid(item = "I1", rater = 1:4, construct = c("A", "B"))
  d$rating <- c(2,2,2,2, 5,5,5,5)
  out <- htd(d, target_map = c(I1 = "A"), scale_min = 1, scale_max = 5)
  expect_equal(out$htd, -0.75)
})

test_that("rating indices reject duplicate item-rater-construct rows", {
  d <- data.frame(item = c("I1", "I1"), rater = c(1,1), construct = c("A","A"), rating = c(4,5))
  expect_error(htc(d, target_map = c(I1 = "A")), "at most once")
})

test_that("rating indices validate scale endpoints and observed ratings", {
  d <- expand.grid(item = "I1", rater = 1:2, construct = c("A", "B"))
  d$rating <- c(5,4,2,2)
  expect_error(htc(d, target_map = c(I1 = "A"), scale_min = 1, scale_max = 4), "between")
  expect_error(htc(d, target_map = c(I1 = "A"), scale_min = 1, scale_max = 4.5), "integer anchor")
})

test_that("target mappings must be complete and valid", {
  d <- expand.grid(item = c("I1", "I2"), rater = 1:2, construct = c("A", "B"))
  d$rating <- 3
  expect_error(htc(d, target_map = c(I1 = "A")), "missing item")
  expect_error(htc(d, target_map = c(I1 = "C", I2 = "B")), "absent")
})


test_that("HTD refuses a between-judge design", {
  d <- data.frame(item = "I1", rater = 1:8,
                  construct = rep(c("A", "B"), each = 4),
                  rating = c(5,4,5,4,2,2,1,2))
  expect_error(htd(d, target_map = c(I1 = "A")), "requires a within-judge")
})

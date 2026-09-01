test_that("Hinkin-Tracey indices reproduce a published Study 1 mean-rating row", {
  # Hinkin & Tracey (1999), Table 2, item IS1:
  # II = 2.93, IM = 3.04, IS = 4.63, IC = 3.06 on a 1-5 scale.
  d <- expand.grid(
    item = "IS1", rater = 1:2,
    construct = c("II", "IM", "IS", "IC"),
    KEEP.OUT.ATTRS = FALSE
  )
  d$rating <- c(2.93, 2.93, 3.04, 3.04, 4.63, 4.63, 3.06, 3.06)
  d$target_construct <- "IS"

  htc_out <- htc(d, scale_min = 1, scale_max = 5)
  htd_out <- htd(d, scale_min = 1, scale_max = 5)

  expect_equal(htc_out$htc, 4.63 / 5, tolerance = 1e-12)
  expect_equal(
    htd_out$htd,
    mean(4.63 - c(2.93, 3.04, 3.06)) / 4,
    tolerance = 1e-12
  )
})

test_that("Polit-Beck-Owen 7-of-9 relevance scenario is reproduced", {
  x <- matrix(c(rep(1, 7), rep(0, 2)), ncol = 1,
              dimnames = list(NULL, "Item1"))
  out <- cvi(x)$item_level
  pc <- stats::dbinom(7, size = 9, prob = .5)
  kstar <- ((7 / 9) - pc) / (1 - pc)

  expect_equal(out$I_CVI, 7 / 9, tolerance = 1e-12)
  expect_equal(out$Pc, pc, tolerance = 1e-12)
  expect_equal(out$kappa_mod, kstar, tolerance = 1e-12)
})

test_that("Ayre-Scally exact logic gives the N=10 critical CVR boundary", {
  at_boundary <- cvr(essential = 9, N = 10)
  below <- cvr(essential = 8, N = 10)

  expect_equal(at_boundary$critical_ne, 9L)
  expect_equal(at_boundary$critical_cvr, .8, tolerance = 1e-12)
  expect_true(at_boundary$pass)
  expect_false(below$pass)
})

test_that("IOC defining mean is reproduced by a hand-worked objective cell", {
  d <- data.frame(
    item = "I1", judge = 1:5, objective = "A",
    score = c(1, 1, 1, 0, -1)
  )
  out <- ioc(d)
  expect_equal(out$ioc, .4, tolerance = 1e-12)
  expect_equal(out$n_judges, 5L)
})

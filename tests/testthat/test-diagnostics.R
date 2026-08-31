test_that("signal_detection confusion matrix has correct orientation", {
  predicted <- c(TRUE, TRUE, FALSE, FALSE)
  actual <- c(TRUE, FALSE, TRUE, FALSE)
  out <- signal_detection(predicted, actual)

  expect_equal(unname(out$confusion["Retain", "Retain"]), 1)
  expect_equal(unname(out$confusion["Retain", "Delete"]), 1)
  expect_equal(unname(out$confusion["Delete", "Retain"]), 1)
  expect_equal(unname(out$confusion["Delete", "Delete"]), 1)
  expect_equal(out$accuracy, 0.5)
  expect_equal(out$sensitivity, 0.5)
  expect_equal(out$specificity, 0.5)
  expect_equal(out$phi, 0)
})

test_that("signal_detection phi preserves direction", {
  predicted <- c(TRUE, TRUE, FALSE, FALSE)
  actual <- c(FALSE, FALSE, TRUE, TRUE)
  out <- signal_detection(predicted, actual)

  expect_equal(out$phi, -1)
  expect_equal(out$chisq, 4, tolerance = 1e-12)
})

test_that("signal_detection handles degenerate margins without fake phi", {
  out <- signal_detection(rep(TRUE, 4), c(TRUE, FALSE, TRUE, FALSE))
  expect_true(is.na(out$phi))
})

test_that("diagnostic functions validate logical vectors", {
  expect_error(signal_detection(c(1, 0), c(TRUE, FALSE)), "logical vectors")
  expect_error(signal_detection(c(TRUE, NA), c(TRUE, FALSE)), "Missing values")
  expect_error(reproducibility_phi(c(TRUE), c(TRUE, FALSE)), "same non-zero length")
})

test_that("reproducibility_phi keeps a full table and signed association", {
  sig1 <- c(TRUE, TRUE, FALSE, FALSE)
  sig2 <- c(FALSE, FALSE, TRUE, TRUE)
  out <- reproducibility_phi(sig1, sig2)

  expect_equal(dim(out$table), c(2L, 2L))
  expect_equal(out$phi, -1)
  expect_equal(out$chisq, 4, tolerance = 1e-12)
})

test_that("reproducibility table stays 2x2 when one level is absent", {
  out <- reproducibility_phi(rep(TRUE, 4), c(TRUE, FALSE, TRUE, FALSE))
  expect_equal(dim(out$table), c(2L, 2L))
  expect_true(is.na(out$phi))
})

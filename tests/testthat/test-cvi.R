test_that("CVI modified kappa uses exact chance agreement", {
  M <- matrix(
    c(
      1, 1, 1, 1,
      1, 1, 1, 0,
      1, 1, 0, 0
    ),
    nrow = 4,
    dimnames = list(NULL, c("Perfect", "ThreeOfFour", "Half"))
  )

  out <- cvi(M)
  il <- out$item_level

  expect_equal(il$A, c(4L, 3L, 2L))
  expect_equal(il$N, c(4L, 4L, 4L))
  expect_equal(il$I_CVI, c(1, 0.75, 0.5))
  expect_equal(il$Pc, c(0.0625, 0.25, 0.375))
  expect_equal(il$kappa_mod, c(1, 2/3, 0.2), tolerance = 1e-12)
  expect_equal(out$scale_level$S_CVI_Ave, 0.75)
  expect_equal(out$scale_level$S_CVI_UA, 1/3)
})

test_that("CVI missing-data policy is explicit and itemwise", {
  M <- matrix(c(1, 1, NA, 1, 0, 1), nrow = 3,
              dimnames = list(NULL, c("I1", "I2")))

  expect_error(cvi(M), "Missing ratings")

  out <- cvi(M, na.rm = TRUE)
  expect_equal(out$item_level$N, c(2L, 3L))
  expect_equal(out$item_level$A, c(2L, 2L))
  expect_equal(out$item_level$I_CVI, c(1, 2/3))
})

test_that("CVI rejects invalid coding", {
  expect_error(cvi(matrix(c(0, 1, 2, 1), nrow = 2)), "only 0/1")
  expect_error(cvi(matrix(character(), nrow = 0, ncol = 0)), "at least one judge")
})

test_that("CVI print method explains scope", {
  M <- matrix(c(1, 1, 1, 0), nrow = 2)
  out <- cvi(M)
  expect_s3_class(out, "contentvalid_cvi")
  expect_output(print(out), "chance-corrected")
  expect_output(print(out), "do not establish comprehensive content validity")
})

test_that("overall Colquitt Psa/Csv cutpoints classify deterministically", {
  expect_equal(interpret_colquitt(.91, "psa")$interpretation, "Very Strong")
  expect_equal(interpret_colquitt(.90, "psa")$interpretation, "Strong")
  expect_equal(interpret_colquitt(.72, "psa")$interpretation, "Moderate")
  expect_equal(interpret_colquitt(.50, "psa")$interpretation, "Weak")
  expect_equal(interpret_colquitt(.38, "psa")$interpretation, "Lack of")

  expect_equal(interpret_colquitt(.81, "csv")$interpretation, "Very Strong")
  expect_equal(interpret_colquitt(.80, "csv")$interpretation, "Strong")
  expect_equal(interpret_colquitt(.60, "csv")$interpretation, "Moderate")
  expect_equal(interpret_colquitt(.04, "csv")$interpretation, "Lack of")
})

test_that("correlation-conditional Colquitt norms select the expected panel", {
  expect_equal(interpret_colquitt(.70, "csv", orbiting_r = .60)$benchmark_set, "stronger")
  expect_equal(interpret_colquitt(.70, "csv", orbiting_r = .40)$benchmark_set, "moderate")
  expect_equal(interpret_colquitt(.70, "csv", orbiting_r = .20)$benchmark_set, "weaker")

  expect_equal(interpret_colquitt(.70, "csv", orbiting_r = .60)$interpretation, "Very Strong")
  expect_equal(interpret_colquitt(.70, "csv", orbiting_r = .40)$interpretation, "Strong")
  expect_equal(interpret_colquitt(.70, "csv", orbiting_r = .20)$interpretation, "Moderate")
})

test_that("rounded gaps in the published table are handled by lower cutpoints", {
  expect_equal(interpret_colquitt(.88, "csv", orbiting_r = .20)$interpretation, "Strong")
})

test_that("Colquitt interpretation is suppressed for expert judges", {
  out <- interpret_colquitt(.90, "psa", judge_type = "expert")
  expect_false(out$applicable)
  expect_true(is.na(out$interpretation))
  expect_match(out$note, "naive judges")
})

test_that("Colquitt helpers validate inputs", {
  expect_error(interpret_colquitt(".8", "psa"), "numeric")
  expect_error(interpret_colquitt(.8, "psa", orbiting_r = 2), "between -1 and 1")
  expect_error(interpret_colquitt(c(.8, .9), "psa", orbiting_r = c(.2, .3, .4)), "length 1")
  expect_equal(nrow(colquitt_benchmarks("csv")), 5L)
})

test_that("Colquitt HTC/HTD overall boundaries are encoded", {
  expect_equal(interpret_colquitt(.91, "htc")$interpretation, "Very Strong")
  expect_equal(interpret_colquitt(.90, "htc")$interpretation, "Strong")
  expect_equal(interpret_colquitt(.84, "htc")$interpretation, "Moderate")
  expect_equal(interpret_colquitt(.60, "htc")$interpretation, "Weak")
  expect_equal(interpret_colquitt(.59, "htc")$interpretation, "Lack of")

  expect_equal(interpret_colquitt(.35, "htd")$interpretation, "Very Strong")
  expect_equal(interpret_colquitt(.27, "htd")$interpretation, "Strong")
  expect_equal(interpret_colquitt(.18, "htd")$interpretation, "Moderate")
  expect_equal(interpret_colquitt(.04, "htd")$interpretation, "Weak")
  expect_equal(interpret_colquitt(.03, "htd")$interpretation, "Lack of")
})

test_that("correlation-conditioned HTC/HTD norms follow Table 5", {
  expect_equal(interpret_colquitt(.90, "htc", orbiting_r = .60)$interpretation, "Very Strong")
  expect_equal(interpret_colquitt(.90, "htc", orbiting_r = .40)$interpretation, "Strong")
  expect_equal(interpret_colquitt(.90, "htc", orbiting_r = .20)$interpretation, "Strong")

  expect_equal(interpret_colquitt(.30, "htd", orbiting_r = .60)$interpretation, "Very Strong")
  expect_equal(interpret_colquitt(.30, "htd", orbiting_r = .40)$interpretation, "Strong")
  expect_equal(interpret_colquitt(.30, "htd", orbiting_r = .20)$interpretation, "Moderate")
})

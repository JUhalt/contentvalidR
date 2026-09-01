test_that("the intended public API is exported from a clean namespace", {
  expected <- c(
    "agreement_summary",
    "aikens_v",
    "anova_content",
    "colquitt_benchmarks",
    "compute_csv",
    "compute_psa",
    "csv_binom_test",
    "cvi",
    "cvr",
    "expert_validity",
    "htc",
    "htd",
    "interpret_colquitt",
    "ioc",
    "qfactor_content",
    "rating_validity",
    "reproducibility_phi",
    "signal_detection",
    "simulate_anova_power",
    "simulate_csv_power",
    "sort_power",
    "sort_validity"
  )

  expect_setequal(getNamespaceExports("contentvalidR"), expected)
  for (nm in expected) {
    expect_true(is.function(getExportedValue("contentvalidR", nm)), info = nm)
  }
})

test_that("release-defining S3 methods are registered in the installed namespace", {
  expected_methods <- list(
    c("print", "contentvalid_sort"),
    c("summary", "contentvalid_sort"),
    c("plot", "contentvalid_sort"),
    c("print", "summary.contentvalid_sort"),
    c("print", "contentvalid_rating"),
    c("summary", "contentvalid_rating"),
    c("plot", "contentvalid_rating"),
    c("print", "summary.contentvalid_rating"),
    c("print", "contentvalid_expert"),
    c("summary", "contentvalid_expert"),
    c("plot", "contentvalid_expert"),
    c("print", "summary.contentvalid_expert"),
    c("print", "contentvalid_sort_power"),
    c("plot", "contentvalid_sort_power"),
    c("print", "contentvalid_cvi")
  )

  for (spec in expected_methods) {
    method <- getS3method(spec[[1]], spec[[2]], optional = TRUE)
    expect_true(is.function(method), info = paste(spec, collapse = "."))
  }
})

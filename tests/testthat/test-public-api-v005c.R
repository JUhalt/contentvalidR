test_that("the intended public API is exported from a clean namespace", {
  expected <- c(
    "agreement_summary",
    "aikens_v",
    "anova_content",
    "colquitt_benchmarks",
    "compare_rounds",
    "compute_csv",
    "compute_psa",
    "content_handoff",
    "content_report",
    "content_structure",
    "contentvalid_glossary",
    "csv_binom_test",
    "cvi",
    "cvr",
    "domain_validity",
    "expert_power",
    "expert_validity",
    "gtheory_content",
    "htc",
    "htd",
    "interpret_colquitt",
    "ioc",
    "judge_validity",
    "panel_agreement",
    "qfactor_content",
    "rating_validity",
    "reproducibility_phi",
    "signal_detection",
    "similarity_from_sort",
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
    c("print", "contentvalid_cvi"),
    c("print", "contentvalid_judge"),
    c("summary", "contentvalid_judge"),
    c("print", "summary.contentvalid_judge"),
    c("print", "contentvalid_gtheory"),
    c("print", "contentvalid_structure"),
    c("plot", "contentvalid_structure"),
    c("print", "contentvalid_domain"),
    c("summary", "contentvalid_domain"),
    c("print", "summary.contentvalid_domain"),
    c("print", "contentvalid_glossary"),
    c("print", "contentvalid_rounds"),
    c("summary", "contentvalid_rounds"),
    c("print", "summary.contentvalid_rounds"),
    c("print", "contentvalid_expert_power"),
    c("plot", "contentvalid_expert_power"),
    c("print", "contentvalid_agreement"),
    c("print", "contentvalid_handoff"),
    c("as.data.frame", "contentvalid_workflow")
  )

  for (spec in expected_methods) {
    method <- getS3method(spec[[1]], spec[[2]], optional = TRUE)
    expect_true(is.function(method), info = paste(spec, collapse = "."))
  }
})

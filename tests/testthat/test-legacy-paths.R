# Paths the everyday tests do not reach: the Monte Carlo helpers kept for
# older analyses, and the compatibility code that lets objects saved by
# earlier versions still print and summarize.

test_that("the simulation helpers check their arguments", {
  expect_error(simulate_csv_power(N = 0), "`N`")
  expect_error(simulate_csv_power(N = 2.5), "`N`")
  expect_error(simulate_csv_power(true_p = 1.5), "`true_p`")
  expect_error(simulate_csv_power(reps = 0), "`reps`")
  expect_error(simulate_csv_power(alpha = 1), "`alpha`")

  expect_error(simulate_anova_power(n_raters = 1), "`n_raters`")
  expect_error(simulate_anova_power(mean_diff = NA), "`mean_diff`")
  expect_error(simulate_anova_power(sd = 0), "`sd`")
  expect_error(simulate_anova_power(k_constructs = 1), "`k_constructs`")
  expect_error(simulate_anova_power(reps = 0), "`reps`")
  expect_error(simulate_anova_power(alpha = 0), "`alpha`")
})

test_that("the simulation helpers return a power between 0 and 1", {
  set.seed(8)
  p_csv <- simulate_csv_power(N = 20, true_p = 0.9, reps = 60)
  expect_true(p_csv >= 0 && p_csv <= 1)
  # With 20 judges choosing the target nine times in ten, the exact test
  # nearly always passes.
  expect_gt(p_csv, 0.8)
  set.seed(8)
  p_anova <- simulate_anova_power(n_raters = 10, mean_diff = 2, sd = 1,
                                  k_constructs = 3, reps = 20)
  expect_true(p_anova >= 0 && p_anova <= 1)
  expect_gt(p_anova, 0.8)
})

test_that("older decision wording still maps onto the shared statuses", {
  old <- c("Insufficient judges", "Needs review", "Retained", "Favoured",
           "Descriptive summary", NA)
  expect_identical(
    contentvalidR:::.workflow_status_from_recommendation(old),
    c("Insufficient data", "Review", "Supported", "Supported",
      "Descriptive only", NA)
  )
})

test_that("the workflow constructor rejects malformed parts", {
  good <- data.frame(item = "I1", recommendation = "Retain")
  build <- function(...) {
    args <- list(subclass = "contentvalid_sort", workflow = "item-sort",
                 results = good, scale_summary = data.frame(),
                 settings = list(), design = list())
    dots <- list(...)
    args[names(dots)] <- dots
    do.call(contentvalidR:::.new_contentvalid_workflow, args)
  }
  expect_s3_class(build(), "contentvalid_workflow")
  expect_error(build(results = "x"), "must be a data.frame")
  expect_error(build(results = data.frame(item = "I1")), "`recommendation` or `status`")
  expect_error(build(results = data.frame(item = "I1", status = "Maybe")),
               "must be one of")
  expect_error(build(scale_summary = "x"), "`scale_summary` must be a data.frame")
  expect_error(build(settings = "x"), "must be lists")
  expect_error(build(details = "x"), "`details` must be a list")
  # Legacy aliases are added without overwriting a current part.
  fit <- build(legacy = list(scale = data.frame(a = 1), results = "ignored"))
  expect_identical(fit$scale, data.frame(a = 1))
  expect_s3_class(fit$results, "data.frame")
})

test_that("expert objects saved before 0.0.6 still summarize", {
  rel <- structure(list(
    mode = "relevance",
    results = data.frame(item = c("I1", "I2"),
                         recommendation = c("Strong support", "Review")),
    scale = data.frame(n_items = 2L, n_experts_min = 5L, n_experts_max = 6L)
  ), class = c("contentvalid_expert", "contentvalid_workflow"))
  expect_identical(contentvalidR:::.workflow_name(rel), "expert-panel")
  d <- contentvalidR:::.workflow_design(rel)
  expect_identical(d$type, "expert-panel relevance")
  expect_identical(d$n_judges_max, 6L)
  s <- contentvalidR:::.workflow_summary_core(rel)
  expect_identical(c(s$n_supported, s$n_review), c(1L, 1L))

  ess <- structure(list(
    mode = "essentiality",
    results = data.frame(item = c("I1", "I2"), N = c(10L, 10L),
                         recommendation = c("Supported", "Review"))
  ), class = c("contentvalid_expert", "contentvalid_workflow"))
  expect_identical(contentvalidR:::.workflow_design(ess)$n_judges, 10L)

  con <- structure(list(
    mode = "congruence",
    results = data.frame(item = c("I1", "I1"), recommendation = "Descriptive only"),
    details = list(cells = data.frame(objective = c("A", "B"),
                                      n_judges = c(4L, 3L), n_missing = c(0L, 1L)))
  ), class = c("contentvalid_expert", "contentvalid_workflow"))
  cd <- contentvalidR:::.workflow_design(con)
  expect_identical(cd$n_items, 1L)
  expect_identical(c(cd$n_judges_min, cd$n_judges_max, cd$n_missing), c(3L, 4L, 1L))
  expect_identical(cd$n_objectives, 2L)

  # Anything else unknown reports no design and no workflow name.
  other <- structure(list(results = data.frame(recommendation = "Retain")),
                     class = "contentvalid_workflow")
  expect_identical(contentvalidR:::.workflow_design(other), list())
  expect_identical(contentvalidR:::.workflow_name(other), NA_character_)
  expect_identical(contentvalidR:::.workflow_scale_summary(other), data.frame())
})

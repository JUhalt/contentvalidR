# The stability policy in ?contentvalidR is only worth something if it covers
# what the package actually exports. These tests keep it from drifting: a new
# export that nobody classified would otherwise inherit a promise by accident,
# or none at all.

# Under R CMD check the help is installed; under devtools::test() it is not,
# so fall back to the .Rd source in the package tree.
rd_text <- function(name) {
  installed <- tryCatch({
    rd <- tools::Rd_db("contentvalidR")[[name]]
    if (is.null(rd)) NULL else paste(as.character(rd), collapse = " ")
  }, error = function(e) NULL)
  if (!is.null(installed)) return(installed)

  source_rd <- testthat::test_path("..", "..", "man", name)
  if (!file.exists(source_rd)) skip("package documentation is not available")
  paste(readLines(source_rd, warn = FALSE), collapse = " ")
}

policy_text <- function() rd_text("contentvalidR-package.Rd")

test_that("every exported function is placed in a tier", {
  policy <- policy_text()
  exports <- getNamespaceExports("contentvalidR")
  # S3 methods are covered by the sentence about the workflows' methods.
  exports <- exports[!grepl("^(print|summary|plot|as\\.data\\.frame)\\.", exports)]

  missing <- exports[!vapply(exports, function(f) {
    grepl(f, policy, fixed = TRUE)
  }, logical(1))]
  expect_identical(
    missing, character(0),
    info = paste0("not classified in ?contentvalidR: ",
                  paste(missing, collapse = ", "))
  )
})

test_that("the policy names the three tiers and the deprecation cycle", {
  policy <- policy_text()
  expect_match(policy, "recommended workflows", fixed = TRUE)
  expect_match(policy, "component indices and planning helpers", fixed = TRUE)
  expect_match(policy, "auxiliary and compatibility helpers", fixed = TRUE)
  expect_match(policy, "at least one minor release", fixed = TRUE)
  expect_match(policy, "schema_version", fixed = TRUE)
})

test_that("both deprecation examples the policy cites are in the state it claims", {
  d <- expand.grid(item = c("A1", "A2"), rater = 1:8,
                   construct = c("A", "B"), stringsAsFactors = FALSE)
  d$target_construct <- "A"
  set.seed(4)
  d$rating <- ifelse(d$construct == d$target_construct,
                     sample(4:5, nrow(d), replace = TRUE),
                     sample(1:2, nrow(d), replace = TRUE))
  fit <- anova_content(d, item_col = "item", rater_col = "rater",
                       construct_col = "construct",
                       target_col = "target_construct",
                       rating_col = "rating")

  # The completed cycle: `posthoc` is gone from the signature, and the policy
  # says so rather than still calling it the current example.
  expect_false("posthoc" %in% names(formals(anova_content)))
  expect_error(
    anova_content(d, target_col = "target_construct", posthoc = TRUE),
    "unused argument"
  )

  # The second completed cycle: `posthoc_pass` was documented as deprecated in
  # 0.7.0, the one minor release of notice step 2 requires, and removed in
  # 0.8.0, the last minor release before 1.0 would lock it in until 2.0.
  expect_false("posthoc_pass" %in% names(fit))
  expect_true("contrast_pass" %in% names(fit))
  rd <- rd_text("anova_content.Rd")
  expect_match(rd, "removed in 0.8.0", fixed = TRUE)

  # With both cycles complete, the policy says nothing is carried into 1.0.
  expect_match(gsub("[[:space:]]+", " ", policy_text()),
               "No deprecation is in progress", fixed = TRUE)
})

test_that("the status vocabulary the policy promises is what workflows use", {
  promised <- c("Supported", "Review", "Insufficient data", "Descriptive only")
  expect_setequal(contentvalidR:::.workflow_status_levels, promised)
  expect_setequal(contentvalidR:::.status_definitions()$status, promised)

  policy <- policy_text()
  for (status in promised) {
    expect_match(policy, status, fixed = TRUE)
  }
})

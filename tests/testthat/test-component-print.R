# The component functions print formatted tables in APA style, but return
# their values unrounded, and the tag that drives the printing must never reach
# a workflow's results.

shown <- function(x) {
  gsub("\\s+", " ", paste(utils::capture.output(print(x)), collapse = " "))
}

sorts <- data.frame(
  item = rep(c("Clear", "Weak"), each = 20), rater = rep(1:20, 2),
  target_construct = "A",
  assigned_construct = c(rep("A", 18), rep("B", 2), rep("A", 12), rep("B", 8)),
  stringsAsFactors = FALSE
)

test_that("component tables print in APA style and keep full precision", {
  psa <- compute_psa(sorts)
  out <- shown(psa)
  expect_match(out, "Proportion of substantive agreement", fixed = TRUE)
  expect_match(out, "18/20 .90 [.70, .97]", fixed = TRUE)
  expect_false(grepl("0.9", out, fixed = TRUE))
  # The value is not rounded.
  expect_equal(psa$psa_low[1], stats::prop.test(18, 20, correct = FALSE)$conf.int[1],
               tolerance = 1e-8)
  expect_true(nchar(format(psa$psa_low[1], digits = 15)) > 6)

  expect_match(shown(cvr(essential = c(8, 10), N = 12)),
               "Item2 10/12 .67 .019 10 yes", fixed = TRUE)
  expect_match(shown(aikens_v(matrix(c(4, 4, 3, 4, 3, 4), 3), lo = 1, hi = 4)),
               "Aiken's V (Aiken, 1980)", fixed = TRUE)
})

test_that("p values print as APA requires", {
  set.seed(12)
  d <- expand.grid(item = c("A1", "B1"), rater = 1:15, construct = c("A", "B", "C"))
  d$target_construct <- ifelse(d$item == "B1", "B", "A")
  d$rating <- ifelse(d$construct == d$target_construct, 5, 2) +
    stats::rnorm(nrow(d), 0, 0.3)
  out <- shown(anova_content(d))
  expect_match(out, "< .001", fixed = TRUE)
  expect_false(grepl("[0-9]e-[0-9]", out))
  expect_match(shown(csv_binom_test(15, 20)), "probability p = .021", fixed = TRUE)
  expect_match(shown(csv_binom_test(20, 20)), "probability p < .001", fixed = TRUE)
})

test_that("as.data.frame() and subsetting give back plain data", {
  psa <- compute_psa(sorts)
  plain <- as.data.frame(psa)
  expect_identical(class(plain), "data.frame")
  expect_identical(plain$psa, unclass(psa)$psa)
  # A subset that drops the columns a display needs prints as a data frame.
  expect_match(shown(psa[, c("item", "psa")]), "0.9", fixed = TRUE)
})

test_that("csv_binom_test returns its inputs beside the result", {
  b <- csv_binom_test(15, 20, p0 = 0.5, alpha = 0.05)
  expect_identical(b$n_target, 15)
  expect_identical(b$N, 20)
  expect_identical(b$p0, 0.5)
  expect_identical(b$alpha, 0.05)
})

test_that("workflow results never carry a component class", {
  expect_identical(class(sort_validity(sorts)$results), "data.frame")
  R <- matrix(c(4, 4, 3, 4, 3, 4, 4, 4, 4), 3,
              dimnames = list(NULL, paste0("I", 1:3)))
  expect_identical(class(expert_validity(R, mode = "relevance", lo = 1, hi = 4,
                                         agreement = "none")$results),
                   "data.frame")
  expect_identical(class(expert_validity(c(10, 8), mode = "essentiality",
                                         N = 12)$results), "data.frame")
})

test_that("a similarity matrix prints formatted and still feeds content_structure()", {
  sim <- similarity_from_sort(data.frame(
    item = rep(paste0("I", 1:4), each = 5), rater = rep(1:5, 4),
    assigned_construct = c(rep("A", 10), rep("B", 10)), stringsAsFactors = FALSE
  ))
  expect_match(shown(sim), "Every pair was sorted by the same 5 judges.", fixed = TRUE)
  expect_s3_class(content_structure(sim), "contentvalid_structure")
})

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

test_that("pairs sorted by different numbers of judges are reported as a range", {
  d <- data.frame(item = rep(paste0("I", 1:4), each = 5), rater = rep(1:5, 4),
                  assigned_construct = c(rep("A", 10), rep("B", 10)),
                  stringsAsFactors = FALSE)
  d <- d[!(d$item == "I4" & d$rater == 5), ]
  expect_match(shown(similarity_from_sort(d)),
               "Pairs were sorted by 4 to 5 judges", fixed = TRUE)
})

ratings_within <- function() {
  set.seed(3)
  d <- expand.grid(item = c("A1", "B1"), rater = 1:12,
                   construct = c("A", "B", "C"), stringsAsFactors = FALSE)
  d$target_construct <- ifelse(d$item == "B1", "B", "A")
  d$rating <- ifelse(d$construct == d$target_construct,
                     sample(4:5, nrow(d), TRUE), sample(1:3, nrow(d), TRUE))
  d
}

test_that("the construct-rating components print as APA tables", {
  d <- ratings_within()
  out_htc <- shown(htc(d, scale_min = 1, scale_max = 5))
  expect_match(out_htc, "Hinkin-Tracey correspondence (HTC", fixed = TRUE)
  expect_match(out_htc, "share of the 5-point scale", fixed = TRUE)
  expect_false(grepl(" 0[.][0-9]", out_htc))

  out_htd <- shown(htd(d, scale_min = 1, scale_max = 5))
  expect_match(out_htd, "Hinkin-Tracey distinctiveness (HTD", fixed = TRUE)
  expect_match(out_htd, "Competitor mean", fixed = TRUE)
  expect_match(out_htd, "averages the gap over every other construct", fixed = TRUE)

  within <- shown(anova_content(d))
  expect_match(within, "Greenhouse-Geisser corrected", fixed = TRUE)
  # The table fits an 80-column console.
  old_width <- options(width = 80)
  on.exit(options(old_width), add = TRUE)
  expect_lte(max(nchar(utils::capture.output(print(anova_content(d))))), 80L)
  expect_match(within, "F[(][0-9.]+, [0-9.]+[)] = [0-9.]+")
  # A between-judges design has whole-number degrees of freedom and no
  # Greenhouse-Geisser note.
  between <- d
  between$rater <- paste0(between$rater, "-", between$construct)
  out_between <- shown(anova_content(between, design = "between"))
  expect_match(out_between, "Content-validity ANOVA", fixed = TRUE)
  expect_false(grepl("Greenhouse-Geisser corrected", out_between, fixed = TRUE))
})

test_that("the item-sort and expert components print their notes", {
  csv <- shown(compute_csv(sorts))
  expect_match(csv, "Coefficient of substantive validity (Csv", fixed = TRUE)
  expect_match(csv, "18/20 B 2/20 .80", fixed = TRUE)
  expect_match(csv, "divided by the number of judges", fixed = TRUE)

  # Without an interval there is no interval column or interval note.
  no_ci <- shown(compute_psa(sorts, ci = "none"))
  expect_false(grepl("95% CI", no_ci, fixed = TRUE))
  # Missing assignments are counted in a note.
  gappy <- sorts
  gappy$assigned_construct[1] <- NA
  expect_match(shown(compute_psa(gappy)), "Missing assignments: 1", fixed = TRUE)

  R <- matrix(c(4, 4, 3, 4, 3, 4, 4, 4, 4), 3,
              dimnames = list(NULL, paste0("I", 1:3)))
  expect_match(shown(aikens_v(R, lo = 1, hi = 4)),
               "Penfield-Giacobbi score (Penfield & Giacobbi, 2004)", fixed = TRUE)
  expect_false(grepl("Interval:", shown(aikens_v(R, lo = 1, hi = 4, ci = "none")),
                     fixed = TRUE))
  expect_match(shown(aikens_v(R, lo = 1, hi = 4, ci = "bootstrap", B = 50,
                              seed = 1)),
               "Interval: percentile bootstrap.", fixed = TRUE)

  d <- expand.grid(item = c("I1", "I2"), judge = 1:4, objective = c("A", "B"))
  d$score <- ifelse((d$item == "I1") == (d$objective == "A"), 1, 0)
  out_ioc <- shown(ioc(d))
  expect_match(out_ioc, "Index of item-objective congruence (IOC", fixed = TRUE)
  # The mean rating, then the index: +1 on A and 0 on B gives .50.
  expect_match(out_ioc, "I1 A 4 1.00 .50", fixed = TRUE)
})

test_that("the Colquitt functions print their bands", {
  bands <- shown(interpret_colquitt(c(.70, .40), "csv"))
  expect_match(bands, "Benchmark bands (Colquitt et al., 2019)", fixed = TRUE)
  expect_match(bands, "Csv .70 Strong", fixed = TRUE)
  expect_match(bands, "not a universal cutoff", fixed = TRUE)
  # Expert judges get no band.
  expect_match(shown(interpret_colquitt(.70, "csv", judge_type = "expert")),
               "not applied", fixed = TRUE)

  norms <- shown(colquitt_benchmarks("htd"))
  expect_match(norms, "Benchmarks for HTD (Colquitt et al., 2019)", fixed = TRUE)
  expect_match(norms, "Lack of 0th-19th none", fixed = TRUE)
})

test_that("the two-by-two helpers print their statistics", {
  pred <- c(TRUE, TRUE, FALSE, FALSE, TRUE, FALSE)
  act <- c(TRUE, FALSE, FALSE, FALSE, TRUE, TRUE)
  sig <- shown(signal_detection(pred, act))
  expect_match(sig, "Retention decisions compared with the actual outcome",
               fixed = TRUE)
  expect_match(sig, "accuracy = ", fixed = TRUE)
  # Six items: the exact test is reported, with the chi-square beside it.
  expect_match(sig, "Fisher's exact p", fixed = TRUE)
  expect_match(sig, "chi-square(1, N = 6) = ", fixed = TRUE)
  rep_out <- shown(reproducibility_phi(pred, act))
  expect_match(rep_out, "Retention decisions in two pretests", fixed = TRUE)
  expect_match(rep_out, "phi = ", fixed = TRUE)
  # When chi-square cannot be computed, only phi is reported.
  flat <- shown(reproducibility_phi(rep(TRUE, 4), rep(TRUE, 4)))
  expect_false(grepl("chi-square", flat, fixed = TRUE))
})

test_that("a csv_binom_test result saved before 0.9.0 still prints", {
  b <- unclass(csv_binom_test(15, 20))
  b[c("n_target", "N", "p0", "alpha")] <- NULL
  class(b) <- c("contentvalid_binom", "contentvalid_component")
  out <- shown(b)
  expect_match(out, "The item meets the exact target-assignment criterion.",
               fixed = TRUE)
  expect_match(out, "Psa = .75, p = .021.", fixed = TRUE)
})

test_that("csv_binom_test prints its verdict first, in the workflow's words", {
  pass <- capture.output(print(csv_binom_test(15, 20)))
  expect_identical(pass[3], "The item meets the exact target-assignment criterion.")
  fail <- shown(csv_binom_test(14, 20))
  expect_match(fail, "The item does not meet the exact target-assignment criterion.",
               fixed = TRUE)
  # No doubled period, and no significance jargon in the printout.
  expect_false(grepl("..", fail, fixed = TRUE))
  expect_false(grepl("n.s.", fail, fixed = TRUE))
})

test_that("each component print falls back to a plain print after subsetting", {
  d <- ratings_within()
  expect_match(shown(htd(d, scale_min = 1, scale_max = 5)[, c("item", "htd")]),
               "item", fixed = TRUE)
  expect_false(grepl("Hinkin-Tracey", shown(htc(d, scale_min = 1,
                                                  scale_max = 5)[, c("item", "htc")]),
                     fixed = TRUE))
})

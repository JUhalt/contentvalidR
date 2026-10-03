# Fixes from the audit before 1.0: what the keys and help pages say, APA
# text, plot arguments, long item names, and as.data.frame() for every
# result.

flat <- function(x, ...) {
  old <- options(width = 80)
  on.exit(options(old), add = TRUE)
  gsub("[[:space:]]+", " ", paste(utils::capture.output(print(x, ...)),
                                  collapse = "\n"))
}

relevance <- function() {
  matrix(c(4, 3, 4, 4, 3, 4, 2, 3, 4, 4, 3, 2, 4, 4, 4, 3, 4, 4), 6,
         dimnames = list(NULL, c("I1", "I2", "I3")))
}

sort_fit <- function() {
  sort_validity(utils::read.csv(
    system.file("extdata", "sort_example.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE))
}

# ---- Keys and glossary --------------------------------------------------------

test_that("the modified kappa key says when it can fall below 0", {
  out <- flat(expert_validity(relevance(), lo = 1, hi = 4, agreement = "none"))
  expect_match(out, "below 0 only when no expert, or one of three, rated it relevant",
               fixed = TRUE)
  expect_false(grepl("below 0 when agreement is below chance", out, fixed = TRUE))
  # It is true: 1 of 3 is negative, 1 of 4 is not.
  k <- function(a, n) {
    pc <- stats::dbinom(a, n, 0.5)
    (a / n - pc) / (1 - pc)
  }
  expect_lt(k(1, 3), 0)
  expect_gte(k(1, 4), 0)
  expect_gt(k(2, 8), 0)
})

test_that("the key defines S-CVI/Ave and S-CVI/UA, which the header prints", {
  out <- flat(expert_validity(relevance(), lo = 1, hi = 4, agreement = "none"))
  expect_match(out, "S-CVI/Ave -- Scale-level CVI, averaging method", fixed = TRUE)
  expect_match(out, "S-CVI/UA -- Scale-level CVI, universal agreement", fixed = TRUE)
})

test_that("the agreement key matches the coefficient chosen", {
  kr <- flat(expert_validity(relevance(), lo = 1, hi = 4, agreement_B = 0))
  expect_match(kr, "it can be low when nearly every rating is the same", fixed = TRUE)
  ac <- flat(expert_validity(relevance(), lo = 1, hi = 4, agreement = "ac1",
                             agreement_B = 0))
  expect_match(ac, "Panel-level agreement (Gwet's AC1)", fixed = TRUE)
  expect_false(grepl("it can be low when nearly every rating is the same", ac,
                     fixed = TRUE))
})

test_that("the judge key separates severity in rating points from logits", {
  g <- contentvalid_glossary()
  sev <- g$definition[g$term == "severity"]
  expect_match(sev, "relevant/not-relevant decision", fixed = TRUE)
  expect_false(grepl("Reported in logits", sev, fixed = TRUE))
  expect_true("severity_raw" %in% g$term)
  r <- rbind(
    c(4, 4, 3, 4, 3, 2, 3, 2, 4, 3), c(4, 3, 4, 3, 2, 3, 2, 3, 4, 2),
    c(3, 4, 4, 3, 3, 2, 2, 2, 3, 3), c(4, 4, 3, 2, 3, 3, 3, 1, 4, 2),
    c(4, 3, 3, 4, 2, 2, 3, 2, 3, 3), c(3, 4, 4, 3, 3, 3, 2, 3, 4, 1),
    c(4, 4, 4, 4, 3, 2, 3, 2, 4, 3), c(3, 2, 3, 2, 2, 1, 2, 1, 2, 2)
  )
  fit <- judge_validity(r, lo = 1, hi = 4)
  expect_true(fit$scale_summary$severity_estimable)
  expect_match(flat(fit), "Logit -- Judge severity in logits", fixed = TRUE)
})

test_that("domain decision meanings state the rule applied", {
  m <- contentvalidR:::.decision_meanings("domain")
  expect_match(m[["Over-represented"]], "over_factor", fixed = TRUE)
  expect_match(m[["Under-represented"]], "over_factor", fixed = TRUE)
  expect_match(m[["Thinly covered"]], "minimum set for this analysis", fixed = TRUE)
})

test_that("three-author works are cited with et al. and p value is not hyphenated", {
  out <- flat(expert_validity(relevance(), lo = 1, hi = 4, agreement = "none"))
  expect_match(out, "(Polit et al., 2007)", fixed = TRUE)
  expect_false(grepl("Polit, Beck", out, fixed = TRUE))
  expect_false(grepl("Polit, Beck", flat(cvi(relevance() >= 3)), fixed = TRUE))
  g <- contentvalid_glossary()
  expect_false(any(grepl("p-value", unlist(g), fixed = TRUE)))
})

# ---- content_report() ------------------------------------------------------

test_that("the relevance report keeps its two intervals apart", {
  tab <- content_report(expert_validity(relevance(), lo = 1, hi = 4,
                                        agreement = "none"))
  expect_false(anyDuplicated(names(tab)) > 0L)
  expect_true(all(c("V 95% CI", "I-CVI 95% CI") %in% names(tab)))
  expect_identical(names(as.data.frame(tab)), names(tab))
  expect_null(attr(as.data.frame(tab), "display"))
  # A reader sees each interval under the shared heading, beside its estimate.
  printed <- utils::capture.output(print(tab))
  expect_identical(lengths(regmatches(printed[1], gregexpr("95% CI", printed[1]))), 2L)
  expect_false(grepl("V 95% CI", printed[1], fixed = TRUE))
  md <- content_report(expert_validity(relevance(), lo = 1, hi = 4,
                                       agreement = "none"), format = "markdown")
  expect_match(md[1], "| V | 95% CI | I-CVI | 95% CI |", fixed = TRUE)
})

# ---- Plot arguments and long item names --------------------------------------

test_that("every plot takes xlab, ylab, xlim, ylim and main from the caller", {
  pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  user <- list(xlab = "Mine", ylab = "Yours", main = "Title")
  try_plot <- function(obj, ...) {
    expect_no_error(do.call(plot, c(list(obj, ...), user)))
  }
  s <- sort_fit()
  for (type in c("item", "map")) {
    expect_no_error(plot(s, type = type, xlab = "Mine", ylab = "Yours",
                         main = "Title"))
  }
  try_plot(expert_validity(relevance(), lo = 1, hi = 4, agreement = "none"),
           xlim = c(0, 1))
  try_plot(expert_validity(relevance(), lo = 1, hi = 4, agreement = "none"),
           type = "distribution")
  try_plot(expert_validity(c(10, 8, 6), mode = "essentiality", N = 12),
           xlim = c(-1, 1))
  d <- expand.grid(item = c("I1", "I2"), judge = 1:4, objective = c("A", "B"))
  d$target_objective <- ifelse(d$item == "I1", "A", "B")
  d$score <- ifelse(d$objective == d$target_objective, 1, -1)
  try_plot(expert_validity(d, mode = "congruence"), ylim = c(0, 4))
  try_plot(sort_power(N = c(10, 20, 30), true_p = 0.8), xlim = c(5, 35))
  try_plot(expert_power(n_experts = 5:10), ylim = c(0, 1))
  try_plot(content_evidence(expert_validity(relevance(), lo = 1, hi = 4,
                                            agreement = "none")))
})

test_that("long item names are shortened rather than breaking a figure", {
  pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  R <- relevance()
  colnames(R) <- c(strrep("A very long item name ", 3), "Short",
                   strrep("Another long name ", 4))
  fit <- expert_validity(R, lo = 1, hi = 4, agreement = "none")
  expect_no_error(plot(fit, type = "distribution"))
  expect_no_error(plot(content_evidence(fit)))
  lab <- contentvalidR:::.item_labels(colnames(R), width_in = 7)
  expect_identical(lab$labels[2], "Short")
  expect_true(all(grepl("...", lab$labels[-2], fixed = TRUE)))
  expect_lte(lab$lines, 1.2 + 0.4 * 7 / graphics::par("csi") + 1e-9)
})

# ---- as.data.frame() for every result ------------------------------------------

test_that("every result becomes a data frame", {
  R <- relevance()
  sim <- matrix(1, 6, 6, dimnames = list(paste0("I", 1:6), paste0("I", 1:6)))
  sim[1:3, 1:3] <- 4
  sim[4:6, 4:6] <- 4
  sim[1, 2] <- sim[2, 1] <- 5
  diag(sim) <- 5
  s <- sort_fit()
  objs <- list(
    sort_power(N = c(10, 20), true_p = .8),
    expert_power(n_experts = c(6, 10)),
    content_structure(sim, membership = rep(c("A", "B"), each = 3)),
    compare_rounds(s, s),
    content_handoff(s),
    gtheory_content(R),
    panel_agreement(R, B = 0),
    cvi(R >= 3)
  )
  for (o in objs) {
    d <- as.data.frame(o)
    expect_s3_class(d, "data.frame")
    expect_gt(nrow(d), 0L)
  }
  expect_identical(nrow(as.data.frame(cvi(R >= 3), component = "scale_level")), 1L)
  expect_identical(names(as.data.frame(content_handoff(s))),
                   names(content_handoff(s)$item_evidence))
  expect_error(as.data.frame(gtheory_content(R), component = "nope"),
               "must be one of")
})

test_that("a single test is one row", {
  b <- as.data.frame(csv_binom_test(16, 20))
  expect_identical(nrow(b), 1L)
  expect_true(all(c("ci_low", "ci_high", "p.value") %in% names(b)))
  pre <- c(TRUE, TRUE, FALSE, TRUE, FALSE, TRUE)
  crit <- c(TRUE, FALSE, FALSE, TRUE, FALSE, TRUE)
  sd <- as.data.frame(signal_detection(pre, crit))
  expect_identical(nrow(sd), 1L)
  expect_identical(sd$n_predicted_retain_actual_retain, 3L)
  expect_identical(nrow(as.data.frame(reproducibility_phi(pre, crit))), 1L)
  pa <- as.data.frame(panel_agreement(relevance(), B = 0))
  expect_identical(nrow(pa), 1L)
  expect_true(all(c("method", "estimate") %in% names(pa)))
})

# ---- Review of the text fixes ------------------------------------------------

test_that("a caller's plot argument reaches the frame, and protected ones do not", {
  seen <- NULL
  capture <- function(...) seen <<- list(...)
  base <- list(x = 1, type = "n", xaxt = "n", xlab = "Method", pch = 19)
  contentvalidR:::.plot_with(base, list(xlab = "Mine", xlim = c(0, 2)),
                             draw = capture)
  expect_identical(seen$xlab, "Mine")
  expect_identical(seen$xlim, c(0, 2))
  contentvalidR:::.plot_with(base, list(type = "l", xaxt = "s", xlab = NULL),
                             draw = capture)
  expect_identical(seen$type, "n")
  expect_identical(seen$xaxt, "n")
  expect_identical(seen$xlab, "Method")
  contentvalidR:::.plot_with(base, list(pch = 17), draw = capture,
                             protect = c("type", "pch"))
  expect_identical(seen$pch, 19)
  expect_warning(contentvalidR:::.plot_with(base, list("stray"), draw = capture),
                 "Unnamed arguments")

  pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  plot(expert_validity(relevance(), lo = 1, hi = 4, agreement = "none"),
       xlim = c(0, 0.5))
  expect_equal(graphics::par("usr")[2], 0.5 + 0.04 * 0.5, tolerance = 1e-6)
})

test_that("shortened labels stay apart and full labels are kept when they fit", {
  pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  stems <- c("I feel confident in my ability to do my job well",
             "I feel confident in my ability to learn new skills",
             "My supervisor gives me useful feedback")
  lab <- contentvalidR:::.item_labels(stems, width_in = 4)
  expect_false(anyDuplicated(lab$labels) > 0L)
  expect_true(all(grepl("...", lab$labels[1:2], fixed = TRUE)))
  short <- c("effort_regulation_01", "effort_regulation_02", "task_focus_01")
  expect_identical(contentvalidR:::.item_labels(short)$labels, short)
})

test_that("both two-by-two tables give their four counts by name", {
  pre <- c(TRUE, TRUE, FALSE, TRUE, FALSE, TRUE)
  crit <- c(TRUE, FALSE, FALSE, TRUE, FALSE, TRUE)
  sd <- as.data.frame(signal_detection(pre, crit))
  expect_identical(
    unlist(sd[c("n_predicted_retain_actual_retain",
                "n_predicted_not_retained_actual_retain",
                "n_predicted_retain_actual_not_retained",
                "n_predicted_not_retained_actual_not_retained")], use.names = FALSE),
    c(3L, 0L, 1L, 2L))
  rp <- as.data.frame(reproducibility_phi(pre, crit))
  expect_identical(
    unlist(rp[c("n_pretest1_retain_pretest2_retain",
                "n_pretest1_not_retained_pretest2_retain",
                "n_pretest1_retain_pretest2_not_retained",
                "n_pretest1_not_retained_pretest2_not_retained")], use.names = FALSE),
    c(3L, 0L, 1L, 2L))
})

test_that("one-row frames say what their interval is", {
  pa <- as.data.frame(panel_agreement(relevance(), B = 0))
  expect_true("ci_alpha" %in% names(pa))
  expect_false("alpha" %in% names(pa))
  b <- as.data.frame(csv_binom_test(16, 20))
  expect_identical(b$ci_sides, "one-sided")
  expect_equal(b$ci_level, 0.95)
})

test_that("three-author works read et al. in printouts", {
  expect_match(flat(cvi(relevance() >= 3)), "Polit et al. (2007)", fixed = TRUE)
  legacy <- flat(sort_fit(), legacy = TRUE)
  expect_match(legacy, "Yao et al. (2008): Psa and Csv", fixed = TRUE)
  expect_false(grepl("Yao, Wu", legacy, fixed = TRUE))
})

test_that("a renamed report column prints under its new name", {
  tab <- content_report(sort_fit())
  expect_true("Psa 95% CI" %in% names(tab))
  names(tab)[1] <- "Item code"
  out <- utils::capture.output(print(tab))
  expect_match(out[1], "Item code", fixed = TRUE)
  expect_match(out[1], "95% CI", fixed = TRUE)
  expect_false(grepl("Psa 95% CI", out[1], fixed = TRUE))
})

test_that("the AC1 key does not read 0 as chance", {
  ac <- flat(expert_validity(relevance(), lo = 1, hi = 4, agreement = "ac1",
                             agreement_B = 0))
  expect_match(ac, "not 0 for independent raters", fixed = TRUE)
  expect_false(grepl("decision (1 is perfect, 0 is chance)", ac, fixed = TRUE))
})

test_that("the glossary keys severity by its column in results", {
  g <- contentvalid_glossary()
  expect_match(g$definition[g$term == "severity_raw"], "rating points", fixed = TRUE)
  expect_match(g$definition[g$term == "severity"], "even in sign", fixed = TRUE)
  expect_false("logit" %in% g$term)
  m <- contentvalidR:::.decision_meanings("domain")
  expect_false(grepl("target", m[["Thinly covered"]], fixed = TRUE))
})

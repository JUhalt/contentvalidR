# Canonical values come from the published worked examples verified on #20.

# One row per expert per round, rebuilt from a cross-tabulation whose rows are
# the earlier round and columns the later one.
from_crosstab <- function(O, rounds = c(2, 3), item = "Q") {
  cells <- which(O > 0, arr.ind = TRUE)
  x1 <- rep(cells[, 1], O[cells])
  x2 <- rep(cells[, 2], O[cells])
  n <- length(x1)
  data.frame(expert = rep(seq_len(n), 2), item = item,
             round = rep(rounds, each = n), rating = c(x1, x2),
             stringsAsFactors = FALSE)
}

# Chaffin & Talley (1980), Tables 2a and 3a, transposed so rows are round 2.
ct_2a <- rbind(c(26, 0, 0), c(7, 62, 2), c(0, 0, 25))
ct_3a <- rbind(c(8, 13, 5), c(20, 38, 13), c(5, 11, 9))

# Fleiss & Cohen (1973), eq. 8: quadratic weighted kappa as two-way ANOVA.
anova_kappa <- function(x1, x2) {
  n <- length(x1)
  y <- c(x1, x2)
  s <- factor(rep(seq_len(n), 2))
  r <- factor(rep(1:2, each = n))
  ss <- stats::anova(stats::lm(y ~ s + r))[["Sum Sq"]]
  (ss[1] - ss[3]) / (ss[1] + 2 * ss[2] + ss[3])
}

small_delphi <- function() {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4, 3, 4), S2 = c(2, 3, 2, 1, 3, 2, 2, 3),
              S3 = c(3, 4, 2, 3, 4, 1, 3, 2), S4 = c(4, 3, 4, 2, 3, 3, 4, 2))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2, 2, 2),
              S3 = c(3, 3, 3, 3, 4, 2, 3, 3), S4 = c(4, 3, 4, 3, 3, 3, 4, 3))
  long <- function(m, round) {
    data.frame(expert = paste0("E", seq_len(nrow(m))),
               item = rep(colnames(m), each = nrow(m)),
               round = round, rating = as.vector(m), stringsAsFactors = FALSE)
  }
  rbind(long(r1, 1), long(r2, 2))
}

test_that("weighted kappa reproduces Cohen's (1968) Table 1", {
  # Frequencies out of N = 200; rows are Judge B, columns Judge A.
  counts <- rbind(c(88, 14, 18), c(10, 40, 10), c(2, 6, 12))
  cells <- which(counts > 0, arr.ind = TRUE)
  x1 <- rep(cells[, 1], counts[cells])
  x2 <- rep(cells[, 2], counts[cells])
  kw <- contentvalidR:::.delphi_weighted_kappa

  V <- rbind(c(0, 1, 3), c(1, 0, 6), c(3, 6, 0))
  expect_equal(round(kw(x1, x2, 1 - diag(3)), 3), 0.492)
  expect_equal(round(kw(x1, x2, V), 3), 0.348)
  swapped <- V
  swapped[V == 6] <- 1
  swapped[V == 1] <- 6
  expect_equal(round(kw(x1, x2, swapped), 3), 0.574)
  validity <- rbind(c(0, 1, 4), c(1, 0, 6), c(2, 2, 0))
  expect_equal(round(kw(x1, x2, validity), 3), 0.353)
})

test_that("quadratic weighted kappa equals Fleiss & Cohen's (1973) ANOVA form", {
  set.seed(3)
  x1 <- sample(1:4, 15, replace = TRUE, prob = c(.1, .2, .3, .4))
  x2 <- pmin(4L, pmax(1L, x1 + sample(-1:1, 15, replace = TRUE)))
  Q <- contentvalidR:::.delphi_disagreement_weights(4, "quadratic")
  expect_equal(contentvalidR:::.delphi_weighted_kappa(x1, x2, Q),
               anova_kappa(x1, x2))
  expect_equal(Q[1, 4], 9)
  expect_equal(contentvalidR:::.delphi_disagreement_weights(4, "linear")[1, 4], 3)
})

test_that("the chi-square helper reproduces Dajani et al. and Chaffin & Talley", {
  chisq <- contentvalidR:::.delphi_chisq
  # Dajani et al. (1979), pooled Table 3: printed 0.138.
  dst <- chisq(rbind(c(6, 5, 10), c(5, 5, 11)))
  expect_equal(dst$statistic, 0.1385281, tolerance = 1e-6)
  expect_identical(dst$df, 2L)

  # Chaffin & Talley (1980), Table 1 group test: printed 1.516.
  expect_equal(chisq(rbind(c(26, 71, 25), c(33, 62, 27)))$statistic, 1.516,
               tolerance = 1e-3)
  # Tables 2a and 3a. The printed 197.5 and 3.79 come from expected counts
  # rounded to one decimal; the exact values are 196.43 and 3.70.
  expect_equal(chisq(ct_2a)$statistic, 196.43, tolerance = 1e-4)
  expect_equal(chisq(ct_3a)$statistic, 3.70, tolerance = 1e-3)
})

test_that("lambda reproduces Chaffin & Talley's (1980) index", {
  lam <- contentvalidR:::.delphi_lambda
  expect_equal(lam(ct_2a), 0.85)
  expect_equal(lam(ct_3a), 0)
  # Undefined when the later round is unanimous.
  expect_true(is.na(lam(rbind(c(0, 5, 0), c(0, 3, 0), c(0, 2, 0)))))
})

test_that("each stability method reads Chaffin & Talley's data in its own direction", {
  d2a <- from_crosstab(ct_2a)
  d3a <- from_crosstab(ct_3a)
  run <- function(d, method) {
    delphi_validity(d, lo = 1, hi = 3, stability = method, B = 0)$details$stability
  }

  # Individual chi-square: rejecting independence is stability.
  ind2 <- run(d2a, "chisq_individual")
  expect_equal(ind2$value, 196.43, tolerance = 1e-4)
  expect_true(ind2$stable)
  ind3 <- run(d3a, "chisq_individual")
  expect_equal(ind3$value, 3.70, tolerance = 1e-3)
  expect_false(ind3$stable)

  # Group chi-square: the same marginals, so both tables look stable.
  grp <- run(d3a, "chisq_group")
  expect_equal(grp$value, 1.516, tolerance = 1e-3)
  expect_true(grp$stable)

  expect_equal(run(d2a, "lambda")$value, 0.85)
  expect_equal(run(d3a, "lambda")$value, 0)

  # Scheibe et al.: 9 net changes among 122 experts, stable below 15%.
  pc <- run(d3a, "percent_change")
  expect_equal(pc$value, 9 / 122)
  expect_true(pc$stable)

  # Only 55 of 122 experts kept their category on Table 3a.
  expect_equal(run(d3a, "kappa")$prop_unchanged, 55 / 122)
})

test_that("kappa in the workflow is the Fleiss & Cohen intraclass form", {
  d <- from_crosstab(ct_3a)
  st <- delphi_validity(d, lo = 1, hi = 3, B = 0)$details$stability
  x1 <- d$rating[d$round == 2]
  x2 <- d$rating[d$round == 3]
  expect_equal(st$value, anova_kappa(x1, x2))
  expect_identical(st$method, "kappa")

  lin <- delphi_validity(d, lo = 1, hi = 3, kappa_weights = "linear",
                         B = 0)$details$stability
  expect_false(isTRUE(all.equal(lin$value, st$value)))
})

test_that("a unanimous round gives kappa 0, flagged, however many kept their rating", {
  d <- data.frame(expert = rep(1:10, 2), item = "Q", round = rep(1:2, each = 10),
                  rating = c(rep(4, 9), 3, rep(4, 10)))
  fit <- delphi_validity(d, lo = 1, hi = 4, B = 0)
  st <- fit$details$stability
  expect_equal(st$prop_unchanged, 0.9)
  expect_equal(st$value, 0)
  expect_match(st$note, "kappa is 0 however many kept their rating")

  both <- data.frame(expert = rep(1:5, 2), item = "Q", round = rep(1:2, each = 5),
                     rating = 4)
  sb <- delphi_validity(both, lo = 1, hi = 4, B = 0)$details$stability
  expect_true(is.na(sb$value))
  expect_equal(sb$prop_unchanged, 1)
  expect_match(sb$note, "undefined")
})

test_that("consensus needs a threshold fixed in advance, and maps onto statuses", {
  d <- small_delphi()
  none <- delphi_validity(d, lo = 1, hi = 4, B = 0)
  expect_true(all(none$results$recommendation == "Descriptive only"))
  expect_true(all(none$results$status == "Descriptive only"))
  expect_true(all(is.na(none$results$consensus)))

  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = 0.75, B = 0)
  r <- fit$results
  expect_equal(r$prop_agree[r$item == "S1"], 1)
  expect_identical(r$recommendation[r$item == "S1"], "Consensus")
  expect_identical(r$status[r$item == "S1"], "Supported")
  expect_identical(r$recommendation[r$item == "S2"], "No consensus")
  expect_identical(r$status[r$item == "S2"], "Review")

  # prop_agree is the I-CVI of the same round.
  last_fit <- fit$details$round_fits[["2"]]
  expect_equal(r$prop_agree, last_fit$results$I_CVI[match(r$item, last_fit$results$item)])

  # Agreement in the other direction is described, not decided.
  expect_match(r$interpretation[r$item == "S2"], "other direction")
})

test_that("fewer than three experts in the last round is insufficient", {
  d <- data.frame(expert = c(1, 2, 3, 1, 2), item = "Q", round = c(1, 1, 1, 2, 2),
                  rating = c(4, 4, 3, 4, 4))
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = 0.75, B = 0)
  expect_identical(fit$results$recommendation, "Insufficient panel")
  expect_identical(fit$results$status, "Insufficient data")
})

test_that("attrition and items leaving the panel are handled explicitly", {
  d <- small_delphi()
  # Expert E8 leaves after round 1; S4 reached consensus and was set aside.
  d <- d[!(d$round == 2 & (d$expert == "E8" | d$item == "S4")), ]
  fit <- delphi_validity(d, lo = 1, hi = 4, B = 0)

  expect_equal(fit$details$panel$n_experts, c(8L, 7L))
  st <- fit$details$stability
  expect_true(all(st$n_paired == 7L))
  expect_false("S4" %in% st$item)

  r <- fit$results
  expect_identical(r$last_round[r$item == "S4"], "1")
  expect_true(is.na(r$prop_unchanged[r$item == "S4"]))
  expect_match(paste(capture.output(print(fit)), collapse = " "),
               "changed size across rounds")
})

test_that("rounds are ordered numerically, by factor levels, or by appearance", {
  d <- small_delphi()
  d10 <- d
  d10$round[d10$round == 2] <- 10
  expect_identical(delphi_validity(d10, lo = 1, hi = 4, B = 0)$design$rounds,
                   c("1", "10"))

  df <- d
  df$round <- factor(ifelse(d$round == 1, "first", "second"),
                     levels = c("first", "second"))
  expect_identical(delphi_validity(df, lo = 1, hi = 4, B = 0)$design$rounds,
                   c("first", "second"))

  dc <- d[order(-d$round), ]
  dc$round <- ifelse(dc$round == 1, "b", "a")
  # Order of appearance: "a" (round 2 rows) comes first here.
  expect_identical(delphi_validity(dc, lo = 1, hi = 4, B = 0)$design$rounds,
                   c("a", "b"))
})

test_that("the kappa interval resamples experts, reproducibly", {
  d <- small_delphi()
  a <- delphi_validity(d, lo = 1, hi = 4, B = 200, seed = 4)$details$stability
  b <- delphi_validity(d, lo = 1, hi = 4, B = 200, seed = 4)$details$stability
  expect_equal(a$lower, b$lower)
  expect_true(all(a$n_boot_usable <= 200))
  expect_true(all(is.na(delphi_validity(d, lo = 1, hi = 4, B = 0)$details$stability$lower)))
})

test_that("inputs are validated with messages a user can act on", {
  d <- small_delphi()
  expect_error(delphi_validity(as.matrix(d), lo = 1, hi = 4), "must be a data frame")
  expect_error(delphi_validity(d, rating_col = "score", lo = 1, hi = 4), "not found")
  bad <- d
  bad$rating[1] <- 5
  expect_error(delphi_validity(bad, lo = 1, hi = 4), "whole numbers from")
  bad$rating[1] <- 2.5
  expect_error(delphi_validity(bad, lo = 1, hi = 4), "whole numbers from")
  expect_error(delphi_validity(rbind(d, d[1, ]), lo = 1, hi = 4), "duplicate")
  expect_error(delphi_validity(d[d$round == 1, ], lo = 1, hi = 4), "at least two rounds")
  expect_error(delphi_validity(d, lo = 1, hi = 4, consensus_threshold = 75),
               "such as 0.75")
  expect_error(delphi_validity(d, lo = 1, hi = 4, agree_cut = 6), "within the rating scale")
  expect_error(delphi_validity(d, lo = 4, hi = 1), "hi > lo")
  expect_error(delphi_validity(d, lo = 1, hi = 4, alpha = 2), "strictly between")
  expect_error(delphi_validity(d, lo = 1, hi = 4, B = -1), "non-negative integer")
  expect_error(delphi_validity(d, lo = 1, hi = 4, stability = "icc"))
})

test_that("the printout explains each method, and kappa carries no verbal labels", {
  d <- small_delphi()
  text <- function(...) {
    paste(capture.output(print(delphi_validity(d, lo = 1, hi = 4, B = 0, ...))),
          collapse = " ")
  }
  k <- text()
  expect_match(k, "weighted kappa \\(quadratic weights\\)")
  expect_match(k, "Fleiss & Cohen, 1973")
  expect_match(k, "No verbal labels")
  expect_false(grepl("Almost perfect|almost perfect agreement", k))
  expect_match(k, "Diamond et al. \\(2014\\)")

  expect_match(text(kappa_weights = "linear"), "counts twice a change of one")
  expect_match(text(stability = "lambda"), "predictability, not agreement")
  expect_match(text(stability = "chisq_individual"), "significant result \\(p < alpha\\)")
  expect_match(text(stability = "chisq_group"), "non-significant")
  expect_match(text(stability = "percent_change"), "no statistical theory")
  expect_match(text(consensus_threshold = 0.75), "fixed before the study")

  s <- paste(capture.output(print(summary(delphi_validity(
    d, lo = 1, hi = 4, consensus_threshold = 0.75, B = 0)))), collapse = " ")
  expect_match(s, "Consensus: 3 of 4")
})

test_that("the round fits feed compare_rounds, and reporting works", {
  fit <- delphi_validity(small_delphi(), lo = 1, hi = 4, B = 0)
  expect_length(fit$details$round_fits, 2L)
  expect_s3_class(fit$details$round_fits[[1]], "contentvalid_expert")
  cmp <- do.call(compare_rounds, unname(fit$details$round_fits))
  expect_s3_class(cmp, "contentvalid_rounds")

  expect_s3_class(fit, "contentvalid_workflow")
  expect_identical(fit$workflow, "delphi")
  rep <- content_report(fit)
  expect_true(all(c("item", "prop_agree", "prop_unchanged", "stability") %in% names(rep)))
})

# Two raters, Schizoid PD, from Wongpakaran et al. (2013): cells No-No = 13,
# No-Yes = 2, Yes-No = 1, Yes-Yes = 3. Reported AC1 = .752, kappa = .565.
wongpakaran_table <- function() {
  rbind(
    VU = c(rep(0, 13), 0, 0, 1, rep(1, 3)),
    MN = c(rep(0, 13), 1, 1, 0, rep(1, 3))
  )
}

krippendorff_panel <- function() {
  rbind(
    A = c(1, 2, 3, 3, 2, 1, 4, 1, 2, NA, NA, NA),
    B = c(1, 2, 3, 3, 2, 2, 4, 1, 2, 5, NA, 3),
    C = c(NA, 3, 3, 3, 2, 3, 4, 2, 2, 5, 1, NA),
    D = c(1, 2, 3, 3, 2, 4, 4, 1, 2, 5, 1, NA)
  )
}

test_that("AC1 reproduces the published Wongpakaran et al. (2013) table", {
  X <- wongpakaran_table()
  res <- contentvalidR:::.gwet_ac1(X)
  expect_equal(res$pa, 16 / 19)
  q <- 9 / 38
  expect_equal(res$pe, 2 * q * (1 - q))

  # The paper prints AC1 = .752. The exact value is 0.7527, so the printed
  # figure appears truncated; it agrees within the paper's three decimals.
  expect_lt(abs(res$estimate - 0.752), 0.001)

  # Kappa from the same table reproduces the paper's .565, confirming the cells
  # were transcribed in the right orientation.
  p_vu <- mean(X["VU", ] == 1)
  p_mn <- mean(X["MN", ] == 1)
  e_kappa <- p_vu * p_mn + (1 - p_vu) * (1 - p_mn)
  expect_equal(round((16 / 19 - e_kappa) / (1 - e_kappa), 3), 0.565)
})

test_that("AC1 with missing ratings follows Gwet's implementation", {
  X <- rbind(
    c(1, 1, 0, 1, NA),
    c(1, 0, 0, 1, 1),
    c(1, 1, NA, 1, NA)
  )
  res <- contentvalidR:::.gwet_ac1(X)

  counts <- sapply(seq_len(ncol(X)), function(i) {
    x <- X[!is.na(X[, i]), i]
    c(sum(x == 0), sum(x == 1))
  })
  r <- colSums(counts)
  paired <- r >= 2
  pa <- mean(colSums(counts[, paired] * (counts[, paired] - 1)) /
               (r[paired] * (r[paired] - 1)))
  pi_q <- rowMeans(sweep(counts, 2, r, "/"))
  pe <- sum(pi_q * (1 - pi_q)) / (2 - 1)

  expect_equal(res$pa, pa)
  expect_equal(res$pe, pe)
  expect_equal(res$estimate, (pa - pe) / (1 - pe))
  # The last item has a single rating: it informs category probabilities but
  # contributes no rating pair.
  expect_equal(res$n_items, 4L)
})

test_that("unanimous ratings give AC1 of 1", {
  expect_equal(contentvalidR:::.gwet_ac1(matrix(1, nrow = 4, ncol = 6))$estimate, 1)
})

test_that("panel_agreement defaults to ordinal Krippendorff's alpha", {
  fit <- panel_agreement(krippendorff_panel(), B = 0)
  expect_s3_class(fit, "contentvalid_agreement")
  expect_equal(fit$method, "krippendorff")
  expect_equal(fit$level, "ordinal")
  expect_equal(round(fit$estimate, 3), 0.815)
  expect_equal(fit$n_items, 11L)
  expect_equal(fit$n_raters, 4L)
})

test_that("the measurement level is selectable", {
  X <- krippendorff_panel()
  expect_equal(round(panel_agreement(X, level = "nominal", B = 0)$estimate, 3), 0.743)
  expect_equal(round(panel_agreement(X, level = "interval", B = 0)$estimate, 3), 0.849)
})

test_that("percent agreement counts identical within-item rating pairs", {
  X <- krippendorff_panel()
  same <- 0
  total <- 0
  for (u in seq_len(ncol(X))) {
    x <- X[!is.na(X[, u]), u]
    if (length(x) < 2) next
    pairs <- utils::combn(x, 2)
    same <- same + sum(pairs[1, ] == pairs[2, ])
    total <- total + ncol(pairs)
  }
  expect_equal(panel_agreement(X, B = 0)$percent_agreement, same / total)
})

test_that("intervals are reproducible with a seed and absent when B is 0", {
  X <- krippendorff_panel()
  a <- panel_agreement(X, B = 200, seed = 11)
  b <- panel_agreement(X, B = 200, seed = 11)
  expect_identical(a$ci_low, b$ci_low)
  expect_identical(a$ci_high, b$ci_high)
  expect_lte(a$ci_low, a$estimate)
  expect_gte(a$ci_high, a$estimate)

  none <- panel_agreement(X, B = 0)
  expect_true(is.na(none$ci_low) && is.na(none$ci_high))
})

test_that("AC1 is selectable, ignores level, and always prints the critique", {
  fit <- panel_agreement(wongpakaran_table(), method = "ac1", level = "interval", B = 0)
  expect_equal(fit$method, "ac1")
  expect_true(is.na(fit$level))
  expect_lt(abs(fit$estimate - 0.752), 0.001)
  expect_match(fit$critique, "Vach and Gerke \\(2023\\)")

  out <- paste(capture.output(print(fit)), collapse = " ")
  expect_match(out, "not the default")
  expect_match(out, "Landis and Koch")

  boot <- paste(capture.output(print(
    panel_agreement(wongpakaran_table(), method = "ac1", B = 100, seed = 2)
  )), collapse = " ")
  expect_match(boot, "this package's\\s+extension")
})

test_that("Krippendorff output explains low alpha on a close-agreeing panel", {
  X <- matrix(4, nrow = 6, ncol = 10)
  X[1, 1] <- 3
  X[2, 5] <- 3
  X[3, 9] <- 3
  fit <- panel_agreement(X, B = 0)
  # Seven items have 30 identical ordered pairs; the three with one dissenter
  # have 20 of 30.
  expect_equal(fit$percent_agreement, 270 / 300)

  out <- paste(capture.output(print(fit)), collapse = " ")
  expect_match(out, "Identical rating pairs")
  expect_match(out, "not by itself\\s+evidence of a poor panel")
  expect_match(out, "no publication applying it specifically")
  expect_match(out, "does not show that the items are relevant")
})

test_that("a panel with no variation reports an undefined coefficient", {
  fit <- panel_agreement(matrix(4, nrow = 4, ncol = 5), B = 0)
  expect_true(is.na(fit$estimate))
  expect_match(fit$interpretation, "undefined")
})

test_that("logical ratings are accepted", {
  X <- rbind(c(TRUE, TRUE, FALSE), c(TRUE, FALSE, FALSE), c(TRUE, TRUE, FALSE))
  expect_s3_class(panel_agreement(X, method = "ac1", B = 0), "contentvalid_agreement")
})

test_that("malformed inputs are rejected", {
  X <- krippendorff_panel()
  expect_error(panel_agreement(matrix(letters[1:6], 2)), "must be numeric")
  expect_error(panel_agreement(matrix(1:3, nrow = 1)), "at least two raters")
  expect_error(panel_agreement(matrix(1:3, ncol = 1)), "at least two raters")
  expect_error(panel_agreement(X, B = -1), "non-negative integer")
  expect_error(panel_agreement(X, B = 2.5), "non-negative integer")
  expect_error(panel_agreement(X, alpha = 0), "strictly between 0 and 1")
  expect_error(panel_agreement(X, seed = "a"), "NULL or one number")
  expect_error(panel_agreement(X, method = "fleiss"), "should be one of")
  expect_error(panel_agreement(X, level = "ratio"), "should be one of")
  Xinf <- X
  Xinf[1, 1] <- Inf
  expect_error(panel_agreement(Xinf), "infinite")
  expect_error(print(panel_agreement(X, B = 0), digits = -1), "nonnegative integer")
})

expert_panel <- function() {
  matrix(
    c(4, 4, 3, 4,  4, 3, 4, 4,  3, 3, 4, 3,  2, 2, 1, 2,  4, 4, 4, 3),
    nrow = 4, dimnames = list(NULL, paste0("Item", 1:5))
  )
}

test_that("expert_validity() reports Krippendorff's alpha on the ratings by default", {
  X <- expert_panel()
  fit <- expert_validity(X, mode = "relevance", lo = 1, hi = 4, seed = 5)
  direct <- panel_agreement(X, B = 1000, seed = 5)

  expect_equal(fit$settings$agreement, "krippendorff")
  expect_equal(fit$settings$agreement_level, "ordinal")
  expect_s3_class(fit$details$agreement, "contentvalid_agreement")
  expect_equal(fit$scale_summary$agreement, direct$estimate)
  expect_equal(fit$scale_summary$agreement_low, direct$ci_low)
  expect_equal(fit$scale_summary$agreement_high, direct$ci_high)
  expect_identical(fit$scale, fit$scale_summary)

  again <- expert_validity(X, mode = "relevance", lo = 1, hi = 4, seed = 5)
  expect_identical(again$scale_summary, fit$scale_summary)
})

test_that("expert_validity() computes AC1 on the relevance decision", {
  X <- expert_panel()
  fit <- expert_validity(X, mode = "relevance", lo = 1, hi = 4,
                         agreement = "ac1", agreement_B = 0)
  expect_equal(fit$scale_summary$agreement,
               panel_agreement(X >= 3, method = "ac1", B = 0)$estimate)
  expect_true(is.na(fit$settings$agreement_level))

  out <- paste(capture.output(print(fit)), collapse = " ")
  expect_match(out, "Gwet's\\s+AC1")
  expect_match(out, "Vach\\s+and\\s+Gerke\\s+\\(2023\\)")
})

test_that("expert_validity() passes the measurement level and can skip agreement", {
  X <- expert_panel()
  interval <- expert_validity(X, mode = "relevance", lo = 1, hi = 4,
                              agreement_level = "interval", agreement_B = 0)
  expect_equal(interval$scale_summary$agreement,
               panel_agreement(X, level = "interval", B = 0)$estimate)

  none <- expert_validity(X, mode = "relevance", lo = 1, hi = 4, agreement = "none")
  expect_true(is.na(none$scale_summary$agreement))
  expect_null(none$details$agreement)
  expect_false(grepl("Panel agreement|Panel-level agreement",
                     paste(capture.output(print(none)), collapse = " ")))
})

test_that("expert_validity() explains agreement output and small panels", {
  X <- expert_panel()
  out <- paste(capture.output(print(
    expert_validity(X, mode = "relevance", lo = 1, hi = 4, seed = 1)
  )), collapse = " ")
  expect_match(out, "Panel\\s+agreement,\\s+Krippendorff's\\s+alpha\\s+\\(ordinal\\)")
  expect_match(out, "Identical\\s+rating\\s+pairs")
  expect_match(out, "not\\s+by\\s+itself\\s+evidence\\s+of\\s+a\\s+poor\\s+panel")
  expect_match(out, "Panel-level agreement")

  one_item <- expert_validity(cbind(I1 = c(4, 4, 3, 4)), mode = "relevance", lo = 1, hi = 4)
  expect_true(is.na(one_item$scale_summary$agreement))
  expect_match(paste(capture.output(print(one_item)), collapse = " "),
               "needs\\s+at\\s+least\\s+two\\s+experts\\s+and\\s+two\\s+items")

  s <- paste(capture.output(print(summary(
    expert_validity(X, mode = "relevance", lo = 1, hi = 4, agreement_B = 0)
  ))), collapse = " ")
  expect_match(s, "Panel\\s+agreement")

  expect_error(expert_validity(X, mode = "relevance", agreement_B = -5),
               "`agreement_B` must be")
  expect_error(expert_validity(X, mode = "relevance", seed = "x"), "`seed` must be")
})

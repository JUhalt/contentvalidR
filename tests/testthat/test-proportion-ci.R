ci_cases <- rbind(
  expand.grid(x = 0:6, n = 6),
  expand.grid(x = 0:10, n = 10),
  data.frame(x = c(0, 1, 17, 19, 20), n = 20)
)

test_that("Wilson intervals match prop.test without continuity correction", {
  for (a in c(0.10, 0.05, 0.01)) {
    ci <- contentvalidR:::.proportion_ci(ci_cases$x, ci_cases$n, "wilson", alpha = a)
    for (i in seq_len(nrow(ci_cases))) {
      ref <- suppressWarnings(stats::prop.test(
        ci_cases$x[i], ci_cases$n[i], conf.level = 1 - a, correct = FALSE
      ))$conf.int
      expect_equal(ci$low[i], ref[1], tolerance = 1e-10)
      expect_equal(ci$high[i], ref[2], tolerance = 1e-10)
    }
  }
})

test_that("exact intervals match binom.test (Clopper-Pearson)", {
  for (a in c(0.10, 0.05, 0.01)) {
    ci <- contentvalidR:::.proportion_ci(ci_cases$x, ci_cases$n, "exact", alpha = a)
    for (i in seq_len(nrow(ci_cases))) {
      ref <- stats::binom.test(ci_cases$x[i], ci_cases$n[i], conf.level = 1 - a)$conf.int
      expect_equal(ci$low[i], ref[1], tolerance = 1e-10)
      expect_equal(ci$high[i], ref[2], tolerance = 1e-10)
    }
  }
})

test_that("Agresti-Coull intervals follow the published adjusted Wald formula", {
  z <- stats::qnorm(0.975)
  ci <- contentvalidR:::.proportion_ci(ci_cases$x, ci_cases$n, "agresti_coull", alpha = 0.05)
  n_adj <- ci_cases$n + z^2
  p_adj <- (ci_cases$x + z^2 / 2) / n_adj
  half <- z * sqrt(p_adj * (1 - p_adj) / n_adj)
  expect_equal(ci$low, pmax(0, p_adj - half), tolerance = 1e-12)
  expect_equal(ci$high, pmin(1, p_adj + half), tolerance = 1e-12)

  # Agresti and Coull (1998) summarize the 95% interval as "add two successes and
  # two failures, then use the Wald formula". The general-z version must stay
  # close to that published rule of thumb.
  p_rule <- (ci_cases$x + 2) / (ci_cases$n + 4)
  half_rule <- 1.96 * sqrt(p_rule * (1 - p_rule) / (ci_cases$n + 4))
  expect_lt(max(abs(ci$low - pmax(0, p_rule - half_rule))), 0.01)
  expect_lt(max(abs(ci$high - pmin(1, p_rule + half_rule))), 0.01)
})

test_that("every method stays within [0, 1]", {
  for (m in c("wilson", "agresti_coull", "exact")) {
    ci <- contentvalidR:::.proportion_ci(ci_cases$x, ci_cases$n, m)
    expect_true(all(ci$low >= 0 & ci$high <= 1), info = m)
    expect_true(all(ci$low <= ci$high), info = m)
  }
})

test_that("Wilson and exact intervals contain the observed proportion", {
  p <- ci_cases$x / ci_cases$n
  for (m in c("wilson", "exact")) {
    ci <- contentvalidR:::.proportion_ci(ci_cases$x, ci_cases$n, m)
    expect_true(all(ci$low <= p + 1e-12 & p - 1e-12 <= ci$high), info = m)
  }
})

test_that("zero and unanimous endorsement reach the bounds", {
  w <- contentvalidR:::.proportion_ci(c(0, 8), c(8, 8), "wilson")
  e <- contentvalidR:::.proportion_ci(c(0, 8), c(8, 8), "exact")
  expect_equal(w$low[1], 0)
  expect_equal(w$high[2], 1)
  expect_equal(e$low[1], 0)
  expect_equal(e$high[2], 1)
})

test_that("intervals narrow as the number of ratings grows", {
  ci <- contentvalidR:::.proportion_ci(c(5, 10, 40), c(10, 20, 80), "wilson")
  width <- ci$high - ci$low
  expect_true(all(diff(width) < 0))
})

test_that("empty panels, missing inputs, and 'none' yield NA", {
  ci <- contentvalidR:::.proportion_ci(c(0, NA, 3), c(0, 5, NA), "wilson")
  expect_true(all(is.na(ci$low)))
  expect_true(all(is.na(ci$high)))

  none <- contentvalidR:::.proportion_ci(ci_cases$x, ci_cases$n, "none")
  expect_true(all(is.na(none$low)) && all(is.na(none$high)))
})

test_that("invalid methods and alpha levels are rejected", {
  expect_error(contentvalidR:::.proportion_ci(3, 5, "wald"), "should be one of")
  expect_error(contentvalidR:::.proportion_ci(3, 5, alpha = 0), "strictly between 0 and 1")
  expect_error(contentvalidR:::.proportion_ci(3, 5, alpha = 1), "strictly between 0 and 1")
  expect_error(contentvalidR:::.proportion_ci(3, 5, alpha = NA_real_), "strictly between 0 and 1")
})

test_that("the method note names the method, its source, and its level", {
  expect_match(contentvalidR:::.proportion_ci_note("wilson", 0.05), "95% intervals")
  expect_match(contentvalidR:::.proportion_ci_note("wilson", 0.05), "Wilson score \\(the default\\)")
  expect_match(contentvalidR:::.proportion_ci_note("wilson", 0.05), "Newcombe \\(1998\\)")
  expect_match(contentvalidR:::.proportion_ci_note("exact", 0.10), "90% intervals")
  expect_match(contentvalidR:::.proportion_ci_note("exact", 0.05), "conservative")
  expect_match(contentvalidR:::.proportion_ci_note("agresti_coull", 0.05), "Agresti and Coull \\(1998\\)")
  expect_match(contentvalidR:::.proportion_ci_note("none", 0.05), "not computed")
})

test_that("cvi() reports I-CVI intervals with a selectable method", {
  M <- matrix(c(1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0), nrow = 4,
              dimnames = list(NULL, c("Item1", "Item2", "Item3")))

  fit <- cvi(M)
  il <- fit$item_level
  expect_true(all(c("I_CVI_low", "I_CVI_high") %in% names(il)))
  ref <- contentvalidR:::.proportion_ci(il$A, il$N, "wilson")
  expect_equal(il$I_CVI_low, ref$low)
  expect_equal(il$I_CVI_high, ref$high)
  expect_equal(fit$ci, "wilson")
  expect_equal(fit$alpha, 0.05)

  exact <- cvi(M, ci = "exact")$item_level
  ref_b <- stats::binom.test(3, 4)$conf.int
  expect_equal(exact$I_CVI_low[2], ref_b[1], tolerance = 1e-10)
  expect_equal(exact$I_CVI_high[2], ref_b[2], tolerance = 1e-10)

  none <- cvi(M, ci = "none")$item_level
  expect_true(all(is.na(none$I_CVI_low)))
  # Point estimates are unchanged by the interval choice.
  expect_equal(none$I_CVI, il$I_CVI)
})

test_that("compute_psa() reports Psa intervals with a selectable method", {
  df <- data.frame(
    item = rep(c("I1", "I2"), each = 4),
    rater = rep(1:4, 2),
    assigned_construct = c("A", "A", "A", "B", "B", "A", "B", "B"),
    target_construct = rep(c("A", "B"), each = 4)
  )
  psa <- compute_psa(df)
  expect_true(all(c("psa_low", "psa_high") %in% names(psa)))
  ref <- contentvalidR:::.proportion_ci(psa$n_target, psa$n, "wilson")
  expect_equal(psa$psa_low, ref$low)
  expect_equal(psa$psa_high, ref$high)

  exact <- compute_psa(df, ci = "exact", alpha = 0.10)
  ref_b <- stats::binom.test(3, 4, conf.level = 0.90)$conf.int
  expect_equal(exact$psa_low[1], ref_b[1], tolerance = 1e-10)
  expect_equal(exact$psa_high[1], ref_b[2], tolerance = 1e-10)
})

test_that("expert_validity() carries I-CVI intervals without disturbing Aiken's V intervals", {
  x <- cbind(Clear = c(4, 4, 4, 4, 4, 4), Mixed = c(4, 3, 3, 2, 3, 2))
  fit <- expert_validity(x, mode = "relevance", lo = 1, hi = 4)
  r <- fit$results

  expect_true(all(c("I_CVI_low", "I_CVI_high", "ci_low", "ci_high") %in% names(r)))
  expect_equal(fit$settings$proportion_ci, "wilson")

  aiken <- aikens_v(x, lo = 1, hi = 4, ci = "score")
  expect_equal(r$ci_low, aiken$ci_low)
  expect_equal(r$ci_high, aiken$ci_high)

  exact <- expert_validity(x, mode = "relevance", lo = 1, hi = 4, proportion_ci = "exact")
  expect_equal(exact$settings$proportion_ci, "exact")
  expect_match(paste(capture.output(print(exact)), collapse = " "), "Clopper-Pearson")
  expect_match(paste(capture.output(print(fit)), collapse = " "), "Wilson score")
})

test_that("sort_validity() carries Psa intervals and names the method", {
  d <- data.frame(
    item = rep(c("A1", "B1"), each = 10),
    rater = rep(1:10, 2),
    assigned_construct = c(rep("A", 9), "B", rep("B", 6), rep("A", 4)),
    target_construct = rep(c("A", "B"), each = 10)
  )
  fit <- sort_validity(d)
  r <- fit$results
  expect_true(all(c("psa_low", "psa_high") %in% names(r)))
  expect_equal(fit$settings$proportion_ci, "wilson")

  ref <- contentvalidR:::.proportion_ci(r$n_target, r$n, "wilson", alpha = fit$settings$alpha)
  expect_equal(r$psa_low, ref$low)

  exact <- sort_validity(d, proportion_ci = "exact")
  ref_b <- stats::binom.test(9, 10, conf.level = 0.95)$conf.int
  expect_equal(exact$results$psa_low[exact$results$item == "A1"], ref_b[1], tolerance = 1e-10)
  expect_match(paste(capture.output(print(exact)), collapse = " "), "Clopper-Pearson")

  expect_error(sort_validity(d, proportion_ci = "wald"), "should be one of")
})

test_that("missing ratings use each item's effective number of ratings", {
  x <- cbind(I1 = c(4, 4, NA, 3, 4, 2), I2 = c(4, 4, 4, 4, 4, 4))
  fit <- expert_validity(x, mode = "relevance", lo = 1, hi = 4, na.rm = TRUE)
  r <- fit$results
  ref <- contentvalidR:::.proportion_ci(r$A, r$N, "wilson")
  expect_equal(r$I_CVI_low, ref$low)
  expect_equal(r$N[r$item == "I1"], 5L)
})

panel_ratings <- function() {
  r <- rbind(
    c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
    c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(4, 3, 4, 3, 1, 2),
    c(4, 4, 3, 4, 2, 2), c(2, 2, 2, 2, 1, 1)
  )
  dimnames(r) <- list(paste0("Judge", 1:8), paste0("Item", 1:6))
  r
}

test_that("judge_validity returns a conforming workflow object with judge-level rows", {
  fit <- judge_validity(panel_ratings(), lo = 1, hi = 4)

  expect_s3_class(fit, "contentvalid_judge")
  expect_s3_class(fit, "contentvalid_workflow")
  expect_true(all(c("results", "scale_summary", "settings", "design", "details") %in% names(fit)))
  expect_equal(nrow(fit$results), 8L)
  expect_equal(fit$results$judge, paste0("Judge", 1:8))
  expect_true(all(fit$results$status %in% contentvalidR:::.workflow_status_levels))
  expect_true(all(nzchar(fit$results$interpretation)))
})

test_that("severity is signed so that positive means harsher, on both scales", {
  fit <- judge_validity(panel_ratings(), lo = 1, hi = 4)
  r <- fit$results

  harshest <- r$judge[which.max(r$severity_raw)]
  expect_equal(harshest, "Judge8")
  expect_gt(r$severity_raw[r$judge == "Judge8"], 0)
  expect_lt(r$mean_rating[r$judge == "Judge8"], mean(r$mean_rating[r$judge != "Judge8"]))

  # Raw severity must be a strictly decreasing function of the judge's mean.
  expect_equal(order(r$severity_raw), order(-r$mean_rating))
})

test_that("a plainly severe judge is flagged even when logit severity is unavailable", {
  fit <- judge_validity(panel_ratings(), lo = 1, hi = 4)
  # This panel agrees almost completely on the dichotomized decision, so the
  # facets model is not estimable. The fallback must still catch Judge8.
  expect_false(fit$scale_summary$severity_estimable)
  expect_true(all(is.na(fit$results$severity)))
  expect_equal(fit$results$status[fit$results$judge == "Judge8"], "Review")
  expect_equal(fit$results$recommendation[fit$results$judge == "Judge8"], "Severe")
  expect_match(fit$results$interpretation[fit$results$judge == "Judge8"], "rating points")
})

test_that("logit severity is estimated and reported when the design supports it", {
  set.seed(11)
  n_j <- 10; n_i <- 40
  sev <- seq(-1.2, 1.2, length.out = n_j)
  easy <- seq(-1.5, 1.5, length.out = n_i)
  p <- 1 / (1 + exp(-(outer(rep(1, n_j), easy) - outer(sev, rep(1, n_i)))))
  B <- matrix(stats::rbinom(n_j * n_i, 1, as.vector(p)), nrow = n_j)
  # Map the binary endorsement onto a 1-4 relevance scale.
  X <- ifelse(B == 1, 4, 2)
  dimnames(X) <- list(paste0("J", 1:n_j), paste0("I", 1:n_i))

  fit <- judge_validity(X, lo = 1, hi = 4)
  expect_true(fit$scale_summary$severity_estimable)
  est <- fit$results$severity
  expect_true(sum(!is.na(est)) >= 8L)
  # Recovered severity must track the simulated severity ordering.
  expect_gt(stats::cor(sev, est, use = "complete.obs"), 0.85)
  # Centred on the panel.
  expect_equal(mean(est, na.rm = TRUE), 0, tolerance = 1e-6)
  expect_true(all(fit$results$se[!is.na(est)] > 0))
})

test_that("the bias correction is applied and reported", {
  set.seed(12)
  X <- ifelse(matrix(stats::rbinom(10 * 20, 1, 0.6), nrow = 10), 4, 2)
  dimnames(X) <- list(paste0("J", 1:10), paste0("I", 1:20))

  corrected <- judge_validity(X, lo = 1, hi = 4, bias_correct = TRUE)
  raw <- judge_validity(X, lo = 1, hi = 4, bias_correct = FALSE)

  skip_if_not(corrected$scale_summary$severity_estimable)
  expect_lt(corrected$settings$bias_correction, 1)
  expect_equal(raw$settings$bias_correction, 1)
  # Correction shrinks the spread of severity estimates toward zero.
  expect_lt(stats::sd(corrected$results$severity, na.rm = TRUE),
            stats::sd(raw$results$severity, na.rm = TRUE))
})

test_that("leave-one-judge-out influence identifies items resting on one judge", {
  # Six judges put the CVI criterion at 0.78; an item endorsed by five of six
  # clears it. Dropping any endorsing judge moves the panel to five judges,
  # where the criterion rises to 1.00 and the item no longer clears.
  X <- rbind(
    c(4, 4, 4), c(4, 4, 4), c(4, 4, 4),
    c(4, 4, 4), c(4, 4, 4), c(2, 4, 4)
  )
  dimnames(X) <- list(paste0("J", 1:6), c("Fragile", "Solid1", "Solid2"))

  fit <- judge_validity(X, lo = 1, hi = 4)
  expect_gt(fit$scale_summary$n_influential, 0L)
  expect_gt(fit$scale_summary$n_fragile_items, 0L)

  fragile <- fit$details$influence_items
  expect_true("Fragile" %in% fragile$item[fragile$fragile %in% TRUE])

  influential <- fit$results[fit$results$n_items_flipped > 0, ]
  expect_true(all(influential$status == "Review"))
  expect_match(influential$interpretation[1], "rests on this one judge")
  # The output must warn that removing a judge also shrinks the panel.
  expect_match(influential$interpretation[1], "reduces the panel size")
})

test_that("a unanimous panel reports no single-judge dependence", {
  X <- matrix(4, nrow = 6, ncol = 5,
              dimnames = list(paste0("J", 1:6), paste0("I", 1:5)))
  fit <- judge_validity(X, lo = 1, hi = 4)

  expect_equal(fit$scale_summary$n_fragile_items, 0L)
  expect_equal(fit$scale_summary$n_influential, 0L)
  expect_false(fit$scale_summary$severity_estimable)
  expect_match(fit$details$severity_note, "agreed almost completely")
})

test_that("generalizability results are carried through to the panel summary", {
  X <- panel_ratings()
  fit <- judge_validity(X, lo = 1, hi = 4)
  gt <- gtheory_content(X, na.rm = TRUE)

  expect_equal(fit$scale_summary$phi_coefficient, gt$coefficients$phi_coefficient)
  expect_equal(fit$scale_summary$g_coefficient, gt$coefficients$g_coefficient)
  expect_s3_class(fit$details$gtheory, "contentvalid_gtheory")
})

test_that("missing ratings require explicit permission and are reported", {
  X <- panel_ratings()
  X[2, 3] <- NA
  expect_error(judge_validity(X, lo = 1, hi = 4), "missing values")

  fit <- judge_validity(X, lo = 1, hi = 4, na.rm = TRUE)
  expect_equal(fit$design$n_missing, 1L)
  expect_equal(fit$results$n_ratings[2], 5L)
  expect_equal(fit$design$gtheory_judges_dropped, 1L)
})

test_that("malformed inputs are rejected", {
  X <- panel_ratings()
  expect_error(judge_validity(X, lo = 4, hi = 1), "hi > lo")
  expect_error(judge_validity(X, lo = 1, hi = 4, relevance_cut = 9), "within the rating scale")
  expect_error(judge_validity(X, lo = 1, hi = 4, severity_cut = 0), "positive number")
  expect_error(judge_validity(X, lo = 1, hi = 4, severity_raw_cut = -1), "positive number")
  expect_error(judge_validity(X, lo = 1, hi = 4, fit_range = c(1.5, 0.5)), "increasing positive")
  expect_error(judge_validity(X, lo = 1, hi = 4, fit_range = 1), "increasing positive")
  expect_error(judge_validity(X, lo = 1, hi = 4, na.rm = NA), "TRUE or FALSE")

  out_of_range <- X
  out_of_range[1, 1] <- 9
  expect_error(judge_validity(out_of_range, lo = 1, hi = 4), "outside the \\[lo, hi\\] scale bounds")

  expect_error(judge_validity(matrix(letters[1:12], nrow = 3), lo = 1, hi = 4),
               "must be numeric")
})

test_that("very small panels degrade without error", {
  X <- rbind(c(4, 4, 3), c(3, 4, 4))
  dimnames(X) <- list(c("J1", "J2"), paste0("I", 1:3))
  fit <- judge_validity(X, lo = 1, hi = 4)

  expect_equal(nrow(fit$results), 2L)
  expect_true(all(is.na(fit$results$n_items_flipped)))
  expect_true(all(nzchar(fit$results$interpretation)))
})

test_that("output states that a flagged judge is not a judge to delete", {
  fit <- judge_validity(panel_ratings(), lo = 1, hi = 4)
  printed <- paste(capture.output(print(fit)), collapse = " ")
  expect_match(printed, "not a judge to remove")
  expect_match(printed, "Positive severity means the judge rates lower")

  summarised <- paste(capture.output(print(summary(fit))), collapse = " ")
  expect_match(summarised, "does not establish that the items cover")
  expect_error(print(fit, digits = -1), "nonnegative integer")
})

test_that("summary exposes the standard workflow counts", {
  s <- summary(judge_validity(panel_ratings(), lo = 1, hi = 4))
  expect_s3_class(s, "summary.contentvalid_judge")
  expect_equal(s$n_supported + s$n_review + s$n_insufficient + s$n_descriptive,
               nrow(judge_validity(panel_ratings(), lo = 1, hi = 4)$results))
  expect_equal(s$workflow, "judge-heterogeneity")
})

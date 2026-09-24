test_that("relevance workflow combines Aiken and CVI evidence", {
  x <- cbind(
    Clear = c(4,4,4,4,4,4),
    Mixed = c(4,3,3,2,3,2)
  )
  fit <- expert_validity(x, mode = "relevance", lo = 1, hi = 4)
  expect_s3_class(fit, "contentvalid_expert")
  expect_equal(fit$mode, "relevance")
  expect_true(all(c("V", "ci_low", "ci_high", "I_CVI", "kappa_mod") %in% names(fit$results)))
  expect_equal(fit$results$recommendation[fit$results$item == "Clear"], "Strong support")
  expect_equal(fit$results$recommendation[fit$results$item == "Mixed"], "Review")
})

test_that("relevance workflow uses panel-size CVI guidelines", {
  x4 <- cbind(I1 = c(4,4,4,3), I2 = c(4,4,4,2))
  f4 <- expert_validity(x4, mode = "relevance", lo = 1, hi = 4)
  expect_equal(f4$results$cvi_criterion, c(1, 1))
  expect_equal(f4$results$recommendation[2], "Review")

  x6 <- cbind(I1 = c(4,4,4,4,4,3))
  f6 <- expert_validity(x6, mode = "relevance", lo = 1, hi = 4)
  expect_equal(f6$results$cvi_criterion, 5 / 6)
  expect_true(f6$results$I_CVI >= 5 / 6)
})

test_that("the I-CVI criterion is Lynn's table, in counts", {
  # Lynn (1986), Table 2: the fewest experts of n whose endorsement is needed.
  lynn <- c(`3` = 3, `4` = 4, `5` = 5, `6` = 5, `7` = 6, `8` = 7, `9` = 7,
            `10` = 8)
  n <- as.integer(names(lynn))
  expect_equal(contentvalidR:::.cvi_required_count(n), unname(as.integer(lynn)))
  expect_true(is.na(contentvalidR:::.cvi_required_count(2L)))
  # Beyond ten, Lynn's lowest tabled proportion (7 of 9) is held.
  expect_equal(contentvalidR:::.cvi_required_count(c(11L, 18L, 27L)),
               c(9L, 14L, 21L))
})

test_that("seven of nine experts meet the criterion, as Lynn's table says", {
  # The regression: the rule was stored as .78, and 7/9 = .778 fell short, so
  # the package demanded 8 of 9. Polit and Beck (2006) state the same case in
  # words: with nine raters there could be two not-relevant ratings.
  seven <- cbind(I1 = c(rep(4, 7), 2, 2))
  six <- cbind(I1 = c(rep(4, 6), 2, 2, 2))
  f7 <- expert_validity(seven, mode = "relevance", lo = 1, hi = 4)
  f6 <- expert_validity(six, mode = "relevance", lo = 1, hi = 4)
  expect_equal(f7$results$cvi_criterion, 7 / 9)
  expect_false(f7$results$recommendation == "Review")
  expect_identical(f6$results$recommendation, "Review")
})

test_that("an item's verdict never contradicts the criterion printed beside it", {
  for (n in 3:15) {
    for (k in 0:n) {
      x <- cbind(I1 = c(rep(4, k), rep(1, n - k)))
      r <- expert_validity(x, mode = "relevance", lo = 1, hi = 4)$results
      meets <- r$I_CVI >= r$cvi_criterion - 1e-12
      expect_identical(r$recommendation != "Review", meets,
                       info = sprintf("n = %d, k = %d", n, k))
    }
  }
})

test_that("relevance workflow does not use Aiken V as a universal deletion cutoff", {
  x <- cbind(I1 = c(4,4,4,4,3,3))
  fit <- expert_validity(x, mode = "relevance", lo = 1, hi = 4)
  expect_true(is.finite(fit$results$V))
  expect_match(fit$results$interpretation, "CVI guideline|Aiken", ignore.case = TRUE)
})

test_that("relevance workflow reports insufficient small panels", {
  x <- cbind(I1 = c(4,4))
  fit <- expert_validity(x, mode = "relevance", lo = 1, hi = 4)
  expect_equal(fit$results$recommendation, "Insufficient panel")
  expect_true(is.na(fit$results$cvi_criterion))
})

test_that("relevance workflow handles missing expert ratings", {
  x <- cbind(I1 = c(4,4,4,NA,3,4), I2 = c(4,3,4,4,4,4))
  fit <- expert_validity(x, mode = "relevance", lo = 1, hi = 4, na.rm = TRUE)
  expect_equal(fit$results$N, c(5L, 6L))
  expect_equal(fit$results$n_missing, c(1L, 0L))
  expect_equal(fit$scale$n_experts_min, 5L)
  expect_equal(fit$scale$n_experts_max, 6L)
})

test_that("relevance scale summary matches component summaries", {
  x <- cbind(I1 = c(4,4,4,4,3,4), I2 = c(4,4,3,4,4,4))
  fit <- expert_validity(x, mode = "relevance", lo = 1, hi = 4)
  expect_equal(fit$scale$mean_Aiken_V, mean(fit$results$V))
  expect_equal(fit$scale$S_CVI_Ave, mean(fit$results$I_CVI))
  expect_true(fit$scale$S_CVI_UA >= 0 && fit$scale$S_CVI_UA <= 1)
})

test_that("relevance cutoff can be declared explicitly", {
  x <- cbind(I1 = c(5,4,4,3,5,4))
  a <- expert_validity(x, mode = "relevance", lo = 1, hi = 5, relevance_cut = 4)
  b <- expert_validity(x, mode = "relevance", lo = 1, hi = 5)
  expect_equal(a$results$I_CVI, b$results$I_CVI)
  expect_error(expert_validity(x, mode = "relevance", lo = 1, hi = 5, relevance_cut = 6), "within")
})

test_that("essentiality workflow exposes exact CVR evidence", {
  fit <- expert_validity(c(10, 6), mode = "essentiality", N = 12)
  expect_s3_class(fit, "contentvalid_expert")
  expect_equal(fit$mode, "essentiality")
  expect_true(all(c("p_value", "critical_ne", "critical_cvr") %in% names(fit$results)))
  expect_equal(fit$results$recommendation, ifelse(fit$results$pass, "Supported", "Review"))
})

test_that("essentiality matrix workflow respects missingness", {
  x <- cbind(I1 = c(1,1,1,1,1,1), I2 = c(1,1,1,NA,0,0))
  fit <- expert_validity(x, mode = "essentiality", na.rm = TRUE)
  expect_equal(fit$results$N, c(6L, 5L))
  expect_equal(fit$scale$n_items, 2)
})

test_that("congruence workflow identifies strongest competitor", {
  d <- expand.grid(item = c("I1", "I2"), judge = 1:4, objective = c("A", "B"))
  d$target_objective <- ifelse(d$item == "I1", "A", "B")
  d$score <- ifelse(d$objective == d$target_objective, 1, -1)
  fit <- expert_validity(d, mode = "congruence")
  expect_s3_class(fit, "contentvalid_expert")
  expect_equal(fit$results$recommendation, rep("Target favored", 2))
  expect_true(all(fit$results$margin > 0))
  expect_equal(sort(fit$results$strongest_competitor), c("A", "B"))
})

test_that("congruence workflow detects ties and wrong-target dominance", {
  d <- data.frame(
    item = rep(c("Tie", "Wrong"), each = 6),
    judge = rep(rep(1:3, 2), 2),
    objective = rep(rep(c("A", "B"), each = 3), 2),
    target_objective = "A",
    score = c(1,1,0, 1,1,0, 0,0,0, 1,1,1)
  )
  fit <- expert_validity(d, mode = "congruence")
  expect_equal(fit$results$recommendation[fit$results$item == "Tie"], "Tie / review")
  expect_equal(fit$results$recommendation[fit$results$item == "Wrong"], "Review")
})

test_that("congruence without target mapping is descriptive", {
  d <- data.frame(
    item = rep("I1", 6), judge = rep(1:3, 2),
    objective = rep(c("A", "B"), each = 3),
    score = c(1,1,1, 0,0,-1)
  )
  fit <- expert_validity(d, mode = "congruence")
  expect_true(all(fit$results$recommendation == "Descriptive only"))
  expect_equal(nrow(fit$results), 2)
})

test_that("congruence rejects inconsistent targets", {
  d <- data.frame(
    item = c("I1", "I1"), judge = c(1,2), objective = c("A", "A"),
    score = c(1,1), target_objective = c("A", "B")
  )
  expect_error(expert_validity(d, mode = "congruence"), "exactly one")
})

test_that("expert print and summary methods return invisibly", {
  x <- cbind(I1 = c(4,4,4,4,4,4), I2 = c(4,3,3,2,3,2))
  fit <- expert_validity(x, mode = "relevance", lo = 1, hi = 4)
  expect_output(p <- print(fit), "expert-panel")
  expect_identical(p, fit)
  s <- summary(fit)
  expect_s3_class(s, "summary.contentvalid_expert")
  expect_output(ps <- print(s), "Summary")
  expect_identical(ps, s)
  expect_true(nrow(s$flagged) >= 1)
})

test_that("expert plotting works for relevance and essentiality", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  r <- expert_validity(cbind(I1 = c(4,4,4,4,3,4)), mode = "relevance", lo = 1, hi = 4)
  e <- expert_validity(c(10, 6), mode = "essentiality", N = 12)
  expect_identical(plot(r), r)
  expect_identical(plot(e), e)
})

test_that("congruence plotting requires target mapping", {
  d <- data.frame(
    item = rep("I1", 6), judge = rep(1:3, 2),
    objective = rep(c("A", "B"), each = 3), score = c(1,1,1, 0,0,-1)
  )
  fit <- expert_validity(d, mode = "congruence")
  expect_error(plot(fit), "target-objective")
})

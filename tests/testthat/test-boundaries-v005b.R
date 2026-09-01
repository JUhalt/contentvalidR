test_that("exact item-sort helpers reject non-finite inputs before stats calls", {
  expect_error(csv_binom_test(n_c = 1, N = Inf), "positive.*integer")
  expect_error(csv_binom_test(n_c = Inf, N = 10), "finite integer")
  expect_error(csv_binom_test(n_c = 1, N = 10, p0 = Inf), "finite probability")
  expect_error(csv_binom_test(n_c = 1, N = 10, alpha = -Inf), "finite probability")
  expect_error(sort_power(N = 10, true_p = .7, p0 = Inf), "finite probability")
})

test_that("Howard-Melloy exact boundaries remain discrete at tiny and canonical N", {
  tiny <- csv_binom_test(n_c = 1, N = 1)
  expect_true(is.na(tiny$critical_n_target))
  expect_false(tiny$passes_chance)

  n5 <- csv_binom_test(n_c = 5, N = 5)
  expect_equal(n5$critical_n_target, 5L)
  expect_true(n5$passes_chance)
  expect_equal(n5$p.value, 1 / 32)

  n10_fail <- csv_binom_test(n_c = 8, N = 10)
  n10_pass <- csv_binom_test(n_c = 9, N = 10)
  expect_equal(n10_pass$critical_n_target, 9L)
  expect_false(n10_fail$passes_chance)
  expect_true(n10_pass$passes_chance)
})

test_that("exact sort power handles probability extremes and impossible tiny-N criteria", {
  out <- sort_power(N = c(1, 5, 10), true_p = c(0, 1))$table
  expect_true(all(is.na(out$power[out$N == 1])))
  expect_equal(out$power[out$N == 5 & out$true_p == 0], 0)
  expect_equal(out$power[out$N == 5 & out$true_p == 1], 1)
  expect_equal(out$power[out$N == 10 & out$true_p == 0], 0)
  expect_equal(out$power[out$N == 10 & out$true_p == 1], 1)
})

test_that("Aiken bootstrap intervals tolerate all-missing item columns", {
  x <- cbind(
    Missing = c(NA, NA, NA, NA),
    Perfect = c(4, 4, 4, 4)
  )
  out <- aikens_v(x, lo = 1, hi = 4, ci = "bootstrap", B = 20,
                  seed = 1, na.rm = TRUE)
  expect_equal(out$N, c(0L, 4L))
  expect_true(is.na(out$V[1]))
  expect_true(is.na(out$ci_low[1]))
  expect_true(is.na(out$ci_high[1]))
  expect_equal(out$V[2], 1)
  expect_equal(out$ci_low[2], 1)
  expect_equal(out$ci_high[2], 1)
})

test_that("CVI reports a fully missing panel without fabricating scale evidence", {
  x <- matrix(NA_real_, nrow = 3, ncol = 2,
              dimnames = list(NULL, c("I1", "I2")))
  out <- cvi(x, na.rm = TRUE)
  expect_equal(out$item_level$N, c(0L, 0L))
  expect_true(all(is.na(out$item_level$I_CVI)))
  expect_true(all(is.na(out$item_level$kappa_mod)))
  expect_equal(out$scale_level$n_items, 0L)
  expect_true(is.na(out$scale_level$S_CVI_Ave))
  expect_true(is.na(out$scale_level$S_CVI_UA))
  expect_false(withVisible(print(out))$visible)
})

test_that("CVR handles zero-information and tiny panels explicitly", {
  x <- matrix(NA_real_, nrow = 3, ncol = 2,
              dimnames = list(NULL, c("I1", "I2")))
  out <- cvr(x, na.rm = TRUE)
  expect_equal(out$N, c(0L, 0L))
  expect_equal(out$ne, c(0L, 0L))
  expect_true(all(is.na(out$cvr)))
  expect_true(all(is.na(out$p_value)))
  expect_true(all(is.na(out$critical_ne)))
  expect_false(any(out$pass))

  one <- cvr(essential = 1, N = 1)
  expect_equal(one$cvr, 1)
  expect_equal(one$p_value, .5)
  expect_true(is.na(one$critical_ne))
  expect_false(one$pass)
})

test_that("IOC exposes all-missing cells as zero usable judges", {
  d <- data.frame(
    item = rep("I1", 4),
    judge = 1:4,
    objective = "A",
    score = NA_real_
  )
  out <- ioc(d, na.rm = TRUE)
  expect_equal(out$n_total, 4L)
  expect_equal(out$n_judges, 0L)
  expect_equal(out$n_missing, 4L)
  expect_true(is.na(out$ioc))
})

test_that("all-missing item-sort data remain analyzable as insufficient", {
  d <- data.frame(
    item = rep(c("A1", "B1"), each = 4),
    rater = rep(1:4, 2),
    assigned_construct = NA_character_,
    target_construct = rep(c("A", "B"), each = 4),
    stringsAsFactors = FALSE
  )
  fit <- sort_validity(d)
  expect_true(all(fit$results$n == 0L))
  expect_true(all(is.na(fit$results$psa)))
  expect_true(all(is.na(fit$results$csv)))
  expect_true(all(fit$results$recommendation == "Insufficient data"))
  expect_equal(summary(fit)$n_insufficient, 2L)

  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_identical(plot(fit, type = "item"), fit)
  expect_identical(plot(fit, type = "map"), fit)
})

test_that("all-missing construct ratings remain analyzable as insufficient", {
  d <- expand.grid(
    item = c("A1", "B1"), rater = 1:4, construct = c("A", "B"),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  d$target_construct <- ifelse(d$item == "A1", "A", "B")
  d$rating <- NA_real_
  fit <- rating_validity(d, scale_min = 1, scale_max = 5)
  expect_true(all(fit$results$n_complete == 0L))
  expect_true(all(is.na(fit$results$htc)))
  expect_true(all(is.na(fit$results$htd)))
  expect_true(all(fit$results$recommendation == "Insufficient data"))
  expect_equal(summary(fit)$n_insufficient, 2L)

  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_identical(plot(fit, type = "item"), fit)
  expect_identical(plot(fit, type = "map"), fit)
  expect_identical(plot(fit, type = "profile"), fit)
})

test_that("zero-variance rating profiles distinguish perfect separation from ties", {
  separated <- expand.grid(
    item = "I1", rater = 1:6, construct = c("A", "B"),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  separated$target_construct <- "A"
  separated$rating <- ifelse(separated$construct == "A", 5, 1)
  good <- rating_validity(separated, scale_min = 1, scale_max = 5)
  expect_equal(good$results$htc, 1)
  expect_equal(good$results$htd, 1)
  expect_equal(good$results$p_value, 0)
  expect_true(good$results$contrast_pass)
  expect_equal(good$results$recommendation, "Retain")

  tied <- separated
  tied$rating <- 3
  tie <- rating_validity(tied, scale_min = 1, scale_max = 5)
  expect_equal(tie$results$htd, 0)
  expect_true(is.na(tie$results$p_value))
  expect_equal(tie$results$recommendation, "Review")
  expect_equal(tie$results$issue, "Target tied with strongest competitor")
})

test_that("whitespace-only rating targets are rejected", {
  d <- expand.grid(item = "I1", rater = 1:4, construct = c("A", "B"),
                   KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  d$rating <- c(5, 4, 5, 4, 2, 2, 1, 2)
  d$target_construct <- "   "
  expect_error(htc(d), "target_col.*empty")

  d$target_construct <- "A"
  expect_error(htc(d, target_col = "   "), "non-empty column name")
})

test_that("whitespace-only congruence target-column names are rejected", {
  d <- expand.grid(item = "I1", judge = 1:3, objective = c("A", "B"),
                   KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  d$score <- ifelse(d$objective == "A", 1, -1)
  expect_error(expert_validity(d, mode = "congruence", target_col = "   "),
               "non-empty column name")
})

test_that("degenerate binary diagnostics retain full tables and undefined metrics", {
  s <- signal_detection(rep(TRUE, 4), rep(TRUE, 4))
  expect_equal(dim(s$confusion), c(2L, 2L))
  expect_equal(sum(s$confusion), 4L)
  expect_equal(s$accuracy, 1)
  expect_equal(s$sensitivity, 1)
  expect_true(is.na(s$specificity))
  expect_true(is.na(s$phi))
  expect_true(is.na(s$chisq))
  expect_true(is.na(s$p))

  r <- reproducibility_phi(rep(TRUE, 4), rep(TRUE, 4))
  expect_equal(dim(r$table), c(2L, 2L))
  expect_equal(sum(r$table), 4L)
  expect_true(is.na(r$phi))
  expect_true(is.na(r$chisq))
  expect_true(is.na(r$p))
})

test_that("expert workflows retain explicit insufficient and single-objective states", {
  rel <- expert_validity(
    matrix(NA_real_, nrow = 4, ncol = 2,
           dimnames = list(NULL, c("I1", "I2"))),
    mode = "relevance", lo = 1, hi = 4, na.rm = TRUE
  )
  expect_true(all(rel$results$recommendation == "Insufficient panel"))
  expect_equal(rel$scale$n_insufficient, 2L)

  ess <- expert_validity(
    matrix(NA_real_, nrow = 4, ncol = 2,
           dimnames = list(NULL, c("I1", "I2"))),
    mode = "essentiality", na.rm = TRUE
  )
  expect_true(all(ess$results$recommendation == "Insufficient data"))

  con <- data.frame(
    item = rep("I1", 4), judge = 1:4, objective = "A",
    score = 1, target_objective = "A"
  )
  cfit <- expert_validity(con, mode = "congruence")
  expect_equal(cfit$results$recommendation, "Target described")
  expect_true(is.na(cfit$results$competitor_ioc))
})

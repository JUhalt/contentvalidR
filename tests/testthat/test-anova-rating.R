test_that("anova_content uses repeated-measures ANOVA for crossed ratings", {
  d <- expand.grid(item = "I1", rater = 1:8, construct = c("A", "B", "C"))
  d$rating <- c(5,4,5,4,5,4,5,4,
                2,2,1,2,1,2,1,2,
                3,2,2,1,2,1,2,1)
  out <- anova_content(d, target_map = c(I1 = "A"), design = "auto")
  expect_equal(out$design, "within")
  expect_equal(out$n_complete, 8L)
  expect_true(out$p < .001)
  expect_true(out$contrast_pass)
  expect_true(out$posthoc_pass)
  expect_true(out$min_mean_diff > 0)
  expect_equal(nrow(attr(out, "contrasts")), 2L)
})

test_that("anova_content detects genuinely between-judge ratings", {
  d <- data.frame(
    item = "I1",
    rater = 1:18,
    construct = rep(c("A", "B", "C"), each = 6),
    rating = c(5,5,4,5,4,5, 2,2,1,2,1,2, 2,3,2,1,2,2)
  )
  out <- anova_content(d, target_map = c(I1 = "A"), design = "auto")
  expect_equal(out$design, "between")
  expect_true(out$p < .001)
  expect_true(out$contrast_pass)
})

test_that("Holm adjustment is available for planned contrasts", {
  d <- expand.grid(item = "I1", rater = 1:8, construct = c("A", "B", "C"))
  d$rating <- c(5,4,5,4,5,4,5,4,
                2,2,1,2,1,2,1,2,
                3,2,2,1,2,1,2,1)
  out <- anova_content(d, target_map = c(I1 = "A"), adjust = "holm")
  con <- attr(out, "contrasts")
  expect_true(all(con$p_adj >= con$p))
  expect_true(all(con$pass))
})

test_that("within-judge ANOVA reports incomplete judge profiles", {
  d <- expand.grid(item = "I1", rater = 1:6, construct = c("A", "B", "C"))
  d$rating <- c(5,4,5,4,5,4, 2,2,1,2,1,2, 3,2,2,1,2,1)
  d$rating[d$rater == "6" & d$construct == "C"] <- NA
  out <- anova_content(d, target_map = c(I1 = "A"), design = "within")
  expect_equal(out$n_raters, 6L)
  expect_equal(out$n_complete, 5L)
})

test_that("deprecated posthoc argument warns rather than silently changing meaning", {
  d <- expand.grid(item = "I1", rater = 1:4, construct = c("A", "B"))
  d$rating <- c(5,4,5,4,2,2,1,2)
  expect_warning(anova_content(d, target_map = c(I1 = "A"), posthoc = "tukey"), "deprecated")
})


test_that("anova_content can still return omnibus tests without target mapping", {
  d <- expand.grid(item = "I1", rater = 1:6, construct = c("A", "B"))
  d$rating <- c(5,4,5,4,5,4,2,2,1,2,1,2)
  out <- anova_content(d, design = "within")
  expect_true(is.na(out$target))
  expect_true(out$p < .001)
  expect_true(is.na(out$contrast_pass))
})


test_that("Greenhouse-Geisser epsilon matches a hand-checkable reference example", {
  y <- matrix(c(
    2.90,2.97,2.67,
    2.56,2.45,2.62,
    2.88,2.76,1.84,
    1.73,1.20,1.33,
    2.50,2.16,1.27,
    3.18,2.89,2.39,
    2.83,2.87,2.39,
    1.92,2.01,1.66
  ), nrow = 8, byrow = TRUE)
  expect_equal(contentvalidR:::.gg_epsilon(y), 0.7038461, tolerance = 1e-6)
})

test_that("within ANOVA reports Greenhouse-Geisser screening values", {
  set.seed(42)
  d <- expand.grid(item = "I1", rater = 1:20, construct = c("A", "B", "C"))
  d$target_construct <- "A"
  d$rating <- ifelse(d$construct == "A", rnorm(nrow(d), 4.5, .3), rnorm(nrow(d), 2, .4))
  out <- anova_content(d, design = "within")
  expect_true(is.finite(out$epsilon_gg))
  expect_true(out$epsilon_gg >= .5 && out$epsilon_gg <= 1)
  expect_equal(out$p_screen, out$p_gg)
  expect_true(out$p_screen < .001)
})

.make_sort_visual <- function() {
  d <- data.frame(
    item = rep(c("A1", "A2", "A3"), each = 20),
    rater = rep(1:20, 3),
    target_construct = "A",
    assigned_construct = c(
      rep("A", 18), rep("B", 2),
      rep("A", 15), rep("B", 5),
      rep("A", 10), rep("B", 10)
    )
  )
  sort_validity(d)
}

.make_rating_visual <- function() {
  d <- expand.grid(item = c("A1", "A2"), rater = 1:10,
                   construct = c("A", "B", "C"), KEEP.OUT.ATTRS = FALSE)
  d$target_construct <- "A"
  d$rating <- ifelse(
    d$item == "A1",
    ifelse(d$construct == "A", 5, ifelse(d$construct == "B", 2, 1)),
    ifelse(d$construct == "A", 3, ifelse(d$construct == "B", 4, 2))
  )
  rating_validity(d)
}

test_that("sort evidence map returns the workflow object invisibly", {
  fit <- .make_sort_visual()
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_identical(plot(fit, type = "map"), fit)
  expect_identical(plot(fit, type = "map", label = "all"), fit)
  expect_identical(plot(fit, type = "map", show_legend = FALSE), fit)
})

test_that("rating evidence map and target-competitor profile are plotable", {
  fit <- .make_rating_visual()
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_identical(plot(fit, type = "map"), fit)
  expect_identical(plot(fit, type = "profile"), fit)
  expect_identical(plot(fit, type = "profile", show_legend = FALSE), fit)
})

test_that("expert evidence plots retain the analysis object", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)

  rel <- expert_validity(
    cbind(I1 = c(4,4,4,4,3,4), I2 = c(4,3,3,2,3,2)),
    mode = "relevance", lo = 1, hi = 4
  )
  ess <- expert_validity(c(10, 6), mode = "essentiality", N = 12)
  d <- expand.grid(item = "I1", judge = 1:4, objective = c("A", "B"))
  d$target_objective <- "A"
  d$score <- ifelse(d$objective == "A", 1, -1)
  con <- expert_validity(d, mode = "congruence")

  expect_identical(plot(rel), rel)
  expect_identical(plot(rel, show_legend = FALSE), rel)
  expect_identical(plot(ess), ess)
  expect_identical(plot(con), con)
})

test_that("sort power plotting supports power and critical-boundary views", {
  p <- sort_power(N = seq(10, 30, by = 5), true_p = c(.60, .70, .80))
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_identical(plot(p), p)
  expect_identical(plot(p, reference_power = .80), p)
  expect_identical(plot(p, type = "critical"), p)
  expect_identical(plot(p, show_legend = FALSE), p)
  expect_error(plot(p, reference_power = 2), "between 0 and 1")
})


test_that("nearby scale-mean labels are deterministically separated", {
  x <- c(.70, .72, .90)
  y <- c(.40, .42, .70)
  pos1 <- .map_scale_label_y(x, y)
  pos2 <- .map_scale_label_y(x, y)

  expect_equal(pos1, pos2)
  expect_gt(abs(pos1[1] - pos1[2]), 0.04)
  expect_equal(pos1[3], y[3] - 0.06)
  expect_true(all(pos1 >= -0.94 & pos1 <= 0.94))
})


test_that("critical Psa curve represents every integer judge count", {
  curve <- .critical_psa_curve(c(10, 15, 20), p0 = .5, alpha = .05)

  expect_equal(curve$N, 10:20)
  expect_equal(curve$critical_n_target,
               vapply(10:20, .critical_target_count, integer(1), p0 = .5, alpha = .05))
  expect_equal(curve$minimum_observed_psa,
               curve$critical_n_target / curve$N)
  expect_equal(curve$minimum_observed_psa[curve$N == 10], .90)
  expect_equal(curve$minimum_observed_psa[curve$N == 20], .75)
})

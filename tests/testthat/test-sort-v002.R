test_that("compute_csv identifies strongest competing constructs including ties", {
  d <- data.frame(
    item = rep(c("I1", "I2"), each = 6),
    rater = rep(1:6, 2),
    target_construct = "A",
    assigned_construct = c("A", "A", "A", "B", "B", "C",
                           "A", "A", "B", "B", "C", "C")
  )
  out <- compute_csv(d)
  expect_equal(out$competitor[out$item == "I1"], "B")
  expect_equal(out$competitor[out$item == "I2"], "B; C")
})

test_that("sort_validity adds target-scale Colquitt summaries", {
  d <- data.frame(
    item = rep(c("A1", "A2", "A3"), each = 20),
    rater = rep(1:20, 3),
    target_construct = "A",
    assigned_construct = c(rep("A", 18), rep("B", 2),
                           rep("A", 17), rep("B", 3),
                           rep("A", 16), rep("B", 4))
  )
  fit <- sort_validity(d)
  expect_equal(nrow(fit$scale_summary), 1L)
  expect_equal(fit$scale_summary$target, "A")
  expect_equal(fit$scale_summary$mean_psa, mean(c(.90, .85, .80)))
  expect_equal(fit$scale_summary$mean_csv, mean(c(.80, .70, .60)))
  expect_equal(fit$scale_summary$psa_strength, "Strong")
  expect_equal(fit$scale_summary$csv_strength, "Strong")
  expect_equal(fit$scale_summary$overall_strength, "Strong")
})

test_that("sort_validity supports target-specific orbiting correlations", {
  d <- data.frame(
    item = rep(c("A1", "B1"), each = 20),
    rater = rep(1:20, 2),
    target_construct = rep(c("A", "B"), each = 20),
    assigned_construct = c(rep("A", 17), rep("B", 3),
                           rep("B", 17), rep("A", 3))
  )
  fit <- sort_validity(d, orbiting_r = c(A = .60, B = .20))
  expect_match(fit$scale_summary$benchmark_set[fit$scale_summary$target == "A"], "Stronger")
  expect_match(fit$scale_summary$benchmark_set[fit$scale_summary$target == "B"], "Weaker")
  expect_error(sort_validity(d, orbiting_r = .40), "named numeric vector")
})

test_that("sort_validity does not apply Colquitt labels to expert panels", {
  d <- data.frame(
    item = rep("A1", 20), rater = 1:20, target_construct = "A",
    assigned_construct = c(rep("A", 18), rep("B", 2))
  )
  fit <- sort_validity(d, judge_type = "expert")
  expect_false(fit$scale_summary$benchmark_applicable)
  expect_true(is.na(fit$scale_summary$psa_strength))
  expect_match(fit$scale_summary$evidence, "not applied")
})

test_that("review diagnostics explain competitor-favored and near-miss patterns", {
  d <- data.frame(
    item = rep(c("Wrong", "Near"), each = 20), rater = rep(1:20, 2),
    target_construct = "A",
    assigned_construct = c(rep("A", 6), rep("B", 14),
                           rep("A", 14), rep("B", 6))
  )
  fit <- sort_validity(d)
  expect_equal(fit$results$issue[fit$results$item == "Wrong"], "Competing construct favored")
  expect_equal(fit$results$issue[fit$results$item == "Near"], "Target favored, exact criterion not met")
  expect_match(fit$results$interpretation[fit$results$item == "Wrong"], "B")
})

test_that("v0.0.2 print and plot methods surface scale-level evidence", {
  d <- data.frame(
    item = rep(c("A1", "A2"), each = 20), rater = rep(1:20, 2),
    target_construct = "A",
    assigned_construct = c(rep("A", 17), rep("B", 3), rep("A", 16), rep("B", 4))
  )
  fit <- sort_validity(d)
  expect_output(print(fit), "Scale-level Colquitt benchmark summary")
  expect_output(print(summary(fit)), "Target-scale evidence")

  tf <- tempfile(fileext = ".pdf")
  grDevices::pdf(tf)
  expect_silent(plot(fit, metric = "psa"))
  grDevices::dev.off()
  unlink(tf)
})

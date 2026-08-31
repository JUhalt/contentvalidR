.make_rating_v003 <- function() {
  d <- expand.grid(item = c("A1", "A2", "B1"), rater = 1:12,
                   construct = c("A", "B", "C"), KEEP.OUT.ATTRS = FALSE)
  d$target_construct <- ifelse(d$item == "B1", "B", "A")
  d$rating <- NA_real_
  for (i in seq_len(nrow(d))) {
    it <- d$item[i]; co <- d$construct[i]; rr <- as.integer(d$rater[i])
    d$rating[i] <- if (it == "A1") {
      if (co == "A") c(5,5,4,5,4,5,5,4,5,4,5,5)[rr] else if (co == "B") 2 else 1
    } else if (it == "A2") {
      if (co == "A") 3 else if (co == "B") 4 else 2
    } else {
      if (co == "B") c(5,4,5,5,4,5,4,5,5,4,5,5)[rr] else 2
    }
  }
  d
}

test_that("rating_validity returns informative item and scale evidence", {
  d <- .make_rating_v003()
  fit <- rating_validity(d)
  expect_s3_class(fit, "contentvalid_rating")
  expect_equal(fit$results$recommendation[fit$results$item == "A1"], "Retain")
  expect_equal(fit$results$recommendation[fit$results$item == "A2"], "Review")
  expect_equal(fit$results$issue[fit$results$item == "A2"], "Orbiting construct rated higher")
  expect_equal(fit$results$strongest_competitor[fit$results$item == "A2"], "B")
  expect_equal(nrow(fit$scale_summary), 2L)
  expect_true(all(c("mean_htc", "mean_htd", "overall_strength", "evidence") %in% names(fit$scale_summary)))
})

test_that("rating_validity print and summary explain the evidence", {
  fit <- rating_validity(.make_rating_v003())
  expect_output(print(fit), "construct-rating analysis")
  expect_output(print(fit), "Review: A2")
  s <- summary(fit)
  expect_s3_class(s, "summary.contentvalid_rating")
  expect_output(print(s), "Items needing attention")
  expect_output(print(s), "Orbiting construct rated higher")
})

test_that("rating_validity uses scale-level Colquitt HTC/HTD norms", {
  fit <- rating_validity(.make_rating_v003(), orbiting_r = c(A = .40, B = .60))
  expect_equal(fit$scale_summary$benchmark_set[fit$scale_summary$target == "A"], "moderate")
  expect_equal(fit$scale_summary$benchmark_set[fit$scale_summary$target == "B"], "stronger")
  expect_true(all(!is.na(fit$scale_summary$htc_strength)))
  expect_true(all(!is.na(fit$scale_summary$htd_strength)))
})

test_that("Colquitt labels are suppressed for expert rating panels", {
  fit <- rating_validity(.make_rating_v003(), judge_type = "expert")
  expect_true(all(is.na(fit$scale_summary$htc_strength)))
  expect_true(all(is.na(fit$scale_summary$htd_strength)))
  expect_match(fit$scale_summary$evidence[1], "suppressed")
})

test_that("rating_validity reports incomplete judge profiles itemwise", {
  d <- .make_rating_v003()
  d$rating[d$item == "A1" & d$rater == 12 & d$construct == "C"] <- NA
  fit <- rating_validity(d)
  expect_equal(fit$results$n_incomplete[fit$results$item == "A1"], 1L)
  expect_equal(fit$results$n_complete[fit$results$item == "A1"], 11L)
})

test_that("rating_validity refuses a between-judge design", {
  d <- data.frame(
    item = "I1", rater = 1:12,
    construct = rep(c("A", "B"), each = 6),
    rating = c(5,5,4,5,4,5, 2,2,1,2,1,2),
    target_construct = "A"
  )
  expect_error(rating_validity(d), "requires a within-judge")
})

test_that("rating plot method returns the analysis object invisibly", {
  fit <- rating_validity(.make_rating_v003())
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_identical(plot(fit, metric = "htc"), fit)
  expect_identical(plot(fit, metric = "htd"), fit)
})


test_that("all-missing rating item is reported as insufficient rather than crashing", {
  d <- expand.grid(item = "I1", rater = 1:6, construct = c("A", "B", "C"))
  d$target_construct <- "A"
  d$rating <- NA_real_
  fit <- rating_validity(d, scale_min = 1, scale_max = 5)
  expect_equal(fit$results$recommendation, "Insufficient data")
  expect_equal(fit$results$n_complete, 0)
  expect_true(is.na(fit$results$htd))
})

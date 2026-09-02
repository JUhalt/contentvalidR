.make_v006_sort <- function() {
  d <- data.frame(
    item = rep(c("A1", "B1"), each = 10),
    rater = rep(1:10, 2),
    assigned_construct = c(rep("A", 9), "B", rep("B", 7), rep("A", 3)),
    target_construct = rep(c("A", "B"), each = 10),
    stringsAsFactors = FALSE
  )
  d$assigned_construct[20] <- NA_character_
  d
}

.make_v006_rating <- function() {
  d <- expand.grid(
    item = c("A1", "B1"), rater = 1:8, construct = c("A", "B"),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  d$target_construct <- ifelse(d$item == "A1", "A", "B")
  d$rating <- ifelse(d$construct == d$target_construct, 4.5, 2.0) +
    rep(c(-.2, .1, .2, -.1), length.out = nrow(d))
  d
}

.make_v006_expert <- function() {
  matrix(
    c(4,4,4,4,4,4,
      4,4,4,3,4,4,
      4,3,4,4,3,4),
    nrow = 6,
    dimnames = list(NULL, paste0("Item", 1:3))
  )
}

test_that("flagship fits share one stable common object contract", {
  fits <- list(
    sort = sort_validity(.make_v006_sort()),
    rating = rating_validity(.make_v006_rating()),
    expert = expert_validity(.make_v006_expert(), mode = "relevance", lo = 1, hi = 4)
  )
  core <- c("workflow", "results", "scale_summary", "settings", "design", "details")

  for (fit in fits) {
    expect_true(inherits(fit, "contentvalid_workflow"))
    expect_true(all(core %in% names(fit)))
    expect_true(is.data.frame(fit$results))
    expect_true(is.data.frame(fit$scale_summary))
    expect_true(is.list(fit$settings))
    expect_true(is.list(fit$design))
    expect_true(is.list(fit$details))
    expect_true("status" %in% names(fit$results))
    expect_true(all(na.omit(fit$results$status) %in%
                      c("Supported", "Review", "Insufficient data", "Descriptive only")))
  }

  expect_equal(fits$sort$workflow, "item-sort")
  expect_equal(fits$rating$workflow, "construct-rating")
  expect_equal(fits$expert$workflow, "expert-panel")
})

test_that("workflow status is standardized without erasing method-specific recommendations", {
  s <- sort_validity(.make_v006_sort())
  s_retain <- s$results$recommendation == "Retain"
  expect_true(any(s_retain))
  expect_true(all(s$results$status[s_retain] == "Supported"))
  expect_true(all(s$results$recommendation %in% c("Retain", "Review", "Insufficient data")))

  r <- rating_validity(.make_v006_rating())
  r_retain <- r$results$recommendation == "Retain"
  expect_true(any(r_retain))
  expect_true(all(r$results$status[r_retain] == "Supported"))
  expect_true(all(r$results$recommendation %in% c("Retain", "Review", "Insufficient data")))

  e <- expert_validity(.make_v006_expert(), mode = "relevance", lo = 1, hi = 4)
  expect_true(all(e$results$status[e$results$recommendation %in% c("Strong support", "Support")] == "Supported"))
})

test_that("all workflow summaries expose the same common contract", {
  fits <- list(
    sort_validity(.make_v006_sort()),
    rating_validity(.make_v006_rating()),
    expert_validity(.make_v006_expert(), mode = "relevance", lo = 1, hi = 4)
  )
  core <- c("workflow", "n_items", "n_results", "n_supported", "n_review",
            "n_insufficient", "n_descriptive", "scale_summary", "reviewed_items",
            "settings", "design")

  for (fit in fits) {
    s <- summary(fit)
    expect_true(inherits(s, "summary.contentvalid_workflow"))
    expect_true(all(core %in% names(s)))
    expect_equal(s$n_results, nrow(fit$results))
    expect_equal(s$n_supported + s$n_review + s$n_insufficient + s$n_descriptive,
                 nrow(fit$results))
  }
})

test_that("rating and expert legacy component aliases remain available", {
  r <- rating_validity(.make_v006_rating())
  expect_identical(r$contrasts, r$details$contrasts)

  e <- expert_validity(.make_v006_expert(), mode = "relevance", lo = 1, hi = 4)
  expect_identical(e$scale, e$scale_summary)

  sr <- summary(r)
  se <- summary(e)
  expect_equal(sr$n_retain, sr$n_supported)
  expect_identical(se$scale, se$scale_summary)
  expect_identical(se$flagged, se$reviewed_items)
})

test_that("design metadata use consistent judge and missingness fields", {
  s <- sort_validity(.make_v006_sort())
  expect_true(all(c("n_items", "n_judges_min", "n_judges_max", "n_missing") %in% names(s$design)))
  expect_equal(s$design$n_missing, 1L)

  rd <- .make_v006_rating()
  rd$rating[rd$item == "B1" & rd$rater == 8 & rd$construct == "A"] <- NA_real_
  r <- rating_validity(rd)
  expect_true(all(c("n_items", "n_judges_min", "n_judges_max", "n_missing") %in% names(r$design)))
  expect_equal(r$design$n_missing, 1L)
  expect_true(r$design$n_incomplete_profiles >= 1L)

  xd <- .make_v006_expert()
  xd[1, 2] <- NA_real_
  e <- expert_validity(xd, mode = "relevance", lo = 1, hi = 4, na.rm = TRUE)
  expect_true(all(c("n_items", "n_judges_min", "n_judges_max", "n_missing") %in% names(e$design)))
  expect_equal(e$design$n_missing, 1L)
})

test_that("expert modes use the same common contract and standardized statuses", {
  ess <- expert_validity(c(10, 6), mode = "essentiality", N = 12)
  expect_true(inherits(ess, "contentvalid_workflow"))
  expect_identical(ess$scale, ess$scale_summary)
  expect_true(all(ess$results$status %in% c("Supported", "Review")))
  expect_equal(ess$settings$judge_type, "expert")

  d <- expand.grid(item = c("I1", "I2"), judge = 1:4, objective = c("A", "B"),
                   KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  d$target_objective <- ifelse(d$item == "I1", "A", "B")
  d$score <- ifelse(d$objective == d$target_objective, 1, -1)
  cong <- expert_validity(d, mode = "congruence")
  expect_true(inherits(cong, "contentvalid_workflow"))
  expect_true(all(cong$results$status == "Supported"))
  expect_equal(cong$design$n_objectives, 2L)

  d$target_objective <- NULL
  desc <- expert_validity(d, mode = "congruence")
  expect_true(all(desc$results$status == "Descriptive only"))
  expect_equal(summary(desc)$n_descriptive, nrow(desc$results))
})

test_that("print and plot control arguments fail consistently", {
  s <- sort_validity(.make_v006_sort())
  r <- rating_validity(.make_v006_rating())
  e <- expert_validity(.make_v006_expert(), mode = "relevance", lo = 1, hi = 4)

  expect_error(print(s, digits = -1), "nonnegative integer")
  expect_error(print(r, digits = 1.5), "nonnegative integer")
  expect_error(print(e, digits = NA_real_), "nonnegative integer")

  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_error(plot(s, show_legend = 1), "TRUE or FALSE")
  expect_error(plot(r, show_legend = NA), "TRUE or FALSE")
  expect_error(plot(e, show_legend = "yes"), "TRUE or FALSE")
})

test_that("pre-v0.0.6 expert objects remain summarizable and printable", {
  current <- expert_validity(.make_v006_expert(), mode = "relevance", lo = 1, hi = 4)
  old <- current
  old$workflow <- NULL
  old$scale_summary <- NULL
  old$design <- NULL
  old$results$status <- NULL
  class(old) <- "contentvalid_expert"

  s <- summary(old)
  expect_equal(s$workflow, "expert-panel")
  expect_true(is.data.frame(s$scale_summary))
  expect_equal(s$n_results, nrow(old$results))
  expect_false(withVisible(print(old))$visible)
})

test_that("pre-v0.0.6 sort and rating objects remain summarizable", {
  s0 <- sort_validity(.make_v006_sort())
  sold <- s0
  sold$workflow <- NULL
  sold$details <- NULL
  sold$results$status <- NULL
  class(sold) <- "contentvalid_sort"
  ss <- summary(sold)
  expect_equal(ss$workflow, "item-sort")
  expect_equal(ss$n_retain, ss$n_supported)

  r0 <- rating_validity(.make_v006_rating())
  rold <- r0
  rold$workflow <- NULL
  rold$details <- NULL
  rold$results$status <- NULL
  class(rold) <- "contentvalid_rating"
  rs <- summary(rold)
  expect_equal(rs$workflow, "construct-rating")
  expect_equal(rs$n_retain, rs$n_supported)
  expect_identical(rold$contrasts, r0$contrasts)
})

test_that("sort-power print and plot controls follow workflow conventions", {
  p <- sort_power(N = c(10, 15), true_p = c(.6, .8))
  expect_error(print(p, digits = -1), "nonnegative integer")
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_error(plot(p, show_legend = 1), "TRUE or FALSE")
})

expert_fit <- function(...) {
  relevance <- matrix(
    c(4, 4, 4, 3,  4, 4, 3, 4,  3, 4, 4, 4,  2, 2, 1, 2),
    nrow = 4,
    dimnames = list(NULL, paste0("Item", 1:4))
  )
  expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
                  agreement = "none", ...)
}

sort_fit <- function() {
  sort_dat <- data.frame(
    item = rep(c("A1", "A2", "A3"), each = 20),
    rater = rep(1:20, 3),
    target_construct = "A",
    assigned_construct = c(
      rep("A", 18), rep("B", 2),
      rep("A", 16), rep("B", 4),
      rep("A", 8), rep("B", 12)
    ),
    stringsAsFactors = FALSE
  )
  sort_validity(sort_dat)
}

rating_fit <- function() {
  set.seed(12)
  d <- expand.grid(item = c("A1", "A2", "B1"), rater = 1:20,
                   construct = c("A", "B", "C"), stringsAsFactors = FALSE)
  d$target_construct <- ifelse(d$item == "B1", "B", "A")
  d$rating <- ifelse(d$construct == d$target_construct,
                     pmin(5, pmax(1, round(stats::rnorm(nrow(d), 4.5, .6)))),
                     pmin(5, pmax(1, round(stats::rnorm(nrow(d), 2.0, .7)))))
  rating_validity(d, scale_min = 1, scale_max = 5)
}

test_that("the handoff carries supported items and keeps the full record", {
  fit <- expert_fit()
  h <- content_handoff(fit)

  expect_s3_class(h, "contentvalid_handoff")
  expect_type(h$items, "character")
  expect_equal(nrow(h$item_evidence), nrow(fit$results))
  expect_true(all(c("item", "status", "recommendation", "carried") %in%
                    names(h$item_evidence)))

  supported <- fit$results$item[fit$results$status == "Supported"]
  expect_equal(h$items, as.character(supported))
  expect_equal(h$item_evidence$carried, h$item_evidence$status == "Supported")

  # Items that did not qualify are still listed, not dropped.
  expect_setequal(h$item_evidence$item, as.character(fit$results$item))
})

test_that("keep selects which statuses travel", {
  fit <- expert_fit()
  strict <- content_handoff(fit)
  wider <- content_handoff(fit, keep = c("Supported", "Review"))

  expect_true(all(strict$items %in% wider$items))
  expect_gt(length(wider$items), length(strict$items))
  expect_equal(wider$provenance$keep, c("Supported", "Review"))
})

test_that("the evidence table carries the workflow's own indices", {
  ev <- content_handoff(expert_fit())$item_evidence
  expect_true(all(c("V", "I_CVI", "kappa_mod") %in% names(ev)))

  sort_ev <- content_handoff(sort_fit())$item_evidence
  expect_true(all(c("psa", "csv") %in% names(sort_ev)))

  rating_ev <- content_handoff(rating_fit())$item_evidence
  expect_true(all(c("htc", "htd") %in% names(rating_ev)))
})

test_that("item-sort and construct-rating workflows hand off too", {
  s <- content_handoff(sort_fit())
  expect_equal(s$provenance$workflow, "item-sort")
  expect_true(length(s$items) >= 1L)
  expect_true(all(s$items %in% c("A1", "A2", "A3")))

  r <- content_handoff(rating_fit())
  expect_equal(r$provenance$workflow, "construct-rating")
  expect_true(all(r$items %in% c("A1", "A2", "B1")))
})

test_that("provenance records what produced the item set", {
  p <- content_handoff(expert_fit())$provenance
  expect_equal(p$package, "contentvalidR")
  expect_equal(p$version, as.character(utils::packageVersion("contentvalidR")))
  expect_equal(p$workflow, "expert-panel")
  expect_equal(p$mode, "relevance")
  expect_equal(p$settings$lo, 1)
  expect_true(is.list(p$design))
  expect_match(p$created, "^[0-9]{4}-[0-9]{2}-[0-9]{2}$")
})

test_that("the printed handoff names the next step and the limits of the evidence", {
  out <- paste(capture.output(print(content_handoff(expert_fit()))), collapse = " ")
  expect_match(out, "Items carried forward")
  expect_match(out, "Held back")
  expect_match(out, "nomo_screen")
  expect_match(out, "does not establish that an item will behave well")
  expect_match(out, "listed above rather than deleted")
})

test_that("workflows without an item set are refused", {
  judge_ratings <- rbind(
    c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
    c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(4, 3, 4, 3, 1, 2),
    c(4, 4, 3, 4, 2, 2), c(2, 2, 2, 2, 1, 1)
  )
  dimnames(judge_ratings) <- list(paste0("Judge", 1:8), paste0("Item", 1:6))
  expect_error(content_handoff(judge_validity(judge_ratings, lo = 1, hi = 4)),
               "carry no item set")
  expect_error(content_handoff(data.frame(item = "A1")),
               "must be a sort, rating, or expert-panel workflow")
})

test_that("keep is validated against the workflow status labels", {
  fit <- expert_fit()
  expect_error(content_handoff(fit, keep = "Retain"), "must be one or more of")
  expect_error(content_handoff(fit, keep = character(0)), "must be one or more of")
  expect_error(content_handoff(fit, keep = NA_character_), "must be one or more of")
})

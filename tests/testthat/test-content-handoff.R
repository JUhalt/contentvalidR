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
    item = rep(c("A1", "A2", "B1"), each = 12),
    rater = rep(1:12, 3),
    target_construct = c(rep("A", 24), rep("B", 12)),
    assigned_construct = c(rep("A", 11), "B",
                           rep("A", 9), rep("B", 3),
                           rep("B", 10), rep("A", 2)),
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

congruence_fit <- function(target = TRUE) {
  d <- expand.grid(item = c("I1", "I2"), judge = 1:4, objective = c("A", "B"),
                   KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  d$score <- ifelse(d$objective == ifelse(d$item == "I1", "A", "B"), 1, -1)
  if (target) d$target_objective <- ifelse(d$item == "I1", "A", "B")
  expert_validity(d, mode = "congruence")
}

test_that("the object matches schema version 1", {
  h <- content_handoff(expert_fit())

  expect_identical(class(h), c("contentvalid_handoff", "cv_handoff", "list"))
  expect_named(h, c("items", "scales", "item_evidence", "item_statistics",
                    "provenance"))
  expect_identical(h$provenance$schema_version, 1L)

  expect_named(h$item_evidence, c("item", "scale", "carried", "status",
                                  "recommendation", "n_judges", "rule", "round"))
  expect_named(h$item_statistics, c("item", "statistic", "value", "criterion",
                                    "round"))
})

test_that("items are the carried items only", {
  fit <- expert_fit()
  h <- content_handoff(fit)
  ev <- h$item_evidence

  expect_identical(h$items, unique(ev$item[ev$carried]))
  expect_false(any(ev$item[!ev$carried] %in% h$items))
  expect_setequal(ev$item, as.character(fit$results$item))
  expect_equal(ev$carried, ev$status == "Supported")
})

test_that("every field is a base type, so a consumer needs no dependency", {
  h <- content_handoff(sort_fit())

  expect_type(h$items, "character")
  expect_true(is.data.frame(h$item_evidence))
  expect_true(is.data.frame(h$item_statistics))
  expect_false(inherits(h$item_evidence, "tbl_df"))
  expect_type(h$item_evidence$carried, "logical")
  expect_type(h$item_evidence$n_judges, "integer")
  expect_type(h$item_statistics$value, "double")
  expect_s3_class(h$provenance$created, "Date")
  expect_true(is.list(h$scales))
})

test_that("scales map constructs to carried items, and are NULL without a mapping", {
  s <- content_handoff(sort_fit(), keep = c("Supported", "Review"))
  expect_named(s$scales, c("A", "B"))
  expect_setequal(unlist(s$scales, use.names = FALSE), s$items)
  # One-to-one membership: no item appears under two constructs.
  expect_equal(anyDuplicated(unlist(s$scales, use.names = FALSE)), 0L)

  r <- content_handoff(rating_fit(), keep = c("Supported", "Review"))
  expect_setequal(names(r$scales), c("A", "B"))

  # Expert relevance rates one item set with no construct column.
  expect_null(content_handoff(expert_fit())$scales)
  expect_true(all(is.na(content_handoff(expert_fit())$item_evidence$scale)))
})

test_that("scales hold carried items only", {
  fit <- sort_fit()
  h <- content_handoff(fit)
  held <- h$item_evidence$item[!h$item_evidence$carried]
  expect_true(length(held) > 0)
  expect_false(any(held %in% unlist(h$scales, use.names = FALSE)))
})

test_that("n_judges is the effective per-item count for each workflow", {
  s <- sort_fit()
  expect_equal(content_handoff(s)$item_evidence$n_judges, as.integer(s$results$n))

  r <- rating_fit()
  expect_equal(content_handoff(r)$item_evidence$n_judges,
               as.integer(r$results$n_complete))

  e <- expert_fit()
  expect_equal(content_handoff(e)$item_evidence$n_judges, as.integer(e$results$N))
})

test_that("the rule states the decision criterion each workflow applied", {
  expect_match(content_handoff(sort_fit())$item_evidence$rule[1],
               "exact binomial target-count test; Howard & Melloy, 2016")
  expect_match(content_handoff(rating_fit())$item_evidence$rule[1],
               "Greenhouse-Geisser corrected omnibus test")
  expect_match(content_handoff(expert_fit())$item_evidence$rule[1],
               "I-CVI >= .+ modified kappa > 0.74")
})

test_that("statistics stack long with their criteria", {
  fit <- expert_fit()
  st <- content_handoff(fit)$item_statistics

  expect_setequal(unique(st$statistic), c("Aiken's V", "I-CVI", "modified kappa"))
  expect_equal(nrow(st), 3L * nrow(fit$results))

  icvi <- st[st$statistic == "I-CVI", ]
  expect_equal(icvi$value, fit$results$I_CVI)
  expect_equal(icvi$criterion, fit$results$cvi_criterion)
  expect_true(all(st$criterion[st$statistic == "modified kappa"] == 0.74))
  expect_true(all(is.na(st$criterion[st$statistic == "Aiken's V"])))

  # Held-back items keep their statistics, so a report can show the numbers.
  expect_setequal(unique(st$item), as.character(fit$results$item))
})

test_that("essentiality and congruence modes hand off", {
  ess <- content_handoff(expert_validity(c(10, 8, 6), mode = "essentiality", N = 12),
                         keep = c("Supported", "Review"))
  expect_equal(ess$provenance$mode, "essentiality")
  expect_null(ess$scales)
  expect_match(ess$item_evidence$rule[1], "Ayre & Scally, 2014")
  expect_true("CVR" %in% ess$item_statistics$statistic)

  con <- content_handoff(congruence_fit(), keep = c("Supported", "Review"))
  expect_named(con$scales, c("A", "B"))
  expect_match(con$item_evidence$rule[1], "target-objective IOC exceeds")

  desc <- content_handoff(congruence_fit(target = FALSE),
                          keep = "Descriptive only")
  expect_null(desc$scales)
  expect_match(desc$item_evidence$rule[1], "no target-objective mapping")
  expect_true(all(desc$item_statistics$statistic == "IOC"))
})

test_that("keep widens what travels and round is recorded", {
  fit <- expert_fit()
  strict <- content_handoff(fit)
  wider <- content_handoff(fit, keep = c("Supported", "Review"), round = 2)

  expect_true(all(strict$items %in% wider$items))
  expect_gt(length(wider$items), length(strict$items))
  expect_equal(wider$provenance$keep, c("Supported", "Review"))
  expect_true(all(wider$item_evidence$round == 2L))
  expect_true(all(wider$item_statistics$round == 2L))
})

test_that("provenance records what produced the item set", {
  p <- content_handoff(expert_fit())$provenance

  expect_equal(p$package, "contentvalidR")
  expect_equal(p$package_version, as.character(utils::packageVersion("contentvalidR")))
  expect_equal(p$workflow, "expert-panel")
  expect_equal(p$mode, "relevance")
  expect_equal(p$method, "Aiken V with score intervals plus CVI/modified kappa")
  expect_true(any(grepl("Penfield", p$citation)))
  expect_equal(p$settings$lo, 1)
  expect_true(is.list(p$design))
})

test_that("the printed handoff names the next step and the limits of the evidence", {
  out <- paste(capture.output(print(content_handoff(expert_fit()))), collapse = " ")
  expect_match(out, "schema version 1")
  expect_match(out, "Items carried forward")
  expect_match(out, "Constructs: none in this design")
  expect_match(out, "Held back")
  expect_match(out, "nomo_screen")
  expect_match(out, "does not establish that an item will behave well")

  sorted <- paste(capture.output(print(content_handoff(sort_fit()))), collapse = " ")
  expect_match(sorted, "Constructs: A \\(")
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

test_that("keep and round are validated", {
  fit <- expert_fit()
  expect_error(content_handoff(fit, keep = "Retain"), "must be one or more of")
  expect_error(content_handoff(fit, keep = character(0)), "must be one or more of")
  expect_error(content_handoff(fit, keep = NA_character_), "must be one or more of")
  expect_error(content_handoff(fit, round = 0), "positive integer")
  expect_error(content_handoff(fit, round = 1.5), "positive integer")
})

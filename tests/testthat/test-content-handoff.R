expert_fit <- function(agreement = "none", ...) {
  relevance <- matrix(
    c(4, 4, 4, 3,  4, 4, 3, 4,  3, 4, 4, 4,  2, 2, 1, 2),
    nrow = 4,
    dimnames = list(NULL, paste0("Item", 1:4))
  )
  expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
                  agreement = agreement, ...)
}

sort_fit <- function(...) {
  sort_dat <- data.frame(
    item = rep(c("A1", "A2", "B1"), each = 12),
    rater = rep(1:12, 3),
    target_construct = c(rep("A", 24), rep("B", 12)),
    assigned_construct = c(rep("A", 11), "B",
                           rep("A", 9), rep("B", 3),
                           rep("B", 10), rep("A", 2)),
    stringsAsFactors = FALSE
  )
  sort_validity(sort_dat, ...)
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
                    "provenance", "panel_statistics"))
  expect_identical(h$provenance$schema_version, 1L)

  # keying, response_min and response_max were appended in 0.7.0, after every
  # original column, which is what the additive rule requires.
  expect_named(h$item_evidence, c("item", "scale", "carried", "status",
                                  "recommendation", "n_judges", "rule", "round",
                                  "keying", "response_min", "response_max"))
  # Columns added within version 1 follow the original ones, so a reader that
  # indexes by position still finds them where they were.
  expect_named(h$item_statistics, c("item", "statistic", "value", "criterion",
                                    "round", "lower", "upper",
                                    "interval_method", "interval_level",
                                    "note"))
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
  # The relevance rule states Lynn's criterion as the count the decision
  # compares, and cites her for it.
  e <- expert_fit()
  h <- content_handoff(e)
  N <- e$results$N[1]
  expect_match(h$item_evidence$rule[1],
               sprintf("at least %d of %d experts rate the item relevant",
                       contentvalidR:::.cvi_required_count(N), N), fixed = TRUE)
  expect_match(h$item_evidence$rule[1], "modified kappa > .74", fixed = TRUE)
  expect_true("Lynn (1986)" %in% h$provenance$citation)
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

# A Delphi handoff (#42): each item travels with its own last round.

delphi_fit <- function(..., threshold = 0.75) {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 3, 4), S2 = c(3, 4, 3, 2, 4, 3),
              S3 = c(2, 1, 2, 2, 1, 2))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(4, 4, 4, 4, 4, 3),
              S3 = c(2, 1, 2, 2, 1, 2))
  # S1 reached consensus in round 2 and was set aside; one expert left.
  r3 <- cbind(S2 = c(4, 4, 4, 4, 4), S3 = c(2, 1, 2, 2, 1))
  long <- function(m, round) {
    data.frame(expert = paste0("E", seq_len(nrow(m))),
               item = rep(colnames(m), each = nrow(m)),
               round = round, rating = as.vector(m), stringsAsFactors = FALSE)
  }
  delphi_validity(rbind(long(r1, 1), long(r2, 2), long(r3, 3)),
                  lo = 1, hi = 4, consensus_threshold = threshold, ...)
}

test_that("a Delphi fit hands off, dating each item by the round it settled in", {
  fit <- delphi_fit(B = 0)
  h <- content_handoff(fit, keep = c("Supported", "Review"))

  expect_s3_class(h, "cv_handoff")
  expect_identical(h$provenance$workflow, "delphi")
  expect_null(h$scales)
  expect_setequal(h$items, c("S1", "S2", "S3"))

  ev <- h$item_evidence
  # S1 was set aside after round 2; the others ran to round 3.
  expect_identical(ev$round[ev$item == "S1"], 2L)
  expect_identical(ev$round[ev$item != "S1"], c(3L, 3L))
  expect_identical(ev$n_judges[ev$item == "S1"], 6L)
  expect_identical(ev$n_judges[ev$item == "S2"], 5L)
  expect_match(ev$rule[ev$item == "S1"], "at least 75% of experts")
  expect_match(ev$rule[ev$item == "S1"], "settled in round 2 of 3")

  # Statistics carry the same per-item round.
  st <- h$item_statistics
  expect_true(all(st$round[st$item == "S1"] == 2L))
  expect_true(all(st$round[st$item == "S2"] == 3L))
})

test_that("Delphi statistics come from each item's own last round", {
  fit <- delphi_fit(B = 0)
  st <- content_handoff(fit, keep = c("Supported", "Review"))$item_statistics
  r <- fit$results

  icvi <- st[st$statistic == "I-CVI", ]
  expect_equal(icvi$value[match(r$item, icvi$item)], r$prop_agree)
  expect_true(all(icvi$criterion == 0.75))

  # S1's interval is round 2's, since that is where it settled.
  round2 <- fit$details$round_fits[["2"]]$results
  expect_equal(icvi$lower[icvi$item == "S1"], round2$I_CVI_low[round2$item == "S1"])
  expect_equal(icvi$upper[icvi$item == "S1"], round2$I_CVI_high[round2$item == "S1"])
  expect_true(all(icvi$interval_method == "Wilson score"))

  aiken <- st[st$statistic == "Aiken's V", ]
  expect_equal(aiken$value[aiken$item == "S1"], round2$V[round2$item == "S1"])
  expect_true(all(aiken$interval_method == "Penfield-Giacobbi score"))

  # Modified kappa travels without a criterion: a Delphi decides on the
  # consensus threshold, not on the 0.74 rule.
  expect_true(all(is.na(st$criterion[st$statistic == "modified kappa"])))
})

test_that("stability travels as evidence, named for the method that ran", {
  fit <- delphi_fit(B = 100, seed = 3)
  st <- content_handoff(fit, keep = c("Supported", "Review"))$item_statistics
  r <- fit$results

  unchanged <- st[st$statistic == "proportion unchanged", ]
  expect_equal(unchanged$value[match(r$item, unchanged$item)], r$prop_unchanged)

  kap <- st[st$statistic == "weighted kappa (quadratic)", ]
  expect_equal(kap$value[match(r$item, kap$item)], r$stability)
  expect_equal(kap$lower[match(r$item, kap$item)], r$stability_low)
  expect_true(any(kap$interval_method == "expert-resampling percentile bootstrap"))
  expect_true(all(is.na(kap$criterion)))

  lin <- content_handoff(delphi_fit(B = 0, kappa_weights = "linear"),
                         keep = c("Supported", "Review"))$item_statistics
  expect_true("weighted kappa (linear)" %in% lin$statistic)

  # Qualified so a downstream report cannot read it as a factor loading or as
  # one of Guttman's reliability coefficients (nomologR#46).
  lam <- content_handoff(delphi_fit(B = 0, stability = "lambda"),
                         keep = c("Supported", "Review"))$item_statistics
  expect_true("Goodman-Kruskal lambda" %in% lam$statistic)
  expect_false("lambda" %in% lam$statistic)

  # Scheibe's rule carries its 15% cut-off as the criterion.
  pc <- content_handoff(delphi_fit(B = 0, stability = "percent_change"),
                        keep = c("Supported", "Review"))$item_statistics
  expect_true(all(pc$criterion[pc$statistic == "net percent change"] == 0.15))

  # The chi-square methods add their p-value against alpha.
  chi <- content_handoff(delphi_fit(B = 0, stability = "chisq_group"),
                         keep = c("Supported", "Review"))$item_statistics
  expect_true("group chi-square" %in% chi$statistic)
  expect_true(all(chi$criterion[chi$statistic == "stability p_value"] == 0.05))
})

test_that("the two reasons a stability statistic is NA are distinguishable", {
  long <- function(m, round) {
    data.frame(expert = paste0("E", seq_len(nrow(m))),
               item = rep(colnames(m), each = nrow(m)),
               round = round, rating = as.vector(m), stringsAsFactors = FALSE)
  }

  # Case 1: no pair of consecutive rounds. S9 was rated in round 1 only, so
  # there was nothing to compare; both the statistic and the share unchanged
  # are NA.
  # Case 2: a pair exists but kappa is undefined, because every paired rating
  # in both rounds fell in one category. The share unchanged is 1: the panel
  # could not have been more stable.
  r1 <- cbind(S8 = c(4, 4, 3, 4), S9 = c(4, 3, 4, 3))
  r2 <- cbind(S8 = c(4, 4, 4, 4))
  r3 <- cbind(S8 = c(4, 4, 4, 4))
  fit <- delphi_validity(rbind(long(r1, 1), long(r2, 2), long(r3, 3)),
                         lo = 1, hi = 4, B = 0)
  st <- content_handoff(fit, keep = "Descriptive only")$item_statistics
  pick <- function(item, statistic) {
    st$value[st$item == item & st$statistic == statistic]
  }

  # Both rows are present: an NA is a statement about the data, not a gap.
  expect_length(pick("S9", "weighted kappa (quadratic)"), 1L)
  expect_length(pick("S8", "weighted kappa (quadratic)"), 1L)

  expect_true(is.na(pick("S9", "weighted kappa (quadratic)")))
  expect_true(is.na(pick("S9", "proportion unchanged")))

  expect_true(is.na(pick("S8", "weighted kappa (quadratic)")))
  expect_equal(pick("S8", "proportion unchanged"), 1)

  # The fit states why, and from 0.7.0 the handoff carries that sentence.
  note <- fit$details$stability$note[fit$details$stability$item == "S8"]
  expect_match(note[length(note)], "every rating fell in the same category")
  expect_identical(st$note[st$item == "S8" &
                             st$statistic == "weighted kappa (quadratic)"],
                   note[length(note)])
})

test_that("the note says why a statistic is undefined, for display only", {
  long <- function(m, round) {
    data.frame(expert = paste0("E", seq_len(nrow(m))),
               item = rep(colnames(m), each = nrow(m)),
               round = round, rating = as.vector(m), stringsAsFactors = FALSE)
  }
  r1 <- cbind(S8 = c(4, 4, 3, 4), S9 = c(4, 3, 4, 3))
  r2 <- cbind(S8 = c(4, 4, 4, 4))
  r3 <- cbind(S8 = c(4, 4, 4, 4))
  fit <- delphi_validity(rbind(long(r1, 1), long(r2, 2), long(r3, 3)),
                         lo = 1, hi = 4, B = 0)
  st <- content_handoff(fit, keep = "Descriptive only")$item_statistics

  # Always character, never NA: "" means there is nothing to say.
  expect_type(st$note, "character")
  expect_false(anyNA(st$note))
  expect_identical(names(st)[length(names(st))], "note")

  note_for <- function(item, statistic) {
    st$note[st$item == item & st$statistic == statistic]
  }
  # The producer's own sentence, carried rather than re-derived.
  expect_identical(note_for("S8", "weighted kappa (quadratic)"),
                   fit$details$stability$note[nrow(fit$details$stability)])
  expect_match(note_for("S8", "weighted kappa (quadratic)"),
               "every rating fell in the same category")
  # The fit has no row for an item rated once, so the handoff writes this one.
  expect_match(note_for("S9", "weighted kappa (quadratic)"),
               "rated in only one round")
  # A statistic that computed fine says nothing.
  expect_identical(note_for("S8", "I-CVI"), "")

  # The note never replaces the values: both NA cases stay distinguishable.
  value_for <- function(item, statistic) {
    st$value[st$item == item & st$statistic == statistic]
  }
  expect_true(is.na(value_for("S9", "proportion unchanged")))
  expect_equal(value_for("S8", "proportion unchanged"), 1)
})

test_that("other workflows carry an empty note, and zero-row blocks survive", {
  for (h in list(content_handoff(expert_fit()),
                 content_handoff(sort_fit()),
                 content_handoff(rating_fit()))) {
    expect_type(h$item_statistics$note, "character")
    expect_true(all(h$item_statistics$note == ""))
  }
  # A congruence fit with no target mapping emits a zero-row statistics block;
  # the note default must not force it to one row.
  desc <- content_handoff(congruence_fit(target = FALSE),
                          keep = "Descriptive only")
  expect_true(is.data.frame(desc$item_statistics))
  expect_true("note" %in% names(desc$item_statistics))
})

test_that("a panel statistic explains an absent coefficient or interval", {
  tiny <- rbind(c(4, 4), c(4, 4))
  colnames(tiny) <- c("I1", "I2")
  fit <- expert_validity(tiny, mode = "relevance", lo = 1, hi = 4,
                         agreement = "krippendorff", agreement_B = 50, seed = 1)
  ps <- content_handoff(fit, keep = c("Supported", "Review", "Descriptive only",
                                      "Insufficient data"))$panel_statistics
  expect_identical(nrow(ps), 1L)
  expect_true(is.na(ps$value))
  expect_match(ps$note, "undefined for these ratings")

  # A panel whose coefficient computes says nothing.
  ok <- content_handoff(expert_fit(agreement = "krippendorff", agreement_B = 200,
                                   seed = 11))$panel_statistics
  expect_identical(ok$note, "")
})

test_that("the AC1 interval carries its extension caveat into the handoff", {
  # The console warns that Zapf et al. did not evaluate this bootstrap for
  # AC1. A reader of the handoff sees the same number and must see the same
  # caveat (#56).
  ac1 <- content_handoff(expert_fit(agreement = "ac1", agreement_B = 200,
                                    seed = 11))$panel_statistics
  expect_identical(nrow(ac1), 1L)
  expect_false(is.na(ac1$lower))
  expect_match(ac1$note, "this package's extension")
  expect_match(ac1$note, "not for AC1")

  # The default coefficient is the one Zapf et al. did evaluate, so it says
  # nothing extra.
  alpha <- content_handoff(expert_fit(agreement = "krippendorff",
                                      agreement_B = 200,
                                      seed = 11))$panel_statistics
  expect_identical(alpha$note, "")
})

test_that("a Delphi handoff records its provenance and refuses `round`", {
  fit <- delphi_fit(B = 0)
  h <- content_handoff(fit, keep = c("Supported", "Review"))

  expect_true(all(c("Holey et al. (2007)", "Diamond et al. (2014)",
                    "Fleiss & Cohen (1973)") %in% h$provenance$citation))
  expect_identical(h$provenance$settings$stability, "kappa")
  expect_identical(nrow(h$panel_statistics), 0L)
  expect_error(content_handoff(fit, round = 2), "cannot be set here")
})

test_that("a Delphi study with no consensus threshold hands off descriptively", {
  fit <- delphi_fit(B = 0, threshold = NULL)
  h <- content_handoff(fit, keep = "Descriptive only")

  expect_setequal(h$items, c("S1", "S2", "S3"))
  expect_match(h$item_evidence$rule[1], "no consensus threshold was set")
  icvi <- h$item_statistics[h$item_statistics$statistic == "I-CVI", ]
  expect_true(all(is.na(icvi$criterion)))
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
               "must be a sort, rating, expert-panel, or Delphi workflow")
})

test_that("keep and round are validated", {
  fit <- expert_fit()
  expect_error(content_handoff(fit, keep = "Retain"), "must be one or more of")
  expect_error(content_handoff(fit, keep = character(0)), "must be one or more of")
  expect_error(content_handoff(fit, keep = NA_character_), "must be one or more of")
  expect_error(content_handoff(fit, round = 0), "positive integer")
  expect_error(content_handoff(fit, round = 1.5), "positive integer")
})

# Interval bounds (#33), additive within schema version 1 (nomologR#46).

interval_cols <- c("lower", "upper", "interval_method", "interval_level")

rows_for <- function(st, statistic, results) {
  s <- st[st$statistic == statistic, , drop = FALSE]
  s[match(as.character(results$item), s$item), , drop = FALSE]
}

test_that("interval bounds are the workflow's own interval columns", {
  fit <- expert_fit()
  st <- content_handoff(fit)$item_statistics

  v <- rows_for(st, "Aiken's V", fit$results)
  expect_equal(v$lower, fit$results$ci_low)
  expect_equal(v$upper, fit$results$ci_high)
  expect_true(all(v$interval_method == "Penfield-Giacobbi score"))
  expect_true(all(v$interval_level == 0.95))

  icvi <- rows_for(st, "I-CVI", fit$results)
  expect_equal(icvi$lower, fit$results$I_CVI_low)
  expect_equal(icvi$upper, fit$results$I_CVI_high)
  expect_true(all(icvi$interval_method == "Wilson score"))

  s <- sort_fit()
  psa <- rows_for(content_handoff(s)$item_statistics, "Psa", s$results)
  expect_equal(psa$lower, s$results$psa_low)
  expect_equal(psa$upper, s$results$psa_high)
  expect_true(all(psa$interval_method == "Wilson score"))
})

test_that("a non-default interval method and level travel with the bounds", {
  fit <- expert_fit(proportion_ci = "exact", alpha = 0.10)
  st <- content_handoff(fit)$item_statistics
  icvi <- rows_for(st, "I-CVI", fit$results)
  expect_equal(icvi$lower, fit$results$I_CVI_low)
  expect_equal(icvi$upper, fit$results$I_CVI_high)
  expect_true(all(icvi$interval_method == "Clopper-Pearson exact"))
  expect_true(all(icvi$interval_level == 0.90))
  # Aiken's V keeps its own method but follows the workflow's level.
  expect_true(all(st$interval_level[st$statistic == "Aiken's V"] == 0.90))

  s <- sort_fit(proportion_ci = "agresti_coull")
  psa <- rows_for(content_handoff(s)$item_statistics, "Psa", s$results)
  expect_equal(psa$lower, s$results$psa_low)
  expect_true(all(psa$interval_method == "Agresti-Coull"))
})

test_that("a unanimous small panel shows how wide its interval is", {
  # The case #33 was opened for: I-CVI = 1 from four experts.
  st <- content_handoff(expert_fit())$item_statistics
  unanimous <- st[st$statistic == "I-CVI" & st$value == 1, , drop = FALSE]
  expect_gt(nrow(unanimous), 0L)
  # Tolerance, not ==: on some platforms the Wilson upper limit at unanimity
  # computes to 1 minus one unit of floating-point rounding.
  expect_equal(unanimous$upper, rep(1, nrow(unanimous)))
  expect_true(all(unanimous$lower < 0.55))
})

test_that("statistics without an interval carry NA in all four columns", {
  sorted <- content_handoff(sort_fit())$item_statistics
  rated <- content_handoff(rating_fit())$item_statistics
  ess <- content_handoff(expert_validity(c(10, 8, 6), mode = "essentiality",
                                         N = 12))$item_statistics
  con <- content_handoff(congruence_fit())$item_statistics
  off <- content_handoff(expert_fit(proportion_ci = "none"))$item_statistics

  none <- rbind(sorted[sorted$statistic %in% c("Csv", "p_value"), ],
                rated, ess, con,
                off[off$statistic %in% c("I-CVI", "modified kappa"), ])
  expect_gt(nrow(none), 0L)
  expect_true(all(is.na(as.matrix(none[interval_cols]))))

  # With proportion intervals switched off, Aiken's V keeps its own.
  expect_false(anyNA(off$interval_method[off$statistic == "Aiken's V"]))

  # NA together or not at all, in every workflow.
  for (st in list(sorted, rated, ess, con, off,
                  content_handoff(expert_fit())$item_statistics)) {
    expect_identical(is.na(st$lower), is.na(st$interval_method))
    expect_identical(is.na(st$upper), is.na(st$interval_level))
  }
})

test_that("interval columns are base types", {
  st <- content_handoff(sort_fit())$item_statistics
  expect_type(st$lower, "double")
  expect_type(st$upper, "double")
  expect_type(st$interval_method, "character")
  expect_type(st$interval_level, "double")
})

test_that("the panel agreement interval travels outside the per-item table", {
  fit <- expert_fit(agreement = "krippendorff", agreement_B = 200, seed = 11)
  h <- content_handoff(fit, round = 2)
  ps <- h$panel_statistics

  expect_true(is.data.frame(ps))
  expect_named(ps, c("statistic", "value", "criterion", "round",
                     interval_cols, "note"))
  expect_identical(nrow(ps), 1L)
  expect_identical(ps$statistic, "Krippendorff's alpha (ordinal)")
  expect_equal(ps$value, fit$scale_summary$agreement)
  expect_equal(ps$lower, fit$scale_summary$agreement_low)
  expect_equal(ps$upper, fit$scale_summary$agreement_high)
  expect_identical(ps$interval_method, "item-resampling percentile bootstrap")
  expect_equal(ps$interval_level, 0.95)
  expect_identical(ps$round, 2L)

  expect_false(any(grepl("Krippendorff", h$item_statistics$statistic)))

  ac1 <- content_handoff(expert_fit(agreement = "ac1", agreement_B = 200,
                                    seed = 11))$panel_statistics
  expect_identical(ac1$statistic, "Gwet's AC1")
})

test_that("workflows without panel statistics carry a zero-row table", {
  fits <- list(expert_fit(), sort_fit(), rating_fit(), congruence_fit())
  for (fit in fits) {
    ps <- content_handoff(fit)$panel_statistics
    expect_true(is.data.frame(ps))
    expect_identical(nrow(ps), 0L)
    expect_named(ps, c("statistic", "value", "criterion", "round",
                       interval_cols, "note"))
  }
})

test_that("the printed handoff names the intervals and the panel statistic", {
  out <- paste(capture.output(print(content_handoff(expert_fit(
    agreement = "krippendorff", agreement_B = 200, seed = 11
  )))), collapse = " ")
  # The intervals line wraps, so compare with whitespace collapsed.
  out <- gsub("[[:space:]]+", " ", out)
  expect_match(out, "Intervals carried: Aiken's V (Penfield-Giacobbi score, 95%)",
               fixed = TRUE)
  expect_match(out, "I-CVI (Wilson score, 95%)", fixed = TRUE)
  expect_match(out, "Panel: Krippendorff's alpha (ordinal) = ", fixed = TRUE)
  expect_match(out, "95% interval", fixed = TRUE)

  rated <- paste(capture.output(print(content_handoff(rating_fit()))),
                 collapse = " ")
  expect_false(grepl("Intervals carried", rated, fixed = TRUE))
})

test_that("keying and the response scale are unknown unless the analyst says", {
  ev <- content_handoff(expert_fit())$item_evidence
  expect_identical(ev$keying, rep(NA_integer_, nrow(ev)))
  expect_identical(ev$response_min, rep(NA_integer_, nrow(ev)))
  expect_identical(ev$response_max, rep(NA_integer_, nrow(ev)))
})

test_that("the panel's rating scale is never passed off as the respondents'", {
  # The trap this guards: an expert panel rated relevance on 1-4. Respondents
  # will answer the items on some other scale. If the handoff copied lo and hi
  # across, a reader screening for out-of-range answers would reject every
  # legitimate 5. The fit's scale must not leak into these columns.
  fit <- expert_fit()
  expect_identical(fit$settings$hi, 4)
  ev <- content_handoff(fit)$item_evidence
  expect_true(all(is.na(ev$response_max)))

  ev <- content_handoff(fit, response_scale = c(1, 5))$item_evidence
  expect_identical(ev$response_min, rep(1L, nrow(ev)))
  expect_identical(ev$response_max, rep(5L, nrow(ev)))
})

test_that("naming reverse-worded items is a statement about every item", {
  items <- as.character(expert_fit()$results$item)

  ev <- content_handoff(expert_fit(), reverse_keyed = "Item2",
                        response_scale = c(1, 5))$item_evidence
  expect_identical(ev$keying[ev$item == "Item2"], -1L)
  expect_true(all(ev$keying[ev$item != "Item2"] == 1L))

  # character(0) records that someone checked and none is reversed, which is
  # different from not having said.
  ev <- content_handoff(expert_fit(), reverse_keyed = character(0))$item_evidence
  expect_identical(ev$keying, rep(1L, length(items)))
})

test_that("declaring a reversed item without the scale warns, and only then", {
  # A reverse-worded item cannot be recoded without the scale's limits, so this
  # combination is nearly always an oversight. Raised by the nomologR
  # maintainers, whose reader would otherwise refuse to recode one step later.
  expect_warning(content_handoff(expert_fit(), reverse_keyed = "Item2"),
                 "response_scale")
  # Nothing reversed needs no scale; both given is complete; neither is simply
  # unrecorded. None of these should warn.
  expect_silent(content_handoff(expert_fit(), reverse_keyed = character(0)))
  expect_silent(content_handoff(expert_fit(), reverse_keyed = "Item2",
                                response_scale = c(1, 5)))
  expect_silent(content_handoff(expert_fit()))
})

test_that("keying is all NA or none NA, and so is the response scale", {
  # A reader can rely on this, so it is worth pinning: the arguments describe
  # the whole instrument or nothing.
  for (args in list(list(), list(reverse_keyed = character(0)),
                    list(reverse_keyed = "Item3", response_scale = c(1, 7)))) {
    ev <- do.call(content_handoff, c(list(expert_fit()), args))$item_evidence
    expect_true(all(is.na(ev$keying)) || !anyNA(ev$keying))
    expect_true(all(is.na(ev$response_min)) || !anyNA(ev$response_min))
    expect_identical(is.na(ev$response_min), is.na(ev$response_max))
  }
})

test_that("keying and the response scale are validated", {
  fit <- expert_fit()
  expect_error(content_handoff(fit, reverse_keyed = "NoSuchItem"),
               "not in this analysis")
  expect_error(content_handoff(fit, reverse_keyed = 2), "character vector")
  expect_error(content_handoff(fit, reverse_keyed = NA_character_),
               "character vector")

  for (bad in list(c(5, 1), c(1, 1), c(1.5, 5), c(1, 5, 7), "1-5",
                   c(1, Inf), c(NA, 5))) {
    expect_error(content_handoff(fit, response_scale = bad), "two whole numbers",
                 info = paste(format(bad), collapse = " "))
  }
})

test_that("instrument metadata covers held-back items too", {
  # A reader recoding responses needs the keying of every item in the response
  # file, including the ones content review did not carry.
  h <- content_handoff(sort_fit(), reverse_keyed = "B1",
                       response_scale = c(1, 7))
  ev <- h$item_evidence
  expect_true(any(!ev$carried))
  expect_false(anyNA(ev$keying))
  expect_true(all(ev$response_max == 7L))
})

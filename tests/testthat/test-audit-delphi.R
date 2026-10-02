# Fixes from the pre-1.0 audit of the Delphi workflow and compare_rounds().
# Each test names what the old code printed or decided.

delphi_long <- function(m, round) {
  data.frame(expert = paste0("E", seq_len(nrow(m))),
             item = rep(colnames(m), each = nrow(m)),
             round = round, rating = as.vector(m), stringsAsFactors = FALSE)
}

three_rounds <- function() {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4), S2 = c(2, 3, 2, 1, 3, 2),
              S3 = c(3, 4, 2, 3, 4, 1))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2),
              S3 = c(3, 3, 3, 3, 4, 2))
  r3 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 2, 2),
              S3 = c(3, 3, 3, 3, 4, 3))
  rbind(delphi_long(r1, 1), delphi_long(r2, 2), delphi_long(r3, 3))
}

squash <- function(x, ...) {
  gsub("\\s+", " ", paste(capture.output(print(x, ...)), collapse = " "))
}

test_that("an item rated in rounds that are not consecutive is described as such", {
  d <- three_rounds()
  d <- d[!(d$item == "S2" & d$round == 2), ]
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  r <- fit$results
  expect_identical(r$n_rounds[r$item == "S2"], 2L)
  expect_true(is.na(r$prop_unchanged[r$item == "S2"]))

  out <- squash(fit)
  expect_match(out,
               "Rated in rounds that are not consecutive, so no pair was compared: S2 (rounds 1, 3).",
               fixed = TRUE)
  # The handoff said this item "was rated in only one round".
  stability_note <- function(handoff, item) {
    st <- handoff$item_statistics
    st$note[st$item == item & grepl("^weighted kappa", st$statistic)]
  }
  h <- content_handoff(fit, keep = c("Supported", "Review"))
  note <- stability_note(h, "S2")
  expect_length(note, 1L)
  expect_match(note, "rated in rounds 1, 3, which are not consecutive",
               fixed = TRUE)
  expect_false(grepl("only one round", note, fixed = TRUE))

  # An item truly rated once keeps the original sentence.
  once <- three_rounds()
  once <- once[!(once$item == "S3" & once$round > 1), ]
  h1 <- content_handoff(
    delphi_validity(once, lo = 1, hi = 4, consensus_threshold = .75, B = 0),
    keep = c("Supported", "Review")
  )
  expect_match(stability_note(h1, "S3"), "rated in only one round", fixed = TRUE)
})

test_that("an item rated again after a gap says which pair its stability is from", {
  d <- three_rounds()
  d4 <- rbind(d, transform(d[d$round == 3, ], round = 4))
  d4 <- d4[!(d4$item == "S3" & d4$round == 3), ]
  out <- squash(delphi_validity(d4, lo = 1, hi = 4, B = 0))
  expect_match(out, "the stability shown is from an earlier pair than the last round: S3 (1->2).",
               fixed = TRUE)
})

test_that("the handoff rule gives the round by position, and names an insufficient panel", {
  d <- three_rounds()
  d$round <- d$round + 1                      # rounds labeled 2, 3, 4
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  rule <- content_handoff(fit, keep = c("Supported", "Review"))$item_evidence$rule
  # It read "settled in round 4 of 3".
  expect_true(all(endsWith(rule, "last rated in round 3 of 3 (\"4\")")))
  expect_false(any(grepl("round 4 of 3", rule, fixed = TRUE)))

  # Rounds numbered from 1 need no label beside the position.
  plain <- content_handoff(
    delphi_validity(three_rounds(), lo = 1, hi = 4, consensus_threshold = .75,
                    B = 0), keep = c("Supported", "Review")
  )$item_evidence$rule
  expect_true(all(grepl("last rated in round 3 of 3$", plain)))

  # Two experts in the last round: no consensus judgment, and the rule says so.
  few <- three_rounds()
  few <- few[!(few$item == "S2" & few$round == 3 &
                 !few$expert %in% c("E1", "E2")), ]
  ffit <- delphi_validity(few, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  expect_identical(ffit$results$recommendation[ffit$results$item == "S2"],
                   "Insufficient panel")
  ev <- content_handoff(
    ffit, keep = c("Supported", "Review", "Insufficient data")
  )$item_evidence
  expect_match(ev$rule[ev$item == "S2"],
               "fewer than three experts rated the item in its last round",
               fixed = TRUE)
  expect_false(grepl("consensus when at least", ev$rule[ev$item == "S2"],
                     fixed = TRUE))

  # No threshold: the rule says none was supplied, not when.
  none <- content_handoff(
    delphi_validity(three_rounds(), lo = 1, hi = 4, B = 0),
    keep = c("Supported", "Review", "Descriptive only")
  )$item_evidence$rule
  expect_true(all(grepl("no consensus threshold was supplied", none, fixed = TRUE)))
})

test_that("the handoff cites three-author works with et al.", {
  h <- content_handoff(delphi_validity(three_rounds(), lo = 1, hi = 4,
                                       consensus_threshold = .75, B = 0,
                                       stability = "chisq_group"),
                       keep = c("Supported", "Review"))
  cites <- unlist(h$provenance$citation)
  expect_true("Dajani et al. (1979)" %in% cites)
  expect_true("Polit et al. (2007)" %in% cites)
  expect_false(any(grepl("Sincoff|Beck", cites)))
})

test_that("a round with fewer than three experts is no decision in the distribution view", {
  d <- three_rounds()
  d <- d[!(d$item == "S1" & d$round == 3 & !d$expert %in% c("E1", "E2")), ]
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  st <- contentvalidR:::.delphi_round_status(fit$details$consensus,
                                              fit$design$rounds)
  # Both remaining experts rated S1 a 4, and it was drawn as "Met the criterion".
  expect_identical(unname(st[[3]]["S1"]), "Insufficient data")
  expect_identical(unname(st[[2]]["S1"]), "Supported")
  expect_identical(unname(st[[3]]["S2"]), "Review")
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_identical(plot(fit, type = "distribution"), fit)
})

test_that("the stability view scales a chi-square on its own axis", {
  d <- three_rounds()
  fit <- delphi_validity(d, lo = 1, hi = 4, stability = "chisq_individual")
  stab <- fit$details$stability
  ax <- contentvalidR:::.delphi_stability_axes(stab, fit$design$rounds, TRUE)
  top <- max(stab$value, na.rm = TRUE)
  expect_gt(top, 1)
  # The ticks stopped at 1 while the statistic ran far above it.
  expect_gt(max(ax$y_at), 1)
  expect_lte(max(ax$y_at), top + 1e-9)
  expect_gte(max(ax$y_at), top / 2)

  kap <- delphi_validity(d, lo = 1, hi = 4, B = 0)
  bx <- contentvalidR:::.delphi_stability_axes(kap$details$stability,
                                                kap$design$rounds, FALSE)
  expect_lte(max(bx$y_at), 1)

  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_identical(plot(fit, type = "stability"), fit)
  expect_identical(plot(kap, type = "stability"), kap)
})

test_that("round-pair labels sit at their own positions when the first item entered late", {
  d <- three_rounds()
  late <- transform(d[d$item == "S1" & d$round > 1, ], item = "S0")
  d <- rbind(late, d)                          # S0, rated in rounds 2 and 3, is listed first
  fit <- delphi_validity(d, lo = 1, hi = 4, B = 0)
  stab <- fit$details$stability
  expect_identical(stab$item[1], "S0")
  expect_identical(stab$from_round[1], "2")
  ax <- contentvalidR:::.delphi_stability_axes(stab, fit$design$rounds, FALSE)
  # The labels were placed as "2-3" at x = 1 and "1-2" at x = 2.
  expect_identical(ax$x_at, c(1L, 2L))
  expect_identical(ax$x_labels, c("1-2", "2-3"))
})

test_that("plot() takes type, and still accepts which", {
  fit <- delphi_validity(three_rounds(), lo = 1, hi = 4,
                         consensus_threshold = .75, B = 0)
  expect_identical(names(formals(contentvalidR:::plot.contentvalid_delphi))[2],
                   "type")
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  for (view in c("consensus", "stability", "distribution")) {
    expect_identical(plot(fit, type = view), fit)
    expect_identical(plot(fit, which = view), fit)
    expect_identical(plot(fit, view), fit)
  }
  expect_error(plot(fit, type = "trend"))
  expect_error(plot(fit, which = "trend"))
})

test_that("the kappa caveat states the interval level the table shows", {
  d <- three_rounds()
  out <- squash(delphi_validity(d, lo = 1, hi = 4, alpha = .10, B = 50, seed = 1))
  expect_match(out, "90% CI", fixed = TRUE)
  # It said "their stated 95%" under a 90% heading.
  expect_match(out, "cover less than their stated 90%", fixed = TRUE)
  expect_false(grepl("stated 95%", out, fixed = TRUE))
  out95 <- squash(delphi_validity(d, lo = 1, hi = 4, B = 50, seed = 1))
  expect_match(out95, "cover less than their stated 95%", fixed = TRUE)
})

test_that("the summary names its items, its statistic, and ends with the caveat", {
  d <- three_rounds()
  d <- d[!(d$item == "S3" & d$round == 3 & !d$expert %in% c("E1", "E2")), ]
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  lines <- capture.output(print(summary(fit)))
  out <- gsub("\\s+", " ", paste(lines, collapse = " "))
  expect_match(out, "No consensus: S2", fixed = TRUE)
  expect_match(out, "Too few experts (fewer than three in the last round): S3",
               fixed = TRUE)
  # It printed the argument value, "kappa".
  expect_match(out, "Stability statistic: weighted kappa (quadratic weights)",
               fixed = TRUE)
  expect_match(out, "Consensus is not correctness", fixed = TRUE)
  expect_false(any(grepl(" $", lines)))
})

test_that("content_report() writes a Delphi chi-square as APA does", {
  fit <- delphi_validity(three_rounds(), lo = 1, hi = 4,
                         consensus_threshold = .75, stability = "chisq_group")
  tab <- as.data.frame(content_report(fit))
  # It was headed "stability", lost its leading zero, and had no df.
  expect_true(all(c("df", "chi-square", "p") %in% names(tab)))
  expect_false("stability" %in% names(tab))
  below_one <- fit$results$stability < 1 & !is.na(fit$results$stability)
  expect_true(any(below_one))
  expect_true(all(grepl("^0\\.", tab$`chi-square`[below_one])))
  expect_identical(tab$df, as.character(fit$results$stability_df))

  kap <- as.data.frame(content_report(
    delphi_validity(three_rounds(), lo = 1, hi = 4, consensus_threshold = .75,
                    B = 0)
  ))
  expect_true("kappa" %in% names(kap))
  expect_false("df" %in% names(kap))
})

test_that("compare_rounds() ignores resampling settings and flags a changed panel", {
  R <- cbind(A = c(4, 4, 3, 4, 2, 4), B = c(2, 3, 4, 4, 3, 4),
             C = c(4, 4, 4, 3, 4, 4))
  same <- compare_rounds(expert_validity(R, seed = 1, agreement_B = 50),
                         expert_validity(R, seed = 2, agreement_B = 80))
  # A different seed made the rounds "analyzed under different settings".
  expect_true(same$comparable)
  expect_identical(nrow(same$settings_changes), 0L)

  mk <- function(n, k) {
    data.frame(item = "I1", rater = seq_len(n),
               assigned_construct = c(rep("A", k), rep("B", n - k)),
               target_construct = "A")
  }
  grown <- compare_rounds(sort_validity(mk(6, 5)), sort_validity(mk(12, 10)))
  # Psa is .83 in both rounds; only the panel, and with it the criterion, moved.
  expect_false(grown$comparable)
  expect_identical(grown$settings_changes$setting, "panel size")
  expect_identical(grown$settings_changes$previous, "6")
  expect_identical(grown$settings_changes$current, "12")
  out <- squash(grown)
  expect_match(out, "The panel changed size", fixed = TRUE)
  expect_false(grepl("can be read as changes in evidence", out, fixed = TRUE))

  steady <- squash(compare_rounds(sort_validity(mk(12, 8)),
                                  sort_validity(mk(12, 10))))
  expect_match(steady, "can be read as changes in evidence", fixed = TRUE)
})

test_that("compare_rounds() opens with its verdict and refuses mismatched input", {
  mk <- function(k) {
    data.frame(item = rep(c("I1", "I2"), each = 12), rater = rep(1:12, 2),
               assigned_construct = c(rep("A", k), rep("B", 12 - k),
                                      rep("A", 11), "B"),
               target_construct = "A")
  }
  cr <- compare_rounds(sort_validity(mk(8)), sort_validity(mk(10)))
  lines <- capture.output(print(cr))
  # The verdict is the first thing after the header.
  expect_match(lines[5],
               "^1 of 2 units in both the first and last round changed status")
  expect_match(gsub("\\s+", " ", paste(lines, collapse = " ")),
               "changed status (1 stronger, 0 weaker).", fixed = TRUE)

  ess <- expert_validity(c(Q1 = 12, Q2 = 6), mode = "essentiality", N = 12)
  rel <- expert_validity(cbind(Q1 = c(4, 4, 4), Q2 = c(2, 3, 4)),
                         agreement = "none")
  expect_error(compare_rounds(rel, ess), "same expert-panel mode")
  fit <- sort_validity(mk(8))
  expect_error(compare_rounds(fit, fit, labels = c("item", "change")),
               "cannot be labeled")
  expect_error(compare_rounds(fit, fit, labels = c("Round 1", NA)),
               "must not be missing or empty")
})

test_that("a rating between scale points is drawn on the side the rule counts it", {
  shares <- contentvalidR:::.rating_shares
  cats <- 1:4
  x <- c(4, 4, 2.5, 4, 4, 4)
  p <- shares(x, cats, cut = 3)
  # round() put the 2.5 in category 3, so the bar read 1.00 against an I-CVI of .83.
  expect_equal(sum(p[cats >= 3]), mean(x >= 3))
  expect_equal(p, c(0, 1, 0, 5) / 6)
  # Whole ratings are untouched.
  expect_equal(shares(c(1, 2, 3, 4, 4), cats, 3), c(1, 1, 1, 2) / 5)
  # A cut between two points still splits where the rule does.
  expect_equal(sum(shares(c(2, 2.5, 3), cats, 2.5)[cats >= 2.5]), 2 / 3)
})

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
               "Rated in rounds that are not consecutive, so no pair was compared: S2 (rounds 1 and 3).",
               fixed = TRUE)
  # The handoff said this item "was rated in only one round".
  stability_note <- function(handoff, item) {
    st <- handoff$item_statistics
    st$note[st$item == item & grepl("^weighted kappa", st$statistic)]
  }
  h <- content_handoff(fit, keep = c("Supported", "Review"))
  note <- stability_note(h, "S2")
  expect_length(note, 1L)
  expect_match(note, "rated in rounds 1 and 3, which are not consecutive",
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
  expect_error(plot(fit, type = "trend"), "should be one of")
  expect_error(plot(fit, which = "trend"), "should be one of")
  # The earlier name stands in for `type`, never beside it.
  expect_error(plot(fit, type = "consensus", which = "stability"),
               "Give `type` or `which`, not both", fixed = TRUE)
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
  # The names sit on the count lines, so no heading is printed twice.
  expect_match(out, "No consensus: 1 of 3 (S2)", fixed = TRUE)
  expect_match(out, "Too few experts (fewer than three in the last round): 1 item (S3)",
               fixed = TRUE)
  expect_identical(sum(grepl("^No consensus", lines)), 1L)
  expect_identical(sum(grepl("^Too few experts", lines)), 1L)
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
  after_header <- lines[-seq_len(grep("^Workflow:", lines)[1])]
  expect_match(after_header[nzchar(after_header)][1],
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
  # A rating a hair under the cut stays on the lower side.
  near <- c(3 - 1e-12, 4, 4)
  expect_equal(sum(shares(near, cats, 3)[cats >= 3]), mean(near >= 3))
})

# ---- Fixes from the review of the Delphi changes -----------------------------

test_that("text labels are ordered by their number only when it is unambiguous", {
  d <- three_rounds()
  relabel <- function(labels) {
    out <- d
    out$round <- labels[d$round]
    out[rev(seq_len(nrow(out))), ]             # rows in reverse order
  }
  rounds_of <- function(labels) {
    delphi_validity(relabel(labels), lo = 1, hi = 4, B = 0)$design$rounds
  }
  expect_identical(rounds_of(c("R1", "R2", "R10")), c("R1", "R2", "R10"))
  expect_identical(rounds_of(c("Round 1 of 3", "Round 2 of 3", "Round 3 of 3")),
                   c("Round 1 of 3", "Round 2 of 3", "Round 3 of 3"))
  expect_identical(rounds_of(c("1", "2", "10")), c("1", "2", "10"))

  # The first number is a quarter, not the round: ordering by it would put
  # the first round last, so the labels are refused.
  expect_error(rounds_of(c("Q4 2023", "Q1 2024", "Q2 2024")),
               "do not say which round came first", fixed = TRUE)
  expect_error(rounds_of(c("12/2023", "1/2024", "2/2024")),
               "do not say which round came first", fixed = TRUE)
  # A shared number, and no number at all.
  expect_error(rounds_of(c("2021 wave 1", "2021 wave 2", "2021 wave 3")),
               "do not say which round came first", fixed = TRUE)
  expect_error(rounds_of(c("pre", "mid", "post")),
               "do not say which round came first", fixed = TRUE)
})

test_that("a date round column is ordered by date", {
  d <- three_rounds()
  dates <- as.Date(c("2026-01-05", "2026-02-09", "2026-03-16"))
  ref <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  dd <- d
  dd$round <- dates[d$round]
  fit <- delphi_validity(dd[rev(seq_len(nrow(dd))), ], lo = 1, hi = 4,
                         consensus_threshold = .75, B = 0)
  expect_identical(fit$design$rounds, as.character(dates))
  expect_identical(fit$results$recommendation[match(ref$results$item,
                                                    fit$results$item)],
                   ref$results$recommendation)
})

test_that("one text-labeled round gets the two-rounds message", {
  one <- three_rounds()
  one <- one[one$round == 1, ]
  one$round <- "baseline"
  expect_error(delphi_validity(one, lo = 1, hi = 4, B = 0),
               "at least two rounds", fixed = TRUE)
})

test_that("the handoff says which pair an after-gap item's stability is from", {
  d <- three_rounds()
  d4 <- rbind(d, transform(d[d$round == 3, ], round = 4))
  d4 <- d4[!(d4$item == "S3" & d4$round == 3), ]
  fit <- delphi_validity(d4, lo = 1, hi = 4, consensus_threshold = .75,
                         stability = "chisq_group")
  st <- content_handoff(fit, keep = c("Supported", "Review"))$item_statistics
  gap <- "From rounds 1 and 2, the item's last consecutive pair; it was last rated in round 4."
  s3 <- st[st$item == "S3", ]
  # The rows are dated round 4 and carried the 1-to-2 values with no note.
  expect_true(all(s3$round == 4L))
  for (stat in c("proportion unchanged", "group chi-square", "stability p_value")) {
    expect_match(s3$note[s3$statistic == stat], gap, fixed = TRUE)
  }
  expect_identical(s3$note[s3$statistic == "I-CVI"], "")
  # Items rated in consecutive rounds have nothing to say.
  expect_true(all(st$note[st$item == "S1" &
                            st$statistic == "proportion unchanged"] == ""))
  expect_false(anyNA(st$note))
})

test_that("too few experts explains the status with or without a threshold", {
  few <- three_rounds()
  few <- few[!(few$item == "S2" & few$round == 3 &
                 !few$expert %in% c("E1", "E2")), ]
  fit <- delphi_validity(few, lo = 1, hi = 4, B = 0)     # no threshold
  ev <- content_handoff(
    fit, keep = c("Supported", "Review", "Descriptive only", "Insufficient data")
  )$item_evidence
  expect_identical(ev$status[ev$item == "S2"], "Insufficient data")
  # The rule said only that agreement is descriptive.
  expect_match(ev$rule[ev$item == "S2"],
               "fewer than three experts rated the item in its last round",
               fixed = TRUE)
  expect_match(ev$rule[ev$item == "S1"], "no consensus threshold was supplied",
               fixed = TRUE)
})

test_that("a label that says its position is not repeated in the rule", {
  d <- three_rounds()
  d$round <- paste("Round", d$round)
  rule <- content_handoff(
    delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0),
    keep = c("Supported", "Review")
  )$item_evidence$rule
  expect_true(all(grepl("last rated in round 3 of 3$", rule)))
})

test_that("the trend tables list the pairs of rounds in round order", {
  d <- three_rounds()
  late <- transform(d[d$item == "S1" & d$round > 1, ], item = "S0")
  fit <- delphi_validity(rbind(late, d), lo = 1, hi = 4, B = 0)
  lines <- capture.output(print(fit))
  header <- lines[grep("^Stability trend", lines)[1] + 1L]
  # S0 entered in round 2 and is listed first, which put "2->3" before "1->2".
  expect_identical(strsplit(trimws(header), "\\s+")[[1]],
                   c("Item", "1->2", "2->3"))
})

test_that("percentages agree across the header, the interpretation and options", {
  d <- three_rounds()
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = 2 / 3, B = 0)
  expect_true(all(grepl("66.7%", fit$results$interpretation, fixed = TRUE)))
  expect_false(any(grepl("threshold of 67%", fit$results$interpretation,
                         fixed = TRUE)))

  # Four of six agreeing against .67: the share is not printed as equal to
  # the threshold it falls short of.
  four <- d
  four$rating[four$item == "S1" & four$round == 3] <- c(4, 4, 4, 4, 1, 1)
  f67 <- delphi_validity(four, lo = 1, hi = 4, consensus_threshold = .67, B = 0)
  expect_match(f67$results$interpretation[f67$results$item == "S1"],
               "66.7% agreed, against a threshold of 67%", fixed = TRUE)

  # The text goes into the handoff, so session options do not change it.
  old <- options(digits = 2, OutDec = ",")
  on.exit(options(old), add = TRUE)
  expect_identical(contentvalidR:::.delphi_percent(2 / 3), "66.7%")
  expect_identical(contentvalidR:::.delphi_percent(0.75), "75%")
})

test_that("the key does not say the threshold was preset", {
  out <- squash(delphi_validity(three_rounds(), lo = 1, hi = 4,
                                consensus_threshold = .75, B = 0))
  expect_match(out, "Consensus threshold: 75%, as supplied.", fixed = TRUE)
  expect_false(grepl("preset", out, fixed = TRUE))
  expect_false(grepl("set before the study", out, fixed = TRUE))
  g <- contentvalid_glossary()
  expect_false(grepl("set before the study", g$definition[g$term == "prop_agree"],
                     fixed = TRUE))
  # Kappa "can be" low, and Holey et al. are cited for what they suggest.
  expect_match(out, "Kappa can be low when ratings concentrate in one category",
               fixed = TRUE)
  expect_match(out, "Holey et al. (2007) suggest this for their Statement 7",
               fixed = TRUE)
})

test_that("the kappa caveat says which level Klar et al. studied", {
  d <- three_rounds()
  out90 <- squash(delphi_validity(d, lo = 1, hi = 4, alpha = .10, B = 50, seed = 1))
  expect_match(out90, "their stated 90% (Klar et al. studied 95% intervals)",
               fixed = TRUE)
  out95 <- squash(delphi_validity(d, lo = 1, hi = 4, B = 50, seed = 1))
  expect_false(grepl("studied 95% intervals", out95, fixed = TRUE))
})

test_that("the distribution view is handed the decision each round supports", {
  skip_if_not_installed("testthat", "3.1.7")
  d <- three_rounds()
  d <- d[!(d$item == "S1" & d$round == 3 & !d$expert %in% c("E1", "E2")), ]
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  seen <- NULL
  testthat::local_mocked_bindings(
    .plot_rating_distribution = function(...) {
      seen <<- list(...)
      invisible(NULL)
    },
    .package = "contentvalidR"
  )
  plot(fit, type = "distribution")
  # What reaches the drawing code, not only what a helper returns.
  expect_identical(unname(seen$status[[3]]["S1"]), "Insufficient data")
  expect_identical(unname(seen$status[[2]]["S1"]), "Supported")
  expect_equal(seen$cut, 3)
  expect_equal(seen$criterion, 0.75)
})

test_that("compare_rounds() compares panel size only where the rule depends on it", {
  d <- three_rounds()
  full <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  fewer <- delphi_validity(d[d$expert != "E6", ], lo = 1, hi = 4,
                           consensus_threshold = .75, B = 0)
  # A Delphi decides on a fixed share, so one expert fewer is not a changed
  # rule. It was flagged, with a sentence about a criterion that did not move.
  cr <- compare_rounds(full, fewer)
  expect_true(cr$comparable)
  expect_false(cr$panel_compared)
  expect_identical(nrow(cr$settings_changes), 0L)
  out <- squash(cr)
  expect_match(out, "The settings were the same in every round, so", fixed = TRUE)
  expect_false(grepl("panel size", out, fixed = TRUE))

  X <- rbind(c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
             c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(2, 2, 2, 2, 1, 1))
  dimnames(X) <- list(paste0("J", 1:6), paste0("I", 1:6))
  judges <- compare_rounds(judge_validity(X), judge_validity(X[-6, ]))
  expect_true(judges$comparable)

  # Relevance fits rest on Lynn's count, which does move with the panel.
  R <- cbind(A = c(4, 4, 3, 4, 2, 4), B = c(2, 3, 4, 4, 3, 4))
  rel <- compare_rounds(expert_validity(R, agreement = "none"),
                        expert_validity(R[-6, ], agreement = "none"))
  expect_false(rel$comparable)
  expect_true(rel$panel_compared)
  expect_identical(rel$settings_changes$setting, "panel size")
  expect_match(squash(summary(rel)), "What differs between rounds", fixed = TRUE)
})

test_that("a changed setting and a changed panel are both explained", {
  mk <- function(n, k) {
    data.frame(item = "I1", rater = seq_len(n),
               assigned_construct = c(rep("A", k), rep("B", n - k)),
               target_construct = "A")
  }
  both <- compare_rounds(sort_validity(mk(6, 5), p0 = .5),
                         sort_validity(mk(12, 10), p0 = .7))
  expect_setequal(both$settings_changes$setting, c("p0", "panel size"))
  out <- squash(both)
  # Re-analysis under the current settings cannot undo a changed panel.
  expect_match(out, "Re-analyze the earlier round under the current settings",
               fixed = TRUE)
  expect_match(out, "The panel changed size", fixed = TRUE)
})

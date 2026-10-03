# Fixes from the final check of the Delphi workflow and compare_rounds()
# before the 1.0 release candidate. Each test names what the old code printed.

closeout_long <- function(m, round, experts = paste0("E", seq_len(nrow(m)))) {
  data.frame(expert = experts, item = rep(colnames(m), each = nrow(m)),
             round = round, rating = as.vector(m), stringsAsFactors = FALSE)
}

closeout_squash <- function(x, ...) {
  gsub("\\s+", " ", paste(capture.output(print(x, ...)), collapse = " "))
}

# The table row that starts with a unit's label, split into its cells.
closeout_row <- function(lines, unit) {
  hit <- grep(paste0("^\\s+", unit, "\\s"), lines, value = TRUE)[1]
  strsplit(trimws(hit), "\\s{1,}")[[1]]
}

closeout_header <- function(lines, first) {
  grep(paste0("^\\s+", first, "\\s"), lines, value = TRUE)[1]
}

# The Rd source of a help page, when the source tree is at hand.
closeout_rd <- function(name) {
  path <- testthat::test_path("..", "..", "man", paste0(name, ".Rd"))
  skip_if_not(file.exists(path), "package documentation is not available")
  gsub("\\s+", " ", paste(readLines(path, warn = FALSE), collapse = " "))
}

# A, rated alike in both rounds by every expert, has a kappa of 1 in every
# resample. B moves, so its interval has width.
closeout_steady <- function() {
  r1 <- cbind(A = c(4, 4, 3, 3, 2, 4, 3, 4), B = c(2, 3, 4, 4, 3, 1, 2, 4))
  r2 <- cbind(A = c(4, 4, 3, 3, 2, 4, 3, 4), B = c(3, 3, 4, 3, 3, 2, 2, 4))
  rbind(closeout_long(r1, 1), closeout_long(r2, 2))
}

test_that("a zero-width kappa interval is described in words, not printed", {
  fit <- delphi_validity(closeout_steady(), lo = 1, hi = 4,
                         consensus_threshold = .75, B = 50, seed = 1)
  r <- fit$results
  # The stored bounds are kept as computed.
  expect_equal(r$stability_low[r$item == "A"], 1)
  expect_equal(r$stability_high[r$item == "A"], 1)
  expect_identical(r$prop_unchanged[r$item == "A"], 1)

  lines <- capture.output(print(fit))
  out <- gsub("\\s+", " ", paste(lines, collapse = " "))
  # It printed "[1.00, 1.00]" as if nine experts gave certainty.
  expect_false(grepl("[1.00, 1.00]", out, fixed = TRUE))
  expect_identical(utils::tail(closeout_row(lines, "A"), 1), "none")
  expect_match(out, paste("A (1->2): No 95% CI, because every expert kept",
                          "their rating, so every resample of the experts",
                          "gave the same kappa."), fixed = TRUE)
  # An interval with width is printed as before.
  b <- r[r$item == "B", ]
  expect_match(out, contentvalidR:::.fmt_ci(b$stability_low, b$stability_high),
               fixed = TRUE)
})

test_that("the paired count is shown and cautioned whenever it falls short", {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 3, 4), S2 = c(2, 3, 2, 1, 3, 2))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2))
  # E5 and E6 are replaced in round 2: six experts each round, four paired.
  d <- rbind(closeout_long(r1, 1),
             closeout_long(r2, 2, c(paste0("E", 1:4), "N5", "N6")))
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  expect_identical(fit$details$panel$n_experts, c(6L, 6L))
  expect_true(all(fit$details$stability$n_paired == 4L))

  lines <- capture.output(print(fit))
  out <- gsub("\\s+", " ", paste(lines, collapse = " "))
  head <- strsplit(trimws(closeout_header(lines, "Item")), "\\s{1,}")[[1]]
  expect_true(all(c("Experts", "Paired") %in% head))
  # "Last round" is two words in the heading and one in the row.
  row <- closeout_row(lines, "S1")
  expect_identical(row[match("Experts", head) - 1L], "6")
  expect_identical(row[match("Paired", head) - 1L], "4")
  # The caution printed only when the panel changed size.
  expect_false(grepl("The panel changed size", out, fixed = TRUE))
  expect_match(out, paste("Stability uses only the experts who rated an item",
                          "in both rounds"), fixed = TRUE)
  expect_match(out, "For every item, those are fewer than rated the item in its last round",
               fixed = TRUE)
  expect_match(out, "Paired: experts who rated the item in both rounds of that pair",
               fixed = TRUE)

  # A full panel needs no paired column and no caution.
  full <- capture.output(print(delphi_validity(
    rbind(closeout_long(r1, 1), closeout_long(r2, 2)), lo = 1, hi = 4,
    consensus_threshold = .75, B = 0
  )))
  expect_false(grepl("Paired", closeout_header(full, "Item"), fixed = TRUE))
  expect_false(any(grepl("Stability uses only", full, fixed = TRUE)))
})

test_that("the help names every reason a stability statistic is NA", {
  # Two disjoint panels: a pair of rounds, and no expert in both.
  r1 <- cbind(S1 = c(4, 4, 3), S2 = c(2, 3, 2))
  d <- rbind(closeout_long(r1, 1, c("E1", "E2", "E3")),
             closeout_long(r1, 2, c("N1", "N2", "N3")))
  fit <- delphi_validity(d, lo = 1, hi = 4, B = 0)
  expect_true(all(is.na(fit$results$prop_unchanged)))
  expect_true(all(fit$details$stability$n_paired == 0L))
  expect_match(fit$details$stability$note[1], "No expert rated the item in both rounds",
               fixed = TRUE)

  rd <- closeout_rd("delphi_validity")
  expect_match(rd, "two disjoint panels", fixed = TRUE)
  expect_match(rd, "no expert rated it in both", fixed = TRUE)
})

test_that("compare_rounds() heads its change column and names every unit's change", {
  mk <- function(m) {
    expert_validity(m, mode = "relevance", lo = 1, hi = 4, agreement = "none")
  }
  e1 <- mk(cbind(I1 = c(4, 4, 4, 4, 4, 4), I2 = c(4, 4, 4, 3, 4, 4)))
  e2 <- mk(cbind(I1 = c(4, 4, 1, 1, 2, 4), I2 = c(4, 4, 4, 3, 4, 4),
                 I3 = c(4, 4, 4, 4, 4, 4)))
  e3 <- mk(cbind(I1 = c(4, 4, 4, 4, 4, 4), I2 = c(4, 4, 4, 3, 4, 4)))
  cr <- compare_rounds(e1, e2, e3)
  t <- cr$transitions
  # I1 fell and recovered: "Unchanged" from first to last, which the
  # heading now says.
  expect_identical(t$change[t$item == "I1"], "Unchanged")
  lines <- capture.output(print(cr))
  expect_match(closeout_header(lines, "Item"), "First to last$")
  expect_true("change" %in% names(t))
  # I3, only in round 2, had change NA and was missing from summary().
  expect_identical(t$change[t$item == "I3"], "Not in first or last")
  s <- summary(cr)
  expect_identical(s$changed$item, "I3")
  out <- closeout_squash(s)
  expect_match(out, "Units that changed status, entered or left", fixed = TRUE)
  expect_match(out, "I3 Supported Not in first or last", fixed = TRUE)
  expect_false(grepl("No unit changed status", out, fixed = TRUE))
})

test_that("compare_rounds() counts a change to or from Descriptive only", {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 3, 4), S2 = c(2, 3, 2, 1, 3, 2),
              S3 = c(3, 4, 4, 4, 3, 4))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2),
              S3 = c(3, 4, 4, 4, 3, 4))
  d <- rbind(closeout_long(r1, 1), closeout_long(r2, 2))
  none <- delphi_validity(d, lo = 1, hi = 4, B = 0)
  set <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  cr <- compare_rounds(none, set)
  s <- cr$summary
  # Compared 3, and nothing in unchanged, stronger or weaker.
  expect_identical(s$n_changed, 3L)
  expect_identical(s$n_compared,
                   s$n_unchanged + s$n_strengthened + s$n_weakened + s$n_changed)
  out <- closeout_squash(cr)
  expect_match(out, "Other: a change to or from Descriptive only", fixed = TRUE)
  lines <- capture.output(print(cr))
  expect_match(closeout_header(lines, "From\\s+To\\s+Compared"), "Other")

  # Ranked changes leave the column out, and the counts still add up.
  sl <- data.frame(item = rep(c("I1", "I2"), each = 6), rater = rep(1:6, 2),
                   assigned_construct = c(rep("A", 5), "B", rep("A", 3),
                                          rep("B", 3)),
                   target_construct = "A", stringsAsFactors = FALSE)
  plain <- compare_rounds(sort_validity(sl), sort_validity(sl))
  expect_identical(plain$summary$n_changed, 0L)
  expect_false(grepl("Other",
                     closeout_header(capture.output(print(plain)),
                                     "From\\s+To\\s+Compared"),
                     fixed = TRUE))
})

test_that("compare_rounds() says when it drops a partly given set of names", {
  mk <- function(m) {
    expert_validity(m, mode = "relevance", lo = 1, hi = 4, agreement = "none")
  }
  e1 <- mk(cbind(I1 = c(4, 4, 4, 4, 4, 4)))
  e2 <- mk(cbind(I1 = c(4, 4, 4, 3, 4, 4)))
  # The name "a" was dropped without a word.
  expect_warning(cr <- compare_rounds(a = e1, e2),
                 "label the rounds only when every round is named")
  expect_identical(cr$labels, c("Round 1", "Round 2"))
  expect_identical(compare_rounds(a = e1, b = e2)$labels, c("a", "b"))
  expect_no_warning(compare_rounds(e1, e2))
  expect_no_warning(compare_rounds(a = e1, e2, labels = c("x", "y")))
})

test_that("compare_rounds() writes an alpha level as APA does", {
  sl <- data.frame(item = rep(c("I1", "I2"), each = 6), rater = rep(1:6, 2),
                   assigned_construct = c(rep("A", 5), "B", rep("A", 3),
                                          rep("B", 3)),
                   target_construct = "A", stringsAsFactors = FALSE)
  cr <- compare_rounds(sort_validity(sl), sort_validity(sl, alpha = .1))
  ch <- cr$settings_changes[cr$settings_changes$setting == "alpha", ]
  # It printed "0.05" and "0.1".
  expect_identical(ch$previous, ".05")
  expect_identical(ch$current, ".10")
  expect_match(closeout_squash(cr), "alpha .05 .10", fixed = TRUE)
})

test_that("a Delphi summary with no threshold claims no consensus count", {
  q <- data.frame(expert = rep(c("A", "B"), 2), item = "Q1",
                  round = rep(1:2, each = 2), rating = c(4, 3, 4, 4))
  fit <- delphi_validity(q, lo = 1, hi = 4, B = 0)
  out <- closeout_squash(summary(fit))
  # It printed "Consensus: 0 of 1" and "No consensus: 0 of 1".
  expect_false(grepl("Consensus: 0 of 1", out, fixed = TRUE))
  expect_false(grepl("No consensus: 0 of 1", out, fixed = TRUE))
  expect_match(out, "No consensus threshold was set", fixed = TRUE)
  expect_match(out, "Too few experts (fewer than three in the last round): 1 item (Q1)",
               fixed = TRUE)
  # The printout names the item too.
  expect_match(closeout_squash(fit),
               "1 item had too few experts in its last round for any judgment (Q1).",
               fixed = TRUE)
})

test_that("the print verdict names the items with too few experts", {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 3, 4), S2 = c(2, 3, 2, 1, 3, 2))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2))
  d <- rbind(closeout_long(r1, 1), closeout_long(r2, 2))
  d <- d[!(d$item == "S2" & d$round == 2 & !d$expert %in% c("E1", "E2")), ]
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  # It read "...; 1 had too few experts." without naming S2.
  expect_match(closeout_squash(fit),
               "1 of 2 items reached consensus in their last round; 1 had too few experts (S2).",
               fixed = TRUE)
})

test_that("the kappa note qualifies its equality with the intraclass correlation", {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4), S2 = c(2, 3, 2, 1, 3, 2))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2))
  out <- closeout_squash(delphi_validity(
    rbind(closeout_long(r1, 1), closeout_long(r2, 2)), lo = 1, hi = 4, B = 0
  ))
  expect_match(out, paste("kappa equals the intraclass correlation of the two",
                          "rounds' ratings in its sums-of-squares form"),
               fixed = TRUE)
  expect_match(out, "The intraclass correlation computed from mean squares",
               fixed = TRUE)
  rd <- closeout_rd("delphi_validity")
  expect_match(rd, "in its sums-of-squares form", fixed = TRUE)
  expect_match(rd, "computed from mean squares", fixed = TRUE)
})

test_that("the help documents tied lines and the shared seed", {
  plot_rd <- closeout_rd("plot.contentvalid_delphi")
  expect_match(plot_rd, "share one line", fixed = TRUE)
  expect_match(plot_rd, "draws every item on its own", fixed = TRUE)
  rd <- closeout_rd("delphi_validity")
  expect_match(rd, "draw the same resample indices", fixed = TRUE)
})

test_that("a share just under a three-decimal threshold is not printed as equal to it", {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 3, 4, 2, 4, 3), S2 = c(4, 4, 4, 4, 4, 4, 4, 4, 4))
  r2 <- cbind(S1 = c(4, 4, 3, 3, 4, 3, 1, 1, 1), S2 = c(4, 4, 4, 4, 4, 4, 4, 4, 4))
  d <- rbind(closeout_long(r1, 1), closeout_long(r2, 2))
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .667, B = 0)
  r <- fit$results
  expect_equal(r$prop_agree[r$item == "S1"], 6 / 9)
  expect_false(r$consensus[r$item == "S1"])
  # It read "66.7% agreed, against a threshold of 66.7%".
  expect_match(r$interpretation[r$item == "S1"],
               "66.67% agreed, against a threshold of 66.70%", fixed = TRUE)
  expect_match(r$interpretation[r$item == "S2"], "against a threshold of 66.70%",
               fixed = TRUE)
  lines <- capture.output(print(fit))
  out <- gsub("\\s+", " ", paste(lines, collapse = " "))
  expect_match(out, "Consensus threshold: 66.70%, as supplied.", fixed = TRUE)
  head <- strsplit(trimws(closeout_header(lines, "Item")), "\\s{1,}")[[1]]
  row <- closeout_row(lines, "S1")
  # "No consensus" in the row and "Last round" in the heading are two words
  # each, so the cells line up with the heading's words.
  expect_identical(row[match("Agree", head)], ".6667")

  # A threshold that is not that close keeps one decimal.
  plain <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = 2 / 3, B = 0)
  expect_match(closeout_squash(plain), "Consensus threshold: 66.7%, as supplied.",
               fixed = TRUE)
  expect_identical(contentvalidR:::.delphi_percent(.667, 2L), "66.70%")
  expect_identical(contentvalidR:::.delphi_percent(.75, 2L), "75%")
})

test_that("the printout says when a panel agreed an item does not belong", {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4, 3, 4), S2 = c(2, 3, 2, 1, 3, 2, 2, 3))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 4, 4), S2 = c(2, 2, 2, 1, 2, 2, 2, 2))
  fit <- delphi_validity(rbind(closeout_long(r1, 1), closeout_long(r2, 2)),
                         lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  out <- closeout_squash(fit)
  # The print showed only "No consensus: S2".
  expect_match(out, "Agreed in the other direction (75% or more rated it below 3): S2",
               fixed = TRUE)
  # One line, the items included.
  lines <- capture.output(print(fit))
  expect_true(any(grepl("^Agreed in the other direction .*: S2$", lines)))
  # Not for an item that merely fell short.
  r2b <- r2
  r2b[, "S2"] <- c(4, 4, 4, 1, 2, 2, 2, 2)
  split <- delphi_validity(rbind(closeout_long(r1, 1), closeout_long(r2b, 2)),
                           lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  expect_false(grepl("Agreed in the other direction", closeout_squash(split),
                     fixed = TRUE))
})

test_that("the item table heads its columns as content_report() does", {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4), S2 = c(2, 3, 2, 1, 3, 2))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2))
  r3 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 2, 2))
  # Three rounds, so the trend tables print too.
  d <- rbind(closeout_long(r1, 1), closeout_long(r2, 2), closeout_long(r3, 3))
  pc <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75,
                        stability = "percent_change")
  lines <- capture.output(print(pc))
  head <- closeout_header(lines, "Item")
  # It read "n" and "Change".
  expect_match(head, "Experts", fixed = TRUE)
  expect_match(head, "Net change", fixed = TRUE)
  expect_false(grepl("\\sn\\s", head))
  out <- gsub("\\s+", " ", paste(lines, collapse = " "))
  expect_match(out, "Stability trend (net change) by pair of rounds", fixed = TRUE)
  expect_match(out, "Net change -- Net change in the rating distribution",
               fixed = TRUE)
  rep <- as.data.frame(content_report(pc))
  expect_true(all(c("experts", "net change") %in% names(rep)))
})

test_that("the Delphi line views draw in gray under apa = TRUE", {
  gray <- contentvalidR:::.delphi_item_colours(6, apa = TRUE)
  rgb <- grDevices::col2rgb(gray)
  expect_true(all(rgb[1, ] == rgb[2, ] & rgb[2, ] == rgb[3, ]))
  expect_identical(gray[1], "#000000")
  colour <- grDevices::col2rgb(contentvalidR:::.delphi_item_colours(6, apa = FALSE))
  expect_false(all(colour[1, ] == colour[2, ] & colour[2, ] == colour[3, ]))

  skip_if_not_installed("testthat", "3.1.7")
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4), S2 = c(2, 3, 2, 1, 3, 2))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2))
  fit <- delphi_validity(rbind(closeout_long(r1, 1), closeout_long(r2, 2)),
                         lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  seen <- logical(0)
  real <- contentvalidR:::.delphi_item_colours
  testthat::local_mocked_bindings(
    .delphi_item_colours = function(n, apa = FALSE) {
      seen <<- c(seen, apa)
      real(n, apa)
    },
    .package = "contentvalidR"
  )
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  for (view in c("consensus", "stability")) {
    expect_identical(plot(fit, type = view), fit)
    expect_identical(plot(fit, type = view, apa = FALSE), fit)
  }
  # The line views ignored apa.
  expect_identical(seen, c(TRUE, FALSE, TRUE, FALSE))
  plot_rd <- closeout_rd("plot.contentvalid_delphi")
  expect_match(plot_rd, "each item's line is a shade of gray", fixed = TRUE)
})

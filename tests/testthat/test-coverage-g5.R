# Tests for branches that covr 4.0.0 found no test running, now that it counts
# a braceless if/else branch inside an expression as a line of its own: paths
# of delphi_validity(), compare_rounds() and panel_agreement() that the rest
# of the suite leaves untried. They are grouped by the function they exercise.

long <- function(m, round) {
  data.frame(expert = paste0("E", seq_len(nrow(m))),
             item = rep(colnames(m), each = nrow(m)), round = round,
             rating = as.vector(m), stringsAsFactors = FALSE)
}

# A printout as one string, with its line breaks and indents reduced to
# single spaces, so a sentence is found wherever the console wrapped it.
printed <- function(x) {
  gsub("\\s+", " ", paste(utils::capture.output(print(x)), collapse = " "))
}

# Draws `expr` on a null device and returns the arguments of every text()
# call, as test-closeout3.R's drawn_text() does for the strings alone.
text_calls <- function(expr) {
  sink <- new.env()
  sink$calls <- list()
  grab <- function(...) sink$calls[[length(sink$calls) + 1L]] <- list(...)
  suppressMessages(trace("text", bquote(.(grab)(...)), print = FALSE,
                         where = graphics::plot))
  on.exit(suppressMessages(untrace("text", where = graphics::plot)),
          add = TRUE)
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  force(expr)
  sink$calls
}

# The strings each text() call drew.
drawn_labels <- function(calls) {
  unlist(lapply(calls, function(z) z$labels), use.names = FALSE)
}

two_rounds <- function() {
  rbind(long(cbind(S1 = c(4, 4, 3, 4), S2 = c(2, 3, 2, 1)), 1),
        long(cbind(S1 = c(4, 4, 4, 4), S2 = c(2, 2, 2, 1)), 2))
}

# delphi_validity(): checks on its input --------------------------------------

test_that("column arguments that are not one name each are refused", {
  d <- two_rounds()
  expect_error(delphi_validity(d, expert_col = c("expert", "item"), lo = 1,
                               hi = 4, B = 0),
               "Column arguments must each be one column name")
  expect_error(delphi_validity(d, round_col = NA_character_, lo = 1, hi = 4,
                               B = 0),
               "Column arguments must each be one column name")
})

test_that("a rating column of text or a factor is refused", {
  d <- two_rounds()
  d$rating <- as.character(d$rating)
  expect_error(delphi_validity(d, lo = 1, hi = 4, B = 0),
               "The rating column must be numeric")
  d$rating <- factor(d$rating)
  expect_error(delphi_validity(d, lo = 1, hi = 4, B = 0),
               "The rating column must be numeric")
})

test_that("a rated row without its expert, item or round is refused", {
  for (col in c("expert", "item", "round")) {
    d <- two_rounds()
    d[[col]][3] <- NA
    expect_error(delphi_validity(d, lo = 1, hi = 4, B = 0),
                 "Expert, item, and round must not be missing for a rated row")
  }
  # A row with no rating is ignored, whatever else it lacks: E3's round 1
  # rating of S1 is dropped, and S1 has three experts in round 1.
  d <- two_rounds()
  d$expert[3] <- NA
  d$rating[3] <- NA
  cons <- delphi_validity(d, lo = 1, hi = 4, B = 0)$details$consensus
  expect_identical(cons$n_experts[cons$item == "S1" & cons$round == "1"], 3L)
})

# delphi_validity(): the printout ---------------------------------------------

test_that("thinly rated items are counted as 'its' for one, 'their' for two", {
  # S3, and then S2 as well, are rated by two experts only.
  one <- rbind(long(cbind(S1 = c(4, 4, 3, 4), S2 = c(2, 3, 2, 1)), 1),
               long(cbind(S1 = c(4, 4, 4, 4), S2 = c(2, 2, 2, 1)), 2),
               long(cbind(S3 = c(4, 4)), 1), long(cbind(S3 = c(4, 4)), 2))
  fit <- delphi_validity(one, lo = 1, hi = 4, B = 0)
  expect_identical(sum(fit$results$recommendation == "Insufficient panel"),
                   1L)
  expect_match(printed(fit), paste("No consensus threshold was set; agreement",
                                   "is reported descriptively. 1 item had too",
                                   "few experts in its last round for any",
                                   "judgment (S3)."), fixed = TRUE)

  two <- one[!(one$item == "S2" & one$expert %in% c("E3", "E4")), ]
  fit <- delphi_validity(two, lo = 1, hi = 4, B = 0)
  expect_match(printed(fit), paste("2 items had too few experts in their last",
                                   "round for any judgment (S2, S3)."),
               fixed = TRUE)
})

test_that("items agreed the other way are named with 'it' or 'each'", {
  # Every expert rates S2, and then S3, below the agreement cut of 3.
  fit <- delphi_validity(two_rounds(), lo = 1, hi = 4,
                         consensus_threshold = .75, B = 0)
  expect_identical(fit$results$prop_agree, c(1, 0))
  expect_match(printed(fit), paste("Agreed in the other direction (75% or",
                                   "more rated it below 3): S2"),
               fixed = TRUE)

  d <- rbind(two_rounds(),
             long(cbind(S3 = c(1, 2, 3, 1)), 1),
             long(cbind(S3 = c(1, 2, 2, 1)), 2))
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  expect_identical(fit$results$recommendation,
                   c("Consensus", "No consensus", "No consensus"))
  expect_match(printed(fit), paste("Agreed in the other direction (75% or",
                                   "more rated each below 3): S2, S3"),
               fixed = TRUE)
})

test_that("the caution about fewer paired experts names the items it covers", {
  # A fifth expert joins in round 2 and rates S1 only, so S1 rests on four
  # paired experts of the five who rated it last.
  d <- rbind(two_rounds(),
             data.frame(expert = "E5", item = "S1", round = 2, rating = 3))
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  expect_identical(fit$results$n_experts, c(5L, 4L))
  expect_identical(fit$details$stability$n_paired, c(4L, 4L))
  out <- printed(fit)
  expect_match(out, paste("For S1, those are fewer than rated it in its last",
                          "round (Paired against Experts)."), fixed = TRUE)

  # Rating both items, the newcomer leaves every item short of its panel.
  d <- rbind(d, data.frame(expert = "E5", item = "S2", round = 2, rating = 1))
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  expect_identical(fit$results$n_experts, c(5L, 5L))
  expect_match(printed(fit), paste("For every item, those are fewer than rated",
                                   "the item in its last round"),
               fixed = TRUE)
})

test_that("a fit with no pair of consecutive rounds prints its gaps", {
  # S1 and S2 skip round 2, the only round S3 is rated in.
  d <- rbind(long(cbind(S1 = c(4, 4, 3, 4), S2 = c(2, 3, 2, 1)), 1),
             long(cbind(S3 = c(4, 4, 4, 4)), 2),
             long(cbind(S1 = c(4, 4, 4, 4), S2 = c(2, 2, 2, 1)), 3))
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  expect_identical(nrow(fit$details$stability), 0L)
  out <- printed(fit)
  expect_match(out, paste("Rated in rounds that are not consecutive, so no",
                          "pair was compared: S1 (rounds 1 and 3); S2 (rounds",
                          "1 and 3)."), fixed = TRUE)
  # With no pair there is no paired count, and no trend to tabulate.
  expect_false(grepl("Paired", out, fixed = TRUE))
  expect_false(grepl("Stability trend", out, fixed = TRUE))
})

# summary() of a Delphi fit ---------------------------------------------------

test_that("with no threshold the summary counts the descriptive items", {
  d <- rbind(two_rounds(), long(cbind(S3 = c(4, 4)), 1),
             long(cbind(S3 = c(4, 4)), 2))
  fit <- delphi_validity(d, lo = 1, hi = 4, B = 0)
  out <- printed(summary(fit))
  expect_match(out, paste("Descriptive only: 2 of 3 items; no consensus",
                          "threshold was set."), fixed = TRUE)
  expect_match(out, paste("Too few experts (fewer than three in the last",
                          "round): 1 item (S3)"), fixed = TRUE)
})

test_that("the summary names no item where none fell short of consensus", {
  # Both items reach consensus, so no item is under review at all.
  d <- rbind(long(cbind(S1 = c(4, 4, 3, 4), S2 = c(3, 3, 4, 4)), 1),
             long(cbind(S1 = c(4, 4, 4, 4), S2 = c(4, 3, 4, 4)), 2))
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  expect_identical(nrow(summary(fit)$reviewed_items), 0L)
  out <- utils::capture.output(print(summary(fit)))
  expect_identical(grep("^No consensus:", out, value = TRUE),
                   "No consensus: 0 of 2")

  # An item short of experts is listed on its own line, not as lacking
  # consensus.
  d <- d[!(d$item == "S2" & d$expert %in% c("E3", "E4")), ]
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  out <- utils::capture.output(print(summary(fit)))
  expect_identical(grep("^No consensus:", out, value = TRUE),
                   "No consensus: 0 of 2")
  expect_match(paste(out, collapse = " "),
               "fewer than three in the last round): 1 item (S2)",
               fixed = TRUE)
})

# plot() of a Delphi fit ------------------------------------------------------

test_that("a single item is drawn in black, whatever the color scheme", {
  d <- rbind(long(cbind(S1 = c(4, 4, 3, 4)), 1),
             long(cbind(S1 = c(4, 4, 4, 4)), 2))
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  calls <- text_calls(shown <- withVisible(plot(fit, apa = FALSE)))
  expect_false(shown$visible)
  expect_identical(shown$value, fit)
  label <- Filter(function(z) identical(z$labels, "S1"), calls)
  expect_length(label, 1L)
  expect_identical(label[[1]]$col, "black")

  # Two items in the same scheme get colors of their own.
  fit <- delphi_validity(two_rounds(), lo = 1, hi = 4,
                         consensus_threshold = .75, B = 0)
  calls <- text_calls(plot(fit, apa = FALSE))
  labels <- Filter(function(z) identical(z$labels, c("S1", "S2")), calls)
  expect_length(labels, 1L)
  cols <- labels[[1]]$col
  expect_length(unique(cols), 2L)
  expect_false(any(cols == "black"))
})

test_that("a stability plot with no defined statistic labels no item", {
  # Every rating is 4 in both rounds, so kappa is undefined for each item.
  d <- rbind(long(cbind(S1 = rep(4, 4), S2 = rep(4, 4)), 1),
             long(cbind(S1 = rep(4, 4), S2 = rep(4, 4)), 2))
  fit <- delphi_validity(d, lo = 1, hi = 4, B = 0)
  expect_true(all(is.na(fit$details$stability$value)))
  calls <- text_calls(shown <- withVisible(plot(fit, type = "stability")))
  expect_false(shown$visible)
  labels <- drawn_labels(calls)
  # The legend is drawn, so the collector saw the figure's text.
  expect_true("Weighted kappa (quadratic)" %in% labels)
  expect_false(any(c("S1", "S2") %in% labels))
})

test_that("a chi-square of zero or none still gets an axis from 0 to 1", {
  # The axis runs from 0 to 1, with 16% headroom above for the legend, and R
  # widens a plotted range by 4% at each end.
  ylim <- c(0, 1.16)
  usr <- ylim + c(-1, 1) * 0.04 * diff(ylim)
  y_range <- function(fit) {
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
    plot(fit, type = "stability")
    graphics::par("usr")[3:4]
  }

  # Every rating is 4 in both rounds: no chi-square can be computed.
  same <- rbind(long(cbind(S1 = rep(4, 4), S2 = rep(4, 4)), 1),
                long(cbind(S1 = rep(4, 4), S2 = rep(4, 4)), 2))
  fit <- delphi_validity(same, lo = 1, hi = 4, stability = "chisq_group",
                         B = 0)
  expect_true(all(is.na(fit$details$stability$value)))
  expect_equal(y_range(fit), usr)

  # Experts swap answers, so each round has the same distribution and the
  # group chi-square is 0 for both items.
  swap <- rbind(long(cbind(S1 = c(4, 3, 4, 3), S2 = c(1, 2, 2, 1)), 1),
                long(cbind(S1 = c(3, 4, 3, 4), S2 = c(2, 1, 1, 2)), 2))
  fit <- delphi_validity(swap, lo = 1, hi = 4, stability = "chisq_group",
                         B = 0)
  expect_identical(fit$details$stability$value, c(0, 0))
  expect_equal(y_range(fit), usr)
})

# compare_rounds() ------------------------------------------------------------

sort_round <- function(i2) {
  data.frame(item = rep(c("I1", "I2"), each = 6), rater = rep(1:6, times = 2),
             assigned_construct = c(rep("A", 6), i2),
             target_construct = "A", stringsAsFactors = FALSE)
}

test_that("a panel that changes size is shown as one size or a range", {
  # In round 2 one judge leaves I2 unsorted: five judges sort it, six I1.
  f1 <- sort_validity(sort_round(c(rep("A", 5), "B")))
  f2 <- sort_validity(sort_round(c(rep("A", 5), NA)))
  cmp <- compare_rounds(f1, f2)
  expect_false(cmp$comparable)
  sc <- cmp$settings_changes
  expect_identical(sc$setting, "panel size")
  expect_identical(c(sc$previous, sc$current), c("6", "5-6"))
})

test_that("a consensus threshold of 1 is written to two decimals", {
  # The threshold is a proportion, written without its leading zero; a whole
  # 1 has no decimals of its own, so it takes the two that .75 has.
  g1 <- delphi_validity(two_rounds(), lo = 1, hi = 4, consensus_threshold = 1,
                        B = 0)
  g2 <- delphi_validity(two_rounds(), lo = 1, hi = 4,
                        consensus_threshold = .75, B = 0)
  sc <- compare_rounds(g1, g2)$settings_changes
  expect_identical(sc$setting, "consensus_threshold")
  expect_identical(c(sc$previous, sc$current), c("1.00", ".75"))
})

test_that("a comparison saved before n_changed existed prints the same", {
  # Without a threshold every item is Descriptive only, so each move to
  # Supported or Review is a change in neither direction.
  g0 <- delphi_validity(two_rounds(), lo = 1, hi = 4, B = 0)
  g2 <- delphi_validity(two_rounds(), lo = 1, hi = 4,
                        consensus_threshold = .75, B = 0)
  cmp <- compare_rounds(g0, g2)
  expect_identical(cmp$summary$n_changed, 2L)
  # Objects from 0.4.0 to 0.10.1 have no n_changed: what the other counts
  # leave of Compared is the count of other changes.
  old <- cmp
  old$summary$n_changed <- NULL
  out <- utils::capture.output(print(old))
  expect_identical(out, utils::capture.output(print(cmp)))
  expect_match(paste(out, collapse = " "),
               "Other: a change to or from Descriptive only", fixed = TRUE)
})

test_that("a fit whose results lost the unit column is refused by name", {
  f1 <- sort_validity(sort_round(c(rep("A", 5), "B")))
  f2 <- f1
  names(f2$results)[names(f2$results) == "item"] <- "Item"
  expect_error(compare_rounds(f1, f2),
               "Expected an `item` column in the workflow results")
})

test_that("a comparison of rounds refuses to plot before opening a device", {
  f1 <- sort_validity(sort_round(c(rep("A", 5), "B")))
  cmp <- compare_rounds(f1, f1)
  devices <- grDevices::dev.list()
  expect_error(plot(cmp), "A comparison of rounds has no figure")
  expect_identical(grDevices::dev.list(), devices)
})

# panel_agreement() -----------------------------------------------------------

test_that("AC1 on a panel with no ratings at all says it cannot be estimated", {
  ag <- panel_agreement(matrix(NA_real_, 3, 2), method = "ac1", B = 0)
  expect_identical(ag$estimate, NA_real_)
  expect_identical(ag$n_items, 0L)
  expect_match(ag$interpretation, "No item was rated by at least two raters",
               fixed = TRUE)
  expect_match(printed(ag), "Gwet's AC1: undefined", fixed = TRUE)
})

test_that("AC1 where no item has two ratings has no estimate or interval", {
  # Each rater rated a different item.
  X <- rbind(c(1, NA), c(NA, 0))
  ag <- panel_agreement(X, method = "ac1", B = 20, seed = 1)
  expect_identical(ag$estimate, NA_real_)
  expect_identical(ag$n_items, 0L)
  # No resample can pair two ratings either.
  expect_identical(ag$n_boot_usable, 0L)
  expect_identical(c(ag$ci_low, ag$ci_high), c(NA_real_, NA_real_))
})

test_that("the printout counts the resamples where alpha was undefined", {
  # Item 1 is rated 4 by everyone, so a resample of item 1 twice has no
  # disagreement and no alpha; every other resample has one.
  X <- cbind(c(4, 4, 4, 4), c(1, 2, 3, 4))
  ag <- panel_agreement(X, B = 40, seed = 1)
  # The same draws, counted directly.
  lost <- withr::with_seed(1, sum(vapply(seq_len(40), function(b) {
    all(sample.int(2, 2, replace = TRUE) == 1L)
  }, logical(1))))
  expect_gt(lost, 0L)
  expect_identical(ag$n_boot_usable, 40L - lost)
  expect_match(printed(ag),
               paste0("In ", lost, " of 40 resamples the coefficient could ",
                      "not be computed, usually because every resampled ",
                      "rating was identical; the interval uses the rest."),
               fixed = TRUE)
})

test_that("expert_validity() says when panel agreement is undefined", {
  # Every expert rates every item 4: nothing to disagree about.
  m <- matrix(4, 4, 3, dimnames = list(NULL, c("I1", "I2", "I3")))
  ev <- expert_validity(m, mode = "relevance", lo = 1, hi = 4,
                        agreement_B = 0)
  line <- paste("Panel agreement, Krippendorff's alpha (ordinal): undefined;",
                "every paired rating was identical.")
  expect_match(printed(ev), line, fixed = TRUE)
  expect_match(printed(summary(ev)), line, fixed = TRUE)
})

test_that("expert_validity() says when no item has two ratings to agree", {
  m <- rbind(c(4, NA, NA), c(NA, 3, NA), c(NA, NA, 4))
  colnames(m) <- c("I1", "I2", "I3")
  ev <- expert_validity(m, mode = "relevance", lo = 1, hi = 4, na.rm = TRUE,
                        agreement_B = 0)
  expect_identical(ev$details$agreement$n_items, 0L)
  line <- paste("Panel agreement, Krippendorff's alpha (ordinal): not",
                "estimable; no item has two ratings.")
  expect_match(printed(ev), line, fixed = TRUE)
  expect_match(printed(summary(ev)), line, fixed = TRUE)
})

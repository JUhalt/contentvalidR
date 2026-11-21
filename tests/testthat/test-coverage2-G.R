# Tests for the last paths of delphi_validity() and compare_rounds() that
# covr 4.0.0 found no test running. No fit the package makes takes them: each
# needs a fit a user has edited by hand, or a direct call to the helper that
# a public function uses. They are grouped by the function they exercise.

# compare_rounds(): the panel size of an edited fit ----------------------------

ess_fit <- function(n) {
  X <- matrix(1, n, 2, dimnames = list(NULL, c("Q1", "Q2")))
  expert_validity(X, mode = "essentiality")
}

sort_fit <- function(n) {
  sort_validity(data.frame(item = rep(c("I1", "I2"), each = n),
                           rater = rep(seq_len(n), times = 2),
                           assigned_construct = "A", target_construct = "A",
                           stringsAsFactors = FALSE))
}

test_that("a design without its panel range falls back to its panel size", {
  # Essentiality fits record the number of judges as n_judges.
  e6 <- ess_fit(6)
  e8 <- ess_fit(8)
  expect_identical(c(e6$design$n_judges, e8$design$n_judges), c(6L, 8L))
  e6$design[c("n_judges_min", "n_judges_max")] <- NULL
  e8$design[c("n_judges_min", "n_judges_max")] <- NULL
  cmp <- compare_rounds(e6, e8)
  expect_false(cmp$comparable)
  expect_identical(cmp$settings_changes$setting, "panel size")
  expect_identical(c(cmp$settings_changes$previous,
                     cmp$settings_changes$current), c("6", "8"))

  # Item-sort fits have no n_judges; they record their raters as n_raters.
  s6 <- sort_fit(6)
  s5 <- sort_fit(5)
  expect_null(s6$design$n_judges)
  expect_identical(c(s6$design$n_raters, s5$design$n_raters), c(6L, 5L))
  s6$design[c("n_judges_min", "n_judges_max")] <- NULL
  s5$design[c("n_judges_min", "n_judges_max")] <- NULL
  cmp <- compare_rounds(s6, s5)
  expect_false(cmp$comparable)
  expect_identical(cmp$settings_changes$setting, "panel size")
  expect_identical(c(cmp$settings_changes$previous,
                     cmp$settings_changes$current), c("6", "5"))
})

test_that("a panel size that cannot be read is left out of the comparison", {
  # Six judges against eight would be a changed panel, but the first fit's
  # design no longer says how many judges it had.
  e6 <- ess_fit(6)
  e6$design$n_judges_min <- NA_integer_
  e6$design$n_judges <- NA_integer_
  expect_identical(contentvalidR:::.round_panel_size(e6), NA_character_)
  cmp <- compare_rounds(e6, ess_fit(8))
  expect_true(cmp$comparable)
  expect_identical(nrow(cmp$settings_changes), 0L)
})

# compare_rounds(): settings with no short printed form -----------------------

test_that("a setting too long or too nested to print is shown by its class", {
  f1 <- sort_fit(6)
  f2 <- f1
  f1$settings$labels <- list("a")
  f2$settings$labels <- list("b")
  f2$settings$cuts <- c(.1, .2, .3, .4, .5)
  cmp <- compare_rounds(f1, f2)
  expect_false(cmp$comparable)
  expect_identical(
    cmp$settings_changes,
    data.frame(from = "Round 1", to = "Round 2", setting = c("labels", "cuts"),
               previous = c("<list>", "(not set)"),
               current = c("<list>", "<numeric>"), stringsAsFactors = FALSE)
  )
  out <- gsub("\\s+", " ",
              paste(utils::capture.output(print(cmp)), collapse = " "))
  expect_match(out, "Round 1 Round 2 cuts (not set) <numeric>", fixed = TRUE)
})

# delphi_validity(): helpers on inputs no fit gives them ----------------------

test_that("weighted kappa with no paired ratings is undefined, not an error", {
  V <- contentvalidR:::.delphi_disagreement_weights(4, "quadratic")
  expect_identical(
    contentvalidR:::.delphi_weighted_kappa(integer(0), integer(0), V),
    NA_real_
  )
})

test_that("the stability trend table follows the rows unless given rounds", {
  # Rows in an order that is not round order: item A's later pair first.
  stab <- data.frame(item = c("A", "A", "B"), from_round = c("2", "1", "1"),
                     to_round = c("3", "2", "2"), value = c(.5, .25, 1),
                     stringsAsFactors = FALSE)
  wide <- contentvalidR:::.delphi_wide
  as_rows <- wide(stab, "value", 2)
  expect_identical(names(as_rows), c("item", "2->3", "1->2"))
  expect_identical(as_rows$item, c("A", "B"))
  expect_identical(as_rows[["2->3"]], c(".50", "--"))
  expect_identical(as_rows[["1->2"]], c(".25", "1.00"))
  # Given the rounds, the same cells are read left to right as a trend.
  by_round <- wide(stab, "value", 2, rounds = c("1", "2", "3"))
  expect_identical(names(by_round), c("item", "1->2", "2->3"))
  expect_identical(by_round[names(as_rows)], as_rows)
  # No pair of rounds, no table.
  expect_null(wide(stab[0, ], "value", 2))
})

test_that("a Delphi fit without its consensus table prints no pair note", {
  delphi_long <- function(m, round) {
    data.frame(expert = paste0("E", seq_len(nrow(m))),
               item = rep(colnames(m), each = nrow(m)),
               round = round, rating = as.vector(m), stringsAsFactors = FALSE)
  }
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4), S2 = c(2, 3, 2, 1, 3, 2))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2))
  r3 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 2, 2))
  d <- rbind(delphi_long(r1, 1), delphi_long(r2, 2), delphi_long(r3, 3))
  # S2 skips round 2, so it has no consecutive pair to compare.
  d <- d[!(d$item == "S2" & d$round == 2), ]
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  rated <- contentvalidR:::.delphi_rated_rounds
  expect_identical(rated(fit), list(S1 = 1:3, S2 = c(1L, 3L)))
  note <- "Rated in rounds that are not consecutive, so no pair was compared"
  intact <- utils::capture.output(print(fit))
  expect_match(paste(intact, collapse = " "), note, fixed = TRUE)

  # Without the table there is no record of the rounds each item was rated
  # in: the note goes, and the rest of the printout stays.
  edited <- fit
  edited$details$consensus <- NULL
  expect_identical(rated(edited), list())
  out <- utils::capture.output(print(edited))
  expect_false(grepl(note, paste(out, collapse = " "), fixed = TRUE))
  expect_identical(setdiff(out, intact), character(0))
  edited$details$consensus <- fit$details$consensus[0, ]
  expect_identical(rated(edited), list())
})

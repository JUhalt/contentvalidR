# Psa and Csv must not depend on how the construct labels happen to be stored.
# Numeric codes once indexed the table of counts by position, so a target coded
# 2 read the second cell, whatever construct that was.

sort_rows <- function(item, target, picks) {
  data.frame(item = item, rater = seq_along(picks), assigned_construct = picks,
             target_construct = target, stringsAsFactors = FALSE)
}

numeric_codes <- rbind(
  sort_rows("Q1", 2, c(rep(2, 16), rep(3, 4))),
  sort_rows("Q2", 1, c(rep(1, 15), rep(2, 5)))
)
text_codes <- transform(
  numeric_codes,
  assigned_construct = paste0("C", assigned_construct),
  target_construct = paste0("C", target_construct)
)

test_that("numeric construct codes give the same counts as text codes", {
  num <- as.data.frame(compute_csv(numeric_codes))
  txt <- as.data.frame(compute_csv(text_codes))
  expect_identical(num$n_target, c(16L, 15L))
  expect_identical(num$n_target, txt$n_target)
  expect_identical(num$n_other_max, c(4L, 5L))
  expect_equal(num$csv, c(.60, .50))
  expect_identical(num$competitor, c("3", "2"))
  expect_identical(as.data.frame(compute_psa(numeric_codes))$n_target, c(16L, 15L))
})

test_that("numeric construct codes give the right decisions and handoff", {
  fit <- sort_validity(numeric_codes)
  ref <- sort_validity(text_codes)
  expect_identical(fit$results$recommendation, c("Retain", "Retain"))
  expect_identical(fit$results$n_target, ref$results$n_target)
  expect_equal(fit$results$p_value, ref$results$p_value)
  expect_equal(fit$results$csv, ref$results$csv)
  expect_identical(content_handoff(fit)$items, c("Q1", "Q2"))
})

test_that("a numeric target with no assignment in its table position is counted", {
  # Target 3 with only codes 1 and 3 used: position 3 does not exist.
  d <- sort_rows("Q1", 3, c(rep(3, 9), 1))
  expect_identical(as.data.frame(compute_csv(d))$n_target, 9L)
  expect_silent(fit <- sort_validity(d))
  expect_identical(fit$results$n_target, 9L)
})

test_that("factor columns with different level sets are compared by label", {
  d <- data.frame(
    item = rep(c("I1", "I2"), each = 6), rater = rep(1:6, 2),
    assigned_construct = factor(c("A", "A", "A", "B", "C", "A",
                                  "B", "B", "B", "B", "A", "C")),
    target_construct = factor(rep(c("A", "B"), each = 6))
  )
  psa <- as.data.frame(compute_psa(d))
  expect_identical(psa$n_target, c(4L, 4L))
  expect_type(psa$item, "character")
  expect_type(psa$target, "character")
  fit <- sort_validity(d)
  expect_equal(fit$results$psa, c(4 / 6, 4 / 6))
  expect_equal(fit$results$csv, c(.5, .5))
})

test_that("leading and trailing spaces do not split a construct in two", {
  d <- sort_rows("A1", "A", c(rep("A", 17), " A", "B", "C "))
  fit <- sort_validity(d)
  expect_identical(fit$results$n_target, 18L)
  expect_identical(fit$results$competitor, "B; C")
  expect_identical(fit$design$n_constructs_observed, 3L)
})

test_that("items keep the order of the data, or of a factor's levels", {
  items <- paste0("Q", c(1, 2, 10, 11))
  d <- do.call(rbind, lapply(items, function(i) {
    sort_rows(i, "A", c(rep("A", 16), rep("B", 4)))
  }))
  expect_identical(as.data.frame(compute_psa(d))$item, items)
  expect_identical(as.data.frame(compute_csv(d))$item, items)
  fit <- sort_validity(d)
  expect_identical(fit$results$item, items)
  expect_identical(content_handoff(fit)$items, items)

  # A factor states its own order.
  d$item <- factor(d$item, levels = rev(items))
  expect_identical(sort_validity(d)$results$item, rev(items))

  # An integer item column is reported as text, like every other workflow.
  d$item <- rep(c(3L, 1L, 2L, 10L), each = 20)
  expect_identical(sort_validity(d)$results$item, c("3", "1", "2", "10"))
})

test_that("the csv_binom_test interval follows alpha and agrees with the test", {
  expect_equal(attr(csv_binom_test(15, 20)$conf.int, "conf.level"), .95)
  wide <- csv_binom_test(14, 20, alpha = .10)
  expect_equal(attr(wide$conf.int, "conf.level"), .90)
  expect_true(wide$passes_chance)
  expect_gt(wide$conf.int[1], wide$p0)

  # The one-sided bound excludes p0 exactly when the test rejects.
  for (alpha in c(.01, .05, .10)) {
    for (n_c in 0:20) {
      b <- csv_binom_test(n_c, 20, alpha = alpha)
      expect_identical(b$conf.int[1] > b$p0, b$passes_chance)
    }
  }
  expect_match(paste(capture.output(print(wide)), collapse = " "),
               "One-sided 90% CI for the target rate", fixed = TRUE)
})

test_that("a panel too small for the exact test has power 0, not NA", {
  plan <- sort_power(N = c(3, 4, 5), true_p = c(.9, 1))
  tab <- plan$table
  expect_true(all(is.na(tab$critical_n_target[tab$N < 5])))
  expect_identical(tab$power[tab$N < 5], rep(0, 4))
  expect_equal(tab$power[tab$N == 5], c(.9^5, 1))
  out <- capture.output(print(plan))
  expect_true(any(grepl("3 +none +-- +\\.00 +\\.00", out)))
  expect_false(any(grepl("NA", out, fixed = TRUE)))
  expect_match(paste(out, collapse = " "),
               "With 4 or fewer judges, no count of target assignments reaches alpha = .05",
               fixed = TRUE)
  # Nothing is said about small panels when every size can be decided.
  expect_false(any(grepl("no count", capture.output(print(sort_power(20, .7))))))
})

test_that("items sorted by too few judges get no decision, and say why", {
  d <- rbind(sort_rows("A1", "A", rep("A", 4)),
             sort_rows("A2", "A", c("A", "A", "B", "B")))
  fit <- sort_validity(d)
  expect_identical(fit$results$recommendation, rep("Insufficient panel", 2))
  expect_identical(fit$results$status, rep("Insufficient data", 2))
  expect_identical(fit$results$issue, rep("Too few judges for the exact test", 2))
  expect_match(fit$results$interpretation[1],
               "With 4 judges, no count of target assignments can reach alpha = .05",
               fixed = TRUE)
  # A Psa from four judges does not set a scale's benchmark band.
  expect_identical(fit$scale_summary$n_items_usable, 0L)
  expect_true(is.na(fit$scale_summary$mean_psa))

  out <- paste(capture.output(print(fit)), collapse = " ")
  expect_match(out, "Too few judges for the exact test: A1, A2. With 4 or fewer judges,",
               fixed = TRUE)
  expect_match(out, "Insufficient panel -- too few judges sorted it", fixed = TRUE)
  expect_false(grepl("Flagged for review", out, fixed = TRUE))

  h <- content_handoff(fit, keep = c("Supported", "Review", "Insufficient data"))
  expect_false(any(grepl("NA", h$item_evidence$rule, fixed = TRUE)))
  expect_match(h$item_evidence$rule[1],
               "no count of target assignments out of 4 can meet the exact",
               fixed = TRUE)
  expect_identical(content_handoff(fit)$items, character(0))
})

test_that("an unsorted item's handoff rule says no judge sorted it", {
  d <- rbind(sort_rows("I1", "A", c(rep("A", 16), rep("B", 4))),
             sort_rows("I2", "A", rep(NA_character_, 20)))
  h <- content_handoff(sort_validity(d),
                       keep = c("Supported", "Review", "Insufficient data"))
  rule <- h$item_evidence$rule[h$item_evidence$item == "I2"]
  expect_match(rule, "no judge sorted the item", fixed = TRUE)
  expect_false(grepl("NA", rule, fixed = TRUE))
})

test_that("alpha is printed with the digits it was given", {
  expect_identical(contentvalidR:::.fmt_alpha(c(.05, .10, .025, .001, .005)),
                   c(".05", ".10", ".025", ".001", ".005"))
  d <- sort_rows("A1", "A", c(rep("A", 19), "B"))
  fit <- sort_validity(d, alpha = .001)
  out <- paste(capture.output(print(fit)), collapse = " ")
  expect_match(out, "alpha = .001)", fixed = TRUE)
  expect_false(grepl("alpha = .00)", out, fixed = TRUE))
  expect_match(content_handoff(fit)$item_evidence$rule, "alpha = .001$")
  expect_match(paste(capture.output(print(csv_binom_test(19, 20, alpha = .001))),
                     collapse = " "),
               "At alpha = .001 an item needs at least 18 of 20.", fixed = TRUE)
})

test_that("a scale mean on a published band minimum falls in that band", {
  # 4.35 / 5 is stored a hair under .87, the Strong minimum for HTC.
  expect_lt(4.35 / 5, .87)
  expect_identical(as.data.frame(interpret_colquitt(4.35 / 5, "htc"))$interpretation,
                   "Strong")
  expect_identical(as.data.frame(interpret_colquitt(4.55 / 5, "htc"))$interpretation,
                   "Very Strong")
  expect_identical(as.data.frame(interpret_colquitt(.8699, "htc"))$interpretation,
                   "Moderate")
})

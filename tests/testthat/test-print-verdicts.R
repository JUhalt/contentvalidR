# Every workflow print opens with its verdict: how many items met the
# criterion, then the flagged items by name. These tests hold the expert-panel
# print to that, and check small printed claims that were once wrong.

# Output wraps at the console width, so whitespace is collapsed before matching.
printed <- function(x) {
  gsub("\\s+", " ", paste(utils::capture.output(print(x)), collapse = " "))
}

relevance <- matrix(c(4, 4, 4, 3, 4, 4, 3, 4, 3, 4, 4, 4, 2, 2, 1, 2), nrow = 4,
                    dimnames = list(NULL, paste0("I", 1:4)))

test_that("the relevance print names the verdict and the flagged item", {
  fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
                         agreement = "none")
  out <- printed(fit)
  met <- sum(fit$results$status == "Supported")
  expect_match(out, sprintf("%d of 4 items meet the I-CVI criterion", met),
               fixed = TRUE)
  expect_match(out, "Flagged for review: I4", fixed = TRUE)
  # The verdict comes before the item table.
  expect_lt(regexpr("items meet the I-CVI criterion", out, fixed = TRUE),
            regexpr("decision", out, fixed = TRUE))
})

test_that("items rated by too few experts are named, not left out", {
  fit <- expert_validity(relevance[1:2, ], mode = "relevance", lo = 1, hi = 4,
                         agreement = "none")
  out <- printed(fit)
  expect_match(out, "0 of 4 items meet the I-CVI criterion.", fixed = TRUE)
  expect_match(out, "Too few experts to judge (fewer than three): I1, I2, I3, I4",
               fixed = TRUE)
})

test_that("the essentiality and congruence prints state their verdicts", {
  ess <- expert_validity(c(10, 8, 6), mode = "essentiality", N = 12)
  out <- printed(ess)
  expect_match(out, "1 of 3 items meets the exact essentiality criterion.",
               fixed = TRUE)
  expect_match(out, "Flagged for review: Item2, Item3", fixed = TRUE)

  d <- expand.grid(item = c("I1", "I2"), judge = 1:4, objective = c("A", "B"))
  d$target_objective <- ifelse(d$item == "I1", "A", "B")
  d$score <- ifelse(d$objective == d$target_objective, 1, -1)
  expect_match(printed(expert_validity(d, mode = "congruence")),
               "2 of 2 items meet the congruence criterion for their target objective.",
               fixed = TRUE)
})

test_that("a panel with no usable essentiality ratings prints no NA", {
  out <- printed(expert_validity(c(0, 0), mode = "essentiality", N = 0))
  expect_false(grepl("at least NA", out, fixed = TRUE))
  expect_match(out, "Insufficient data: Item1, Item2", fixed = TRUE)
})

test_that("the key does not claim modified kappa stays between 0 and 1", {
  fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
                         agreement = "none")
  # With four experts an item nobody rates relevant is below chance.
  expect_lt(fit$results$kappa_mod[fit$results$item == "I4"], 0)
  expect_equal(round(fit$results$kappa_mod[fit$results$item == "I4"], 2), -0.07)
  out <- printed(fit)
  expect_match(out, "below 0 when agreement is below chance", fixed = TRUE)
  expect_false(grepl("overstate consensus. (0 to 1", out, fixed = TRUE))
})

test_that("the handoff mentions held-back items only when there are some", {
  all_in <- content_handoff(expert_validity(relevance[, 1:3], mode = "relevance",
                                            lo = 1, hi = 4, agreement = "none"))
  expect_false(grepl("listed above", printed(all_in), fixed = TRUE))
  some_out <- content_handoff(expert_validity(relevance, mode = "relevance",
                                              lo = 1, hi = 4, agreement = "none"))
  expect_match(printed(some_out), "listed above", fixed = TRUE)
})

test_that("counts take the right noun", {
  expect_identical(.n_noun(c(0, 1, 3), "item"), c("0 items", "1 item", "3 items"))
  expect_identical(.n_noun(1, "item addresses", "items address"),
                   "1 item addresses")
})

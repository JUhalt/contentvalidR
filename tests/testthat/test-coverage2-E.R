# Tests for the second coverage round on domain_validity() and
# content_structure(): the three fixes found in the first round (all-zero
# targets, the reason given for an undefined index, item names in a map from
# an unnamed matrix) and the branches covr 4.0.0 still found no test running.

# The nine-item similarity ratings from the content_structure() examples:
# three items written for each of three blueprint cells.
e2_similarity <- function() {
  items <- paste0("I", 1:9)
  matrix(c(
    5, 4, 3, 2, 2, 1, 1, 2, 1,
    4, 5, 4, 3, 1, 2, 2, 1, 1,
    3, 4, 5, 1, 2, 2, 1, 1, 3,
    2, 3, 1, 5, 4, 3, 2, 2, 1,
    2, 1, 2, 4, 5, 4, 1, 3, 2,
    1, 2, 2, 3, 4, 5, 2, 1, 2,
    1, 2, 1, 2, 1, 2, 5, 3, 4,
    2, 1, 1, 2, 3, 1, 3, 5, 4,
    1, 1, 3, 1, 2, 2, 4, 4, 5
  ), 9, 9, dimnames = list(items, items))
}

e2_blueprint <- function() {
  rep(c("Autonomy", "Competence", "Relatedness"), each = 3)
}

# Printed text with its line breaks and indents collapsed to single spaces,
# so a check does not depend on where a sentence wraps.
e2_printed <- function(x) {
  gsub("[[:space:]]+", " ", paste(utils::capture.output(print(x)),
                                  collapse = " "))
}

# domain_validity(): targets ---------------------------------------------

test_that("targets that give every cell zero items are refused", {
  assignments <- data.frame(item = paste0("I", 1:4),
                            cell = c("A", "A", "B", "B"))
  refusal <- "`targets` must give at least one cell a positive number of items."
  expect_error(domain_validity(assignments, targets = c(A = 0, B = 0)),
               refusal, fixed = TRUE)
  expect_error(domain_validity(assignments, domain = c("A", "B", "C"),
                               targets = c(A = 0, B = 0, C = 0)),
               refusal, fixed = TRUE)
})

test_that("a zero target beside a positive one still means no items there", {
  assignments <- data.frame(item = paste0("I", 1:4),
                            cell = c("A", "A", "B", "B"))
  fit <- domain_validity(assignments, targets = c(A = 2, B = 0))
  # Expected shares are the targets over their sum: 2 / 2 and 0 / 2.
  expect_identical(fit$results$expected_share, c(1, 0))
  expect_identical(fit$results$recommendation,
                   c("Covered", "Over-represented"))
  expect_identical(fit$results$status, c("Supported", "Review"))
})

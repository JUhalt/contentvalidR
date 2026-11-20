# Tests for the last untested branches of the reporting, the data-frame
# export and the name checks, and for the duplicate-name message, grouped by
# the function they exercise.

# .check_unique_names(), through judge_validity() -----------------------------

test_that("more than five repeated names end the list with a count, not dots", {
  # Seven item names used twice: five are listed and the other two counted,
  # as the package's other lists cut at five are.
  X <- matrix(3, 6, 14, dimnames = list(paste0("J", 1:6),
                                        rep(LETTERS[1:7], 2)))
  expect_error(judge_validity(X),
               paste("Each item needs its own name, but these column names",
                     "are used more than once: A, B, C, D, E and 2 more."),
               fixed = TRUE)
  # Six judge names used twice: one is counted.
  Y <- matrix(3, 12, 3, dimnames = list(rep(paste0("J", 1:6), 2),
                                        paste0("I", 1:3)))
  expect_error(judge_validity(Y),
               paste("Each judge needs its own name, but these row names",
                     "are used more than once: J1, J2, J3, J4, J5 and 1 more."),
               fixed = TRUE)
})

round_data <- function(i1, i2) {
  data.frame(
    item = rep(c("I1", "I2"), each = 6),
    rater = rep(1:6, times = 2),
    assigned_construct = c(i1, i2),
    target_construct = "A",
    stringsAsFactors = FALSE
  )
}

weak_round <- function() round_data(c(rep("A", 4), "B", "B"), c(rep("A", 3), rep("B", 3)))
strong_round <- function() round_data(rep("A", 6), c(rep("A", 5), "B"))

test_that("transitions record each unit's status in every round", {
  f1 <- sort_validity(weak_round())
  f2 <- sort_validity(strong_round())
  cmp <- compare_rounds(f1, f2)

  expect_s3_class(cmp, "contentvalid_rounds")
  expect_equal(cmp$n_rounds, 2L)
  expect_equal(cmp$labels, c("Round 1", "Round 2"))
  expect_equal(nrow(cmp$transitions), 2L)
  expect_true(all(c("item", "Round 1", "Round 2", "change") %in% names(cmp$transitions)))

  expect_equal(cmp$transitions$`Round 1`, f1$results$status)
  expect_equal(cmp$transitions$`Round 2`, f2$results$status)
})

test_that("change direction follows the evidential ordering of statuses", {
  cmp <- compare_rounds(sort_validity(weak_round()), sort_validity(strong_round()))
  t <- cmp$transitions

  expect_equal(t$change[t$item == "I1"], "Strengthened")
  expect_equal(t$change[t$item == "I2"], "Unchanged")

  # Reversing the rounds reverses the direction.
  rev_cmp <- compare_rounds(sort_validity(strong_round()), sort_validity(weak_round()))
  expect_equal(rev_cmp$transitions$change[rev_cmp$transitions$item == "I1"], "Weakened")
})

test_that("status ranking orders evidence and leaves descriptive results unranked", {
  expect_lt(contentvalidR:::.status_rank("Insufficient data"),
            contentvalidR:::.status_rank("Review"))
  expect_lt(contentvalidR:::.status_rank("Review"),
            contentvalidR:::.status_rank("Supported"))
  # "Descriptive only" applied no decision rule, so it is not better or worse.
  expect_true(is.na(contentvalidR:::.status_rank("Descriptive only")))
})

test_that("changed analysis settings mark the comparison as not comparable", {
  f1 <- sort_validity(weak_round())
  f2 <- sort_validity(strong_round(), p0 = 0.7)
  cmp <- compare_rounds(f1, f2)

  expect_false(cmp$comparable)
  expect_true(any(cmp$settings_changes$setting == "p0"))
  changed <- cmp$settings_changes[cmp$settings_changes$setting == "p0", ]
  expect_equal(changed$previous, "0.5")
  expect_equal(changed$current, "0.7")
  expect_true(cmp$summary$settings_changed)

  # The warning must appear in the output, not only in the object.
  out <- paste(capture.output(print(cmp)), collapse = " ")
  expect_match(out, "analyzed under different settings")
  expect_match(out, "may reflect the changed rule rather than changed\\s+evidence")
})

test_that("identical settings are reported as comparable", {
  cmp <- compare_rounds(sort_validity(weak_round()), sort_validity(strong_round()))
  expect_true(cmp$comparable)
  expect_equal(nrow(cmp$settings_changes), 0L)

  out <- paste(capture.output(print(cmp)), collapse = " ")
  expect_match(out, "Settings were identical across rounds")
})

test_that("round-to-round summary counts each consecutive pair", {
  f1 <- sort_validity(weak_round())
  f2 <- sort_validity(strong_round())
  f3 <- sort_validity(round_data(rep("A", 6), rep("A", 6)))
  cmp <- compare_rounds(f1, f2, f3, labels = c("Pilot", "Rev1", "Rev2"))

  expect_equal(nrow(cmp$summary), 2L)
  expect_equal(cmp$summary$from, c("Pilot", "Rev1"))
  expect_equal(cmp$summary$to, c("Rev1", "Rev2"))
  expect_equal(cmp$labels, c("Pilot", "Rev1", "Rev2"))

  # Counts must partition the compared units.
  for (i in seq_len(nrow(cmp$summary))) {
    row <- cmp$summary[i, ]
    expect_equal(row$n_unchanged + row$n_strengthened + row$n_weakened,
                 row$n_compared)
  }
})

test_that("units entering or leaving the item set are labelled", {
  f1 <- sort_validity(weak_round())
  extra <- rbind(
    strong_round(),
    data.frame(item = "I3", rater = 1:6, assigned_construct = rep("A", 6),
               target_construct = "A", stringsAsFactors = FALSE)
  )
  cmp <- compare_rounds(f1, sort_validity(extra))

  expect_equal(cmp$transitions$change[cmp$transitions$item == "I3"], "Added")
  expect_true(is.na(cmp$transitions$`Round 1`[cmp$transitions$item == "I3"]))
  expect_equal(cmp$summary$n_added, 1L)

  # And the reverse direction is a removal.
  rev_cmp <- compare_rounds(sort_validity(extra), f1)
  expect_equal(rev_cmp$transitions$change[rev_cmp$transitions$item == "I3"], "Removed")
  expect_equal(rev_cmp$summary$n_removed, 1L)
})

test_that("comparisons across different workflows are refused", {
  f1 <- sort_validity(weak_round())
  ev <- expert_validity(cbind(A = c(4, 4, 4, 4, 4, 4)), mode = "relevance",
                        lo = 1, hi = 4)
  expect_error(compare_rounds(f1, ev), "must come from the same workflow")
})

test_that("malformed calls are rejected", {
  f1 <- sort_validity(weak_round())
  f2 <- sort_validity(strong_round())

  expect_error(compare_rounds(f1), "at least two")
  expect_error(compare_rounds(f1, "not a workflow"), "fitted contentvalidR workflow")
  expect_error(compare_rounds(f1, f2, labels = "only one"), "one entry per round")
  expect_error(compare_rounds(f1, f2, labels = c("same", "same")), "must be distinct")
})

test_that("judge and domain workflows compare on their own unit of analysis", {
  ratings <- rbind(
    c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
    c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(4, 3, 4, 3, 1, 2),
    c(4, 4, 3, 4, 2, 2), c(2, 2, 2, 2, 1, 1)
  )
  dimnames(ratings) <- list(paste0("Judge", 1:8), paste0("Item", 1:6))
  j1 <- judge_validity(ratings, lo = 1, hi = 4)
  j2 <- judge_validity(ratings, lo = 1, hi = 4)
  cmp <- compare_rounds(j1, j2)
  expect_equal(cmp$id_col, "judge")
  expect_true("judge" %in% names(cmp$transitions))
  expect_true(all(cmp$transitions$change == "Unchanged"))

  assignments <- data.frame(
    item = paste0("I", 1:4),
    cell = c("A", "A", "B", "B"),
    stringsAsFactors = FALSE
  )
  d1 <- domain_validity(assignments, domain = c("A", "B", "C"))
  d2 <- domain_validity(assignments, domain = c("A", "B", "C"))
  dcmp <- compare_rounds(d1, d2)
  expect_equal(dcmp$id_col, "cell")
  expect_true("cell" %in% names(dcmp$transitions))
})

test_that("output warns that crossing a criterion is not a measured improvement", {
  cmp <- compare_rounds(sort_validity(weak_round()), sort_validity(strong_round()))
  out <- paste(capture.output(print(cmp)), collapse = " ")
  expect_match(out, "crossed a criterion")
  expect_match(out, "not that an item\\s+improved by a measurable amount")
})

test_that("summary lists only the units that changed", {
  s <- summary(compare_rounds(sort_validity(weak_round()),
                              sort_validity(strong_round())))
  expect_s3_class(s, "summary.contentvalid_rounds")
  expect_equal(nrow(s$changed), 1L)
  expect_equal(s$changed$item, "I1")

  stable <- summary(compare_rounds(sort_validity(weak_round()),
                                   sort_validity(weak_round())))
  expect_equal(nrow(stable$changed), 0L)
  expect_match(paste(capture.output(print(stable)), collapse = " "),
               "No unit changed status")
})

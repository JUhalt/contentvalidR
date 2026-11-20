# Tests from the second coverage round for the expert-panel workflow: a
# congruence fit saved before 1.0, which summary() now refuses as
# content_report() does, and the printout branches that only a results
# frame or fit edited by hand reaches.

# The printed output on an 80-column console, with runs of white space
# collapsed so a sentence can be matched however it was wrapped.
c2_flat <- function(x, ...) {
  old <- options(width = 80)
  on.exit(options(old), add = TRUE)
  out <- utils::capture.output(print(x, ...))
  gsub("[[:space:]]+", " ", paste(out, collapse = "\n"))
}

# Three items rated by four experts against objectives A and B, the data of
# test-audit-ioc.R. With two objectives the index is half the gap between
# the two means: I1 (target A) 1, I2 (target B) .50, I3 (target A) -.50.
c2_congruence <- function(target = TRUE) {
  d <- expand.grid(item = c("I1", "I2", "I3"), judge = 1:4,
                   objective = c("A", "B"), stringsAsFactors = FALSE)
  d$score <- with(d, ifelse(
    item == "I1", ifelse(objective == "A", 1, -1),
    ifelse(item == "I2", ifelse(objective == "B", 1, 0),
           ifelse(objective == "A", 0, 1))))
  if (target) d$target_objective <- c(I1 = "A", I2 = "B", I3 = "A")[d$item]
  d
}

c2_pre10_message <- paste(
  "This congruence fit was made before contentvalidR 1.0. Its `target_ioc`",
  "holds a mean rating, not the index of item-objective congruence, and its",
  "decision used the highest mean. Fit it again with expert_validity() to",
  "get the index and its criterion."
)

# ---- summary(): a congruence fit saved before 1.0 ---------------------------

test_that("summary() refuses a targeted congruence fit saved before 1.0", {
  # The shape 0.10.1 returned: target_ioc, competitor_ioc and margin held
  # mean ratings, and the decision went to the highest mean. I2's two means
  # tie, so it was "Tie / review"; I1 was "Target favored".
  old <- expert_validity(c2_congruence(), mode = "congruence")
  old$results <- data.frame(
    item = c("I1", "I2"), target = c("A", "B"), target_ioc = c(1, 2 / 3),
    strongest_competitor = c("B", "A"), competitor_ioc = c(-1, 2 / 3),
    margin = c(2, 0), recommendation = c("Target favored", "Tie / review"),
    status = c("Supported", "Review"), stringsAsFactors = FALSE
  )
  old$settings$ioc_cut <- NULL
  # No summary is made, so none can count "Target favored" as Congruent
  # or label the stored means as the index.
  expect_error(summary(old), c2_pre10_message, fixed = TRUE)
  from_summary <- tryCatch(summary(old), error = conditionMessage)
  from_report <- tryCatch(content_report(old), error = conditionMessage)
  expect_identical(from_summary, from_report)
  # print() still shows what the fit holds, beside the same message.
  out <- c2_flat(old)
  expect_match(out, c2_pre10_message, fixed = TRUE)
  expect_match(out, "Tie / review", fixed = TRUE)
})

test_that("summary() refuses an untargeted congruence fit saved before 1.0", {
  # Before 1.0 a fit without targets returned ioc()'s item-by-objective
  # cells, whose `ioc` held the mean rating, each "Descriptive only".
  old <- expert_validity(c2_congruence(target = FALSE), mode = "congruence")
  res <- old$details$cells
  res$recommendation <- "Descriptive only"
  res$interpretation <- "Stored by an earlier version."
  old$results <- res
  expect_error(summary(old), c2_pre10_message, fixed = TRUE)
  expect_error(content_report(old), c2_pre10_message, fixed = TRUE)
})

test_that("a current congruence fit still summarizes", {
  fit <- expert_validity(c2_congruence(), mode = "congruence")
  s <- summary(fit)
  expect_s3_class(s, "summary.contentvalid_expert")
  # I1's index of 1 meets .70; I2's .50 and I3's -.50 do not.
  expect_identical(c(s$n_supported, s$n_review), c(1L, 2L))
  expect_identical(s$flagged$item, c("I2", "I3"))
  out <- c2_flat(s)
  expect_match(out, "Congruent: 1 of 3 | Review: 2 of 3", fixed = TRUE)
  expect_match(out, "I3 A Review 4 -.50 .00", fixed = TRUE)
})

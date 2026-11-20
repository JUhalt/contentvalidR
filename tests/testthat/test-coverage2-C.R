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

# ---- print() and summary(): results edited by hand --------------------------

test_that("an item table without the index columns shows the stored numbers", {
  # A current fit whose target_ioc column was removed has neither the
  # index layout nor the best-objective one, so its numeric columns are
  # printed as stored, each with its leading zero.
  fit <- expert_validity(c2_congruence(), mode = "congruence")
  fit$results$target_ioc <- NULL
  # Target means: I1 1 on A, I2 1 on B, I3 0 on A. Competitor means: -1,
  # 0 and 1. Margins: 2, 1 and -1.
  expect_identical(fit$results$target_mean, c(1, 1, 0))
  expect_identical(fit$results$competitor_mean, c(-1, 0, 1))
  out <- c2_flat(fit)
  expect_match(out, paste("Item Target Decision N_judges Target_mean",
                          "Competitor_mean Margin"), fixed = TRUE)
  expect_match(out, "I1 A Congruent 4.00 1.00 -1.00 2.00", fixed = TRUE)
  expect_match(out, "I2 B Review 4.00 1.00 0.00 1.00", fixed = TRUE)
  expect_match(out, "I3 A Review 4.00 0.00 1.00 -1.00", fixed = TRUE)
  # The fit holds target_mean, so it is not taken for one saved before 1.0.
  expect_false(grepl("made before contentvalidR 1.0", out, fixed = TRUE))
  s <- c2_flat(summary(fit))
  expect_match(s, "I2 B Review 4.00 1.00 0.00 1.00", fixed = TRUE)
  expect_match(s, "I3 A Review 4.00 0.00 1.00 -1.00", fixed = TRUE)
  expect_false(grepl("I1 A Congruent", s, fixed = TRUE))
})

test_that("a fit without targets or details prints its item table", {
  fit <- expert_validity(c2_congruence(target = FALSE), mode = "congruence")
  # With its details the item-by-objective table is the result.
  expect_match(c2_flat(fit),
               "Mean: the experts' mean rating on the objective (-1 to 1).",
               fixed = TRUE)
  fit$details <- NULL
  out <- c2_flat(fit)
  # Without them, one row per item: I1 matched A best, (1 - (-1)) / 2 = 1;
  # I2 and I3 matched B, (1 - 0) / 2 = .50.
  expect_match(out, "Item Decision Objectives Best objective Best IOC",
               fixed = TRUE)
  expect_match(out, "I1 Descriptive only 2 A 1.00", fixed = TRUE)
  expect_match(out, "I2 Descriptive only 2 B .50", fixed = TRUE)
  expect_match(out, "I3 Descriptive only 2 B .50", fixed = TRUE)
  expect_match(out, paste("Best IOC: the highest index over the item's",
                          "objectives, described without a decision."),
               fixed = TRUE)
  expect_false(grepl("Mean: the experts' mean rating", out, fixed = TRUE))
})

test_that("a flagged item without a target is footnoted with the index", {
  # Every item of a fit without targets is "Descriptive only", so nothing
  # is flagged until a status is changed by hand.
  fit <- expert_validity(c2_congruence(target = FALSE), mode = "congruence")
  expect_identical(summary(fit)$n_review, 0L)
  fit$results$status[2] <- "Review"
  s <- summary(fit)
  expect_identical(s$flagged$item, "I2")
  out <- c2_flat(s)
  expect_match(out, "Congruent: 0 of 3 | Review: 1 of 3 | Descriptive only: 2",
               fixed = TRUE)
  expect_match(out, "I2 Descriptive only 2 B .50", fixed = TRUE)
  expect_match(out, "IOC = index of item-objective congruence.", fixed = TRUE)
  expect_false(grepl("Best IOC: the highest index", out, fixed = TRUE))
})

test_that("with Aiken's V interval removed the note names I-CVI's alone", {
  rel <- utils::read.csv(system.file("extdata",
                                     "expert_relevance_example.csv",
                                     package = "contentvalidR"))
  fit <- expert_validity(as.matrix(rel[, -1]), mode = "relevance",
                         lo = 1, hi = 4, agreement = "none")
  expect_match(c2_flat(fit), "Each 95% CI follows its estimate", fixed = TRUE)
  fit$results$ci_low <- NULL
  fit$results$ci_high <- NULL
  out <- c2_flat(fit)
  # The one interval column left follows I-CVI.
  expect_match(out, "Item Decision Experts V I-CVI 95% CI Kappa",
               fixed = TRUE)
  expect_match(out, paste("The 95% CI follows I-CVI: the proportion interval",
                          "named below."), fixed = TRUE)
  expect_false(grepl("follows its estimate", out, fixed = TRUE))
  expect_false(grepl("follows Aiken's V", out, fixed = TRUE))
  # The method it names follows.
  expect_match(out, "95% intervals for proportions: Wilson score",
               fixed = TRUE)
})

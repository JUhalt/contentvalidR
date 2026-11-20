# Tests for the last untested branches of the reporting, the data-frame
# export and the name checks, and for the duplicate-name message, grouped by
# the function they exercise.

# Two rounds of eight experts rating three statements.
cov2a_delphi <- function() {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4, 3, 4),
              S2 = c(2, 3, 2, 1, 3, 2, 2, 3),
              S3 = c(4, 3, 4, 4, 4, 2, 4, 3))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 3, 4),
              S2 = c(2, 2, 2, 1, 3, 2, 2, 2),
              S3 = c(4, 4, 4, 4, 4, 3, 4, 4))
  long <- function(m, round) {
    data.frame(expert = paste0("E", seq_len(nrow(m))),
               item = rep(colnames(m), each = nrow(m)), round = round,
               rating = as.vector(m), stringsAsFactors = FALSE)
  }
  rbind(long(r1, 1), long(r2, 2))
}

# Six judges rating ten items; J6 rates nearly every item 3.
cov2a_judges <- function() {
  r <- rbind(c(4, 3, 4, 2, 3, 4, 1, 3, 2, 4), c(4, 3, 3, 2, 3, 4, 2, 3, 1, 4),
             c(3, 3, 4, 2, 4, 4, 1, 3, 2, 3), c(4, 2, 4, 1, 3, 3, 1, 3, 2, 4),
             c(4, 3, 4, 2, 3, 4, 2, 2, 1, 4), c(3, 3, 3, 3, 3, 3, 3, 3, 2, 3))
  dimnames(r) <- list(paste0("J", 1:6), paste0("I", 1:10))
  r
}

# A workflow of a class content_report() has no layout for, built with the
# package's own constructor. It has an item column and a numeric column, so
# an empty table is not for want of columns to show.
cov2a_custom <- function() {
  res <- data.frame(item = c("I1", "I2"), score = c(0.9, 0.4),
                    recommendation = c("Retain", "Review"),
                    stringsAsFactors = FALSE)
  contentvalidR:::.new_contentvalid_workflow(
    "contentvalid_custom", "custom", res, data.frame(), list(), list()
  )
}

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

# .as_df_row(), behind as.data.frame() of a single test -----------------------

test_that("a two-by-two table without dimension names is exported by cell", {
  predicted <- c(TRUE, TRUE, FALSE, FALSE, TRUE)
  actual <- c(TRUE, FALSE, TRUE, FALSE, TRUE)
  sd <- signal_detection(predicted, actual)
  # The table of an edited result whose dimensions have lost their names.
  names(dimnames(sd$confusion)) <- NULL
  out <- as.data.frame(sd)
  # The counts are named by row and column, in the table's column order.
  expect_identical(names(out)[1:4],
                   c("n_confusion_11", "n_confusion_21", "n_confusion_12",
                     "n_confusion_22"))
  expect_identical(unlist(out[1, 1:4], use.names = FALSE),
                   c(sum(predicted & actual), sum(!predicted & actual),
                     sum(predicted & !actual), sum(!predicted & !actual)))
  expect_false(any(grepl("predicted", names(out), fixed = TRUE)))
  expect_identical(out$accuracy, 3 / 5)
})

test_that("a pair of numbers other than the interval keeps its own name", {
  b <- csv_binom_test(7, 10)
  # An edited result carrying a second two-number element.
  b$band <- c(0.2, 0.8)
  out <- as.data.frame(b)
  expect_identical(c(out$band_low, out$band_high), c(0.2, 0.8))
  expect_false("band" %in% names(out))
  # The interval itself is still written as ci_low and ci_high.
  expect_identical(c(out$ci_low, out$ci_high), as.vector(b$conf.int))
  expect_identical(out$ci_sides, "one-sided")
})

# content_report() of a workflow class it has no layout for -------------------

test_that("a workflow class with no report layout keeps only its decisions", {
  tab <- content_report(cov2a_custom(), format = "data.frame")
  expect_identical(names(tab), c("recommendation", "status"))
  expect_identical(tab$recommendation, c("Retain", "Review"))
  expect_identical(tab$status, c("Supported", "Review"))
})

test_that("a workflow class with no report layout gets an empty APA table", {
  fit <- cov2a_custom()
  expect_identical(contentvalidR:::.report_spec(fit), list())
  tab <- content_report(fit)
  expect_s3_class(tab, "contentvalid_report")
  expect_identical(ncol(tab), 0L)
  expect_null(attr(tab, "note"))
  # The note has nothing to say for such a class, also when given headings.
  expect_null(contentvalidR:::.report_note(fit, c("item", "score")))
})

# content_report(): the note under a Delphi table ------------------------------

test_that("a Delphi stability method the report does not know gets no note", {
  fit <- delphi_validity(cov2a_delphi(), lo = 1, hi = 4, B = 0)
  expect_match(attr(content_report(fit), "note"),
               "Kappa = quadratic-weighted kappa between those rounds.",
               fixed = TRUE)
  fit$settings$stability <- "custom"
  note <- attr(content_report(fit), "note")
  expect_match(note, paste("Unchanged = share of experts who kept their",
                           "rating between the item's last two consecutive",
                           "rounds."), fixed = TRUE)
  expect_false(grepl("Kappa =|Lambda =|Net change =|Chi-square =|Stable =",
                     note))
})

test_that("a Delphi fit with no stored alpha reads its stable rule at .05", {
  fit <- delphi_validity(cov2a_delphi(), lo = 1, hi = 4, B = 0,
                         stability = "chisq_individual", alpha = 0.10)
  expect_match(attr(content_report(fit), "note"),
               "Stable = p below alpha = .10: the later ratings depend",
               fixed = TRUE)
  fit$settings$alpha <- NULL
  expect_match(attr(content_report(fit), "note"),
               paste("Stable = p below alpha = .05: the later ratings depend",
                     "on the earlier ones."), fixed = TRUE)
})

test_that("a net-change table without its Stable column states the .15 cut", {
  fit <- delphi_validity(cov2a_delphi(), lo = 1, hi = 4, B = 0,
                         stability = "percent_change")
  full <- attr(content_report(fit), "note")
  expect_match(full, "Stable = net change below .15.", fixed = TRUE)
  expect_false(grepl("read as stable below", full, fixed = TRUE))
  # Results edited to drop the decision column: the cut moves to the
  # statistic's own sentence.
  fit$results$stable <- NULL
  tab <- content_report(fit)
  expect_true("net change" %in% names(tab))
  expect_false("stable" %in% names(tab))
  note <- attr(tab, "note")
  expect_match(note, paste("Net change = net change in the rating",
                           "distribution between those rounds, read as",
                           "stable below .15 (Scheibe et al., 1975/2002)."),
               fixed = TRUE)
  expect_false(grepl("Stable =", note, fixed = TRUE))
})

# content_report(): the flag rules under a judge or domain table ---------------

test_that("a judge fit without its severity cut states no flag rule", {
  fit <- judge_validity(cov2a_judges())
  expect_identical(fit$results$recommendation[6], "Low differentiation")
  rule <- "Low differentiation = scale use below 0.50."
  expect_match(attr(content_report(fit), "note"), rule, fixed = TRUE)
  fit$settings$severity_cut <- NULL
  note <- attr(content_report(fit), "note")
  expect_false(grepl(rule, note, fixed = TRUE))
  expect_false(grepl("convention", note, fixed = TRUE))
  # The column notes are still given.
  expect_match(note, "Ratings = items the judge rated.", fixed = TRUE)
})

test_that("a domain fit without its minimum item count states no rule", {
  asg <- data.frame(item = paste0("I", 1:8),
                    cell = c(rep("Autonomy", 5), "Competence", "Competence",
                             "Relatedness"))
  fit <- domain_validity(asg, targets = c(Autonomy = 2, Competence = 3,
                                          Relatedness = 3))
  expect_identical(fit$results$recommendation,
                   c("Over-represented", "Covered", "Thinly covered"))
  expect_match(attr(content_report(fit), "note"),
               "These criteria are contentvalidR conventions", fixed = TRUE)
  fit$settings$min_items <- NULL
  note <- attr(content_report(fit), "note")
  expect_identical(note, paste("Share = percentage of all items in the cell.",
                               "Expected = the cell's share of the targets in",
                               "the blueprint."))
})

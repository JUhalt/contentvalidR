# Tests for branches that covr 4.0.0 found no test running. Since 4.0.0 a
# braceless if/else inside an expression counts as a line of its own, so
# each test here reaches an arm the rest of the suite left unrun: the
# tables as.data.frame() returns, what content_handoff() records and
# prints, and the earlier methods that print() sets beside a decision.

# Everything print() writes, as one line with single spaces.
flat_print <- function(x, ...) {
  gsub("[[:space:]]+", " ",
       paste(utils::capture.output(print(x, ...)), collapse = " "))
}

# Mean similarity ratings for nine items written for three blueprint cells,
# from the example in ?content_structure.
structure_example <- function() {
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
blueprint_cells <- c("Autonomy", "Competence", "Relatedness")

# Two items sorted by ten judges: A1 goes to its target 9 times in 10, B1 7.
two_item_sort <- function() {
  data.frame(
    item = rep(c("A1", "B1"), each = 10), rater = rep(1:10, 2),
    assigned_construct = c(rep("A", 9), "B", rep("B", 7), rep("A", 3)),
    target_construct = rep(c("A", "B"), each = 10), stringsAsFactors = FALSE
  )
}

# The shape of a workflow object saved before 0.0.6: no `workflow` or
# `details`, no `status` column, and only the subclass, as the objects in
# test-api-v006.R are built.
saved_before_006 <- function(fit) {
  cls <- class(fit)[1]
  fit$workflow <- NULL
  fit$details <- NULL
  fit$results$status <- NULL
  class(fit) <- cls
  fit
}

# Delphi ratings in long form, one row per expert, item and round.
long_ratings <- function(m, round) {
  data.frame(expert = paste0("E", seq_len(nrow(m))),
             item = rep(colnames(m), each = nrow(m)), round = round,
             rating = as.vector(m), stringsAsFactors = FALSE)
}

# ---- as.data.frame() --------------------------------------------------------

test_that("a structure's cross-tabulation comes back with one row per cell", {
  x <- content_structure(structure_example(),
                         membership = rep(blueprint_cells, each = 3))
  # Each cell's three items form one cluster of their own.
  expect_identical(x$clusters$cluster, rep(1:3, each = 3))
  out <- as.data.frame(x, component = "cross_tab")
  expect_s3_class(out, "data.frame")
  expect_identical(names(out), c("blueprint", "cluster", "n_items"))
  expect_identical(as.character(out$blueprint), rep(blueprint_cells, 3))
  expect_identical(as.character(out$cluster), rep(c("1", "2", "3"), each = 3))
  expect_identical(out$n_items, c(3L, 0L, 0L, 0L, 3L, 0L, 0L, 0L, 3L))
})

test_that("asking for the cross-tabulation without a blueprint is refused", {
  x <- content_structure(structure_example(), k = 3)
  expect_null(x$cross_tab)
  expect_error(as.data.frame(x, component = "cross_tab"),
               "no `cross_tab` table: no blueprint was given", fixed = TRUE)
})

test_that("a structure's fit table holds the stress the result reports", {
  x <- content_structure(structure_example(),
                         membership = rep(blueprint_cells, each = 3))
  out <- as.data.frame(x, component = "fit")
  expect_s3_class(out, "data.frame")
  expect_identical(names(out), c("dims", "stress", "gof"))
  expect_identical(rownames(out), as.character(seq_len(nrow(out))))
  # The retained two dimensions are the row behind the headline numbers.
  expect_equal(out$stress[out$dims == 2L], x$stress)
  expect_equal(out$gof[out$dims == 2L], x$gof)
})

test_that("a handoff saved before panel statistics existed says it has none", {
  # contentvalidR 0.4.0 wrote no `panel_statistics`; it arrived in 0.5.0.
  fit <- sort_validity(two_item_sort())
  old <- content_handoff(fit)
  old$panel_statistics <- NULL
  expect_error(as.data.frame(old, component = "panel_statistics"),
               "This result has no `panel_statistics` table.", fixed = TRUE)
  # The tables it does have still come back.
  expect_identical(as.data.frame(old)$item, c("A1", "B1"))
})

# ---- content_handoff() ------------------------------------------------------

test_that("an agreement interval too few resamples support says so", {
  rel <- read.csv(system.file("extdata", "expert_relevance_example.csv",
                              package = "contentvalidR"))
  rel$expert <- NULL
  # One resample is fewer than the two a percentile interval needs.
  fit <- expert_validity(rel, mode = "relevance", lo = 1, hi = 4,
                         agreement_B = 1, seed = 1)
  ag <- fit$details$agreement
  expect_identical(ag$n_boot_usable, 1L)
  ps <- content_handoff(fit)$panel_statistics
  expect_identical(nrow(ps), 1L)
  expect_equal(ps$value, panel_agreement(rel, B = 0)$estimate)
  expect_identical(
    ps$note,
    paste("The bootstrap interval could not be computed: too few resamples",
          "produced a usable coefficient.")
  )
  # The four interval columns are missing together, as the schema says.
  expect_true(all(is.na(c(ps$lower, ps$upper, ps$interval_level))))
  expect_true(is.na(ps$interval_method))
})

test_that("a Delphi rule at the top of the scale does not say 'or higher'", {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4, 3, 4), S2 = c(2, 3, 2, 1, 3, 2, 2, 3),
              S3 = c(4, 3, 4, 4, 4, 2, 4, 3))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2, 2, 2),
              S3 = c(4, 4, 4, 4, 4, 3, 4, 4))
  d <- rbind(long_ratings(r1, 1), long_ratings(r2, 2))
  top <- delphi_validity(d, lo = 1, hi = 4, agree_cut = 4,
                         consensus_threshold = .75, B = 0)
  rule <- content_handoff(top)$item_evidence$rule
  expect_length(rule, 3L)
  expect_true(all(grepl(
    "at least 75% of experts rated the item 4 on the 1 to 4 scale",
    rule, fixed = TRUE)))
  expect_false(any(grepl("or higher", rule, fixed = TRUE)))
  # Below the top of the scale the rule does say it.
  lower <- delphi_validity(d, lo = 1, hi = 4, agree_cut = 3,
                           consensus_threshold = .75, B = 0)
  expect_true(all(grepl("rated the item 3 or higher on the 1 to 4 scale",
                        content_handoff(lower)$item_evidence$rule,
                        fixed = TRUE)))
})

test_that("a keep that is not text is refused with only the valid statuses", {
  fit <- sort_validity(two_item_sort())
  valid <- paste0("must be one or more of \"Supported\", \"Review\", ",
                  "\"Insufficient data\", \"Descriptive only\"\\.$")
  # The message ends at the list: there are no wrong names to quote back.
  expect_error(content_handoff(fit, keep = 1), valid)
  expect_error(content_handoff(fit, keep = TRUE), valid)
})

test_that("several items with no decision rule are named together", {
  cong <- read.csv(system.file("extdata", "expert_congruence_example.csv",
                               package = "contentvalidR"),
                   stringsAsFactors = FALSE)
  # I8 and I9 are rated against their target objective only, so the index,
  # which compares objectives, cannot decide them.
  extra <- rbind(
    data.frame(item = "I8", judge = 1:6, objective = "A",
               target_objective = "A", score = 1),
    data.frame(item = "I9", judge = 1:6, objective = "B",
               target_objective = "B", score = 1)
  )
  fit <- expert_validity(rbind(cong, extra), mode = "congruence")
  h <- content_handoff(fit)
  ev <- h$item_evidence
  expect_identical(ev$status[ev$item %in% c("I8", "I9")],
                   rep("Descriptive only", 2))
  expect_false(any(ev$carried[ev$item %in% c("I8", "I9")]))
  out <- flat_print(h)
  expect_match(out, paste("No decision rule was applied to I8, I9, so they",
                          "are Descriptive only and not carried."),
               fixed = TRUE)
  expect_match(out, "keep = c(\"Supported\", \"Descriptive only\")",
               fixed = TRUE)
})

test_that("a sort object saved before 0.0.6 hands off with no panel table", {
  fit <- sort_validity(two_item_sort())
  h <- content_handoff(saved_before_006(fit))
  # 9 of 10 meets the exact test at alpha = .05 (P = 11/1024); 7 of 10 does
  # not, since 9 is the fewest that does (8 of 10 gives P = 56/1024).
  expect_identical(h$items, "A1")
  expect_identical(h$provenance$workflow, "item-sort")
  expect_identical(nrow(h$panel_statistics), 0L)
  expect_identical(
    names(h$panel_statistics),
    names(contentvalidR:::.handoff_schema()$panel_statistics)
  )
})

test_that("a rating object saved before 0.0.6 still explains a held item", {
  # Every judge rates the intended construct and B the same, so that
  # contrast has no p; the omnibus test is significant.
  d <- data.frame(
    item = "q1", rater = rep(paste0("J", 1:6), 3),
    construct = rep(c("A", "B", "C"), each = 6),
    rating = c(5, 4, 4, 5, 4, 5,
               5, 4, 4, 5, 4, 5,
               1, 2, 1, 1, 2, 1),
    target_construct = "A", stringsAsFactors = FALSE
  )
  fit <- rating_validity(d)
  expect_lte(fit$results$p_value, .05)
  expect_identical(fit$results$recommendation, "Review")
  # Without `details` the contrasts are gone, so the tied construct cannot
  # be named; the note still says why the item was held back.
  st <- content_handoff(saved_before_006(fit))$item_statistics
  expect_identical(
    st$note[st$statistic == "p_value"],
    paste0("This omnibus p meets alpha, but the rule also needs every ",
           "planned contrast to pass, and not every one did.")
  )
})

# ---- print(): earlier methods -----------------------------------------------

test_that("a sort object saved before 0.0.6 prints without earlier methods", {
  fit <- sort_validity(two_item_sort(), legacy = TRUE)
  expect_match(flat_print(fit), "Earlier methods, for comparison",
               fixed = TRUE)
  old <- saved_before_006(fit)
  out <- flat_print(old)
  # The choice to show the block was kept in `details`, so it is not shown.
  expect_false(grepl("Earlier methods", out, fixed = TRUE))
  expect_match(out, "1 of 2 items meets the exact target-assignment criterion",
               fixed = TRUE)
  utils::capture.output(expect_invisible(print(old)))
})

test_that("items just short of a computed cutoff are named together", {
  # Wilson et al.'s minimum for six panelists is z(.95) / sqrt(6) = .6715,
  # which prints as .67, as does 5 of 6 (CVR .6667).
  fit <- expert_validity(c(5, 5), mode = "essentiality", N = 6,
                         legacy = TRUE)
  it <- fit$details$earlier_methods$items
  expect_equal(it$wilson_critical, rep(stats::qnorm(.95) / sqrt(6), 2))
  expect_equal(it$cvr, rep(4 / 6, 2))
  expect_identical(it$wilson_meets, c(FALSE, FALSE))
  # A computed cutoff is shown to three decimals, so the sentence does not
  # appear to contradict itself.
  expect_match(flat_print(fit),
               paste("Item1 (.667), Item2 (.667) print at the Wilson et al.",
                     "criterion of .672 but fall short of it before",
                     "rounding."),
               fixed = TRUE)
})

test_that("a panel size Lawshe's table does not list has no minimum", {
  fit <- expert_validity(c(16, 12), mode = "essentiality", N = 16,
                         legacy = TRUE)
  expect_true(all(is.na(fit$details$earlier_methods$items$lawshe_minimum)))
  out <- flat_print(fit)
  expect_match(out, paste("Lawshe (1975, Table 1) lists no minimum for 16",
                          "panelists; the table covers 5 to 15, then every",
                          "fifth size to 40."),
               fixed = TRUE)
  expect_false(grepl("minimum CVR NA", out, fixed = TRUE))
})

test_that("Lawshe's index is called undefined when no item meets him", {
  # For ten panelists Lawshe's .62 needs 9 essential ratings; these have 6
  # and 5.
  fit <- expert_validity(c(6, 5), mode = "essentiality", N = 10,
                         legacy = TRUE)
  em <- fit$details$earlier_methods
  expect_identical(em$items$lawshe_meets, c(FALSE, FALSE))
  expect_identical(em$lawshe_n_retained, 0L)
  expect_identical(em$lawshe_cvi, NA_real_)
  expect_match(flat_print(fit),
               paste("Lawshe's content validity index is not defined here:",
                     "no item met his minimum."),
               fixed = TRUE)
})

test_that("Fleiss' kappa is withheld when an expert skipped an item", {
  R <- cbind(I1 = c(4, 4, 3, NA), I2 = c(4, 3, 4, 4), I3 = c(2, 4, 3, 4))
  fit <- expert_validity(R, mode = "relevance", lo = 1, hi = 4, na.rm = TRUE,
                         agreement = "none", legacy = TRUE)
  em <- fit$details$earlier_methods
  expect_false(em$complete)
  expect_identical(em$fleiss_kappa, NA_real_)
  expect_match(flat_print(fit),
               paste("kappa on the relevant/not-relevant decision: not",
                     "computed, because it needs every expert to rate every",
                     "item."),
               fixed = TRUE)
})

test_that("with judges skipping items the Ccv's chance terms are ranges", {
  R <- cbind(I1 = c(4, 4, 3, NA), I2 = c(4, 3, 4, 4), I3 = c(2, 4, 3, 4))
  fit <- expert_validity(R, mode = "relevance", lo = 1, hi = 4, na.rm = TRUE,
                         agreement = "none", legacy = TRUE)
  cc <- fit$details$earlier_methods$ccv
  # (1/J)^J for three judges on I1 and four on the others.
  expect_equal(cc$pe, c((1 / 3)^3, (1 / 4)^4, (1 / 4)^4))
  out <- flat_print(fit)
  # .037 and .0039, to two significant digits, largest first.
  expect_match(out, "number of scale points, and is .037 to .0039 here.",
               fixed = TRUE)
  # The floor 1/4 less each term: .2130 and .2461.
  expect_match(out, "not below that less (1/J)^J (.21 to .25 here)",
               fixed = TRUE)
})

test_that("Fleiss' kappa is called undefined when every decision agrees", {
  R <- cbind(I1 = c(4, 4, 3, 4), I2 = c(3, 3, 4, 4), I3 = c(4, 3, 3, 4))
  fit <- expert_validity(R, mode = "relevance", lo = 0, hi = 4,
                         agreement = "none", legacy = TRUE)
  em <- fit$details$earlier_methods
  # Every rating is relevant, so chance agreement is 1 and kappa is 0/0.
  expect_true(em$complete)
  expect_identical(em$fleiss_kappa, NA_real_)
  expect_match(flat_print(fit),
               paste("kappa on the relevant/not-relevant decision:",
                     "undefined, because every decision was the same."),
               fixed = TRUE)
})

test_that("on a scale starting at 0 the Ccv before correction is Aiken's V", {
  R <- cbind(I1 = c(4, 4, 3, 4), I2 = c(3, 3, 4, 4), I3 = c(4, 3, 3, 4))
  fit <- expert_validity(R, mode = "relevance", lo = 0, hi = 4,
                         agreement = "none", legacy = TRUE)
  cc <- fit$details$earlier_methods$ccv
  # Both are the mean rating over the maximum when the scale starts at 0.
  expect_equal(cc$ccv, unname(colMeans(R)) / 4)
  expect_equal(fit$results$V, unname(colMeans(R)) / 4)
  expect_match(flat_print(fit),
               paste("On a scale starting at 0, as here, Ccv before the",
                     "correction is Aiken's V."),
               fixed = TRUE)
})

test_that("the Ccv is not shown for a scale that starts below 0", {
  R <- cbind(I1 = c(2, 1, 2, 2), I2 = c(1, 2, -1, 0), I3 = c(1, 2, 2, 2))
  fit <- expert_validity(R, mode = "relevance", lo = -2, hi = 2,
                         agreement = "none", legacy = TRUE)
  expect_true(all(is.na(fit$details$earlier_methods$ccv$ccv)))
  out <- flat_print(fit)
  expect_match(out, paste("needs a rating scale that starts at 0 or above;",
                          "this one starts at -2, so it is not shown."),
               fixed = TRUE)
  expect_false(grepl("Total Ccv", out, fixed = TRUE))
})

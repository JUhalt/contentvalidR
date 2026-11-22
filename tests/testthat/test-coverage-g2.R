# Tests for branches that covr 4.0.0 found no test running: refusals of
# malformed input, printouts and figures for less common panels, fits saved
# by earlier versions, and the helpers behind the expert-panel printout.
# Grouped by the function they exercise.

# The printed output on an 80-column console, with runs of white space
# collapsed so a sentence can be matched however it was wrapped.
printed_flat <- function(x, ...) {
  old <- options(width = 80)
  on.exit(options(old), add = TRUE)
  out <- utils::capture.output(print(x, ...))
  gsub("[[:space:]]+", " ", paste(out, collapse = "\n"))
}

# Every string a figure draws with text() or mtext(), legends included, as in
# test-closeout3.R.
figure_text <- function(expr) {
  sink <- new.env()
  sink$text <- character(0)
  grab <- function(x) sink$text <- c(sink$text, as.character(x))
  grab_chars <- function(...) {
    for (a in list(...)) if (is.character(a)) grab(a)
  }
  suppressMessages({
    trace("mtext", bquote(.(grab)(text)), print = FALSE, where = graphics::plot)
    trace("text", bquote(.(grab_chars)(...)), print = FALSE,
          where = graphics::plot)
  })
  on.exit(suppressMessages({
    untrace("mtext", where = graphics::plot)
    untrace("text", where = graphics::plot)
  }), add = TRUE)
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  force(expr)
  sink$text
}

# The key a figure lays out: the labels, symbols, line types and colors it
# hands to .legend_fit(), which then lays them out and draws them as usual.
record_key <- function(env = parent.frame()) {
  seen <- new.env()
  real <- contentvalidR:::.legend_fit
  testthat::local_mocked_bindings(
    .legend_fit = function(legend, pch = NA, lty = NA, col = "black", ...) {
      seen$legend <- legend
      seen$pch <- pch
      seen$lty <- lty
      seen$col <- col
      real(legend, pch, lty, col, ...)
    },
    .package = "contentvalidR", .env = env
  )
  seen
}

# Long congruence ratings for one item on one objective, one judge a score.
congruence_long <- function(item, objective, score, target = NULL) {
  d <- data.frame(item = item, judge = seq_along(score), objective = objective,
                  score = score, stringsAsFactors = FALSE)
  if (!is.null(target)) d$target_objective <- target
  d
}

# The relevance example shipped with the package: eight experts, five items,
# rated 1 to 4, without the expert column.
relevance_example <- function() {
  rel <- utils::read.csv(system.file("extdata", "expert_relevance_example.csv",
                                     package = "contentvalidR"))
  as.matrix(rel[, -1])
}

# ---- cvr() -------------------------------------------------------------------

test_that("a judge-by-item table of text is refused", {
  m <- matrix(c("1", "0", "1", "1"), 2, dimnames = list(NULL, c("A", "B")))
  expect_error(cvr(m), "`essential` must contain numeric or logical 0/1 values",
               fixed = TRUE)
  # A data frame with one text column becomes a text matrix too.
  df <- data.frame(A = c(1, 0), B = c("1", "1"))
  expect_error(cvr(df), "`essential` must contain numeric or logical 0/1 values",
               fixed = TRUE)
})

test_that("a judge-by-item table with a rating other than 0 or 1 is refused", {
  m <- matrix(c(1, 0, 2, 1), 2, dimnames = list(NULL, c("A", "B")))
  expect_error(cvr(m), "`essential` must contain only 0/1 values",
               fixed = TRUE)
})

test_that("a judge-by-item table without judges or items is refused", {
  no_judges <- matrix(numeric(0), nrow = 0, ncol = 2,
                      dimnames = list(NULL, c("A", "B")))
  no_items <- matrix(numeric(0), nrow = 3, ncol = 0)
  msg <- "`essential` must contain at least one judge and one item."
  expect_error(cvr(no_judges), msg, fixed = TRUE)
  expect_error(cvr(no_items), msg, fixed = TRUE)
})

test_that("an unnamed judge-by-item table numbers its items", {
  # Five judges; the items are rated essential by 5, 4, and 1 of them.
  m <- matrix(c(1, 1, 1, 1, 1,
                1, 1, 1, 1, 0,
                1, 0, 0, 0, 0), nrow = 5)
  out <- cvr(m)
  expect_identical(out$item, c("Item1", "Item2", "Item3"))
  expect_identical(out$ne, c(5L, 4L, 1L))
  expect_identical(out$N, c(5L, 5L, 5L))
  # Lawshe's CVR, (ne - N/2) / (N/2), with N/2 = 2.5.
  expect_equal(out$cvr, c(2.5, 1.5, -1.5) / 2.5)
})

test_that("missing, infinite, or absent essential counts are refused", {
  msg <- "`essential` must contain finite counts."
  expect_error(cvr(c(3, NA), N = 5), msg, fixed = TRUE)
  expect_error(cvr(c(3, Inf), N = 5), msg, fixed = TRUE)
  expect_error(cvr(numeric(0), N = 5), msg, fixed = TRUE)
})

test_that("panel sizes matching neither one item nor all are refused", {
  expect_error(cvr(c(3, 4, 5), N = c(6, 6)),
               "`N` must be scalar or have the same length as `essential`.",
               fixed = TRUE)
})

test_that("item names that do not match the number of counts are refused", {
  expect_error(cvr(c(3, 4), N = 6, item_names = c("A", "B", "C")),
               "`item_names` must match the number of items.", fixed = TRUE)
})

# ---- cvi() -------------------------------------------------------------------

test_that("a relevance table of text is refused", {
  m <- matrix(c("1", "0", "1", "1"), 2, dimnames = list(NULL, c("A", "B")))
  expect_error(cvi(m), "`binary` must contain numeric/logical 0/1 values.",
               fixed = TRUE)
})

test_that("the CVI printout gives the expert range when some skipped items", {
  # The relevance example, relevant at 3 or 4, with one rating of Item2 and
  # two of Item5 left out.
  b <- (relevance_example() >= 3) * 1
  b[1, "Item2"] <- NA
  b[2:3, "Item5"] <- NA
  fit <- cvi(b, na.rm = TRUE)
  expect_identical(fit$item_level$N, as.integer(colSums(!is.na(b))))
  expect_identical(fit$item_level$N, c(8L, 7L, 8L, 8L, 6L))
  expect_match(printed_flat(fit),
               "Experts per item: 6 to 8 (itemwise missingness)", fixed = TRUE)
})

# ---- ioc() -------------------------------------------------------------------

test_that("ratings without the four long-format columns are refused", {
  msg <- paste("`ratings` must be a data.frame with item, judge, objective,",
               "and score columns.")
  expect_error(ioc(data.frame(item = "I1", judge = 1, score = 1)), msg,
               fixed = TRUE)
  expect_error(ioc(matrix(1, 2, 4)), msg, fixed = TRUE)
})

test_that("ratings with no rows are refused", {
  empty <- data.frame(item = character(0), judge = character(0),
                      objective = character(0), score = numeric(0))
  expect_error(ioc(empty), "`ratings` contains no rows.", fixed = TRUE)
})

test_that("congruence scores stored as text are refused", {
  d <- congruence_long("I1", "A", c("1", "0"))
  expect_error(ioc(d), "`score` must be numeric.", fixed = TRUE)
})

# ---- reproducibility_phi() ---------------------------------------------------

test_that("retention decisions coded as numbers are refused", {
  expect_error(reproducibility_phi(c(1, 0, 1), c(TRUE, FALSE, TRUE)),
               "`sig1` and `sig2` must be logical vectors.", fixed = TRUE)
})

test_that("a missing retention decision is refused", {
  expect_error(reproducibility_phi(c(TRUE, NA, FALSE), c(TRUE, TRUE, FALSE)),
               "Missing values are not supported in `sig1` or `sig2`.",
               fixed = TRUE)
})

# ---- expert_power() ----------------------------------------------------------

test_that("a panel too small for the exact CVR test prints as needing none", {
  p <- expert_power(n_experts = c(4, 6), prob = 0.9, criterion = "cvr")
  r <- p$results
  # Four of four gives p = 1/16 = .0625 > .05, so no count can pass; with six
  # experts five gives 7/64 = .109 and six gives 1/64 = .016.
  expect_gt(stats::pbinom(3, 4, 0.5, lower.tail = FALSE), 0.05)
  expect_gt(stats::pbinom(4, 6, 0.5, lower.tail = FALSE), 0.05)
  expect_lte(stats::pbinom(5, 6, 0.5, lower.tail = FALSE), 0.05)
  expect_identical(r$required_endorsements, c(NA, 6L))
  expect_equal(r$power, c(0, 0.9^6))
  out <- printed_flat(p)
  expect_match(out, "4 none .00", fixed = TRUE)
  expect_match(out, "6 6/6 .53", fixed = TRUE)
  expect_match(out, "(none: no count reaches the criterion at this size)",
               fixed = TRUE)
})

test_that("the CVR planner gives an empty panel no required count, as cvr()", {
  # expert_power() calls .cvr_required_count() only for panels of at least
  # one expert, so its guard for an empty panel is reached only directly.
  expect_identical(contentvalidR:::.cvr_required_count(c(0L, 5L), 0.05),
                   c(NA_integer_, 5L))
  expect_identical(cvr(essential = 0, N = 0)$critical_ne, NA_integer_)
})

# ---- expert_validity(): congruence -------------------------------------------

test_that("congruence mode refuses ratings that are not a long data frame", {
  expect_error(expert_validity(matrix(c(1, 0, -1, 1), 2), mode = "congruence"),
               "Congruence mode requires a long data.frame.", fixed = TRUE)
})

test_that("an item whose target objective no expert rated has no decision", {
  d <- rbind(congruence_long("I1", "A", c(NA, NA, NA), "A"),
             congruence_long("I1", "B", c(1, 1, 0), "A"))
  fit <- expert_validity(d, mode = "congruence", na.rm = TRUE)
  r <- fit$results
  expect_identical(r$recommendation, "Insufficient data")
  expect_identical(r$status, "Insufficient data")
  expect_identical(r$n_judges, 0L)
  expect_true(is.na(r$target_mean))
  expect_identical(r$interpretation,
                   "The intended objective lacks usable expert ratings.")
  expect_match(printed_flat(fit), "Insufficient data: I1", fixed = TRUE)
})

test_that("an item below the criterion, unclear on its target, says so", {
  # Target rated 0 by every expert, the only other objective -1: the index is
  # (0 - (-1)) / 2 = .50, below .70, though the target leads by 1.
  d <- rbind(congruence_long("I1", "A", c(0, 0, 0), "A"),
             congruence_long("I1", "B", c(-1, -1, -1), "A"))
  r <- expert_validity(d, mode = "congruence")$results
  expect_equal(r$target_ioc, 0.5)
  expect_equal(r$margin, 1)
  expect_identical(r$recommendation, "Review")
  expect_match(r$interpretation,
               paste("is below .70: the experts did not, on balance, match",
                     "the item to its intended objective."), fixed = TRUE)
})

test_that("a congruent item says when a rival was rated as high or higher", {
  # Five objectives. Every expert gives the rival B +1 and C, D, E -1, so the
  # other objectives average (1 - 3) / 4 = -.50. I1's target mean is 1 (index
  # .75, margin 0); I2's is 2/3 (index 7/12, margin -1/3).
  others <- function(item) {
    rbind(congruence_long(item, "B", c(1, 1, 1), "A"),
          congruence_long(item, "C", c(-1, -1, -1), "A"),
          congruence_long(item, "D", c(-1, -1, -1), "A"),
          congruence_long(item, "E", c(-1, -1, -1), "A"))
  }
  d <- rbind(congruence_long("I1", "A", c(1, 1, 1), "A"), others("I1"),
             congruence_long("I2", "A", c(1, 1, 0), "A"), others("I2"))
  r <- expert_validity(d, mode = "congruence", ioc_cut = 0.5)$results
  expect_equal(r$target_ioc, c((1 + 0.5) / 2, (2 / 3 + 0.5) / 2))
  expect_equal(r$margin, c(0, -1 / 3))
  expect_identical(r$recommendation, c("Congruent", "Congruent"))
  expect_match(r$interpretation[1],
               "but the experts rated B as high as the intended objective.",
               fixed = TRUE)
  expect_match(r$interpretation[2],
               "but the experts rated B higher than the intended objective.",
               fixed = TRUE)
  expect_match(r$interpretation, "at or above .50, because it averages over",
               fixed = TRUE)
})

# ---- expert_validity(): figures ----------------------------------------------

test_that("the essentiality figure keys a panel too small to test", {
  # Four of four cannot reach .05; eleven of twelve passes (ten are needed).
  fit <- expert_validity(c(4, 11), mode = "essentiality", N = c(4, 12))
  expect_identical(fit$results$recommendation,
                   c("Insufficient panel", "Supported"))
  key <- record_key()
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_invisible(plot(fit))
  expect_identical(key$legend, c("Observed CVR", "Needed (exact test)",
                                 "Too few experts to test"))
  # Filled observed CVR, open needed CVR, and a cross for no decision.
  expect_identical(key$pch, c(19, 1, 4))
})

test_that("the congruence figure keys an item with no index as a black cross", {
  # I1 is matched to its target and not to B; I2 was rated on its target
  # alone, so it has a mean but no index.
  d <- rbind(congruence_long("I1", "A", rep(1, 4), "A"),
             congruence_long("I1", "B", rep(-1, 4), "A"),
             congruence_long("I2", "B", rep(1, 4), "B"))
  fit <- expert_validity(d, mode = "congruence")
  expect_identical(fit$results$recommendation,
                   c("Congruent", "Target described"))
  key <- record_key()
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_identical(plot(fit), fit)
  expect_identical(key$legend, c("IOC: meets criterion", "Mean: target",
                                 "Mean: competitor", "No index",
                                 "Criterion (.70)"))
  # Filled index, triangles up and down for the means in gray, a cross for
  # no index, and the dashed criterion line.
  expect_identical(key$pch, c(19, 2, 6, 4, NA))
  expect_identical(key$lty, c(NA, NA, NA, NA, 2))
  expect_identical(key$col, c("black", "grey40", "grey40", "black", "black"))
})

test_that("the relevance key drops the count when panel sizes differ", {
  # Five experts, one of whom skipped the second item: five and four
  # experts both need every expert to agree, so one line serves both.
  m <- matrix(c(4, 4, 4, 4, 4,
                4, 4, 3, 4, NA), nrow = 5,
              dimnames = list(NULL, c("Clear", "Brief")))
  fit <- expert_validity(m, mode = "relevance", na.rm = TRUE,
                         agreement = "none")
  expect_identical(fit$results$N, c(5L, 4L))
  expect_equal(fit$results$cvi_criterion, c(1, 1))
  key <- record_key()
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_invisible(plot(fit))
  expect_identical(key$legend,
                   c("Aiken's V", "I-CVI", "95% CI", "I-CVI criterion"))
  # With every expert rating every item, the count is named.
  full <- expert_validity(m[, "Clear", drop = FALSE], mode = "relevance",
                          agreement = "none")
  plot(full)
  expect_identical(key$legend[4], "I-CVI criterion (5 of 5)")
})

test_that("the distribution view has no criterion when sizes need two", {
  # The relevance example with one rating of Item2 left out: eight experts
  # need 7 of 8 and seven need 6 of 7, so no single line can be drawn.
  ratings <- relevance_example()
  ratings[1, "Item2"] <- NA
  fit <- expert_validity(ratings, mode = "relevance", na.rm = TRUE,
                         agreement = "none")
  expect_equal(unique(fit$results$cvi_criterion), c(7 / 8, 6 / 7))
  drawn <- figure_text(plot(fit, type = "distribution"))
  expect_true("Met the criterion" %in% drawn)
  expect_false("Criterion" %in% drawn)
  # The complete example has one criterion, which the key names.
  complete <- expert_validity(relevance_example(), mode = "relevance",
                              agreement = "none")
  expect_true("Criterion" %in% figure_text(plot(complete,
                                                type = "distribution")))
})

# ---- expert_validity(): fits saved by earlier versions -----------------------

test_that("an essentiality fit saved before v0.0.6 prints and summarizes", {
  # The shape expert_validity() returned for essentiality before v0.0.6: no
  # workflow, design, scale_summary, or status, and `details` NULL.
  res <- as.data.frame(cvr(c(12, 10, 8, 6), N = 12))
  res$recommendation <- ifelse(res$pass, "Supported", "Review")
  res$interpretation <- "Stored by an earlier version."
  old <- list(mode = "essentiality", results = res,
              scale = data.frame(n_items = 4L, n_supported = sum(res$pass),
                                 n_review = sum(!res$pass)),
              settings = list(alpha = 0.05, na.rm = FALSE,
                              method = paste("Lawshe CVR with exact binomial",
                                             "critical values")),
              details = NULL)
  class(old) <- "contentvalid_expert"
  # Ten of twelve is the exact critical count at .05 (Ayre & Scally, 2014).
  expect_identical(res$critical_ne, rep(10L, 4))

  out <- printed_flat(old, legacy = TRUE)
  expect_match(out, "2 of 4 items meet the exact essentiality criterion.",
               fixed = TRUE)
  expect_match(out, "Flagged for review: Item3, Item4", fixed = TRUE)
  # No earlier methods were stored, so none can be shown; a current fit
  # shows them when asked.
  expect_false(grepl("Earlier methods", out, fixed = TRUE))
  current <- expert_validity(c(12, 10, 8, 6), mode = "essentiality", N = 12)
  expect_match(printed_flat(current, legacy = TRUE), "Earlier methods",
               fixed = TRUE)

  s <- summary(old)
  expect_s3_class(s, "summary.contentvalid_expert")
  expect_identical(c(s$n_supported, s$n_review), c(2L, 2L))
  expect_identical(s$flagged$item, c("Item3", "Item4"))
  # With no details there is no panel agreement to carry; a current
  # relevance fit's summary carries the one it stored.
  expect_null(s$agreement)
  rel <- expert_validity(relevance_example(), mode = "relevance",
                         agreement_B = 0)
  expect_s3_class(rel$details$agreement, "contentvalid_agreement")
  expect_identical(summary(rel)$agreement, rel$details$agreement)
})

# ---- helpers behind the expert-panel printout --------------------------------

test_that("without targets, the item table shows each item's best objective", {
  # print() uses .expert_item_table() and .congruence_column_note(), but for
  # a fit without targets it prints the item-by-objective table in
  # details$cells, so this layout and its note are reached only directly.
  d <- rbind(congruence_long("I1", "A", c(1, 1, 1)),
             congruence_long("I1", "B", c(-1, -1, -1)),
             congruence_long("I2", "A", c(0, 0, 0)),
             congruence_long("I2", "B", c(1, 1, 1)))
  fit <- expert_validity(d, mode = "congruence")
  # I1: (1 - (-1)) / 2 = 1 for A. I2: (1 - 0) / 2 = .50 for B.
  expect_identical(fit$results$best_objective, c("A", "B"))
  tab <- contentvalidR:::.expert_item_table(fit$results, "congruence", 2, 0.05)
  expect_identical(names(tab), c("item", "decision", "objectives",
                                 "best objective", "best IOC"))
  expect_identical(tab$`best objective`, c("A", "B"))
  expect_identical(tab$`best IOC`, c("1.00", ".50"))
  expect_identical(tab$objectives, c(2L, 2L))
  expect_identical(
    contentvalidR:::.congruence_column_note(names(tab)),
    paste("Best IOC: the highest index over the item's objectives,",
          "described without a decision.")
  )
})

test_that("no scale line is made for a fit that does not record one", {
  # print() and summary() of a relevance fit use .relevance_scale_line();
  # every fit this version makes records the scale, so the NULL is reached
  # only directly.
  expect_null(contentvalidR:::.relevance_scale_line(list(lo = 1, hi = 4)))
  expect_identical(
    contentvalidR:::.relevance_scale_line(list(lo = 1, hi = 4,
                                               relevance_cut = 3)),
    "Scale: 1 to 4 | Relevant: a rating of 3 or higher"
  )
})

# Second round of the coverage work on the judge and item-sort workflows:
# the fixes for separated relevance decisions, for a judge left in the
# facets model with no decisions, and for an unnamed matrix given to the
# facets helper, and the code those fixes and the dead-branch removals touch.

# Judge1 and Judge2 each rate one of Item1 and Item2 relevant and nothing
# else; Judge3 and Judge4 rate both of those relevant, and one of Item3 and
# Item4. No judge or item is unanimous, yet the decisions are separated.
d2_separated_panel <- function() {
  X <- rbind(c(4, 1, 1, 1), c(1, 4, 1, 1), c(4, 4, 4, 1), c(4, 4, 1, 4))
  dimnames(X) <- list(paste0("Judge", 1:4), paste0("Item", 1:4))
  X
}

# Judges A1-A3 rate Q1-Q3 in a cycle: each rates two of the three relevant.
# Judges C1, C3, ..., C21 and items K2, K4, ..., K20 form a chain: judge
# C(p) rates K(p - 1) a 1 and K(p + 1) a 4 where those items exist, and
# every other cell is missing.
d2_chain_panel <- function() {
  judges <- c(paste0("A", 1:3), paste0("C", seq(1, 21, 2)))
  items <- c(paste0("Q", 1:3), paste0("K", seq(2, 20, 2)))
  X <- matrix(NA_real_, length(judges), length(items),
              dimnames = list(judges, items))
  X[1:3, 1:3] <- rbind(c(4, 4, 1), c(4, 1, 4), c(1, 4, 4))
  for (p in seq(1, 21, 2)) {
    if (p > 1) X[paste0("C", p), paste0("K", p - 1)] <- 1
    if (p < 21) X[paste0("C", p), paste0("K", p + 1)] <- 4
  }
  X
}

d2_flat <- function(x) {
  old <- options(width = 80)
  on.exit(options(old), add = TRUE)
  gsub("[[:space:]]+", " ",
       paste(utils::capture.output(print(x)), collapse = " "))
}

# Separated relevance decisions ---------------------------------------------

test_that("separated relevance decisions withhold logit severity", {
  fit <- judge_validity(d2_separated_panel(), lo = 1, hi = 4)
  r <- fit$results

  # The model has no maximum-likelihood estimates, so no judge is placed.
  expect_false(fit$scale_summary$severity_estimable)
  expect_false(any(r$severity_estimable))
  expect_true(all(is.na(c(r$severity, r$se, r$infit, r$outfit))))
  expect_identical(r$n_scored, rep(0L, 4))
  expect_identical(fit$settings$bias_correction, NA_real_)
  expect_identical(fit$design$n_judges_not_estimable, 4L)
  expect_match(fit$details$severity_note,
               paste("maximum-likelihood estimates do not exist",
                     "(Albert & Anderson, 1984)."), fixed = TRUE)

  # Flags rest on rating points instead. The panel mean is 2.5 and the
  # judges' means 1.75, 1.75, 3.25 and 3.25, so each sits exactly at the
  # cut of 0.75 (a quarter of the scale range) and none is beyond it.
  expect_equal(r$severity_raw, c(0.75, 0.75, -0.75, -0.75))
  expect_identical(r$recommendation, rep("Typical", 4))
  expect_identical(r$status, rep("Supported", 4))

  out <- d2_flat(fit)
  expect_match(out, "Logit severity not estimated", fixed = TRUE)
  expect_match(out, paste("The relevance decisions split the judges and",
                          "items into two groups"), fixed = TRUE)
  expect_match(out, paste("Severity in rating points is reported instead",
                          "and is used for flagging."), fixed = TRUE)
  expect_false(grepl("Logit:", out, fixed = TRUE))
})

test_that("the separation rule finds a group the model can push apart", {
  sep <- contentvalidR:::.facets_separated
  B <- ifelse(d2_separated_panel() >= 3, 1, 0)
  expect_true(sep(B))
  # The group is Judge3, Judge4, Item3 and Item4. Moving it up the logit
  # scale by t (its judges more lenient, its items harder) fits every
  # decision between the groups better and leaves the rest as they were, so
  # the log-likelihood climbs with t and never reaches a maximum.
  loglik <- function(t) {
    eta <- outer(c(0, 0, t, t), c(0, 0, t, t), "-")
    sum(B * stats::plogis(eta, log.p = TRUE) +
          (1 - B) * stats::plogis(-eta, log.p = TRUE))
  }
  expect_true(all(diff(vapply(c(0, 1, 5, 20, 40), loglik, numeric(1))) > 0))

  # A cycle, in which each judge rates two of three items relevant, has
  # every decision on a loop. An item every judge endorsed has none.
  cycle <- rbind(c(1, 1, 0), c(1, 0, 1), c(0, 1, 1))
  expect_false(sep(cycle))
  expect_true(sep(cbind(cycle, 1)))

  # Missing cells: two cycles with nothing between them are not separated,
  # only unlinked. One judge of the first endorsing an item of the second
  # separates them; a judge of the second endorsing an item of the first
  # closes the loop again.
  two <- matrix(NA_real_, 6, 6)
  two[1:3, 1:3] <- cycle
  two[4:6, 4:6] <- cycle
  expect_false(sep(two))
  one_way <- two
  one_way[1, 4] <- 1
  expect_true(sep(one_way))
  both_ways <- one_way
  both_ways[4, 1] <- 1
  expect_false(sep(both_ways))
})

test_that("separation is checked after the unanimous are set aside", {
  # Item5, which every judge rates relevant, is set aside first; the four
  # items left are still separated.
  X <- cbind(d2_separated_panel(), Item5 = 4)
  fs <- contentvalidR:::.facets_severity(ifelse(X >= 3, 1, 0))
  expect_false(fs$estimable)
  expect_identical(c(fs$n_judges_dropped, fs$n_items_dropped), c(0L, 1L))
  expect_match(fs$reason, "split the judges and items into two groups",
               fixed = TRUE)
})

# Trimming to a stable set ---------------------------------------------------

test_that("trimming goes on until no judge or item without variation is left", {
  X <- d2_chain_panel()
  B <- ifelse(is.na(X), NA_real_, as.numeric(X >= 3))
  dimnames(B) <- dimnames(X)
  # The chain is set aside from both ends, one judge or item a round, and
  # its middle judge, C11, loses its last items in the tenth round. It goes
  # in the eleventh, leaving the cycle of A1-A3 and Q1-Q3.
  trim <- contentvalidR:::.facets_trim_extremes(B)
  expect_identical(trim$keep_judges, rep(c(TRUE, FALSE), c(3L, 11L)))
  expect_identical(trim$keep_items, rep(c(TRUE, FALSE), c(3L, 10L)))
})

test_that("no judge without decisions is placed on the logit scale", {
  fit <- judge_validity(d2_chain_panel(), lo = 1, hi = 4, na.rm = TRUE)
  r <- fit$results
  c11 <- r$judge == "C11"
  expect_identical(r$severity_estimable, rep(c(TRUE, FALSE), c(3L, 11L)))
  expect_true(is.na(r$severity[c11]) && is.na(r$se[c11]))
  expect_identical(r$n_scored[c11], 0L)
  expect_identical(c(fit$details$facets$n_judges_dropped,
                     fit$design$n_items_dropped_from_model), c(11L, 10L))

  # The model holds only the cycle. By symmetry every fitted probability is
  # 2/3 and every judge's severity 0. With information 2/9 per decision, a
  # centred judge effect from three judges and three items has variance
  # (2/3) / (3 * 2/9) = 1, and the correction (3 - 1) / 3 scales it by 2/3.
  # glm() stops within its convergence tolerance, hence the looser check.
  expect_equal(r$severity[1:3], rep(0, 3))
  expect_equal(r$se[1:3], rep(sqrt(2 / 3), 3), tolerance = 1e-6)
  expect_equal(fit$settings$bias_correction, 2 / 3)
})

# The facets helper on an unnamed matrix -------------------------------------

test_that("facets severity fits an unnamed matrix under the default names", {
  B <- rbind(c(1, 1, 0, 1), c(1, 0, 1, 0), c(0, 1, 1, 1), c(1, 0, 0, 1))
  named <- B
  dimnames(named) <- list(paste0("Judge", 1:4), paste0("Item", 1:4))
  fs <- contentvalidR:::.facets_severity(B)
  expect_true(fs$estimable)
  expect_identical(fs$table$judge, paste0("Judge", 1:4))
  expect_identical(fs$table, contentvalidR:::.facets_severity(named)$table)
  # Judge names alone are enough as well.
  rows_only <- B
  rownames(rows_only) <- paste0("Judge", 1:4)
  expect_identical(contentvalidR:::.facets_severity(rows_only)$table,
                   fs$table)
  # The same decisions through judge_validity(), where 4 is relevant and 1
  # is not.
  fit <- judge_validity(ifelse(B == 1, 4, 1), lo = 1, hi = 4)
  expect_equal(fit$results$severity, fs$table$severity)
  expect_equal(fit$results$se, fs$table$se)
})

# Item-sort helpers ----------------------------------------------------------

test_that("a scale label close to two others is placed once in their group", {
  place <- contentvalidR:::.map_scale_label_y
  # Each label is close to both others, so the third is found from the first
  # and again from the second. The three are spread 0.055 apart around
  # their mean less 0.06, in order of x.
  expect_equal(place(c(0.50, 0.52, 0.54), c(0.30, 0.32, 0.34)),
               0.26 + c(-0.055, 0, 0.055))
  # The first and third are close only through the second.
  expect_equal(place(c(0.60, 0.50, 0.55), c(0.30, 0.30, 0.30)),
               0.24 + c(0.055, -0.055, 0))
})

test_that("the item-sort design gives the fewest and most judges per item", {
  d <- data.frame(
    item = rep(c("A1", "A2"), c(20, 19)),
    rater = c(1:20, 1:19),
    target_construct = "A",
    assigned_construct = c(rep("A", 18), rep("B", 2),
                           rep("A", 16), rep("B", 3))
  )
  design <- sort_validity(d)$design
  expect_identical(c(design$n_judges_min, design$n_judges_max), c(19L, 20L))
})

test_that("judges who rated no item in common get no logit severity", {
  # Two panels, each a cycle in which every judge rates two of its three
  # items relevant, with every rating between the panels missing. Each panel
  # varies and no decision is separated, yet nothing places one panel's
  # severities against the other's.
  cycle <- rbind(c(4, 4, 1), c(4, 1, 4), c(1, 4, 4))
  X <- matrix(NA_real_, 6, 6,
              dimnames = list(paste0("J", 1:6), paste0("I", 1:6)))
  X[1:3, 1:3] <- cycle
  X[4:6, 4:6] <- cycle
  unlinked <- contentvalidR:::.facets_unlinked
  B <- ifelse(X >= 3, 1, 0)
  expect_true(unlinked(B))
  expect_false(contentvalidR:::.facets_separated(B))
  expect_false(unlinked(B[1:3, 1:3]))
  linked <- B
  linked[1, 4] <- 1
  linked[4, 1] <- 1
  expect_false(unlinked(linked))

  fit <- judge_validity(X, lo = 1, hi = 4, na.rm = TRUE)
  expect_false(fit$scale_summary$severity_estimable)
  expect_false(any(fit$results$severity_estimable))
  expect_match(fit$details$severity_note, "rated no item in common",
               fixed = TRUE)
})

# Tests for branches that covr 4.0.0 found no test running: the judge
# heterogeneity workflow, the item-sort workflow, and the helpers behind
# them. Grouped by the function they exercise.

# The help page's panel: eight judges rate ten items for relevance on 1-4.
example_ratings <- function() {
  r <- rbind(
    c(4, 4, 3, 4, 3, 2, 3, 2, 4, 3), c(4, 3, 4, 3, 2, 3, 2, 3, 4, 2),
    c(3, 4, 4, 3, 3, 2, 2, 2, 3, 3), c(4, 4, 3, 2, 3, 3, 3, 1, 4, 2),
    c(4, 3, 3, 4, 2, 2, 3, 2, 3, 3), c(3, 4, 4, 3, 3, 3, 2, 3, 4, 1),
    c(4, 4, 4, 4, 3, 2, 3, 2, 4, 3), c(3, 2, 3, 2, 2, 1, 2, 1, 2, 2)
  )
  dimnames(r) <- list(paste0("Judge", 1:8), paste0("Item", 1:10))
  r
}

# The help page's item sort: 20 judges sort three items written for A.
example_sort <- function() {
  data.frame(
    item = rep(c("A1", "A2", "A3"), each = 20),
    rater = rep(1:20, 3),
    target_construct = "A",
    assigned_construct = c(
      rep("A", 18), rep("B", 2),
      rep("A", 16), rep("B", 4),
      rep("A", 12), rep("B", 8)
    ),
    stringsAsFactors = FALSE
  )
}

# Draws `expr` on a null device and returns every string text() was asked
# to draw, as the collector in test-closeout3.R does.
text_drawn_by <- function(expr) {
  sink <- new.env()
  sink$text <- character(0)
  grab <- function(...) {
    for (a in list(...)) {
      if (is.character(a)) sink$text <- c(sink$text, a)
    }
  }
  suppressMessages(trace("text", bquote(.(grab)(...)), print = FALSE,
                         where = graphics::plot))
  on.exit(suppressMessages(untrace("text", where = graphics::plot)),
          add = TRUE)
  grDevices::pdf(NULL, width = 7, height = 5)
  on.exit(grDevices::dev.off(), add = TRUE)
  force(expr)
  sink$text
}

# judge_validity() ----------------------------------------------------------

test_that("infinite ratings are refused before any analysis", {
  r <- example_ratings()
  r[2, 3] <- Inf
  expect_error(judge_validity(r, lo = 1, hi = 4),
               "`ratings` cannot contain infinite values")
  r[2, 3] <- -Inf
  expect_error(judge_validity(r, lo = 1, hi = 4),
               "`ratings` cannot contain infinite values")
})

test_that("a judge who rated nothing is insufficient data, every effect NA", {
  # J4 returned a blank form; the other three rated every item.
  m <- rbind(c(4, 3, 4, 2), c(3, 4, 4, 1), c(4, 4, 3, 2), rep(NA, 4))
  dimnames(m) <- list(paste0("J", 1:4), paste0("I", 1:4))
  fit <- judge_validity(m, lo = 1, hi = 4, na.rm = TRUE)
  r <- fit$results

  expect_identical(r$n_ratings, c(4L, 4L, 4L, 0L))
  effects <- c("mean_rating", "sd_rating", "severity_raw", "differentiation",
               "central_prop", "extreme_prop")
  expect_true(all(is.na(unlist(r[4, effects]))))
  expect_identical(r$recommendation[4], "Insufficient data")
  expect_identical(r$status[4], "Insufficient data")
  expect_identical(
    r$interpretation[4],
    paste("This judge supplied fewer than two usable ratings, so no",
          "heterogeneity evidence can be computed for them.")
  )
  # The others are compared with the panel on the items they rated: item
  # means 11/3, 11/3, 11/3 and 5/3, less each judge's rating, averaged.
  expect_equal(r$severity_raw[1:3], c(-1, 2, -1) / 12)
  # Ratings strictly between 1 and 4: two of four, one of four, two of four.
  expect_equal(r$central_prop[1:3], c(0.5, 0.25, 0.5))
})

test_that("a model that does not converge withholds logit severity", {
  # A perfect Guttman staircase: judge k accepts the first k of 21 items.
  # No finite severities exist. Extremes are set aside for at most ten
  # rounds, which leaves a separated core of ten judges and eleven items,
  # and glm() stops on it without converging.
  k <- 1:20
  stair <- outer(k, 1:21, function(j, i) ifelse(i <= j, 4, 1))
  dimnames(stair) <- list(paste0("Judge", k), paste0("Item", 1:21))
  fit <- judge_validity(stair, lo = 1, hi = 4)

  expect_identical(
    fit$details$severity_note,
    "The facets model did not converge, so judge severity is not reported."
  )
  expect_false(fit$scale_summary$severity_estimable)
  expect_true(all(is.na(fit$results$severity)))
  expect_false(any(fit$results$severity_estimable))
  expect_identical(fit$settings$bias_correction, NA_real_)

  # Severity in rating points still flags judges: judge k's mean is
  # (4k + 21 - k) / 21 and the panel's 2.5, and the cut is 0.75.
  expect_equal(fit$results$severity_raw, 2.5 - (3 * k + 21) / 21)
  expect_identical(fit$results$recommendation[c(1:5, 16:20)],
                   rep(c("Severe", "Lenient"), each = 5))

  out <- utils::capture.output(print(fit))
  expect_true("Logit severity not estimated" %in% out)
  expect_match(paste(out, collapse = " "),
               "The facets model did not converge", fixed = TRUE)
})

test_that("an erratic judge's sentence names a bound the analyst set", {
  fit <- judge_validity(example_ratings(), lo = 1, hi = 4,
                        fit_range = c(0.5, 1.4), fit_min_ratings = 5)
  r <- fit$results
  above <- !is.na(r$infit) & pmax(r$infit, r$outfit) > 1.4
  # The model scored six decisions of each judge it placed, at least five.
  expect_true(all(r$n_scored[above] >= 5L))
  expect_identical(r$judge[above], c("Judge2", "Judge4"))
  expect_identical(r$recommendation[above], c("Erratic", "Erratic"))
  expect_match(r$interpretation[above],
               "above 1.4, the upper bound set for this analysis",
               fixed = TRUE)
  expect_false(any(grepl("Linacre", r$interpretation[above])))
})

test_that("long judge names turn the fragile-item table into sentences", {
  old <- options(width = 80)
  on.exit(options(old), add = TRUE)
  r <- example_ratings()
  long_names <- c(
    "Professor Adelaide Featherstonehaugh", "Dr Bartholomew Quackenbush",
    "Dr Cordelia Montgomery-Smythe", "Professor Desmond Abernathy-Wolfe",
    "Dr Evangeline Thistlewood", "Dr Ferdinand Oyelaran-Castellanos",
    "Dr Guinevere Ashcombe", "Professor Horatio Pemberton-Vale"
  )
  short <- utils::capture.output(print(judge_validity(r, lo = 1, hi = 4)))
  rownames(r) <- long_names
  out <- utils::capture.output(print(judge_validity(r, lo = 1, hi = 4)))

  # Item4 is rated relevant (3 or 4) by six of eight judges, one short of
  # Lynn's criterion for eight, so it is under review; removing either
  # judge who rated it below 3 changes that.
  dissent <- long_names[r[, "Item4"] < 3]
  expect_identical(sum(r[, "Item4"] >= 3), 6L)
  txt <- gsub("\\s+", " ", paste(out, collapse = " "))
  expect_match(txt, paste0("Item4: 6 of 8 relevant (Review); changes without ",
                           paste(dissent, collapse = ", "), "."),
               fixed = TRUE)
  # Short names keep the table; long ones drop it for the sentence, and
  # every line still fits the console.
  expect_true(any(grepl("Relevant\\s+Status", short)))
  expect_false(any(grepl("Relevant\\s+Status", out)))
  expect_lte(max(nchar(out, type = "width")), 80L)
})

test_that("summary() prints Phi and G, or says they cannot be estimated", {
  # Each judge left a different item unrated, so no judge rated every item
  # and the generalizability analysis has no complete judge to use. Every
  # item has two raters, too few for the fragile-item check.
  m <- rbind(c(4, 3, NA), c(NA, 4, 3), c(3, NA, 4))
  dimnames(m) <- list(c("Ana", "Ben", "Cy"), c("Q1", "Q2", "Q3"))
  fit <- judge_validity(m, lo = 1, hi = 4, na.rm = TRUE)
  out <- utils::capture.output(print(summary(fit)))

  expect_true("  Dependability (absolute decisions): not estimable" %in% out)
  expect_true("  Generalizability (rank ordering):   not estimable" %in% out)
  # The note on unchecked items stands apart from the line above it.
  i <- grep("^Not checked: 3 items rated by three or fewer judges", out)
  expect_length(i, 1L)
  expect_identical(out[i - 1L], "")
  expect_identical(out[i - 2L], "No judge was flagged for review.")

  # With complete ratings the coefficients are printed: Crocker et al.'s
  # (1988) Phi and G from the two-way mean squares, computed here by hand.
  X <- example_ratings()
  nj <- nrow(X)
  ni <- ncol(X)
  gm <- mean(X)
  ms_item <- nj * sum((colMeans(X) - gm)^2) / (ni - 1)
  ms_judge <- ni * sum((rowMeans(X) - gm)^2) / (nj - 1)
  ms_resid <- (sum((X - gm)^2) - ms_item * (ni - 1) - ms_judge * (nj - 1)) /
    ((ni - 1) * (nj - 1))
  v_item <- max(0, (ms_item - ms_resid) / nj)
  v_judge <- max(0, (ms_judge - ms_resid) / ni)
  phi <- v_item / (v_item + (v_judge + ms_resid) / nj)
  g <- v_item / (v_item + ms_resid / nj)
  apa <- function(v) sub("^0", "", sprintf("%.2f", v))
  full <- utils::capture.output(print(summary(
    judge_validity(X, lo = 1, hi = 4)
  )))
  expect_true(paste0("  Dependability (absolute decisions): ", apa(phi)) %in%
                full)
  expect_true(paste0("  Generalizability (rank ordering):   ", apa(g)) %in%
                full)
})

# Helpers behind judge_validity() --------------------------------------------
# judge_validity() names unnamed rows Judge1, Judge2, ... before it calls
# these, so their own default names are reached only by calling them.

test_that("rater effects name unnamed judges as judge_validity() does", {
  X <- unname(example_ratings())
  eff <- contentvalidR:::.rater_effects(X, lo = 1, hi = 4)
  expect_identical(eff$judge, paste0("Judge", 1:8))
  expect_identical(judge_validity(X, lo = 1, hi = 4)$results$judge,
                   eff$judge)
  # With complete ratings, severity is the grand mean less the judge's mean.
  expect_equal(eff$mean_rating, unname(rowMeans(X)))
  expect_equal(eff$severity_raw, mean(X) - unname(rowMeans(X)))
  named <- contentvalidR:::.rater_effects(example_ratings(), lo = 1, hi = 4)
  expect_equal(eff[-1], named[-1], ignore_attr = TRUE)
})

test_that("facets severity names unnamed judges when none is estimable", {
  # Every judge endorses every item, so every judge and item is set aside.
  B <- matrix(1, nrow = 3, ncol = 4)
  fs <- contentvalidR:::.facets_severity(B)
  expect_false(fs$estimable)
  expect_identical(fs$table$judge, paste0("Judge", 1:3))
  expect_true(all(is.na(fs$table$severity)))
  expect_identical(fs$n_judges_dropped, 3L)
  expect_identical(fs$n_items_dropped, 4L)
})

test_that("the Phi clause says nothing when no judge was dropped", {
  # print() and summary() call this only when ratings are missing, and
  # gtheory_content() then drops at least one judge, so a count of zero or
  # none is reached only by calling it.
  clause <- contentvalidR:::.phi_judges_clause
  expect_identical(clause(5, 0L), "")
  expect_identical(clause(5, NULL), "")
  expect_identical(clause(5, 2L),
                   "; Phi uses the 3 judges who rated every item")
})

# Sort-data checks behind compute_psa(), compute_csv() and sort_validity() --

test_that("sort data that is not a usable data frame is refused", {
  d <- example_sort()
  expect_error(compute_psa(as.matrix(d)), "`assignments` must be a data.frame")
  expect_error(compute_csv(d[0, ]),
               "`assignments` must contain at least one response row")
  expect_error(
    sort_validity(d[c("item", "assigned_construct")]),
    "`assignments` is missing required column(s): rater, target_construct.",
    fixed = TRUE
  )
})

test_that("an alpha outside (0, 1) is refused before any item is analyzed", {
  d <- example_sort()
  msg <- "`alpha` must be one finite probability strictly between 0 and 1"
  expect_error(sort_validity(d, alpha = 1), msg)
  expect_error(sort_validity(d, alpha = 0), msg)
  expect_error(sort_validity(d, alpha = NA_real_), msg)
  expect_error(sort_validity(d, alpha = c(0.05, 0.10)), msg)
})

test_that("the critical count refuses a judge count that is not whole", {
  # csv_binom_test() checks N by the same rule before calling this, and
  # sort_validity() and sort_power() call it with N = 1, so a bad N is
  # reached only by calling it.
  crit <- contentvalidR:::.critical_target_count
  msg <- "`N` must be a positive finite integer"
  expect_error(crit(0), msg)
  expect_error(crit(2.5), msg)
  expect_error(crit(NA_real_), msg)
  expect_error(crit(c(5, 6)), msg)
  # With 20 judges, 15 is the fewest whose upper tail is at most .05.
  expect_lte(stats::pbinom(14, 20, 0.5, lower.tail = FALSE), 0.05)
  expect_gt(stats::pbinom(13, 20, 0.5, lower.tail = FALSE), 0.05)
  expect_equal(crit(20), 15)
})

test_that("scale labels on the map need one y per x, and none is fine", {
  # plot(type = "map") for item-sort and rating results calls this with the
  # scale means it found, always paired and never empty, so these guards
  # are reached only by calling it.
  place <- contentvalidR:::.map_scale_label_y
  expect_error(place(c(0.5, 0.7), 0.2),
               "`x` and `y` must have the same length")
  expect_identical(place(numeric(0), numeric(0)), numeric(0))
  # A lone label sits 0.06 below its point.
  expect_equal(place(0.5, 0.2), 0.14)
})

# sort_validity() -----------------------------------------------------------

test_that("a blank name on a single orbiting correlation counts as no name", {
  d <- example_sort()
  plain <- sort_validity(d, orbiting_r = 0.45)
  expect_identical(plain$scale_summary$orbiting_r, 0.45)
  # A space, and a non-breaking space.
  for (blank in c(" ", intToUtf8(160))) {
    named <- sort_validity(d, orbiting_r = stats::setNames(0.45, blank))
    expect_identical(named$scale_summary, plain$scale_summary)
  }
  # A real name must still be the target's.
  expect_error(sort_validity(d, orbiting_r = c(B = 0.45)), "named 'B'")
})

test_that("orbiting correlations outside -1 to 1 are refused", {
  d <- example_sort()
  msg <- "`orbiting_r` must contain finite correlations between -1 and 1"
  expect_error(sort_validity(d, orbiting_r = 1.2), msg)
  expect_error(sort_validity(d, orbiting_r = -1.5), msg)
  expect_error(sort_validity(d, orbiting_r = NA_real_), msg)
  expect_error(sort_validity(d, orbiting_r = "0.4"), msg)
})

test_that("orbiting correlations must name every target construct", {
  d <- example_sort()
  d$target_construct[d$item == "A3"] <- "B"
  expect_error(sort_validity(d, orbiting_r = c(A = 0.4)),
               "`orbiting_r` is missing target construct(s): B",
               fixed = TRUE)
})

test_that("the header gives the panel per item when it is not every judge", {
  # Judges 1-20 sorted A1 and judges 2-21 sorted A2: 21 judges, 20 each.
  d <- data.frame(
    item = rep(c("A1", "A2"), each = 20),
    rater = c(1:20, 2:21),
    target_construct = "A",
    assigned_construct = c(rep("A", 18), rep("B", 2),
                           rep("A", 16), rep("B", 4))
  )
  fit <- sort_validity(d)
  out <- utils::capture.output(print(fit))
  expect_identical(out[grep("^Items:", out)],
                   "Items: 2 | Judges: 21 (20 per item) | Target constructs: 1")
})

test_that("retained items whose intervals reach p0 share one plural note", {
  # 20 of 30 judges meets the exact test (one-sided p <= .05), but the
  # two-sided 95% Wilson interval reaches below .5; 27 of 30 clears it.
  wilson_low <- function(x, n, z = stats::qnorm(0.975)) {
    (x + z^2 / 2) / (n + z^2) - z / (n + z^2) * sqrt(x * (n - x) / n + z^2 / 4)
  }
  expect_lte(stats::binom.test(20, 30, alternative = "greater")$p.value, 0.05)
  expect_lt(wilson_low(20, 30), 0.5)
  expect_gt(wilson_low(27, 30), 0.5)

  d <- data.frame(
    item = rep(c("A1", "A2", "A3"), each = 30),
    rater = rep(1:30, 3),
    target_construct = "A",
    assigned_construct = c(rep("A", 20), rep("B", 10),
                           rep("A", 20), rep("B", 10),
                           rep("A", 27), rep("B", 3))
  )
  fit <- sort_validity(d)
  expect_identical(fit$results$recommendation, rep("Retain", 3))
  expect_equal(fit$results$psa_low, wilson_low(c(20, 20, 27), 30))

  old <- options(width = 80)
  on.exit(options(old), add = TRUE)
  txt <- gsub("\\s+", " ",
              paste(utils::capture.output(print(fit)), collapse = " "))
  # Both items in one sentence, A3 not among them.
  expect_match(txt, paste("A1, A2 are retained although their 95%",
                          "intervals include p0 = .50: the interval is",
                          "two-sided"), fixed = TRUE)

  # One such item reads in the singular.
  one <- sort_validity(d[d$item != "A2", ])
  txt <- gsub("\\s+", " ",
              paste(utils::capture.output(print(one)), collapse = " "))
  expect_match(txt, paste("A1 is retained although its 95% interval",
                          "includes p0 = .50"), fixed = TRUE)
})

test_that("the evidence map draws no item labels when asked for none", {
  fit <- sort_validity(example_sort())
  res <- NULL
  none <- text_drawn_by(res <- plot(fit, type = "map", label = "none"))
  every <- text_drawn_by(plot(fit, type = "map", label = "all"))
  expect_identical(res, fit)
  # The collector sees item labels when they are drawn, so their absence
  # means something.
  expect_true(all(c("A1", "A2", "A3") %in% every))
  expect_false(any(c("A1", "A2", "A3") %in% none))
  # The scale mean keeps its label either way.
  expect_true("A" %in% none)
})

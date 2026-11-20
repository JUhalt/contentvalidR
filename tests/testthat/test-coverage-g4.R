# Tests for branches that covr 4.0.0 found no test running in the
# construct-rating functions (the shared rating-data and scale checks,
# anova_content(), rating_validity() and its print and plot), the Colquitt
# benchmark helpers and the Q-factor comparator. They are grouped by the
# function they exercise.

# The package's construct-rating example: six items, two per target
# construct A, B and C, rated by 24 judges against all three definitions.
rating_ex <- function() {
  utils::read.csv(system.file("extdata", "rating_example.csv",
                              package = "contentvalidR"),
                  stringsAsFactors = FALSE)
}

# The text a figure draws: mtext(), text() and the axis titles set through
# title(), collected while the figure is drawn on a null device.
figure_text <- function(expr) {
  sink <- new.env()
  sink$text <- character(0)
  grab_chars <- function(...) {
    for (a in list(...)) {
      if (is.character(a)) sink$text <- c(sink$text, a)
    }
  }
  suppressMessages({
    trace("mtext", bquote(.(grab_chars)(text)), print = FALSE,
          where = graphics::plot)
    trace("text", bquote(.(grab_chars)(...)), print = FALSE,
          where = graphics::plot)
    trace("title", bquote(.(grab_chars)(main, sub, xlab, ylab)),
          print = FALSE, where = graphics::plot)
  })
  # Untraced on the way out, and the device closed, even when expr fails.
  on.exit(suppressMessages({
    untrace("mtext", where = graphics::plot)
    untrace("text", where = graphics::plot)
    untrace("title", where = graphics::plot)
  }), add = TRUE)
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  force(expr)
  sink$text
}

# A printout as one line with single spaces, so a phrase can be matched
# wherever the console width wraps it.
printed <- function(x) {
  gsub("\\s+", " ", paste(utils::capture.output(print(x)), collapse = " "))
}

# ---------------------------------------------------------------------------
# Rating-data checks shared by htc(), htd(), anova_content() and
# rating_validity()
# ---------------------------------------------------------------------------

test_that("an empty ratings table is refused before any analysis", {
  rat <- rating_ex()
  expect_error(anova_content(rat[0, ]),
               "`ratings` must be a non-empty data.frame.", fixed = TRUE)
  expect_error(rating_validity(rat[0, ]),
               "`ratings` must be a non-empty data.frame.", fixed = TRUE)
})

test_that("a ratings table without a needed column is refused, naming it", {
  rat <- rating_ex()
  expect_error(
    anova_content(rat[c("item", "rater", "rating", "target_construct")]),
    "`ratings` is missing required column(s): construct.", fixed = TRUE
  )
  # Every missing column is named, in the order the arguments give them.
  expect_error(
    htc(rat[c("item", "rating", "target_construct")]),
    "`ratings` is missing required column(s): rater, construct.",
    fixed = TRUE
  )
})

test_that("a factor or text rating column is refused as not numeric", {
  rat <- rating_ex()
  as_factor <- rat
  as_factor$rating <- factor(as_factor$rating)
  expect_error(anova_content(as_factor), "`rating` must be numeric.",
               fixed = TRUE)
  as_text <- rat
  as_text$rating <- as.character(as_text$rating)
  expect_error(rating_validity(as_text), "`rating` must be numeric.",
               fixed = TRUE)
})

test_that("a target_map given as a list analyzes as the named vector does", {
  rat <- rating_ex()
  bare <- rat[c("item", "rater", "construct", "rating")]
  map <- c(A1 = "A", A2 = "A", B1 = "B", B2 = "B", C1 = "C", C2 = "C")
  from_vector <- anova_content(bare, target_map = map)
  from_list <- anova_content(bare, target_map = as.list(map))
  expect_identical(from_list, from_vector)
  expect_identical(from_list$target, unname(map))
  # The same targets read from the data's target column give the same tests.
  expect_identical(as.data.frame(from_list),
                   as.data.frame(anova_content(rat)))
})

test_that("without a target map or target column the indices ask for one", {
  bare <- rating_ex()[c("item", "rater", "construct", "rating")]
  msg <- paste("Supply a named `target_map` or include a target column",
               "(default `target_construct`).")
  expect_error(rating_validity(bare), msg, fixed = TRUE)
  expect_error(htc(bare), msg, fixed = TRUE)
})

# ---------------------------------------------------------------------------
# Rating-scale checks used by htc(), htd() and rating_validity()
# ---------------------------------------------------------------------------

test_that("a missing or infinite scale endpoint is refused", {
  rat <- rating_ex()
  msg <- "`scale_min` and `scale_max` must be finite numeric scalars."
  expect_error(rating_validity(rat, scale_max = NA), msg, fixed = TRUE)
  expect_error(htd(rat, scale_min = -Inf), msg, fixed = TRUE)
})

test_that("a scale whose maximum does not exceed its minimum is refused", {
  rat <- rating_ex()
  msg <- "`scale_max` must be greater than `scale_min`."
  expect_error(rating_validity(rat, scale_min = 5, scale_max = 5), msg,
               fixed = TRUE)
  expect_error(htc(rat, scale_min = 5, scale_max = 1), msg, fixed = TRUE)
})

test_that("endpoints that are one anchor apart up to rounding are refused", {
  # A computed endpoint can carry rounding noise: this one is 1 + 2.2e-16,
  # so it passes the check that the maximum exceeds the minimum and the
  # check that it is a whole anchor, yet leaves one anchor on the scale.
  top <- 0.1 * 3 / 0.3
  expect_gt(top, 1)
  expect_error(rating_validity(rating_ex(), scale_min = 1, scale_max = top),
               "At least two rating anchors are required.", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# rating_validity(): orbiting correlations
# ---------------------------------------------------------------------------

test_that("orbiting_r that leaves out a target scale is refused, naming it", {
  expect_error(rating_validity(rating_ex(), orbiting_r = c(A = .30, C = .40)),
               "`orbiting_r` is missing target(s): B.", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# anova_content()
# ---------------------------------------------------------------------------

test_that("an alpha outside the open interval from 0 to 1 is refused", {
  rat <- rating_ex()
  msg <- "`alpha` must be one number strictly between 0 and 1."
  expect_error(anova_content(rat, alpha = 0), msg, fixed = TRUE)
  expect_error(anova_content(rat, alpha = 1), msg, fixed = TRUE)
  expect_error(anova_content(rat, alpha = NA_real_), msg, fixed = TRUE)
  expect_error(anova_content(rat, alpha = c(.05, .10)), msg, fixed = TRUE)
})

test_that("an item with no usable rating gets no design and no tests", {
  d <- expand.grid(rater = 1:4, construct = c("A", "B", "C"),
                   item = c("I1", "I2"), KEEP.OUT.ATTRS = FALSE,
                   stringsAsFactors = FALSE)
  d$target_construct <- ifelse(d$item == "I1", "A", "B")
  d$rating <- c(5, 4, 5, 4, 2, 3, 2, 2, 1, 2, 2, 1, rep(NA, 12))
  res <- anova_content(d)
  i2 <- res[res$item == "I2", ]
  expect_identical(res$design, c("within", "unknown"))
  expect_identical(i2$target, "B")
  expect_identical(i2$n_raters, 4L)
  expect_identical(i2$n_complete, 0L)
  expect_true(is.na(i2$target_mean))
  expect_true(all(is.na(unlist(i2[c("F", "df1", "df2", "p", "epsilon_gg",
                                    "p_gg", "p_screen", "partial_eta2",
                                    "max_contrast_p", "contrast_pass")]))))
  # Only the item with ratings has planned contrasts.
  expect_identical(unique(attr(res, "contrasts")$item), "I1")
})

# A between-judge item: each of ten judges rated it against one definition.
# The intended construct A and the orbiting B, C and D have no spread; E
# does.
between_item <- function() {
  data.frame(item = "I1", rater = paste0("J", 1:10),
             construct = rep(c("A", "B", "C", "D", "E"), each = 2),
             rating = c(4, 4, 2, 2, 5, 5, 4, 4, 1, 3),
             target_construct = "A", stringsAsFactors = FALSE)
}

test_that("a between-judge item without a target gets only the omnibus test", {
  d <- between_item()
  d$target_construct <- NULL
  res <- anova_content(d, design = "between")
  # By hand: group means 4, 2, 5, 4, 2 around a grand mean of 3.4 give a
  # between-construct sum of squares of 14.4 on 4 df; only E varies, with
  # a sum of squares of 2 on 5 df. F = (14.4 / 4) / (2 / 5) = 9.
  expect_identical(res$design, "between")
  expect_true(is.na(res$target))
  expect_equal(res$F, 9)
  expect_equal(c(res$df1, res$df2), c(4, 5))
  expect_equal(res$p, stats::pf(9, 4, 5, lower.tail = FALSE))
  expect_equal(res$partial_eta2, 14.4 / 16.4)
  expect_true(is.na(res$contrast_pass))
  expect_identical(nrow(attr(res, "contrasts")), 0L)
})

test_that("between-judge contrasts without spread are infinite or untested", {
  res <- anova_content(between_item())
  con <- attr(res, "contrasts")
  expect_identical(con$competitor, c("B", "C", "D", "E"))
  # A is above B, below C and level with D, and none of the three varies:
  # the difference is certain, so t is +Inf, -Inf or undefined, and the
  # one-sided p is 0, 1 or undefined.
  expect_identical(con$t[1:3], c(Inf, -Inf, NA))
  expect_identical(con$p[1:3], c(0, 1, NA))
  expect_identical(con$df[1:3], rep(Inf, 3))
  expect_identical(con$pass, c(TRUE, FALSE, FALSE, FALSE))
  # With no spread in either group there is no pooled SD for Cohen's d.
  expect_identical(con$dz[1:3], rep(NA_real_, 3))
  # E varies, so its contrast is the one-sided Welch test.
  welch <- stats::t.test(c(4, 4), c(1, 3), alternative = "greater")
  expect_equal(con$t[4], unname(welch$statistic))
  expect_equal(con$df[4], unname(welch$parameter))
  expect_equal(con$p[4], welch$p.value)
  # Pooled SD sqrt((0 + 2) / 2) = 1, so d = (4 - 2) / 1.
  expect_equal(con$dz[4], 2)
  # The untested tie leaves no largest contrast p, and fails the item.
  expect_true(is.na(res$max_contrast_p))
  expect_false(res$contrast_pass)
  expect_equal(res$min_mean_diff, -1)
})

test_that("between-judge contrasts with too few ratings are not tested", {
  d <- data.frame(
    item = rep(c("I1", "I2"), c(5, 4)),
    rater = c(paste0("J", 1:5), paste0("J", 1:4)),
    construct = c("A", "A", "A", "B", "C", "A", "A", "B", "B"),
    rating = c(4, 5, 3, 2, NA, NA, NA, 2, 3),
    target_construct = "A", stringsAsFactors = FALSE
  )
  res <- anova_content(d)
  con <- attr(res, "contrasts")
  expect_identical(res$design, c("between", "between"))
  expect_identical(paste(con$item, con$competitor),
                   c("I1 B", "I1 C", "I2 B"))
  # I1 against B: three ratings against one, so the means are reported and
  # no test is run.
  expect_identical(con$n, c(1L, 0L, 0L))
  expect_equal(con$mean_target, c(4, 4, NA))
  # I1 against C: C has no rating. I2: its target A has none.
  expect_equal(con$mean_competitor, c(2, NA, 2.5))
  expect_equal(con$mean_diff, c(2, NA, NA))
  expect_true(all(is.na(con[c("t", "df", "p", "p_adj", "dz")])))
  expect_identical(con$pass, c(FALSE, FALSE, FALSE))
  expect_true(all(is.na(res$max_contrast_p)))
  expect_identical(res$contrast_pass, c(FALSE, FALSE))
  expect_true(is.na(res$target_mean[2]))
})

# ---------------------------------------------------------------------------
# print.contentvalid_rating(): the definitions caution
# ---------------------------------------------------------------------------

# The example with target B's items rated against A and B only.
two_definitions_for_b <- function() {
  rat <- rating_ex()
  rating_validity(rat[!(rat$target_construct == "B" & rat$construct == "C"), ],
                  scale_min = 1, scale_max = 5)
}

test_that("the definitions caution names the scales rated against two", {
  fit <- two_definitions_for_b()
  expect_identical(fit$scale_summary$n_definitions, c(3L, 2L, 3L))
  out <- printed(fit)
  expect_match(out, "B: These bands come from tasks with three definitions",
               fixed = TRUE)
  expect_match(out, "items here were rated against 2", fixed = TRUE)
  expect_false(grepl("A: These bands", out, fixed = TRUE))
})

test_that("an object saved without definition counts prints no caution", {
  # Through contentvalidR 0.10.1 the scale summary had no n_definitions
  # column, so a saved object cannot say which scales the caution concerns.
  fit <- two_definitions_for_b()
  fit$scale_summary$n_definitions <- NULL
  out <- printed(fit)
  expect_match(out, "Benchmark set: Overall (not correlation-normed)",
               fixed = TRUE)
  expect_false(grepl("These bands come from tasks", out, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# plot.contentvalid_rating()
# ---------------------------------------------------------------------------

test_that("the item plot uses a caller's x-axis title in place of Item", {
  fit <- rating_validity(rating_ex())
  default <- figure_text(plot(fit))
  custom <- figure_text(plot(fit, xlab = "Pool items"))
  expect_true("Item" %in% default)
  expect_true("Pool items" %in% custom)
  expect_false("Item" %in% custom)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_invisible(plot(fit, xlab = "Pool items"))
  expect_identical(plot(fit, xlab = "Pool items"), fit)
})

test_that("the map labels every item, or none, when asked", {
  fit <- rating_validity(rating_ex())
  items <- fit$results$item
  review <- items[fit$results$recommendation == "Review"]
  expect_identical(review, c("A2", "B2", "C2"))
  shown <- function(...) {
    drawn <- figure_text(plot(fit, type = "map", ...))
    items[items %in% drawn]
  }
  expect_identical(shown(), review)
  expect_identical(shown(label = "all"), items)
  expect_identical(shown(label = "none"), character(0))
  # The scale means keep their target labels whatever the item labels.
  none <- figure_text(plot(fit, type = "map", label = "none"))
  expect_true(all(c("A", "B", "C") %in% none))
})

# ---------------------------------------------------------------------------
# interpret_colquitt()
# ---------------------------------------------------------------------------

test_that("a value outside its index's range is refused with the range", {
  expect_error(interpret_colquitt(1.2, "psa"),
               "`psa` values must lie between 0 and 1.", fixed = TRUE)
  expect_error(interpret_colquitt(c(.20, -1.5), "htd"),
               "`htd` values must lie between -1 and 1.", fixed = TRUE)
  expect_error(interpret_colquitt(Inf, "csv"),
               "`csv` values must lie between -1 and 1.", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# qfactor_content()
# ---------------------------------------------------------------------------

# The data of the help-page example: six items rated by ten judges against
# three definitions, with ratings drawn at random.
q_example <- function() {
  data.frame(
    item = rep(paste0("I", 1:6), each = 30),
    rater = rep(1:10, times = 18),
    construct = rep(rep(LETTERS[1:3], each = 10), times = 6),
    rating = withr::with_seed(1, stats::rnorm(180)),
    stringsAsFactors = FALSE
  )
}

test_that("a percentile outside the open interval from 0 to 100 is refused", {
  q <- q_example()
  msg <- "`percentile` must be one number between 0 and 100, exclusive."
  expect_error(qfactor_content(q, percentile = 0), msg, fixed = TRUE)
  expect_error(qfactor_content(q, percentile = 100), msg, fixed = TRUE)
  expect_error(qfactor_content(q, percentile = NA_real_), msg, fixed = TRUE)
})

test_that("an empty or incomplete Q ratings table is refused", {
  q <- q_example()
  expect_error(qfactor_content(q[0, ]),
               "`ratings` must be a non-empty data.frame.", fixed = TRUE)
  expect_error(qfactor_content(as.matrix(q)),
               "`ratings` must be a non-empty data.frame.", fixed = TRUE)
  expect_error(
    qfactor_content(q[c("item", "rater", "rating")]),
    "`ratings` must contain columns: item, rater, construct, rating",
    fixed = TRUE
  )
})

test_that("non-numeric or infinite Q ratings are refused", {
  q <- q_example()
  as_text <- q
  as_text$rating <- format(as_text$rating)
  expect_error(qfactor_content(as_text), "`rating` must be numeric.",
               fixed = TRUE)
  with_inf <- q
  with_inf$rating[7] <- Inf
  expect_error(qfactor_content(with_inf),
               "`rating` must contain only finite values or NA.", fixed = TRUE)
})

test_that("k_factors outside 1 through the number of items is refused", {
  q <- q_example()
  msg <- paste("`k_factors` must be NULL or an integer from 1 through the",
               "number of items.")
  expect_error(qfactor_content(q, k_factors = 0), msg, fixed = TRUE)
  expect_error(qfactor_content(q, k_factors = 7), msg, fixed = TRUE)
  expect_error(qfactor_content(q, k_factors = 1.5), msg, fixed = TRUE)
})

test_that("principal-axis extraction refuses a singular Q-correlation", {
  q <- q_example()
  # I2 repeats I1's ratings, so the two correlate 1 and the matrix has no
  # inverse for the squared multiple correlations.
  q$rating[q$item == "I2"] <- q$rating[q$item == "I1"]
  expect_error(qfactor_content(q, method = "pa", k_factors = 1),
               "requires a nonsingular Q-correlation matrix.", fixed = TRUE)
  # PCA needs no inverse and still runs on the same matrix.
  pc <- qfactor_content(q, method = "pca", k_factors = 1)
  expect_equal(pc$cor_Q["I1", "I2"], 1)
  expect_identical(dim(pc$loadings), c(6L, 1L))
})

test_that("parallel analysis keeps factors while the observed eigenvalue wins", {
  q <- q_example()
  # The number of leading eigenvalues above their comparison values.
  leading <- function(fit) {
    above <- fit$eigen > fit$parallel_eigen
    as.integer(if (all(above)) length(above) else which(!above)[1] - 1)
  }
  # Glorfeld's comparison at a low percentile is beaten by every observed
  # eigenvalue, so every factor is suggested and extracted.
  low <- qfactor_content(q, parallel_criterion = "percentile", percentile = 1,
                         seed = 1)
  expect_true(all(low$eigen > low$parallel_eigen))
  expect_identical(low$k_suggested, 6L)
  expect_identical(low$k_suggested, leading(low))
  expect_identical(low$k, 6L)
  expect_identical(ncol(low$loadings), 6L)
  expect_identical(low$percentile, 1)
  # Horn's mean comparison beats the first observed eigenvalue of these
  # random ratings: none is suggested, and one factor is still extracted.
  horn <- qfactor_content(q, seed = 1)
  expect_identical(horn$k_suggested, leading(horn))
  expect_identical(horn$k_suggested, 0L)
  expect_identical(horn$k, 1L)
})

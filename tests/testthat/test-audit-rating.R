# Fixes from the audit before 1.0: the construct-rating workflow.

shown <- function(x, ...) {
  old <- options(width = 100)
  on.exit(options(old), add = TRUE)
  paste(utils::capture.output(print(x, ...)), collapse = "\n")
}

flat <- function(x, ...) gsub("[[:space:]]+", " ", shown(x, ...))

rating_data <- function(items = c("I1", "I2", "I3"), raters = 1:8, seed = 5) {
  set.seed(seed)
  d <- expand.grid(item = items, rater = raters, construct = c("A", "B", "C"),
                   stringsAsFactors = FALSE)
  d$target_construct <- "A"
  d$rating <- ifelse(d$construct == "A", sample(4:5, nrow(d), TRUE),
                     sample(1:3, nrow(d), TRUE))
  d
}

test_that("an item with one complete judge stays out of the scale means", {
  d <- rating_data()
  d$rating[d$item == "I3" & d$rater != 1 & d$construct == "B"] <- NA
  fit <- rating_validity(d)
  r <- fit$results
  expect_identical(r$recommendation[r$item == "I3"], "Insufficient data")
  # Its one judge still gives it an HTC and an HTD.
  expect_false(is.na(r$htc[r$item == "I3"]))
  expect_false(is.na(r$htd[r$item == "I3"]))

  s <- fit$scale_summary
  decided <- r$recommendation != "Insufficient data"
  expect_equal(s$mean_htc, mean(r$htc[decided]))
  expect_equal(s$mean_htd, mean(r$htd[decided]))
  expect_identical(s$n_items, 3L)
  expect_identical(s$n_htc, 2L)
  expect_identical(s$n_htd, 2L)

  out <- flat(fit)
  expect_match(out, "A: mean HTC and mean HTD use 2 of 3 items; an item without a decision is left out.",
               fixed = TRUE)
  expect_match(flat(summary(fit)), "mean HTC and mean HTD use 2 of 3 items",
               fixed = TRUE)
})

test_that("the scale means do not depend on alpha", {
  d <- rating_data()
  a <- rating_validity(d, alpha = .05)$scale_summary
  b <- rating_validity(d, alpha = .001)$scale_summary
  expect_equal(a$mean_htc, b$mean_htc)
  expect_equal(a$mean_htd, b$mean_htd)
})

test_that("exactly parallel judges give F = Inf, p = 0, and no correction", {
  # Every judge's ratings differ across the constructs by the same amounts, at
  # fractional ratings whose sums of squares do not cancel exactly.
  shift <- c(0.1, 0.2, 0.3, 0.1, 0.2)
  d <- expand.grid(item = "I1", rater = 1:5, construct = c("A", "B", "C"),
                   stringsAsFactors = FALSE)
  d$rating <- unname(c(A = 4.3, B = 2.7, C = 1.9)[d$construct]) + shift[d$rater]
  # Without the tolerance the error sum of squares is rounding noise, not 0.
  wide <- matrix(d$rating, nrow = 5)
  resid <- wide - outer(rowMeans(wide), rep(1, 3)) -
    outer(rep(1, 5), colMeans(wide)) + mean(wide)
  expect_lt(max(abs(resid)), 1e-12)
  out <- anova_content(d, target_map = c(I1 = "A"))
  expect_identical(out$F, Inf)
  expect_identical(out$p, 0)
  expect_true(is.na(out$epsilon_gg))
  expect_true(is.na(out$df1_gg))
  expect_true(is.na(out$p_gg))
  expect_identical(out$p_screen, 0)
  expect_equal(out$partial_eta2, 1)
  expect_true(out$contrast_pass)

  txt <- flat(out)
  expect_match(txt, "F(2, 8) = Inf", fixed = TRUE)
  expect_match(txt, "F = Inf: the judges' rating profiles were exactly parallel",
               fixed = TRUE)
  expect_false(grepl("Greenhouse-Geisser corrected, so", txt, fixed = TRUE))
})

test_that("the zero-variance tolerance does not depend on the rating units", {
  # The same ratings in units a million times smaller: a real error variance
  # stays a real error variance, and F is unchanged.
  d <- expand.grid(item = "I1", rater = 1:8, construct = c("A", "B", "C"))
  d$rating <- c(5, 4, 5, 4, 5, 4, 5, 4,
                2, 2, 1, 2, 1, 2, 1, 2,
                3, 2, 2, 1, 2, 1, 2, 1)
  small <- d
  small$rating <- small$rating * 1e-6
  a <- anova_content(d, target_map = c(I1 = "A"))
  b <- anova_content(small, target_map = c(I1 = "A"))
  expect_true(is.finite(b$F))
  expect_equal(b$F, a$F)
  expect_equal(b$p_screen, a$p_screen)
  expect_equal(b$epsilon_gg, a$epsilon_gg)
})

test_that("identical ratings still give no test", {
  d <- expand.grid(item = "I1", rater = 1:5, construct = c("A", "B", "C"),
                   stringsAsFactors = FALSE)
  d$rating <- 3
  out <- anova_content(d, target_map = c(I1 = "A"))
  expect_true(is.na(out$F))
  expect_true(is.na(out$p))
  expect_true(is.na(out$p_screen))
  expect_match(flat(out), "--", fixed = TRUE)
})

test_that("an ordinary item is untouched by the zero-variance tolerance", {
  d <- expand.grid(item = "I1", rater = 1:8, construct = c("A", "B", "C"))
  d$rating <- c(5, 4, 5, 4, 5, 4, 5, 4,
                2, 2, 1, 2, 1, 2, 1, 2,
                3, 2, 2, 1, 2, 1, 2, 1)
  out <- anova_content(d, target_map = c(I1 = "A"))
  wide <- matrix(d$rating, nrow = 8)
  long <- data.frame(y = as.vector(wide), judge = factor(rep(1:8, 3)),
                     construct = factor(rep(1:3, each = 8)))
  ref <- summary(stats::aov(y ~ construct + Error(judge / construct),
                            data = long))
  tab <- ref[["Error: judge:construct"]][[1]]
  expect_equal(out$F, tab$`F value`[1])
  expect_equal(out$p, tab$`Pr(>F)`[1])
})

test_that("whole degrees of freedom print whole, and the note fits the test", {
  set.seed(4)
  two <- expand.grid(item = c("I1", "I2"), rater = 1:10,
                     construct = c("A", "B"), stringsAsFactors = FALSE)
  two$target_construct <- "A"
  two$rating <- ifelse(two$construct == "A", sample(3:5, nrow(two), TRUE),
                       sample(1:4, nrow(two), TRUE))
  txt <- flat(anova_content(two))
  expect_match(txt, "F(1, 9) = ", fixed = TRUE)
  expect_false(grepl("1.00, 9.00", txt, fixed = TRUE))
  # With two constructs nothing is corrected, so nothing is said about it.
  expect_false(grepl("fractional", txt, fixed = TRUE))

  three <- flat(anova_content(rating_data()))
  expect_match(three, "Greenhouse-Geisser corrected, so their degrees of freedom are fractional",
               fixed = TRUE)
  expect_match(three, "F\\([0-9]\\.[0-9]{2}, [0-9]+\\.[0-9]{2}\\) = ")
})

test_that(".fmt_df writes whole and fractional degrees of freedom", {
  expect_identical(contentvalidR:::.fmt_df(c(2, 14, 1.8912, NA)),
                   c("2", "14", "1.89", "NA"))
  expect_identical(contentvalidR:::.fmt_df(2.0000000001), "2")
})

test_that("the test is credited to both of its sources", {
  d <- rating_data()
  expect_match(flat(anova_content(d)),
               "adapted from Hinkin & Tracey, 1999; MacKenzie et al., 2011",
               fixed = TRUE)
  fit <- rating_validity(d)
  h <- content_handoff(fit)
  rule <- unique(h$item_evidence$rule)
  expect_length(rule, 1L)
  expect_match(rule, "adapted from Hinkin & Tracey, 1999, following MacKenzie et al., 2011",
               fixed = TRUE)
  expect_match(rule, "omnibus test and every planned target-versus-orbiting contrast",
               fixed = TRUE)
  expect_match(rule, "alpha = .05", fixed = TRUE)
  expect_true("MacKenzie et al. (2011)" %in% h$provenance$citation)
  expect_true("Hinkin & Tracey (1999)" %in% h$provenance$citation)
  # Schema 1 is frozen: the statistics carried are the same three.
  expect_setequal(unique(h$item_statistics$statistic),
                  c("HTC", "HTD", "p_value"))
})

test_that("the printout states the rule and its alpha", {
  fit <- rating_validity(rating_data(), alpha = .01)
  out <- flat(fit)
  expect_match(out, "Retain: the omnibus p and every contrast p at or below alpha = .01.",
               fixed = TRUE)
  expect_match(out, "The contrasts are one-sided", fixed = TRUE)
})

test_that("Retain means what the rule says", {
  fit <- rating_validity(rating_data())
  r <- fit$results
  retain <- r$p_value <= fit$settings$alpha & r$contrast_pass
  expect_identical(r$recommendation == "Retain", retain)
  meaning <- contentvalidR:::.decision_meanings("construct-rating")[["Retain"]]
  expect_match(meaning, "omnibus test", fixed = TRUE)
  expect_match(meaning, "every planned contrast", fixed = TRUE)
})

test_that("HTD is defined as an average over every other construct", {
  # Target 5, B 4, C 1 for every judge: the lead over the closest rival is
  # 1 / 4 = .25, and the average lead over both is (1 + 4) / 2 / 4 = .625.
  d <- expand.grid(item = "I1", rater = 1:4, construct = c("A", "B", "C"),
                   stringsAsFactors = FALSE)
  d$rating <- c(A = 5, B = 4, C = 1)[d$construct]
  out <- htd(d, target_map = c(I1 = "A"))
  expect_equal(out$htd, 0.625)
  expect_identical(out$strongest_competitor, "B")

  g <- contentvalid_glossary()
  def <- g$definition[g$term == "htd"]
  expect_match(def, "averaged over every other construct", fixed = TRUE)
  expect_false(grepl("best competing", def, fixed = TRUE))
  short <- contentvalidR:::.term_short()[["htd"]]
  expect_false(grepl("closest rival", short, fixed = TRUE))
  expect_match(short, "on average", fixed = TRUE)
})

test_that("HTC is said to start at 1 / a, and does", {
  d <- expand.grid(item = "I1", rater = 1:4, construct = c("A", "B"),
                   stringsAsFactors = FALSE)
  d$rating <- 1
  expect_equal(htc(d, target_map = c(I1 = "A"), scale_min = 1,
                   scale_max = 5)$htc, 0.2)
  g <- contentvalid_glossary()
  expect_match(g$range[g$term == "htc"], ".20 to 1 on a 5-point scale",
               fixed = TRUE)
  expect_false(grepl("^0 to 1", g$range[g$term == "htc"]))
})

test_that("items keep the order of the data, and numeric names are text", {
  d <- rating_data(items = c(10, 2, 1))
  expect_identical(htc(d)$item, c("10", "2", "1"))
  expect_identical(htd(d)$item, c("10", "2", "1"))
  expect_identical(anova_content(d)$item, c("10", "2", "1"))
  fit <- rating_validity(d)
  expect_identical(fit$results$item, c("10", "2", "1"))

  f <- rating_data(items = c("Q10", "Q2", "Q1"))
  f$item <- factor(f$item, levels = c("Q1", "Q2", "Q10"))
  expect_identical(rating_validity(f)$results$item, c("Q1", "Q2", "Q10"))

  # A large whole number is not written in scientific notation.
  big <- rating_data(items = c(100000, 2))
  expect_identical(rating_validity(big)$results$item, c("100000", "2"))
})

test_that("spaces around labels are ignored, in the data and in target_map", {
  d <- rating_data(items = c("I1", "I2"))
  ref <- rating_validity(d)$results

  padded <- d
  padded$construct[padded$construct == "A" & padded$rater %% 2 == 0] <- " A"
  padded$target_construct <- "A "
  padded$item[padded$item == "I1" & padded$rater > 4] <- "I1 "
  got <- rating_validity(padded)$results
  expect_identical(got$item, ref$item)
  expect_equal(got$htc, ref$htc)
  expect_equal(got$htd, ref$htd)
  expect_equal(got$p_value, ref$p_value)

  bare <- d[c("item", "rater", "construct", "rating")]
  mapped <- rating_validity(bare, target_map = c(" I1" = "A", "I2 " = " A"))
  expect_equal(mapped$results$htd, ref$htd)
  expect_error(
    rating_validity(bare, target_map = c("I1" = "A", "I1 " = "A", "I2" = "A")),
    "names the same item more than once", fixed = TRUE
  )
})

test_that("expert-judge tables leave out the level columns", {
  d <- rating_data()
  fit <- rating_validity(d, judge_type = "expert")
  out <- flat(fit)
  expect_false(grepl("HTC level", out, fixed = TRUE))
  expect_false(grepl("HTD level", out, fixed = TRUE))
  expect_false(grepl("Benchmark set", out, fixed = TRUE))
  expect_match(out, "mean HTC mean HTD", fixed = TRUE)
  sm <- flat(summary(fit))
  expect_false(grepl("HTC level", sm, fixed = TRUE))
  expect_false(grepl("HTD level", sm, fixed = TRUE))
  expect_false(grepl("overall", sm, fixed = TRUE))
  expect_match(flat(summary(rating_validity(d))), "HTC level", fixed = TRUE)

  naive <- flat(rating_validity(d))
  expect_match(naive, "HTC level", fixed = TRUE)
  expect_match(naive, "Benchmark set:", fixed = TRUE)

  sorts <- utils::read.csv(
    system.file("extdata", "sort_example.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE
  )
  es <- sort_validity(sorts, judge_type = "expert")
  expect_false(grepl("Psa level", flat(es), fixed = TRUE))
  expect_false(grepl("Benchmark set", flat(es), fixed = TRUE))
  expect_false(grepl("Psa level", flat(summary(es)), fixed = TRUE))
  expect_false(grepl("overall", flat(summary(es)), fixed = TRUE))
  expect_match(flat(sort_validity(sorts)), "Psa level", fixed = TRUE)
  expect_match(flat(summary(sort_validity(sorts))), "Psa level", fixed = TRUE)
})

test_that("one incomplete profile is singular", {
  d <- rating_data()
  d$rating[d$item == "I1" & d$rater == 1 & d$construct == "B"] <- NA
  out <- flat(rating_validity(d))
  expect_match(out, "1 item-judge profile was incomplete", fixed = TRUE)
  d$rating[d$item == "I2" & d$rater == 2 & d$construct == "C"] <- NA
  expect_match(flat(rating_validity(d)),
               "2 item-judge profiles were incomplete", fixed = TRUE)
})

test_that("results carry the corrected degrees of freedom of the screening p", {
  fit <- rating_validity(rating_data())
  r <- fit$results
  expect_true(all(c("df1_gg", "df2_gg") %in% names(r)))
  expect_equal(r$df1_gg, r$epsilon_gg * r$df1)
  expect_equal(r$df2_gg, r$epsilon_gg * r$df2)
  expect_equal(r$p_value,
               stats::pf(r$F, r$df1_gg, r$df2_gg, lower.tail = FALSE))
})

test_that("content_report() carries the F test and its effect size", {
  fit <- rating_validity(rating_data())
  rep <- content_report(fit)
  expect_true(all(c("F test", "partial eta^2", "omnibus p", "contrast p") %in%
                    names(rep)))
  r <- fit$results
  expect_identical(
    rep$`F test`[1],
    sprintf("F(%s, %s) = %s", formatC(r$df1_gg[1], format = "f", digits = 2),
            formatC(r$df2_gg[1], format = "f", digits = 2),
            formatC(r$F[1], format = "f", digits = 2))
  )
  expect_identical(rep$`partial eta^2`[1],
                   sub("^0", "", formatC(r$partial_eta2[1], format = "f",
                                         digits = 2)))
  num <- content_report(fit, format = "data.frame")
  expect_true(all(c("F", "df1_gg", "df2_gg", "partial_eta2") %in% names(num)))

  # An F of Inf has no correction: the plain degrees of freedom are shown.
  d <- expand.grid(item = "I1", rater = 1:5, construct = c("A", "B", "C"),
                   stringsAsFactors = FALSE)
  d$target_construct <- "A"
  d$rating <- c(A = 5, B = 3, C = 2)[d$construct]
  expect_identical(content_report(rating_validity(d))$`F test`,
                   "F(2, 8) = Inf")
})

test_that("the profile figure draws complete-judge means and marks no decision", {
  d <- rating_data()
  d$rating[d$item == "I3" & d$rater != 1 & d$construct == "B"] <- NA
  # I1 loses its high target ratings from judges who are incomplete anyway,
  # so the mean over every target rating differs from the complete-judge mean.
  d$rating[d$item == "I1" & d$rater %in% 1:2 & d$construct == "C"] <- NA
  d$rating[d$item == "I1" & d$rater %in% 1:2 & d$construct == "A"] <- 1
  fit <- rating_validity(d)
  r <- fit$results
  expect_false(isTRUE(all.equal(r$target_mean[1], r$target_mean_complete[1])))

  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_silent(plot(fit, type = "profile"))
  expect_silent(plot(fit, type = "profile", show_legend = FALSE))
  expect_silent(plot(fit, type = "map"))
  expect_silent(plot(fit))

  # Every item without a decision: nothing but crosses, and still no error.
  one <- d[d$rater == 1, ]
  expect_silent(plot(rating_validity(one), type = "profile"))
})

test_that("an item held back by the omnibus test alone is told so", {
  # Two constructs, so F is the square of the paired t: the one-sided contrast
  # p is half the omnibus p, and can pass where the omnibus does not.
  d <- data.frame(
    item = "I1", rater = rep(1:8, 2), construct = rep(c("A", "B"), each = 8),
    rating = c(5, 4, 4, 4, 4, 3, 3, 3,
               3, 3, 3, 3, 3, 3, 3, 4),
    target_construct = "A", stringsAsFactors = FALSE
  )
  fit <- rating_validity(d)
  r <- fit$results
  expect_gt(r$p_value, .05)
  expect_lte(r$max_contrast_p, .05)
  expect_true(r$contrast_pass)
  expect_equal(r$max_contrast_p, r$p_value / 2)
  expect_identical(r$recommendation, "Review")
  expect_identical(r$issue, "Every contrast met, omnibus test not met")
  expect_match(r$interpretation,
               "Every planned contrast met the screening criterion, but the omnibus test did not",
               fixed = TRUE)
  expect_false(grepl("weakest target-orbiting comparison", r$interpretation,
                     fixed = TRUE))
  # The omnibus p does not meet alpha, so its handoff row needs no note.
  h <- content_handoff(fit, keep = c("Supported", "Review"))
  expect_identical(h$item_statistics$note[h$item_statistics$statistic == "p_value"], "")
  expect_match(flat(fit), "0 of 1 item meets the full item-level screening criterion",
               fixed = TRUE)
})

test_that("the handoff says when a contrast, not the omnibus p, held an item back", {
  # A and B are rated alike and C far lower: the omnibus test is significant
  # and the contrast of A against B is not.
  d <- data.frame(
    item = "I1", rater = rep(1:8, 3),
    construct = rep(c("A", "B", "C"), each = 8),
    rating = c(5, 4, 5, 4, 5, 4, 5, 4,
               4, 5, 4, 5, 4, 5, 4, 5,
               1, 2, 1, 2, 2, 1, 1, 2),
    target_construct = "A", stringsAsFactors = FALSE
  )
  good <- rating_data(items = "I2")
  fit <- rating_validity(rbind(d, good[names(d)]))
  r <- fit$results
  expect_lte(r$p_value[1], .05)
  expect_false(r$contrast_pass[1])
  expect_identical(r$recommendation, c("Review", "Retain"))

  h <- content_handoff(fit, keep = c("Supported", "Review"))
  st <- h$item_statistics
  note <- st$note[st$statistic == "p_value"]
  expect_match(note[st$item[st$statistic == "p_value"] == "I1"],
               "This omnibus p meets alpha, but the rule also needs every planned contrast to pass; the largest contrast p = .500.",
               fixed = TRUE)
  expect_identical(note[st$item[st$statistic == "p_value"] == "I2"], "")
  expect_false(anyNA(st$note))
  # Schema 1 is frozen: the same columns as before.
  expect_identical(names(st), names(content_handoff(rating_validity(good))$item_statistics))
})

test_that("the ANOVA printout states the level and adjustment of its contrasts", {
  d <- rating_data()
  expect_match(flat(anova_content(d, alpha = .01)),
               "The contrasts are one-sided (the intended construct rated above the other), at alpha = .01, with no adjustment for the number of contrasts.",
               fixed = TRUE)
  expect_match(flat(anova_content(d, adjust = "holm")),
               "at alpha = .05, with p values Holm-adjusted for the number of contrasts.",
               fixed = TRUE)
  expect_match(flat(anova_content(d)),
               "the other construct with the highest mean rating", fixed = TRUE)
})

test_that("a single orbiting_r named for another construct is refused", {
  d <- rating_data()
  expect_silent(rating_validity(d, orbiting_r = .4))
  expect_silent(rating_validity(d, orbiting_r = c(A = .4)))
  expect_silent(rating_validity(d, orbiting_r = c(" A" = .4)))
  expect_error(rating_validity(d, orbiting_r = c(B = .4)),
               "`orbiting_r` is named 'B', but the only target is 'A'",
               fixed = TRUE)

  sorts <- data.frame(
    item = rep(c("I1", "I2"), each = 10), rater = rep(1:10, 2),
    assigned_construct = c(rep("A", 9), "B", rep("A", 8), "B", "B"),
    target_construct = "A", stringsAsFactors = FALSE
  )
  expect_silent(sort_validity(sorts, orbiting_r = c(A = .4)))
  expect_error(sort_validity(sorts, orbiting_r = c(B = .4)),
               "`orbiting_r` is named 'B', but the only target is 'A'",
               fixed = TRUE)

  # With several targets the names are trimmed, as the target labels are.
  two <- rating_data(items = c("I1", "I2"))
  two$target_construct <- ifelse(two$item == "I2", "B", "A")
  expect_silent(rating_validity(two, orbiting_r = c(" A" = .4, "B " = .5)))
})

test_that("references name the sources of the repeated-measures test", {
  rd <- function(topic) {
    path <- testthat::test_path("..", "..", "man", paste0(topic, ".Rd"))
    skip_if_not(file.exists(path), "man pages are not installed with the tests")
    paste(readLines(path, warn = FALSE), collapse = "\n")
  }
  anova_rd <- rd("anova_content")
  expect_match(anova_rd, "MacKenzie", fixed = TRUE)
  expect_match(anova_rd, "Greenhouse", fixed = TRUE)
  expect_match(anova_rd, "Duncan", fixed = TRUE)
  expect_false(grepl("Halvorsen", anova_rd, fixed = TRUE))
  expect_match(rd("rating_validity"), "MacKenzie", fixed = TRUE)
  expect_match(rd("htd"), "Content validation guidelines", fixed = TRUE)
})

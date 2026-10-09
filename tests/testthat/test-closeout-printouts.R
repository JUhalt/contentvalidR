# Close-out of the printout findings before the 1.0 release candidate: the
# item-sort, construct-rating, judge and planning printouts, and the help
# pages behind them.

co_shown <- function(x, ...) {
  old <- options(width = 80)
  on.exit(options(old), add = TRUE)
  utils::capture.output(print(x, ...))
}

co_flat <- function(x, ...) gsub("[[:space:]]+", " ", paste(co_shown(x, ...), collapse = "\n"))

# A help page as plain text: from the source tree when there is one, from
# the installed help otherwise, with the Rd markup taken off.
co_rd <- function(topic) {
  path <- testthat::test_path("..", "..", "man", paste0(topic, ".Rd"))
  txt <- if (file.exists(path)) {
    paste(readLines(path, warn = FALSE), collapse = " ")
  } else {
    db <- tryCatch(tools::Rd_db("contentvalidR"), error = function(e) NULL)
    rd <- if (is.null(db)) NULL else db[[paste0(topic, ".Rd")]]
    if (is.null(rd)) skip("package documentation is not available")
    paste(as.character(rd), collapse = "")
  }
  for (i in 1:3) txt <- gsub("\\\\[a-zA-Z]+\\{([^{}]*)\\}", "\\1", txt)
  gsub("[[:space:]]+", " ", txt)
}

co_sort_rows <- function(item, n_target, n_other, target = "A", other = "B") {
  data.frame(item = item, rater = seq_len(n_target + n_other),
             target_construct = target,
             assigned_construct = c(rep(target, n_target), rep(other, n_other)),
             stringsAsFactors = FALSE)
}

# One item each for 23, 25, 20 and 14 of 25 judges; I1 (16 of 23) is retained
# at p = .047 with a Wilson interval that reaches below .50.
co_unequal_sort <- function() {
  rbind(co_sort_rows("I1", 16, 7), co_sort_rows("I2", 21, 4),
        co_sort_rows("I3", 17, 3, "B", "A"), co_sort_rows("I4", 12, 2, "B", "A"))
}

# Every judge rates the intended construct 5 or 4 (mean HTC .868) and the
# others 1 or 2.
co_boundary_rating <- function(n5 = 17, n4 = 33) {
  n <- n5 + n4
  rbind(
    data.frame(item = "A1", rater = 1:n, construct = "A", target_construct = "A",
               rating = c(rep(5, n5), rep(4, n4))),
    data.frame(item = "A1", rater = 1:n, construct = "B", target_construct = "A",
               rating = rep(c(1, 2), length.out = n)),
    data.frame(item = "A1", rater = 1:n, construct = "C", target_construct = "A",
               rating = rep(c(2, 1), length.out = n))
  )
}

co_panel <- function() {
  r <- rbind(
    c(4, 4, 3, 4, 3, 2, 3, 2, 4, 3), c(4, 3, 4, 3, 2, 3, 2, 3, 4, 2),
    c(3, 4, 4, 3, 3, 2, 2, 2, 3, 3), c(4, 4, 3, 2, 3, 3, 3, 1, 4, 2),
    c(4, 3, 3, 4, 2, 2, 3, 2, 3, 3), c(3, 4, 4, 3, 3, 3, 2, 3, 4, 1),
    c(4, 4, 4, 4, 3, 2, 3, 2, 4, 3), c(3, 2, 3, 2, 2, 1, 2, 1, 2, 2)
  )
  dimnames(r) <- list(paste0("Judge", 1:8), paste0("Item", 1:10))
  r
}

test_that("the advice beside the Colquitt bands is labeled as the package's", {
  d <- rbind(co_sort_rows("P1", 15, 5), co_sort_rows("P2", 15, 5))
  d$assigned_construct[d$assigned_construct == "B"][c(1, 6)] <- "C"
  fit <- sort_validity(d)
  ev <- fit$scale_summary$evidence
  expect_match(ev, "Moderate band of published scales (Colquitt et al., 2019). A contentvalidR suggestion for that band: review the weaker items before finalizing.",
               fixed = TRUE)
  expect_false(grepl("2019); review", ev, fixed = TRUE))

  out <- co_flat(fit)
  expect_false(grepl("not comparable", out, fixed = TRUE))
  expect_match(out, "their values cannot be compared with each other; their labels can, because each is a percentile position among published scales.",
               fixed = TRUE)

  # Two different bands name the lower one the suggestion is for.
  d2 <- rbind(co_sort_rows("S1", 81, 19), co_sort_rows("S2", 82, 18))
  ev2 <- sort_validity(d2)$scale_summary$evidence
  expect_match(ev2, "(Colquitt et al., 2019). A contentvalidR suggestion for the lower band, Moderate: review",
               fixed = TRUE)

  # The construct-rating evidence follows the same pattern.
  rv <- rating_validity(co_boundary_rating(), scale_min = 1, scale_max = 5)
  expect_match(rv$scale_summary$evidence,
               "(Colquitt et al., 2019). A contentvalidR suggestion for the lower band, Moderate: inspect the weaker items",
               fixed = TRUE)
  # Bands that need no advice carry none.
  strong <- rating_validity(co_boundary_rating(40, 10), scale_min = 1,
                            scale_max = 5)
  expect_false(grepl("suggestion", strong$scale_summary$evidence, fixed = TRUE))
})

test_that("bands resting on items no test could decide carry a caution", {
  d <- data.frame(item = c("A1", "A2", "A3"), rater = 1,
                  target_construct = "A", assigned_construct = "A")
  fit <- sort_validity(d)
  caution <- "No item had enough judges for the exact test to decide it, so this comparison with published scales rests on too few judges to mean much."
  expect_match(co_flat(fit), caution, fixed = TRUE)
  expect_match(co_flat(summary(fit)), caution, fixed = TRUE)
  # A printed caution only: the stored summary is unchanged.
  expect_false(grepl("too few judges to mean much", fit$scale_summary$evidence,
                     fixed = TRUE))
  expect_identical(fit$scale_summary$psa_strength, "Very Strong")

  # With a decided scale beside it, the caution names the undecided one.
  mixed <- rbind(d, co_sort_rows("B1", 18, 2, "B", "A"))
  out <- co_flat(sort_validity(mixed))
  expect_match(out, "A: No item had enough judges", fixed = TRUE)
  expect_false(grepl("B: No item", out, fixed = TRUE))

  # Decided items, and expert judges with no bands, get no such caution.
  ok <- sort_validity(co_unequal_sort())
  expect_false(grepl("to mean much", co_flat(ok), fixed = TRUE))
  expect_false(grepl("to mean much", co_flat(sort_validity(d, judge_type = "expert")),
                     fixed = TRUE))
})

test_that("a retained item whose interval includes p0 is explained", {
  fit <- sort_validity(co_unequal_sort())
  r <- fit$results
  expect_identical(r$recommendation[r$item == "I1"], "Retain")
  expect_lt(r$psa_low[r$item == "I1"], .5)
  out <- co_flat(fit)
  expect_match(out, "I1 is retained although its 95% interval includes p0 = .50: the interval is two-sided, while the exact test is one-sided at alpha = .05. The decision comes from the test.",
               fixed = TRUE)
  # Said only when it happens, and never without an interval.
  clear <- sort_validity(co_sort_rows("C1", 18, 2))
  expect_false(grepl("retained although", co_flat(clear), fixed = TRUE))
  expect_false(grepl("retained although",
                     co_flat(sort_validity(co_unequal_sort(), proportion_ci = "none")),
                     fixed = TRUE))
  # At a stricter p0 the note names that value: 9 of 10 meets p0 = .6, and
  # its interval starts at .596.
  strict <- sort_validity(co_sort_rows("D1", 9, 1), p0 = .6)
  expect_identical(strict$results$recommendation, "Retain")
  expect_match(co_flat(strict), "D1 is retained although its 95% interval includes p0 = .60",
               fixed = TRUE)
})

test_that("the header gives the judges per item when panels differ", {
  out <- co_shown(sort_validity(co_unequal_sort()))
  expect_identical(out[2], "Items: 4 | Judges: 25 (14 to 25 per item) | Target constructs: 2")
  even <- co_shown(sort_validity(co_sort_rows("E1", 18, 2)))
  expect_identical(even[2], "Items: 1 | Judges: 20 | Target constructs: 1")
  # Every item sorted by the same subset of the judges.
  sub <- rbind(co_sort_rows("F1", 15, 3), co_sort_rows("F2", 16, 2))
  sub <- rbind(sub, data.frame(item = "F3", rater = 19:20, target_construct = "A",
                               assigned_construct = "A"))
  sub <- sub[!(sub$item == "F3" & sub$rater == 20), ]
  hdr <- co_shown(sort_validity(sub))[2]
  expect_match(hdr, "Judges: 19 (1 to 18 per item)", fixed = TRUE)
  # An object saved before the range was stored prints the count alone.
  old <- sort_validity(co_unequal_sort())
  old$design$n_judges_min <- NULL
  expect_identical(co_shown(old)[2], "Items: 4 | Judges: 25 | Target constructs: 2")
})

test_that("the help says a p value equal to alpha meets the criterion", {
  # The code's rule, which the help now states.
  expect_true(csv_binom_test(4, 4, alpha = 1 / 16)$passes_chance)
  expect_identical(contentvalidR:::.critical_target_count(4, .5, 1 / 16), 4L)
  expect_match(co_rd("csv_binom_test"),
               "a p equal to alpha counts as meeting it", fixed = TRUE)
  expect_match(co_rd("csv_binom_test"), "multiple of 1 / 2^N", fixed = TRUE)
  expect_match(co_rd("sort_validity"),
               "so a p equal to alpha counts as meeting it", fixed = TRUE)
})

test_that("sort_power's p0 carries Howard and Melloy's caveat", {
  rd <- co_rd("sort_power")
  expect_match(rd, "Howard and Melloy describe .5 as arbitrary and lenient",
               fixed = TRUE)
  expect_match(rd, "such as .6 or .75, chosen before data collection",
               fixed = TRUE)
})

test_that("a column left out for width is not pointed to without saying where it is", {
  long <- do.call(rbind, lapply(1:5, function(i) {
    co_sort_rows(paste0("J", i), 10 + i, 10 - i, "Interpersonal justice",
                 "Informational justice")
  }))
  fit <- sort_validity(long, n_constructs = 4)
  out <- co_flat(fit)
  expect_match(out, "Not shown for width: Competitor.", fixed = TRUE)
  expect_match(out, "The competitor column is not shown above for width: summary(x) names it for each flagged item, and as.data.frame(x) has it for every item.",
               fixed = TRUE)
  # summary(x) does name it.
  expect_match(co_flat(summary(fit)), "strongest competitor: Informational justice",
               fixed = TRUE)
  # Shown, or with nothing to review, the pointer is not needed.
  short <- co_flat(sort_validity(co_sort_rows("K1", 11, 9)))
  expect_false(grepl("not shown above for width", short, fixed = TRUE))
  expect_false(grepl("not shown above for width",
                     co_flat(sort_validity(co_sort_rows("K2", 18, 2,
                                                        "Interpersonal justice",
                                                        "Informational justice"))),
                     fixed = TRUE))
  # The construct-rating printout says the same.
  set.seed(5)
  d <- expand.grid(item = c("A1", "A2"), rater = 1:12,
                   construct = c("Interpersonal justice", "Informational justice",
                                 "Procedural justice"),
                   stringsAsFactors = FALSE)
  d$target_construct <- "Interpersonal justice"
  d$rating <- ifelse(d$construct == d$target_construct,
                     pmin(5, pmax(1, round(stats::rnorm(nrow(d), 3.4, 1)))),
                     pmin(5, pmax(1, round(stats::rnorm(nrow(d), 3.0, 1)))))
  rfit <- rating_validity(d, scale_min = 1, scale_max = 5)
  expect_true(any(rfit$results$recommendation == "Review"))
  rout <- co_flat(rfit)
  expect_match(rout, "Not shown for width: Competitor.", fixed = TRUE)
  expect_match(rout, "The competitor column is not shown above for width",
               fixed = TRUE)

  # The planning table's note says x$table holds the hidden values as rows.
  plan <- co_flat(sort_power(N = c(10, 20, 30),
                             true_p = c(.55, .6, .65, .7, .75, .8)))
  expect_match(plan, "See x$table (one row per panel size and rate) for every column.",
               fixed = TRUE)
})

test_that("a scale mean is never printed as a band minimum it falls below", {
  fit <- rating_validity(co_boundary_rating(), scale_min = 1, scale_max = 5)
  expect_equal(fit$scale_summary$mean_htc, .868)
  expect_identical(fit$scale_summary$htc_strength, "Moderate")
  expect_match(co_flat(fit), "A 1 .868 Moderate .71 Very Strong", fixed = TRUE)
  expect_match(co_flat(summary(fit)), "A 1 1 0 .868 Moderate .71 Very Strong",
               fixed = TRUE)

  # A mean on the minimum itself keeps two decimals and the band it starts.
  on_cut <- rating_validity(co_boundary_rating(7, 13), scale_min = 1,
                            scale_max = 5)
  expect_identical(on_cut$scale_summary$htc_strength, "Strong")
  expect_match(co_flat(on_cut), " .87 Strong ", fixed = TRUE)

  # The item-sort tables follow the same rule.
  s <- sort_validity(rbind(co_sort_rows("S1", 81, 19), co_sort_rows("S2", 82, 18)))
  expect_identical(s$scale_summary$psa_strength, "Moderate")
  expect_match(co_flat(s), "A 2 .815 Moderate .63 Strong", fixed = TRUE)
  expect_match(co_flat(summary(s)), "A 2 2 0 .815 Moderate .63 Strong",
               fixed = TRUE)

  # The benchmark set decides the cut: .815 is not beside a stronger-set cut.
  fmt <- contentvalidR:::.fmt_band_mean
  expect_identical(fmt(.815, "psa"), ".815")
  expect_identical(fmt(.815, "psa", orbiting_r = .6), ".82")
  expect_identical(fmt(c(.8699999, NA), "htc"), c(".8699999", "--"))
  expect_identical(fmt(.87, "htc"), ".87")
})

test_that("HTD's competitor is described by its mean, not as the closest", {
  rd <- co_rd("htd")
  expect_false(grepl("closest", rd, fixed = TRUE))
  expect_match(rd, "The other construct with the highest mean rating is reported beside it as strongest_competitor",
               fixed = TRUE)
})

test_that("anova_content says which judges each of its means uses", {
  rd <- co_rd("anova_content")
  expect_match(rd, "use every available rating of the item", fixed = TRUE)
  expect_match(rd, "use only the judges who rated the item against every construct (n_complete)",
               fixed = TRUE)
  expect_match(rd, "target_mean_complete", fixed = TRUE)
})

test_that("the construct-rating print heads the judge count Judges", {
  set.seed(12)
  d <- expand.grid(item = c("A1", "A2", "B1"), rater = 1:20,
                   construct = c("A", "B", "C"))
  d$target_construct <- ifelse(d$item == "B1", "B", "A")
  d$rating <- ifelse(d$construct == d$target_construct,
                     pmin(5, pmax(1, round(stats::rnorm(nrow(d), 4.5, .6)))),
                     pmin(5, pmax(1, round(stats::rnorm(nrow(d), 2.0, .7)))))
  out <- co_shown(rating_validity(d, scale_min = 1, scale_max = 5))
  head_row <- out[grepl("^  Item ", out)][1]
  expect_match(head_row, "Decision  Judges  HTC", fixed = TRUE)
  expect_false(grepl(" n ", head_row, fixed = TRUE))
  expect_match(paste(out, collapse = " "),
               "Judges: the number who rated the item against every construct.",
               fixed = TRUE)
})

test_that("a judge cut the analyst set is printed as set for this analysis", {
  set_all <- co_flat(judge_validity(co_panel(), lo = 1, hi = 4, severity_cut = 2,
                                    differentiation_cut = 0.4,
                                    fit_min_ratings = 5))
  expect_match(set_all, "severity exceeds 2 logits in either direction",
               fixed = TRUE)
  expect_match(set_all, "The logit severity and scale-use cuts were set for this analysis; the rating-point severity cut is a contentvalidR convention, not a published standard.",
               fixed = TRUE)
  expect_match(set_all, "The flag is a contentvalidR convention; the minimum was set for this analysis.",
               fixed = TRUE)
  expect_false(grepl("These cuts are contentvalidR conventions", set_all,
                     fixed = TRUE))

  defaults <- co_flat(judge_validity(co_panel(), lo = 1, hi = 4))
  expect_match(defaults, "severity exceeds 1 logit in either direction",
               fixed = TRUE)
  expect_match(defaults, "These cuts are contentvalidR conventions, not published standards.",
               fixed = TRUE)
  expect_match(defaults, "The flag and the minimum are contentvalidR conventions.",
               fixed = TRUE)

  # A cut equal to its default is the convention however it was given.
  same <- co_flat(judge_validity(co_panel(), lo = 1, hi = 4, severity_cut = 1,
                                 severity_raw_cut = 0.75))
  expect_match(same, "These cuts are contentvalidR conventions", fixed = TRUE)

  every <- co_flat(judge_validity(co_panel(), lo = 1, hi = 4, severity_cut = 2,
                                  severity_raw_cut = 1,
                                  differentiation_cut = 0.4))
  expect_match(every, "These cuts were set for this analysis.", fixed = TRUE)

  src <- contentvalidR:::.judge_cut_source
  expect_identical(src(c(a = "severity", b = "scale-use"), c(a = TRUE, b = FALSE)),
                   "The scale-use cut was set for this analysis; the severity cut is a contentvalidR convention, not a published standard.")
})

test_that("content_structure's k default is documented as the code applies it", {
  set.seed(3)
  S <- matrix(stats::runif(144, 1, 5), 12, 12)
  S <- (S + t(S)) / 2
  diag(S) <- 5
  expect_identical(content_structure(S, membership = rep("U", 12))$settings$k, 2L)
  expect_match(co_rd("content_structure"),
               "or 2 when no blueprint is supplied or it names fewer than two cells",
               fixed = TRUE)
})

test_that("item-sort and construct-rating say the same thing for expert judges", {
  sentence <- "Colquitt benchmark labels are not applied because the analysis was marked as using expert judges."
  s <- sort_validity(co_sort_rows("X1", 18, 2), judge_type = "expert")
  set.seed(12)
  d <- expand.grid(item = c("A1", "B1"), rater = 1:10,
                   construct = c("A", "B", "C"))
  d$target_construct <- ifelse(d$item == "B1", "B", "A")
  d$rating <- ifelse(d$construct == d$target_construct, 5,
                     pmin(5, pmax(1, round(stats::rnorm(nrow(d), 2.0, .7)))))
  r <- rating_validity(d, scale_min = 1, scale_max = 5, judge_type = "expert")
  for (fit in list(s, r)) {
    expect_match(co_flat(fit), sentence, fixed = TRUE)
    expect_match(co_flat(summary(fit)), sentence, fixed = TRUE)
    expect_match(fit$scale_summary$evidence[1], sentence, fixed = TRUE)
    expect_false(grepl("suppressed", co_flat(fit), fixed = TRUE))
  }
})

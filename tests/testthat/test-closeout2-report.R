# The second close-out of the audit: the report notes, the congruence
# summary, the table's width pointer and the help pages the final review
# found wanting before the 1.0 release candidate.

co2r_shown <- function(x, width = 80, key = TRUE) {
  old <- options(width = width, contentvalidR.show_key = key)
  on.exit(options(old), add = TRUE)
  utils::capture.output(print(x))
}

co2r_flat <- function(x, ...) {
  gsub("[[:space:]]+", " ", paste(co2r_shown(x, ...), collapse = " "))
}

co2r_rd <- function(name) {
  path <- testthat::test_path("..", "..", "man", paste0(name, ".Rd"))
  txt <- if (file.exists(path)) {
    readLines(path, warn = FALSE)
  } else {
    db <- tryCatch(tools::Rd_db("contentvalidR"), error = function(e) NULL)
    rd <- db[[paste0(name, ".Rd")]]
    if (is.null(rd)) character(0) else as.character(rd)
  }
  gsub("[[:space:]]+", " ", paste(txt, collapse = " "))
}

co2r_count <- function(txt, pattern) {
  lengths(regmatches(txt, gregexpr(pattern, txt, fixed = TRUE)))
}

# Eight judges on ten items; Judge8 rates lower than the rest.
co2r_panel <- function() {
  r <- rbind(
    c(4, 4, 3, 4, 3, 2, 3, 2, 4, 3), c(4, 3, 4, 3, 2, 3, 2, 3, 4, 2),
    c(3, 4, 4, 3, 3, 2, 2, 2, 3, 3), c(4, 4, 3, 2, 3, 3, 3, 1, 4, 2),
    c(4, 3, 3, 4, 2, 2, 3, 2, 3, 3), c(3, 4, 4, 3, 3, 3, 2, 3, 4, 1),
    c(4, 4, 4, 4, 3, 2, 3, 2, 4, 3), c(3, 2, 3, 2, 2, 1, 2, 1, 2, 2)
  )
  dimnames(r) <- list(paste0("Judge", 1:8), paste0("Item", 1:10))
  r
}

co2r_congruence <- function() {
  utils::read.csv(system.file("extdata", "expert_congruence_example.csv",
                              package = "contentvalidR"),
                  stringsAsFactors = FALSE)
}

co2r_relevance <- function() {
  d <- utils::read.csv(system.file("extdata", "expert_relevance_example.csv",
                                   package = "contentvalidR"))
  d[setdiff(names(d), "expert")]
}

# ---- 1. The judge report names which cuts were set -----------------------

test_that("the judge report note names the cuts set and the conventions apart", {
  one <- judge_validity(co2r_panel(), lo = 1, hi = 4, severity_cut = 0.5)
  expect_true("Severe" %in% one$results$recommendation)
  note <- attr(content_report(one), "note")
  expect_match(note, "Severe or Lenient = severity beyond 0.5 logits, or beyond 0.75 rating points",
               fixed = TRUE)
  expect_match(note, "The logit severity cut was set for this analysis; the rating-point severity cut is a contentvalidR convention, not a published standard.",
               fixed = TRUE)
  expect_false(grepl("These cuts were set", note, fixed = TRUE))
  # The same split as the printout.
  expect_match(co2r_flat(one), "The logit severity cut was set for this analysis; the rating-point severity",
               fixed = TRUE)

  # A fit bound at its default is not said to be set for the analysis.
  two <- judge_validity(co2r_panel(), lo = 1, hi = 4, severity_cut = 2,
                        differentiation_cut = 0.4, fit_min_ratings = 5)
  expect_true(all(c("Erratic", "Severe") %in% two$results$recommendation))
  note2 <- attr(content_report(two), "note")
  expect_match(note2, "Erratic = infit or outfit above 1.5, on at least 5 scored decisions.",
               fixed = TRUE)
  expect_match(note2, "The logit severity and scored-decisions cuts were set for this analysis; the rating-point severity and mean-square cuts are contentvalidR conventions, not published standards.",
               fixed = TRUE)

  # Every cut at its default.
  def <- attr(content_report(judge_validity(co2r_panel(), lo = 1, hi = 4)),
              "note")
  expect_match(def, "These cuts are contentvalidR conventions, not published standards.",
               fixed = TRUE)

  # One cut stated: one cut named.
  src <- contentvalidR:::.judge_cut_source
  expect_identical(src(c(differentiation = "scale-use"), c(differentiation = TRUE)),
                   "This cut is a contentvalidR convention, not a published standard.")
  expect_identical(src(c(differentiation = "scale-use"), c(differentiation = FALSE)),
                   "This cut was set for this analysis.")
  crit <- contentvalidR:::.report_judge_criterion(
    list(severity_cut = 1, severity_raw_cut = 0.75, lo = 1, hi = 4,
         differentiation_cut = 0.4, fit_range = c(0.5, 1.5),
         fit_min_ratings = 30L),
    "Low differentiation")
  expect_identical(crit, paste("Low differentiation = scale use below 0.40.",
                               "This cut was set for this analysis."))
})

# ---- 2. The congruence summary states only a criterion an item met -------

test_that("a target-only congruence summary states no criterion and its own word", {
  cg <- co2r_congruence()
  ta <- cg[cg$objective == "A" & cg$target_objective == "A", ]
  fit <- expert_validity(ta, mode = "congruence")
  expect_identical(fit$results$recommendation, "Target described")
  s <- co2r_flat(summary(fit))
  expect_match(s, "Congruent: 0 of 1 | Review: 0 of 1 | Target described: 1",
               fixed = TRUE)
  expect_false(grepl("Descriptive only", s, fixed = TRUE))
  expect_false(grepl("Criterion:", s, fixed = TRUE))
  # The printout and the report say the same.
  expect_false(grepl("Criterion:", co2r_flat(fit), fixed = TRUE))
  expect_false(grepl("Congruent =", attr(content_report(fit), "note"),
                     fixed = TRUE))

  # A fit with decisions keeps its criterion line.
  full <- co2r_flat(summary(expert_validity(cg, mode = "congruence")))
  expect_match(full, "Criterion: IOC at or above .70, the criterion Rovinelli and Hambleton applied.",
               fixed = TRUE)
  # Without targets every item is Descriptive only, under that word.
  un <- expert_validity(cg[setdiff(names(cg), "target_objective")],
                        mode = "congruence")
  us <- co2r_flat(summary(un))
  expect_match(us, "Descriptive only: 3", fixed = TRUE)
  expect_false(grepl("Criterion:", us, fixed = TRUE))
})

# ---- 3. The congruence competitor is the highest mean, not the closest ---

test_that("congruence text names the competitor by its mean, never as closest", {
  fit <- expert_validity(co2r_congruence(), mode = "congruence")
  meaning <- contentvalidR:::.decision_meanings("congruence")
  expect_match(meaning[["Review"]], "the other objective with the highest mean rating",
               fixed = TRUE)
  expect_false(any(grepl("closest", meaning, fixed = TRUE)))
  note <- attr(content_report(fit), "note")
  expect_match(note, "Competitor mean = the same for the other objective with the highest mean.",
               fixed = TRUE)
  expect_false(grepl("closest", note, fixed = TRUE))
  out <- co2r_flat(fit)
  expect_false(grepl("closest", out, fixed = TRUE))
  expect_match(out, "compares with the other objective with the highest mean rating",
               fixed = TRUE)
})

# ---- 4. The item-sort report explains a retained interval reaching p0 ----

test_that("the item-sort report note explains a retained interval that reaches p0", {
  d <- rbind(
    data.frame(item = "I1", rater = 1:23, target_construct = "A",
               assigned_construct = c(rep("A", 16), rep("B", 7))),
    data.frame(item = "I2", rater = 1:23, target_construct = "B",
               assigned_construct = c(rep("B", 22), "A"))
  )
  fit <- sort_validity(d)
  expect_identical(fit$results$recommendation, c("Retain", "Retain"))
  expect_lte(fit$results$psa_low[1], 0.5)
  sentence <- paste("I1 is retained although its 95% interval includes",
                    "p0 = .50: the interval is two-sided, while the exact",
                    "test is one-sided at alpha = .05. The decision comes",
                    "from the test.")
  note <- attr(content_report(fit), "note")
  expect_match(note, sentence, fixed = TRUE)
  # The same sentence as the printout, and in the Markdown note.
  expect_match(co2r_flat(fit), sentence, fixed = TRUE)
  md <- gsub("[[:space:]]+", " ",
             paste(content_report(fit, format = "markdown"), collapse = " "))
  expect_match(md, sentence, fixed = TRUE)

  # No such row, no such sentence.
  clear <- attr(content_report(sort_validity(d[d$item == "I2", ])), "note")
  expect_false(grepl("is retained although", clear, fixed = TRUE))
})

# ---- 5. The Markdown stub is left-aligned --------------------------------

test_that("the Markdown rule left-aligns the stub when items are numbered", {
  rel <- co2r_relevance()
  names(rel) <- as.character(seq_along(rel))
  md <- content_report(expert_validity(rel, lo = 1, hi = 4, seed = 1),
                       format = "markdown")
  expect_match(md[3], "^\\| 1 \\| ")
  expect_identical(md[2], "| :--- | ---: | ---: | ---: | ---: | ---: | ---: | :--- |")
  d <- data.frame(a = c("1", "2"), b = c(".50", ".60"), stringsAsFactors = FALSE)
  expect_identical(contentvalidR:::.as_markdown_table(d)[2], "| :--- | ---: |")
})

# ---- 6. A shared heading left out for width says whose it is -------------

test_that("columns left out for width that share a heading are named by estimate", {
  R2 <- co2r_relevance()
  R2$Item4[6:8] <- NA
  R2$Item5[3:8] <- NA
  fit <- expert_validity(R2, lo = 1, hi = 4, seed = 1, na.rm = TRUE)
  for (x in list(fit, summary(fit))) {
    out <- co2r_flat(x, width = 60)
    expect_match(out, "Not shown for width: 95% CI for V, 95% CI for I-CVI, Kappa.",
                 fixed = TRUE)
    expect_false(grepl("95% CI, 95% CI", out, fixed = TRUE))
  }
  # In the report one interval is shown; the other is still named.
  rep <- co2r_flat(content_report(fit), width = 60)
  expect_match(rep, "Not shown for width: 95% CI for I-CVI, Kappa.", fixed = TRUE)

  # A heading no other column shares keeps its plain name.
  tab <- data.frame(item = "I1", V = ".50", ci = "[.10, .90]",
                    kappa = paste(rep("x", 70), collapse = ""),
                    stringsAsFactors = FALSE, check.names = FALSE)
  names(tab)[3] <- "95% CI"
  old <- options(width = 60)
  on.exit(options(old), add = TRUE)
  plain <- utils::capture.output(contentvalidR:::.print_table(tab))
  expect_true(any(grepl("Not shown for width: Kappa.", plain, fixed = TRUE)))
  expect_false(any(grepl("Kappa for", plain, fixed = TRUE)))
})

# ---- 7-10. Help pages ----------------------------------------------------

test_that("?content_handoff lists every work it cites, as ?delphi_validity does", {
  ch <- co2r_rd("content_handoff")
  dv <- co2r_rd("delphi_validity")
  skip_if(!nzchar(ch) || !nzchar(dv), "package documentation is not available")
  refs <- c(
    "Chaffin, W. W., & Talley, W. K. (1980). Individual stability in Delphi studies.",
    "Dajani, J. S., Sincoff, M. Z., & Talley, W. K. (1979). Stability and agreement criteria for the termination of Delphi studies.",
    "Scheibe, M., Skutsch, M., & Schofer, J. (2002). Experiments in Delphi methodology.",
    "(Original work published 1975)",
    "10.1016/0040-1625(80)90074-8",
    "10.1016/0040-1625(79)90007-6"
  )
  for (r in refs) {
    expect_match(ch, r, fixed = TRUE)
    expect_match(dv, r, fixed = TRUE)
  }
  expect_match(ch, "Lynn, M. R. (1986).", fixed = TRUE)
})

test_that("?expert_validity describes cvi_criterion and kappa_quality once", {
  ev <- co2r_rd("expert_validity")
  skip_if(!nzchar(ev), "package documentation is not available")
  expect_identical(co2r_count(ev, "Cicchetti and Sparrow (1981) and Fleiss (1981)"), 1L)
  expect_identical(co2r_count(ev, "decides nothing"), 1L)
  expect_false(grepl("also holds \\code{cvi_criterion}", ev, fixed = TRUE))
  expect_match(ev, "as cited in Polit et al. (2007), who apply them to modified kappa",
               fixed = TRUE)
  expect_match(ev, "It is shown for reading: the decision compares counts.",
               fixed = TRUE)
})

test_that("?contentvalid-methods says what summary(compare_rounds())$changed holds", {
  rd <- co2r_rd("contentvalid-methods")
  skip_if(!nzchar(rd), "package documentation is not available")
  expect_match(rd, "changed status between the first and last rounds, entered or left, or appeared only in between",
               fixed = TRUE)
  # As the code keeps them: a unit added or removed is listed.
  m1 <- cbind(I1 = c(4, 4, 4, 3, 4), I2 = c(4, 3, 4, 4, 4))
  m2 <- cbind(I1 = c(4, 4, 4, 3, 4), I3 = c(4, 3, 4, 4, 4))
  e1 <- expert_validity(m1, lo = 1, hi = 4, agreement = "none")
  e2 <- expert_validity(m2, lo = 1, hi = 4, agreement = "none")
  ch <- summary(compare_rounds(e1, e2))$changed
  expect_setequal(ch$change, c("Added", "Removed"))
})

test_that("?contentvalid-methods names the results with no print() method", {
  rd <- co2r_rd("contentvalid-methods")
  skip_if(!nzchar(rd), "package documentation is not available")
  expect_false(grepl("Every contentvalidR result has a \\code{print()} method, and",
                     rd, fixed = TRUE))
  for (fn in c("qfactor_content", "simulate_csv_power", "simulate_anova_power")) {
    expect_match(rd, fn, fixed = TRUE)
  }
  expect_match(rd, "returns a plain list", fixed = TRUE)
  expect_match(rd, "return a number", fixed = TRUE)
  # As the code behaves: no class of their own, so no print() method.
  expect_identical(class(simulate_csv_power(N = 20, true_p = 0.8, reps = 20)),
                   "numeric")
  ratings <- utils::read.csv(system.file("extdata", "rating_example.csv",
                                         package = "contentvalidR"),
                             stringsAsFactors = FALSE)
  expect_identical(class(qfactor_content(ratings, seed = 1)), "list")
})

# ---- 12. The G-study interpretation names a default cut as a criterion ----

test_that("gtheory_content() calls the default cut a criterion, a changed one set", {
  def <- gtheory_content(co2r_panel())
  expect_identical(def$status, "Supported")
  expect_match(def$interpretation, "at or above the .80 criterion.", fixed = TRUE)
  expect_false(grepl("set for this analysis", def$interpretation, fixed = TRUE))
  expect_match(co2r_flat(def), "(criterion: Phi >= .80, a contentvalidR convention)",
               fixed = TRUE)

  low <- gtheory_content(co2r_panel(), phi_cut = 0.5)
  expect_match(low$interpretation, "at or above the .50 set for this analysis.",
               fixed = TRUE)
  expect_match(co2r_flat(low), "(criterion: Phi >= .50, set for this analysis)",
               fixed = TRUE)
  high <- gtheory_content(co2r_panel(), phi_cut = 0.95)
  expect_identical(high$status, "Review")
  expect_match(high$interpretation, "below the .95 set for this analysis.",
               fixed = TRUE)
  # A default given another way is still the convention.
  same <- gtheory_content(co2r_panel(), phi_cut = 4 / 5)
  expect_match(same$interpretation, "the .80 criterion", fixed = TRUE)
})

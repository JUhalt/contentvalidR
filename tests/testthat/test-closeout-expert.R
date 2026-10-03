# The expert-panel printouts, the planning print and content_report(): the
# findings the final audit check left open before the 1.0 release candidate.

closeout_shown <- function(x, width = 80, key = TRUE, ...) {
  old <- options(width = width, contentvalidR.show_key = key)
  on.exit(options(old), add = TRUE)
  utils::capture.output(print(x, ...))
}

closeout_flat <- function(x, ...) {
  gsub("[[:space:]]+", " ", paste(closeout_shown(x, ...), collapse = " "))
}

closeout_header <- function(lines, first) {
  lines[grepl(paste0("^  ", first, " "), lines)][1]
}

# Eight experts on five items: Item4 rated by five, Item5 by two.
closeout_unequal <- function() {
  m <- cbind(
    Item1 = c(4, 3, 2, 4, 3, 2, 3, 2),
    Item2 = c(4, 4, 3, 4, 4, 3, 4, 4),
    Item3 = c(3, 4, 2, 4, 3, 3, 2, 4),
    Item4 = c(NA, NA, NA, 3, 4, 2, 4, 3),
    Item5 = c(NA, NA, NA, NA, NA, NA, 4, 3)
  )
  expert_validity(m, lo = 1, hi = 4, na.rm = TRUE, seed = 1, agreement_B = 50)
}

# Nine experts; I2 falls short of 7 of 9.
closeout_nine <- function(...) {
  m <- cbind(I1 = c(4, 4, 3, 4, 4, 3, 4, 4, 4),
             I2 = c(1, 1, 1, 1, 1, 4, 3, 4, 3),
             I3 = c(4, 3, 4, 4, 4, 4, 3, 4, 4))
  expert_validity(m, lo = 1, hi = 4, agreement = "none", ...)
}

closeout_rd <- function(name) {
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

closeout_long <- function(m, round) {
  data.frame(expert = paste0("E", seq_len(nrow(m))),
             item = rep(colnames(m), each = nrow(m)), round = round,
             rating = as.vector(m), stringsAsFactors = FALSE)
}

closeout_delphi <- function(stability, ...) {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 3, 4, 2, 4), S2 = c(3, 4, 3, 2, 4, 3, 2, 1),
              S3 = rep(4, 8), S4 = c(4, 3, 4, 2, 4, 3, 4, 4))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 2, 4), S2 = c(4, 4, 4, 4, 4, 3, 2, 2),
              S3 = rep(4, 8), S4 = c(4, 3, 4, 2, 4, 3, 4, 4))
  delphi_validity(rbind(closeout_long(r1, 1), closeout_long(r2, 2)),
                  lo = 1, hi = 4, consensus_threshold = .75,
                  stability = stability, ...)
}

# ---- 1. The per-item criterion column survives a narrow console ----------

test_that("the relevance print keeps I-CVI needed at 80 columns and explains what it shows", {
  fit <- closeout_unequal()
  lines <- closeout_shown(fit)
  head <- closeout_header(lines, "Item")
  expect_match(head, "I-CVI needed", fixed = TRUE)
  expect_false(any(grepl("Not shown for width: .*I-CVI needed", lines)))
  out <- gsub("[[:space:]]+", " ", paste(lines, collapse = " "))
  expect_match(out, "I-CVI needed: the criterion of Lynn (1986) for each item's panel size.",
               fixed = TRUE)
  expect_true(all(nchar(lines, type = "width") <= 80L))
  # Item4 was held to 5 of 5 experts, which the reader can now see.
  row4 <- lines[grepl("^  Item4 ", lines)]
  expect_match(row4, "1[.]00$")
  # Kappa gave way to the criterion, so it is neither explained nor pointed
  # to.
  expect_false(grepl("Kappa", head, fixed = TRUE))
  expect_match(out, "Not shown for width: Kappa", fixed = TRUE)
  expect_false(grepl("Kappa is modified kappa", out, fixed = TRUE))
  expect_false(grepl("(the kappa column)", out, fixed = TRUE))
  expect_false(grepl("Kappa -- Modified kappa", out, fixed = TRUE))
  # On a wide console every column is shown and explained.
  wide <- closeout_flat(fit, width = 200)
  expect_match(wide, "Kappa is modified kappa", fixed = TRUE)
  expect_match(wide, "(the kappa column)", fixed = TRUE)
  expect_match(wide, "Kappa -- Modified kappa", fixed = TRUE)
})

# ---- 2. Essentiality states its test whatever the panel sizes ------------

test_that("essentiality with mixed panel sizes states alpha, the test and its source", {
  fit <- expert_validity(c(10, 14), mode = "essentiality", N = c(10, 16),
                         alpha = 0.01)
  for (key in c(TRUE, FALSE)) {
    out <- closeout_flat(fit, key = key)
    expect_match(out, "alpha = .01", fixed = TRUE)
    expect_match(out, "exact one-sided binomial test", fixed = TRUE)
    expect_match(out, "(Ayre & Scally, 2014)", fixed = TRUE)
    expect_match(out, "Needed: the fewest essential ratings", fixed = TRUE)
  }
  # One panel size keeps its count sentence.
  one <- closeout_flat(expert_validity(c(10, 8), mode = "essentiality", N = 12))
  expect_match(one, "With 12 experts, an item needs at least 10 rating it essential",
               fixed = TRUE)
  # A panel too small for the test still names it.
  small <- closeout_flat(expert_validity(c(4, 3), mode = "essentiality", N = 4))
  expect_match(small, "Each decision uses the exact one-sided binomial test at alpha = .05 (Ayre & Scally, 2014).",
               fixed = TRUE)
  # So does the summary, where the flagged table gives each item's count.
  s <- closeout_flat(summary(expert_validity(c(10, 9, 3), mode = "essentiality",
                                             N = c(10, 16, 4), alpha = 0.01)))
  expect_match(s, "Each decision uses the exact one-sided binomial test at alpha = .01 (Ayre & Scally, 2014).",
               fixed = TRUE)
  expect_match(s, "Needed = the fewest essential ratings", fixed = TRUE)
})

# ---- 3. summary() states the criterion, the scale and the cut ------------

test_that("the relevance summary states the scale, the cut and the criterion", {
  fit <- closeout_nine()
  for (key in c(TRUE, FALSE)) {
    out <- closeout_flat(summary(fit), key = key)
    expect_match(out, "Scale: 1 to 4 | Relevant: a rating of 3 or higher",
                 fixed = TRUE)
    expect_match(out, "I-CVI criterion for 9 experts: 7 agreeing (.78), following Lynn (1986).",
                 fixed = TRUE)
  }
  cut <- closeout_flat(summary(closeout_nine(relevance_cut = 2.5)))
  expect_match(cut, "Relevant: a rating of 2.5 or higher", fixed = TRUE)

  # With panels of several sizes the flagged table gives each item's
  # criterion, also when the flagged items share one size.
  m <- cbind(A = c(4, 4, 4, 4, 4, 3, 4, 3), B = c(2, 2, 2, 4, 4, 4, 4, 4),
             C = c(NA, NA, NA, 4, 4, 4, 4, 3))
  mixed <- expert_validity(m, lo = 1, hi = 4, na.rm = TRUE, agreement = "none")
  expect_identical(summary(mixed)$flagged$item, "B")
  lines <- closeout_shown(summary(mixed))
  expect_match(closeout_header(lines, "Item"), "I-CVI needed", fixed = TRUE)
  out <- gsub("[[:space:]]+", " ", paste(lines, collapse = " "))
  expect_match(out, "I-CVI criterion: the count of Lynn (1986) for each item's panel size, from 5 to 8 experts here.",
               fixed = TRUE)
  expect_match(out, "I-CVI needed = the I-CVI the criterion asks of the item's panel size",
               fixed = TRUE)
})

# ---- 4. Kappa above .74 is said once, as a consequence -------------------

test_that("the relevance verdict no longer repeats the kappa band", {
  fit <- closeout_nine()
  count <- function(txt, pattern) {
    lengths(regmatches(txt, gregexpr(pattern, txt, fixed = TRUE)))
  }
  # With the key, its decision legend says it; without, the criterion note.
  out <- closeout_flat(fit)
  expect_match(out, "2 of 3 items meet the I-CVI criterion.", fixed = TRUE)
  expect_false(grepl("with strong support (modified kappa", out, fixed = TRUE))
  expect_identical(count(out, "puts modified kappa above .74") +
                     count(out, "criterion puts it above .74"), 1L)
  expect_match(out, "Kappa is modified kappa, read as excellent above .74 (Polit et al., 2007).",
               fixed = TRUE)
  bare <- closeout_flat(fit, key = FALSE)
  expect_match(bare, "2 of 3 items meet the I-CVI criterion.", fixed = TRUE)
  expect_identical(count(bare, "meeting the I-CVI criterion puts it above .74"), 1L)
  expect_identical(count(bare, "above .74"), 1L)
  r <- fit$results
  expect_false(any(grepl("excellent chance-corrected agreement",
                         r$interpretation, fixed = TRUE)))
  expect_true(all(grepl("which also puts its modified kappa above .74",
                        r$interpretation[r$recommendation == "Strong support"],
                        fixed = TRUE)))
  # The interpretation is true of every passing item.
  expect_true(all(r$kappa_mod[r$recommendation == "Strong support"] > .74))
})

# ---- 5. Reference lists --------------------------------------------------

test_that("the expert help pages give complete references", {
  ev <- closeout_rd("expert_validity")
  skip_if(!nzchar(ev), "package documentation is not available")
  expect_match(ev, "Aiken, L. R. (1980). Content validity and reliability of single items or questionnaires.",
               fixed = TRUE)
  expect_match(ev, "Is the CVI an acceptable indicator of content validity? Appraisal and recommendations.",
               fixed = TRUE)
  ep <- closeout_rd("expert_power")
  expect_match(ep, "Critical values for Lawshe's content validity ratio: Revisiting the original methods of calculation.",
               fixed = TRUE)
  expect_match(ep, "10.1097/00006199-198611000-00017", fixed = TRUE)
})

# ---- 6. One name for the raters ------------------------------------------

test_that("expert-panel printouts call the raters experts", {
  out <- closeout_flat(closeout_nine())
  expect_match(out, "Mean Aiken's V: ", fixed = TRUE)
  expect_match(out, "Experts per item: 9", fixed = TRUE)
  expect_false(grepl("Mean Aiken V", out, fixed = TRUE))

  M <- cbind(Item1 = c(1, 1, 1, 1), Item2 = c(1, 1, 1, 0))
  cv <- closeout_flat(cvi(M))
  expect_match(cv, "Experts per item: 4", fixed = TRUE)
  expect_match(cv, "Agree: experts rating the item relevant", fixed = TRUE)
  expect_match(cv, "this many experts would agree by chance", fixed = TRUE)
  expect_false(grepl("Judges per item", cv, fixed = TRUE))

  io <- closeout_shown(ioc(data.frame(item = "I1", judge = rep(1:3, 2),
                                      objective = rep(c("A", "B"), each = 3),
                                      score = c(1, 1, 1, 0, -1, 0))))
  expect_match(closeout_header(io, "Item"), "Experts", fixed = TRUE)
  expect_false(any(grepl("Judges", io, fixed = TRUE)))
})

# ---- 7. The kappa band below .40 -----------------------------------------

test_that("modified kappa below .40 is in the Poor band", {
  k <- c(.20, .399, .40, .60, .74, .75, NA)
  expect_identical(contentvalidR:::.kappa_quality(k),
                   c("Poor", "Poor", "Fair", "Good", "Good", "Excellent", NA))
  fit <- closeout_nine()
  expect_identical(fit$results$kappa_quality[fit$results$item == "I2"], "Poor")
  ev <- closeout_rd("expert_validity")
  skip_if(!nzchar(ev), "package documentation is not available")
  expect_match(ev, "Cicchetti and Sparrow (1981) and Fleiss (1981)", fixed = TRUE)
  expect_match(ev, "below .40", fixed = TRUE)
})

# ---- 8. Congruence notes for what is shown -------------------------------

test_that("an all-target-described congruence print explains only its columns", {
  d <- data.frame(item = rep(c("I1", "I2"), each = 3), judge = rep(1:3, 2),
                  objective = "A", target_objective = "A",
                  score = c(1, 1, 0, 1, 1, 1))
  fit <- expert_validity(d, mode = "congruence")
  out <- closeout_flat(fit)
  expect_match(out, "Mean: the experts' mean rating on the target objective (-1 to 1).",
               fixed = TRUE)
  expect_false(grepl("IOC: the index", out, fixed = TRUE))
  expect_false(grepl("Competitor mean:", out, fixed = TRUE))
  expect_false(grepl("Margin:", out, fixed = TRUE))
  expect_false(grepl("IOC -- Index of item-objective congruence", out, fixed = TRUE))
  rep <- attr(content_report(fit), "note")
  expect_false(grepl("Congruent =", rep, fixed = TRUE))
  expect_match(rep, "Target described = ", fixed = TRUE)
})

test_that("an untargeted congruence report explains Descriptive only", {
  ioc_d <- utils::read.csv(system.file("extdata", "expert_congruence_example.csv",
                                       package = "contentvalidR"),
                           stringsAsFactors = FALSE)
  untargeted <- expert_validity(ioc_d[setdiff(names(ioc_d), "target_objective")],
                                mode = "congruence")
  note <- attr(content_report(untargeted), "note")
  expect_false(grepl("Congruent =", note, fixed = TRUE))
  expect_match(note, "Descriptive only = no intended objective was given",
               fixed = TRUE)
  md <- content_report(untargeted, format = "markdown")
  expect_false(any(grepl("Congruent =", md, fixed = TRUE)))
  # A targeted fit still states its criterion.
  targeted <- attr(content_report(expert_validity(ioc_d, mode = "congruence")),
                   "note")
  expect_match(targeted, "Congruent = IOC at or above .70", fixed = TRUE)
})

# ---- 9. The planner says it is the package's own -------------------------

test_that("the expert_power() printout labels the planning calculation", {
  for (crit in c("cvi", "cvr")) {
    out <- closeout_flat(expert_power(n_experts = c(6, 9, 12), prob = 0.9,
                                      criterion = crit))
    expect_match(out, "This is a contentvalidR planning tool, not a published power method",
                 fixed = TRUE)
  }
  expect_match(closeout_flat(expert_power(n_experts = 6:8, prob = .9,
                                          criterion = "cvr")),
               "the exact test of Ayre and Scally (2014)", fixed = TRUE)
})

# ---- 10. No sentence about an interval that was not computed -------------

test_that("proportion_ci = 'none' prints no sentence about an I-CVI interval", {
  out <- closeout_flat(closeout_nine(proportion_ci = "none"))
  expect_false(grepl("Each 95% CI follows its estimate", out, fixed = TRUE))
  expect_false(grepl("the proportion interval named below", out, fixed = TRUE))
  expect_match(out, "The 95% CI follows Aiken's V: a Penfield-Giacobbi score interval.",
               fixed = TRUE)
  expect_match(out, "Intervals for proportion indices were not computed.",
               fixed = TRUE)
  both <- closeout_flat(closeout_nine())
  expect_match(both, "Each 95% CI follows its estimate", fixed = TRUE)
})

# ---- 11. content_report() ------------------------------------------------

test_that("the Markdown rule aligns text left and numbers right", {
  sorts <- utils::read.csv(system.file("extdata", "sort_example.csv",
                                       package = "contentvalidR"),
                           stringsAsFactors = FALSE)
  md <- content_report(sort_validity(sorts), format = "markdown")
  expect_identical(md[1], "| Item | Target | Judges | Competitor | Psa | 95% CI | Csv | *p* | Decision |")
  expect_identical(md[2], "| :--- | :--- | ---: | :--- | ---: | ---: | ---: | ---: | :--- |")
  # A missing cell, an em dash in Markdown, does not decide the alignment.
  d <- data.frame(a = c("x", "y"), b = c(".50", "—"), stringsAsFactors = FALSE)
  expect_identical(contentvalidR:::.as_markdown_table(d)[2], "| :--- | ---: |")
})

test_that("?content_report says how to render the Markdown and what p = 0 means", {
  rd <- closeout_rd("content_report")
  skip_if(!nzchar(rd), "package documentation is not available")
  expect_match(rd, 'results = "asis"', fixed = TRUE)
  expect_match(rd, "one below .0005 becomes 0", fixed = TRUE)
  expect_match(rd, "critical_ne", fixed = TRUE)
})

test_that("the essentiality data frame keeps the counts its decision compares", {
  fe <- expert_validity(c(11, 9, 6), mode = "essentiality", N = 12)
  tab <- content_report(fe, format = "data.frame")
  expect_true(all(c("N", "ne", "critical_ne", "cvr", "p_value") %in% names(tab)))
  expect_equal(tab$ne, c(11, 9, 6))
  expect_equal(tab$critical_ne, rep(10, 3))
})

test_that("the Delphi report carries the stable decision and which way it reads", {
  ind <- content_report(closeout_delphi("chisq_individual", B = 0))
  expect_true("stable" %in% names(ind))
  fit_ind <- closeout_delphi("chisq_individual", B = 0)
  expect_identical(ind$stable,
                   ifelse(is.na(fit_ind$results$stable), "--",
                          ifelse(fit_ind$results$stable, "yes", "no")))
  expect_match(attr(ind, "note"), "Stable = p below alpha = .05", fixed = TRUE)

  grp <- content_report(closeout_delphi("chisq_group", B = 0))
  expect_match(attr(grp, "note"), "Stable = p at or above alpha = .05",
               fixed = TRUE)
  # S3 had every rating in one category in both rounds: no p, and stable.
  expect_identical(grp$stable[grp$item == "S3"], "yes")
  expect_match(attr(grp, "note"), "with no p, every rating fell in one category",
               fixed = TRUE)

  pc <- content_report(closeout_delphi("percent_change", B = 0))
  expect_match(attr(pc, "note"), "Stable = net change below .15.", fixed = TRUE)
  expect_true("stable" %in% names(pc))

  # Kappa has no stability rule, so no column.
  kp <- content_report(closeout_delphi("kappa", B = 0))
  expect_false("stable" %in% names(kp))

  # The printed report keeps the column on an 80-column console.
  lines <- closeout_shown(ind)
  expect_match(closeout_header(lines, "Item"), "Stable", fixed = TRUE)
})

test_that("a zero-width interval in a report is explained in its note", {
  fit <- closeout_delphi("kappa", B = 200, seed = 1)
  r <- fit$results
  s4 <- r$item == "S4"
  expect_equal(r$stability_low[s4], r$stability_high[s4])
  rep <- content_report(fit)
  expect_identical(rep$`kappa 95% CI`[rep$item == "S4"], "[1.00, 1.00]")
  note <- attr(rep, "note")
  expect_match(note, "An interval with equal limits (S4) has no width because every resample of the experts gave the same value",
               fixed = TRUE)
  # An interval with width gets no such sentence.
  sorts <- utils::read.csv(system.file("extdata", "sort_example.csv",
                                       package = "contentvalidR"),
                           stringsAsFactors = FALSE)
  expect_false(grepl("equal limits", attr(content_report(sort_validity(sorts)),
                                          "note"), fixed = TRUE))
})

# ---- 12. A defined term is never split -----------------------------------

test_that("the rating report note keeps 'F test' on one line", {
  bound <- contentvalidR:::.bind_phrases("F test = within-judge omnibus test")
  expect_false(grepl("F test", bound, fixed = TRUE))
  expect_match(bound, "F test", fixed = TRUE)
  rating <- utils::read.csv(system.file("extdata", "rating_example.csv",
                                        package = "contentvalidR"),
                            stringsAsFactors = FALSE)
  lines <- closeout_shown(content_report(rating_validity(rating)))
  expect_false(any(grepl("(^|[[:space:]])F$", lines)))
  expect_false(any(grepl("^test = ", trimws(lines))))
  expect_true(any(grepl("F test = within-judge", lines, fixed = TRUE)))
  expect_true(all(nchar(lines, type = "width") <= 80L))
})

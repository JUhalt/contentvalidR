# Tests for branches that covr 4.0.0 found no test running: the reporting,
# the shared print style, the component printouts, the workflow object API,
# the argument checks and the glossary, grouped by the function they
# exercise.

# Everything a print method writes, as one line of text.
flat_print <- function(x) {
  gsub("\\s+", " ", paste(utils::capture.output(print(x)), collapse = " "))
}

delphi_long <- function(m, round) {
  data.frame(expert = paste0("E", seq_len(nrow(m))),
             item = rep(colnames(m), each = nrow(m)), round = round,
             rating = as.vector(m), stringsAsFactors = FALSE)
}

delphi_r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4, 3, 4),
                   S2 = c(2, 3, 2, 1, 3, 2, 2, 3),
                   S3 = c(4, 3, 4, 4, 4, 2, 4, 3))
delphi_r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 3, 4),
                   S2 = c(2, 2, 2, 1, 3, 2, 2, 2),
                   S3 = c(4, 4, 4, 4, 4, 3, 4, 4))

# Six judges rating ten items; J6 rates nearly every item 3.
flat_judge_panel <- function() {
  r <- rbind(c(4, 3, 4, 2, 3, 4, 1, 3, 2, 4), c(4, 3, 3, 2, 3, 4, 2, 3, 1, 4),
             c(3, 3, 4, 2, 4, 4, 1, 3, 2, 3), c(4, 2, 4, 1, 3, 3, 1, 3, 2, 4),
             c(4, 3, 4, 2, 3, 4, 2, 2, 1, 4), c(3, 3, 3, 3, 3, 3, 3, 3, 2, 3))
  dimnames(r) <- list(paste0("J", 1:6), paste0("I", 1:10))
  r
}

# Six judges who agree closely on eight items.
typical_judge_panel <- function() {
  r <- rbind(c(4, 3, 4, 2, 3, 4, 1, 3), c(4, 3, 3, 2, 3, 4, 2, 3),
             c(3, 3, 4, 2, 4, 4, 1, 3), c(4, 2, 4, 1, 3, 3, 1, 3),
             c(4, 3, 4, 2, 3, 4, 2, 2), c(3, 3, 4, 2, 3, 4, 1, 3))
  dimnames(r) <- list(paste0("J", 1:6), paste0("I", 1:8))
  r
}

example_sort <- function() {
  utils::read.csv(system.file("extdata", "sort_example.csv",
                              package = "contentvalidR"),
                  stringsAsFactors = FALSE)
}

example_congruence <- function() {
  utils::read.csv(system.file("extdata", "expert_congruence_example.csv",
                              package = "contentvalidR"),
                  stringsAsFactors = FALSE)
}

# content_report(): the general note under the APA table ----------------------

test_that("a relevance panel over ten experts is told Lynn's 7 of 9 is held", {
  m <- cbind(I1 = rep(4, 11), I2 = rep(3, 11), I3 = c(rep(4, 6), rep(1, 5)))
  fit <- expert_validity(m, mode = "relevance", agreement = "none")
  expect_identical(fit$results$N, rep(11L, 3))
  note <- attr(content_report(fit), "note")
  expect_match(note, paste("held at her 7 of 9 beyond ten experts",
                           "(a contentvalidR extension)."), fixed = TRUE)
  # Ten experts are within Lynn's own table, so the extension is not named.
  ten <- expert_validity(m[1:10, ], mode = "relevance", agreement = "none")
  expect_false(grepl("7 of 9", attr(content_report(ten), "note")))
})

test_that("a congruence criterion other than .70 is reported as set here", {
  fit <- expert_validity(example_congruence(), mode = "congruence",
                         ioc_cut = 0.80)
  # I1 and I3 fall on either side of the cut, so items were decided.
  expect_identical(fit$results$recommendation[c(1, 3)],
                   c("Congruent", "Review"))
  note <- attr(content_report(fit), "note")
  expect_match(note, paste("Congruent = IOC at or above .80, set for this",
                           "analysis; Rovinelli and Hambleton (1977)",
                           "applied .70."), fixed = TRUE)
  default <- expert_validity(example_congruence(), mode = "congruence")
  expect_match(attr(content_report(default), "note"),
               "the criterion Rovinelli and Hambleton (1977) applied.",
               fixed = TRUE)
})

test_that("a Delphi table with no stability column names no paired experts", {
  # S1 is rated only in round 1 and S3 only in round 2, so no item has two
  # consecutive rounds and nothing rests on paired experts.
  d <- rbind(delphi_long(delphi_r1[, "S1", drop = FALSE], 1),
             delphi_long(delphi_r2[, "S3", drop = FALSE], 2))
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  expect_true(all(is.na(fit$results$prop_unchanged)))
  report <- content_report(fit)
  expect_identical(names(report), c("item", "last round", "experts",
                                    "agree", "decision"))
  note <- attr(report, "note")
  expect_match(note, "Consensus = at least 75% of experts agreeing",
               fixed = TRUE)
  expect_false(grepl("Unchanged", note, fixed = TRUE))
  expect_false(grepl("rest on the experts", note, fixed = TRUE))
})

test_that("a flagged-only Delphi report with nothing flagged keeps its note", {
  d <- rbind(delphi_long(delphi_r1[, c("S1", "S3")], 1),
             delphi_long(delphi_r2[, c("S1", "S3")], 2))
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  expect_identical(fit$results$recommendation, c("Consensus", "Consensus"))
  report <- content_report(fit, include = "flagged")
  expect_identical(nrow(report), 0L)
  note <- attr(report, "note")
  expect_match(note, "Consensus = at least 75% of experts agreeing",
               fixed = TRUE)
  expect_false(grepl("rest on the experts", note, fixed = TRUE))
  expect_match(flat_print(report),
               "No units matched the requested selection.", fixed = TRUE)
})

test_that("a judge table with every judge typical states no flag rule", {
  fit <- judge_validity(typical_judge_panel())
  expect_true(all(fit$results$recommendation == "Typical"))
  note <- attr(content_report(fit), "note")
  expect_match(note, "Ratings = items the judge rated.", fixed = TRUE)
  expect_false(grepl("Severe or Lenient =", note, fixed = TRUE))
  expect_false(grepl("Low differentiation =", note, fixed = TRUE))
  expect_false(grepl("convention", note, fixed = TRUE))
})

test_that("the scale-use rule is stated for current and pre-1.0 judge fits", {
  fit <- judge_validity(flat_judge_panel())
  expect_identical(fit$results$recommendation[6], "Low differentiation")
  expect_lt(fit$results$differentiation[6], 0.5)
  rule <- paste("Low differentiation = scale use below 0.50. This cut is a",
                "contentvalidR convention, not a published standard.")
  expect_match(attr(content_report(fit), "note"), rule, fixed = TRUE)
  # A fit saved before 1.0 stored no differentiation_cut; it was 0.5.
  old <- fit
  old$settings$differentiation_cut <- NULL
  expect_match(attr(content_report(old), "note"), rule, fixed = TRUE)
})

test_that("a domain table states the coverage rules its decisions applied", {
  asg <- data.frame(item = paste0("I", 1:8),
                    cell = c(rep("Autonomy", 5), "Competence", "Competence",
                             "Relatedness"))
  fit <- domain_validity(asg, targets = c(Autonomy = 2, Competence = 3,
                                          Relatedness = 3))
  # Autonomy holds 5/8 = .625 of the items, more than twice its expected 2/8;
  # Relatedness holds 1, fewer than min(min_items = 2, target = 3).
  expect_identical(fit$results$recommendation,
                   c("Over-represented", "Covered", "Thinly covered"))
  note <- attr(content_report(fit), "note")
  expect_match(note, paste("Thinly covered = fewer than 2 items (or the",
                           "cell's target, if smaller); Over-represented =",
                           "more than 2 times the expected share."),
               fixed = TRUE)
})

# .as_markdown_table(), which writes content_report(format = "markdown") ------

test_that("a Markdown table of no rows is no lines, not a bare header", {
  # content_report() writes its own line for an empty selection before it
  # gets here, so the helper's guard is checked on the helper.
  md <- contentvalidR:::.as_markdown_table
  expect_identical(md(data.frame(item = character(0))), character(0))
  expect_identical(md(data.frame(item = "I1")),
                   c("| item |", "| :--- |", "| I1 |"))
})

# .choose(), behind every argument with a fixed set of choices ----------------

test_that("a choice that is not a string is refused with the choices listed", {
  fit <- sort_validity(example_sort())
  expect_error(content_report(fit, format = 1),
               paste('`format` must be one of "apa", "data.frame", or',
                     '"markdown", not 1.'), fixed = TRUE)
  expect_error(content_report(fit, format = "latex"),
               paste('`format` must be one of "apa", "data.frame", or',
                     '"markdown", not "latex".'), fixed = TRUE)
})

# .check_unique_names(), through judge_validity() -----------------------------

test_that("a repeated judge or item name is refused with the names", {
  X <- flat_judge_panel()
  rownames(X)[2] <- "J1"
  expect_error(judge_validity(X),
               paste("Each judge needs its own name, but this row name is",
                     "used more than once: J1."), fixed = TRUE)
  X <- flat_judge_panel()
  colnames(X) <- c("A", "A", "B", "B", "C", "C", "D", "E", "F", "G")
  expect_error(judge_validity(X),
               paste("Each item needs its own name, but these column names",
                     "are used more than once: A, B, C."), fixed = TRUE)
})

test_that("more than five repeated names are listed by the first five", {
  X <- cbind(flat_judge_panel(), flat_judge_panel()[, 1:4])
  colnames(X) <- rep(LETTERS[1:7], 2)
  msg <- tryCatch(judge_validity(X), error = conditionMessage)
  listed <- sub("^.*used more than once: ", "", msg)
  expect_match(listed, "^A, B, C, D, E")
  expect_false(grepl("F", listed, fixed = TRUE))
  expect_false(grepl("G", listed, fixed = TRUE))
})

# The shared print style (format_apa.R) ---------------------------------------

test_that("a missing alpha level is written as the missing mark", {
  # .fmt_alpha() writes alpha in every printout and handoff rule.
  expect_identical(contentvalidR:::.fmt_alpha(c(0.05, NA)), c(".05", "--"))
})

test_that("a whole-number proportion setting keeps two decimals", {
  d <- rbind(delphi_long(delphi_r1[, c("S1", "S2")], 1),
             delphi_long(delphi_r2[, c("S1", "S2")], 2))
  none <- delphi_validity(d, lo = 1, hi = 4, B = 0)
  all_agree <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = 1,
                               B = 0)
  cmp <- compare_rounds(none, all_agree)
  ch <- cmp$settings_changes
  expect_identical(ch$setting, "consensus_threshold")
  expect_identical(c(ch$previous, ch$current), c("(not set)", "1.00"))
  expect_false(cmp$comparable)
})

test_that("a table with no columns prints nothing", {
  # Every printout lays out its tables with .print_table(); none passes it a
  # table with no columns, so the guard is checked on the helper.
  out <- utils::capture.output(
    res <- withVisible(contentvalidR:::.print_table(data.frame()))
  )
  expect_identical(out, character(0))
  expect_false(res$visible)
  expect_identical(res$value, character(0))
})

test_that("a component filtered to no rows prints its headings alone", {
  x <- ioc(data.frame(item = "I1", judge = rep(1:3, 2),
                      objective = rep(c("A", "B"), each = 3),
                      score = c(1, 1, 1, 0, -1, 0)))
  none <- x[!is.na(x$ioc) & x$ioc > 1, ]
  expect_s3_class(none, "contentvalid_ioc")
  expect_identical(nrow(none), 0L)
  out <- utils::capture.output(print(none))
  expect_true("  Item  Objective  Experts  Mean  IOC" %in% out)
  expect_false(any(grepl("^  I1", out)))
})

test_that("a table without dimension names prints with a blank stub", {
  # .table_frame() lays out the two-by-two printouts and the blueprint
  # cross-tabulation of content_structure().
  tab <- matrix(c(5, 1, 1, 5), 2,
                dimnames = list(c("Retain", "Not retained"),
                                c("Retain", "Not retained")))
  fr <- contentvalidR:::.table_frame(tab)
  expect_identical(names(fr), c(" ", "Retain", "Not retained"))
  expect_identical(fr[[" "]], c("Retain", "Not retained"))
  expect_identical(fr$Retain, c("5", "1"))
  named <- contentvalidR:::.table_frame(
    table(Pretest1 = c("a", "a", "b"), Pretest2 = c("a", "b", "b"))
  )
  expect_identical(names(named), c("Pretest1", "Pretest2: a", "Pretest2: b"))
})

test_that("a panel too small for the CVR test is named by its size", {
  # One of one is p = .5, and four of four p = 1/16 = .0625: neither
  # reaches .05, while nine of ten does.
  expect_gt(stats::pbinom(3, 4, 0.5, lower.tail = FALSE), 0.05)
  expect_lt(stats::pbinom(8, 10, 0.5, lower.tail = FALSE), 0.05)
  one <- flat_print(cvr(essential = 1, N = 1))
  expect_match(one, "With 1 expert, no count of essential ratings reaches",
               fixed = TRUE)
  four <- flat_print(cvr(essential = c(3, 9), N = c(4, 10)))
  expect_match(four, paste("With 4 or fewer experts, no count of essential",
                           "ratings reaches alpha = .05"), fixed = TRUE)
})

# Component printouts (component_print.R) -------------------------------------

test_that("an item rated against one objective has its missing IOC explained", {
  x <- ioc(data.frame(item = c(rep("I1", 6), rep("I2", 3)),
                      judge = c(1:3, 1:3, 1:3),
                      objective = c(rep("A", 3), rep("B", 3), rep("A", 3)),
                      score = c(1, 1, 1, -1, -1, 0, 1, 1, 0)))
  d <- as.data.frame(x)
  # Half the gap between the means on A (1) and B (-2/3).
  expect_equal(d$ioc[1], (1 - (-2 / 3)) / 2)
  expect_identical(d$n_objectives[3], 1L)
  expect_true(is.na(d$ioc[3]))
  expect_match(flat_print(x), paste("IOC is -- for an item rated against one",
                                    "objective: the index compares",
                                    "objectives."), fixed = TRUE)
})

test_that("a two-by-two result saved before n existed takes N from the table", {
  pred <- c(TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE,
            TRUE, FALSE)
  act <- c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, FALSE,
           TRUE, FALSE)
  s <- signal_detection(pred, act)
  expect_equal(sum(s$confusion), 12)
  old <- s
  old$n <- NULL
  expect_identical(flat_print(old), flat_print(s))
  expect_match(flat_print(old), "chi-square(1, N = 12)", fixed = TRUE)
  r <- reproducibility_phi(pred, act)
  r$n <- NULL
  expect_match(flat_print(r), "chi-square(1, N = 12)", fixed = TRUE)
})

test_that("a similarity matrix too wide for the console prints in blocks", {
  ws <- utils::read.csv(system.file("extdata", "walkthrough_sort.csv",
                                    package = "contentvalidR"),
                        stringsAsFactors = FALSE)
  sim <- similarity_from_sort(ws)
  expect_identical(ncol(sim), 12L)
  withr::local_options(width = 60)
  out <- utils::capture.output(print(sim))
  heads <- grep("^  Item ", out)
  expect_length(heads, 2L)
  # A blank line separates the blocks, and every item heads one column.
  expect_identical(out[heads[2] - 1L], "")
  cols <- unlist(strsplit(trimws(out[heads]), " +"))
  expect_identical(sort(setdiff(cols, "Item")), sort(colnames(sim)))
  expect_lte(max(nchar(out)), 60L)
})

# The workflow object API (workflow_api.R) ------------------------------------

test_that("the workflow constructor takes NULL details as no details", {
  # Every workflow function builds its object with this constructor.
  fit <- contentvalidR:::.new_contentvalid_workflow(
    subclass = "contentvalid_sort", workflow = "item-sort",
    results = data.frame(item = "I1", recommendation = "Retain"),
    scale_summary = data.frame(), settings = list(), design = list(),
    details = NULL
  )
  expect_s3_class(fit, "contentvalid_sort")
  expect_identical(fit$details, list())
})

test_that("an essentiality object saved before 0.0.6 reports its panel range", {
  # summary() of a workflow reads the design through .workflow_design().
  legacy <- function(N) {
    structure(list(
      mode = "essentiality",
      results = data.frame(item = sprintf("I%d", seq_along(N)), N = N,
                           recommendation = rep("Review", length(N)))
    ), class = c("contentvalid_expert", "contentvalid_workflow"))
  }
  d <- contentvalidR:::.workflow_design(legacy(c(8L, 10L)))
  expect_identical(d$n_items, 2L)
  expect_identical(d$n_judges, NA_integer_)
  expect_identical(c(d$n_judges_min, d$n_judges_max), c(8L, 10L))
  # No items: a range of 0 judges, not Inf with a warning from min().
  design <- contentvalidR:::.workflow_design
  expect_no_warning(empty <- design(legacy(integer(0))))
  expect_identical(empty$n_items, 0L)
  expect_identical(c(empty$n_judges_min, empty$n_judges_max), c(0L, 0L))
})

test_that("a congruence object saved without cells reports no panel counts", {
  bare <- structure(list(
    mode = "congruence",
    results = data.frame(objective = c("A", "B", "C"),
                         recommendation = "Descriptive only")
  ), class = c("contentvalid_expert", "contentvalid_workflow"))
  d <- contentvalidR:::.workflow_design(bare)
  expect_identical(d$type, "expert-panel congruence")
  # No item column: each row is a unit.
  expect_identical(d$n_items, 3L)
  expect_identical(c(d$n_judges_min, d$n_judges_max, d$n_missing,
                     d$n_objectives), rep(NA_integer_, 4))
  full <- bare
  full$results$item <- c("I1", "I1", "I2")
  full$details <- list(cells = data.frame(objective = c("A", "B"),
                                          n_judges = c(5L, 4L),
                                          n_missing = c(0L, 1L)))
  fd <- contentvalidR:::.workflow_design(full)
  expect_identical(fd$n_items, 2L)
  expect_identical(c(fd$n_judges_min, fd$n_judges_max), c(4L, 5L))
})

test_that("an object with no design counts its units from the results", {
  # summary() of every workflow starts from .workflow_summary_core(). Sort
  # objects saved before 0.0.6 carried no design.
  old_sort <- structure(list(
    results = data.frame(item = c("I1", "I2", "I3"),
                         recommendation = c("Retain", "Review", "Retain"))
  ), class = c("contentvalid_sort", "contentvalid_workflow"))
  s <- contentvalidR:::.workflow_summary_core(old_sort)
  expect_identical(s$n_items, 3L)
  expect_identical(c(s$n_supported, s$n_review), c(2L, 1L))
  no_ids <- structure(list(
    results = data.frame(recommendation = c("Retain", "Review"))
  ), class = "contentvalid_workflow")
  expect_identical(contentvalidR:::.workflow_summary_core(no_ids)$n_items, 2L)
})

# Status words and decision legends (glossary.R) ------------------------------

test_that("a round comparison names each workflow's passing decision", {
  passing <- function(fit) {
    txt <- flat_print(compare_rounds(fit, fit))
    sub("\\).*$", "", sub("^.*passing decision \\(", "", txt))
  }
  rating <- utils::read.csv(system.file("extdata", "rating_example.csv",
                                        package = "contentvalidR"),
                            stringsAsFactors = FALSE)
  ess <- cbind(I1 = c(1, 1, 1, 1, 1, 1, 1, 1, 0, 1),
               I2 = c(1, 0, 1, 0, 1, 0, 1, 1, 0, 0))
  d <- rbind(delphi_long(delphi_r1, 1), delphi_long(delphi_r2, 2))
  asg <- data.frame(item = paste0("I", 1:7),
                    cell = c(rep("Autonomy", 4), "Competence", "Competence",
                             "Relatedness"))
  expect_identical(passing(sort_validity(example_sort())), "Retain")
  expect_identical(passing(rating_validity(rating)), "Retain")
  expect_identical(passing(expert_validity(ess, mode = "essentiality")),
                   "Supported")
  expect_identical(passing(expert_validity(example_congruence(),
                                           mode = "congruence")),
                   "Congruent")
  expect_identical(passing(delphi_validity(d, lo = 1, hi = 4, B = 0)),
                   "Consensus")
  expect_identical(passing(judge_validity(typical_judge_panel())), "Typical")
  expect_identical(passing(domain_validity(asg)), "Covered")
})

test_that("a comparison saved before the mode was stored reads generically", {
  ess <- cbind(I1 = c(1, 1, 1, 1, 1, 1, 1, 1, 0, 1),
               I2 = c(1, 0, 1, 0, 1, 0, 1, 1, 0, 0))
  fit <- expert_validity(ess, mode = "essentiality")
  cmp <- compare_rounds(fit, fit)
  cmp$mode <- NULL
  generic <- paste("Supported is the analysis's passing decision, and Review",
                   "marks an item to look at again, not to delete.")
  expect_match(flat_print(cmp), generic, fixed = TRUE)
  expect_match(flat_print(summary(cmp)), generic, fixed = TRUE)
})

test_that("a workflow with no known passing word gets the generic sentence", {
  # .status_meaning() writes this sentence for compare_rounds() printouts.
  expect_identical(
    contentvalidR:::.status_meaning(NULL, NULL, workflow = "custom"),
    paste("Status uses the words shared with nomologR: Supported is the",
          "analysis's passing decision, and Review marks an item to look at",
          "again, not to delete.")
  )
})

test_that("a workflow with no decision meanings fails loudly", {
  # The legends under every workflow printout and the glossary read these.
  expect_error(contentvalidR:::.decision_meanings("no-such-workflow"),
               "No decision meanings for workflow 'no-such-workflow'.",
               fixed = TRUE)
})

test_that("no legend section is printed for words it does not define", {
  # Every workflow printout ends with this legend; a decision word it does
  # not define, such as older wording, gets no empty section.
  on.exit(contentvalidR:::.end_section(), add = TRUE)
  legend <- contentvalidR:::.print_decision_legend
  out <- utils::capture.output(res <- withVisible(legend("Retained",
                                                         "item-sort")))
  expect_identical(out, character(0))
  expect_false(res$visible)
  expect_null(res$value)
  shown <- utils::capture.output(legend("Retain", "item-sort"))
  expect_true("What the decisions mean" %in% shown)
})

test_that("a key with no terms prints no section", {
  # Every workflow printout writes its key with .print_key().
  on.exit(contentvalidR:::.end_section(), add = TRUE)
  key <- contentvalidR:::.print_key
  out <- utils::capture.output(res <- withVisible(key(character(0))))
  expect_identical(out, character(0))
  expect_false(res$visible)
  expect_null(res$value)
  expect_true("What these columns mean" %in% utils::capture.output(key("psa")))
})

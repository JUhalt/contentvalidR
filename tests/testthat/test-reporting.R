sort_fit <- function() {
  sort_validity(utils::read.csv(
    system.file("extdata", "sort_example.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE
  ))
}

expert_fit <- function() {
  d <- utils::read.csv(
    system.file("extdata", "expert_relevance_example.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE
  )
  expert_validity(as.matrix(d[, setdiff(names(d), "expert")]),
                  mode = "relevance", lo = 1, hi = 4)
}

judge_fit <- function() {
  r <- rbind(
    c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
    c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(4, 3, 4, 3, 1, 2),
    c(4, 4, 3, 4, 2, 2), c(2, 2, 2, 2, 1, 1)
  )
  dimnames(r) <- list(paste0("Judge", 1:8), paste0("Item", 1:6))
  judge_validity(r, lo = 1, hi = 4)
}

test_that("as.data.frame returns the results with workflow provenance", {
  fit <- sort_fit()
  d <- as.data.frame(fit)

  expect_s3_class(d, "data.frame")
  expect_equal(nrow(d), nrow(fit$results))
  expect_equal(names(d)[1], "workflow")
  expect_true(all(d$workflow == "item-sort"))
  expect_true(all(names(fit$results) %in% names(d)))
})

test_that("interpretation text can be dropped for compact tables", {
  fit <- sort_fit()
  expect_true("interpretation" %in% names(as.data.frame(fit)))
  compact <- as.data.frame(fit, include_interpretation = FALSE)
  expect_false("interpretation" %in% names(compact))
  expect_equal(nrow(compact), nrow(fit$results))

  expect_error(as.data.frame(fit, include_interpretation = NA), "TRUE or FALSE")
})

test_that("the scale summary is reachable through the same generic", {
  fit <- sort_fit()
  s <- as.data.frame(fit, component = "scale_summary")
  expect_equal(nrow(s), nrow(fit$scale_summary))
  expect_true("workflow" %in% names(s))
  expect_error(as.data.frame(fit, component = "nope"), "must be one of")
})

test_that("tables from different workflows stack without losing identity", {
  a <- as.data.frame(sort_fit(), include_interpretation = FALSE)[, c("workflow", "item", "status")]
  b <- as.data.frame(expert_fit(), include_interpretation = FALSE)[, c("workflow", "item", "status")]
  stacked <- rbind(a, b)

  expect_equal(nrow(stacked), nrow(a) + nrow(b))
  expect_setequal(unique(stacked$workflow), c("item-sort", "expert-panel"))
})

test_that("as.data.frame works for every flagship workflow", {
  domain <- domain_validity(
    data.frame(item = paste0("I", 1:4), cell = c("A", "A", "B", "B"),
               stringsAsFactors = FALSE),
    domain = c("A", "B", "C")
  )
  for (fit in list(sort_fit(), expert_fit(), judge_fit(), domain)) {
    d <- as.data.frame(fit)
    expect_s3_class(d, "data.frame")
    expect_gt(nrow(d), 0L)
    expect_equal(names(d)[1], "workflow")
  }
})

test_that("content_report selects reporting columns and keeps status", {
  tab <- content_report(sort_fit(), format = "data.frame")
  expect_s3_class(tab, "data.frame")
  expect_true(all(c("item", "psa", "csv", "recommendation", "status") %in% names(tab)))
  # The long interpretation text does not belong in a manuscript table.
  expect_false("interpretation" %in% names(tab))
  expect_equal(nrow(tab), 6L)
})

test_that("content_report rounds to the requested digits", {
  tab <- content_report(sort_fit(), digits = 1, format = "data.frame")
  # Half up, as the APA table rounds: .85 is .9, where round() gives .8.
  expect_equal(tab$psa, .half_up(sort_fit()$results$psa, 1))
  expect_identical(tab$psa[sort_fit()$results$item == "B1"], 0.9)
  # p values keep three decimals whatever `digits` is.
  expect_equal(tab$p_value, round(sort_fit()$results$p_value, 3))
  expect_error(content_report(sort_fit(), digits = -1), "nonnegative integer")
})

test_that("flagged selection keeps only units needing attention", {
  all_rows <- content_report(sort_fit(), include = "all", format = "data.frame")
  flagged <- content_report(sort_fit(), include = "flagged", format = "data.frame")

  expect_lt(nrow(flagged), nrow(all_rows))
  expect_true(all(flagged$status != "Supported"))
  expect_setequal(flagged$item, c("B2", "C2"))
})

test_that("markdown output is a valid table carrying its settings", {
  md <- content_report(sort_fit(), format = "markdown")
  expect_type(md, "character")

  # Header, separator rule, one line per item, then a blank line and the
  # APA note.
  expect_match(md[1], "^\\| Item \\|")
  # The item column is text, so the rule aligns it left.
  expect_match(md[2], "^\\| :--- \\|")
  expect_gte(length(md), 2L + 6L + 2L)
  table_md <- md[1:8]
  expect_true(all(grepl("^\\|", table_md)))
  expect_identical(md[9], "")
  expect_match(md[10], "^[*]Note[.][*] ")

  # Every row has the same number of cells as the header.
  cells <- vapply(table_md, function(l) lengths(regmatches(l, gregexpr("|", l, fixed = TRUE))),
                  integer(1))
  expect_equal(length(unique(cells)), 1L)

  settings <- attr(md, "settings")
  expect_equal(settings$p0, sort_fit()$settings$p0)
  expect_equal(settings$alpha, sort_fit()$settings$alpha)
})

test_that("a markdown caption is placed above the table", {
  md <- content_report(sort_fit(), format = "markdown", caption = "**Table 1.** Evidence.")
  expect_equal(md[1], "**Table 1.** Evidence.")
  expect_equal(md[2], "")
  expect_match(md[3], "^\\| Item \\|")
  expect_error(content_report(sort_fit(), format = "markdown", caption = 5),
               "one character string")
})

test_that("an empty selection produces a readable note rather than a broken table", {
  clean <- sort_validity(data.frame(
    item = rep("I1", 6), rater = 1:6,
    assigned_construct = rep("A", 6), target_construct = "A",
    stringsAsFactors = FALSE
  ))
  expect_equal(nrow(content_report(clean, include = "flagged")), 0L)

  md <- content_report(clean, format = "markdown", include = "flagged")
  expect_equal(length(md), 1L)
  expect_match(md, "No units matched")
})

test_that("columns that are entirely missing are dropped from manuscript tables", {
  fit <- judge_fit()
  # This panel agrees too closely for logit severity to be estimable.
  expect_true(all(is.na(fit$results$severity)))

  tab <- content_report(fit, format = "data.frame")
  expect_false("severity" %in% names(tab))
  expect_false("outfit" %in% names(tab))
  # Columns that do carry information are kept.
  expect_true("severity_raw" %in% names(tab))
  expect_true("differentiation" %in% names(tab))
})

test_that("markdown escapes pipe characters in cell values", {
  d <- data.frame(a = "x|y", b = 1, stringsAsFactors = FALSE)
  lines <- contentvalidR:::.as_markdown_table(d)
  expect_match(lines[3], "x\\\\|y")
})

test_that("content_report works for every flagship workflow", {
  domain <- domain_validity(
    data.frame(item = paste0("I", 1:4), cell = c("A", "A", "B", "B"),
               stringsAsFactors = FALSE),
    domain = c("A", "B", "C")
  )
  for (fit in list(sort_fit(), expert_fit(), judge_fit(), domain)) {
    tab <- content_report(fit, format = "data.frame")
    expect_s3_class(tab, "data.frame")
    expect_true("status" %in% names(tab))
    expect_gt(ncol(tab), 2L)
    apa <- content_report(fit)
    expect_s3_class(apa, "contentvalid_report")
    expect_true("decision" %in% names(apa))
    expect_true(all(vapply(apa, is.character, logical(1))))
  }
})

test_that("content_report rejects non-workflow input", {
  expect_error(content_report("not a workflow"), "fitted contentvalidR workflow")
  expect_error(content_report(list()), "fitted contentvalidR workflow")
})

test_that("the default report is an APA table", {
  tab <- content_report(sort_fit())
  # The names on the object are the ones code relies on; sentence case is
  # applied only where the table is shown.
  expect_identical(names(tab), c("item", "target", "judges", "competitor",
                                 "Psa", "Psa 95% CI", "Csv", "p", "decision"))
  r <- sort_fit()$results
  i <- which(r$item == "A1")
  expect_identical(tab$judges[i], paste0(r$n_target[i], "/", r$n[i]))
  expect_false(any(grepl("^0[.]", tab$Psa)))
  expect_match(tab$`Psa 95% CI`[i], "^[[][.][0-9]{2}, (1[.]00|[.][0-9]{2})[]]$")
  expect_true(all(grepl("^(< [.]001|[.][0-9]{3}|> [.]999)$", tab$p)))

  # It prints without row names, and as.data.frame() gives a plain data frame.
  out <- utils::capture.output(print(tab))
  expect_identical(out[1], "<contentvalid_report> Results table in APA style")
  expect_match(out[3], "^  Item  Target  Judges")
  expect_match(paste(out, collapse = " "), 'format = "markdown"', fixed = TRUE)
  expect_identical(class(as.data.frame(tab)), "data.frame")
})

test_that("markdown output prints as the table, not as a character vector", {
  md <- content_report(sort_fit(), format = "markdown")
  out <- utils::capture.output(print(md))
  expect_identical(out, as.character(unclass(md)))
  expect_false(any(grepl("^[[]1[]]|settings", out)))
  expect_match(out[1], "| Psa | 95% CI |", fixed = TRUE)
})

test_that("every workflow and expert mode has an APA report with a decision", {
  set.seed(2)
  rd <- expand.grid(item = c("A1", "B1"), rater = 1:12,
                    construct = c("A", "B", "C"), stringsAsFactors = FALSE)
  rd$target_construct <- ifelse(rd$item == "B1", "B", "A")
  rd$rating <- ifelse(rd$construct == rd$target_construct,
                      sample(4:5, nrow(rd), TRUE), sample(1:3, nrow(rd), TRUE))
  rating <- content_report(rating_validity(rd))
  expect_identical(names(rating), c("item", "target", "judges", "HTC", "HTD",
                                    "F test", "p", "contrast p", "decision"))

  ess <- content_report(expert_validity(c(10, 8), mode = "essentiality", N = 12))
  expect_identical(names(ess), c("item", "essential", "CVR", "p", "decision"))
  expect_identical(ess$essential, c("10/12", "8/12"))

  d <- expand.grid(item = c("I1", "I2"), judge = 1:4, objective = c("A", "B"))
  d$target_objective <- ifelse(d$item == "I1", "A", "B")
  d$score <- ifelse(d$objective == d$target_objective, 1, -1)
  con <- content_report(expert_validity(d, mode = "congruence"))
  expect_identical(names(con), c("item", "target", "experts", "IOC", "mean",
                                 "competitor", "competitor mean", "margin",
                                 "decision"))
  expect_identical(con$margin, c("2.00", "2.00"))

  long <- function(m, round) {
    data.frame(expert = paste0("E", seq_len(nrow(m))),
               item = rep(colnames(m), each = nrow(m)), round = round,
               rating = as.vector(m), stringsAsFactors = FALSE)
  }
  r1 <- cbind(S1 = c(4, 4, 3, 4, 3, 4), S2 = c(3, 4, 3, 2, 4, 3))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(4, 4, 4, 4, 4, 3))
  delphi <- content_report(delphi_validity(rbind(long(r1, 1), long(r2, 2)),
                                           lo = 1, hi = 4, B = 0))
  expect_true(all(c("item", "last round", "experts", "agree", "unchanged",
                    "decision") %in% names(delphi)))

  dom <- content_report(domain_validity(
    data.frame(item = paste0("I", 1:3), cell = c("A", "A", "B"),
               stringsAsFactors = FALSE),
    domain = c("A", "B", "C")))
  expect_identical(dom$share, c("67%", "33%", "0%"))
})

test_that("an APA report with no rows prints a note rather than an empty table", {
  clean <- sort_validity(data.frame(
    item = rep("I1", 6), rater = 1:6,
    assigned_construct = rep("A", 6), target_construct = "A",
    stringsAsFactors = FALSE
  ))
  out <- utils::capture.output(print(content_report(clean, include = "flagged")))
  expect_identical(out[1:3], c("<contentvalid_report> Results table in APA style",
                               "", "No units matched the requested selection."))
})

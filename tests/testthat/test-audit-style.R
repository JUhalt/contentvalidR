# The output style shared with nomologR (JUhalt/nomologR#144): headers,
# numbers, tables, sections, flags, closings, errors, plots and APA notes.

shown <- function(x, width = 80, ...) {
  old <- options(width = width)
  on.exit(options(old), add = TRUE)
  utils::capture.output(print(x, ...))
}

sort_fit <- function() {
  sort_validity(utils::read.csv(
    system.file("extdata", "sort_example.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE))
}

relevance <- function() {
  matrix(c(4, 3, 4, 4, 3, 4, 2, 3, 4, 4, 3, 2, 4, 4, 4, 3, 4, 4), 6,
         dimnames = list(NULL, c("I1", "I2", "I3")))
}

test_that("every printout opens with a tag-first header and no rule", {
  fit <- sort_fit()
  out <- shown(fit)
  expect_identical(out[1], "<contentvalid_sort> Item-sort analysis")
  expect_false(grepl("^-+$", out[2]))
  expect_identical(shown(summary(fit))[1],
                   "<contentvalid_sort summary> Item-sort analysis")
  expect_match(shown(compute_psa(utils::read.csv(
    system.file("extdata", "sort_example.csv", package = "contentvalidR"))))[1],
    "^<contentvalid_psa> ")
  expect_match(shown(cvi(relevance() >= 3))[1], "^<contentvalid_cvi> ")
})

test_that("numbers round half up, missing values print --, and p never reads 1.000", {
  fmt <- contentvalidR:::.fmt
  expect_identical(fmt(c(5 / 8, 1 / 8, 3 / 8)), c(".63", ".13", ".38"))
  expect_identical(fmt(c(-0.004, NA)), c(".00", "--"))
  expect_identical(fmt(2.675, bounded = FALSE), "2.68")
  expect_identical(contentvalidR:::.fmt_p(c(0.9996, 0.0004)), c("> .999", "< .001"))
  expect_identical(contentvalidR:::.p_phrase(0.9999), "p > .999")
  expect_identical(contentvalidR:::.fmt_pct(c(1 / 3, NA), base = 9), c("33%", "--"))
  expect_identical(contentvalidR:::.fmt_pct(1 / 3, base = 150), "33.3%")
})

test_that("prose wraps at 79 columns without breaking a statistic", {
  old <- options(width = 60)
  on.exit(options(old), add = TRUE)
  out <- utils::capture.output(contentvalidR:::.say(paste(
    "The interval [.65, .99] and p < .001 with N = 473 and F(2, 14) = 3.21",
    "stay whole across the lines of a long paragraph, alpha = .05 too.")))
  expect_true(all(nchar(out) <= 59))
  joined <- paste(out, collapse = "\n")
  for (phrase in c("[.65, .99]", "p < .001", "N = 473", "F(2, 14)", "alpha = .05")) {
    expect_true(any(grepl(phrase, out, fixed = TRUE)), info = phrase)
  }
  expect_false(grepl(intToUtf8(160), joined))
})

test_that("tables indent, align, use sentence case, and drop empty columns", {
  tab <- data.frame(item = c("A1", "B22"), decision = c("Retain", "Review"),
                    Psa = c(".90", ".65"), p = c("< .001", ".132"),
                    empty = c("--", "--"), stringsAsFactors = FALSE)
  out <- utils::capture.output(contentvalidR:::.print_table(tab))
  expect_identical(out[1], "  Item  Decision  Psa       p")
  expect_identical(out[3], "  B22   Review    .65    .132")
  # A status column stays even when empty; a decisive test column too.
  tab$decision <- "--"
  out <- utils::capture.output(contentvalidR:::.print_table(tab))
  expect_match(out[1], "Decision", fixed = TRUE)
})

test_that("a table too wide for the console drops trailing columns and says so", {
  old <- options(width = 40)
  on.exit(options(old), add = TRUE)
  tab <- data.frame(item = "A1", decision = "Retain", first = strrep("x", 12),
                    second = strrep("y", 12), third = strrep("z", 12),
                    stringsAsFactors = FALSE)
  out <- utils::capture.output(contentvalidR:::.print_table(tab))
  expect_match(out[1], "Decision", fixed = TRUE)
  expect_match(paste(out, collapse = " "), "Not shown for width:", fixed = TRUE)
  expect_match(paste(out, collapse = " "), "as.data.frame(x)", fixed = TRUE)
})

test_that("sections indent their prose, and the closing returns to the margin", {
  out <- shown(sort_fit())
  i <- which(out == "Item-level evidence")
  expect_match(out[i + 1L], "^  Item ")
  expect_true(any(grepl("^  Judges: assignments", out)))
  last <- out[length(out)]
  expect_match(last, "^See summary\\(x\\)")
  expect_true(any(grepl("^'Review' is not an automatic deletion decision", out)))
})

test_that("summaries list flagged units as bullets with complete sentences", {
  out <- shown(summary(sort_fit()))
  expect_true(any(out == "Flagged"))
  bullets <- out[startsWith(trimws(out), "- ")]
  expect_gte(length(bullets), 1L)
  expect_match(bullets[1], "^  - [A-Z0-9, ]+ \\(Review\\): [A-Z]")
})

test_that("a wrong choice names the argument and the choices", {
  expect_error(content_report(sort_fit(), format = "latex"),
               '`format` must be one of "apa", "data.frame", or "markdown", not "latex".',
               fixed = TRUE)
  expect_error(expert_power(criterion = "x"),
               '`criterion` must be one of "cvi" or "cvr", not "x".', fixed = TRUE)
  # A unique partial match still works, as with match.arg().
  expect_s3_class(content_report(sort_fit(), format = "mark"), "contentvalid_markdown")
})

test_that("every plot method takes type", {
  methods <- c("plot.contentvalid_sort", "plot.contentvalid_rating",
               "plot.contentvalid_expert", "plot.contentvalid_delphi",
               "plot.contentvalid_evidence", "plot.contentvalid_sort_power",
               "plot.contentvalid_expert_power", "plot.contentvalid_structure")
  for (m in methods) {
    expect_true("type" %in% names(formals(utils::getFromNamespace(m, "contentvalidR"))),
                info = m)
  }
})

test_that("a manuscript table carries an APA note", {
  tab <- content_report(sort_fit())
  note <- attr(tab, "note")
  expect_match(note, "^Psa = proportion of substantive agreement; CI = confidence interval; Csv = ")
  expect_match(note, "95% CI = Wilson score confidence interval.", fixed = TRUE)
  expect_match(note, "Retain = at least the number of target assignments", fixed = TRUE)
  expect_match(paste(shown(tab), collapse = " "), "Note. Psa =", fixed = TRUE)
  md <- content_report(sort_fit(), format = "markdown")
  expect_match(md[length(md)], "^[*]Note[.][*] Psa = ")
  rel <- content_report(expert_validity(relevance(), lo = 1, hi = 4, agreement = "none"))
  expect_match(attr(rel, "note"),
               "Penfield-Giacobbi score confidence interval for V and Wilson score",
               fixed = TRUE)
})

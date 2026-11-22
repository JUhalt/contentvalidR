# APA's table forms (1.0.1, decided with nomologR): a p cell reads "<.001" or
# ">.999" with no space, and a negative number in an APA table takes the
# minus sign, U+2212. Sentences, notes' p phrases, the console printouts and
# the handoff keep the forms they had.

minus <- intToUtf8(0x2212L)

congruence_fit <- function() {
  ratings <- read.csv(
    system.file("extdata", "expert_congruence_example.csv",
                package = "contentvalidR"),
    stringsAsFactors = FALSE
  )
  expert_validity(ratings, mode = "congruence")
}

test_that("a p cell drops the space, and a sentence keeps it", {
  expect_identical(contentvalidR:::.fmt_p(c(0.0004, 0.0421, 0.9996, NA),
                                          table = TRUE),
                   c("<.001", ".042", ">.999", "--"))
  expect_identical(contentvalidR:::.fmt_p(c(0.0004, 0.9996)),
                   c("< .001", "> .999"))
  expect_identical(contentvalidR:::.p_phrase(c(0.0004, 0.9996, 0.021)),
                   c("p < .001", "p > .999", "p = .021"))
})

test_that("the minus replaces only a hyphen that starts a number", {
  x <- c("-.43", "[-.12, .30]", "F(2, 14) = -1.20", "(-1 to 1)", "-0.57",
         "Hinkin-Tracey", "A-1", "--", "x.-5", "Holm-adjusted", "1-2")
  expect_identical(contentvalidR:::.apa_minus(x), c(
    paste0(minus, ".43"), paste0("[", minus, ".12, .30]"),
    paste0("F(2, 14) = ", minus, "1.20"), paste0("(", minus, "1 to 1)"),
    paste0(minus, "0.57"), "Hinkin-Tracey", "A-1", "--", "x.-5",
    "Holm-adjusted", "1-2"
  ))
  expect_identical(contentvalidR:::.apa_minus(character(0)), character(0))
  # The source holds the code point, not the character.
  expect_identical(utf8ToInt(contentvalidR:::.minus_sign), 0x2212L)
})

test_that("a column with the minus or the bare p bound still reads as numbers", {
  expect_true(contentvalidR:::.looks_numeric(c(paste0(minus, ".43"), ".20")))
  expect_true(contentvalidR:::.looks_numeric(c("<.001", ".042", ">.999")))
  expect_true(contentvalidR:::.looks_numeric(c("< .001", "-.10")))
  expect_false(contentvalidR:::.looks_numeric(c("A-1", "B")))
})

test_that("the APA table, its note and its Markdown carry the minus", {
  fit <- congruence_fit()
  tab <- content_report(fit)
  note <- attr(tab, "note")
  expect_match(note, paste0("(", minus, "1 to 1)"), fixed = TRUE)
  expect_false(grepl("(-1 to 1)", note, fixed = TRUE))
  # Text cells, such as item names and decisions, are not touched.
  expect_identical(tab$item, as.character(fit$results$item))

  md <- content_report(fit, format = "markdown")
  expect_true(any(grepl(minus, md, fixed = TRUE)))
  out <- utils::capture.output(print(tab))
  expect_true(any(grepl(minus, out, fixed = TRUE)) || !l10n_info()[["UTF-8"]])
})

test_that("a console that is not UTF-8 prints the hyphen, and the object keeps the minus", {
  fit <- congruence_fit()
  tab <- content_report(fit)
  md <- content_report(fit, format = "markdown")
  testthat::local_mocked_bindings(.utf8_output = function() FALSE)
  out <- c(utils::capture.output(print(tab)), utils::capture.output(print(md)))
  expect_false(any(grepl(minus, out, fixed = TRUE)))
  expect_true(any(grepl("(-1 to 1)", out, fixed = TRUE)))
  expect_true(any(grepl(minus, unlist(tab), fixed = TRUE)))
  expect_true(any(grepl(minus, md, fixed = TRUE)))
})

test_that("knitted to PDF, the minus becomes LaTeX's own or the hyphen", {
  fit <- congruence_fit()
  md <- content_report(fit, format = "markdown")
  tab <- content_report(fit)
  # Markdown that goes into the document as Markdown: LaTeX's math minus,
  # which pdflatex sets; the Unicode minus would stop it.
  testthat::local_mocked_bindings(.latex_knit = function() TRUE,
                                  .asis_chunk = function() TRUE)
  out <- utils::capture.output(print(md))
  expect_false(any(grepl(minus, out, fixed = TRUE)))
  expect_true(any(grepl("$-$", out, fixed = TRUE)))
  # Console output in the PDF (a verbatim block): the hyphen.
  out <- utils::capture.output(print(tab))
  expect_false(any(grepl(minus, out, fixed = TRUE)))
  expect_false(any(grepl("$-$", out, fixed = TRUE)))
})

test_that("Markdown printed outside an asis chunk of a PDF gets the hyphen", {
  md <- content_report(congruence_fit(), format = "markdown")
  testthat::local_mocked_bindings(.latex_knit = function() TRUE,
                                  .asis_chunk = function() FALSE)
  out <- utils::capture.output(print(md))
  expect_false(any(grepl(minus, out, fixed = TRUE)))
  expect_false(any(grepl("$-$", out, fixed = TRUE)))
})

test_that("outside knitr the LaTeX checks are off", {
  withr::local_options(knitr.in.progress = NULL)
  expect_false(contentvalidR:::.latex_knit())
})

test_that("an empty report names its units and points to no table", {
  rating <- data.frame(
    item = rep("I1", 6), rater = 1:6,
    assigned_construct = rep("A", 6), target_construct = "A",
    stringsAsFactors = FALSE
  )
  rep <- content_report(sort_validity(rating))
  expect_identical(attr(rep, "empty"), "There are no items to report.")
  expect_null(attr(as.data.frame(rep), "empty"))
  expect_identical(contentvalidR:::.report_unit(structure(list(),
    class = c("contentvalid_judge", "contentvalid_workflow"))), "judges")
  expect_identical(contentvalidR:::.report_unit(structure(list(),
    class = c("contentvalid_domain", "contentvalid_workflow"))),
    "blueprint cells")
  # An object whose attribute was dropped still prints a sentence.
  bare <- rep[0, ]
  attr(bare, "empty") <- NULL
  expect_true(any(grepl("There is nothing to report.",
                        utils::capture.output(print(bare)), fixed = TRUE)))
})

test_that("the console printout, the numbers and the handoff stay ASCII", {
  fit <- congruence_fit()
  out <- utils::capture.output(print(fit), summary(fit))
  expect_false(any(grepl(minus, out, fixed = TRUE)))
  df <- content_report(fit, format = "data.frame")
  expect_true(is.numeric(df$margin))
  h <- content_handoff(fit)
  text <- unlist(lapply(unclass(h), function(el) {
    if (is.data.frame(el)) unlist(lapply(el, as.character)) else
      if (is.character(el)) el else character(0)
  }))
  expect_false(any(grepl("[^\\x01-\\x7F]", text, perl = TRUE)))
})

# The lines of the 1.0.1 helpers that no workflow reaches on ordinary data:
# the short forms of the input-check messages, and knitr's checks outside a
# PDF knit. Each is run here directly, so every line of R/ stays under a
# test.

test_that("a long list of values is cut to five and a count", {
  expect_identical(contentvalidR:::.list_some(letters[1:7]),
                   "a, b, c, d, e and 2 more")
  expect_identical(contentvalidR:::.list_some(letters[1:3]), "a, b, c")
})

test_that("a numeric table names no column, and a message stays whole", {
  expect_null(contentvalidR:::.text_columns_phrase(data.frame(a = 1:2,
                                                              b = c(TRUE, NA))))
  expect_identical(contentvalidR:::.but_columns(NULL), "")
  expect_identical(contentvalidR:::.convert_what(NULL), "the ratings")
  expect_error(contentvalidR:::.stop_not_numeric(data.frame(a = 1:2), "data"),
               paste0("`data` must hold numeric ratings. `data` needs one row ",
                      "per judge and one column per item"), fixed = TRUE)
  expect_error(contentvalidR:::.stop_not_numeric(data.frame(a = 1:2), "data"),
               "Otherwise convert the ratings to numbers", fixed = TRUE)
})

test_that("a long text value is shortened in the message", {
  long <- strrep("x", 50)
  phrase <- contentvalidR:::.text_columns_phrase(data.frame(a = long))
  expect_match(phrase, paste0("(such as \"", strrep("x", 37), "...\")"),
               fixed = TRUE)
  expect_false(grepl(long, phrase, fixed = TRUE))
})

test_that("congruence data missing two columns names both", {
  d <- data.frame(item = "I1", rater = 1, objective = "A", rating = 1)
  expect_error(ioc(d), "It has no columns named judge, score", fixed = TRUE)
})

test_that("outside a PDF knit the LaTeX check is off, even while knitting", {
  skip_if_not_installed("knitr")
  # knitr sets this option while it knits; is_latex_output() then reads the
  # output format, which outside a real knit is not LaTeX.
  withr::local_options(knitr.in.progress = TRUE)
  expect_false(contentvalidR:::.latex_knit())
  expect_false(contentvalidR:::.asis_chunk())
})

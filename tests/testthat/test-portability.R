# R CMD check warns when R code holds non-ASCII characters, and CRAN requires
# ASCII there; a name such as Hernandez-Nieto's needs a \u escape. This catches
# it in an ordinary test run, before the release gate's check stage does.
# Comments may hold UTF-8 (roxygen documentation does), so only code is read.

test_that("R code outside comments is ASCII", {
  dir <- testthat::test_path("..", "..", "R")
  skip_if_not(dir.exists(dir), "package sources are not available")
  offending <- character(0)
  for (f in list.files(dir, pattern = "[.][Rr]$", full.names = TRUE)) {
    lines <- readLines(f, warn = FALSE, encoding = "UTF-8")
    code <- sub("^\\s*#.*$", "", lines)
    bad <- which(grepl("[^\\x01-\\x7F]", code, perl = TRUE))
    if (length(bad)) {
      offending <- c(offending, paste0(basename(f), ":", bad))
    }
  }
  expect_identical(offending, character(0))
})

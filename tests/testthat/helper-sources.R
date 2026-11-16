# Where the tests find the package's own files.
#
# From the source tree a test reads the SOURCE, so an edit is tested before
# it is installed. Without the source tree, as under R CMD check, it reads
# the copy an installed package carries: the help pages, the vignette sources
# under doc/, and the files of inst/. README.Rmd and the R/ sources are not
# installed, so a test that reads one of them skips there.

# The path of one of the package's files, named as in the source tree, as in
# pkg_file("vignettes", "delphi-rounds.Rmd"); "" when the file is not there.
pkg_file <- function(...) {
  path <- testthat::test_path("..", "..", ...)
  # Where the source tree has the directory, the source or nothing: never an
  # installed copy, which may be older than the source.
  if (dir.exists(dirname(path))) return(if (file.exists(path)) path else "")
  parts <- c(...)
  # An installed package keeps its vignette sources in doc/ and the files of
  # inst/ at its top level.
  installed <- if (parts[1] == "vignettes") {
    c("doc", parts[-1])
  } else if (parts[1] == "inst") {
    parts[-1]
  }
  if (!length(installed)) return("")
  do.call(system.file, c(as.list(installed), list(package = "contentvalidR")))
}

# The lines of such a file.
src_lines <- function(...) {
  path <- pkg_file(...)
  if (!nzchar(path)) skip("package sources are not available")
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

# The file names of the vignette sources.
vignette_sources <- function() {
  dir <- testthat::test_path("..", "..", "vignettes")
  if (!dir.exists(dir)) dir <- system.file("doc", package = "contentvalidR")
  list.files(dir, pattern = "[.]Rmd$")
}

# The lines of a help page's Rd source: the file in man/, or without the
# source tree the installed page, written back out as Rd. The installed page
# keeps the wording but not the order of the sections, and a macro such as
# \doi{} is already expanded in it. A page missing from man/ is an error, not
# a reason to read an installed copy.
rd_lines <- function(topic) {
  man <- testthat::test_path("..", "..", "man")
  file <- paste0(topic, ".Rd")
  if (dir.exists(man)) return(readLines(file.path(man, file), warn = FALSE))
  db <- tryCatch(tools::Rd_db("contentvalidR"), error = function(e) NULL)
  if (is.null(db[[file]])) skip("package documentation is not available")
  rd <- paste(as.character(db[[file]], deparse = TRUE), collapse = "")
  strsplit(rd, "\n", fixed = TRUE)[[1]]
}

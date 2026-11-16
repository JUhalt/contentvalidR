# Stage 2: run the whole test suite from the source tree.
#
# R CMD check (stage 4) and CI test the installed package. There the tests
# that read README.Rmd or the R/ sources skip, because neither is installed
# (5 tests when this stage was added, at 0.10.1.9000), and the tests of the
# help pages and vignettes read the installed copies, not the sources.
# Before this stage, those tests met the sources only when someone
# remembered to run devtools::test() by hand, and the gate should not
# depend on that.
#
# The stage fails on a failed test, on an error, and on a test that skips
# because it could not find the package sources or documentation. Under
# R CMD check that reason is true. In a source tree it cannot be, so here
# it means the test's path has gone stale and the test runs nowhere. Any
# other skip, such as a suggested package that is not installed, is listed
# and does not fail the stage.
#
# It runs second, after build and before smoke and check:
#   - build regenerates man/, which some of these tests read, and leaves
#     the stamp of the tree the tarball was built from. Like smoke and
#     check, this stage refuses a tree that does not match the stamp, so a
#     PASS here describes the source that was built.
#   - it takes minutes and names the test that failed, where check takes
#     most of an hour to reach the same tests.
#
# devtools::test() loads contentvalidR from source into this process. That
# is safe only because each stage is its own process: smoke starts in one
# that has never loaded the package. It also sets NOT_CRAN unless it is
# already set, so a test marked skip_on_cran() runs here, which it does not
# under the check stage.
#
# Everything below runs inside local(), so that the tests see the global
# environment a plain devtools::test() gives them: a name defined here
# (root, out, a helper) would otherwise be found by any test that used it
# without defining it, and such a test would pass here and fail elsewhere.

local({
  args <- commandArgs(trailingOnly = TRUE)
  out <- args[[1]]
  root <- args[[2]]

  gate_fail <- function(...) {
    cat("FAIL: ", ..., "\n", sep = "")
    quit(status = 1)
  }

  version <- read.dcf(file.path(root, "DESCRIPTION"), fields = "Version")[1, 1]
  tarball <- file.path(out, paste0("contentvalidR_", version, ".tar.gz"))
  if (!file.exists(tarball)) {
    gate_fail("no tarball at ", tarball, "; run the build stage first.")
  }
  source(file.path(root, "tools", "gate-stamp.R"), local = TRUE)
  if (!gate_tarball_matches_source(tarball, root)) quit(status = 1)
  before <- gate_source_stamp(root)

  cat("-- tests, from the source tree\n")
  # One line for each test file, then every skip and every failure in full.
  # The reporter's defaults would instead print a line every tenth of a
  # second when the output is not a terminal, and stop at the tenth failure.
  reporter <- testthat::ProgressReporter$new(show_praise = FALSE,
                                             max_failures = Inf,
                                             update_interval = Inf)
  run <- tryCatch(
    devtools::test(root, reporter = reporter, stop_on_failure = FALSE),
    error = function(e) e
  )
  if (inherits(run, "error")) {
    gate_fail("the test run stopped before it finished: ",
              conditionMessage(run))
  }

  # testthat records one result for each expectation and error.
  count <- function(class) {
    sum(vapply(run, function(test) {
      sum(vapply(test$results, inherits, logical(1), what = class))
    }, numeric(1)))
  }
  failed <- count("expectation_failure")
  errors <- count("expectation_error")
  passed <- count("expectation_success")

  # The skips come from the reporter, not from the results: a skip at the
  # top of a test file, outside test_that(), ends the file and is left out
  # of the results, so none of that file's tests would be missed here. The
  # reporter sees every skip. Its `skips` field is public but is not
  # documented, so a testthat that no longer has it fails the stage instead
  # of passing it unread.
  seen <- tryCatch(reporter$skips$as_list(), error = function(e) NULL)
  if (is.null(seen)) {
    gate_fail("testthat's reporter did not give its skips, so this stage",
              " cannot tell whether a test skipped. Update tools/gate-tests.R",
              " for this version of testthat.")
  }
  skipped <- length(seen)
  skips <- do.call(rbind, lapply(seen, function(skip) {
    from <- attr(skip$srcref, "srcfile")$filename
    reason <- sub("^Reason: ", "", conditionMessage(skip))
    data.frame(file = if (is.null(from)) NA_character_ else basename(from),
               test = skip$test,
               reason = gsub("[[:space:]]+", " ", reason))
  }))
  # What a test says when it skips for want of the source tree: "package
  # sources are not available", "package documentation is not available" or
  # "handoff documentation is not available".
  stale <- grepl("(sources|documentation) (is|are) not available",
                 skips$reason)

  # Counted as testthat's own last line counts them, except that it adds
  # failures and errors together as FAIL.
  cat("\n-- result\n")
  cat("failed ", failed, ", errors ", errors, ", skipped ", skipped,
      ", passed ", passed, "\n", sep = "")
  if (skipped) {
    cat("skips (file: reason, then the test):\n")
    cat(sprintf("  %s: %s%s\n      %s\n", skips$file, skips$reason,
                ifelse(stale, "  <-- cannot be true in a source tree", ""),
                skips$test), sep = "")
  } else {
    cat("skips: none\n")
  }

  if (failed + errors + skipped + passed == 0) {
    gate_fail("the run returned no results, so no test ran.")
  }
  problems <- c(
    if (failed) paste0(failed, " failed expectation(s)"),
    if (errors) paste0(errors, " error(s)"),
    if (any(stale)) {
      paste0(sum(stale), " skip(s) for want of sources or documentation",
             " that are here")
    }
  )
  if (length(problems)) gate_fail(paste(problems, collapse = ", "), ".")

  # A test that changed a tracked file or left a new file in the tree, or an
  # edit made during the run, would leave smoke and check to fail on the
  # stamp without saying why. The stamp does not watch paths git ignores.
  if (!identical(gate_source_stamp(root), before)) {
    gate_fail("the source tree changed while the tests ran: a tracked file",
              " changed or a new file appeared. If nobody edited it, a test",
              " wrote into it, and a test must leave the tree as it found",
              " it. Run the build stage again.")
  }
})

# Stage 3: R CMD check --as-cran on the built tarball, with CRAN's incoming
# checks enabled so URL and DOI problems surface here rather than from CRAN.

args <- commandArgs(trailingOnly = TRUE)
out <- args[[1]]
root <- args[[2]]

version <- read.dcf(file.path(root, "DESCRIPTION"), fields = "Version")[1, 1]
tarball <- file.path(out, paste0("contentvalidR_", version, ".tar.gz"))
if (!file.exists(tarball)) {
  cat("FAIL: no tarball at ", tarball, "; run the build stage first.\n", sep = "")
  quit(status = 1)
}
source(file.path(root, "tools", "gate-stamp.R"))
if (!gate_tarball_matches_source(tarball, root)) quit(status = 1)

Sys.setenv("_R_CHECK_CRAN_INCOMING_REMOTE_" = "TRUE")
res <- rcmdcheck::rcmdcheck(tarball, args = "--as-cran", error_on = "never",
                            quiet = TRUE, check_dir = file.path(out, "chk"))
print(res)

# Two notes are expected: CRAN's incoming-feasibility note, and math rendering
# skipped where V8 is unavailable. Anything else is a finding, and errors and
# warnings always are.
#
# The incoming note is expected only when every line of it is one of these:
# the maintainer, "New submission" (before the package was on CRAN), "Version
# contains large components" (a development version), "Days since last
# update" (once it is on CRAN, since 0.4.0 on 2026-09-28), or "Version jumps
# in minor" for a 1.0.0 release candidate only. CRAN prints that last one when
# the minor version leaps far past CRAN's (0.99.0 against 0.4.0 did; 0.10.1
# did not), and every 0.99.N candidate does it by design. For any other
# version it is still a finding. Any other line in the note, such as a
# misspelling or a URL problem, is a finding too.
incoming_expected <- function(note) {
  lines <- trimws(strsplit(note, "\n", fixed = TRUE)[[1]][-1])
  lines <- lines[nzchar(lines)]
  known <- c("^Maintainer: ", "^New submission$",
             "^Version contains large components ", "^Days since last update: [0-9]+$",
             "^Version jumps in minor \\(submitted: 0\\.99\\.[0-9]+, existing: [0-9.]+\\)$")
  all(vapply(lines, function(l) any(vapply(known, grepl, logical(1), l)),
             logical(1)))
}
is_incoming <- grepl("CRAN incoming feasibility", res$notes, fixed = TRUE)
expected <- grepl("V8", res$notes, fixed = TRUE) |
  (is_incoming & vapply(res$notes, incoming_expected, logical(1)))
unexpected <- res$notes[!expected]
if (length(res$errors) || length(res$warnings) || length(unexpected)) {
  cat("\nFAIL: unexpected check results.\n")
  if (length(unexpected)) cat(paste(unexpected, collapse = "\n"), "\n")
  quit(status = 1)
}
cat("\n", length(res$notes), " note(s), all expected.\n", sep = "")

# Not a failure, but worth seeing before a submission: CRAN asks that updates
# come no more often than every one to two months. R reports "Days since last
# update" only in the first week after a release, so the date of the last
# CRAN release is kept in tools/cran-release-date (one line, YYYY-MM-DD, set
# when CRAN accepts a version) and the days are counted from it. The note's
# own count is used when R gives one.
days <- regmatches(res$notes, regexpr("Days since last update: [0-9]+", res$notes))
n <- if (length(days)) as.integer(sub("\\D+", "", days[1])) else NA_integer_
release_file <- file.path(root, "tools", "cran-release-date")
if (is.na(n) && file.exists(release_file)) {
  # An empty file or a line not in YYYY-MM-DD form gives no reminder rather
  # than failing the gate after a clean check.
  x <- readLines(release_file, n = 1L, warn = FALSE)
  released <- if (length(x)) {
    as.Date(trimws(x), format = "%Y-%m-%d")
  } else {
    as.Date(NA)
  }
  if (!is.na(released)) n <- as.integer(Sys.Date() - released)
}
if (!is.na(n) && n < 60L) {
  cat("Reminder: CRAN last updated this package ", n, " day(s) ago. CRAN asks ",
      "for updates no more often than every one to two months.\n", sep = "")
}

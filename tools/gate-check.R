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
# come no more often than every one to two months.
days <- regmatches(res$notes, regexpr("Days since last update: [0-9]+", res$notes))
if (length(days)) {
  n <- as.integer(sub("\\D+", "", days[1]))
  if (n < 60L) {
    cat("Reminder: CRAN last updated this package ", n, " day(s) ago. CRAN asks ",
        "for updates no more often than every one to two months.\n", sep = "")
  }
}

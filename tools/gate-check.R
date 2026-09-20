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

Sys.setenv("_R_CHECK_CRAN_INCOMING_REMOTE_" = "TRUE")
res <- rcmdcheck::rcmdcheck(tarball, args = "--as-cran", error_on = "never",
                            quiet = TRUE, check_dir = file.path(out, "chk"))
print(res)

# Two notes are expected until the package is on CRAN: the new-submission note,
# and math rendering skipped where V8 is unavailable. Anything else is a
# finding, and errors and warnings always are.
unexpected <- res$notes[!grepl("New submission|V8", res$notes)]
if (length(res$errors) || length(res$warnings) || length(unexpected)) {
  cat("\nFAIL: unexpected check results.\n")
  if (length(unexpected)) cat(paste(unexpected, collapse = "\n"), "\n")
  quit(status = 1)
}
cat("\n", length(res$notes), " note(s), all expected.\n", sep = "")

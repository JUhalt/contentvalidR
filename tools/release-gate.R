# Release gate for contentvalidR. Run from the package root:
#
#   Rscript tools/release-gate.R
#
# Each stage runs in its own R process, which is the point rather than a
# detail: the build stage calls devtools::document(), and a session that has
# loaded contentvalidR cannot install it on Windows ("package is in use"). The
# smoke test therefore has to run somewhere that never loaded it, or it proves
# nothing about a clean install (#51).
#
# Stages, in order:
#   1. build  - document, README, spelling, URLs, build the tarball, inspect it
#   2. smoke  - install the tarball into an empty library, run it there
#   3. check  - R CMD check --as-cran on the tarball, with CRAN's incoming checks
#
# Output directory defaults to a short path, because Windows' 260-character
# limit truncates check directories nested any deeper.

root <- normalizePath(".", winslash = "/")
if (!file.exists(file.path(root, "DESCRIPTION"))) {
  stop("Run this from the package root.", call. = FALSE)
}
version <- read.dcf(file.path(root, "DESCRIPTION"), fields = "Version")[1, 1]
out <- file.path(Sys.getenv("TEMP", tempdir()), paste0("cvr-gate-", version))
dir.create(out, recursive = TRUE, showWarnings = FALSE)

rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
stages <- c("build", "smoke", "check")
args <- commandArgs(trailingOnly = TRUE)
if (length(args)) stages <- intersect(stages, args)

cat("contentvalidR release gate\n")
cat("version: ", version, "\n", sep = "")
cat("workdir: ", out, "\n", sep = "")

# Each stage tests what the previous one produced, so once one fails the rest
# are skipped rather than run: a later stage reporting PASS after an earlier
# FAIL has, at best, tested something other than this source.
status <- integer(0)
for (stage in stages) {
  if (any(status != 0, na.rm = TRUE)) {
    status[stage] <- NA_integer_
    next
  }
  cat("\n", strrep("=", 70), "\n== ", stage, "\n", strrep("=", 70), "\n", sep = "")
  script <- file.path(root, "tools", paste0("gate-", stage, ".R"))
  # --vanilla so no user profile can load the package behind our back.
  code <- system2(rscript, c("--vanilla", shQuote(script), shQuote(out), shQuote(root)))
  status[stage] <- code
}

cat("\n", strrep("=", 70), "\n== summary\n", strrep("=", 70), "\n", sep = "")
for (stage in names(status)) {
  label <- if (is.na(status[[stage]])) {
    "SKIP (an earlier stage failed)"
  } else if (status[[stage]] == 0) "PASS" else "FAIL"
  cat(sprintf("%-6s %s\n", stage, label))
}
if (any(is.na(status) | status != 0)) {
  cat("\nA stage failed. The gate is the last check before a release, so fix\n",
      "the cause rather than working around it by hand.\n", sep = "")
  quit(status = 1)
}
cat("\nAll stages passed. The tarball is at:\n  ",
    file.path(out, paste0("contentvalidR_", version, ".tar.gz")), "\n", sep = "")

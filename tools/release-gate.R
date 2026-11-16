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
#   2. tests  - run the whole test suite from the source tree the tarball was
#               built from, where the tests that read the sources do not skip
#   3. smoke  - install the tarball into a library that holds nothing else but
#               the packages it declares it needs, and run it there
#   4. check  - R CMD check --as-cran on the tarball, with CRAN's incoming
#               checks
#
# tests comes second because it needs what build leaves (the regenerated
# man/, and the stamp of the tree that was built) and because it fails in
# minutes, before smoke and the long check stage are spent on a source that
# is not ready.
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
# devtools asks pak for the package's dependencies, and pak gives its helper
# process five seconds to start. On a busy machine that is not enough, and
# the build stage stops with "Subprocess is busy or cannot start" at
# build_readme(), after document() and before any of its checks has run.
# The stages inherit this longer wait (in milliseconds); a value already set
# is left alone.
if (!nzchar(Sys.getenv("PKG_SUBPROCESS_TIMEOUT"))) {
  Sys.setenv(PKG_SUBPROCESS_TIMEOUT = "120000")
}

known <- c("build", "tests", "smoke", "check")
args <- commandArgs(trailingOnly = TRUE)
# A mistyped stage name must not run nothing and then report success.
unknown <- setdiff(args, known)
if (length(unknown)) {
  stop("Unknown stage: ", paste(unknown, collapse = ", "), ". The stages are ",
       paste(known, collapse = ", "), ".", call. = FALSE)
}
stages <- if (length(args)) intersect(known, args) else known

cat("contentvalidR release gate\n")
cat("version: ", version, "\n", sep = "")
cat("workdir: ", out, "\n", sep = "")

# Every stage after build depends on it: the tests stage runs on the source
# the tarball was built from, and smoke and check run on the tarball. So once
# a stage fails the rest are skipped rather than run. After a failed build, a
# later stage reporting PASS has, at best, tested something other than this
# source. After a failed tests stage, the source is not ready, and an hour of
# check would only delay the fix.
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
# A run of some stages is not the gate, whether or not those stages passed.
# That includes a run of build, smoke and check, which was the whole gate
# before the tests stage existed.
not_run <- setdiff(known, names(status))
for (stage in not_run) cat(sprintf("%-6s %s\n", stage, "not run"))
if (any(is.na(status) | status != 0)) {
  cat("\nA stage failed. The gate is the last check before a release, so fix\n",
      "the cause rather than working around it by hand.\n", sep = "")
  quit(status = 1)
}
if (length(not_run)) {
  cat("\nThe stages that ran passed, but this was not the whole gate: ",
      paste(not_run, collapse = ", "), " did not run. Only a run of all ",
      length(known), " stages is the gate.\n", sep = "")
} else {
  cat("\nAll stages passed. The tarball is at:\n  ",
      file.path(out, paste0("contentvalidR_", version, ".tar.gz")), "\n", sep = "")
}

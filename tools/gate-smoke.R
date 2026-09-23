# Stage 2: install the built tarball into an empty library and use it there.
#
# Nothing in this process may load contentvalidR before the install: on Windows
# an R session holding the package cannot overwrite it, and install.packages()
# warns "package is in use" and carries on, leaving the smoke test to fail on a
# package that was never installed (#51). The gate therefore runs this stage as
# its own process, and the smoke script itself runs in a third one so its
# library path holds only base R and the new install.

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
if ("contentvalidR" %in% loadedNamespaces()) {
  cat("FAIL: contentvalidR is loaded in this session, so the install would be",
      " skipped. That is the bug this staging exists to prevent.\n", sep = "")
  quit(status = 1)
}

lib <- file.path(out, "lib")
empty <- file.path(out, "empty")
unlink(lib, recursive = TRUE)
dir.create(lib, showWarnings = FALSE)
dir.create(empty, showWarnings = FALSE)

cat("-- installing into a clean library\n")
utils::install.packages(tarball, lib = lib, repos = NULL, type = "source",
                        quiet = TRUE)
if (!dir.exists(file.path(lib, "contentvalidR"))) {
  cat("FAIL: the package did not install into ", lib, ".\n", sep = "")
  quit(status = 1)
}
cat("installed: ", dir(lib), "\n", sep = "")

cat("\n-- running the smoke test against that library\n")
rscript <- file.path(R.home("bin"),
                     if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
Sys.setenv(R_LIBS = lib, R_LIBS_USER = empty, R_LIBS_SITE = empty)
code <- system2(rscript, c("--vanilla",
                           shQuote(file.path(root, "tools", "gate-smoke-run.R"))))
if (code != 0) {
  cat("FAIL: the smoke test exited with status ", code, ".\n", sep = "")
  quit(status = 1)
}

# Stage 2: install the built tarball into an empty library and use it there.
#
# Nothing in this process may load contentvalidR before the install: on Windows
# an R session holding the package cannot overwrite it, and install.packages()
# warns "package is in use" and carries on, leaving the smoke test to fail on a
# package that was never installed (#51). The gate therefore runs this stage as
# its own process, and the smoke script itself runs in a third one so its
# library path holds only the packages that ship with R, the new install, and
# the packages the new install declares it needs.

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
unlink(lib, recursive = TRUE, force = TRUE)
if (dir.exists(lib)) {
  cat("FAIL: could not clear ", lib, " from an earlier run.\n", sep = "")
  quit(status = 1)
}
dir.create(lib, showWarnings = FALSE)
dir.create(empty, showWarnings = FALSE)

# The packages the source declares it needs (Depends, Imports and LinkingTo,
# and theirs in turn), other than those that ship with R. They are found
# before the install so that a missing one is named here: R refuses to
# install a package whose dependency is absent, and the quiet install below
# would not say which.
declared <- function(description) {
  fields <- read.dcf(description, fields = c("Depends", "Imports", "LinkingTo"))
  x <- unlist(strsplit(fields[!is.na(fields)], ","))
  x <- trimws(gsub("[(][^)]*[)]", "", x))
  setdiff(x[nzchar(x)], "R")
}
needs <- character(0)
todo <- declared(file.path(root, "DESCRIPTION"))
while (length(todo)) {
  pkg <- todo[1]
  todo <- todo[-1]
  # Base and recommended packages are on the smoke test's path already.
  if (pkg %in% names(needs) || dir.exists(file.path(.Library, pkg))) next
  from <- tryCatch(find.package(pkg), error = function(e) NA_character_)
  if (is.na(from)) {
    cat("FAIL: the package declares ", pkg, ", directly or through a",
        " dependency, and it is not installed on this machine.\n", sep = "")
    quit(status = 1)
  }
  needs[pkg] <- from
  todo <- c(todo, declared(file.path(from, "DESCRIPTION")))
}

cat("-- installing into a clean library\n")
utils::install.packages(tarball, lib = lib, repos = NULL, type = "source",
                        quiet = TRUE)
if (!dir.exists(file.path(lib, "contentvalidR"))) {
  cat("FAIL: the package did not install into ", lib, ".\n", sep = "")
  quit(status = 1)
}
cat("installed: ", dir(lib), "\n", sep = "")

# The clean library also gets those declared packages, copied from this
# machine's library, and nothing else. A package from outside R's own library
# that is used without being declared is then still missing, and the smoke
# test fails on it. (The packages that ship with R, base and recommended, are
# always on the path, so the smoke test cannot catch an undeclared use of
# one of those; R CMD check does.)
for (pkg in names(needs)) {
  if (!file.copy(needs[[pkg]], lib, recursive = TRUE, copy.mode = FALSE)) {
    cat("FAIL: could not copy ", pkg, " into ", lib, ".\n", sep = "")
    quit(status = 1)
  }
  cat("declared dependency added: ", pkg, " ",
      read.dcf(file.path(needs[[pkg]], "DESCRIPTION"), fields = "Version")[1, 1],
      " (copied from ", dirname(needs[[pkg]]), ")\n", sep = "")
}
if (!length(needs)) {
  cat("declared dependencies beyond the packages that ship with R: none\n")
}

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

# Stage 1: document, README, spelling, URLs, build the tarball, inspect it.
# This stage loads the package (devtools::document() does), which is why the
# install and smoke test happen in a different process.

args <- commandArgs(trailingOnly = TRUE)
out <- args[[1]]
root <- args[[2]]
setwd(root)

fail <- function(...) {
  cat("FAIL: ", ..., "\n", sep = "")
  quit(status = 1)
}

source(file.path(root, "tools", "gate-stamp.R"))

# Remove the previous tarball before anything can fail, so a build that stops
# early leaves nothing behind for a later stage to mistake for its own output.
version <- read.dcf(file.path(root, "DESCRIPTION"), fields = "Version")[1, 1]
old <- file.path(out, paste0("contentvalidR_", version, ".tar.gz"))
unlink(c(old, gate_stamp_path(old)))

cat("-- document and README\n")
devtools::document(quiet = TRUE)
devtools::build_readme(quiet = TRUE)

cat("\n-- spelling\n")
misspelled <- spelling::spell_check_package(".")
if (nrow(misspelled)) {
  print(misspelled)
  fail("spelling found ", nrow(misspelled), " word(s) not in inst/WORDLIST.")
}
cat("no spelling errors\n")

cat("\n-- URLs\n")
urls <- urlchecker::url_check(".")
if (NROW(urls)) {
  print(urls)
  fail(NROW(urls), " URL(s) need attention.")
}
cat("all URLs resolve\n")

cat("\n-- build\n")
tarball <- devtools::build(path = out, manual = TRUE, quiet = TRUE)
# document() and build_readme() have already run, so this is the tree the
# tarball was built from.
writeLines(gate_source_stamp(root), gate_stamp_path(tarball))
cat("tarball: ", tarball, " (", round(file.size(tarball) / 1024), " KB)\n", sep = "")

files <- utils::untar(tarball, list = TRUE)
cat("files in tarball: ", length(files), "\n", sep = "")

hidden <- files[grepl("/[.]", files)]
if (length(hidden)) {
  print(hidden)
  # CRAN returned 0.3.1 for exactly this, a .git file from a worktree build.
  fail(length(hidden), " hidden file(s) in the tarball.")
}
cat("hidden files: 0\n")

ignored <- c("ROADMAP.md", "cran-comments.md", "CITATION.cff", ".github",
             "_pkgdown.yml", "README.Rmd", ".Rproj", "LICENSE.md", "tools/")
leaked <- files[vapply(files, function(f) {
  any(vapply(ignored, function(p) grepl(p, f, fixed = TRUE), logical(1)))
}, logical(1))]
if (length(leaked)) {
  print(leaked)
  fail(length(leaked), " build-ignored file(s) reached the tarball.")
}
cat("build-ignored files: 0\n")

utils::untar(tarball, files = "contentvalidR/DESCRIPTION", exdir = out)
inside <- read.dcf(file.path(out, "contentvalidR", "DESCRIPTION"),
                   fields = "Version")[1, 1]
declared <- read.dcf(file.path(root, "DESCRIPTION"), fields = "Version")[1, 1]
if (!identical(inside, declared)) {
  fail("tarball says version ", inside, ", the source says ", declared, ".")
}
cat("version inside tarball: ", inside, "\n", sep = "")

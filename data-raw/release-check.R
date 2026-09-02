# contentvalidR release-check helper
#
# Run from the package root during v0.0.8 / pre-release hardening.
# This file lives under data-raw/ and is excluded from the source tarball.

stopifnot(file.exists("DESCRIPTION"), file.exists("NAMESPACE"))

message("1/7: roxygen documentation")
devtools::document()

message("2/7: unit/regression tests")
devtools::test()

message("3/7: README")
devtools::build_readme()

message("4/7: standard package check")
devtools::check()

message("5/7: CRAN-style package check")
devtools::check(args = "--as-cran")

message("6/7: URLs and spelling (when developer helpers are installed)")
if (requireNamespace("urlchecker", quietly = TRUE)) {
  print(urlchecker::url_check())
} else {
  message("  urlchecker not installed; run install.packages('urlchecker') if desired.")
}
if (requireNamespace("spelling", quietly = TRUE)) {
  print(spelling::spell_check_package())
} else {
  message("  spelling not installed; run install.packages('spelling') if desired.")
}

message("7/7: pkgdown site")
if (requireNamespace("pkgdown", quietly = TRUE)) {
  pkgdown::build_site()
} else {
  message("  pkgdown not installed; run install.packages('pkgdown') and build the site before release.")
}

message("Release helper finished. Review every warning/note rather than treating completion as success.")

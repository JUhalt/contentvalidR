## Test environments

* Local Windows 11: `R CMD check --as-cran`
* GitHub Actions:
  * Windows release
  * macOS release
  * Ubuntu release
  * Ubuntu oldrel-1
  * Ubuntu devel
  * Ubuntu devel with `--as-cran` and NOTE-as-failure

## R CMD check results

0 errors | 0 warnings | 0 notes

The local `--as-cran` check completed cleanly. The full six-job GitHub Actions
matrix also completed successfully, including the dedicated R-devel
`--as-cran` job configured to fail on NOTE.

## Additional release checks

* Package documentation and tests completed successfully.
* README and vignettes built successfully from clean source.
* The pkgdown site built successfully and is published through GitHub Pages.
* URL checking completed successfully after GitHub Pages deployment.
* Spelling review was completed; technical terms, acronyms, and proper names
  were handled through the package word list where appropriate.

## Submission notes

This will be the first CRAN submission of `contentvalidR`.

## Resubmission

This is a resubmission. In this version I have:

* Replaced the relative links to `LICENSE.md` and `ROADMAP.md` in README.md
  with full URLs. Those files are not part of the built package, so the
  incoming checks for 0.3.0 reported them as invalid file URIs. Nothing else
  changed.

## Test environments

* Local: Windows 11, R 4.6.1, `R CMD check --as-cran` on the built source
  tarball
* GitHub Actions:
  * Windows, R release
  * macOS, R release
  * Ubuntu, R release
  * Ubuntu, R oldrel-1
  * Ubuntu, R devel
  * Ubuntu, R devel with `--as-cran`, configured to fail on any NOTE

## R CMD check results

0 errors | 0 warnings | 3 notes

* checking CRAN incoming feasibility ... NOTE
  New submission

  This is the first submission of contentvalidR.

* checking HTML version of manual ... NOTE
  Skipping checking math rendering: package 'V8' unavailable

  This comes from the local Windows check machine, where the optional V8
  package is not installed. It does not concern the package.

* checking for detritus in the temp directory ... NOTE
  Found the following files/directories: 'lastMiKTeXException'

  MiKTeX on the local Windows check machine writes this file while building
  the PDF manual. The package's code, examples, tests, and vignettes do not
  create it.

The built tarball was also installed into an empty library, where the examples
for every help topic, all seven vignettes, and the citation ran successfully.

## Submission notes

* This is the first CRAN submission of contentvalidR.
* The words flagged as possibly misspelled in DESCRIPTION are spelled
  correctly. Colquitt, Crocker, Geisinger, Gerbing, Hinkin, Krippendorff,
  Lawshe, Llabre, Melloy, and Sireci are author surnames. HTC and HTD are the
  Hinkin-Tracey correspondence and distinctiveness indices, and "et al." is the
  standard citation abbreviation.
* contentvalidR is distinct from the CRAN package contentValidity (version
  0.2.0). contentValidity computes item- and scale-level content validity
  indices: I-CVI, S-CVI, modified kappa, Aiken's V, and Lawshe's CVR.
  contentvalidR also provides substantive-validity item sorting (Anderson and
  Gerbing, 1991), the construct-rating procedure of Hinkin and Tracey (1999),
  judge-heterogeneity and content-domain coverage analyses, and panel-level
  agreement, organized into workflows that return interpretable summaries.
  Some expert-panel indices overlap, but the scope differs, and the package
  names differ.
* The package imports only `stats` and contains no compiled code.
* The Description field gives DOIs for the implemented methods.

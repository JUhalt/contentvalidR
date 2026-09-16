## Resubmission

This is a resubmission. Both earlier versions were returned by the incoming
checks, and this version fixes each problem:

* 0.3.0 was returned for "Found the following (possibly) invalid file URIs:
  LICENSE.md, ROADMAP.md (from README.md)". README.md now links to both files
  with full URLs.
* 0.3.1 was returned for "Found the following hidden files and directories:
  .git". That tarball had been built from a git worktree checkout, where `.git`
  is a file rather than a directory, and `R CMD build` did not drop it.
  `.Rbuildignore` now excludes `.git`, `.gitignore`, and `.gitattributes`, and
  the contents of the built tarball were listed to confirm it contains no
  hidden files.

The version is 0.4.0 rather than a further patch because it also adds new
functionality: a documented handoff of content-reviewed items to downstream
empirical workflows, and a selectable criterion for parallel analysis.

## Test environments

* Local: Windows 11, R 4.6.1, `R CMD check --as-cran` on the built source
  tarball
* win-builder: R-devel
* GitHub Actions:
  * Windows, R release
  * macOS, R release
  * Ubuntu, R release
  * Ubuntu, R oldrel-1
  * Ubuntu, R devel
  * Ubuntu, R devel with `--as-cran`, configured to fail on any NOTE

## R CMD check results

0 errors | 0 warnings | 2 notes

* checking CRAN incoming feasibility ... NOTE
  New submission

  No version of contentvalidR is on CRAN yet. On win-builder the same NOTE
  also lists possibly misspelled words in DESCRIPTION, explained below.

* checking HTML version of manual ... NOTE
  Skipping checking math rendering: package 'V8' unavailable

  This comes from the local Windows check machine, where the optional V8
  package is not installed. It does not concern the package.

The built tarball contains no hidden files. Installed into an empty library,
it ran the examples for all 40 help topics, all eight vignettes, and the
citation.

## Submission notes

* No version of contentvalidR is on CRAN yet, so the incoming checks report a
  new submission.
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

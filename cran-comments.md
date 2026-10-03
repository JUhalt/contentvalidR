## Update

This is an update of contentvalidR from 0.4.0, on CRAN since 2026-09-28, to
1.0.0. The versions in between were released on GitHub and R-universe only.

* One exported function is removed: `agreement_summary()`. It was deprecated
  in 0.9.0, with a warning naming its replacement, `panel_agreement()`. That
  warning shipped only on GitHub and R-universe, so CRAN users go from 0.4.0,
  where the function works, to 1.0.0, where it is gone; NEWS.md records the
  removal and the replacement. No other function, argument or returned field
  that 0.4.0 exported is removed.
* Several results change because methods were corrected after an audit of the
  package against its sources. NEWS.md lists each change under "values that
  change", with the reason.
* The printed output of every function changed to a style shared with the
  companion package nomologR. Printed output is outside the package's
  stability policy (`?contentvalidR`).

## Test environments

To be completed at submission, from the release gate and win-builder:

* Local: Windows 11, R 4.6.1, `R CMD check --as-cran` on the built source
  tarball
* win-builder: R-devel
* GitHub Actions: Windows, macOS and Ubuntu with R release; Ubuntu with R
  oldrel-1 and R devel; Ubuntu R devel with `--as-cran`, configured to fail on
  any NOTE

## R CMD check results

To be completed at submission from the raw win-builder log (00check.log).

* checking HTML version of manual ... NOTE
  Skipping checking math rendering: package 'V8' unavailable

  This comes from the local Windows check machine, where the optional V8
  package is not installed. It does not concern the package.

## Reverse dependencies

To be confirmed at submission with `tools::package_dependencies("contentvalidR",
reverse = TRUE, which = "all")`. The companion package nomologR reads
contentvalidR's handoff object; it is maintained by the same author.

## Submission notes

* The words flagged as possibly misspelled in DESCRIPTION are spelled
  correctly. Colquitt, Crocker, Geisinger, Gerbing, Hinkin, Krippendorff,
  Lawshe, MacKenzie, Melloy, Sireci and Tracey are author surnames, and "et
  al." is the standard citation abbreviation.
* The package imports only `stats` and contains no compiled code.
* The Description field gives DOIs for the implemented methods.

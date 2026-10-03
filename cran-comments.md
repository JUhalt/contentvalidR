## Update

This is an update of contentvalidR from 0.4.0, on CRAN since 2026-09-28, to
1.0.0. The versions in between were released on GitHub and R-universe only.

* One exported function is removed: `agreement_summary()`. It was deprecated
  in 0.9.0, with a warning naming its replacement, `panel_agreement()`. That
  warning shipped only on GitHub and R-universe, so CRAN users go from 0.4.0,
  where the function works, to 1.0.0, where it is gone; NEWS.md records the
  removal and the replacement.
* Also removed since 0.4.0, each recorded in NEWS.md with its reason:
  `anova_content()`'s `posthoc` argument (deprecated from the first release,
  removed in 0.7.0) and its `posthoc_pass` column (removed in 0.8.0);
  `overall_strength` in the `scale_summary` of `sort_validity()` and
  `rating_validity()`, `n_support` in that of `expert_validity()` and
  `competitor_ioc` in its congruence results, `n_influential` in the
  `scale_summary` of `judge_validity()`, and `fit_label` in the `fit`
  table of `content_structure()`. These five fields were removed in 1.0.0
  without a notice period because they were wrong or unreachable;
  `?contentvalidR` says so beside the deprecation policy.
* `content_report()` returns an APA table by default since 0.9.0;
  `format = "data.frame"` gives the numeric table.
* Several results change because methods were corrected after an audit of the
  package against its sources. NEWS.md lists each change under "values that
  change", with the reason, and lists the stored sentences that now follow
  the printed rounding rules under "Stored text that changes".
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
  correctly: Colquitt, Crocker, Geisinger, Gerbing, Hinkin, Krippendorff,
  Lawshe, MacKenzie, Melloy, and Sireci are author surnames;
  "generalizability" is the standard term of generalizability theory; and
  "et al." is the standard citation abbreviation. To be confirmed against
  the raw win-builder log at submission.
* The package imports only `stats` and contains no compiled code.
* The Description field gives DOIs for the principal methods.

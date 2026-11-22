## Update

This is an update of contentvalidR from 0.4.0, on CRAN since 2026-09-28, to
1.0.1. The versions in between, 0.5.0 through 1.0.0, were released on GitHub
and R-universe only. 1.0.1 is the stable 1.0.0 with APA's table forms in
`content_report()` and the fixes from a last review before this submission;
NEWS.md lists both.

* One exported function is removed: `agreement_summary()`. It was deprecated
  in 0.9.0, with a warning naming its replacement, `panel_agreement()`. That
  warning shipped only on GitHub and R-universe, so CRAN users go from 0.4.0,
  where the function works, to 1.0.1, where it is gone; NEWS.md records the
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
* `expert_validity()` gained `ioc_cut` in 1.0.0 as its tenth argument, ahead
  of `proportion_ci`. A call written for 0.4.0 that passes `proportion_ci`
  or a later argument by position now stops with a message about `ioc_cut`
  rather than using the default interval.
* `content_report()` returns an APA table by default since 0.9.0;
  `format = "data.frame"` gives the numeric table.
* `aikens_v()` no longer assumes a 1 to 5 scale: `lo` and `hi` must be
  given, and a call without them stops with a message naming both. Code
  that ran under 0.4.0 with the defaults stops here; NEWS.md gives the
  reason under "Expert panel: values that change".
* Several results change because methods were corrected after an audit of the
  package against its sources. NEWS.md lists each change under "values that
  change", with the reason, and lists the stored sentences that now follow
  the printed rounding rules under "Stored text that changes".
* The printed output of every function changed to a style shared with the
  companion package nomologR. Printed output is outside the package's
  stability policy (`?contentvalidR`).
* The package now imports withr. A function given `seed` runs its bootstrap
  or parallel analysis inside `withr::with_seed()`, which leaves the
  session's random stream as it was; the package does not write to the
  global environment.

## Test environments

* Local: Windows 11, R 4.6.1, `R CMD check --as-cran` on the built source
  tarball, with the incoming checks run remotely
* win-builder: R-devel and R-release
* GitHub Actions: Windows, macOS and Ubuntu with R release; Ubuntu with R
  oldrel-1 and R devel; Ubuntu R devel with `--as-cran`, configured to fail on
  any NOTE
* R-universe: Linux, macOS and Windows binaries with R release and devel, and
  oldrel on macOS and Windows

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Possibly misspelled words in DESCRIPTION: MacKenzie

  MacKenzie is an author surname (MacKenzie et al., 2011), cited with its
  DOI in the Description field.

## Reverse dependencies

There are no reverse dependencies on CRAN
(`tools::package_dependencies("contentvalidR", reverse = TRUE, which = "all")`
returns none). The companion package nomologR, by the same maintainer, reads
contentvalidR's handoff object without depending on contentvalidR; it is not
yet on CRAN.

## Submission notes

* The package imports only `stats` and `withr` and contains no compiled code.
* The Description field gives DOIs for the principal methods.

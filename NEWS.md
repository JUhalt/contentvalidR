# contentvalidR 0.0.2.9000

## Modern item-sort workflow

* Added Colquitt et al. (2019) empirical Psa/Csv interpretation bands, including
  overall and focal-orbiting-correlation-conditional norms.
* Colquitt labels are applied to target-scale averages, matching how the
  published norms were constructed, rather than being presented as validated
  item-level cutoffs.
* `sort_validity()` now reports target-scale definitional correspondence and
  distinctiveness alongside Howard-Melloy item-level Retain/Review decisions.
* Added optional focal-orbiting correlations and explicit naive/expert judge
  handling; Colquitt norms are suppressed for expert panels.
* `compute_csv()` now reports the strongest competing construct(s), making item
  confusion easier to diagnose.
* Added `sort_power()` for exact binomial design/power planning.
* Added `plot.contentvalid_sort()` for dependency-free item-level Psa/Csv plots.
* Added a dedicated item-sort vignette and expanded regression tests.

# contentvalidR 0.0.1.9000

## Methodological foundation

* Fixed `compute_csv()` when all non-target assignments fall in a single
  construct; unanimous assignment to the same wrong construct now correctly
  yields `Csv = -1`.
* `compute_psa()` and `compute_csv()` now use non-missing itemwise denominators,
  report `n_total`, `n`, and `n_missing`, and validate duplicate item-rater rows
  and inconsistent target mappings.
* Corrected Polit-Beck-Owen modified kappa in `cvi()` to use the probability of
  exactly `A` agreements, and added S-CVI/UA plus item-specific effective judge
  counts.
* Corrected confusion-matrix orientation in `signal_detection()` and changed
  phi calculations to preserve the direction of association.
* Reproducibility diagnostics now retain a full 2 x 2 table even when a decision
  level is absent.
* Clarified `csv_binom_test()` as exact Howard-Melloy target-count inference and
  added the critical target-assignment count to its output.
* Added `sort_validity()` as the first recommended user-facing workflow, with
  classed results, informative `print()`/`summary()` methods, and restrained
  Retain/Review/Insufficient-data recommendations.
* Replaced the placeholder unit test with substantive regression and edge-case
  tests.
* Consolidated GitHub Actions into one cross-platform R CMD check workflow and
  removed an obsolete workflow that tested unsupported R versions.

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

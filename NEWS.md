# contentvalidR 0.0.4.9000

### Final visualization polish

- Deterministically stagger nearby target-scale labels on Psa/Csv and HTC/HTD evidence maps so similar scale means remain legible without manual annotation.
- Draw the exact critical-Psa planning view as an integer-N step function, with requested design points overlaid, to reflect the discrete binomial retention rule rather than implying smooth interpolation.
- Added regression tests for map-label separation and the full integer critical-Psa curve.

### Visualization polish

- Tightened default axis labels and plot keys so diagnostic graphics remain readable in smaller RStudio plotting panes.
- Moved profile/expert plot keys into reserved top space and moved item-sort power keys to a low-conflict location.
- Added `show_legend = FALSE` to workflow plot methods for compact/custom reporting.
- Reduced map-label collisions by separating item labels from target-scale-mean labels.
- Fixed the expert-panel vignette plotting object name and aligned the item-sort vignette index title with its YAML title.

## Visualization and roadmap closure

* Added correspondence-distinctiveness evidence maps for item-sort (Psa/Csv) and construct-rating (HTC/HTD) workflows, with target-scale means shown separately from item points.
* Added a Hinkin-Tracey target-versus-strongest-competitor gap plot and strengthened expert-panel plots for Aiken V/I-CVI, CVR critical values, and IOC target-versus-competitor margins.
* Added plotting for exact item-sort power and the critical observed-Psa boundary.
* Added canonical published/hand-worked reference tests, including Hinkin-Tracey Study 1 mean ratings, Polit-Beck-Owen modified kappa, and the Ayre-Scally N=10 CVR boundary.
* Closed the Anderson-Gerbing legacy-inference decision: Psa/Csv remain supported, but the obsolete critical-Csv decision rule is not exposed as an alternate workflow because Howard-Melloy is applicable to multi-choice sorts and agrees in the original two-choice case.


## Expert-panel workflow and repository hygiene

* Added `expert_validity()` with relevance, essentiality, and congruence modes plus informative `print()`, `summary()`, and `plot()` methods.
* Hardened Aiken's V and made the Penfield-Giacobbi score confidence interval the default deterministic interval; bootstrap intervals remain available.
* Extended `cvr()` to support item-specific panel sizes and judge-by-item 0/1 input, with exact one-sided binomial p-values and critical counts following Ayre and Scally's revisiting of Lawshe's method.
* Hardened `ioc()` input validation, duplicate detection, and missing-data reporting.
* Added common panel-size CVI guidelines to the user-facing relevance workflow while explicitly treating them as review aids rather than universal validity cutoffs.
* Updated GitHub Actions from `actions/checkout@v4` to the current Node-24-compatible `actions/checkout@v7` line.
* Expanded public README guidance and added a dedicated expert-panel vignette.

# contentvalidR 0.0.3.9000

## Modern construct-rating workflow

* Added `htc()` and `htd()` for Hinkin-Tracey definitional correspondence and
  distinctiveness, with explicit rating-anchor validation.
* Rebuilt `anova_content()` around the fully crossed within-judge design used by
  the Hinkin-Tracey rating procedure. The function now uses a one-way repeated-
  measures ANOVA with Greenhouse-Geisser corrected omnibus inference plus planned
  target-versus-orbiting contrasts and retains a between-judge path only for
  genuinely independent designs. Raw omnibus p values remain available for
  transparency.
* Added `rating_validity()` as the recommended user-facing construct-rating
  workflow, including strongest-competitor diagnostics, Retain/Review/
  Insufficient-data screening, and narrative print/summary output.
* Extended Colquitt et al. (2019) scale-level interpretation to HTC and HTD,
  including focal-orbiting-correlation-conditional norms and expert-judge
  suppression.
* Added `plot.contentvalid_rating()` for dependency-free HTC/HTD item plots.
* Added a dedicated Hinkin-Tracey-to-Colquitt vignette and expanded tests for
  rating indices, repeated-measures inference, incomplete profiles, and
  user-facing output.

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

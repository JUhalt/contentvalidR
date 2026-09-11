# Changelog

## contentvalidR 0.1.0.9000

### Development

- Changed the current development source to GNU GPL version 3 only
  (`GPL-3.0-only`; R metadata `GPL-3`), retaining the original MIT
  notice in `inst/NOTICE`. Previously published releases keep their
  original terms.

- Aligned citation metadata with development version `0.1.0.9000`,
  restored the README release-status paragraph outside the badge block,
  and linked roadmap workstreams to their issues and milestone.

- Refreshed generated documentation and documented the publishing
  sources.

- Recorded an optional research proposal for qualitative-evidence
  traceability under the domain-coverage issue; no statistical
  implementation changed.

- Opened post-v0.1 development toward `v0.2.0`.

- Updated installation guidance to distinguish the stable R-universe
  release from the GitHub development version.

- Replaced the completed pre-v0.1 release roadmap with an active
  post-release development plan.

- Removed the obsolete committed `DESCRIPTION.bak` file.

- Hardened Ubuntu GitHub Actions setup against stale Google Chrome apt
  repository metadata. \# contentvalidR 0.1.0

### First public release

- First public release of `contentvalidR`, providing reproducible
  quantitative tools for substantive and content-oriented scale
  pretesting.
- The recommended API centers on three complementary workflows:
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  for item sorting,
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
  for construct ratings, and
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  for relevance, essentiality, and congruence expert panels.
- Item-sort inference combines Anderson-Gerbing Psa/Csv indices with
  exact Howard-Melloy target-count inference and scale-level Colquitt et
  al. empirical interpretation benchmarks.
- Construct-rating analyses implement Hinkin-Tracey correspondence and
  distinctiveness, repeated-measures item screening with
  Greenhouse-Geisser correction, planned target-versus-orbiting
  contrasts, and Colquitt et al. scale-level interpretation.
- Expert-panel analyses support Aiken’s V with Penfield-Giacobbi score
  confidence intervals, Lawshe CVR with exact inference, CVI/modified
  kappa, and item-objective congruence.
- Flagship workflow objects share a stable user-facing structure, common
  status terminology, informative print/summary/plot methods, explicit
  missingness and design metadata, and restrained review
  recommendations.
- The release includes deterministic example data,
  workflow/design/reporting vignettes, manuscript-ready reporting
  examples, citation metadata, extensive regression and
  boundary-condition tests, and a cross-platform release matrix
  including a dedicated R-devel `--as-cran` NOTE-as-failure gate.
- Quantitative screening is explicitly framed as one component of a
  broader validity argument rather than an automatic item-retention or
  deletion rule.

## contentvalidR 0.0.8.9000

### CRAN and release hardening

- Added a dedicated CRAN-style GitHub Actions job on R-devel with
  NOTE-as-failure, while retaining release/oldrel/devel checks across
  Windows, macOS, and Linux.
- Updated the workflow to `actions/checkout@v7` and current
  `r-lib/actions@v2` conventions.
- Hardened source-package exclusions for generated pkgdown output, CRAN
  submission metadata, check directories, and source tarballs.
- Added a reproducible `data-raw/release-check.R` developer checklist
  covering documentation, tests, README, standard and `--as-cran`
  checks, optional URL/spelling audits, and pkgdown construction.
- Added a draft `cran-comments.md` for the first submission; it is
  excluded from the built package and must be populated with actual
  final check results before submission.
- Synchronized the development roadmap through v0.0.7 and moved the
  remaining CI/public-repository verification items into the v0.0.8
  release checklist.

## contentvalidR 0.0.7.9000

### Documentation and reproducibility

- Added five deterministic, human-readable example datasets for
  item-sort, construct-rating, and all three expert-panel tasks, plus a
  base-R `data-raw/` provenance script that regenerates them.
- Added a manuscript-ready reporting vignette with conservative
  methods/results scaffolds, reproducibility guidance, and examples of
  language that avoids treating statistical review flags as automatic
  validity decisions.
- Added `inst/CITATION` for the package and a centralized
  `inst/REFERENCES.bib` bibliography covering the release-defining
  methods and verified DOIs.
- Completed missing DOI metadata in core function references for Aiken
  V, Hinkin-Tracey ratings, Lawshe CVR, Penfield-Giacobbi score
  intervals, and IOC-related sources.
- Added pkgdown reference/article organization that foregrounds the
  three flagship workflows and clearly separates auxiliary compatibility
  helpers.
- Added clean-install tests for documentation assets, example-data
  schemas, citation metadata, and the pkgdown/reference structure.

## contentvalidR 0.0.6.9000

### Stable user-facing workflow API

- Harmonized
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md),
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md),
  and
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  around a common workflow-object contract: `results`, `scale_summary`,
  `settings`, `design`, and `details`, with a shared
  `contentvalid_workflow` superclass.
- Added a standardized `status` field (`Supported`, `Review`,
  `Insufficient data`, or `Descriptive only`) while preserving
  method-specific `recommendation` wording such as `Retain`,
  `Strong support`, and `Target favored`.
- Harmonized [`summary()`](https://rdrr.io/r/base/summary.html) objects
  around common counts, reviewed-item tables, scale summaries, settings,
  and design metadata; retained `n_retain`, expert `scale`/`flagged`,
  and rating `contrasts` compatibility aliases.
- Standardized design metadata for effective judge ranges and
  missingness reporting across item-sort, construct-rating, and
  expert-panel workflows.
- Standardized validation of `digits` and plot `show_legend` controls
  across the primary workflow methods and exact sort-power planning
  object.
- Added compatibility handling so pre-v0.0.6 expert workflow objects
  remain printable and summarizable.
- Reviewed low-level function names and retained the existing public
  names through v0.1.0; auxiliary diagnostic, simulation, agreement, and
  Q-factor helpers remain available but are not promoted as flagship
  workflows.
- Added API regression tests and updated README/getting-started guidance
  for the unified workflow contract.

## contentvalidR 0.0.5.9000

### Release hardening

- Added centralized validation for logical flags and column-name
  arguments used across public workflows.
- Hardened rating data against non-finite values, malformed/duplicated
  target maps, empty identifiers, and ambiguous multi-scale `orbiting_r`
  specifications.
- Added clearer safeguards for within- versus between-judge ANOVA
  designs and for distinctiveness analyses with fewer than two construct
  definitions.
- Hardened expert-panel congruence target mappings, Aiken/CVI/CVR/IOC
  missing-data flags, alpha/seed/bootstrap inputs, and Colquitt
  benchmark input handling.
- Added defensive validation to legacy/auxiliary Q-factor, agreement,
  and simulation helpers while keeping them outside the recommended
  workflow surface.
- Added a dedicated v0.0.5 regression suite for malformed inputs,
  degenerate designs, legacy-helper contracts, and S3 workflow return
  contracts.
- Added boundary-focused regression coverage for all-missing item
  columns, tiny expert panels, zero-variance/tied rating profiles,
  degenerate diagnostic 2 x 2 tables, and all-missing workflow plots.
- Hardened exact item-sort inputs against non-finite
  counts/probabilities, made Aiken bootstrap intervals safe for
  all-missing item columns, and rejected whitespace-only target
  labels/target-column names.
- Represented unattainable exact CVR critical counts as `NA` (rather
  than an out-of-range sentinel) and hardened regression tests against
  brittle error-message wording.
- Closed the v0.0.5 public-API audit with an explicit namespace/export
  contract and S3 registration regression tests; corrected the generated
  namespace snapshot so
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  is available in clean installs and vignette builds.

## contentvalidR 0.0.4.9000

#### Final visualization polish

- Deterministically stagger nearby target-scale labels on Psa/Csv and
  HTC/HTD evidence maps so similar scale means remain legible without
  manual annotation.
- Draw the exact critical-Psa planning view as an integer-N step
  function, with requested design points overlaid, to reflect the
  discrete binomial retention rule rather than implying smooth
  interpolation.
- Added regression tests for map-label separation and the full integer
  critical-Psa curve.

#### Visualization polish

- Tightened default axis labels and plot keys so diagnostic graphics
  remain readable in smaller RStudio plotting panes.
- Moved profile/expert plot keys into reserved top space and moved
  item-sort power keys to a low-conflict location.
- Added `show_legend = FALSE` to workflow plot methods for
  compact/custom reporting.
- Reduced map-label collisions by separating item labels from
  target-scale-mean labels.
- Fixed the expert-panel vignette plotting object name and aligned the
  item-sort vignette index title with its YAML title.

### Visualization and roadmap closure

- Added correspondence-distinctiveness evidence maps for item-sort
  (Psa/Csv) and construct-rating (HTC/HTD) workflows, with target-scale
  means shown separately from item points.
- Added a Hinkin-Tracey target-versus-strongest-competitor gap plot and
  strengthened expert-panel plots for Aiken V/I-CVI, CVR critical
  values, and IOC target-versus-competitor margins.
- Added plotting for exact item-sort power and the critical observed-Psa
  boundary.
- Added canonical published/hand-worked reference tests, including
  Hinkin-Tracey Study 1 mean ratings, Polit-Beck-Owen modified kappa,
  and the Ayre-Scally N=10 CVR boundary.
- Closed the Anderson-Gerbing legacy-inference decision: Psa/Csv remain
  supported, but the obsolete critical-Csv decision rule is not exposed
  as an alternate workflow because Howard-Melloy is applicable to
  multi-choice sorts and agrees in the original two-choice case.

### Expert-panel workflow and repository hygiene

- Added
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  with relevance, essentiality, and congruence modes plus informative
  [`print()`](https://rdrr.io/r/base/print.html),
  [`summary()`](https://rdrr.io/r/base/summary.html), and
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods.
- Hardened Aiken’s V and made the Penfield-Giacobbi score confidence
  interval the default deterministic interval; bootstrap intervals
  remain available.
- Extended
  [`cvr()`](https://juhalt.github.io/contentvalidR/reference/cvr.md) to
  support item-specific panel sizes and judge-by-item 0/1 input, with
  exact one-sided binomial p-values and critical counts following Ayre
  and Scally’s revisiting of Lawshe’s method.
- Hardened
  [`ioc()`](https://juhalt.github.io/contentvalidR/reference/ioc.md)
  input validation, duplicate detection, and missing-data reporting.
- Added common panel-size CVI guidelines to the user-facing relevance
  workflow while explicitly treating them as review aids rather than
  universal validity cutoffs.
- Updated GitHub Actions from `actions/checkout@v4` to the current
  Node-24-compatible `actions/checkout@v7` line.
- Expanded public README guidance and added a dedicated expert-panel
  vignette.

## contentvalidR 0.0.3.9000

### Modern construct-rating workflow

- Added
  [`htc()`](https://juhalt.github.io/contentvalidR/reference/htc.md) and
  [`htd()`](https://juhalt.github.io/contentvalidR/reference/htd.md) for
  Hinkin-Tracey definitional correspondence and distinctiveness, with
  explicit rating-anchor validation.
- Rebuilt
  [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
  around the fully crossed within-judge design used by the Hinkin-Tracey
  rating procedure. The function now uses a one-way repeated- measures
  ANOVA with Greenhouse-Geisser corrected omnibus inference plus planned
  target-versus-orbiting contrasts and retains a between-judge path only
  for genuinely independent designs. Raw omnibus p values remain
  available for transparency.
- Added
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
  as the recommended user-facing construct-rating workflow, including
  strongest-competitor diagnostics, Retain/Review/ Insufficient-data
  screening, and narrative print/summary output.
- Extended Colquitt et al. (2019) scale-level interpretation to HTC and
  HTD, including focal-orbiting-correlation-conditional norms and
  expert-judge suppression.
- Added
  [`plot.contentvalid_rating()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_rating.md)
  for dependency-free HTC/HTD item plots.
- Added a dedicated Hinkin-Tracey-to-Colquitt vignette and expanded
  tests for rating indices, repeated-measures inference, incomplete
  profiles, and user-facing output.

## contentvalidR 0.0.2.9000

### Modern item-sort workflow

- Added Colquitt et al. (2019) empirical Psa/Csv interpretation bands,
  including overall and focal-orbiting-correlation-conditional norms.
- Colquitt labels are applied to target-scale averages, matching how the
  published norms were constructed, rather than being presented as
  validated item-level cutoffs.
- [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  now reports target-scale definitional correspondence and
  distinctiveness alongside Howard-Melloy item-level Retain/Review
  decisions.
- Added optional focal-orbiting correlations and explicit naive/expert
  judge handling; Colquitt norms are suppressed for expert panels.
- [`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md)
  now reports the strongest competing construct(s), making item
  confusion easier to diagnose.
- Added
  [`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md)
  for exact binomial design/power planning.
- Added
  [`plot.contentvalid_sort()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_sort.md)
  for dependency-free item-level Psa/Csv plots.
- Added a dedicated item-sort vignette and expanded regression tests.

## contentvalidR 0.0.1.9000

### Methodological foundation

- Fixed
  [`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md)
  when all non-target assignments fall in a single construct; unanimous
  assignment to the same wrong construct now correctly yields
  `Csv = -1`.
- [`compute_psa()`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md)
  and
  [`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md)
  now use non-missing itemwise denominators, report `n_total`, `n`, and
  `n_missing`, and validate duplicate item-rater rows and inconsistent
  target mappings.
- Corrected Polit-Beck-Owen modified kappa in
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) to
  use the probability of exactly `A` agreements, and added S-CVI/UA plus
  item-specific effective judge counts.
- Corrected confusion-matrix orientation in
  [`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md)
  and changed phi calculations to preserve the direction of association.
- Reproducibility diagnostics now retain a full 2 x 2 table even when a
  decision level is absent.
- Clarified
  [`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md)
  as exact Howard-Melloy target-count inference and added the critical
  target-assignment count to its output.
- Added
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  as the first recommended user-facing workflow, with classed results,
  informative
  [`print()`](https://rdrr.io/r/base/print.html)/[`summary()`](https://rdrr.io/r/base/summary.html)
  methods, and restrained Retain/Review/Insufficient-data
  recommendations.
- Replaced the placeholder unit test with substantive regression and
  edge-case tests.
- Consolidated GitHub Actions into one cross-platform R CMD check
  workflow and removed an obsolete workflow that tested unsupported R
  versions.

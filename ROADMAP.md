# contentvalidR development roadmap

## Product principle

`contentvalidR` is not intended to be a bag of coefficients. Low-level
statistics remain available for methodological transparency, but the recommended
user experience is built around workflow objects that:

- organize item-level evidence cleanly;
- explain what the evidence supports in plain language;
- flag results that need substantive review;
- make restrained recommendations only where a method supports them;
- distinguish "review" from automatic deletion/rejection;
- disclose missingness, effective judge counts, and design limitations; and
- state what the analysis cannot establish on its own.

Quantitative pretest evidence complements theory, construct-domain coverage,
qualitative review, cognitive interviewing, and other evidence concerning
relevance, comprehensiveness, and comprehensibility.

## v0.0.1 - Methodological foundation (completed)

Goal: make the existing core statistically trustworthy before expanding the API.

- [x] Correct Csv when the target construct is never selected.
- [x] Use non-missing itemwise denominators for Psa/Csv and report missingness.
- [x] Reject duplicate item-rater rows and inconsistent item targets.
- [x] Correct Polit-Beck-Owen modified-kappa chance agreement.
- [x] Add S-CVI/UA and itemwise CVI judge counts.
- [x] Correct confusion-matrix orientation and signed phi.
- [x] Preserve a full 2 x 2 table for reproducibility diagnostics.
- [x] Document the exact target-count test as Howard-Melloy inference.
- [x] Add a first user-facing `sort_validity()` workflow with print/summary.
- [x] Replace the placeholder test with substantive regression tests.
- [x] Consolidate GitHub Actions and remove obsolete R versions.
- [x] Verify all changes under R with `document()`, `test()`, and `check()`.
- [ ] Add published/hand-worked canonical validation cases for every core method.
- [ ] Decide whether to expose the Anderson-Gerbing legacy critical-Csv test.

## v0.0.2 - Modern item-sort workflow (completed)

Goal: make A&G -> Howard-Melloy -> Colquitt the flagship module.

- [x] Add Colquitt et al. (2019) empirical interpretation bands for Psa/Csv,
      clearly labeled as normative benchmarks rather than universal cutoffs.
- [x] Support overall and orbiting-construct-conditional interpretation.
- [x] Add item and scale summaries for definitional correspondence/distinctiveness.
- [x] Add exact design/power planning for target-assignment retention rules.
- [x] Add plotting for item-sort evidence and review flags.
- [x] Add dedicated substantive-validity sort vignette.

## v0.0.3 - Modern construct-rating workflow (current)

Goal: modernize the Hinkin-Tracey side of the package.

- [x] Implement HTC (Hinkin-Tracey correspondence).
- [x] Implement HTD (Hinkin-Tracey distinctiveness).
- [x] Add Colquitt et al. (2019) HTC/HTD interpretation bands.
- [x] Redesign `anova_content()` so within-judge and between-judge designs are
      explicit and modeled appropriately.
- [x] Add Greenhouse-Geisser corrected omnibus inference for repeated-measures
      rating designs while retaining raw ANOVA output.
- [x] Add `rating_validity()` with informative print/summary methods.
- [x] Add dependency-free HTC/HTD plotting.
- [x] Add a dedicated construct-rating vignette.
- [ ] Verify the full v0.0.3 patch under R with `document()`, `test()`, `check()`,
      and `build_readme()`.

## v0.0.4 - Expert-panel workflow

Goal: provide trustworthy complementary indices without duplicating unrelated
packages merely for feature count.

Release/public-repository hygiene in this sprint:

- [ ] Update GitHub Actions dependencies to current supported majors (including
      replacing the Node-20 `actions/checkout@v4` workflow dependency).
- [ ] Confirm a warning-free Windows/macOS/Linux CI matrix after the Actions refresh.
- [ ] Refresh the public GitHub repository description/topics so they match the
      modern sort + rating + expert-panel package scope.
- [ ] Refresh README badges/public-facing wording and pkgdown-facing navigation.

- [ ] Harden Aiken's V and add a score-based confidence interval.
- [ ] Document exact CVR critical values and corrected Lawshe references.
- [x] Correct I-CVI / modified kappa calculations.
- [x] Add S-CVI/Ave and S-CVI/UA.
- [ ] Harden IOC validation and missing-data handling.
- [ ] Add `expert_validity()` with informative print/summary methods.
- [ ] Add a dedicated expert-panel vignette.

## v0.0.5 - Test hardening

Goal: reach publication-grade numerical and behavioral coverage.

- [ ] Target roughly 80-120 meaningful tests across methods and edge cases.
- [ ] Add published examples, hand calculations, boundary conditions, malformed
      input, missingness, degenerate tables, and output-contract tests.
- [ ] Add regression tests for every discovered bug.

## v0.0.6 - Stable user-facing API

- [ ] Harmonize workflow object structure across sort/rating/expert analyses.
- [ ] Implement consistent `print()`, `summary()`, and `plot()` conventions.
- [ ] Standardize terminology, recommendations, warnings, and missingness reports.
- [ ] Review low-level function names and deprecation/compatibility needs.

## v0.0.7 - Documentation and reproducibility

- [ ] Rewrite/get dedicated vignettes for each major workflow.
- [ ] Add a design-and-reporting vignette and reporting templates.
- [ ] Add example datasets and `data-raw/` provenance scripts.
- [ ] Add `inst/CITATION` and complete method references/DOIs.
- [x] Add `NEWS.md` development history.
- [ ] Organize pkgdown reference sections and articles.

## v0.0.8 - CRAN hardening

- [ ] Linux / Windows / macOS CI on release, oldrel, and devel R.
- [ ] Clean imports/suggests, examples, URLs, spelling, and source-package files.
- [ ] Build README, vignettes, and pkgdown site from clean source.
- [ ] `R CMD check --as-cran`: 0 errors, 0 warnings, 0 notes.

## v0.1.0 - First public/CRAN release

Focused release claim: reproducible quantitative tools for substantive and
content-oriented scale pretesting, centered on modern item-sort and
construct-rating workflows with complementary expert-panel indices.

## Post-0.1 parking lot

Potentially useful but not release-defining features:

- Q-factor helper / alternative extraction approaches;
- later-CFA signal-detection diagnostics;
- between-pretest reproducibility helpers;
- broader simulation framework;
- APA/report exporters;
- Bayesian extensions;
- interactive applications.

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
- [x] Add published/hand-worked canonical validation cases for every release-defining core method.
- [x] Decide whether to expose the Anderson-Gerbing legacy critical-Csv test.
      Decision: do not expose it as an alternate user-facing rule. Howard-Melloy
      is the supported default; the legacy rule adds no decision difference in
      the original two-choice case and is miscalibrated when generalized to
      multi-choice sorts.

## v0.0.2 - Modern item-sort workflow (completed)

Goal: make A&G -> Howard-Melloy -> Colquitt the flagship module.

- [x] Add Colquitt et al. (2019) empirical interpretation bands for Psa/Csv,
      clearly labeled as normative benchmarks rather than universal cutoffs.
- [x] Support overall and orbiting-construct-conditional interpretation.
- [x] Add item and scale summaries for definitional correspondence/distinctiveness.
- [x] Add exact design/power planning for target-assignment retention rules.
- [x] Add plotting for item-sort evidence and review flags.
- [x] Add dedicated substantive-validity sort vignette.

## v0.0.3 - Modern construct-rating workflow (completed)

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
- [x] Verify the full v0.0.3 patch under R with `document()`, `test()`, `check()`,
      and `build_readme()`.

## v0.0.4 - Expert-panel workflow (completed)

Goal: provide trustworthy complementary indices without duplicating unrelated
packages merely for feature count.

Release/public-repository hygiene in this sprint:

- [x] Update GitHub Actions dependencies to current supported majors (including
      replacing the Node-20 `actions/checkout@v4` workflow dependency).
- [x] Move final cross-platform CI verification into the v0.0.8 release-hardening gate so it is checked against the release candidate rather than an intermediate sprint.
- [x] Move the final public GitHub description/topics refresh into the v0.0.8 release-hygiene gate.
- [x] Refresh README badges/public-facing wording; pkgdown navigation remains in v0.0.7.

- [x] Harden Aiken's V and add a Penfield-Giacobbi score confidence interval.
- [x] Document exact CVR critical values and Ayre-Scally references.
- [x] Correct I-CVI / modified kappa calculations.
- [x] Add S-CVI/Ave and S-CVI/UA.
- [x] Harden IOC validation and missing-data handling.
- [x] Add `expert_validity()` with informative print/summary/plot methods.
- [x] Add a dedicated expert-panel vignette.
- [x] Add correspondence-distinctiveness evidence maps for sort/rating workflows,
      target-versus-competitor gap plots for rating/IOC, richer expert evidence
      plots, and exact sort-power planning plots. Full-size exported plots were
      smoke-tested and visually reviewed; final v0.0.4d polish staggers nearby
      scale labels and renders the exact critical-Psa boundary as a step function.

## v0.0.5 - Test hardening (completed)

Goal: reach publication-grade numerical and behavioral coverage.

- [x] Reach the original 80-120 meaningful-test target (103 `test_that()` blocks by the final v0.0.4d candidate).
- [x] Add published examples and hand calculations for release-defining core methods.
- [x] Complete boundary-condition, malformed-input, missingness, degenerate-design,
      and output-contract hardening across the public API.
      - [x] v0.0.5a: malformed-input/design/contract audit.
      - [x] v0.0.5b: all-missing, tiny-panel, exact-boundary, zero-variance,
            tied-profile, and degenerate-diagnostic regression pass.
      - [x] v0.0.5c: public export/S3 registration audit and clean-install vignette contract.
- [x] Add regression tests for every discovered bug found during the v0.0.5 audit.
- [x] Classify legacy helpers (`qfactor_content()`, `agreement_summary()`,
      `simulate_*()`, `signal_detection()`, `reproducibility_phi()`) as
      auxiliary/compatibility functions rather than release-defining workflows;
      retain them for now but do not expand their methodological role before 0.1.0.

## v0.0.6 - Stable user-facing API (completed)

- [x] Harmonize workflow object structure across sort/rating/expert analyses.
      All flagship fits expose `results`, `scale_summary`, `settings`, `design`,
      and `details`, plus a common `contentvalid_workflow` superclass.
- [x] Implement consistent `print()`, `summary()`, and `plot()` conventions.
      Summary objects share common counts/metadata; primary print methods validate
      `digits`; plots validate the common `show_legend` control and return fits
      invisibly.
- [x] Standardize terminology, recommendations, warnings, and missingness reports.
      A common `status` field uses Supported / Review / Insufficient data /
      Descriptive only while method-specific recommendation language remains
      available; design metadata now exposes effective judge ranges and missingness.
- [x] Review low-level function names and deprecation/compatibility needs.
      No gratuitous renaming is needed before v0.1.0. Existing low-level names and
      compatibility aliases are retained; auxiliary helpers remain non-flagship.

## v0.0.7 - Documentation and reproducibility (completed)

- [x] Add dedicated vignettes for each major workflow (sort, rating, expert panel).
- [x] Add a design-and-reporting vignette.
- [x] Add reusable reporting templates/examples for manuscript-ready results.
- [x] Add example datasets and `data-raw/` provenance scripts.
- [x] Add `inst/CITATION` and complete method references/DOIs.
- [x] Add `NEWS.md` development history.
- [x] Organize pkgdown reference sections and articles.

## v0.0.8 - CRAN hardening (current)

Goal: turn the tested development package into a clean, reproducible first-release candidate.

- [x] Refresh GitHub Actions configuration to Windows/macOS/Linux release plus Linux oldrel-1/devel and add a dedicated R-devel `--as-cran` gate with NOTE-as-failure.
- [x] Use Node-24-compatible `actions/checkout@v7` while retaining the current `r-lib/actions@v2` line.
- [x] Audit source-package exclusions and ignore generated pkgdown output, check directories, source tarballs, and CRAN-only submission metadata.
- [x] Add a reproducible developer release-check script and first-submission `cran-comments.md` draft.
- [ ] Run dependency/import, example, URL, and spelling audits and resolve every actionable finding.
- [ ] Build README and all vignettes from clean source; build the pkgdown site successfully.
- [ ] Run local `R CMD check --as-cran`: 0 errors, 0 warnings, 0 notes.
- [ ] Confirm the full GitHub Actions matrix, including the `--as-cran` job, is warning/note-free after push.
- [ ] Refresh the live GitHub repository description/topics to match the modern sort + rating + expert-panel scope.
- [ ] Verify the live GitHub `ROADMAP.md`, `DESCRIPTION`, README, and workflow reflect the release candidate rather than an older cached/remote state.

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

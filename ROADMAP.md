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

- [x] Complete the expert-panel workflow and visualization hardening.
- [x] Harden Aiken V, CVR, CVI/modified kappa, and IOC behavior.
- [x] Add public workflow print/summary/plot methods and dedicated documentation.
- [x] Move final cross-platform and public-repository verification to v0.0.8.

## v0.0.5 - Test hardening (completed)

Goal: reach publication-grade numerical and behavioral coverage.

- [x] Complete malformed-input, boundary-condition, missingness, degenerate-design,
      canonical-value, public-export, and S3 registration regression coverage.
- [x] Classify legacy helpers as auxiliary/compatibility rather than flagship API.

## v0.0.6 - Stable user-facing API (completed)

- [x] Harmonize workflow object structure across sort/rating/expert analyses.
- [x] Implement consistent `print()`, `summary()`, and `plot()` conventions.
- [x] Standardize terminology, recommendations, warnings, and missingness reports.
- [x] Review low-level names and compatibility needs before the first public release.

## v0.0.7 - Documentation and reproducibility (completed)

- [x] Add dedicated workflow, design/reporting, and manuscript-ready vignettes.
- [x] Add deterministic example data and `data-raw/` provenance.
- [x] Add package citation and centralized method references.
- [x] Organize pkgdown reference sections and articles.

## v0.0.8 - CRAN hardening (completed)

- [x] Complete source-package, URL, spelling, README, vignette, pkgdown, and
      local `--as-cran` release audits.
- [x] Complete the six-job GitHub Actions matrix, including R-devel
      `--as-cran` with NOTE-as-failure.
- [x] Publish the pkgdown site and refresh repository metadata.
- [x] Verify live GitHub files reflect the release candidate.

## v0.1.0 - First public/CRAN release (current)

Goal: publish the frozen and validated first public release without adding new
features during the release cut.

- [x] Freeze the feature set at the completed v0.0.8 release candidate.
- [x] Stamp `DESCRIPTION` as version `0.1.0`.
- [x] Add first-public-release notes to `NEWS.md`.
- [ ] Run the final release battery against the actual stamped `0.1.0` source:
      `document()`, `test()`, `build_readme()`, standard check, `--as-cran`,
      URL audit, spelling audit, and pkgdown build.
- [ ] Commit and push the `0.1.0` release candidate.
- [ ] Confirm all six GitHub Actions jobs are green on the stamped `0.1.0` commit.
- [ ] Create annotated Git tag `v0.1.0` and push it.
- [ ] Create the GitHub `v0.1.0` release.
- [ ] Publish `contentvalidR` through a personal R-universe so the tagged/public
      package is installable from a CRAN-like repository without waiting for CRAN.
- [ ] Submit `contentvalidR` 0.1.0 to CRAN using the verified source tarball and
      final `cran-comments.md`.
- [ ] Confirm CRAN acceptance and verify the public CRAN package page/install path.
- [ ] Replace this historical pre-0.1 roadmap with the new post-0.1 development
      roadmap; the `v0.1.0` tag preserves this release roadmap permanently.

## Post-0.1 parking lot

These ideas move to the new roadmap immediately after v0.1.0 is public:

- Bayesian extensions and uncertainty-first content-validity inference;
- formal content validity analysis and richer domain-coverage modeling;
- judge/rater heterogeneity and influence diagnostics, including modern
  latent-variable or IRT approaches;
- Q-factor helper / alternative extraction approaches;
- later-CFA signal-detection diagnostics;
- between-pretest and multi-round reproducibility helpers;
- broader design/power and simulation framework;
- APA/Quarto/report exporters and tidy interoperability;
- interactive applications;
- a methodological/package paper framed as a practical primer for researchers
  learning scale development and substantive/content-validity pretesting.

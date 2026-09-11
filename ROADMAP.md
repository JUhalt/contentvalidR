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

## v0.1.0 - First public release (completed)

**Status:** Released September 2, 2026

Goal: publish a frozen, validated first public release of the three flagship
content-validity workflows.

- [x] Freeze the feature set at the completed v0.0.8 release candidate.
- [x] Stamp `DESCRIPTION` as version `0.1.0`.
- [x] Add first-public-release notes to `NEWS.md`.
- [x] Run the final release battery against the stamped `0.1.0` source.
- [x] Commit and push the stable `0.1.0` source.
- [x] Confirm the six-job GitHub Actions release matrix is green.
- [x] Create the `v0.1.0` Git tag.
- [x] Publish the GitHub `contentvalidR 0.1.0` release.
- [x] Publish the stable release through the JUhalt R-universe.
- [x] Verify the public pkgdown site and repository metadata.

CRAN submission is optional and is **not** a requirement for the completed
`v0.1.0` release. The existing CRAN-preparation infrastructure may be retained
for a future submission if useful.

***

## v0.2.0 - Uncertainty, Heterogeneity, and Reproducibility

**Status:** Planning and public-page reconciliation before development resumes
**Milestone:** [v0.2.0](https://github.com/JUhalt/contentvalidR/milestone/1)
**Development version:** `0.1.0.9000`

Goal: extend the stable content-validity workflow without turning the package
into a disconnected collection of coefficients. New methods should improve the
quality, transparency, or reproducibility of substantive/content-validity
decisions.

The issues below retain the existing v0.2.0 workstreams. A workstream's presence
in the milestone is a planning target, not evidence that it is implemented.
Research options require explicit scope and validation decisions before release.

Current-source housekeeping: GPLv3-only licensing and development citation
metadata are synchronized; the MIT terms of historical releases are unchanged.

### Bayesian and uncertainty-first extensions

Tracking: [#2](https://github.com/JUhalt/contentvalidR/issues/2).

- [ ] Conduct a focused methodological review of Bayesian approaches relevant to
      item sorting, construct ratings, expert-panel evidence, and content-domain
      coverage.
- [ ] Identify where Bayesian models add information beyond the package's current
      exact/frequentist uncertainty summaries.
- [ ] Prototype posterior or probability-based summaries only where assumptions
      can be explained transparently to applied researchers.
- [ ] Develop frequentist/exact-versus-Bayesian comparison examples.
- [ ] Establish simulation-based calibration/recovery tests before exposing any
      Bayesian method as a flagship workflow.
- [ ] Decide which Bayesian extensions are mature enough for the public API and
      which remain methodological research.

### Judge and rater heterogeneity

Tracking: [#3](https://github.com/JUhalt/contentvalidR/issues/3).

- [ ] Add influence diagnostics showing whether conclusions depend strongly on
      particular judges or raters.
- [ ] Explore heterogeneity summaries for judge severity, response style, and
      construct discrimination.
- [ ] Evaluate latent-variable, multilevel, or IRT-style approaches where they
      materially improve interpretation over aggregate indices.
- [ ] Preserve transparent raw-judge evidence alongside model-based summaries.

### Domain coverage and content structure

Tracking: [#4](https://github.com/JUhalt/contentvalidR/issues/4).

- [ ] Expand item-objective/domain congruence tools beyond isolated coefficients.
- [ ] Add summaries of construct-domain coverage and potential content gaps.
- [ ] Support richer item-to-domain mappings where items legitimately address
      multiple facets.
- [ ] Keep domain-coverage evidence distinct from downstream empirical
      factor-analytic evidence handled by `nomologR`.

Research option for triage in [#4](https://github.com/JUhalt/contentvalidR/issues/4):
link domain coverage to a structured register of qualitative evidence about
relevance, comprehensiveness, and comprehensibility. This is a proposed extension
informed by [Terwee et al. (2018)](https://doi.org/10.1007/s11136-018-1829-0),
not a validated package method or a release commitment.

### Multi-round and reproducibility workflows

Tracking: [#5](https://github.com/JUhalt/contentvalidR/issues/5).

- [ ] Add helpers for comparing repeated pretests or successive item-revision rounds.
- [ ] Quantify stability/change in item recommendations across rounds.
- [ ] Expand reproducibility diagnostics for independent judge samples.
- [ ] Provide audit trails showing why an item's status changed.

### Design, simulation, and power

Tracking: [#6](https://github.com/JUhalt/contentvalidR/issues/6).

- [ ] Generalize the existing item-sort planning framework.
- [ ] Add planning/simulation tools for expert-panel and construct-rating designs
      where a defensible planning target can be specified.
- [ ] Show sensitivity to judge count, missingness, effect magnitude, and decision
      criteria.
- [ ] Avoid unsupported universal sample-size rules of thumb.

### Reporting and interoperability

Tracking: [#7](https://github.com/JUhalt/contentvalidR/issues/7).

- [ ] Add tidy extraction helpers for flagship workflow objects.
- [ ] Expand manuscript-ready table/report scaffolds.
- [ ] Evaluate Quarto/HTML reporting helpers without making reporting dependencies
      mandatory for core analyses.
- [ ] Improve interoperability with downstream `nomologR` workflows where the
      conceptual handoff is scientifically appropriate.

### v0.2.0 exit gate

Tracking: [#8](https://github.com/JUhalt/contentvalidR/issues/8).

- [ ] Every new public method has a documented methodological basis or explicit
      derivation when the method is novel.
- [ ] Canonical-value, simulation/recovery, malformed-input, and edge-case tests
      cover every release-defining extension.
- [ ] R CMD check is clean across the supported OS/R matrix.
- [ ] Documentation clearly distinguishes established methods, package extensions,
      and experimental research features.
- [ ] README, vignettes, NEWS, citation metadata, pkgdown, and R-universe
      instructions reflect the release candidate.
- [ ] Clean-library installation and flagship workflow smoke tests pass.

***

## v0.3.x - Advanced Modeling and Dissemination

Candidate directions after the v0.2 foundation:

- [ ] Mature latent-variable/IRT models for judge/rater behavior.
- [ ] Q-factor and alternative extraction approaches where justified.
- [ ] Later-CFA signal-detection diagnostics and stronger handoffs to `nomologR`.
- [ ] Interactive applications for teaching and applied workflow exploration.
- [ ] A methodological/package paper on substantive/content-validity pretesting.
- [ ] Research evaluating whether guided package output improves applied
      measurement decisions and methodological understanding.

***

## Development principle

`contentvalidR` should continue to distinguish **quantitative evidence** from
automatic item-retention decisions. New functionality belongs in a stable release
only when it improves the validity argument, transparency of the decision
process, or reproducibility of the workflow.
## Keeping plans and pages aligned

Root `README.Rmd`, `ROADMAP.md`, `NEWS.md`, `DESCRIPTION`, and `CITATION.cff`
are the sources of current project information. Regenerate `README.md` from
`README.Rmd` and refresh the tracked `docs/` output after documentation changes;
do not edit generated HTML independently. The pkgdown workflow rebuilds the site
for pull requests and publishes default-branch changes to GitHub Pages.

Record findings or proposals in an issue with evidence and an observable outcome.
Link the issue here, assign a milestone when its scope is accepted, and update
the roadmap and NEWS when an implementation ships. Preserve completed release
history and identify deferred or experimental work explicitly.

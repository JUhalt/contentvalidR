# contentvalidR development roadmap

## Product principle

`contentvalidR` is not intended to be a bag of coefficients. Low-level
statistics remain available for methodological transparency, but the
recommended user experience is built around workflow objects that:

- organize item-level evidence cleanly;
- explain what the evidence supports in plain language;
- flag results that need substantive review;
- make restrained recommendations only where a method supports them;
- distinguish “review” from automatic deletion/rejection;
- disclose missingness, effective judge counts, and design limitations;
  and
- state what the analysis cannot establish on its own.

Quantitative pretest evidence complements theory, construct-domain
coverage, qualitative review, cognitive interviewing, and other evidence
concerning relevance, comprehensiveness, and comprehensibility.

## v0.0.1 - Methodological foundation (completed)

Goal: make the existing core statistically trustworthy before expanding
the API.

Correct Csv when the target construct is never selected.

Use non-missing itemwise denominators for Psa/Csv and report
missingness.

Reject duplicate item-rater rows and inconsistent item targets.

Correct Polit-Beck-Owen modified-kappa chance agreement.

Add S-CVI/UA and itemwise CVI judge counts.

Correct confusion-matrix orientation and signed phi.

Preserve a full 2 x 2 table for reproducibility diagnostics.

Document the exact target-count test as Howard-Melloy inference.

Add a first user-facing
[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
workflow with print/summary.

Replace the placeholder test with substantive regression tests.

Consolidate GitHub Actions and remove obsolete R versions.

Verify all changes under R with `document()`, `test()`, and `check()`.

Add published/hand-worked canonical validation cases for every
release-defining core method.

Decide whether to expose the Anderson-Gerbing legacy critical-Csv test.
Decision: do not expose it as an alternate user-facing rule.
Howard-Melloy is the supported default; the legacy rule adds no decision
difference in the original two-choice case and is miscalibrated when
generalized to multi-choice sorts.

## v0.0.2 - Modern item-sort workflow (completed)

Goal: make A&G -\> Howard-Melloy -\> Colquitt the flagship module.

Add Colquitt et al. (2019) empirical interpretation bands for Psa/Csv,
clearly labeled as normative benchmarks rather than universal cutoffs.

Support overall and orbiting-construct-conditional interpretation.

Add item and scale summaries for definitional
correspondence/distinctiveness.

Add exact design/power planning for target-assignment retention rules.

Add plotting for item-sort evidence and review flags.

Add dedicated substantive-validity sort vignette.

## v0.0.3 - Modern construct-rating workflow (completed)

Goal: modernize the Hinkin-Tracey side of the package.

Implement HTC (Hinkin-Tracey correspondence).

Implement HTD (Hinkin-Tracey distinctiveness).

Add Colquitt et al. (2019) HTC/HTD interpretation bands.

Redesign
[`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
so within-judge and between-judge designs are explicit and modeled
appropriately.

Add Greenhouse-Geisser corrected omnibus inference for repeated-measures
rating designs while retaining raw ANOVA output.

Add
[`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
with informative print/summary methods.

Add dependency-free HTC/HTD plotting.

Add a dedicated construct-rating vignette.

Verify the full v0.0.3 patch under R with `document()`, `test()`,
`check()`, and `build_readme()`.

## v0.0.4 - Expert-panel workflow (completed)

Goal: provide trustworthy complementary indices without duplicating
unrelated packages merely for feature count.

Complete the expert-panel workflow and visualization hardening.

Harden Aiken V, CVR, CVI/modified kappa, and IOC behavior.

Add public workflow print/summary/plot methods and dedicated
documentation.

Move final cross-platform and public-repository verification to v0.0.8.

## v0.0.5 - Test hardening (completed)

Goal: reach publication-grade numerical and behavioral coverage.

Complete malformed-input, boundary-condition, missingness,
degenerate-design, canonical-value, public-export, and S3 registration
regression coverage.

Classify legacy helpers as auxiliary/compatibility rather than flagship
API.

## v0.0.6 - Stable user-facing API (completed)

Harmonize workflow object structure across sort/rating/expert analyses.

Implement consistent [`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html), and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) conventions.

Standardize terminology, recommendations, warnings, and missingness
reports.

Review low-level names and compatibility needs before the first public
release.

## v0.0.7 - Documentation and reproducibility (completed)

Add dedicated workflow, design/reporting, and manuscript-ready
vignettes.

Add deterministic example data and `data-raw/` provenance.

Add package citation and centralized method references.

Organize pkgdown reference sections and articles.

## v0.0.8 - CRAN hardening (completed)

Complete source-package, URL, spelling, README, vignette, pkgdown, and
local `--as-cran` release audits.

Complete the six-job GitHub Actions matrix, including R-devel
`--as-cran` with NOTE-as-failure.

Publish the pkgdown site and refresh repository metadata.

Verify live GitHub files reflect the release candidate.

## v0.1.0 - First public release (completed)

**Status:** Released September 2, 2026

Goal: publish a frozen, validated first public release of the three
flagship content-validity workflows.

Freeze the feature set at the completed v0.0.8 release candidate.

Stamp `DESCRIPTION` as version `0.1.0`.

Add first-public-release notes to `NEWS.md`.

Run the final release battery against the stamped `0.1.0` source.

Commit and push the stable `0.1.0` source.

Confirm the six-job GitHub Actions release matrix is green.

Create the `v0.1.0` Git tag.

Publish the GitHub `contentvalidR 0.1.0` release.

Publish the stable release through the JUhalt R-universe.

Verify the public pkgdown site and repository metadata.

CRAN submission is optional and is **not** a requirement for the
completed `v0.1.0` release. The existing CRAN-preparation infrastructure
may be retained for a future submission if useful.

------------------------------------------------------------------------

## v0.2.0 - Uncertainty, Heterogeneity, and Reproducibility

**Status:** Scoped and in development **Milestone:**
[v0.2.0](https://github.com/JUhalt/contentvalidR/milestone/1)
**Development version:** `0.1.0.9000`

Goal: extend the stable content-validity workflow without turning the
package into a disconnected collection of coefficients. New methods
should improve the quality, transparency, or reproducibility of
substantive/content-validity decisions.

Current-source housekeeping: GPLv3-only licensing and development
citation metadata are synchronized; the MIT terms of historical releases
are unchanged.

### Scope decisions (2026-09-13)

- **Judge/rater heterogeneity
  ([\#3](https://github.com/JUhalt/contentvalidR/issues/3)) and domain
  coverage ([\#4](https://github.com/JUhalt/contentvalidR/issues/4)) are
  confirmed release commitments.** Both rest on established published
  methodology and both are implementable within `Imports: stats`.
- **Bayesian extensions
  ([\#2](https://github.com/JUhalt/contentvalidR/issues/2)) moved to
  v0.3.0** on sequencing and dependency grounds, not for lack of
  published evidence.
- **Interpretable output
  ([\#11](https://github.com/JUhalt/contentvalidR/issues/11)) added as a
  first-class release commitment.** The package is intended for serious
  researchers and for Master’s and doctoral students. Output that cannot
  be read correctly without the primary sources is treated as a defect,
  not as missing polish.
- **The zero-compiled-dependency install profile is retained.** The
  package must remain installable on managed and locked-down machines
  without a compiler toolchain. Where a method has a defensible base-R
  formulation, that formulation is used and its tradeoffs are documented
  rather than hidden.

### Judge and rater heterogeneity

Tracking: [\#3](https://github.com/JUhalt/contentvalidR/issues/3).

Methodological basis: generalizability theory for content-validity
ratings ([Crocker, Llabre & Miller,
1988](https://doi.org/10.1111/j.1745-3984.1988.tb00309.x)); many-facet
Rasch measurement (Linacre, 1989); rater errors as named, measurable
effects ([Engelhard,
1994](https://doi.org/10.1111/j.1745-3984.1994.tb00436.x)); the
generalized linear model formulation of facet models (de Boeck & Wilson,
2004).

Estimation decision: rater severity is estimated with a base-R facets
model fitted via [`stats::glm()`](https://rdrr.io/r/stats/glm.html)
(joint maximum likelihood), not an external Rasch engine. The candidate
engines (`sirt`, `immer`, `TAM`) each pull a compiled dependency chain
that works against the package’s intended audience. The joint-ML
small-sample bias is corrected, reported, and documented; marginal-ML
estimation is tracked for v0.3.0.

Implement G-theory variance decomposition (judge, item, judge x item)
with generalizability and dependability coefficients.

Add a decision study reporting judges required to reach a target
coefficient.

Implement the [`stats::glm()`](https://rdrr.io/r/stats/glm.html) facets
model for judge severity/leniency, with standard errors and infit/outfit
fit statistics.

Apply and document the joint-ML bias correction and state its limits.

Add rater-effect indices for severity, central tendency, halo, and
restriction of range.

Add leave-one-judge-out influence diagnostics across I-CVI, Aiken’s V,
CVR, and Psa/Csv, flagging items whose status changes when a judge is
removed.

Preserve transparent raw-judge evidence alongside model-based summaries.

Add canonical-value and simulation-recovery tests for severity
parameters.

### Domain coverage and content structure

Tracking: [\#4](https://github.com/JUhalt/contentvalidR/issues/4).

Methodological basis: expert item-similarity ratings analyzed by
multidimensional scaling and hierarchical cluster analysis against the a
priori blueprint ([Sireci & Geisinger,
1992](https://doi.org/10.1177/014662169201600102);
[1995](https://doi.org/10.1177/014662169501900303)), within the
content-validity framing of [Sireci
(1998)](https://doi.org/10.1023/A:1006985528729). Implemented with
[`stats::cmdscale`](https://rdrr.io/r/stats/cmdscale.html),
[`stats::dist`](https://rdrr.io/r/stats/dist.html), and
[`stats::hclust`](https://rdrr.io/r/stats/hclust.html).

Add a blueprint / table-of-specifications representation with item
assignments.

Report coverage per blueprint cell, flagging empty, thin, and
over-represented cells with explicit thresholds.

Implement the expert item-similarity MDS + hierarchical clustering
pipeline.

Report MDS stress/fit and recommend dimensionality transparently.

Quantify recovered-structure versus blueprint agreement with a
chance-corrected index, alongside the raw cross-tabulation.

Derive similarity structure from existing item-sort data where no
dedicated similarity task was run, documenting the weaker inference this
supports.

Add MDS content-map plotting with blueprint membership indicated.

Keep domain-coverage evidence distinct from downstream empirical
factor-analytic evidence handled by `nomologR`.

Research option for triage in
[\#4](https://github.com/JUhalt/contentvalidR/issues/4): link domain
coverage to a structured register of qualitative evidence about
relevance, comprehensiveness, and comprehensibility. This is a proposed
extension informed by [Terwee et
al. (2018)](https://doi.org/10.1007/s11136-018-1829-0), not a validated
package method or a release commitment.

### Multi-round and reproducibility workflows

Tracking: [\#5](https://github.com/JUhalt/contentvalidR/issues/5).

Add helpers for comparing repeated pretests or successive item-revision
rounds.

Quantify stability/change in item recommendations across rounds.

Expand reproducibility diagnostics for independent judge samples.

Provide audit trails showing why an item’s status changed.

### Design, simulation, and power

Tracking: [\#6](https://github.com/JUhalt/contentvalidR/issues/6).

Generalize the existing item-sort planning framework.

Add planning/simulation tools for expert-panel and construct-rating
designs where a defensible planning target can be specified.

Show sensitivity to judge count, missingness, effect magnitude, and
decision criteria.

Avoid unsupported universal sample-size rules of thumb.

### Reporting and interoperability

Tracking: [\#7](https://github.com/JUhalt/contentvalidR/issues/7).

Add tidy extraction helpers for flagship workflow objects.

Expand manuscript-ready table/report scaffolds.

Evaluate Quarto/HTML reporting helpers without making reporting
dependencies mandatory for core analyses.

Improve interoperability with downstream `nomologR` workflows where the
conceptual handoff is scientifically appropriate.

### Interpretable output for researchers and students

Tracking: [\#11](https://github.com/JUhalt/contentvalidR/issues/11).

The product principle that this package is “not a bag of coefficients”
is only real if a second-year doctoral student can run a workflow, read
the output, and correctly explain what it does and does not support
without first reading four primary sources. Where that fails, it is a
defect in how results are communicated, not a documentation gap.

Audit every [`print()`](https://rdrr.io/r/base/print.html) and
[`summary()`](https://rdrr.io/r/base/summary.html) method against
whether a reader who has not read the source paper could act on it
correctly.

State in plain language what each index measures and what a high or low
value means in context, not only its value and cut point.

Make the distinction between `Review` and deletion unmissable in the
output itself, not only in the documentation.

Standardize status vocabulary across workflows and define terms where
shown.

Report what the analysis cannot establish with the same prominence as
what it can.

Add a “how to read contentvalidR output” vignette for graduate students,
annotating each flagship workflow’s output field by field.

Add a glossary of indices, status terms, and decision language.

Add worked interpretation examples for a clean result and an ambiguous
one, including how to write up each.

Document common misreadings, including treating benchmarks as universal
cut scores and treating a single index as sufficient validity evidence.

Verify new output from \#3 and \#4 meets the same interpretive standard
before those features are considered complete.

Add regression tests covering interpretive output so wording users rely
on cannot silently disappear.

### v0.2.0 exit gate

Tracking: [\#8](https://github.com/JUhalt/contentvalidR/issues/8).

Every new public method has a documented methodological basis or
explicit derivation when the method is novel.

Canonical-value, simulation/recovery, malformed-input, and edge-case
tests cover every release-defining extension.

R CMD check is clean across the supported OS/R matrix.

Documentation clearly distinguishes established methods, package
extensions, and experimental research features.

README, vignettes, NEWS, citation metadata, pkgdown, and R-universe
instructions reflect the release candidate.

Clean-library installation and flagship workflow smoke tests pass.

Output from every release-defining extension meets the interpretive
standard in [\#11](https://github.com/JUhalt/contentvalidR/issues/11).

CRAN submission is completed rather than deferred again;
`cran-comments.md` is populated with actual final check results.

------------------------------------------------------------------------

## v0.3.0 - Advanced Modeling and Dissemination

**Milestone:**
[v0.3.0](https://github.com/JUhalt/contentvalidR/milestone/2)

### Bayesian and uncertainty-first extensions

Tracking: [\#2](https://github.com/JUhalt/contentvalidR/issues/2).

Deferred from v0.2.0 on sequencing and dependency grounds, **not** for
lack of published evidence. Credible work exists — see [Uto
(2023)](https://doi.org/10.3758/s13428-022-01997-z), *Behavior Research
Methods* 55(7), 3910-3928, on a Bayesian many-facet Rasch model for
rater severity drift. Two blockers: credible estimation needs a Stan- or
JAGS-class backend, which reverses the zero-compiled-dependency decision
and must be weighed on its own merits; and the literature aimed
specifically at content-validity evidence, as distinct from
rater-mediated performance assessment generally, needs a focused review
first.

The base-R joint-ML facets model shipped in v0.2.0 fixes the estimand
and the output contract, which makes a later Bayesian version a
substitution rather than a new design.

Conduct the focused methodological review.

Evaluate whether a Bayesian facet model materially improves on the
v0.2.0 joint-ML severity estimates for the small panels (5-20 experts)
typical of content-validity work, where JML bias is largest.

Decide the dependency question explicitly: sampler in `Suggests` with
graceful degradation, a companion package, or not at all.

Establish simulation-based calibration/recovery tests before exposing
any Bayesian method as a flagship workflow.

### Other candidate directions

Marginal-ML / full many-facet Rasch estimation as an optional upgrade
path over the v0.2.0 base-R facets model.

Q-factor and alternative extraction approaches where justified.

Later-CFA signal-detection diagnostics and stronger handoffs to
`nomologR`.

Interactive applications for teaching and applied workflow exploration.

A methodological/package paper on substantive/content-validity
pretesting.

Research evaluating whether guided package output improves applied
measurement decisions and methodological understanding.

------------------------------------------------------------------------

## Development principle

`contentvalidR` should continue to distinguish **quantitative evidence**
from automatic item-retention decisions. New functionality belongs in a
stable release only when it improves the validity argument, transparency
of the decision process, or reproducibility of the workflow.

## Keeping plans and pages aligned

Root `README.Rmd`, `ROADMAP.md`, `NEWS.md`, `DESCRIPTION`, and
`CITATION.cff` are the sources of current project information.
Regenerate `README.md` from `README.Rmd` and refresh the tracked `docs/`
output after documentation changes; do not edit generated HTML
independently. The pkgdown workflow rebuilds the site for pull requests
and publishes default-branch changes to GitHub Pages.

Record findings or proposals in an issue with evidence and an observable
outcome. Link the issue here, assign a milestone when its scope is
accepted, and update the roadmap and NEWS when an implementation ships.
Preserve completed release history and identify deferred or experimental
work explicitly.

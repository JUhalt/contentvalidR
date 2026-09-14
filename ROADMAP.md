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

**Status:** Released
**Milestone:** [v0.2.0](https://github.com/JUhalt/contentvalidR/milestone/1)
**Version:** `0.2.0`

Goal: extend the stable content-validity workflow without turning the package
into a disconnected collection of coefficients. New methods should improve the
quality, transparency, or reproducibility of substantive/content-validity
decisions.

Current-source housekeeping: GPLv3-only licensing and development citation
metadata are synchronized; the MIT terms of historical releases are unchanged.

### Scope decisions (2026-09-13)

- **Judge/rater heterogeneity ([#3](https://github.com/JUhalt/contentvalidR/issues/3))
  and domain coverage ([#4](https://github.com/JUhalt/contentvalidR/issues/4))
  are confirmed release commitments.** Both rest on established published
  methodology and both are implementable within `Imports: stats`.
- **Bayesian extensions
  ([#2](https://github.com/JUhalt/contentvalidR/issues/2)) moved to v0.3.0**
  on sequencing and dependency grounds, not for lack of published evidence.
- **Interpretable output
  ([#11](https://github.com/JUhalt/contentvalidR/issues/11)) added as a
  first-class release commitment.** The package is intended for serious
  researchers and for Master's and doctoral students. Output that cannot be read
  correctly without the primary sources is treated as a defect, not as missing
  polish.
- **The zero-compiled-dependency install profile is retained.** The package must
  remain installable on managed and locked-down machines without a compiler
  toolchain. Where a method has a defensible base-R formulation, that
  formulation is used and its tradeoffs are documented rather than hidden.

### Judge and rater heterogeneity

Tracking: [#3](https://github.com/JUhalt/contentvalidR/issues/3).

Methodological basis: generalizability theory for content-validity ratings
([Crocker, Llabre & Miller, 1988](https://doi.org/10.1111/j.1745-3984.1988.tb00309.x));
many-facet Rasch measurement (Linacre, 1989); rater errors as named, measurable
effects ([Engelhard, 1994](https://doi.org/10.1111/j.1745-3984.1994.tb00436.x));
the generalized linear model formulation of facet models (de Boeck & Wilson, 2004).

Estimation decision: rater severity is estimated with a base-R facets model
fitted via `stats::glm()` (joint maximum likelihood), not an external Rasch
engine. The candidate engines (`sirt`, `immer`, `TAM`) each pull a compiled
dependency chain that works against the package's intended audience. The
joint-ML small-sample bias is corrected, reported, and documented; marginal-ML
estimation is tracked for v0.3.0.

- [ ] Implement G-theory variance decomposition (judge, item, judge x item) with
      generalizability and dependability coefficients.
- [ ] Add a decision study reporting judges required to reach a target coefficient.
- [ ] Implement the `stats::glm()` facets model for judge severity/leniency, with
      standard errors and infit/outfit fit statistics.
- [ ] Apply and document the joint-ML bias correction and state its limits.
- [ ] Add rater-effect indices for severity, central tendency, halo, and
      restriction of range.
- [ ] Add leave-one-judge-out influence diagnostics across I-CVI, Aiken's V, CVR,
      and Psa/Csv, flagging items whose status changes when a judge is removed.
- [ ] Preserve transparent raw-judge evidence alongside model-based summaries.
- [ ] Add canonical-value and simulation-recovery tests for severity parameters.

### Domain coverage and content structure

Tracking: [#4](https://github.com/JUhalt/contentvalidR/issues/4).

Methodological basis: expert item-similarity ratings analyzed by multidimensional
scaling and hierarchical cluster analysis against the a priori blueprint
([Sireci & Geisinger, 1992](https://doi.org/10.1177/014662169201600102);
[1995](https://doi.org/10.1177/014662169501900303)), within the content-validity
framing of [Sireci (1998)](https://doi.org/10.1023/A:1006985528729). Implemented
with `stats::cmdscale`, `stats::dist`, and `stats::hclust`.

- [ ] Add a blueprint / table-of-specifications representation with item assignments.
- [ ] Report coverage per blueprint cell, flagging empty, thin, and
      over-represented cells with explicit thresholds.
- [ ] Implement the expert item-similarity MDS + hierarchical clustering pipeline.
- [ ] Report MDS stress/fit and recommend dimensionality transparently.
- [ ] Quantify recovered-structure versus blueprint agreement with a
      chance-corrected index, alongside the raw cross-tabulation.
- [ ] Derive similarity structure from existing item-sort data where no dedicated
      similarity task was run, documenting the weaker inference this supports.
- [ ] Add MDS content-map plotting with blueprint membership indicated.
- [ ] Keep domain-coverage evidence distinct from downstream empirical
      factor-analytic evidence handled by `nomologR`.

Research option for triage in [#4](https://github.com/JUhalt/contentvalidR/issues/4):
link domain coverage to a structured register of qualitative evidence about
relevance, comprehensiveness, and comprehensibility. This is a proposed extension
informed by [Terwee et al. (2018)](https://doi.org/10.1007/s11136-018-1829-0),
not a validated package method or a release commitment.

### Multi-round and reproducibility workflows

Tracking: [#5](https://github.com/JUhalt/contentvalidR/issues/5).

- [x] Add helpers for comparing repeated pretests or successive item-revision
      rounds, via `compare_rounds()`.
- [x] Quantify stability/change in item recommendations across rounds, including
      units that entered or left the item set.
- [x] Provide audit trails showing whether a status change can be read as an
      evidence change at all: settings are compared between rounds and the
      comparison is marked not comparable when a decision rule changed.
- [x] Retain `reproducibility_phi()` for agreement between independent judge
      samples analyzed under identical settings; cross-referenced from
      `compare_rounds()` rather than duplicated.

### Design, simulation, and power

Tracking: [#6](https://github.com/JUhalt/contentvalidR/issues/6).

- [x] Extend planning beyond item sorting with `expert_power()`, giving the exact
      probability of clearing the panel-size I-CVI guideline or the Lawshe CVR
      critical count.
- [x] Show sensitivity to judge count, assumed endorsement probability, decision
      criterion, and non-response, the last by averaging over the realized panel
      size rather than assuming the invited panel arrives intact.
- [x] Report the I-CVI criterion's step at six experts rather than smoothing it,
      including the case where a fourth or fifth expert lowers the probability of
      clearing under unanimity.
- [x] Avoid unsupported universal sample-size rules of thumb: planning output
      reports the consequences of the panel sizes requested and explicitly
      declines to recommend one.
- [x] Plan judge counts against a generalizability target through the
      `gtheory_content()` decision study.

### Reporting and interoperability

Tracking: [#7](https://github.com/JUhalt/contentvalidR/issues/7).

- [x] Add extraction helpers for flagship workflow objects: an `as.data.frame()`
      method returning results or the scale summary with workflow provenance, so
      tables from several analyses stack.
- [x] Add manuscript-ready table scaffolds through `content_report()`.
- [x] Support Quarto/R Markdown reporting by generating Markdown directly, with
      analysis settings attached to the output, and without adding any reporting
      dependency to the package.
- [x] Decide against a helper that returns only the units that passed. Filtering
      on status is a substantive decision that belongs in the user's own visible
      code, and `Review` is not an instruction to delete.
- [ ] Revisit a closer `nomologR` handoff once that package's intake format is
      settled; the documented evidence table is the handoff for now.

### Interpretable output for researchers and students

Tracking: [#11](https://github.com/JUhalt/contentvalidR/issues/11).

The product principle that this package is "not a bag of coefficients" is only
real if a second-year doctoral student can run a workflow, read the output, and
correctly explain what it does and does not support without first reading four
primary sources. Where that fails, it is a defect in how results are
communicated, not a documentation gap.

- [x] Audit every `print()` and `summary()` method against whether a reader who
      has not read the source paper could act on it correctly.
- [x] State in plain language what each index measures and what a high or low
      value means in context, not only its value and cut point.
- [x] Make the distinction between `Review` and deletion unmissable in the output
      itself, not only in the documentation.
- [x] Standardize status vocabulary across workflows and define terms where shown,
      including how each workflow's own recommendation wording maps onto it.
- [x] Report what the analysis cannot establish with the same prominence as what
      it can.
- [x] Add a "how to read contentvalidR output" vignette for graduate students,
      annotating each flagship workflow's output field by field.
- [x] Add a glossary of indices, status terms, and decision language, via
      `contentvalid_glossary()`, which is also the source of the inline keys so a
      term cannot be defined differently in two places.
- [x] Add worked interpretation examples for a clean result and an ambiguous one,
      including how to write up each.
- [x] Document common misreadings, including treating benchmarks as universal cut
      scores and treating a single index as sufficient validity evidence.
- [x] State that benchmark labels are not comparable across indices. A scale-level
      HTC of 0.83 is labelled `Weak` in the same row where an HTD of 0.44 is
      labelled `Very Strong`, because HTC is an average rating and HTD is a
      difference. Output that leaves this unexplained reads as an error.
- [x] Verify new output from #3 and #4 meets the same interpretive standard
      before those features are considered complete.
- [x] Add regression tests covering interpretive output so wording users rely on
      cannot silently disappear, including a test that the documented HTC/HTD
      contrast still occurs in the shipped example data.

### v0.2.0 exit gate

Tracking: [#8](https://github.com/JUhalt/contentvalidR/issues/8).

- [x] Every new public method has a documented methodological basis or explicit
      derivation when the method is novel.
- [x] Canonical-value, simulation/recovery, malformed-input, and edge-case tests
      cover every release-defining extension.
- [x] R CMD check is clean across the supported OS/R matrix, including the
      R-devel `--as-cran` job that treats any NOTE as a failure.
- [x] Documentation clearly distinguishes established methods, package extensions,
      and experimental research features.
- [x] README, vignettes, NEWS, citation metadata, pkgdown, and R-universe
      instructions reflect the release candidate.
- [x] Clean-library installation and flagship workflow smoke tests pass.
- [x] Output from every release-defining extension meets the interpretive
      standard in [#11](https://github.com/JUhalt/contentvalidR/issues/11).
- [x] Stable version stamped, tagged, and published through GitHub and the
      personal R-universe.

**CRAN submission is deferred to v0.3.0** and tracked on its own in
[#14](https://github.com/JUhalt/contentvalidR/issues/14), so that the completed
v0.2.0 workstreams reach users without waiting on a submission round. It is a
separate issue rather than a line in a release gate because it has now slipped
twice inside larger gates that closed around it.

***

## v0.3.0 - Evidence-based methods with selectable options

**Milestone:** [v0.3.0](https://github.com/JUhalt/contentvalidR/milestone/2)

Scope was set on 2026-09-14 after an evidence review of every candidate. v0.3
implements only approaches with published, verifiable methodological support.

**Design rule.** Where more than one published approach exists, researchers
choose it through an argument that has an evidence-based default. Output names
the method that ran, why the default is the default, and the method's known
limits. Methods with published evidence against them remain available but are
never the default, and selecting one prints the critique.

### Selectable score intervals for I-CVI and Psa

Tracking: [#17](https://github.com/JUhalt/contentvalidR/issues/17).

- [ ] Wilson score interval as the default (Wilson, 1927; Newcombe, 1998).
- [ ] Agresti-Coull adjusted Wald interval (Agresti & Coull, 1998).
- [ ] Clopper-Pearson exact interval (Clopper & Pearson, 1934), documented as
      conservative.
- [ ] Verification against `prop.test(correct = FALSE)` and `binom.test()`.

### Selectable agreement coefficients for expert panels

Tracking: [#18](https://github.com/JUhalt/contentvalidR/issues/18).

- [ ] Modified kappa stays the default (Polit, Beck & Owen, 2007).
- [ ] Krippendorff's alpha with bootstrap intervals (Hayes & Krippendorff, 2007;
      Zapf et al., 2016), documented as a general reliability coefficient with
      no content-validity-specific publication.
- [ ] Gwet's AC1 (Gwet, 2008) as a never-default option that prints the critique
      in Vach & Gerke (2023).

### Evidence-based factor retention and citations for auxiliary helpers

Tracking: [#19](https://github.com/JUhalt/contentvalidR/issues/19).

- [ ] Parallel analysis (Horn, 1965) replaces Kaiser's eigenvalue > 1 rule as the
      `qfactor_content()` default, since Zwick & Velicer (1986) found the Kaiser
      rule severely overestimates the number of components.
- [ ] The Kaiser rule stays selectable by name so earlier results can be
      reproduced, and prints the critique when chosen.
- [ ] Cite Schriesheim et al. (1993, 1999) in `qfactor_content()` and Anderson &
      Gerbing (1991) in `signal_detection()`.

### CRAN submission

Tracking: [#14](https://github.com/JUhalt/contentvalidR/issues/14).

- [ ] Populate `cran-comments.md` with actual final check results, including a
      sentence distinguishing contentvalidR from the `contentValidity` package.
- [ ] Confirm no stray `LICENSE` file reaches the built tarball, and that the
      source carries `License: GPL-3` with `inst/NOTICE` preserving the historical
      MIT attribution for v0.1.0.
- [ ] Check the built tarball with `--as-cran`, not only the source directory.
- [ ] Submit, respond to maintainer feedback, and confirm acceptance.
- [ ] Update README installation guidance once CRAN is live.

### Not implemented on evidence grounds

- **Halo index.** This was deferred from the v0.2.0 judge-heterogeneity work.
  Murphy, Jako & Anhalt (1993) reviewed the halo literature and called for a
  moratorium on halo indices, because true and illusory halo cannot be
  separated.

***

## Future research

**Milestone:** [Future research](https://github.com/JUhalt/contentvalidR/milestone/3)

Evidence-reviewed items that are not release commitments. Each records why it
is parked and what would move it into a release.

- [ ] **Bayesian content-validity extensions**
      ([#2](https://github.com/JUhalt/contentvalidR/issues/2)). The one
      content-validity-specific method found, Bayesian Instrument Development
      (Gajewski et al., 2013; Jiang et al., 2014), needs participant response
      data and MCMC. That places it at the handoff to `nomologR`, and it
      conflicts with the dependency policy.
- [ ] **COSMIN content-validity appraisal**
      ([#16](https://github.com/JUhalt/contentvalidR/issues/16)). Strong evidence
      (Terwee et al., 2018), but it is a qualitative appraisal framework, and it
      was developed for patient-reported outcome measures.
- [ ] **Delphi consensus and stability**
      ([#20](https://github.com/JUhalt/contentvalidR/issues/20)). Supported by
      Diamond et al. (2014) and Schifano & Niederberger (2025). The stability
      statistic still needs verifying from Holey et al. (2007).
- [ ] **Marginal-ML many-facet Rasch estimation.** An established method, but it
      needs a compiled estimation engine, which the dependency policy rules out.
- [ ] **Hernández-Nieto's content validity coefficient.** Published in a book
      with a fixed 0.80 cutoff, and close to Aiken's V, which is already
      implemented.
- [ ] **rWG within-group agreement** (James, Demaree & Wolf, 1984). Designed for
      aggregating group ratings; no content-validity application was verified.
- [ ] Stronger `nomologR` handoffs, interactive teaching applications, a
      methodological package paper, and research on whether guided output
      improves applied decisions. These are not methods questions and are
      scoped separately.

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

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

**Status:** Released **Milestone:**
[v0.2.0](https://github.com/JUhalt/contentvalidR/milestone/1)
**Version:** `0.2.0`

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
rounds, via
[`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md).

Quantify stability/change in item recommendations across rounds,
including units that entered or left the item set.

Provide audit trails showing whether a status change can be read as an
evidence change at all: settings are compared between rounds and the
comparison is marked not comparable when a decision rule changed.

Retain
[`reproducibility_phi()`](https://juhalt.github.io/contentvalidR/reference/reproducibility_phi.md)
for agreement between independent judge samples analyzed under identical
settings; cross-referenced from
[`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
rather than duplicated.

### Design, simulation, and power

Tracking: [\#6](https://github.com/JUhalt/contentvalidR/issues/6).

Extend planning beyond item sorting with
[`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md),
giving the exact probability of clearing the panel-size I-CVI guideline
or the Lawshe CVR critical count.

Show sensitivity to judge count, assumed endorsement probability,
decision criterion, and non-response, the last by averaging over the
realized panel size rather than assuming the invited panel arrives
intact.

Report the I-CVI criterion’s step at six experts rather than smoothing
it, including the case where a fourth or fifth expert lowers the
probability of clearing under unanimity.

Avoid unsupported universal sample-size rules of thumb: planning output
reports the consequences of the panel sizes requested and explicitly
declines to recommend one.

Plan judge counts against a generalizability target through the
[`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md)
decision study.

### Reporting and interoperability

Tracking: [\#7](https://github.com/JUhalt/contentvalidR/issues/7).

Add extraction helpers for flagship workflow objects: an
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) method
returning results or the scale summary with workflow provenance, so
tables from several analyses stack.

Add manuscript-ready table scaffolds through
[`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md).

Support Quarto/R Markdown reporting by generating Markdown directly,
with analysis settings attached to the output, and without adding any
reporting dependency to the package.

Decide against a helper that returns only the units that passed.
Filtering on status is a substantive decision that belongs in the user’s
own visible code, and `Review` is not an instruction to delete.

Revisit a closer `nomologR` handoff once that package’s intake format is
settled; the documented evidence table is the handoff for now.

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
shown, including how each workflow’s own recommendation wording maps
onto it.

Report what the analysis cannot establish with the same prominence as
what it can.

Add a “how to read contentvalidR output” vignette for graduate students,
annotating each flagship workflow’s output field by field.

Add a glossary of indices, status terms, and decision language, via
[`contentvalid_glossary()`](https://juhalt.github.io/contentvalidR/reference/contentvalid_glossary.md),
which is also the source of the inline keys so a term cannot be defined
differently in two places.

Add worked interpretation examples for a clean result and an ambiguous
one, including how to write up each.

Document common misreadings, including treating benchmarks as universal
cut scores and treating a single index as sufficient validity evidence.

State that benchmark labels are not comparable across indices. A
scale-level HTC of 0.83 is labeled `Weak` in the same row where an HTD
of 0.44 is labeled `Very Strong`, because HTC is an average rating and
HTD is a difference. Output that leaves this unexplained reads as an
error.

Verify new output from \#3 and \#4 meets the same interpretive standard
before those features are considered complete.

Add regression tests covering interpretive output so wording users rely
on cannot silently disappear, including a test that the documented
HTC/HTD contrast still occurs in the shipped example data.

### v0.2.0 exit gate

Tracking: [\#8](https://github.com/JUhalt/contentvalidR/issues/8).

Every new public method has a documented methodological basis or
explicit derivation when the method is novel.

Canonical-value, simulation/recovery, malformed-input, and edge-case
tests cover every release-defining extension.

R CMD check is clean across the supported OS/R matrix, including the
R-devel `--as-cran` job that treats any NOTE as a failure.

Documentation clearly distinguishes established methods, package
extensions, and experimental research features.

README, vignettes, NEWS, citation metadata, pkgdown, and R-universe
instructions reflect the release candidate.

Clean-library installation and flagship workflow smoke tests pass.

Output from every release-defining extension meets the interpretive
standard in [\#11](https://github.com/JUhalt/contentvalidR/issues/11).

Stable version stamped, tagged, and published through GitHub and the
personal R-universe.

**CRAN submission is deferred to v0.3.0** and tracked on its own in
[\#14](https://github.com/JUhalt/contentvalidR/issues/14), so that the
completed v0.2.0 workstreams reach users without waiting on a submission
round. It is a separate issue rather than a line in a release gate
because it has now slipped twice inside larger gates that closed around
it.

------------------------------------------------------------------------

## v0.3.0 - Evidence-based methods with selectable options

**Status:** Released (0.3.0 on 2026-09-15; patch 0.3.1 fixes README
links flagged by CRAN’s incoming checks) **Milestone:**
[v0.3.0](https://github.com/JUhalt/contentvalidR/milestone/2)
**Version:** `0.3.1`

Scope was set on 2026-09-14 after an evidence review of every candidate.
v0.3 implements only approaches with published, verifiable
methodological support.

**Design rule.** Where more than one published approach exists,
researchers choose it through an argument that has an evidence-based
default. Output names the method that ran, why the default is the
default, and the method’s known limits. Methods with published evidence
against them remain available but are never the default, and selecting
one prints the critique.

### Selectable score intervals for I-CVI and Psa

Tracking: [\#17](https://github.com/JUhalt/contentvalidR/issues/17).

Wilson score interval as the default (Wilson, 1927; Newcombe, 1998).

Agresti-Coull adjusted Wald interval (Agresti & Coull, 1998).

Clopper-Pearson exact interval (Clopper & Pearson, 1934), documented as
conservative.

Verification against `prop.test(correct = FALSE)` and
[`binom.test()`](https://rdrr.io/r/stats/binom.test.html).

### Panel-level agreement coefficients for expert panels

Tracking: [\#18](https://github.com/JUhalt/contentvalidR/issues/18).

Modified kappa (Polit, Beck & Owen, 2007) is an item-level correction
and stays as it is. This workstream adds a panel-level coefficient
describing agreement across the whole item set, which
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
did not previously report.

Krippendorff’s alpha as the default (Hayes & Krippendorff, 2007;
Krippendorff, 2011), with the measurement level selectable: ordinal
(default), nominal, or interval. Documented as a general reliability
coefficient with no content-validity-specific publication.

Percentile bootstrap intervals that resample items with all ratings
intact, following Zapf et al. (2016).

Gwet’s AC1 (Gwet, 2008) as a never-default option on the relevance
decision, printing the critique in Vach & Gerke (2023).

Output explains that alpha can be low on a high-agreement panel when
nearly every rating is “relevant”, so a low value is not read as a poor
panel.

### Evidence-based factor retention and citations for auxiliary helpers

Tracking: [\#19](https://github.com/JUhalt/contentvalidR/issues/19).

Parallel analysis (Horn, 1965) replaces Kaiser’s eigenvalue \> 1 rule as
the
[`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
default, since Zwick & Velicer (1986) found the Kaiser rule severely
overestimates the number of components.

The Kaiser rule stays selectable by name so earlier results can be
reproduced, and prints the critique when chosen.

Cite Schriesheim et al. (1993, 1999) in
[`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
and Anderson & Gerbing (1991) in
[`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md).

### CRAN submission

Tracking: [\#14](https://github.com/JUhalt/contentvalidR/issues/14).

Populate `cran-comments.md` with actual final check results, including a
sentence distinguishing contentvalidR from the `contentValidity`
package.

Confirm no stray `LICENSE` file reaches the built tarball, and that the
source carries `License: GPL-3` with `inst/NOTICE` preserving the
historical MIT attribution for v0.1.0.

Check the built tarball with `--as-cran`, not only the source directory.

Submit. 0.3.0 was uploaded on 2026-09-15 at 15:56 UTC and confirmed by
the maintainer; it entered CRAN’s `pretest` queue the same day.

Respond to maintainer feedback. CRAN returned 0.3.0 for relative README
links to build-ignored files, reported as invalid file URIs, and its
automated pretest returned 0.3.1 for a hidden `.git` file left by a
worktree build. Both fixes ship in 0.4.0.

Carried forward: acceptance and the README installation update are
tracked under v0.4.0, since 0.4.0 is the version in CRAN review.

### v0.3.0 exit gate

Every new method has a verified published basis, and output names the
method that ran, why it is the default, and its known limits.

Tests reproduce published worked examples for each new method, alongside
recovery, malformed-input, and edge-case tests.

R CMD check is clean across the supported OS/R matrix, including the
R-devel `--as-cran` job that treats any NOTE as a failure.

The built source tarball passes `R CMD check --as-cran` locally, with no
errors or warnings; its notes are explained in `cran-comments.md`.

README, vignettes, NEWS, and citation metadata reflect the release
candidate, and every URL and DOI resolves.

Stable version stamped, tagged, and published through GitHub and the
personal R-universe.

Submitted to CRAN
([\#14](https://github.com/JUhalt/contentvalidR/issues/14)). The GitHub
release does not wait on CRAN acceptance. Win-builder’s R-devel incoming
check then flagged relative README links to files that are not part of
the built package, which the local and CI checks had not reported; 0.3.1
replaces them with full URLs.

### Not implemented on evidence grounds

- **Halo index.** This was deferred from the v0.2.0 judge-heterogeneity
  work. Murphy, Jako & Anhalt (1993) reviewed the halo literature and
  called for a moratorium on halo indices, because true and illusory
  halo cannot be separated.

------------------------------------------------------------------------

## v0.4.0 - Handoff to empirical validation

**Status:** Released (0.4.0 on 2026-09-16; submitted to CRAN the same
day) **Milestone:**
[v0.4.0](https://github.com/JUhalt/contentvalidR/milestone/4)
**Version:** `0.4.0`

### Handoff to nomologR

Tracking: [\#27](https://github.com/JUhalt/contentvalidR/issues/27),
with the downstream companion in
[JUhalt/nomologR#46](https://github.com/JUhalt/nomologR/issues/46),
which holds the agreed exchange schema.

contentvalidR ends where empirical data begin, and `nomologR` starts
there: `nomo_screen(data, items = <names>)` already takes the item set
as a character vector. Today a researcher retypes the surviving item
names, and the reasons behind each decision do not travel with them.

[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
returning the retained item names, a per-item evidence table, and
provenance (workflow, settings, design, version, date).

Item-level workflows only.
[`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
and
[`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md)
refuse with a message naming the reason, since their rows are judges and
blueprint cells rather than items.

Items held back stay listed with `carried = FALSE`. Review is not
deletion, and nothing disappears silently.

A vignette running from the expert panel to `nomo_screen()` and on to
the nomological network.

No new dependency on either side. The handoff is plain data with a
documented shape, so each package builds and tests independently.

Output states that content evidence supports relevance and coverage, not
that an item will behave well empirically.

### Selectable parallel analysis criterion

Tracking: [\#26](https://github.com/JUhalt/contentvalidR/issues/26).

Horn’s mean criterion, which v0.3.0 made the default, still tends to
retain a factor or two by chance on noisy data. Glorfeld (1995) compares
each observed eigenvalue against an upper percentile of the simulated
null distribution instead, and reports that Horn’s procedure, while
relatively accurate, errs toward retaining one or two more factors than
is warranted.

`parallel_criterion` selects `"mean"` (the default, Horn) or
`"percentile"` (Glorfeld), with `percentile` defaulting to 95.

Both criteria read the same simulation, so a single seeded run compares
them directly, and the result records which criterion ran.

The default is unchanged. The mean criterion is what Zwick & Velicer
(1986) evaluated and what v0.3.0 shipped.

### Packaging fixes for the CRAN submission

Tracking: [\#14](https://github.com/JUhalt/contentvalidR/issues/14).

`.Rbuildignore` excludes `.git`, `.gitignore`, and `.gitattributes`.
CRAN’s incoming pretest returned 0.3.1 because a tarball built from a
`git worktree` checkout carried a `.git` **file**, which `R CMD build`
drops only in its directory form.

Submit 0.4.0 to CRAN carrying these fixes, listing the built tarball’s
contents to confirm no dotfiles before upload. The first upload, on
2026-09-16, expired unconfirmed. The 2026-09-18 resubmission passed the
automated pretest and entered CRAN’s `newbies` queue for manual review.

Confirm acceptance, verify the CRAN package page, and verify a clean
`install.packages("contentvalidR")`.

Update the README installation guidance once CRAN is live.

------------------------------------------------------------------------

## v0.5.0 - Delphi rounds and a richer handoff

**Status:** Released (0.5.0 on 2026-09-19, on GitHub and R-universe)
**Milestone:**
[v0.5.0](https://github.com/JUhalt/contentvalidR/milestone/5)
**Version:** `0.5.0`

CRAN: 0.4.0 is still in CRAN’s review queue. CRAN policy asks that no
further submission be made while one is pending, and that established
packages update no more than every one to two months. 0.5.0 will
therefore be submitted as an update once 0.4.0 is resolved, from the
`v0.5.0` tag, with the win-builder log read before upload.

Opened on 2026-09-18, while 0.4.0 is in CRAN review. Any fix CRAN
requests for 0.4.0 branches from the `v0.4.0` tag, so work here cannot
reach that submission.

### Delphi consensus and stability

Tracking: [\#20](https://github.com/JUhalt/contentvalidR/issues/20).

A workflow for successive expert rounds, building on
[`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md).
The evidence steps come first.

Verify the stability statistic from the full text of Holey et al.
(2007). Stability is measured per statement as weighted kappa between
participants’ responses in successive rounds, read as a trend with no
threshold. The individual-level approach rests on Chaffin & Talley
(1980).

Verify the primary stability sources Holey et al. rest on, from their
full texts, reproducing every printed statistic in R. Dajani, Sincoff &
Talley (1979) test *group* stability with a χ² on round by response
category, reading a failure to reject as stability. Chaffin & Talley
(1980) show that group stability does not imply individual stability,
test *individual* stability with a χ² on each respondent’s category in
one round against the next, reading a rejection as stability, and
propose Goodman & Kruskal’s λ when expected counts are small.

Verify the “15% change” stability rule. It is Scheibe, Skutsch &
Schofer’s (1975), verified in the editors’ web edition of the book. It
is a group measure by the authors’ choice: net person-changes between
the two rounds’ histograms, divided by the number of participants. The
authors say it has no statistical theory; the 15% cut-off was set from
about 13% oscillation at the mode in one classroom Delphi.

Offer every published stability method, with Holey et al.’s weighted
kappa as the default (maintainer decision, 2026-09-18). Chaffin &
Talley’s λ and individual χ², Dajani et al.’s group χ², and Scheibe et
al.’s percent change are selectable, each with its critique printed. The
output states which way each test reads, since the two χ² tests point in
opposite directions, and flags expected counts below 5 rather than
pooling silently. Implemented in
[`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md).

Settle the kappa weights against Cohen (1968) and Fleiss & Cohen (1973),
both read in full. Quadratic weights are the default because they make
kappa the intraclass correlation of the two rounds; linear weights are
available under Cohen’s general framework.

Consensus as percent agreement against a threshold the researcher sets a
priori, with no default. Diamond et al. (2014) report a median of 75%
across studies, which describes practice rather than validating a
cutoff.

Report stability as a trend and leave the stopping decision to the
researcher’s a priori criteria. Stability never changes an item’s
status. Holey et al. is a single exploratory study and does not validate
kappa as a stopping rule.

Settle whether verbal kappa labels belong in the output. They do not
(maintainer decision, 2026-09-18). Landis & Koch (1977), p. 165, call
their divisions clearly arbitrary, and kappa falls as a panel converges.
Holey et al.’s most-agreed statement had their lowest kappa.

A vignette that walks a graduate student through a Delphi analysis:
[`vignette("delphi-rounds")`](https://juhalt.github.io/contentvalidR/articles/delphi-rounds.md).

### Interval bounds in the handoff

Tracking: [\#33](https://github.com/JUhalt/contentvalidR/issues/33).

Schema version 1 carries each statistic’s value and criterion but not
its interval. Small panels make the interval matter: a unanimous
four-judge I-CVI has a Wilson 95% lower limit near 0.51.

Agree the schema version with nomologR on
[nomologR#46](https://github.com/JUhalt/nomologR/issues/46). The new
columns are additive within version 1, under three conditions recorded
there: existing fields keep their names, types, and meaning; `NA` means
“this statistic has no interval”, never missing data; and each addition
is listed on \#46 with the contentvalidR version that introduced it.

Carry `lower`, `upper`, `interval_method`, and `interval_level` for
every statistic that has an interval, and the panel-level agreement
interval outside the per-item table. Merged in
[\#36](https://github.com/JUhalt/contentvalidR/pull/36): the interval
columns follow `round` in `item_statistics`, and panel agreement travels
in a new top-level `panel_statistics` table. Fixtures regenerated for
nomologR.

Report intervals only. No mapping from content-validity statistics to
priors; that question belongs to
[nomologR#49](https://github.com/JUhalt/nomologR/issues/49).

Keep the additions table on nomologR#46 accurate, listing the version
that actually ships these columns. Updated on 2026-09-18 with the exact
method labels and the `panel_statistics` row. At release, replace
“merged, not yet released” with the shipping version and its release
date, so the table records what shipped (requested on \#46).

------------------------------------------------------------------------

## v0.6.0 - Hand a Delphi study off to empirical validation

**Status:** Released (0.6.0 on 2026-09-20, on GitHub and R-universe)
**Milestone:**
[v0.6.0](https://github.com/JUhalt/contentvalidR/milestone/6)
**Version:** `0.6.0`

CRAN: unchanged from 0.5.0. 0.4.0 is still in review, so 0.6.0 is not
submitted; whichever version is current when 0.4.0 resolves goes to CRAN
as the update, from its own tag.

Tracking: [\#42](https://github.com/JUhalt/contentvalidR/issues/42).

[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
refused a Delphi fit, although a Delphi study is item-level and ends
with exactly the evidence the handoff carries.

Accept `contentvalid_delphi` in
[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md),
carrying each item’s evidence from its own last round.

Let `round` hold the round an item settled in, rather than a constant.
It is the first workflow where the field carries real information, and
it cannot be set by hand for a Delphi fit.

Carry stability as evidence beside the decision: the share of experts
who kept their rating, and the statistic that ran, named for its method.
Stability never decides what travels.

Tell nomologR which new `statistic` values to expect, since names are
data rather than schema.

Add a [`plot()`](https://rdrr.io/r/graphics/plot.default.html) method
for
[`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md)
([\#44](https://github.com/JUhalt/contentvalidR/issues/44)): consensus
by round, and stability by pair of rounds, drawing no criterion the
analysis did not apply.

Audit printed claims against what the functions compute
([\#41](https://github.com/JUhalt/contentvalidR/issues/41)). The checks
work from real fitted objects, and `.print_key()` now fails on an
unknown term rather than dropping a column’s explanation in silence. The
first pass found no false claim in the printed output.

------------------------------------------------------------------------

## v0.7.0 - Safe to depend on

**Status:** Released (0.7.0 on 2026-09-23, on GitHub and R-universe)
**Milestone:**
[v0.7.0](https://github.com/JUhalt/contentvalidR/milestone/7)
**Version:** `0.7.0`

Planned as housekeeping, it became the release that met most of this
package’s share of the joint 1.0 criteria: a written stability policy, a
frozen handoff schema checked against its readers, the last deprecation
settled, and the joint walkthrough.

Say what an `NA` stability statistic means in a handoff
([\#48](https://github.com/JUhalt/contentvalidR/issues/48)). Documented
the two cases, and added a `note` column carrying the producing
function’s own sentence, so a consumer need not reconstruct
method-specific semantics from statistic names.

Make the release gate’s clean-library smoke test actually run
([\#51](https://github.com/JUhalt/contentvalidR/issues/51)). It lives in
the repository at `tools/release-gate.R`, runs each stage in its own
process, and fails rather than printing findings to read past. The old
gate skipped its own smoke test at three consecutive releases.

State the deprecation policy and public API stability
([\#53](https://github.com/JUhalt/contentvalidR/pull/53)), which is the
1.0 criterion on
[nomologR#53](https://github.com/JUhalt/nomologR/issues/53) that rests
entirely with this package. Three tiers covering every export, the
deprecation cycle, a changed default treated as breaking, the handoff
schema’s guarantees, and which versions of R are supported.

Resolve the one deprecation in flight before 1.0 locks it in
([\#60](https://github.com/JUhalt/contentvalidR/issues/60)). The policy
removes a deprecation in a minor release before 1.0 and only in a major
release afterwards, so this was the last release that could settle
[`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)’s
`posthoc` argument without waiting for 2.0. It is removed;
`posthoc_pass` is documented as deprecated, starting its clock.

Freeze handoff schema version 1
([\#54](https://github.com/JUhalt/contentvalidR/issues/54)), after
checking it against nomologR and solomonR. Adds `keying`,
`response_min`, and `response_max`, which come from the analyst and
never from the fit.

The joint walkthrough on shared teaching data
([\#55](https://github.com/JUhalt/contentvalidR/issues/55)):
[`vignette("one-item-set-both-stages")`](https://juhalt.github.io/contentvalidR/articles/one-item-set-both-stages.md),
where the two stages disagree in both directions.

Settle the two interval extensions
([\#56](https://github.com/JUhalt/contentvalidR/issues/56)). The Delphi
kappa interval turned out to be a published procedure (Klar et al.,
2002) with a measured coverage shortfall at panel sizes, which the
output now reports. The AC1 interval remains an extension, labeled
wherever its number appears.

CRAN: unchanged. 0.4.0 is still in review, so 0.7.0 is not submitted;
whichever version is current when 0.4.0 resolves goes to CRAN as the
update, from its own tag.

------------------------------------------------------------------------

## v1.0.0 - Joint stable release with nomologR (proposed)

**Status:** Proposed by the maintainer on 2026-09-19. Not scheduled.
**Criteria:** agreed jointly on
[nomologR#53](https://github.com/JUhalt/nomologR/issues/53), which is
the single list. This section only mirrors it, with this package’s
progress.

contentvalidR and nomologR are the two halves of scale development:
content review, then empirical validation. They are joined by the
handoff schema on
[nomologR#46](https://github.com/JUhalt/nomologR/issues/46). The target
is for both to release 1.0.0 together, so the version number tells users
the pair is stable together.

Converge, don’t move in lockstep. Minor versions stay independent until
1.0.0, and neither package tags 1.0.0 on its own.

After 1.0.0, major versions move together whenever the shared contract
breaks. Minor versions and patches stay independent.

The criteria on nomologR#53, with where contentvalidR stands now:

the handoff is implemented on both sides, tested against real fixtures
from more than one producer version. The producer shipped in 0.4.0;
nomologR’s reader
([nomologR#46](https://github.com/JUhalt/nomologR/issues/46), closed) is
tested against stored producer output from contentvalidR 0.6.0 and
0.7.0.

schema version 1 is frozen and becomes a compatibility promise (0.7.0).

both packages are on CRAN. Waiting on CRAN’s review of 0.4.0, which has
been in the `newbies` queue since 2026-09-18, and on nomologR’s first
submission.

both public APIs are stable, under a written deprecation policy, as far
as this package goes (0.7.0). The last deprecation in flight,
[`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)’s
`posthoc_pass` column, is removed for 0.8.0, so nothing deprecated is
carried into 1.0.

there is a joint walkthrough from content review to empirical validation
(0.7.0).

the two releases go out on the same day, each linking the other.

------------------------------------------------------------------------

## Future research

**Milestone:** [Future
research](https://github.com/JUhalt/contentvalidR/milestone/3)

Evidence-reviewed items that are not release commitments. Each records
why it is parked and what would move it into a release.

**Bayesian content-validity extensions**: moved to nomologR as
[nomologR#49](https://github.com/JUhalt/nomologR/issues/49), and
[\#2](https://github.com/JUhalt/contentvalidR/issues/2) closed on
2026-09-16. Bayesian Instrument Development (Gajewski et al., 2012,
2013; Jiang et al., 2014) models responses and needs MCMC, which puts it
past the handoff and outside the `Imports: stats` profile. nomologR
records it as a v0.3 candidate, framed as priors on simple structure
(which items belong to which construct) whose strength is earned by
panel evidence, rather than priors on loading size.

**COSMIN content-validity appraisal**: decided not to fit the package,
and [\#16](https://github.com/JUhalt/contentvalidR/issues/16) closed on
2026-09-24. COSMIN (Terwee et al., 2018; guideline version 2.0, Mokkink,
Elsman & Terwee, 2024) is a method for systematic reviews of existing
instruments: reviewers rate study quality, rate evidence against 10
criteria, and grade their certainty, all by judgment that cannot be
computed from panel ratings. It prefers qualitative evidence, and
comprehensibility must come from cognitive interviews with the target
population. Its 2024 guideline extends it to social and behavioral
outcomes, so the domain was not the reason. Researchers who need a
COSMIN appraisal should use COSMIN’s own tools.

**Marginal-ML many-facet Rasch estimation.** An established method, but
it needs a compiled estimation engine, which the dependency policy rules
out.

**Hernández-Nieto’s content validity coefficient (Ccv)**: added for
comparison only, beside Aiken’s V in `expert_validity(legacy = TRUE)`,
after reading the full text (Hernández-Nieto, 2002, pp. 111-160). It
never decides anything: it uses only the mean rating, so it cannot
reflect agreement despite the book’s claim; its chance correction,
(1/J)^J, ignores the ratings and the number of scale points; on a scale
starting at 0 it is Aiken’s V; and its .80 and .90 bands are not
derived, nor kept to by the book’s own examples.
[`?expert_validity`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
documents each shortcoming with page references.

**rWG within-group agreement** (James, Demaree & Wolf, 1984). Designed
for aggregating group ratings; no content-validity application was
verified.

Interactive teaching applications, a methodological package paper, and
research on whether guided output improves applied decisions. These are
not methods questions and are scoped separately.

------------------------------------------------------------------------

## Development principle

`contentvalidR` should continue to distinguish **quantitative evidence**
from automatic item-retention decisions. New functionality belongs in a
stable release only when it improves the validity argument, transparency
of the decision process, or reproducibility of the workflow.

## Keeping plans and pages aligned

Root `README.Rmd`, `ROADMAP.md`, `NEWS.md`, `DESCRIPTION`, and
`CITATION.cff` are the sources of current project information.
Regenerate `README.md` from `README.Rmd` after documentation changes.
The website is not committed: the pkgdown workflow builds it for every
pull request and publishes default-branch changes to the `gh-pages`
branch, which GitHub Pages serves. A local
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
is only a preview, and `docs/` is ignored by git.

Record findings or proposals in an issue with evidence and an observable
outcome. Link the issue here, assign a milestone when its scope is
accepted, and update the roadmap and NEWS when an implementation ships.
Preserve completed release history and identify deferred or experimental
work explicitly.

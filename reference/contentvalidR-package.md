# contentvalidR: Tools for Substantive and Content Validity Pretesting

Provides quantitative tools for substantive and content-oriented scale
pretesting. Implements item-sort indices from Anderson and Gerbing
(1991)
[doi:10.1037/0021-9010.76.5.732](https://doi.org/10.1037/0021-9010.76.5.732)
, exact item-sort inference following Howard and Melloy (2016)
[doi:10.1007/s10869-015-9404-y](https://doi.org/10.1007/s10869-015-9404-y)
, empirical interpretation benchmarks from Colquitt et al. (2019)
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406) , and the
construct-rating procedure of Hinkin and Tracey (1999)
[doi:10.1177/109442819922004](https://doi.org/10.1177/109442819922004)
with HTC/HTD indices and repeated-measures item screening. The
expert-panel workflow combines Aiken's V with score confidence
intervals, Lawshe content validity ratios with exact inference, content
validity indices with modified kappa and score intervals, item-objective
congruence, and panel-level agreement using Krippendorff's alpha as
described by Hayes and Krippendorff (2007)
[doi:10.1080/19312450709336664](https://doi.org/10.1080/19312450709336664)
. Also provides judge and rater heterogeneity analysis following the
generalizability-theory treatment of content-validity ratings in
Crocker, Llabre and Miller (1988)
[doi:10.1111/j.1745-3984.1988.tb00309.x](https://doi.org/10.1111/j.1745-3984.1988.tb00309.x)
, content-domain coverage and expert-perceived content structure
following Sireci and Geisinger (1992)
[doi:10.1177/014662169201600102](https://doi.org/10.1177/014662169201600102)
, consensus and stability across Delphi rounds with between-round
weighted kappa following Holey et al. (2007)
[doi:10.1186/1471-2288-7-52](https://doi.org/10.1186/1471-2288-7-52) ,
comparison across successive pretest rounds, and exact expert-panel
planning. Where published methods compete, users choose among them
through arguments with evidence-based defaults. User-facing workflows
emphasize interpretable summaries and transparent review recommendations
rather than isolated coefficients.

## What you can rely on

Code written against contentvalidR should keep working. This section
says exactly what "keep working" covers, so that a study analyzed today
can be reanalyzed later and a downstream package can read this one's
output without guessing.

The public API is in three tiers.

**Tier 1, the recommended workflows.**
[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md),
[`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md),
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md),
[`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md),
[`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md),
and
[`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md);
their [`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html), and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods; the
object contract they share (`results`, `scale_summary`, `settings`,
`design`, `details`); the shared status vocabulary (`Supported`,
`Review`, `Insufficient data`, `Descriptive only`); and
[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md),
[`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md),
[`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md),
[`as.data.frame.contentvalid_workflow()`](https://juhalt.github.io/contentvalidR/reference/as.data.frame.contentvalid_workflow.md),
and
[`contentvalid_glossary()`](https://juhalt.github.io/contentvalidR/reference/contentvalid_glossary.md).

Tier 1 will not change in a way that breaks working code except across a
major version, and never without the deprecation cycle below.

**Tier 2, the component indices and planning helpers.**
[`aikens_v()`](https://juhalt.github.io/contentvalidR/reference/aikens_v.md),
[`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md),
[`cvr()`](https://juhalt.github.io/contentvalidR/reference/cvr.md),
[`ioc()`](https://juhalt.github.io/contentvalidR/reference/ioc.md),
[`htc()`](https://juhalt.github.io/contentvalidR/reference/htc.md),
[`htd()`](https://juhalt.github.io/contentvalidR/reference/htd.md),
[`compute_psa()`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md),
[`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md),
[`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md),
[`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md),
[`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md),
[`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md),
[`colquitt_benchmarks()`](https://juhalt.github.io/contentvalidR/reference/colquitt_benchmarks.md),
[`interpret_colquitt()`](https://juhalt.github.io/contentvalidR/reference/interpret_colquitt.md),
[`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md),
[`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md),
and
[`similarity_from_sort()`](https://juhalt.github.io/contentvalidR/reference/similarity_from_sort.md).

These are supported and tested to the same standard. They may gain
arguments, and their return values may gain fields. Anything that would
break working code goes through the deprecation cycle.

**Tier 3, auxiliary and compatibility helpers.**
[`agreement_summary()`](https://juhalt.github.io/contentvalidR/reference/agreement_summary.md),
[`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md),
[`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md),
[`reproducibility_phi()`](https://juhalt.github.io/contentvalidR/reference/reproducibility_phi.md),
[`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md),
[`simulate_anova_power()`](https://juhalt.github.io/contentvalidR/reference/simulate_anova_power.md),
and
[`simulate_csv_power()`](https://juhalt.github.io/contentvalidR/reference/simulate_csv_power.md).

These are kept for continuity with older analyses and for sensitivity
checks. They are not recommended workflows, and they may be deprecated
and removed with one minor release of warning.

Anything else is internal: functions whose names begin with a dot,
anything reached with `:::`, and the exact wording of printed output.
Internals can change in any release.

## How something is deprecated

Nothing exported disappears without warning first.

1.  The function or argument keeps working and warns, saying what to use
    instead.
    [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)'s
    `posthoc` argument is the current example.

2.  The warning stands for **at least one minor release**, so code has a
    version in which it both runs and tells you what to change.

3.  Removal follows: in a minor release before 1.0, and only in a major
    release from 1.0 onward.

4.  `NEWS.md` records both the deprecation and the removal, with the
    replacement.

## Changing a default

A changed default can silently change published numbers, so it is
treated as a breaking change even though no code fails. When a default
changes, the release notes say what changed, why the evidence supports
it, and which argument restores the previous behavior. Defaults are
chosen from published evidence; when that evidence is contested, the
contested option is available through an argument rather than made the
default.

## The handoff schema

[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
returns an exchange object that another package reads, so it carries its
own contract, agreed with the `nomologR` maintainers and recorded at
<https://github.com/JUhalt/nomologR/issues/46>.

- Fields may be **added** within a schema version. Existing fields keep
  their names, types, and meanings.

- Changing or removing a field, or changing what one means, requires a
  new `schema_version`.

- A reader checks that an optional field is present rather than assuming
  it, and infers nothing from its absence beyond "this producer version
  did not emit it".

- The values in the `statistic` column are data rather than schema, and
  the `note` column is display text. Both may be reworded in a minor
  release, so neither should be matched on.

## Versions of R

The current R release and the one before it are supported and tested,
along with R-devel. Support for an older R is dropped only when it
prevents a correct implementation, and the release notes say so.

## See also

Useful links:

- <https://github.com/JUhalt/contentvalidR>

- <https://juhalt.github.io/contentvalidR/>

- Report bugs at <https://github.com/JUhalt/contentvalidR/issues>

## Author

**Maintainer**: Joshua Uhalt <Josh.Uhalt@gmail.com>

Authors:

- Joshua Uhalt <Josh.Uhalt@gmail.com>

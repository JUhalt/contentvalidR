# contentvalidR: Tools for Substantive and Content Validity Pretesting

Provides quantitative tools for substantive and content-oriented scale
pretesting. Implements item-sort indices from Anderson and Gerbing
(1991)
[doi:10.1037/0021-9010.76.5.732](https://doi.org/10.1037/0021-9010.76.5.732)
, exact item-sort inference following Howard and Melloy (2016)
[doi:10.1007/s10869-015-9404-y](https://doi.org/10.1007/s10869-015-9404-y)
, and the construct-rating procedure of Hinkin and Tracey (1999)
[doi:10.1177/109442819922004](https://doi.org/10.1177/109442819922004) ,
with the Hinkin-Tracey correspondence and distinctiveness indices and
empirical interpretation benchmarks of Colquitt et al. (2019)
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406) and
repeated-measures item screening following MacKenzie et al. (2011)
[doi:10.2307/23044045](https://doi.org/10.2307/23044045) . The
expert-panel workflow combines Aiken's V with score confidence
intervals, Lawshe content validity ratios with exact inference, content
validity indices with modified kappa and score intervals, item-objective
congruence, and panel-level agreement using Krippendorff's alpha as
described by Hayes and Krippendorff (2007)
[doi:10.1080/19312450709336664](https://doi.org/10.1080/19312450709336664)
. Also provides judge and rater heterogeneity analysis following the
generalizability-theory treatment of content-validity ratings in Crocker
et al. (1988)
[doi:10.1111/j.1745-3984.1988.tb00309.x](https://doi.org/10.1111/j.1745-3984.1988.tb00309.x)
, content-domain coverage against a blueprint, expert-perceived content
structure adapted from Sireci and Geisinger (1992)
[doi:10.1177/014662169201600102](https://doi.org/10.1177/014662169201600102)
, consensus and stability across Delphi rounds with between-round
weighted kappa following Holey et al. (2007)
[doi:10.1186/1471-2288-7-52](https://doi.org/10.1186/1471-2288-7-52) ,
comparison across successive pretest rounds, and exact expert-panel
planning. Where published methods compete, users choose among them
through arguments with evidence-based defaults. User-facing workflows
emphasize interpretable summaries and transparent review recommendations
rather than isolated coefficients.

## Reading the output

The printouts follow a style shared with nomologR, so the two packages
read alike. Every printout opens with a header naming the object's class
and what it holds, such as `<contentvalid_sort> Item-sort analysis`,
then its facts, then its verdict.
[`print()`](https://rdrr.io/r/base/print.html) shows the full evidence
with a key to its columns;
[`summary()`](https://rdrr.io/r/base/summary.html) shows what needs
attention, the flagged units with a sentence each. A workflow's printout
ends with what the evidence does not decide, and every printout ends
with a line pointing to what else the object holds. Markdown output from
[`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
is the one exception: it prints only the lines to paste. Numbers follow
APA 7: no leading zero where a value cannot exceed 1, two decimals and
three for *p*, `--` for a value that could not be computed, and `> .999`
for a *p* that would round to 1.

The statuses read across the two packages as follows:

|                   |              |
|-------------------|--------------|
| contentvalidR     | nomologR     |
| Supported         | no flag      |
| Review            | review       |
| (no counterpart)  | concern      |
| Insufficient data | not computed |
| Descriptive only  | note         |

"Review" always means look again, never delete. In the `results` and the
handoff of this package, `recommendation` is the decision word (such as
`"Retain"` or `"Strong support"`); `status` is the shared vocabulary
above.

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
their [`print()`](https://rdrr.io/r/base/print.html) and
[`summary()`](https://rdrr.io/r/base/summary.html) methods, and the
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods of the
first four (when similarity data were supplied, a domain fit's content
map is drawn with `plot(fit$details$structure)`); the object contract
they share (`results`, `scale_summary`, `settings`, `design`,
`details`); the shared status vocabulary (`Supported`, `Review`,
`Insufficient data`, `Descriptive only`); and
[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md),
[`content_evidence()`](https://juhalt.github.io/contentvalidR/reference/content_evidence.md),
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
[`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md),
and
[`similarity_from_sort()`](https://juhalt.github.io/contentvalidR/reference/similarity_from_sort.md).

These are supported and tested to the same standard. They may gain
arguments, and their return values may gain fields. Anything that would
break working code goes through the deprecation cycle.

**Tier 3, auxiliary and compatibility helpers.**
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

1.  The function, argument, or returned field keeps working and says
    what to use instead. An argument warns when it is passed; a returned
    field cannot warn when it is read, so its documentation carries the
    notice instead.

2.  The notice stands for **at least one minor release**, so code has a
    version in which it both runs and tells you what to change.

3.  Removal follows: in a minor release before 1.0, and only in a major
    release from 1.0 onward.

4.  `NEWS.md` records both the deprecation and the removal, with the
    replacement.

[`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
supplies an example of each kind. Its `posthoc` argument was deprecated
in the first release, warned through every release to 0.6.0, and was
removed in 0.7.0. Its `posthoc_pass` returned column, a duplicate of
`contrast_pass`, could not warn when read, so it was documented as
deprecated in 0.7.0 and removed in 0.8.0. Both ends of each are recorded
in `NEWS.md`.

`agreement_summary()`, a Tier 3 helper, was deprecated in 0.9.0 and is
removed in 1.0.0: it was the only function that took items in rows
rather than raters, and
[`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
does its job. Nothing deprecated is carried past 1.0.

Five returned fields were removed at 1.0.0 without that notice, because
the audit before 1.0 found them wrong or unreachable, and a release that
kept them would have kept wrong values in use: `overall_strength` in the
`scale_summary` of
[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
and
[`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
(a combination of the two Colquitt et al. levels that they do not
publish), `n_support` in that of
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
(a count of a decision that could not occur), `competitor_ioc` in its
congruence `results` (a mean labeled as the index), `n_influential` in
the `scale_summary` of
[`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
(a flag that was withdrawn), and `fit_label` in the `fit` table of
[`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md)
(Kruskal's labels, which belong to a different statistic). With the
congruence index corrected, its handoff statistics `competitor IOC` and
`IOC margin` gave way to `target IOC` and the two mean ratings.
`NEWS.md` gives the reason for each.

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

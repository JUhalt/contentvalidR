# Glossary of contentvalidR indices and status terms

Plain-language definitions of every abbreviated quantity the package
reports, and of the status labels shared by all flagship workflows.

The same definitions are printed beneath workflow output, so what you
read here is what appears alongside your results. Set
`options(contentvalidR.show_key = FALSE)` to suppress those inline keys
once the terms are familiar.

## Usage

``` r
contentvalid_glossary(workflow = NULL)
```

## Arguments

- workflow:

  Optionally restrict to one workflow: `"item-sort"`,
  `"construct-rating"`, `"expert-panel"`, `"judge-heterogeneity"`,
  `"domain-coverage"`, or `"delphi"`.

## Value

An object of class `contentvalid_glossary`: a data frame of `term`,
`workflow`, `label`, `definition`, and `range`, carrying the status
definitions as the `"statuses"` attribute.

## A note on benchmark labels

Strength labels such as `Strong` or `Weak` from
[`interpret_colquitt()`](https://juhalt.github.io/contentvalidR/reference/interpret_colquitt.md)
are percentile positions relative to scales published in the measurement
literature. They are not absolute judgments, and they are not comparable
across indices: HTC and HTD sit on different scales with different
typical values, so an HTC of .83 can be labeled `Weak` in the same
analysis where an HTD of .44 is labeled `Very Strong`. Compare each
index against its own benchmark, never against another index's number.

## See also

[`interpret_colquitt()`](https://juhalt.github.io/contentvalidR/reference/interpret_colquitt.md)
for the benchmark bands themselves.

## Examples

``` r
contentvalid_glossary()
#> <contentvalid_glossary> Glossary
#> 
#> Item-sort workflow ("item-sort")
#>   psa -- Proportion of Substantive Agreement. Share of judges who assigned the
#>       item to the construct it was written for. Higher means judges recognized
#>       the item as belonging where you intended. (0 to 1; higher is stronger)
#>   csv -- Coefficient of Substantive Validity. How much more often the item
#>       went to its intended construct than to the alternative construct judges
#>       chose most. It rewards being distinctly right, not merely often right.
#>       (-1 to 1; 0 means the intended construct and its closest rival were
#>       chosen equally often)
#>   competitor -- Strongest competing construct. The construct, other than the
#>       intended one, that judges chose most often for this item.
#>   p_value -- Howard-Melloy exact test. Probability of seeing at least this
#>       many target assignments if each judge chose the intended construct with
#>       probability p0. The default, .50, is the benchmark Howard and Melloy
#>       (2016) used; it is not the rate expected from random assignment, which
#>       is 1 divided by the number of constructs. Small values mean judges chose
#>       the intended construct more often than that benchmark. (0 to 1; compared
#>       against alpha)
#>   psa_low/psa_high -- Interval for Psa. Lower and upper limits of an interval
#>       around Psa. A wide interval means few judges sorted the item, so a
#>       different sample of judges could plausibly give a quite different Psa.
#>       (between 0 and 1; the method and level are named in the output)
#>   Decisions
#>     Retain -- met the exact target-assignment criterion.
#>     Review -- did not meet the exact target-assignment criterion; the
#>         competitor column shows where judges put it instead.
#>     Insufficient panel -- too few judges sorted it for any count to meet the
#>         exact criterion.
#>     Insufficient data -- no judge sorted it.
#> 
#> Construct-rating workflow ("construct-rating")
#>   htc -- Hinkin-Tracey Correspondence. Average rating of the item against its
#>       intended construct definition, divided by the number of scale points.
#>       The lowest possible rating still counts as one point, so the index
#>       cannot reach 0. (1 / (scale points) to 1, so .20 to 1 on a 5-point
#>       scale; higher is stronger)
#>   htd -- Hinkin-Tracey Distinctiveness. How far the intended construct's
#>       rating exceeds the other constructs' ratings, averaged over every other
#>       construct and every judge, as a proportion of the widest possible
#>       difference. It is a difference, so its typical values are far smaller
#>       than HTC's. (-1 to 1, usually a small positive number; higher is
#>       stronger)
#>   Decisions
#>     Retain -- its ratings differed across constructs (the omnibus test) and
#>         the intended construct was rated above every other (every planned
#>         contrast).
#>     Review -- did not meet every criterion; the competitor column shows the
#>         closest rival.
#>     Insufficient data -- fewer than two judges rated it against every
#>         construct.
#> 
#> Expert-panel workflow ("expert-panel")
#>   V -- Aiken's V. Relevance index that rescales the experts' average rating to
#>       run from 0 to 1 given the bounds of the rating scale used. (0 to 1;
#>       higher is stronger)
#>   I_CVI -- Item-level Content Validity Index. Proportion of experts who rated
#>       the item as relevant, after applying the relevance cut. (0 to 1;
#>       compared with Lynn's (1986) criterion for the panel size, which this
#>       package extends past ten experts at her 7 of 9)
#>   I_CVI_low/I_CVI_high -- Interval for I-CVI. Lower and upper limits of an
#>       interval around I-CVI. Expert panels are usually small, so these
#>       intervals are often wide: a single I-CVI value can look more settled
#>       than the number of experts behind it supports. (between 0 and 1; the
#>       method and level are named in the output)
#>   kappa_mod -- Modified kappa. I-CVI adjusted for the chance that experts
#>       would have agreed even if rating at random. With small panels, chance
#>       agreement is substantial, which is why the raw I-CVI alone can overstate
#>       consensus. (at most 1; below 0 only when no expert, or one of three,
#>       rated the item relevant; higher is stronger)
#>   agreement -- Panel-level agreement. One coefficient describing how
#>       consistently the whole panel rated the item set: Krippendorff's alpha,
#>       the default (see agreement_ac1 for Gwet's AC1). It is separate from
#>       modified kappa, which describes one item at a time. (1 is perfect
#>       agreement and 0 is agreement no better than chance; it can be low on a
#>       close-agreeing panel whose ratings cluster on one value)
#>   agreement_ac1 -- Panel-level agreement (Gwet's AC1). One coefficient
#>       describing how consistently the whole panel made the
#>       relevant/not-relevant decision, with chance agreement estimated so that
#>       it stays small when nearly every rating falls in one category. It is
#>       separate from modified kappa, which describes one item at a time. (1 is
#>       perfect agreement; 0 is agreement equal to AC1's own chance estimate,
#>       which independent raters need not reach; it stays high when nearly every
#>       rating is the same)
#>   S_CVI_Ave -- Scale-level CVI, averaging method. The mean of the items'
#>       I-CVIs, the same quantity as the average congruency percentage. Polit
#>       and Beck (2006) recommend .90 or higher. (0 to 1)
#>   S_CVI_UA -- Scale-level CVI, universal agreement. The share of items that
#>       every expert rated relevant. It falls as experts are added, so Polit and
#>       Beck (2006) recommend reporting it beside S-CVI/Ave. (0 to 1)
#>   cvr -- Lawshe's Content Validity Ratio. How far the panel leans toward
#>       calling the item essential rather than merely useful. (-1 to 1; above 0
#>       means more than half the panel called it essential)
#>   ioc -- Index of item-objective congruence. Whether experts matched the item
#>       to an objective and not to the item's other objectives: half the gap
#>       between their mean rating on the objective and their mean rating on the
#>       others (Rovinelli & Hambleton, 1977). It is 1 only when every expert
#>       rates the item +1 on the objective and -1 on every other. (-1 to 1;
#>       Rovinelli and Hambleton applied a criterion of .70)
#>   Decisions (relevance)
#>     Strong support -- met the I-CVI criterion, which also puts modified kappa
#>         above .74.
#>     Review -- did not meet the I-CVI criterion.
#>     Insufficient panel -- fewer than three experts rated it.
#>   Decisions (essentiality)
#>     Supported -- enough experts rated it essential to pass the exact test.
#>     Review -- too few experts rated it essential to pass the exact test.
#>     Insufficient panel -- too few experts rated it for any count to pass the
#>         exact test.
#>     Insufficient data -- no expert rated it.
#>   Decisions (congruence)
#>     Congruent -- its index of item-objective congruence met the criterion.
#>     Review -- its index fell below the criterion; the margin shows how its
#>         intended objective compares with the closest other.
#>     Target described -- only its intended objective was rated, so there is
#>         nothing to compare.
#>     Insufficient data -- no usable ratings for its intended objective.
#>     Descriptive only -- no intended objective was given, so the index is only
#>         described.
#> 
#> Judge-heterogeneity workflow ("judge-heterogeneity")
#>   severity_raw -- Judge severity. How harsh or lenient a judge is compared
#>       with the panel, on the items that judge rated, in rating points
#>       (`severity_raw` in `results`, printed as severity). Positive means the
#>       judge rates lower than the panel. (0 means typical of this panel)
#>   severity -- Judge severity in logits. Severity estimated by the many-facet
#>       Rasch model on the relevant/not-relevant decision, against the judges
#>       the model placed (`severity` in `results`, printed as logit), by default
#>       corrected for the bias of joint maximum likelihood (`bias_correct`).
#>       Positive means harsher. It can differ from the rating-point severity,
#>       even in sign. (0 means typical of the judges placed; flagged beyond the
#>       logit cut)
#>   infit/outfit -- Fit mean squares. Whether a judge's pattern of decisions is
#>       as predictable as the model expects. Around 1 is expected; high values
#>       mean erratic ratings, low values mean ratings more predictable than
#>       expected. Linacre (2002) calls 0.5 to 1.5 productive for measurement.
#>       Only a value above that range is flagged, and only when it rests on
#>       enough decisions. (around 1.0 is expected; 0.5 to 1.5 is productive for
#>       measurement)
#>   differentiation -- Scale use. How widely a judge spread their ratings
#>       compared with a typical judge on this panel. Values well below 1 mean
#>       the judge distinguished less among items. (1.0 is typical of this panel)
#>   g_coefficient -- Generalizability coefficient. How dependably the ranking of
#>       items by rated relevance would reproduce with a different panel of the
#>       same size. Use it for comparative decisions such as picking the best
#>       items from a pool. (0 to 1; higher is stronger)
#>   phi_coefficient -- Dependability coefficient. How dependably the absolute
#>       level of the ratings would reproduce with a different panel of the same
#>       size. Penalized by judge severity differences, and usually the relevant
#>       one for content validity, where items are judged against a fixed
#>       standard. (0 to 1; never exceeds the generalizability coefficient)
#>   Decisions
#>     Typical -- consistent with the panel.
#>     Severe -- rates markedly lower than the panel.
#>     Lenient -- rates markedly higher than the panel.
#>     Erratic -- decisions noisier than the model expects (infit or outfit above
#>         the range).
#>     Low differentiation -- draws few distinctions among items compared with
#>         other judges.
#>     Insufficient data -- fewer than two usable ratings, or no other judge to
#>         compare with.
#> 
#> Domain-coverage workflow ("domain-coverage")
#>   share -- Share of items. Percentage of all items that fall in this blueprint
#>       cell. (0 to 100%)
#>   adjusted_rand -- Adjusted Rand index. How closely the groupings experts
#>       perceive match the blueprint's cells, corrected for the agreement
#>       expected by chance. (0 is chance agreement, 1 is exact; can be slightly
#>       negative)
#>   stress -- Map distortion. How far the distances on the content map depart
#>       from the experts' dissimilarities: the root of their squared differences
#>       over the squared dissimilarities. Lower is a closer map. It is not
#>       Kruskal's (1964) stress-1, which belongs to nonmetric scaling, so his
#>       verbal benchmarks do not apply to it. (0 is an exact map; no published
#>       benchmark applies)
#>   Decisions
#>     Covered -- met the coverage criteria.
#>     Thinly covered -- fewer items than the minimum set for this analysis.
#>     Over-represented -- more than `over_factor` times its expected share of
#>         the items.
#>     Under-represented -- less than its target share divided by `over_factor`.
#>     Not covered -- the blueprint includes it, but no item addresses it.
#> 
#> Delphi workflow ("delphi")
#>   prop_agree -- Share of experts agreeing. Share of the experts rating an item
#>       in a round whose rating was at or above the agreement cut. On a
#>       relevance scale this is the I-CVI. Consensus means it reached the
#>       consensus threshold supplied. (0 to 1; higher is broader agreement)
#>   prop_unchanged -- Share of experts keeping their rating. Among experts who
#>       rated the item in both of two consecutive rounds, the share who gave
#>       exactly the same rating again. It is the plainest reading of stability,
#>       and it stays meaningful when kappa does not. (0 to 1; 1 means no expert
#>       changed their rating)
#>   kappa_w -- Weighted kappa between rounds. Agreement between each expert's
#>       ratings in two consecutive rounds, corrected for chance, with larger
#>       changes counting more. Read it as a trend across rounds. It can be low
#>       when ratings bunch in one category, so a converged panel can show a low
#>       kappa even when almost no one changed their rating. (-1 to 1; 1 is
#>       perfect stability, 0 is no better than chance)
#>   lambda -- Goodman-Kruskal lambda, an index of predictive association. How
#>       much knowing an expert's earlier rating improves a guess at their later
#>       one. It measures predictability, not agreement: experts who all moved up
#>       one category would still score 1. (0 to 1; undefined when the later
#>       round is unanimous)
#>   chi_sq_individual -- Individual stability chi-square. Tests whether experts'
#>       later ratings depend on their earlier ones. A significant result is read
#>       as stability. It needs expected counts of at least 5, which small panels
#>       rarely have. (0 or more; read with its p value)
#>   chi_sq_group -- Group stability chi-square. Tests whether the two rounds'
#>       rating distributions differ. A non-significant result is read as
#>       stability, so small panels often look stable because the test has little
#>       power, and experts swapping ratings go unseen. (0 or more; read with its
#>       p value)
#>   percent_change -- Net change in the rating distribution. How far the panel's
#>       rating distribution moved between two rounds, as a share of the experts
#>       compared. Change below 15% is read as stable, a threshold its authors
#>       set from one study without statistical theory. (0 to 1; stable below
#>       .15)
#>   Decisions
#>     Consensus -- reached the consensus threshold in its last round.
#>     No consensus -- did not reach the consensus threshold.
#>     Descriptive only -- no consensus threshold was set, so agreement is only
#>         described.
#>     Insufficient panel -- fewer than three experts rated it in its last round.
#> 
#> Status labels
#>   Supported -- The evidence met the criteria set for this analysis.
#>   Review -- Something here needs a closer look. This is not an instruction to
#>       delete anything.
#>   Insufficient data -- Too little usable data to reach a judgment.
#>   Descriptive only -- Reported for description only; no decision rule was
#>       applied.
#>   Each decision word above maps onto one of these statuses, stored in the
#>   `status` column of `results`.
#> 
#> Strength labels such as Strong or Weak are percentile positions relative to
#> published scales, not absolute judgments, and are not comparable across
#> different indices.
#> 
#> See as.data.frame(x) for the definitions as a table.
contentvalid_glossary("item-sort")
#> <contentvalid_glossary> Glossary
#> 
#> Item-sort workflow ("item-sort")
#>   psa -- Proportion of Substantive Agreement. Share of judges who assigned the
#>       item to the construct it was written for. Higher means judges recognized
#>       the item as belonging where you intended. (0 to 1; higher is stronger)
#>   csv -- Coefficient of Substantive Validity. How much more often the item
#>       went to its intended construct than to the alternative construct judges
#>       chose most. It rewards being distinctly right, not merely often right.
#>       (-1 to 1; 0 means the intended construct and its closest rival were
#>       chosen equally often)
#>   competitor -- Strongest competing construct. The construct, other than the
#>       intended one, that judges chose most often for this item.
#>   p_value -- Howard-Melloy exact test. Probability of seeing at least this
#>       many target assignments if each judge chose the intended construct with
#>       probability p0. The default, .50, is the benchmark Howard and Melloy
#>       (2016) used; it is not the rate expected from random assignment, which
#>       is 1 divided by the number of constructs. Small values mean judges chose
#>       the intended construct more often than that benchmark. (0 to 1; compared
#>       against alpha)
#>   psa_low/psa_high -- Interval for Psa. Lower and upper limits of an interval
#>       around Psa. A wide interval means few judges sorted the item, so a
#>       different sample of judges could plausibly give a quite different Psa.
#>       (between 0 and 1; the method and level are named in the output)
#>   Decisions
#>     Retain -- met the exact target-assignment criterion.
#>     Review -- did not meet the exact target-assignment criterion; the
#>         competitor column shows where judges put it instead.
#>     Insufficient panel -- too few judges sorted it for any count to meet the
#>         exact criterion.
#>     Insufficient data -- no judge sorted it.
#> 
#> Status labels
#>   Supported -- The evidence met the criteria set for this analysis.
#>   Review -- Something here needs a closer look. This is not an instruction to
#>       delete anything.
#>   Insufficient data -- Too little usable data to reach a judgment.
#>   Descriptive only -- Reported for description only; no decision rule was
#>       applied.
#>   Each decision word above maps onto one of these statuses, stored in the
#>   `status` column of `results`.
#> 
#> Strength labels such as Strong or Weak are percentile positions relative to
#> published scales, not absolute judgments, and are not comparable across
#> different indices.
#> 
#> See as.data.frame(x) for the definitions as a table.
```

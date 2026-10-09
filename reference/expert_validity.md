# Analyze expert-panel content-validity evidence

Provides a user-facing workflow for three common expert-panel tasks:

- `mode = "relevance"`: bounded ordinal relevance ratings, combining
  Aiken's (1980) V (with the score intervals of Penfield and Giacobbi,
  2004), the CVI with the modified kappa of Polit et al. (2007), and a
  panel-level agreement coefficient.

- `mode = "essentiality"`: Lawshe CVR with exact binomial critical
  values.

- `mode = "congruence"`: the index of item-objective congruence of
  Rovinelli and Hambleton (1977), from ratings of +1, 0, or -1 on each
  objective (see
  [`ioc()`](https://juhalt.github.io/contentvalidR/reference/ioc.md)).

Quantitative results are presented as evidence for item review rather
than as a substitute for expert comments, construct coverage,
comprehensibility, or other parts of a content-validity argument.

In essentiality mode an item rated by so few experts that no count could
meet the exact test (four or fewer at the default `alpha`) is labeled
`"Insufficient panel"`, with status `"Insufficient data"`, as an item
rated by fewer than three experts is in relevance mode. It is not
`"Review"`, which would say the experts had disagreed.

## Usage

``` r
expert_validity(
  data,
  mode = c("relevance", "essentiality", "congruence"),
  lo = 1,
  hi = 4,
  relevance_cut = NULL,
  N = NULL,
  alpha = 0.05,
  na.rm = FALSE,
  target_col = "target_objective",
  ioc_cut = 0.7,
  proportion_ci = c("wilson", "agresti_coull", "exact", "none"),
  agreement = c("krippendorff", "ac1", "none"),
  agreement_level = c("ordinal", "nominal", "interval"),
  agreement_B = 1000,
  seed = NULL,
  legacy = FALSE
)
```

## Arguments

- data:

  Ratings data. For relevance, a judge-by-item numeric matrix/data
  frame. For essentiality, either a judge-by-item 0/1 matrix/data frame
  or a vector of essential counts, whose names become the item names
  when every count has a distinct name. For congruence, a long data
  frame accepted by
  [`ioc()`](https://juhalt.github.io/contentvalidR/reference/ioc.md). In
  a judge-by-item table every column is an item; a column whose name
  looks like a rater ID (such as `expert` or `rater_id`) stops the
  function, so remove it, or rename an item that has such a name.

- mode:

  One of `"relevance"`, `"essentiality"`, or `"congruence"`.

- lo, hi:

  Rating-scale bounds for relevance mode. The default is the 1-4
  relevance scale; give the bounds for any other scale, because Aiken's
  V and the relevance cut both depend on them. The printout states the
  scale that was used.

- relevance_cut:

  Lowest rating treated as relevant for CVI. Defaults to `hi - 1`, e.g.,
  3 on a 1-4 scale or 4 on a 1-5 scale, and to `hi` on a two-point
  scale. The default assumes scale points one unit apart, so set the cut
  yourself on any other scale. It must lie above `lo`: at `lo` every
  rating would count as relevant.

- N:

  Panel size for essential-count vector input.

- alpha:

  Inferential/CI alpha level.

- na.rm:

  Permit itemwise/cellwise missing ratings where supported.

- target_col:

  In congruence mode, optional column identifying each item's intended
  objective. If absent, every item-objective index is described and no
  decision is made.

- ioc_cut:

  In congruence mode, the lowest index of item-objective congruence that
  counts as congruent. The default, .70, is the criterion Rovinelli and
  Hambleton (1977) applied. Turner and Carlson (2003) extend the index
  to items written for more than one objective, which this package does
  not do.

- proportion_ci:

  Interval method for I-CVI in relevance mode: `"wilson"` (default),
  `"agresti_coull"`, `"exact"`, or `"none"`. The interval uses the same
  `alpha` as Aiken's V. See `ci` in
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) for
  the methods and the evidence for each.

- agreement:

  Panel-level agreement coefficient for relevance mode: `"krippendorff"`
  (default), `"ac1"`, or `"none"`. Krippendorff's alpha (Hayes &
  Krippendorff, 2007), which Zapf et al. (2016) recommend for ordinal or
  incomplete ratings, uses the relevance ratings at `agreement_level`;
  Gwet's AC1 uses the relevant/not-relevant decision. See
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
  for the evidence behind each, including why AC1 is never the default.
  Panels with fewer than two experts or two items report no agreement
  coefficient.

- agreement_level:

  Measurement level for Krippendorff's alpha: `"ordinal"` (default),
  `"nominal"`, or `"interval"`. Ignored for AC1.

- agreement_B:

  Bootstrap resamples for the agreement interval; `0` skips the
  interval.

- seed:

  Optional seed that makes the agreement interval reproducible. The
  random-number stream of the session is left as it was.

- legacy:

  Print the earlier published rules beside the decision, for comparison,
  in relevance and essentiality modes. Default `FALSE`. They are
  computed either way, stored in `details$earlier_methods`, and never
  change the decision; `print(fit, legacy = TRUE)` shows them for any
  fit.

## Value

An object of class `contentvalid_expert` and `contentvalid_workflow`.
All flagship workflow objects expose the common components `results`,
`scale_summary`, `settings`, `design`, and `details`. The historical
top-level `scale` component is retained as a compatibility alias for
`scale_summary`. Results include a standardized `status` field while
retaining mode-specific `recommendation` wording. In relevance mode,
`scale_summary` also holds `agreement`, `agreement_low`, and
`agreement_high`, and `details$agreement` holds the full
[`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
result. [`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html), and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) are described
in
[contentvalid-methods](https://juhalt.github.io/contentvalidR/reference/contentvalid-methods.md).

**Results columns.** `results` has one row per item, and its columns
depend on `mode`. Every mode ends with `recommendation`, the decision in
the mode's own words; `interpretation`, the decision explained in a
sentence; and `status`, the shared status.

In relevance mode:

- `item`:

  The item.

- `N`:

  Experts who rated the item.

- `n_missing`:

  Experts who did not.

- `V`:

  Aiken's V.

- `ci_low`, `ci_high`:

  The interval for V at level `1 - alpha`.

- `ci_method`:

  The method of that interval, the score interval of Penfield and
  Giacobbi (2004).

- `A`:

  Experts who rated the item relevant, at or above `relevance_cut`.

- `I_CVI`:

  The I-CVI, `A / N`.

- `I_CVI_low`, `I_CVI_high`:

  The interval for the I-CVI, by the method in `proportion_ci`; `NA`
  with `"none"`.

- `Pc`:

  The probability of chance agreement that modified kappa corrects for
  (Polit et al., 2007).

- `kappa_mod`:

  Modified kappa.

- `cvi_criterion`:

  The I-CVI that Lynn's (1986) criterion requires for the item's panel
  size, as a proportion; `NA` below three experts. It is shown for
  reading: the decision compares counts.

- `kappa_quality`:

  The band of `kappa_mod` in the guidelines of Cicchetti and
  Sparrow (1981) and Fleiss (1981), as cited in Polit et al. (2007), who
  apply them to modified kappa: `"Excellent"` above .74, `"Good"` from
  .60 to .74, `"Fair"` from .40 to .59, and `"Poor"` below .40. The band
  describes the item and decides nothing; every item that meets the
  I-CVI criterion is `"Excellent"`.

- `ci_width`:

  The width of the interval for V, `ci_high - ci_low`.

- `recommendation`:

  `"Strong support"` (the item meets the I-CVI criterion), `"Review"`,
  or `"Insufficient panel"` (fewer than three experts).

In essentiality mode:

- `item`:

  The item.

- `ne`:

  Experts who rated the item essential.

- `N`:

  Experts who rated the item.

- `cvr`:

  Lawshe's CVR, `(ne - N / 2) / (N / 2)`.

- `p_value`:

  The one-sided exact binomial *p* of `ne` at a rate of .5.

- `critical_ne`:

  The fewest essential ratings that meet the criterion at `alpha`; `NA`
  when no count can.

- `critical_cvr`:

  The CVR of `critical_ne`.

- `pass`:

  Whether `ne` reaches `critical_ne`.

- `recommendation`:

  `"Supported"`, `"Review"`, `"Insufficient panel"` (no count could meet
  the test), or `"Insufficient data"` (no expert rated the item).

In congruence mode, with a target objective for each item:

- `item`:

  The item.

- `target`:

  The objective the item was written for.

- `n_judges`:

  Experts who rated the item on its target.

- `target_ioc`:

  The index of item-objective congruence for the target.

- `target_mean`:

  The experts' mean rating on the target, -1 to 1.

- `strongest_competitor`:

  The other objective with the highest mean rating, ties joined by
  `", "`.

- `competitor_mean`:

  The mean rating on that objective.

- `margin`:

  `target_mean - competitor_mean`, a description beside the index, not
  part of its criterion.

- `recommendation`:

  `"Congruent"` (`target_ioc` at or above `ioc_cut`), `"Review"`,
  `"Target described"` (the item was rated on its target alone, so there
  is no index), or `"Insufficient data"`.

Without a target objective, congruence `results` hold `item`,
`n_objectives` (objectives the item was rated on), `best_objective` and
`best_ioc` (the objective with the highest index, and that index), and
`recommendation`, which is `"Descriptive only"`.

## Earlier methods, for comparison

The decisions use Lynn's (1986) criterion in relevance mode (beyond the
ten experts her table covers, this package's extension holding her 7 of
9) and the exact binomial test (Ayre & Scally, 2014) in essentiality
mode. Earlier rules are reported beside them for teaching, and none
changes a decision:

- **Essentiality.** Lawshe's (1975) Table 1 gives a minimum CVR for 5 to
  15 panelists, then every fifth panel size to 40; other sizes have no
  minimum. He labeled it a one-tailed test at .05. Wilson et al. (2012)
  found the table closer to a two-tailed test and recomputed it by the
  normal approximation, `z / sqrt(N)` for a one-tailed test at `alpha`
  (their Table 2). An item meets Lawshe's minimum when its essential
  count reaches the count that minimum implies: 8 of 9 for his .78,
  which is .778 printed to two decimals (Ayre & Scally, 2014). Lawshe's
  content validity index for the whole set is the mean CVR of the items
  his table retains (Lawshe, 1975).

- **Relevance.** Fleiss' (1971) kappa, his kappa for many raters and
  nominal categories, on the relevant/not-relevant decision. It needs
  every expert to rate every item. The printout also notes that
  S-CVI/Ave is the average congruency percentage, for which Polit and
  Beck (2006) recommend .90 or higher, while calling .80 a reasonable,
  even strict, criterion for S-CVI/UA.

- **Relevance: the content validity coefficient (Ccv) of Hernández-Nieto
  (2002).** For each item, the mean rating divided by the scale maximum,
  minus \\(1/J)^J\\ for the \\J\\ judges who rated it; the total is the
  mean over items (Hernández-Nieto, 2002, pp. 130-137). The book calls a
  value below .80 unacceptable, .80 to .90 satisfactory, and .90 or
  higher excellent (p. 120). It is shown beside Aiken's V because it is
  widely cited, and it never informs a decision here, because of its
  shortcomings:

  - It uses only each item's mean rating, so it cannot reflect agreement
    among judges, although the book presents it as measuring agreement
    as well as validity (p. 157). The book's own Table 7 (pp. 148-149)
    gives ratings of 1, 3, 4, 5, 2 and of 3, 3, 3, 3, 3 the same .60.

  - The correction for chance, \\(1/J)^J\\, is derived by setting the
    probability that a judge gives a score at random to \\1/J\\, one
    over the number of judges (p. 136), so it depends on neither the
    ratings nor the number of scale points. It is .037 for three judges,
    .0039 for four, and .00032 for five, so it barely changes the value.

  - On a scale starting at 0, the book's preferred scale (pp. 119-120),
    Ccv before the correction equals Aiken's V. On a scale starting at 1
    it cannot fall below 1 divided by the scale maximum (the book notes
    .33 on a 1-3 scale, p. 160), so it does not reach 0 even when every
    judge gives the lowest rating. A scale starting below 0 has no Ccv.

  - The .80 and .90 bands come without derivation, a sampling
    distribution, or a test, and the book does not keep to them: its
    Example 11 labels .7968 acceptable (p. 155). The package applies the
    bands as stated on p. 120.

  - The book's tables mix .0032 and .00032 for the five-judge
    correction. The package uses the formula, \\(1/5)^5 = .00032\\,
    which reproduces the book's worked totals where they are consistent
    (for example, .33268 and .99968, pp. 146-148).

## References

Aiken, L. R. (1980). Content validity and reliability of single items or
questionnaires. *Educational and Psychological Measurement, 40*(4),
955–959.
[doi:10.1177/001316448004000419](https://doi.org/10.1177/001316448004000419)

Ayre, C., & Scally, A. J. (2014). Critical values for Lawshe's content
validity ratio: Revisiting the original methods of calculation.
*Measurement and Evaluation in Counseling and Development, 47*(1),
79–86.
[doi:10.1177/0748175613513808](https://doi.org/10.1177/0748175613513808)

Fleiss, J. L. (1971). Measuring nominal scale agreement among many
raters. *Psychological Bulletin, 76*(5), 378–382.
[doi:10.1037/h0031619](https://doi.org/10.1037/h0031619)

Hayes, A. F., & Krippendorff, K. (2007). Answering the call for a
standard reliability measure for coding data. *Communication Methods and
Measures, 1*(1), 77–89.
[doi:10.1080/19312450709336664](https://doi.org/10.1080/19312450709336664)

Hernández-Nieto, R. (2002). *Contributions to statistical analysis: The
coefficients of proportional variance, content validity and kappa*.
BookSurge.

Lawshe, C. H. (1975). A quantitative approach to content validity.
*Personnel Psychology, 28*(4), 563–575.
[doi:10.1111/j.1744-6570.1975.tb01393.x](https://doi.org/10.1111/j.1744-6570.1975.tb01393.x)

Lynn, M. R. (1986). Determination and quantification of content
validity. *Nursing Research, 35*(6), 382–385.
[doi:10.1097/00006199-198611000-00017](https://doi.org/10.1097/00006199-198611000-00017)

Penfield, R. D., & Giacobbi, P. R., Jr. (2004). Applying a score
confidence interval to Aiken's item content-relevance index.
*Measurement in Physical Education and Exercise Science, 8*(4), 213–225.
[doi:10.1207/s15327841mpee0804_3](https://doi.org/10.1207/s15327841mpee0804_3)

Polit, D. F., & Beck, C. T. (2006). The content validity index: Are you
sure you know what's being reported? Critique and recommendations.
*Research in Nursing & Health, 29*(5), 489–497.
[doi:10.1002/nur.20147](https://doi.org/10.1002/nur.20147)

Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an
acceptable indicator of content validity? Appraisal and recommendations.
*Research in Nursing & Health, 30*(4), 459–467.
[doi:10.1002/nur.20199](https://doi.org/10.1002/nur.20199)

Rovinelli, R. J., & Hambleton, R. K. (1977). On the use of content
specialists in the assessment of criterion-referenced test item
validity. *Dutch Journal of Educational Research, 2*, 49–60.

Turner, R. C., & Carlson, L. (2003). Indexes of item-objective
congruence for multidimensional items. *International Journal of
Testing, 3*(2), 163–171.
[doi:10.1207/S15327574IJT0302_5](https://doi.org/10.1207/S15327574IJT0302_5)

Wilson, F. R., Pan, W., & Schumsky, D. A. (2012). Recalculation of the
critical values for Lawshe's content validity ratio. *Measurement and
Evaluation in Counseling and Development, 45*(3), 197–210.
[doi:10.1177/0748175612440286](https://doi.org/10.1177/0748175612440286)

Zapf, A., Castell, S., Morawietz, L., & Karch, A. (2016). Measuring
inter-rater reliability for nominal data: Which coefficients and
confidence intervals are appropriate? *BMC Medical Research Methodology,
16*, Article 93.
[doi:10.1186/s12874-016-0200-9](https://doi.org/10.1186/s12874-016-0200-9)

## Examples

``` r
relevance <- matrix(
  c(4,4,4,3, 4,4,3,4, 3,4,4,4, 4,3,4,4),
  nrow = 4,
  dimnames = list(NULL, paste0("Item", 1:4))
)
fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4, seed = 1)
fit
#> <contentvalid_expert> Expert-panel analysis
#> Mode: relevance
#> Items: 4 | Experts per item: 4
#> Scale: 1 to 4 | Relevant: a rating of 3 or higher
#> Mean Aiken's V: .92 | S-CVI/Ave: 1.00 | S-CVI/UA: 1.00
#> Panel agreement, Krippendorff's alpha (ordinal): -.25; no 95% CI, because
#>   every resample of the items gave the same value. Identical rating pairs:
#>   50%.
#> 
#> 4 of 4 items meet the I-CVI criterion.
#> 
#>   Item   Decision        Experts    V      95% CI  I-CVI       95% CI  Kappa
#>   Item1  Strong support        4  .92  [.65, .99]   1.00  [.51, 1.00]   1.00
#>   Item2  Strong support        4  .92  [.65, .99]   1.00  [.51, 1.00]   1.00
#>   Item3  Strong support        4  .92  [.65, .99]   1.00  [.51, 1.00]   1.00
#>   Item4  Strong support        4  .92  [.65, .99]   1.00  [.51, 1.00]   1.00
#> 
#> Each 95% CI follows its estimate: Aiken's V has a Penfield-Giacobbi score
#> interval, and I-CVI the proportion interval named below.
#> I-CVI criterion for 4 experts: 4 agreeing (1.00), following Lynn (1986). Kappa
#> is modified kappa, read as excellent above .74 (Polit et al., 2007).
#> 95% intervals for proportions: Wilson score (the default). Newcombe (1998)
#> compared seven methods and recommends score intervals over the Wald interval.
#> An interval reflects how few ratings an item received, not whether the right
#> people rated it.
#> 
#> Panel agreement is one coefficient for the whole panel, whereas modified kappa
#> (the kappa column) describes each item. Alpha can be low when nearly every
#> rating is the same value, even on a panel that agrees closely, so read it
#> beside the share of identical rating pairs. A low alpha with many identical
#> pairs is not by itself evidence of a poor panel. Print x$details$agreement for
#> the full explanation and interval details.
#> 
#> CVI criteria are published panel-size guidelines, not universal validity
#> cutoffs.
#> 
#> What these columns mean
#>   S-CVI/Ave -- Scale-level CVI, averaging method. Mean of the items' I-CVIs;
#>       Polit and Beck (2006) recommend .90 or higher.
#>   S-CVI/UA -- Scale-level CVI, universal agreement. Share of items every
#>       expert rated relevant; it falls as experts are added.
#>   V -- Aiken's V. Mean relevance rating rescaled to run from 0 (lowest
#>       possible) to 1 (highest).
#>   I-CVI -- Item-level Content Validity Index. Share of experts rating the item
#>       relevant, against Lynn's criterion for the panel size (beyond ten, this
#>       package's).
#>   95% CI after I-CVI -- Interval for I-CVI. Wide because expert panels are
#>       small; the method is named above.
#>   Kappa -- Modified kappa. I-CVI corrected for chance agreement (at most 1;
#>       below 0 only when no expert, or one of three, rated it relevant).
#>   Panel agreement -- Panel-level agreement. One coefficient for the whole
#>       panel (1 is perfect, 0 is chance); it can be low when nearly every
#>       rating is the same.
#> 
#> What the decisions mean
#>   Strong support -- met the I-CVI criterion, which also puts modified kappa
#>       above .74.
#> 
#>   Full definitions: contentvalid_glossary(). To hide this key:
#>   options(contentvalidR.show_key = FALSE).
#> 
#> Use quantitative indices alongside expert comments, construct coverage, and
#> comprehensibility review.
#> 
#> See summary(x) for the flagged items and content_report(x) for an APA table.
summary(fit)
#> <contentvalid_expert summary> Expert-panel analysis
#> Mode: relevance
#> Scale: 1 to 4 | Relevant: a rating of 3 or higher
#> Strong support: 4 of 4 | Review: 0 of 4
#> I-CVI criterion for 4 experts: 4 agreeing (1.00), following Lynn (1986).
#> Panel agreement, Krippendorff's alpha (ordinal): -.25; no 95% CI, because
#>   every resample of the items gave the same value. Identical rating pairs:
#>   50%.
#> 
#> No items were flagged by the workflow's quantitative review rules.
#> 
#> These summaries support, but do not replace, qualitative content review.
#> 
#> See summary(x)$reviewed_items for the flagged items as a data frame.

# Essential counts from 12 experts, beside Lawshe's table and Wilson et al.
expert_validity(c(12, 10, 8, 6), mode = "essentiality", N = 12,
                legacy = TRUE)
#> <contentvalid_expert> Expert-panel analysis
#> Mode: essentiality
#> Items: 4 | Experts per item: 12
#> Method: Lawshe CVR with exact binomial critical values
#> 
#> 2 of 4 items meet the exact essentiality criterion.
#> Flagged for review: Item3, Item4
#> 
#>   Item   Decision   Essential   CVR       p
#>   Item1  Supported      12/12  1.00  < .001
#>   Item2  Supported      10/12   .67    .019
#>   Item3  Review          8/12   .33    .194
#>   Item4  Review          6/12   .00    .613
#> 
#> Essential: experts rating the item essential, out of those who rated it.
#> With 12 experts, an item needs at least 10 rating it essential for the exact
#> one-sided binomial test at alpha = .05 (Ayre & Scally, 2014).
#> 
#> Earlier methods, for comparison (not used for the decision)
#>   Item   Decision   Essential   CVR  Lawshe (1975)  Wilson et al. (2012)
#>   Item1  Supported      12/12  1.00  Meets          Meets
#>   Item2  Supported      10/12   .67  Meets          Meets
#>   Item3  Review          8/12   .33  Below          Below
#>   Item4  Review          6/12   .00  Below          Below
#> 
#>   Lawshe (1975, Table 1): minimum CVR .56 for 12 panelists (10 of 12), which
#>   he labeled a one-tailed test at .05. Wilson et al. (2012) found the table
#>   closer to a two-tailed test.
#>   Wilson et al. (2012, Table 2): minimum CVR .47, the normal approximation
#>   z/sqrt(N) at one-tailed alpha = .05.
#>   The decision above uses the exact binomial test (Ayre & Scally, 2014).
#>   Lawshe's content validity index, the mean CVR of the items his table
#>   retains: .83 (2 items).
#> 
#> What these columns mean
#>   CVR -- Lawshe's Content Validity Ratio. Lean of the panel toward calling the
#>       item essential (-1 to 1; above 0 means more than half did).
#> 
#> What the decisions mean
#>   Supported -- enough experts rated it essential to pass the exact test.
#>   Review -- too few experts rated it essential to pass the exact test.
#> 
#>   Full definitions: contentvalid_glossary(). To hide this key:
#>   options(contentvalidR.show_key = FALSE).
#> 
#> Use quantitative indices alongside expert comments, construct coverage, and
#> comprehensibility review.
#> 
#> See summary(x) for the flagged items and content_report(x) for an APA table.
```

# Analyze expert-panel content-validity evidence

Provides a user-facing workflow for three common expert-panel tasks:

- `mode = "relevance"`: bounded ordinal relevance ratings, combining
  Aiken's V (with Penfield-Giacobbi score intervals), CVI/modified
  kappa, and a panel-level agreement coefficient.

- `mode = "essentiality"`: Lawshe CVR with exact binomial critical
  values.

- `mode = "congruence"`: Rovinelli-Hambleton item-objective congruence.

Quantitative results are presented as evidence for item review rather
than as a substitute for expert comments, construct coverage,
comprehensibility, or other parts of a content-validity argument.

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
  or a vector of essential counts. For congruence, a long data frame
  accepted by
  [`ioc()`](https://juhalt.github.io/contentvalidR/reference/ioc.md).

- mode:

  One of `"relevance"`, `"essentiality"`, or `"congruence"`.

- lo, hi:

  Rating-scale bounds for relevance mode.

- relevance_cut:

  Lowest rating treated as relevant for CVI. Defaults to `hi - 1`, e.g.,
  3 on a 1-4 scale or 4 on a 1-5 scale.

- N:

  Panel size for essential-count vector input.

- alpha:

  Inferential/CI alpha level.

- na.rm:

  Permit itemwise/cellwise missing ratings where supported.

- target_col:

  In congruence mode, optional column identifying each item's intended
  objective. If absent, IOC cells are returned descriptively.

- proportion_ci:

  Interval method for I-CVI in relevance mode: `"wilson"` (default),
  `"agresti_coull"`, `"exact"`, or `"none"`. The interval uses the same
  `alpha` as Aiken's V. See `ci` in
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) for
  the methods and the evidence for each.

- agreement:

  Panel-level agreement coefficient for relevance mode: `"krippendorff"`
  (default), `"ac1"`, or `"none"`. Krippendorff's alpha uses the
  relevance ratings at `agreement_level`; Gwet's AC1 uses the
  relevant/not-relevant decision. See
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

  Optional seed that makes the agreement interval reproducible.

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
result.

## Earlier methods, for comparison

The decisions use Lynn's (1986) criterion in relevance mode and the
exact binomial test (Ayre & Scally, 2014) in essentiality mode. Earlier
rules are reported beside them for teaching, and none changes a
decision:

- **Essentiality.** Lawshe's (1975) Table 1 gives a minimum CVR for 5 to
  15 panelists, then every fifth panel size to 40; other sizes have no
  minimum. He labeled it a one-tailed test at .05. Wilson, Pan and
  Schumsky (2012) found the table closer to a two-tailed test and
  recomputed it by the normal approximation, `z / sqrt(N)` for a
  one-tailed test at `alpha` (their Table 2). Lawshe's content validity
  index for the whole set is the mean CVR of the items his table retains
  (Lawshe, 1975).

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

Penfield, R. D., & Giacobbi, P. R., Jr. (2004). Applying a score
confidence interval to Aiken's item content-relevance index.
*Measurement in Physical Education and Exercise Science, 8*(4), 213-225.
[doi:10.1207/s15327841mpee0804_3](https://doi.org/10.1207/s15327841mpee0804_3)

Ayre, C., & Scally, A. J. (2014). Critical values for Lawshe's content
validity ratio: Revisiting the original methods of calculation.
*Measurement and Evaluation in Counseling and Development, 47*(1),
79-86.
[doi:10.1177/0748175613513808](https://doi.org/10.1177/0748175613513808)

Lynn, M. R. (1986). Determination and quantification of content
validity. *Nursing Research, 35*(6), 382-385.
[doi:10.1097/00006199-198611000-00017](https://doi.org/10.1097/00006199-198611000-00017)

Polit, D. F., & Beck, C. T. (2006). The content validity index: Are you
sure you know what's being reported? Critique and recommendations.
*Research in Nursing & Health, 29*(5), 489-497.
[doi:10.1002/nur.20147](https://doi.org/10.1002/nur.20147)

Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an
acceptable indicator of content validity? *Research in Nursing & Health,
30*(4), 459-467.
[doi:10.1002/nur.20199](https://doi.org/10.1002/nur.20199)

Hayes, A. F., & Krippendorff, K. (2007). Answering the call for a
standard reliability measure for coding data. *Communication Methods and
Measures, 1*(1), 77-89.
[doi:10.1080/19312450709336664](https://doi.org/10.1080/19312450709336664)

Zapf, A., Castell, S., Morawietz, L., & Karch, A. (2016). Measuring
inter-rater reliability for nominal data: Which coefficients and
confidence intervals are appropriate? *BMC Medical Research Methodology,
16*, 93.
[doi:10.1186/s12874-016-0200-9](https://doi.org/10.1186/s12874-016-0200-9)

Lawshe, C. H. (1975). A quantitative approach to content validity.
*Personnel Psychology, 28*(4), 563-575.
[doi:10.1111/j.1744-6570.1975.tb01393.x](https://doi.org/10.1111/j.1744-6570.1975.tb01393.x)

Wilson, F. R., Pan, W., & Schumsky, D. A. (2012). Recalculation of the
critical values for Lawshe's content validity ratio. *Measurement and
Evaluation in Counseling and Development, 45*(3), 197-210.
[doi:10.1177/0748175612440286](https://doi.org/10.1177/0748175612440286)

Fleiss, J. L. (1971). Measuring nominal scale agreement among many
raters. *Psychological Bulletin, 76*(5), 378-382.
[doi:10.1037/h0031619](https://doi.org/10.1037/h0031619)

Hernández-Nieto, R. (2002). *Contributions to statistical analysis: The
coefficients of proportional variance, content validity and kappa.*
Universidad de Los Andes.

## Examples

``` r
relevance <- matrix(
  c(4,4,4,3, 4,4,3,4, 3,4,4,4, 4,3,4,4),
  nrow = 4,
  dimnames = list(NULL, paste0("Item", 1:4))
)
fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4, seed = 1)
fit
#> contentvalidR expert-panel analysis
#> -----------------------------------
#> Mode: relevance
#> Items: 4 | Experts/item: 4
#> Mean Aiken V: .92 | S-CVI/Ave: 1.00 | S-CVI/UA: 1.00
#> Strong support: 4 | Support: 0 | Review: 0
#> Panel agreement, Krippendorff's alpha (ordinal): -.25, 95% CI [-.25, -.25].
#>   Identical rating pairs: 50.0%.
#> 
#>   item       decision N   V     95% CI I-CVI      95% CI kappa
#>  Item1 Strong support 4 .92 [.65, .99]  1.00 [.51, 1.00]  1.00
#>  Item2 Strong support 4 .92 [.65, .99]  1.00 [.51, 1.00]  1.00
#>  Item3 Strong support 4 .92 [.65, .99]  1.00 [.51, 1.00]  1.00
#>  Item4 Strong support 4 .92 [.65, .99]  1.00 [.51, 1.00]  1.00
#> 
#> Each 95% CI follows its estimate: Aiken's V has a Penfield-Giacobbi score
#> interval, and I-CVI the proportion interval named below.
#> I-CVI criterion for 4 experts: 4 agreeing (1.00), following Lynn (1986);
#> kappa is modified kappa, with values above .74 read as excellent (Polit,
#> Beck, & Owen, 2007).
#> 95% intervals for proportions: Wilson score (the default). Newcombe (1998)
#> compared seven methods and recommends score intervals over the Wald interval.
#> An interval reflects how few ratings an item received, not whether the right
#> judges were chosen.
#> 
#> Panel agreement is one coefficient for the whole panel, whereas modified
#> kappa (the kappa column) describes each item. Alpha can be low when nearly
#> every rating is the same value, even on a panel that agrees closely, so read
#> it beside the share of identical rating pairs. A low alpha with many
#> identical pairs is not by itself evidence of a poor panel. Print
#> `details$agreement` for the full explanation and interval details.
#> 
#> CVI criteria are published panel-size guidelines, not universal validity
#> cutoffs.
#> 
#> What these columns mean
#>   V -- Aiken's V. Relevance index that rescales the experts' average rating
#>       to run from 0 to 1 given the bounds of the rating scale used. (0 to
#>       1; higher is stronger)
#>   I-CVI -- Item-level Content Validity Index. Proportion of experts who
#>       rated the item as relevant, after applying the relevance cut. (0 to
#>       1; compared against a panel-size guideline)
#>   95% CI after I-CVI -- Interval for I-CVI. Lower and upper limits of an
#>       interval around I-CVI. Expert panels are usually small, so these
#>       intervals are often wide: a single I-CVI value can look more settled
#>       than the number of experts behind it supports. (between 0 and 1; the
#>       method and level are named in the output)
#>   kappa -- Modified kappa. I-CVI adjusted for the chance that experts would
#>       have agreed even if rating at random. With small panels, chance
#>       agreement is substantial, which is why the raw I-CVI alone can
#>       overstate consensus. (0 to 1; higher is stronger)
#>   Panel agreement -- Panel-level agreement. One coefficient describing how
#>       consistently the whole panel rated the item set: Krippendorff's alpha
#>       by default, or Gwet's AC1 if chosen. It is separate from modified
#>       kappa, which describes one item at a time. (1 is perfect agreement
#>       and 0 is agreement no better than chance; it can be low on a
#>       close-agreeing panel whose ratings cluster on one value)
#> 
#> What the status labels mean
#>   Supported -- The evidence met the criteria set for this analysis.
#>   Review -- Something here needs a closer look. This is not an instruction
#>       to delete anything.
#>   Insufficient data -- Too little usable data to reach a judgment.
#>   Descriptive only -- Reported for description only; no decision rule was
#>       applied.
#>   Each workflow also uses its own wording in the decision column (Retain,
#>   Strong support, Typical, Covered, and so on). Those words map onto the
#>   shared statuses above.
#> 
#> See `contentvalid_glossary()` for all terms, or set
#> `options(contentvalidR.show_key = FALSE)` to hide this key.
#> 
#> Use quantitative indices alongside expert comments, construct coverage, and
#> comprehensibility review.
summary(fit)
#> Summary: expert-panel content-validity evidence
#> -----------------------------------------------
#> Mode: relevance
#> Supported: 4 | Review: 0
#> Panel agreement, Krippendorff's alpha (ordinal): -.25, 95% CI [-.25, -.25].
#>   Identical rating pairs: 50.0%.
#> 
#> No items were flagged by the workflow's quantitative review rules.
#> 
#> These summaries support, but do not replace, qualitative content review.

# Essential counts from 12 experts, beside Lawshe's table and Wilson et al.
expert_validity(c(12, 10, 8, 6), mode = "essentiality", N = 12,
                legacy = TRUE)
#> contentvalidR expert-panel analysis
#> -----------------------------------
#> Mode: essentiality
#> Items: 4 | Experts/item: 12
#> Method: Lawshe CVR with exact binomial critical values
#> 
#>   item  decision essential  CVR      p
#>  Item1 Supported     12/12 1.00 < .001
#>  Item2 Supported     10/12  .67   .019
#>  Item3    Review      8/12  .33   .194
#>  Item4    Review      6/12  .00   .613
#> 
#> essential: experts rating the item essential, out of those who rated it.
#> With 12 experts, an item needs at least 10 rating it essential for the exact
#> one-tailed binomial test at alpha = .05 (Ayre & Scally, 2014).
#> 
#> Earlier methods, for comparison (not used for the decision)
#>   item  decision essential  CVR Lawshe (1975) Wilson et al. (2012)
#>  Item1 Supported     12/12 1.00         meets                meets
#>  Item2 Supported     10/12  .67         meets                meets
#>  Item3    Review      8/12  .33         below                below
#>  Item4    Review      6/12  .00         below                below
#> 
#> Lawshe (1975, Table 1): minimum CVR .56 for 12 panelists, labeled a
#> one-tailed test at .05. Wilson, Pan and Schumsky (2012) found the table
#> closer to a two-tailed test.
#> Wilson et al. (2012, Table 2): minimum CVR .47, the normal approximation
#> z/sqrt(N) at one-tailed alpha = .05.
#> The decision above uses the exact binomial test (Ayre & Scally, 2014).
#> Lawshe's content validity index, the mean CVR of the items his table retains:
#> .83 (2 items).
#> 
#> What these columns mean
#>   CVR -- Lawshe's Content Validity Ratio. How far the panel leans toward
#>       calling the item essential rather than merely useful. (-1 to 1; above
#>       0 means more than half the panel called it essential)
#> 
#> What the status labels mean
#>   Supported -- The evidence met the criteria set for this analysis.
#>   Review -- Something here needs a closer look. This is not an instruction
#>       to delete anything.
#>   Insufficient data -- Too little usable data to reach a judgment.
#>   Descriptive only -- Reported for description only; no decision rule was
#>       applied.
#>   Each workflow also uses its own wording in the decision column (Retain,
#>   Strong support, Typical, Covered, and so on). Those words map onto the
#>   shared statuses above.
#> 
#> See `contentvalid_glossary()` for all terms, or set
#> `options(contentvalidR.show_key = FALSE)` to hide this key.
#> 
#> Use quantitative indices alongside expert comments, construct coverage, and
#> comprehensibility review.
```

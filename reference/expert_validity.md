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
  seed = NULL
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
#> Mean Aiken V: 0.917 | S-CVI/Ave: 1 | S-CVI/UA: 1 
#> Strong support: 4 | Support: 0 | Review: 0 
#> Panel agreement, Krippendorff's alpha (ordinal): -0.25 (95% interval -0.25
#>   to -0.25). Identical rating pairs: 50%
#> 
#>   item N     V ci_low ci_high I_CVI I_CVI_low I_CVI_high kappa_mod
#>  Item1 4 0.917  0.646   0.985     1      0.51          1         1
#>  Item2 4 0.917  0.646   0.985     1      0.51          1         1
#>  Item3 4 0.917  0.646   0.985     1      0.51          1         1
#>  Item4 4 0.917  0.646   0.985     1      0.51          1         1
#>  recommendation
#>  Strong support
#>  Strong support
#>  Strong support
#>  Strong support
#> 
#> ci_low and ci_high bound Aiken's V (Penfield-Giacobbi score interval);
#> I_CVI_low and I_CVI_high bound I-CVI.
#> 95% intervals for proportions: Wilson score (the default). Newcombe (1998)
#> compared seven methods and recommends score intervals over the Wald
#> interval. An interval reflects how few ratings an item received, not
#> whether the right judges were chosen.
#> 
#> Panel agreement is one coefficient for the whole panel, whereas kappa_mod
#> describes each item. Alpha can be low when nearly every rating is the same
#> value, even on a panel that agrees closely, so read it beside the share of
#> identical rating pairs. A low alpha with many identical pairs is not by
#> itself evidence of a poor panel. Print `details$agreement` for the full
#> explanation and interval details.
#> 
#> CVI thresholds shown by the workflow are common panel-size guidelines, not universal validity cutoffs.
#> 
#> What these columns mean
#>   V -- Aiken's V. Relevance index that rescales the experts' average rating
#>       to run from 0 to 1 given the bounds of the rating scale used. (0 to
#>       1; higher is stronger)
#>   I_CVI -- Item-level Content Validity Index. Proportion of experts who
#>       rated the item as relevant, after applying the relevance cut. (0 to
#>       1; compared against a panel-size guideline)
#>   I_CVI_low/I_CVI_high -- Interval for I-CVI. Lower and upper limits of an
#>       interval around I-CVI. Expert panels are usually small, so these
#>       intervals are often wide: a single I-CVI value can look more settled
#>       than the number of experts behind it supports. (between 0 and 1; the
#>       method and level are named in the output)
#>   kappa_mod -- Modified kappa. I-CVI adjusted for the chance that experts
#>       would have agreed even if rating at random. With small panels, chance
#>       agreement is substantial, which is why the raw I-CVI alone can
#>       overstate consensus. (0 to 1; higher is stronger)
#>   agreement -- Panel-level agreement. One coefficient describing how
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
#>   Each workflow also uses its own wording in the recommendation column
#>   (Retain, Strong support, Typical, Covered, and so on). Those words map
#>   onto the shared statuses above.
#> 
#> See `contentvalid_glossary()` for all terms, or set 
#> `options(contentvalidR.show_key = FALSE)` to hide this key.
#> 
#> Use quantitative indices alongside expert comments, construct coverage, and comprehensibility review.
summary(fit)
#> Summary of expert-panel content-validity evidence
#> ---------------------------------------------
#> Mode: relevance 
#> Supported: 4 | Review: 0
#> Panel agreement, Krippendorff's alpha (ordinal): -0.25 (95% interval -0.25
#>   to -0.25). Identical rating pairs: 50%
#> No items were flagged by the workflow's quantitative review rules.
#> 
#> These summaries support, but do not replace, qualitative content review.
```

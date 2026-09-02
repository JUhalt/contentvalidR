# Analyze expert-panel content-validity evidence

Provides a user-facing workflow for three common expert-panel tasks:

- `mode = "relevance"`: bounded ordinal relevance ratings, combining
  Aiken's V (with Penfield-Giacobbi score intervals) and CVI/modified
  kappa.

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
  target_col = "target_objective"
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

## Value

An object of class `contentvalid_expert` and `contentvalid_workflow`.
All flagship workflow objects expose the common components `results`,
`scale_summary`, `settings`, `design`, and `details`. The historical
top-level `scale` component is retained as a compatibility alias for
`scale_summary`. Results include a standardized `status` field while
retaining mode-specific `recommendation` wording.

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

Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an
acceptable indicator of content validity? *Research in Nursing & Health,
30*(4), 459-467.
[doi:10.1002/nur.20199](https://doi.org/10.1002/nur.20199)

## Examples

``` r
relevance <- matrix(
  c(4,4,4,3, 4,4,3,4, 3,4,4,4, 4,3,4,4),
  nrow = 4,
  dimnames = list(NULL, paste0("Item", 1:4))
)
fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4)
fit
#> contentvalidR expert-panel analysis
#> -----------------------------------
#> Mode: relevance 
#> Items: 4 | Experts/item: 4 
#> Mean Aiken V: 0.917 | S-CVI/Ave: 1 | S-CVI/UA: 1 
#> Strong support: 4 | Support: 0 | Review: 0 
#> 
#>   item N     V ci_low ci_high I_CVI kappa_mod recommendation
#>  Item1 4 0.917  0.646   0.985     1         1 Strong support
#>  Item2 4 0.917  0.646   0.985     1         1 Strong support
#>  Item3 4 0.917  0.646   0.985     1         1 Strong support
#>  Item4 4 0.917  0.646   0.985     1         1 Strong support
#> 
#> CVI thresholds shown by the workflow are common panel-size guidelines, not universal validity cutoffs.
#> 
#> Use quantitative indices alongside expert comments, construct coverage, and comprehensibility review.
summary(fit)
#> Summary of expert-panel content-validity evidence
#> ---------------------------------------------
#> Mode: relevance 
#> Supported: 4 | Review: 0
#> No items were flagged by the workflow's quantitative review rules.
#> 
#> These summaries support, but do not replace, qualitative content review.
```

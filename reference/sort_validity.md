# Analyze an item-sort content-validity pretest

Provides the recommended user-facing workflow for item-sort studies. At
the item level, `sort_validity()` combines Anderson and Gerbing's (1991)
Psa and Csv statistics with the exact target-count significance test
recommended by Howard and Melloy (2016). Items meeting the exact
criterion are labeled `"Retain"`; items that do not meet it are labeled
`"Review"`, not automatically `"Delete"`.

At the target-scale level, Psa and Csv are averaged across items and
interpreted using the empirical percentile norms from Colquitt et al.
(2019). This mirrors how those norms were constructed. The Colquitt
categories are descriptive benchmarks rather than pass/fail rules.

## Usage

``` r
sort_validity(
  assignments,
  item_col = "item",
  rater_col = "rater",
  assigned_col = "assigned_construct",
  target_col = "target_construct",
  p0 = 0.5,
  alpha = 0.05,
  orbiting_r = NULL,
  judge_type = c("naive", "expert")
)
```

## Arguments

- assignments:

  A data.frame containing item-sort responses.

- item_col, rater_col, assigned_col, target_col:

  Column names for the item, rater, assigned construct, and intended
  target construct.

- p0:

  Null target-assignment probability for the exact binomial test.
  Default `0.5`, following Howard and Melloy (2016).

- alpha:

  Significance level. Default `0.05`.

- orbiting_r:

  Optional average correlation between each focal/target scale and its
  orbiting scales. For one target, supply one correlation. For multiple
  targets, supply a named numeric vector keyed by target construct. If
  omitted, the overall Colquitt et al. norms are used.

- judge_type:

  Either `"naive"` (the Anderson-Gerbing/Colquitt design) or `"expert"`.
  Colquitt benchmark labels are not applied to expert judges.

## Value

An object of class `contentvalid_sort` and `contentvalid_workflow`. All
flagship workflow objects expose the common components `results`,
`scale_summary`, `settings`, `design`, and `details`. Item-level
`results` include a standardized `status` field while retaining the
method-specific `recommendation` field.
[`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html), and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) provide
user-facing interpretation.

## References

Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
measures in a confirmatory factor analysis with a pretest assessment of
their substantive validities. *Journal of Applied Psychology, 76*(5),
732-740.
[doi:10.1037/0021-9010.76.5.732](https://doi.org/10.1037/0021-9010.76.5.732)

Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task
methods: The presentation of a new statistical significance formula and
methodological best practices. *Journal of Business and Psychology,
31*(1), 173-186.
[doi:10.1007/s10869-015-9404-y](https://doi.org/10.1007/s10869-015-9404-y)

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243-1265.
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406)

## Examples

``` r
sort_dat <- data.frame(
  item = rep(c("A1", "A2", "A3"), each = 20),
  rater = rep(1:20, 3),
  target_construct = "A",
  assigned_construct = c(
    rep("A", 18), rep("B", 2),
    rep("A", 16), rep("B", 4),
    rep("A", 12), rep("B", 8)
  )
)
fit <- sort_validity(sort_dat)
fit
#> contentvalidR item-sort analysis
#> --------------------------------
#> Items: 3 | Raters: 20 | Target scales: 1 
#> Item inference: Howard-Melloy exact target-count test (p0 = 0.50, alpha = 0.050) 
#> Judges: naive 
#> 
#> 2 item(s) meet the exact target-assignment criterion; 1 item(s) are flagged for review.
#> Review: A3 
#> 
#> Item-level evidence:
#>  item target  n n_target competitor psa csv p_value recommendation
#>    A1      A 20       18          B 0.9 0.8   0.000         Retain
#>    A2      A 20       16          B 0.8 0.6   0.006         Retain
#>    A3      A 20       12          B 0.6 0.2   0.252         Review
#> 
#> Scale-level Colquitt benchmark summary:
#>  target n_items mean_psa psa_strength mean_csv csv_strength
#>       A       3    0.767     Moderate    0.533     Moderate
#>                     benchmark_set
#>  Overall (not correlation-normed)
#> 
#> Colquitt labels are empirical percentile norms derived from scale-level averages,
#> not universal cutoffs or automatic scale-retention rules.
#> 'Review' is not an automatic deletion decision. Use theory, construct-domain coverage,
#> item wording, and qualitative judge feedback alongside these statistics.
summary(fit)
#> Summary of item-sort content-validity evidence
#> -------------------------------------------
#> Retain: 2 of 3 item(s)
#> Review: 1 of 3 item(s)
#> 
#> Target-scale evidence:
#>  target n_items n_retain n_review mean_psa psa_strength mean_csv csv_strength
#>       A       3        2        1    0.767     Moderate    0.533     Moderate
#>  overall_strength
#>          Moderate
#> 
#> A: Generally supportive normative standing, with at least one dimension in the moderate range; review weaker items before finalizing.
#> 
#> Items needing attention:
#>  item target competitor psa csv p_value                                   issue
#>    A3      A          B 0.6 0.2   0.252 Target favored, exact criterion not met
#>  recommendation
#>          Review
#> 
#> Interpret scale norms and item flags alongside theory, domain coverage, and qualitative feedback.
#> This analysis does not by itself establish comprehensiveness or the full content-validity argument.
```

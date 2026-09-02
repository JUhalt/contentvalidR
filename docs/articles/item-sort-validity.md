# Item-Sort Content Validation: Anderson-Gerbing to Howard-Melloy to Colquitt

## What this workflow answers

Item-sort pretests ask judges to assign candidate items to construct
definitions. The workflow provides two related kinds of evidence:

1.  **Definitional correspondence**: are items assigned to their
    intended construct?
2.  **Definitional distinctiveness**: are items assigned to the intended
    construct more often than to a competing construct?

Anderson and Gerbing (1991) operationalized these ideas with **Psa** and
**Csv**. Howard and Melloy (2016) clarified exact inference for the
target-assignment count, particularly when more than two assignment
alternatives are present. Colquitt et al. (2019) later supplied
empirical interpretation norms based on 112 published scales.

These statistics do not establish the entire content-validity argument.
In particular, they do not establish that the item pool comprehensively
covers the construct domain.

## A reproducible example

``` r

sort_dat <- data.frame(
  item = rep(c("A1", "A2", "A3", "B1", "B2", "B3"), each = 20),
  rater = rep(1:20, 6),
  target_construct = rep(c("A", "A", "A", "B", "B", "B"), each = 20),
  assigned_construct = c(
    rep("A", 18), rep("B", 2),
    rep("A", 16), rep("B", 4),
    rep("A", 13), rep("B", 7),
    rep("B", 18), rep("A", 2),
    rep("B", 17), rep("A", 3),
    rep("B", 14), rep("A", 6)
  )
)

fit <- sort_validity(sort_dat)
fit
#> contentvalidR item-sort analysis
#> --------------------------------
#> Items: 6 | Raters: 20 | Target scales: 2 
#> Item inference: Howard-Melloy exact target-count test (p0 = 0.50, alpha = 0.050) 
#> Judges: naive 
#> 
#> 4 item(s) meet the exact target-assignment criterion; 2 item(s) are flagged for review.
#> Review: A3, B3 
#> 
#> Item-level evidence:
#>  item target  n n_target competitor  psa csv p_value recommendation
#>    A1      A 20       18          B 0.90 0.8   0.000         Retain
#>    A2      A 20       16          B 0.80 0.6   0.006         Retain
#>    A3      A 20       13          B 0.65 0.3   0.132         Review
#>    B1      B 20       18          A 0.90 0.8   0.000         Retain
#>    B2      B 20       17          A 0.85 0.7   0.001         Retain
#>    B3      B 20       14          A 0.70 0.4   0.058         Review
#> 
#> Scale-level Colquitt benchmark summary:
#>  target n_items mean_psa psa_strength mean_csv csv_strength
#>       A       3    0.783     Moderate    0.567     Moderate
#>       B       3    0.817     Moderate    0.633       Strong
#>                     benchmark_set
#>  Overall (not correlation-normed)
#>  Overall (not correlation-normed)
#> 
#> Colquitt labels are empirical percentile norms derived from scale-level averages,
#> not universal cutoffs or automatic scale-retention rules.
#> 'Review' is not an automatic deletion decision. Use theory, construct-domain coverage,
#> item wording, and qualitative judge feedback alongside these statistics.
```

The item table is intentionally diagnostic rather than merely numeric. A
`Review` flag is not a command to delete an item. The output reports the
strongest competing construct so that researchers can distinguish weak
target correspondence from specific construct overlap.

``` r

summary(fit)
#> Summary of item-sort content-validity evidence
#> -------------------------------------------
#> Retain: 4 of 6 item(s)
#> Review: 2 of 6 item(s)
#> 
#> Target-scale evidence:
#>  target n_items n_retain n_review mean_psa psa_strength mean_csv csv_strength
#>       A       3        2        1    0.783     Moderate    0.567     Moderate
#>       B       3        2        1    0.817     Moderate    0.633       Strong
#>  overall_strength
#>          Moderate
#>          Moderate
#> 
#> A: Generally supportive normative standing, with at least one dimension in the moderate range; review weaker items before finalizing.
#> B: Generally supportive normative standing, with at least one dimension in the moderate range; review weaker items before finalizing.
#> 
#> Items needing attention:
#>  item target competitor  psa csv p_value
#>    A3      A          B 0.65 0.3   0.132
#>    B3      B          A 0.70 0.4   0.058
#>                                    issue recommendation
#>  Target favored, exact criterion not met         Review
#>  Target favored, exact criterion not met         Review
#> 
#> Interpret scale norms and item flags alongside theory, domain coverage, and qualitative feedback.
#> This analysis does not by itself establish comprehensiveness or the full content-validity argument.
```

## Item-level inference: Howard-Melloy

The default exact test asks whether the target-assignment probability
exceeds `.50`. At `N = 20` and `alpha = .05`, an item needs 15 target
assignments to meet the one-sided exact criterion.

``` r

csv_binom_test(n_c = 15, N = 20)
#> $p.value
#> [1] 0.02069473
#> 
#> $estimate
#> [1] 0.75
#> 
#> $conf.int
#> [1] 0.5444176 1.0000000
#> attr(,"conf.level")
#> [1] 0.95
#> 
#> $critical_n_target
#> [1] 15
#> 
#> $passes_chance
#> [1] TRUE
#> 
#> $decision
#> [1] "significant"
#> 
#> $interpretation
#> [1] "Target assignments exceed the exact chance criterion."
csv_binom_test(n_c = 14, N = 20)
#> $p.value
#> [1] 0.05765915
#> 
#> $estimate
#> [1] 0.7
#> 
#> $conf.int
#> [1] 0.4921816 1.0000000
#> attr(,"conf.level")
#> [1] 0.95
#> 
#> $critical_n_target
#> [1] 15
#> 
#> $passes_chance
#> [1] FALSE
#> 
#> $decision
#> [1] "n.s."
#> 
#> $interpretation
#> [1] "Target assignments do not exceed the exact chance criterion."
```

[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
therefore uses **Retain** to mean “meets this exact statistical
screening criterion” and **Review** to mean “does not meet it.” Revision
or removal remains a substantive decision.

## Scale-level interpretation: Colquitt et al. (2019)

Colquitt et al. did not create their interpretation bands from
individual item values. They averaged Psa and Csv across the items in
each of 112 scales and then created empirical percentile bands.
[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
follows that design: Howard-Melloy is used item by item, while Colquitt
interpretation is reported for each target scale’s mean Psa and mean
Csv.

The default uses the overall norms:

``` r

colquitt_benchmarks("psa")
#>   statistic benchmark_set                  benchmark_label interpretation
#> 1       psa       overall Overall (not correlation-normed)    Very Strong
#> 2       psa       overall Overall (not correlation-normed)         Strong
#> 3       psa       overall Overall (not correlation-normed)       Moderate
#> 4       psa       overall Overall (not correlation-normed)           Weak
#> 5       psa       overall Overall (not correlation-normed)        Lack of
#>   percentile minimum
#> 1  80th-99th    0.91
#> 2  60th-79th    0.82
#> 3  40th-59th    0.72
#> 4  20th-39th    0.39
#> 5   0th-19th    -Inf
colquitt_benchmarks("csv")
#>   statistic benchmark_set                  benchmark_label interpretation
#> 1       csv       overall Overall (not correlation-normed)    Very Strong
#> 2       csv       overall Overall (not correlation-normed)         Strong
#> 3       csv       overall Overall (not correlation-normed)       Moderate
#> 4       csv       overall Overall (not correlation-normed)           Weak
#> 5       csv       overall Overall (not correlation-normed)        Lack of
#>   percentile minimum
#> 1  80th-99th    0.81
#> 2  60th-79th    0.61
#> 3  40th-59th    0.51
#> 4  20th-39th    0.05
#> 5   0th-19th    -Inf
```

The labels—Very Strong, Strong, Moderate, Weak, and Lack of—are
empirical normative standing, **not universal validity cutoffs**.

### Correlation-conditional norms

Colquitt et al. showed that Psa/Csv depend partly on how similar the
focal scale is to its orbiting scales. If substantive data provide an
average focal-orbiting correlation, supply it to the workflow. With
multiple focal scales, use a named vector.

``` r

fit_normed <- sort_validity(
  sort_dat,
  orbiting_r = c(A = .42, B = .28)
)
fit_normed$scale_summary
#>   target n_items n_items_usable n_retain n_review  mean_psa psa_strength
#> 1      A       3              3        2        1 0.7833333     Moderate
#> 2      B       3              3        2        1 0.8166667         Weak
#>    mean_csv csv_strength orbiting_r
#> 1 0.5666667     Moderate       0.42
#> 2 0.6333333         Weak       0.28
#>                                        benchmark_set benchmark_applicable
#> 1 More moderate focal-orbiting correlation (.35-.50)                 TRUE
#> 2       Weaker focal-orbiting correlation (r <= .34)                 TRUE
#>   overall_strength
#> 1         Moderate
#> 2             Weak
#>                                                                                                                                evidence
#> 1    Generally supportive normative standing, with at least one dimension in the moderate range; review weaker items before finalizing.
#> 2 Limited normative standing on at least one dimension; review item wording and construct overlap and consider re-pretesting revisions.
```

The conditional panels are:

- `.34` or below: weaker focal-orbiting correlation;
- `.35` to `.50`: more moderate correlation;
- `.51` or above: stronger correlation.

A given Csv can be more impressive when the focal and orbiting
constructs are closely related, so the appropriate norm can change the
descriptive category.

## Judge type matters

Anderson and Gerbing advocated naïve judges representative of the
population of interest, and Colquitt et al.’s norms were generated with
that kind of judge. Their criteria should not simply be transferred to
expert panels.

``` r

expert_fit <- sort_validity(sort_dat, judge_type = "expert")
expert_fit$scale_summary
#>   target n_items n_items_usable n_retain n_review  mean_psa psa_strength
#> 1      A       3              3        2        1 0.7833333         <NA>
#> 2      B       3              3        2        1 0.8166667         <NA>
#>    mean_csv csv_strength orbiting_r                    benchmark_set
#> 1 0.5666667         <NA>         NA Overall (not correlation-normed)
#> 2 0.6333333         <NA>         NA Overall (not correlation-normed)
#>   benchmark_applicable overall_strength
#> 1                FALSE             <NA>
#> 2                FALSE             <NA>
#>                                                                              evidence
#> 1 Colquitt norms not applied because this workflow was marked as using expert judges.
#> 2 Colquitt norms not applied because this workflow was marked as using expert judges.
```

The Psa/Csv statistics and item-level screening remain available, but
Colquitt normative labels are suppressed.

## Planning judge sample size

Use
[`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md)
to calculate the exact probability that an item will reach the required
target-assignment count under a plausible true target-assignment
probability.

``` r

sort_power(N = c(20, 30, 40), true_p = c(.60, .70, .80))
#> Exact item-sort planning analysis
#> ---------------------------------
#> Retention rule: p0 = 0.50, alpha = 0.050
#> 
#>   N true_p critical_n_target minimum_observed_psa power
#>  20    0.6                15                0.750 0.126
#>  30    0.6                20                0.667 0.291
#>  40    0.6                26                0.650 0.317
#>  20    0.7                15                0.750 0.416
#>  30    0.7                20                0.667 0.730
#>  40    0.7                26                0.650 0.807
#>  20    0.8                15                0.750 0.804
#>  30    0.8                20                0.667 0.974
#>  40    0.8                26                0.650 0.992
#> 
#> Power is the exact probability of reaching the required target-assignment count
#> under the assumed true target-assignment probability.
```

This is preferable to treating a rule such as “20-40 judges” as a
universal sample-size requirement. Power depends on the assumed
target-assignment probability, `N`, the null probability, and alpha.

## Plotting item evidence

The one-index views remain available:

``` r

plot(fit, metric = "psa")
```

![](item-sort-validity_files/figure-html/unnamed-chunk-8-1.png)

``` r

plot(fit, metric = "csv")
```

![](item-sort-validity_files/figure-html/unnamed-chunk-8-2.png)

For diagnosis, the package also introduces a
**correspondence-distinctiveness evidence map**:

``` r

plot(fit, type = "map")
```

![](item-sort-validity_files/figure-html/unnamed-chunk-9-1.png)

Psa and Csv are shown jointly, review items are labeled by default, and
target- scale averages are added as diamonds. This makes it easier to
distinguish a correspondence problem (low Psa) from a construct-overlap
problem (low or negative Csv). The map does not draw Colquitt cutoff
regions across individual items because those empirical norms were
constructed from scale-level averages.

The exact planning object is also plotable:

``` r

plan <- sort_power(N = seq(10, 50, by = 5), true_p = c(.60, .70, .80))
plot(plan)
```

![](item-sort-validity_files/figure-html/unnamed-chunk-10-1.png)

``` r

plot(plan, type = "critical")
```

![](item-sort-validity_files/figure-html/unnamed-chunk-10-2.png)

No conventional target-power line is imposed unless the analyst supplies
one.

## Why the Anderson-Gerbing legacy critical-Csv rule is not exposed

`contentvalidR` retains Anderson and Gerbing’s Psa and Csv indices but
does not provide their legacy critical-Csv decision rule as a
user-selectable alternative. Howard and Melloy (2016) showed that the
older rule is appropriate for the original two-choice case but becomes
miscalibrated when it is applied to sorts with more than two construct
choices. Their revised target-count procedure agrees with the legacy
logic in the two-choice case and is applicable to the broader designs
now used in practice. Exposing the obsolete rule would therefore add a
reproducibility option that is easy to misuse without adding a
recommended analysis path.

## Reporting

A useful report should include:

- who the judges were and why they fit the intended design;
- the focal and orbiting constructs and their definitions;
- the number of judges and missing assignments;
- item-level Psa, Csv, target counts, strongest competitors, and exact
  decisions;
- target-scale mean Psa/Csv and the Colquitt norm set used;
- focal-orbiting correlations if conditional norms were used; and
- the substantive reasoning behind any revisions or removals.

## References

Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
measures in a confirmatory factor analysis with a pretest assessment of
their substantive validities. *Journal of Applied Psychology, 76*(5),
732-740. <https://doi.org/10.1037/0021-9010.76.5.732>

Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task
methods: The presentation of a new statistical significance formula and
methodological best practices. *Journal of Business and Psychology,
31*(1), 173-186. <https://doi.org/10.1007/s10869-015-9404-y>

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243-1265. <https://doi.org/10.1037/apl0000406>

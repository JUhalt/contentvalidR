# Analyze a Hinkin-Tracey construct-rating content-validity pretest

Provides the recommended user-facing workflow for a fully crossed
construct-rating study. Judges rate each item against its intended
construct definition and one or more orbiting definitions.
`rating_validity()` combines:

- Hinkin-Tracey correspondence (HTC),

- Hinkin-Tracey distinctiveness (HTD),

- one-way repeated-measures ANOVA (with Greenhouse-Geisser correction)
  for each item, and

- planned paired target-versus-orbiting contrasts.

Item-level output is diagnostic rather than a coefficient dump: it
identifies the strongest competing construct, describes why an item was
flagged, and labels statistical screening decisions `"Retain"`,
`"Review"`, or `"Insufficient data"`. `"Review"` is not an instruction
to delete the item.

Colquitt et al. (2019) norms are applied only to **target-scale
averages** of HTC and HTD, matching the level at which those empirical
benchmarks were constructed. The labels are suppressed for expert
judges.

## Usage

``` r
rating_validity(
  ratings,
  item_col = "item",
  rater_col = "rater",
  construct_col = "construct",
  rating_col = "rating",
  target_map = NULL,
  target_col = "target_construct",
  scale_min = 1,
  scale_max = 5,
  alpha = 0.05,
  adjust = c("none", "holm"),
  orbiting_r = NULL,
  judge_type = c("naive", "expert")
)
```

## Arguments

- ratings:

  Long-format rating data.

- item_col, rater_col, construct_col, rating_col:

  Column names.

- target_map:

  Optional named item-to-target mapping.

- target_col:

  Target column used when `target_map` is `NULL`.

- scale_min, scale_max:

  Endpoints of the equally spaced integer rating scale.

- alpha:

  Significance level for item-level inferential screening.

- adjust:

  Planned-contrast p-value adjustment: `"none"` (historical
  planned-comparison logic) or `"holm"`.

- orbiting_r:

  Optional average focal-orbiting correlation. For multiple target
  scales, use a named numeric vector keyed by target.

- judge_type:

  Either `"naive"` or `"expert"`. Colquitt normative labels are not
  applied to expert-judge data.

## Value

An object of class `contentvalid_rating` and `contentvalid_workflow`.
All flagship workflow objects expose the common components `results`,
`scale_summary`, `settings`, `design`, and `details`. Planned contrasts
live in `details$contrasts`; the historical top-level `contrasts`
component is retained as a compatibility alias. Item-level `results`
include a standardized `status` field while retaining the
method-specific `recommendation` field.

## References

Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach
to content validation. *Organizational Research Methods, 2*(2), 175-186.
[doi:10.1177/109442819922004](https://doi.org/10.1177/109442819922004)

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243-1265.
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406)

## Examples

``` r
set.seed(12)
d <- expand.grid(item = c("A1", "A2", "B1"), rater = 1:20,
                 construct = c("A", "B", "C"))
d$target_construct <- ifelse(d$item == "B1", "B", "A")
d$rating <- ifelse(d$construct == d$target_construct,
                   pmin(5, pmax(1, round(rnorm(nrow(d), 4.5, .6)))),
                   pmin(5, pmax(1, round(rnorm(nrow(d), 2.0, .7)))))
fit <- rating_validity(d, scale_min = 1, scale_max = 5)
fit
#> contentvalidR construct-rating analysis
#> ---------------------------------------
#> Items: 3 | Raters: 20 | Target scales: 2 | Constructs: 3 
#> Design: within-judge ratings | Scale: 1 to 5 
#> Item inference: one-way repeated-measures ANOVA (Greenhouse-Geisser corrected omnibus p) plus planned paired target-versus-orbiting contrasts 
#> Planned-contrast adjustment: none 
#> Judges: naive 
#> 
#> 3 item(s) meet the full item-level screening criterion; 0 item(s) are flagged for review.
#> 
#> Item-level evidence:
#>  item target n_complete strongest_competitor  htc   htd p_value max_contrast_p
#>    A1      A         20                    B 0.89 0.650       0              0
#>    A2      A         20                    B 0.88 0.600       0              0
#>    B1      B         20                    C 0.93 0.694       0              0
#>  recommendation
#>          Retain
#>          Retain
#>          Retain
#> 
#> Target-scale Colquitt benchmark summary:
#>  target n_items n_htc n_htd mean_htc htc_strength mean_htd htd_strength
#>       A       2     2     2    0.885       Strong    0.625  Very Strong
#>       B       1     1     1    0.930  Very Strong    0.694  Very Strong
#>  benchmark_set
#>        overall
#>        overall
#> 
#> Colquitt labels are empirical percentile norms for scale-level HTC/HTD averages, not universal cutoffs.
#> 'Review' is not an automatic deletion decision. Consider construct definitions, item wording,
#> orbiting-construct choice, domain coverage, and qualitative judge feedback.
summary(fit)
#> Summary of construct-rating content-validity evidence
#> ---------------------------------------------------
#> Retain: 3 of 3 item(s)
#> Review: 0 of 3 item(s)
#> 
#> Target-scale evidence:
#>  target n_items n_htc n_htd n_retain n_review mean_htc htc_strength mean_htd
#>       A       2     2     2        2        0    0.885       Strong    0.625
#>       B       1     1     1        1        0    0.930  Very Strong    0.694
#>  htd_strength overall_strength
#>   Very Strong           Strong
#>   Very Strong      Very Strong
#> 
#> A: Strong normative standing on the weaker of definitional correspondence (HTC) and distinctiveness (HTD).
#> B: Very Strong normative standing on the weaker of definitional correspondence (HTC) and distinctiveness (HTD).
#> 
#> All analyzed items met the item-level inferential screening criterion.
#> 
#> Interpret these results alongside theory, domain coverage, and qualitative feedback.
#> The analysis does not by itself establish comprehensiveness or the full content-validity argument.
```

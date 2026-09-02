# Hinkin-Tracey ANOVA content test

For each item, evaluates whether definitional-correspondence ratings
differ across construct definitions and whether the intended construct
is rated higher than every orbiting construct.

The Hinkin and Tracey (1999) rating task is ordinarily a
**within-judge** design: the same judge rates an item against multiple
construct definitions. For that design, `anova_content()` uses a one-way
repeated-measures ANOVA on judges with complete ratings for the item's
construct set, followed by one-sided paired planned contrasts of the
target against each orbiting construct. A between-judge path is retained
for genuinely independent rating designs, but it is not the recommended
Hinkin-Tracey protocol.

The repeated-measures output includes the conventional omnibus F/p and a
Greenhouse-Geisser epsilon/corrected p-value. With more than two
construct definitions, the corrected p-value is the safer default for
omnibus screening when sphericity may not hold. Planned
target-versus-orbiting contrasts provide the more direct item-level
evidence.

## Usage

``` r
anova_content(
  ratings,
  item_col = "item",
  rater_col = "rater",
  construct_col = "construct",
  rating_col = "rating",
  target_map = NULL,
  posthoc = NULL,
  alpha = 0.05,
  target_col = "target_construct",
  design = c("auto", "within", "between"),
  adjust = c("none", "holm")
)
```

## Arguments

- ratings:

  A long-format data.frame with item, rater, construct, and numeric
  rating columns.

- item_col, rater_col, construct_col, rating_col:

  Column names.

- target_map:

  Optional named character vector/list mapping item to target. If
  neither a map nor `target_col` is available, omnibus tests are still
  returned but target-versus-orbiting contrasts are `NA`.

- posthoc:

  Deprecated compatibility argument. Tukey/Duncan post-hoc testing is no
  longer used because the Hinkin-Tracey question is directly represented
  by planned target-versus-orbiting contrasts.

- alpha:

  Significance level for the omnibus test and planned contrasts.

- target_col:

  Target column used when `target_map` is `NULL`.

- design:

  One of `"auto"`, `"within"`, or `"between"`. `"auto"` identifies the
  design itemwise from whether judges provide ratings for multiple
  construct definitions.

- adjust:

  Multiplicity adjustment for the target-versus-orbiting planned
  contrast p values. Default `"none"` reproduces the planned-comparison
  logic commonly used with the Hinkin-Tracey procedure; `"holm"` is a
  conservative option.

## Value

A data.frame with one row per item, including the omnibus F, raw p,
Greenhouse-Geisser epsilon/corrected degrees of freedom and p-value for
within-judge designs, partial eta-squared, and planned-contrast
diagnostics. The full planned-contrast table is stored in
`attr(result, "contrasts")`. `posthoc_pass` is retained as an alias of
`contrast_pass` for backward compatibility.

## References

Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach
to content validation. *Organizational Research Methods, 2*(2), 175-186.
[doi:10.1177/109442819922004](https://doi.org/10.1177/109442819922004)

Colquitt, J. A., Baer, M. D., Long, D. M., & Halvorsen-Ganepola, M. D.
K. (2014). Scale indicators of social exchange relationships: A
comparison of relative content validity. *Journal of Applied Psychology,
99*(4), 599-618.
[doi:10.1037/a0036374](https://doi.org/10.1037/a0036374)

## Examples

``` r
set.seed(1)
d <- expand.grid(item = c("I1", "I2"), rater = 1:12,
                 construct = c("A", "B", "C"))
d$target_construct <- ifelse(d$item == "I1", "A", "B")
d$rating <- ifelse(d$construct == d$target_construct,
                   rnorm(nrow(d), 4.5, .4), rnorm(nrow(d), 2.3, .5))
anova_content(d)
#>   item target design n_raters n_complete n_constructs target_mean
#> 1   I1      A within       12         12            3    4.624823
#> 2   I2      B within       12         12            3    4.479589
#>   strongest_competitor competitor_mean        F df1 df2            p epsilon_gg
#> 1                    B        2.182382 193.4263   2  22 1.095003e-14  0.9470582
#> 2                    A        2.294693 138.4564   2  22 3.432890e-13  0.8868080
#>     df1_gg   df2_gg         p_gg     p_screen partial_eta2 min_mean_diff
#> 1 1.894116 20.83528 5.134046e-14 5.134046e-14    0.9461909      2.442440
#> 2 1.773616 19.50978 6.346279e-12 6.346279e-12    0.9263999      2.184897
#>   max_contrast_p contrast_pass posthoc_pass
#> 1   9.296774e-10          TRUE         TRUE
#> 2   1.444617e-08          TRUE         TRUE
```

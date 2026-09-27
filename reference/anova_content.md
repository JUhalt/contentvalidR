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
`attr(result, "contrasts")`. It prints as a formatted table in APA
style; the values themselves are unrounded, and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the plain data frame. `posthoc_pass`, a duplicate of `contrast_pass`
deprecated in 0.7.0, was removed in 0.8.0; read `contrast_pass`.

## References

Colquitt, J. A., Baer, M. D., Long, D. M., & Halvorsen-Ganepola, M. D.
K. (2014). Scale indicators of social exchange relationships: A
comparison of relative content validity. *Journal of Applied Psychology,
99*(4), 599–618.
[doi:10.1037/a0036374](https://doi.org/10.1037/a0036374)

Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach
to content validation. *Organizational Research Methods, 2*(2), 175–186.
[doi:10.1177/109442819922004](https://doi.org/10.1177/109442819922004)

## Examples

``` r
set.seed(1)
d <- expand.grid(item = c("I1", "I2"), rater = 1:12,
                 construct = c("A", "B", "C"))
d$target_construct <- ifelse(d$item == "I1", "A", "B")
d$rating <- ifelse(d$construct == d$target_construct,
                   rnorm(nrow(d), 4.5, .4), rnorm(nrow(d), 2.3, .5))
anova_content(d)
#> Content-validity ANOVA (Hinkin & Tracey, 1999)
#> 
#>  item target judges                  F test      p partial eta^2 contrast p met
#>    I1      A     12 F(1.89, 20.84) = 193.43 < .001           .95     < .001 yes
#>    I2      B     12 F(1.77, 19.51) = 138.46 < .001           .93     < .001 yes
#> 
#> Within-judge omnibus tests are Greenhouse-Geisser corrected, so their degrees
#> of freedom are fractional.
#> contrast p: the largest p among the planned target-versus-other contrasts;
#> met: whether every one of them met the screening criterion. attr(x,
#> "contrasts") holds each contrast, and `strongest_competitor` the construct
#> rated closest to the target.
```

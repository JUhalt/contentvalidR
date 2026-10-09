# Repeated-measures ANOVA content test for construct ratings

For each item, evaluates whether definitional-correspondence ratings
differ across construct definitions and whether the intended construct
is rated higher than every orbiting construct.

The Hinkin and Tracey (1999) rating task is a **within-judge** design:
the same judge rates an item against every construct definition. Hinkin
and Tracey analyzed those ratings with a one-way ANOVA and Duncan's
multiple range test at .05, treating the definitions as independent
groups. Because the same judges rate every definition, `anova_content()`
uses the repeated-measures form that MacKenzie et al. (2011) recommend
for this task: a one-way repeated-measures ANOVA on the judges with
complete ratings for the item, followed by planned contrasts of the
intended construct against the others. A between-judge path is kept for
designs in which different judges rate each definition, where a one-way
ANOVA across groups is the fitting test.

The repeated-measures output includes the conventional omnibus *F* and
*p* and a Greenhouse-Geisser (1959) epsilon with its corrected *p*
value. With more than two construct definitions, the corrected *p* value
is the safer default for omnibus screening when sphericity may not hold.
Planned target-versus-orbiting contrasts provide the more direct
item-level evidence.

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
  contrast *p* values. Default `"none"` treats each contrast as a
  planned comparison, in the spirit of MacKenzie et al. (2011); `"holm"`
  is a conservative option. Hinkin and Tracey (1999) themselves used
  Duncan's multiple range test, not planned contrasts.

## Value

A data.frame with one row per item, including the omnibus F, raw p,
Greenhouse-Geisser epsilon/corrected degrees of freedom and *p* value
for within-judge designs, partial eta-squared, and planned-contrast
diagnostics. The full planned-contrast table is stored in
`attr(result, "contrasts")`: for each contrast the two means, their
difference, `t`, `df`, the one-sided `p`, the adjusted `p_adj`, and
`pass`. Its `dz` column is a standardized mean difference: the mean
difference over the standard deviation of the differences in a
within-judge design, and Cohen's *d* with the pooled standard deviation
in a between-judge design. `p_screen` is the *p* the screening uses: the
Greenhouse-Geisser corrected `p_gg` in a within-judge design where a
correction applies, and `p` otherwise. `max_contrast_p` is the largest
contrast *p*, and `NA` when a contrast has no *p* because every judge
rated the intended construct and another the same.

When every judge's ratings differ across the constructs by the same
amounts there is no error variance: `F` is `Inf`, `p` is 0, no
sphericity correction applies (`epsilon_gg`, `df1_gg`, `df2_gg` and
`p_gg` are `NA`), and `p_screen` is `p`. It prints as a formatted table
in APA style; the values themselves are unrounded, and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the plain data frame. `posthoc_pass`, a duplicate of `contrast_pass`
deprecated in 0.7.0, was removed in 0.8.0; read `contrast_pass`.

## What is published and what is this package's choice

The rating task is Hinkin and Tracey's (1999). The repeated-measures
ANOVA followed, when its *F* is significant, by a planned contrast of
the intended construct against the others is MacKenzie et al.'s (2011)
recommendation for it, so the rule that an item passes the omnibus test
and then its contrasts follows their sequence. These details are
contentvalidR choices, not taken from either source:

- The Greenhouse-Geisser corrected *p* is the screening *p* of the
  omnibus test.

- There is one one-sided paired contrast for each orbiting construct,
  and every one must pass, where MacKenzie et al. describe a single
  contrast against the other constructs.

- The contrasts are not adjusted for their number unless
  `adjust = "holm"`.

- The tests use the judges who rated the item against every construct,
  and need at least two of them.

- In a between-judge design the contrasts are one-sided Welch *t* tests.

## References

Greenhouse, S. W., & Geisser, S. (1959). On methods in the analysis of
profile data. *Psychometrika, 24*(2), 95–112.
[doi:10.1007/BF02289823](https://doi.org/10.1007/BF02289823)

Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach
to content validation. *Organizational Research Methods, 2*(2), 175–186.
[doi:10.1177/109442819922004](https://doi.org/10.1177/109442819922004)

MacKenzie, S. B., Podsakoff, P. M., & Podsakoff, N. P. (2011). Construct
measurement and validation procedures in MIS and behavioral research:
Integrating new and existing techniques. *MIS Quarterly, 35*(2),
293–334. [doi:10.2307/23044045](https://doi.org/10.2307/23044045)

## Examples

``` r
set.seed(1)
d <- expand.grid(item = c("I1", "I2"), rater = 1:12,
                 construct = c("A", "B", "C"))
d$target_construct <- ifelse(d$item == "I1", "A", "B")
d$rating <- ifelse(d$construct == d$target_construct,
                   rnorm(nrow(d), 4.5, .4), rnorm(nrow(d), 2.3, .5))
anova_content(d)
#> <contentvalid_anova> Content-validity ANOVA
#> Adapted from Hinkin and Tracey (1999) and MacKenzie et al. (2011).
#> 
#>   Item Target Judges F test                       p Partial eta^2 Contrast p Met
#>   I1   A          12 F(1.89, 20.84) = 193.43 < .001           .95     < .001 yes
#>   I2   B          12 F(1.77, 19.51) = 138.46 < .001           .93     < .001 yes
#> 
#> Within-judge omnibus tests are Greenhouse-Geisser corrected, which reduces
#> their degrees of freedom.
#> Contrast p: the largest p among the planned contrasts, each one-sided (the
#> intended construct rated above one of the others), at alpha = .05 with no
#> adjustment for their number. It is -- when a contrast has no p because every
#> judge rated the two constructs the same. Met: whether every contrast passed.
#> attr(x, "contrasts") holds each one.
#> 
#> See as.data.frame(x) for the unrounded values.
```

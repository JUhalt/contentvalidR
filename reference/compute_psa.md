# Proportion of Substantive Agreement (Psa)

For each item, computes the proportion of non-missing item-sort
responses assigned to the item's intended (target) construct. This is
Anderson and Gerbing's (1991) proportion of substantive agreement,
\\P\_{sa}\\.

Missing assignments are excluded itemwise and reported in `n_missing` so
that the effective denominator is transparent. Psa is a proportion of a
finite set of judges, so an interval is reported alongside it; see `ci`.

## Usage

``` r
compute_psa(
  assignments,
  item_col = "item",
  rater_col = "rater",
  assigned_col = "assigned_construct",
  target_col = "target_construct",
  ci = c("wilson", "agresti_coull", "exact", "none"),
  alpha = 0.05
)
```

## Arguments

- assignments:

  A data.frame containing item-sort responses.

- item_col, rater_col, assigned_col, target_col:

  Column names for the item, rater, assigned construct, and intended
  target construct.

- ci:

  Interval method for Psa: `"wilson"` (default), `"agresti_coull"`,
  `"exact"`, or `"none"`. The methods and the evidence for each are
  described under `ci` in
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md).

- alpha:

  Two-sided alpha level for the interval; `0.05` gives a 95% interval.

## Value

A data.frame with one row per item and columns `item`, `target`,
`n_total`, `n`, `n_missing`, `n_target`, `psa`, `psa_low`, and
`psa_high`.

## References

Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
measures in a confirmatory factor analysis with a pretest assessment of
their substantive validities. *Journal of Applied Psychology, 76*(5),
732-740.
[doi:10.1037/0021-9010.76.5.732](https://doi.org/10.1037/0021-9010.76.5.732)

Wilson, E. B. (1927). Probable inference, the law of succession, and
statistical inference. *Journal of the American Statistical Association,
22*(158), 209-212.
[doi:10.1080/01621459.1927.10502953](https://doi.org/10.1080/01621459.1927.10502953)

Newcombe, R. G. (1998). Two-sided confidence intervals for the single
proportion: Comparison of seven methods. *Statistics in Medicine,
17*(8), 857-872.

Agresti, A., & Coull, B. A. (1998). Approximate is better than "exact"
for interval estimation of binomial proportions. *The American
Statistician, 52*(2), 119-126.
[doi:10.1080/00031305.1998.10480550](https://doi.org/10.1080/00031305.1998.10480550)

Clopper, C. J., & Pearson, E. S. (1934). The use of confidence or
fiducial limits illustrated in the case of the binomial. *Biometrika,
26*(4), 404-413.
[doi:10.1093/biomet/26.4.404](https://doi.org/10.1093/biomet/26.4.404)

## See also

[`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) for
the same interval methods applied to I-CVI.

## Examples

``` r
df <- data.frame(
  item = rep(c("I1", "I2"), each = 4),
  rater = rep(1:4, 2),
  assigned_construct = c("A", "A", "A", "B", "B", "A", "B", "B"),
  target_construct = rep(c("A", "B"), each = 4)
)
compute_psa(df)
#>   item target n_total n n_missing n_target  psa   psa_low  psa_high
#> 1   I1      A       4 4         0        3 0.75 0.3006418 0.9544127
#> 2   I2      B       4 4         0        3 0.75 0.3006418 0.9544127
compute_psa(df, ci = "exact")
#>   item target n_total n n_missing n_target  psa   psa_low  psa_high
#> 1   I1      A       4 4         0        3 0.75 0.1941204 0.9936905
#> 2   I2      B       4 4         0        3 0.75 0.1941204 0.9936905
```

# Proportion of Substantive Agreement (Psa)

For each item, computes the proportion of non-missing item-sort
responses assigned to the item's intended (target) construct. This is
Anderson and Gerbing's (1991) proportion of substantive agreement,
\\P\_{sa}\\.

Missing assignments are excluded itemwise and reported in `n_missing` so
that the effective denominator is transparent.

## Usage

``` r
compute_psa(
  assignments,
  item_col = "item",
  rater_col = "rater",
  assigned_col = "assigned_construct",
  target_col = "target_construct"
)
```

## Arguments

- assignments:

  A data.frame containing item-sort responses.

- item_col, rater_col, assigned_col, target_col:

  Column names for the item, rater, assigned construct, and intended
  target construct.

## Value

A data.frame with one row per item and columns `item`, `target`,
`n_total`, `n`, `n_missing`, `n_target`, and `psa`.

## References

Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
measures in a confirmatory factor analysis with a pretest assessment of
their substantive validities. *Journal of Applied Psychology, 76*(5),
732-740.
[doi:10.1037/0021-9010.76.5.732](https://doi.org/10.1037/0021-9010.76.5.732)

## Examples

``` r
df <- data.frame(
  item = rep(c("I1", "I2"), each = 4),
  rater = rep(1:4, 2),
  assigned_construct = c("A", "A", "A", "B", "B", "A", "B", "B"),
  target_construct = rep(c("A", "B"), each = 4)
)
compute_psa(df)
#>   item target n_total n n_missing n_target  psa
#> 1   I1      A       4 4         0        3 0.75
#> 2   I2      B       4 4         0        3 0.75
```

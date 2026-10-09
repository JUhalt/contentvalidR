# Substantive Validity Coefficient (Csv)

For each item, computes Anderson and Gerbing's (1991)
substantive-validity coefficient:

\$\$C\_{sv} = (n_c - n_o) / N,\$\$

where \\n_c\\ is the number of non-missing assignments to the intended
construct, \\n_o\\ is the largest number of assignments to any one
non-target construct, and \\N\\ is the number of non-missing
assignments.

Missing assignments are excluded itemwise and reported in `n_missing`.

## Usage

``` r
compute_csv(
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
`n_total`, `n`, `n_missing`, `n_target`, `competitor`, `n_other_max`,
and `csv`. It prints as a formatted table in APA style; the values
themselves are unrounded, and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the plain data frame.

## References

Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
measures in a confirmatory factor analysis with a pretest assessment of
their substantive validities. *Journal of Applied Psychology, 76*(5),
732–740.
[doi:10.1037/0021-9010.76.5.732](https://doi.org/10.1037/0021-9010.76.5.732)

## Examples

``` r
df <- data.frame(
  item = rep(c("I1", "I2"), each = 4),
  rater = rep(1:4, 2),
  assigned_construct = c("A", "A", "A", "B", "B", "B", "B", "B"),
  target_construct = rep("A", 8)
)
compute_csv(df)
#> <contentvalid_csv> Coefficient of substantive validity (Csv)
#> Anderson and Gerbing (1991).
#> 
#>   Item  Target  Judges  Competitor  Competitor judges    Csv
#>   I1    A          3/4  B                         1/4    .50
#>   I2    A          0/4  B                         4/4  -1.00
#> 
#> Csv is the target count minus the count for the most-chosen other construct,
#> divided by the number of judges.
#> 
#> See as.data.frame(x) for the unrounded values.
```

# Lawshe's Content Validity Ratio (CVR)

Computes Lawshe's CVR and exact one-sided binomial inference following
the critical-value logic revisited by Ayre and Scally (2014). Input may
be either counts of experts marking each item essential or a
judge-by-item 0/1 matrix.

## Usage

``` r
cvr(essential, N = NULL, alpha = 0.05, na.rm = FALSE, item_names = NULL)
```

## Arguments

- essential:

  Numeric/integer vector of essential counts, or a matrix/data frame
  with judges in rows, items in columns, coded `1 = essential` and
  `0 = not essential`.

- N:

  Panel size. Required for count-vector input. May be a scalar or a
  vector matching `essential`. Ignored for matrix input, where effective
  N is calculated itemwise.

- alpha:

  One-sided exact alpha level. Default `.05`.

- na.rm:

  Logical; for matrix input, permit itemwise missing ratings.

- item_names:

  Optional item names for count-vector input.

## Value

A data.frame containing item, `ne`, effective `N`, CVR, exact p-value,
critical essential count/CVR, and `pass`.

## References

Lawshe, C. H. (1975). A quantitative approach to content validity.
*Personnel Psychology, 28*(4), 563-575.
[doi:10.1111/j.1744-6570.1975.tb01393.x](https://doi.org/10.1111/j.1744-6570.1975.tb01393.x)

Ayre, C., & Scally, A. J. (2014). Critical values for Lawshe's content
validity ratio: Revisiting the original methods of calculation.
*Measurement and Evaluation in Counseling and Development, 47*(1),
79-86.
[doi:10.1177/0748175613513808](https://doi.org/10.1177/0748175613513808)

## Examples

``` r
cvr(essential = c(8, 10, 5), N = 12)
#>    item ne  N        cvr    p_value critical_ne critical_cvr  pass
#> 1 Item1  8 12  0.3333333 0.19384766          10    0.6666667 FALSE
#> 2 Item2 10 12  0.6666667 0.01928711          10    0.6666667  TRUE
#> 3 Item3  5 12 -0.1666667 0.80615234          10    0.6666667 FALSE
```

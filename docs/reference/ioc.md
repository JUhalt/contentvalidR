# Item-Objective Congruence (IOC)

Computes item-objective congruence from expert ratings coded `-1`, `0`,
and `+1`. Duplicate item-judge-objective ratings are rejected. Missing
ratings may be removed cellwise with transparent effective judge counts.

## Usage

``` r
ioc(ratings, na.rm = FALSE)
```

## Arguments

- ratings:

  Data frame with columns `item`, `judge`, `objective`, `score`.

- na.rm:

  Logical. If `FALSE`, missing scores are an error; if `TRUE`, missing
  scores are removed within item-objective cells.

## Value

A data.frame with item, objective, total rows, effective judge count,
missing count, and IOC.

## References

Rovinelli, R. J., & Hambleton, R. K. (1977). On the use of content
specialists in the assessment of criterion-referenced test item
validity. *Dutch Journal of Educational Research, 2*, 49-60.

Turner, R. C., & Carlson, L. (2003). Indexes of item-objective
congruence for multidimensional items. *International Journal of
Testing, 3*(2), 163-171.
[doi:10.1207/S15327574IJT0302_5](https://doi.org/10.1207/S15327574IJT0302_5)

## Examples

``` r
df <- data.frame(
  item = rep("I1", 6),
  judge = rep(1:3, 2),
  objective = rep(c("A", "B"), each = 3),
  score = c(1,1,1, 0,-1,0)
)
ioc(df)
#>   item objective n_total n_judges n_missing        ioc
#> 1   I1         A       3        3         0  1.0000000
#> 2   I1         B       3        3         0 -0.3333333
```

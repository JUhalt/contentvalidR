# Aiken's V for expert content-relevance ratings

Computes Aiken's V per item for bounded ordinal expert ratings. By
default, confidence intervals use the score method described by Penfield
and Giacobbi (2004). Percentile bootstrap intervals remain available for
compatibility and sensitivity analysis.

## Usage

``` r
aikens_v(
  ratings,
  lo = 1,
  hi = 5,
  ci = c("score", "none", "bootstrap"),
  B = 500,
  alpha = 0.05,
  seed = NULL,
  na.rm = FALSE
)
```

## Arguments

- ratings:

  Matrix/data.frame with judges in rows and items in columns.

- lo, hi:

  Numeric lower and upper bounds of the rating scale.

- ci:

  Confidence-interval method: `"score"` (default), `"bootstrap"`, or
  `"none"`.

- B:

  Number of bootstrap replicates when `ci = "bootstrap"`.

- alpha:

  Two-sided CI alpha level; `.05` gives a 95% interval.

- seed:

  Optional integer seed for bootstrap reproducibility.

- na.rm:

  Logical. If `FALSE` (default), missing ratings are an error. If
  `TRUE`, item-specific effective judge counts are used.

## Value

A data.frame with item, effective judge count `N`, number missing,
Aiken's `V`, and (when requested) `ci_low` and `ci_high`.

## References

Aiken, L. R. (1980). Content validity and reliability of single items or
questionnaires. *Educational and Psychological Measurement, 40*(4),
955-959.
[doi:10.1177/001316448004000419](https://doi.org/10.1177/001316448004000419)

Penfield, R. D., & Giacobbi, P. R., Jr. (2004). Applying a score
confidence interval to Aiken's item content-relevance index.
*Measurement in Physical Education and Exercise Science, 8*(4), 213-225.
[doi:10.1207/S15327841MPEE0804_3](https://doi.org/10.1207/S15327841MPEE0804_3)

## Examples

``` r
R <- matrix(c(4,4,3,4, 4,3,4,4, 3,3,4,4), nrow = 4)
colnames(R) <- c("Item1", "Item2", "Item3")
aikens_v(R, lo = 1, hi = 4)
#>    item N n_missing         V    ci_low   ci_high               ci_method
#> 1 Item1 4         0 0.9166667 0.6461201 0.9851349 Penfield-Giacobbi score
#> 2 Item2 4         0 0.9166667 0.6461201 0.9851349 Penfield-Giacobbi score
#> 3 Item3 4         0 0.8333333 0.5519691 0.9530349 Penfield-Giacobbi score
```

# Aiken's V for expert content-relevance ratings

Computes Aiken's V per item for bounded ordinal expert ratings. By
default, confidence intervals use the score method described by Penfield
and Giacobbi (2004). Percentile bootstrap intervals remain available for
compatibility and sensitivity analysis.

## Usage

``` r
aikens_v(
  ratings,
  lo,
  hi,
  ci = c("score", "none", "bootstrap"),
  B = 500,
  alpha = 0.05,
  seed = NULL,
  na.rm = FALSE
)
```

## Arguments

- ratings:

  Matrix/data.frame with judges in rows and items in columns. Every
  column is an item; a column whose name looks like a rater ID (such as
  `expert` or `rater_id`) stops the function, so remove it, or rename an
  item that has such a name.

- lo, hi:

  Lowest and highest points of the rating scale. Both are required: V
  rescales the mean rating by the range of the scale, so the same
  ratings give a different V on a 1-4 scale than on a 1-5 scale.

- ci:

  Confidence-interval method: `"score"` (default), `"bootstrap"`, or
  `"none"`.

- B:

  Number of bootstrap replicates when `ci = "bootstrap"`.

- alpha:

  Two-sided CI alpha level; `.05` gives a 95% interval.

- seed:

  Optional integer seed for bootstrap reproducibility. The random-number
  stream of the session is left as it was.

- na.rm:

  Logical. If `FALSE` (default), missing ratings are an error. If
  `TRUE`, item-specific effective judge counts are used.

## Value

A data.frame with item, effective judge count `N`, number missing,
Aiken's `V`, and (when requested) `ci_low` and `ci_high`. It prints as a
formatted table in APA style; the values themselves are unrounded, and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the plain data frame.

## References

Aiken, L. R. (1980). Content validity and reliability of single items or
questionnaires. *Educational and Psychological Measurement, 40*(4),
955–959.
[doi:10.1177/001316448004000419](https://doi.org/10.1177/001316448004000419)

Penfield, R. D., & Giacobbi, P. R., Jr. (2004). Applying a score
confidence interval to Aiken's item content-relevance index.
*Measurement in Physical Education and Exercise Science, 8*(4), 213–225.
[doi:10.1207/S15327841MPEE0804_3](https://doi.org/10.1207/S15327841MPEE0804_3)

## Examples

``` r
R <- matrix(c(4,4,3,4, 4,3,4,4, 3,3,4,4), nrow = 4)
colnames(R) <- c("Item1", "Item2", "Item3")
aikens_v(R, lo = 1, hi = 4)
#> Aiken's V (Aiken, 1980)
#> 
#>   item experts   V     95% CI
#>  Item1       4 .92 [.65, .99]
#>  Item2       4 .92 [.65, .99]
#>  Item3       4 .83 [.55, .95]
#> 
#> Scale: 1 to 4.
#> Interval: Penfield-Giacobbi score (Penfield & Giacobbi, 2004).
```

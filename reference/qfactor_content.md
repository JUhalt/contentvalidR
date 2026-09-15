# Q-factor helper for content adequacy (comparator)

Builds an item-by-item Q-correlation matrix from rating data and runs a
factor extraction (PCA by default), following the content-adequacy
approach of Schriesheim et al. (1993): judges rate every item against
every construct definition, and items that measure the same construct
correlate across those ratings. Schriesheim et al. (1999) compared this
approach empirically with other content-adequacy methods and found
substantial similarity along with some differences. This comparator is
retained for compatibility and exploratory use; it is not part of the
recommended sort, rating, or expert-panel workflows.

## Usage

``` r
qfactor_content(
  ratings,
  item_col = "item",
  rater_col = "rater",
  construct_col = "construct",
  rating_col = "rating",
  k_factors = NULL,
  method = c("pca", "pa"),
  retention = c("parallel", "kaiser"),
  n_iter = 100,
  seed = NULL
)
```

## Arguments

- ratings:

  A data.frame with columns for item, rater, construct, rating.

- item_col:

  Name of the item column. Default "item".

- rater_col:

  Name of the rater column. Default "rater".

- construct_col:

  Name of the construct column. Default "construct".

- rating_col:

  Name of the rating column. Default "rating".

- k_factors:

  Optional integer: number of factors to extract. When supplied,
  `retention` is ignored.

- method:

  `"pca"` (default) or `"pa"` (principal axis; uses SMCs as initial
  communalities).

- retention:

  How to choose the number of factors when `k_factors` is `NULL`:
  `"parallel"` (default) or `"kaiser"`. See the section below.

- n_iter:

  Number of random data sets for parallel analysis.

- seed:

  Optional seed that makes parallel analysis reproducible.

## Value

A list with components:

- `cor_Q`: item-by-item correlation matrix,

- `eigen`: eigenvalues of `cor_Q`,

- `k`: number of factors used,

- `loadings`: matrix of factor loadings,

- `method`: the extraction method,

- `retention`: `"parallel"`, `"kaiser"`, or `"fixed"` when `k_factors`
  was supplied,

- `k_suggested`: the number of factors the retention rule suggested,
  which can be 0,

- `parallel_eigen`: mean random-data eigenvalues from parallel analysis,
  or `NULL` when parallel analysis was not run.

## Number of factors

Unless `k_factors` is supplied, `retention` sets the number of factors:

- `"parallel"` (default): Horn's (1965) parallel analysis. The
  eigenvalues of the Q-correlation matrix are compared, in order, with
  the mean eigenvalues from random normal data of the same size and with
  the same missing cells. Factors are retained while the observed
  eigenvalue is larger. Zwick and Velicer (1986) found parallel analysis
  among the most accurate rules. Results vary slightly between runs
  unless `seed` is set.

- `"kaiser"`: retain eigenvalues greater than 1. This was the default
  before contentvalidR 0.3.0 and remains available so earlier results
  can be reproduced. It is never the default: Zwick and Velicer (1986)
  found that it severely overestimates the number of components, and
  choosing it prints a message saying so.

Both rules use the eigenvalues of the full Q-correlation matrix, with 1s
on the diagonal, whichever extraction `method` is used. At least one
factor is always extracted; `k_suggested` shows when a rule suggested
none.

## References

Horn, J. L. (1965). A rationale and test for the number of factors in
factor analysis. *Psychometrika, 30*(2), 179-185.
[doi:10.1007/BF02289447](https://doi.org/10.1007/BF02289447)

Schriesheim, C. A., Powers, K. J., Scandura, T. A., Gardiner, C. C., &
Lankau, M. J. (1993). Improving construct measurement in management
research: Comments and a quantitative approach for assessing the
theoretical content adequacy of paper-and-pencil survey-type
instruments. *Journal of Management, 19*(2), 385-417.
[doi:10.1177/014920639301900208](https://doi.org/10.1177/014920639301900208)

Schriesheim, C. A., Cogliser, C. C., Scandura, T. A., Lankau, M. J., &
Powers, K. J. (1999). An empirical comparison of approaches for
quantitatively assessing the content adequacy of paper-and-pencil
measurement instruments. *Organizational Research Methods, 2*(2),
140-156.
[doi:10.1177/109442819922002](https://doi.org/10.1177/109442819922002)

Zwick, W. R., & Velicer, W. F. (1986). Comparison of five rules for
determining the number of components to retain. *Psychological Bulletin,
99*(3), 432-442.
[doi:10.1037/0033-2909.99.3.432](https://doi.org/10.1037/0033-2909.99.3.432)

## Examples

``` r
set.seed(1)
df <- data.frame(
  item = rep(paste0("I",1:6), each = 30),
  rater = rep(1:10, times = 18),
  construct = rep(rep(LETTERS[1:3], each = 10), times = 6),
  rating = rnorm(180)
)
qf <- qfactor_content(df, seed = 1)
qf$k
#> [1] 1
str(qf$loadings)
#>  num [1:6, 1] 0.211 -0.756 -0.638 0.177 0.559 ...
#>  - attr(*, "dimnames")=List of 2
#>   ..$ : chr [1:6] "I1" "I2" "I3" "I4" ...
#>   ..$ : chr "PC1"
```

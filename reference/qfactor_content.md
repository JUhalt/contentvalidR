# Q-factor helper for content adequacy (comparator)

Builds an item-by-item Q-correlation matrix from rating data and runs a
simple factor extraction (PCA by default). This legacy comparator is
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
  method = c("pca", "pa")
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

  Optional integer: number of factors to extract. If `NULL`, uses a
  simple Kaiser \> 1 rule on PCA eigenvalues to suggest k.

- method:

  `"pca"` (default) or `"pa"` (principal axis; uses SMCs as initial
  communalities).

## Value

A list with components:

- `cor_Q`: item-by-item correlation matrix,

- `eigen`: eigenvalues of `cor_Q`,

- `k`: number of factors used,

- `loadings`: matrix of factor loadings,

- `method`: the extraction method.

## Examples

``` r
set.seed(1)
df <- data.frame(
  item = rep(paste0("I",1:6), each = 30),
  rater = rep(1:10, times = 18),
  construct = rep(rep(LETTERS[1:3], each = 10), times = 6),
  rating = rnorm(180)
)
qf <- qfactor_content(df)
str(qf$loadings)
#>  num [1:6, 1:3] 0.211 -0.756 -0.638 0.177 0.559 ...
#>  - attr(*, "dimnames")=List of 2
#>   ..$ : chr [1:6] "I1" "I2" "I3" "I4" ...
#>   ..$ : chr [1:3] "PC1" "PC2" "PC3"
```

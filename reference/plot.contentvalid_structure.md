# Plot an expert content map

Plots the multidimensional scaling content map from
[`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md),
with each item positioned by expert-perceived similarity and labeled by
its blueprint cell. Items that sit away from others sharing their cell
are the ones experts did not group as the blueprint expects.

## Usage

``` r
# S3 method for class 'contentvalid_structure'
plot(x, show_legend = TRUE, ...)
```

## Arguments

- x:

  A `contentvalid_structure` object.

- show_legend:

  Draw the blueprint-cell key.

- ...:

  Passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html). An
  argument given here, such as `xlab`, `xlim` or `main`, replaces the
  one the method would set. A `pch` or `col` with one value per
  blueprint cell (or cluster) is applied cell by cell and shown in the
  key; a `pch` of any other length leaves the key out, because it could
  no longer tell the cells apart.

## Value

`x`, invisibly. Called for the plot.

## Examples

``` r
items <- paste0("I", 1:9)
blueprint <- rep(c("Autonomy", "Competence", "Relatedness"), each = 3)
sim <- matrix(c(
  5, 4, 3, 2, 2, 1, 1, 2, 1,
  4, 5, 4, 3, 1, 2, 2, 1, 1,
  3, 4, 5, 1, 2, 2, 1, 1, 3,
  2, 3, 1, 5, 4, 3, 2, 2, 1,
  2, 1, 2, 4, 5, 4, 1, 3, 2,
  1, 2, 2, 3, 4, 5, 2, 1, 2,
  1, 2, 1, 2, 1, 2, 5, 3, 4,
  2, 1, 1, 2, 3, 1, 3, 5, 4,
  1, 1, 3, 1, 2, 2, 4, 4, 5
), 9, 9, dimnames = list(items, items))
plot(content_structure(sim, membership = blueprint))
```

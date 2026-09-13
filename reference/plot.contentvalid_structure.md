# Plot an expert content map

Plots the multidimensional scaling content map from
[`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md),
with each item positioned by expert-perceived similarity and labelled by
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
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

`x`, invisibly. Called for the plot.

## Examples

``` r
items <- paste0("I", 1:6)
blueprint <- c(rep("Autonomy", 3), rep("Competence", 3))
sim <- matrix(1, 6, 6, dimnames = list(items, items))
sim[1:3, 1:3] <- 5
sim[4:6, 4:6] <- 5
diag(sim) <- 5
plot(content_structure(sim, membership = blueprint))
```

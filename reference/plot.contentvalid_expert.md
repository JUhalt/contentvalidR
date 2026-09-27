# Plot expert-panel content-validity results

Draws a mode-specific evidence plot, one row per item with the first
item at the top. Relevance mode shows Aiken's V and I-CVI side by side,
each with its interval, and a dashed line at the I-CVI criterion when
every item had the same number of experts. Essentiality mode shows each
observed CVR against the CVR the exact test needs for that item.
Congruence mode shows each item's IOC for its intended objective against
its strongest competitor, when a target mapping is available.

## Usage

``` r
# S3 method for class 'contentvalid_expert'
plot(x, show_legend = TRUE, ...)
```

## Arguments

- x:

  A `contentvalid_expert` object.

- show_legend:

  Logical; draw the compact plot key. Default `TRUE`.

- ...:

  Additional graphical arguments passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

The input object invisibly.

## Examples

``` r
relevance <- matrix(
  c(4,4,4,3, 4,4,3,4, 3,4,4,4, 4,3,4,4),
  nrow = 4,
  dimnames = list(NULL, paste0("Item", 1:4))
)
plot(expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
                     agreement = "none"))

plot(expert_validity(c(10, 8, 6), mode = "essentiality", N = 12))
```

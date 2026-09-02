# Plot item-sort evidence

Draws either the original one-index item plot or a
correspondence-distinctiveness evidence map. The map places Psa on the
x-axis and Csv on the y-axis so that intended-construct correspondence
and distinctiveness can be inspected together. Target-scale means are
added as diamonds when available. Colquitt benchmark bands are
deliberately not drawn across item points because those norms were
developed for scale-level averages rather than individual items.

## Usage

``` r
# S3 method for class 'contentvalid_sort'
plot(
  x,
  metric = c("psa", "csv"),
  type = c("item", "map"),
  label = c("review", "all", "none"),
  show_legend = TRUE,
  ...
)
```

## Arguments

- x:

  A `contentvalid_sort` object.

- metric:

  Either `"psa"` or `"csv"` for `type = "item"`.

- type:

  Either `"item"` for the original one-index plot or `"map"` for the
  correspondence-distinctiveness evidence map.

- label:

  Which item labels to draw on the map: `"review"` (default), `"all"`,
  or `"none"`.

- show_legend:

  Logical; draw the compact plot key. Default `TRUE`.

- ...:

  Additional graphical arguments passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

The input object invisibly.

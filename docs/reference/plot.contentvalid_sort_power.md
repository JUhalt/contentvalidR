# Plot exact item-sort planning evidence

Visualizes either exact Howard-Melloy retention power across planned
judge sample sizes or the minimum observed Psa implied by the exact
critical target count. The critical view is drawn as a step function
over every integer judge count in the displayed range, reflecting the
discrete exact-binomial rule. Multiple assumed true target-assignment
probabilities are distinguished by line type and plotting symbol rather
than color.

## Usage

``` r
# S3 method for class 'contentvalid_sort_power'
plot(
  x,
  type = c("power", "critical"),
  reference_power = NULL,
  show_legend = TRUE,
  ...
)
```

## Arguments

- x:

  A `contentvalid_sort_power` object.

- type:

  Either `"power"` or `"critical"`.

- reference_power:

  Optional horizontal reference value for `type = "power"`. No
  conventional target is imposed by default.

- show_legend:

  Logical; draw the compact power-series key. Default `TRUE`.

- ...:

  Additional graphical arguments passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

The input object invisibly.

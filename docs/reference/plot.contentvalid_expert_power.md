# Plot an expert-panel planning curve

Plot an expert-panel planning curve

## Usage

``` r
# S3 method for class 'contentvalid_expert_power'
plot(x, show_legend = TRUE, ...)
```

## Arguments

- x:

  A `contentvalid_expert_power` object.

- show_legend:

  Draw the key identifying each assumed endorsement probability.

- ...:

  Passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

`x`, invisibly. Called for the plot.

## Examples

``` r
plot(expert_power(n_experts = 3:12, prob = c(0.7, 0.85)))
```

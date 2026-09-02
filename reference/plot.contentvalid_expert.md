# Plot expert-panel content-validity results

Draws a mode-specific evidence plot. Relevance mode shows Aiken's V with
its score confidence interval and overlays I-CVI as a separate marker.
Essentiality mode shows each observed CVR against its item-specific
critical CVR. Congruence mode uses a target-versus-strongest-competitor
gap plot when a target mapping is available.

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

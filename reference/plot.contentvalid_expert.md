# Plot expert-panel content-validity results

Draws a mode-specific evidence plot, one row per item with the first
item at the top. Relevance mode shows Aiken's V and I-CVI side by side,
each with its interval, and a dashed line at the I-CVI criterion when
every item had the same number of experts. Essentiality mode shows each
observed CVR against the CVR the exact test needs for that item.
Congruence mode shows each item's index for its intended objective
against the `ioc_cut` criterion (dashed), with the experts' mean ratings
on the target and on the closest other objective in gray, when a target
mapping is available; an item with no index is marked with a cross.

In relevance mode, `type = "distribution"` draws every expert's rating
as a diverging stacked bar (Heiberger & Robbins, 2014), split at the
relevance cut. Ratings below the cut extend left and ratings at or above
it extend right, so the right-hand length is the item's I-CVI, read
against the dashed criterion line. The number beside each bar is that
I-CVI, and the symbol is the decision the fit made. It shows what the
index cannot: two items with the same I-CVI, one rated relevant with 4s
and the other with 3s.

## Usage

``` r
# S3 method for class 'contentvalid_expert'
plot(
  x,
  show_legend = TRUE,
  type = c("item", "distribution"),
  apa = TRUE,
  labels = NULL,
  ...
)
```

## Arguments

- x:

  A `contentvalid_expert` object.

- show_legend:

  Logical; draw the compact plot key. Default `TRUE`.

- type:

  `"item"` (default) for the evidence plot described above, or
  `"distribution"` for the rating distributions (relevance mode only).

- apa:

  Used by `type = "distribution"`. `TRUE` (default) draws in gray, with
  darker meaning a higher rating, as an APA figure is printed. `FALSE`
  draws ratings below the cut in brown and ratings at or above it in
  teal, a colorblind-safe scheme for slides and posters. The symbol
  beside each bar carries the decision either way. The `"item"` plot is
  always gray.

- labels:

  For `type = "distribution"`, one label per rating category, lowest
  first, such as
  `c("Not relevant", "Somewhat relevant", "Quite relevant", "Highly relevant")`.
  Defaults to `"Rated 1"`, `"Rated 2"`, and so on.

- ...:

  Additional graphical arguments passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

The input object invisibly.

## References

Heiberger, R. M., & Robbins, N. B. (2014). Design of diverging stacked
bar charts for Likert scales and other applications. *Journal of
Statistical Software, 57*(5), 1–32.
[doi:10.18637/jss.v057.i05](https://doi.org/10.18637/jss.v057.i05)

## Examples

``` r
relevance <- matrix(
  c(4,4,4,3, 4,4,3,4, 3,4,4,4, 4,3,4,4),
  nrow = 4,
  dimnames = list(NULL, paste0("Item", 1:4))
)
fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
                       agreement = "none")
plot(fit)

plot(fit, type = "distribution")

plot(fit, type = "distribution", apa = FALSE)

plot(expert_validity(c(10, 8, 6), mode = "essentiality", N = 12))
```

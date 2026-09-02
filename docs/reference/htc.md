# Hinkin-Tracey correspondence (HTC)

Computes the Hinkin-Tracey correspondence index for each item. Following
Colquitt et al. (2019), HTC is the average definitional-correspondence
rating for the intended construct divided by `a`, the number of rating
anchors. Ratings are internally shifted to a 1-to-`a` metric when a
scale such as 0-to-4 is supplied, preserving the meaning of the
published formula.

HTC describes definitional correspondence. Higher values indicate that
judges see the item as more representative of its intended construct.

## Usage

``` r
htc(
  ratings,
  item_col = "item",
  rater_col = "rater",
  construct_col = "construct",
  rating_col = "rating",
  target_map = NULL,
  target_col = "target_construct",
  scale_min = 1,
  scale_max = 5
)
```

## Arguments

- ratings:

  A long-format data.frame containing item, rater, construct, and rating
  columns.

- item_col, rater_col, construct_col, rating_col:

  Column names.

- target_map:

  Optional named character vector/list mapping item to target.

- target_col:

  Target column used when `target_map` is `NULL`.

- scale_min, scale_max:

  Endpoints of the equally spaced integer rating scale (for example, 1
  and 5).

## Value

A data.frame with item-level target means, usable target-rating counts,
and HTC.

## References

Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach
to content validation. *Organizational Research Methods, 2*(2), 175-186.
[doi:10.1177/109442819922004](https://doi.org/10.1177/109442819922004)

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243-1265.
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406)

## Examples

``` r
d <- expand.grid(item = "I1", rater = 1:4, construct = c("A", "B"))
d$rating <- c(5, 4, 5, 4, 2, 2, 1, 2)
htc(d, target_map = c(I1 = "A"), scale_min = 1, scale_max = 5)
#>   item target n_target target_mean anchors htc
#> 1   I1      A        4         4.5       5 0.9
```

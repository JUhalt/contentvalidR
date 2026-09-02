# Hinkin-Tracey distinctiveness (HTD)

Computes the Hinkin-Tracey distinctiveness index for each item in a
fully crossed, within-judge rating design. For every complete judge, the
intended construct rating is contrasted with each orbiting-construct
rating. The average of those difference scores is divided by `a - 1`,
where `a` is the number of rating anchors. HTD ranges from -1 to 1.

## Usage

``` r
htd(
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

  Optional named item-to-target mapping.

- target_col:

  Target column used when `target_map` is `NULL`.

- scale_min, scale_max:

  Endpoints of the equally spaced integer rating scale.

## Value

A data.frame containing item-level HTD, the strongest orbiting
construct, complete-judge count, and number of target-orbiting pairs.

## References

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
*Journal of Applied Psychology, 104*(10), 1243-1265.
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406)

## Examples

``` r
d <- expand.grid(item = "I1", rater = 1:4, construct = c("A", "B", "C"))
d$rating <- c(5,4,5,4, 2,2,1,2, 3,2,2,1)
htd(d, target_map = c(I1 = "A"), scale_min = 1, scale_max = 5)
#>   item target n_complete n_pairs target_mean_complete strongest_competitor
#> 1   I1      A          4       8                  4.5                    C
#>   competitor_mean anchors     htd
#> 1               2       5 0.65625
```

# Hinkin-Tracey distinctiveness (HTD)

Computes the Hinkin-Tracey distinctiveness index of Colquitt et al.
(2019) for each item in a fully crossed, within-judge rating design. For
every complete judge, the intended construct rating is contrasted with
each orbiting-construct rating. The average of those difference scores
is divided by `a - 1`, where `a` is the number of rating anchors. HTD
ranges from -1 to 1.

HTD is therefore the intended construct's average lead over **all** the
orbiting constructs, not its lead over the closest one. The closest one
is reported beside it as `strongest_competitor`.

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
construct, complete-judge count, and number of target-orbiting pairs. It
prints as a formatted table in APA style; the values themselves are
unrounded, and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the plain data frame.

## References

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243–1265.
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406)

## Examples

``` r
d <- expand.grid(item = "I1", rater = 1:4, construct = c("A", "B", "C"))
d$rating <- c(5,4,5,4, 2,2,1,2, 3,2,2,1)
htd(d, target_map = c(I1 = "A"), scale_min = 1, scale_max = 5)
#> Hinkin-Tracey distinctiveness (HTD; Colquitt et al., 2019)
#> 
#>  item target judges target mean competitor competitor mean HTD
#>    I1      A      4        4.50          C            2.00 .66
#> 
#> competitor: the other construct with the highest mean rating. HTD itself
#> averages the gap over every other construct.
```

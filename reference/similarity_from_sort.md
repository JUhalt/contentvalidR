# Derive item similarities from an item-sort task

Builds an item-by-item similarity matrix from item-sort data, where the
similarity of two items is the proportion of judges who assigned them to
the same construct.

This lets
[`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md)
be used when a study collected a sorting task rather than the pairwise
similarity ratings of Sireci and Geisinger (1992).

## Usage

``` r
similarity_from_sort(
  assignments,
  item_col = "item",
  rater_col = "rater",
  assigned_col = "assigned_construct"
)
```

## Arguments

- assignments:

  A long-format data frame of sort assignments.

- item_col, rater_col, assigned_col:

  Column names.

## Value

A square, symmetric item-by-item matrix of co-assignment proportions,
with attribute `"n_pairs"` giving the number of judges contributing to
each cell. It prints with two decimals; the values themselves are
unrounded.

## Weaker evidence than a similarity task

Co-assignment similarity is coarser than a direct similarity rating. A
sort forces every item into exactly one construct, so two items placed
in different constructs record zero similarity no matter how closely
related a judge considers them, and the recovered structure is
constrained toward the construct set the sorting task offered. Structure
recovered this way is evidence about how judges sorted, which is a
weaker basis for claims about perceived content structure than pairwise
similarity ratings collected for that purpose.

## References

Sireci, S. G., & Geisinger, K. F. (1992). Analyzing test content using
cluster analysis and multidimensional scaling. *Applied Psychological
Measurement, 16*(1), 17–31.
[doi:10.1177/014662169201600102](https://doi.org/10.1177/014662169201600102)

## Examples

``` r
sorts <- data.frame(
  item = rep(paste0("I", 1:4), each = 5),
  rater = rep(1:5, times = 4),
  assigned_construct = c(rep("A", 5), rep("A", 5), rep("B", 5), rep("B", 5))
)
similarity_from_sort(sorts)
#> <contentvalid_similarity> Item similarity
#> The share of judges who sorted both items and put them in the same construct.
#> 
#>   Item    I1    I2    I3    I4
#>   I1          1.00   .00   .00
#>   I2    1.00         .00   .00
#>   I3     .00   .00        1.00
#>   I4     .00   .00  1.00
#> 
#> Every pair was sorted by the same 5 judges.
#> 
#> See content_structure(x) to scale and cluster these similarities.
```

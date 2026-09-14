# Item-similarity structure of a content domain

Analyzes whether subject-matter experts perceive items as grouping the
way a test blueprint says they should, using the multidimensional
scaling and cluster analysis procedure of Sireci and Geisinger (1992,
1995).

Experts rate how similar each pair of items is. Those similarities are
scaled into a low-dimensional content map and clustered. If the
blueprint describes the domain as experts actually see it, the recovered
clusters should correspond to the blueprint's cells. Agreement is
quantified with the adjusted Rand index, which is corrected for chance
so that a value near 0 means no better than random correspondence.

This is evidence about perceived content *structure*. It is not evidence
that the items cover the domain: see
[`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md)
for coverage.

## Usage

``` r
content_structure(
  similarity,
  membership = NULL,
  k = NULL,
  dims = 2,
  max_dims = 5,
  similarity_is_distance = FALSE
)
```

## Arguments

- similarity:

  A square, symmetric item-by-item matrix of expert similarity ratings,
  or a distance matrix when `similarity_is_distance` is `TRUE`.
  Similarities are converted to distances as
  `max(similarity) - similarity`.

- membership:

  Optional blueprint cell for each item, as a vector in the same order
  as the rows of `similarity`, or named by item. When supplied, the
  recovered clustering is compared against it.

- k:

  Number of clusters to extract. Defaults to the number of distinct
  blueprint cells, or 2 when no blueprint is supplied.

- dims:

  Number of multidimensional scaling dimensions to retain.

- max_dims:

  Largest dimensionality reported in the fit table.

- similarity_is_distance:

  Set `TRUE` when `similarity` already holds distances rather than
  similarities.

## Value

An object of class `contentvalid_structure`, a list containing the MDS
`coordinates`, `clusters`, the `fit` table across dimensionalities, the
`stress` and `gof` of the retained solution, the `adjusted_rand` index
and `cross_tab` against the blueprint, `settings`, `design`, `status`,
and an `interpretation`.

## Dimensionality

The retained dimensionality is reported rather than chosen silently. The
`fit` table gives Kruskal stress-1 for every dimensionality up to
`max_dims`, with the conventional descriptive labels. Those labels are
long-standing conventions for describing fit, not thresholds that decide
how many dimensions a content domain has. Substantive interpretability
of the dimensions should drive that choice.

## References

Sireci, S. G., & Geisinger, K. F. (1992). Analyzing test content using
cluster analysis and multidimensional scaling. *Applied Psychological
Measurement, 16*(1), 17-31.
[doi:10.1177/014662169201600102](https://doi.org/10.1177/014662169201600102)

Sireci, S. G., & Geisinger, K. F. (1995). Using subject-matter experts
to assess content representation: An MDS analysis. *Applied
Psychological Measurement, 19*(3), 241-255.
[doi:10.1177/014662169501900303](https://doi.org/10.1177/014662169501900303)

Sireci, S. G. (1998). The construct of content validity. *Social
Indicators Research, 45*(1-3), 83-117.
[doi:10.1023/A:1006985528729](https://doi.org/10.1023/A%3A1006985528729)

Hubert, L., & Arabie, P. (1985). Comparing partitions. *Journal of
Classification, 2*(1), 193-218.
[doi:10.1007/BF01908075](https://doi.org/10.1007/BF01908075)

## See also

[`similarity_from_sort()`](https://juhalt.github.io/contentvalidR/reference/similarity_from_sort.md)
to derive similarities from an item-sort task, and
[`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md)
for the combined coverage-and-structure workflow.

## Examples

``` r
items <- paste0("I", 1:6)
blueprint <- c(rep("Autonomy", 3), rep("Competence", 3))
sim <- matrix(1, 6, 6, dimnames = list(items, items))
sim[1:3, 1:3] <- 5
sim[4:6, 4:6] <- 5
diag(sim) <- 5
content_structure(sim, membership = blueprint)
#> Expert item-similarity content structure
#> Items: 6   Dimensions retained: 1   Clusters: 2
#> Requested 2 dimensions, but these similarities support only 1.
#> The solution uses 1.
#> Stress (Kruskal-1): 0 (excellent)
#> 
#> Fit by dimensionality
#>  dims stress gof fit_label
#>     1      0   1 excellent
#> 
#> Blueprint cell by recovered cluster
#>             cluster
#> blueprint    1 2
#>   Autonomy   3 0
#>   Competence 0 3
#> 
#> Adjusted Rand index: 1
#> 
#> Status: Supported
#> Expert-perceived item groupings correspond closely to the blueprint
#> (adjusted Rand index 1.00, where 0 is chance agreement and 1 is exact).
#> This supports the claim that the blueprint describes the domain as
#> subject-matter experts see it.
#> 
#> Stress labels are descriptive conventions, not rules for deciding 
#> how many dimensions a content domain has.
```

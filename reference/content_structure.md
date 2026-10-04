# Item-similarity structure of a content domain

Analyzes whether subject-matter experts perceive items as grouping the
way a test blueprint says they should, with multidimensional scaling
followed by a cluster analysis of the item coordinates, adapted from
Sireci and Geisinger (1992, 1995).

Experts rate how similar each pair of items is. Those similarities are
scaled into a low-dimensional content map, and the items' coordinates on
that map are clustered. If the blueprint describes the domain as experts
actually see it, the recovered clusters should correspond to the
blueprint's cells. Agreement is quantified with the adjusted Rand index
(Hubert & Arabie, 1985), which is corrected for chance so that a value
near 0 means no better than random correspondence.

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
  similarity_is_distance = FALSE,
  ari_cut = 0.6
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
  as the rows of `similarity`, or named by item. When it has names, they
  must be the item names: a vector whose names do not match the items is
  an error, never read by position. When supplied, the recovered
  clustering is compared against it.

- k:

  Number of clusters to extract. Defaults to the number of distinct
  blueprint cells, or 2 when no blueprint is supplied.

- dims:

  Number of multidimensional scaling dimensions to retain. The clusters
  are formed from the coordinates on these dimensions.

- max_dims:

  Largest dimensionality reported in the fit table.

- similarity_is_distance:

  Set `TRUE` when `similarity` already holds distances rather than
  similarities.

- ari_cut:

  Adjusted Rand index at or above which the status is `"Supported"`.
  Default .60, a contentvalidR convention.

## Value

An object of class `contentvalid_structure`, a list containing the MDS
`coordinates`, `clusters`, the `fit` table across dimensionalities, the
`stress` and `gof` of the retained solution, the `adjusted_rand` index
and `cross_tab` against the blueprint, `settings`, `design`, `status`,
and an `interpretation`. `status` is `"Supported"` or `"Review"` by
`ari_cut`, `"Descriptive only"` without a blueprint, and
`"Insufficient data"` when the blueprint or the clustering has a single
group, which leaves nothing to compare.

## What is published and what is this package's choice

Sireci and Geisinger scaled the experts' similarity ratings and then ran
a hierarchical cluster analysis on the items' scaling coordinates.
`content_structure()` does the same, so the clusters depend on the
number of dimensions retained. Four things differ from their procedure
or are not stated in it, and are this package's choices:

- In their 1995 study they scaled each expert's matrix with an
  individual-differences model (INDSCAL). This function applies
  classical scaling to one similarity matrix, usually the experts' mean
  ratings.

- The clusters are formed with average linkage.

- They read the correspondence with the blueprint from the cluster table
  and from regressions of relevance ratings on the coordinates. The
  adjusted Rand index is added here to put a number on that
  correspondence.

- The status rests on `ari_cut`. No published standard says how large an
  adjusted Rand index must be, so the default, .60, is a contentvalidR
  convention. It is printed beside the status so a reader can apply
  another.

Versions before 1.0 clustered the original dissimilarities, not the
coordinates, so the number of dimensions had no effect on the clusters.

## Dimensionality

The retained dimensionality is reported rather than chosen silently. For
every dimensionality up to `max_dims`, the `fit` table gives two
measures of how well the map reproduces the similarities. `gof` is the
goodness of fit of classical scaling: the share of the sum of the
absolute eigenvalues that the retained dimensions account for. `stress`,
printed as "distortion", is the root of the squared differences between
the dissimilarities and the map distances, over the squared
dissimilarities; 0 is an exact map. It need not fall as dimensions are
added, because classical scaling does not minimize it.

That `stress` is not Kruskal's (1964) stress-1, which compares the map
distances with monotonically transformed dissimilarities in a nonmetric
solution fitted to minimize it. His verbal benchmarks ("good", "fair",
"poor") were given for that quantity and are not applied here. Versions
before 1.0 printed this statistic as "Kruskal stress-1" with those
labels. Substantive interpretability of the dimensions should drive the
choice of dimensionality.

## References

Hubert, L., & Arabie, P. (1985). Comparing partitions. *Journal of
Classification, 2*(1), 193–218.
[doi:10.1007/BF01908075](https://doi.org/10.1007/BF01908075)

Kruskal, J. B. (1964). Multidimensional scaling by optimizing goodness
of fit to a nonmetric hypothesis. *Psychometrika, 29*(1), 1–27.
[doi:10.1007/BF02289565](https://doi.org/10.1007/BF02289565)

Sireci, S. G., & Geisinger, K. F. (1992). Analyzing test content using
cluster analysis and multidimensional scaling. *Applied Psychological
Measurement, 16*(1), 17–31.
[doi:10.1177/014662169201600102](https://doi.org/10.1177/014662169201600102)

Sireci, S. G., & Geisinger, K. F. (1995). Using subject-matter experts
to assess content representation: An MDS analysis. *Applied
Psychological Measurement, 19*(3), 241–255.
[doi:10.1177/014662169501900303](https://doi.org/10.1177/014662169501900303)

## See also

[`similarity_from_sort()`](https://juhalt.github.io/contentvalidR/reference/similarity_from_sort.md)
to derive similarities from an item-sort task, and
[`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md)
for the combined coverage-and-structure workflow.

## Examples

``` r
# Mean similarity ratings (1 = unlike, 5 = alike) for nine items written
# for three blueprint cells.
items <- paste0("I", 1:9)
blueprint <- rep(c("Autonomy", "Competence", "Relatedness"), each = 3)
sim <- matrix(c(
  5, 4, 3, 2, 2, 1, 1, 2, 1,
  4, 5, 4, 3, 1, 2, 2, 1, 1,
  3, 4, 5, 1, 2, 2, 1, 1, 3,
  2, 3, 1, 5, 4, 3, 2, 2, 1,
  2, 1, 2, 4, 5, 4, 1, 3, 2,
  1, 2, 2, 3, 4, 5, 2, 1, 2,
  1, 2, 1, 2, 1, 2, 5, 3, 4,
  2, 1, 1, 2, 3, 1, 3, 5, 4,
  1, 1, 3, 1, 2, 2, 4, 4, 5
), 9, 9, dimnames = list(items, items))
content_structure(sim, membership = blueprint)
#> <contentvalid_structure> Content structure from expert similarity
#> Items: 9 | Dimensions retained: 2 | Clusters: 3
#> Status: Supported (criterion: adjusted Rand index >= .60, a contentvalidR
#>   convention)
#> Expert-perceived item groupings correspond to the blueprint (adjusted Rand
#> index 1.00, where 0 is chance agreement and 1 is exact; at or above the .60
#> set for this analysis). This supports the claim that the blueprint describes
#> the domain as subject-matter experts see it.
#> 
#> Fit by dimensionality
#>   Dimensions  GOF  Distortion
#>            1  .29         .45
#>            2  .50         .24
#>            3  .65         .20
#>            4  .79         .25
#> 
#>   GOF: goodness of fit from classical scaling, the share of the sum of the
#>   absolute eigenvalues that the retained dimensions account for. Distortion:
#>   how far the map's distances depart from the dissimilarities (0 is an exact
#>   map); it need not fall as dimensions are added. It is not Kruskal's
#>   stress-1, so his benchmarks do not apply.
#> 
#> Blueprint cell by recovered cluster (counts of items)
#>   Blueprint    Cluster: 1  Cluster: 2  Cluster: 3
#>   Autonomy              3           0           0
#>   Competence            0           3           0
#>   Relatedness           0           0           3
#> 
#>   Adjusted Rand index: 1.00
#> 
#> The clusters come from the item coordinates on the 2 retained dimensions
#> (average linkage), so they change with the number of dimensions. Choose that
#> number for how interpretable the dimensions are.
#> 
#> See plot(x) for the content map.
```

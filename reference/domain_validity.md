# Analyze content-domain coverage and structure

Answers two questions that item-level relevance indices cannot: whether
the item set actually spans the intended content domain, and whether
experts perceive the items as grouping the way the blueprint says they
should.

Coverage is assessed against a blueprint, or table of specifications:
the cells of the domain the instrument is meant to represent. Cells with
no items, or too few, are content gaps that no amount of item-level
relevance evidence will reveal, because an item can only be rated if it
exists.

Structure is assessed with the multidimensional scaling and cluster
analysis procedure of Sireci and Geisinger (1992), and is run when
expert similarity data is supplied. See
[`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md).

## Usage

``` r
domain_validity(
  assignments,
  item_col = "item",
  cell_col = "cell",
  facet_col = NULL,
  domain = NULL,
  min_items = 2,
  over_factor = 2,
  targets = NULL,
  similarity = NULL,
  ...
)
```

## Arguments

- assignments:

  A data frame mapping items to blueprint cells.

- item_col:

  Column naming each item.

- cell_col:

  Column naming each item's blueprint cell, typically the construct or
  content area.

- facet_col:

  Optional second column. When supplied, cells are the crossing of
  `cell_col` and `facet_col`, as in a construct-by-facet table of
  specifications.

- domain:

  Optional character vector of every cell the blueprint intends to
  cover. Supplying it is what makes **empty** cells detectable; without
  it only the cells that already contain items can be reported.

- min_items:

  Fewest items a cell may hold before it is flagged as thinly covered.

- over_factor:

  A cell holding more than this multiple of its expected share is
  flagged as over-represented. This is an attention-drawing heuristic,
  not a standard.

- targets:

  Optional named numeric vector giving the intended number of items per
  cell. When supplied, expected shares come from it rather than from an
  assumption of equal cells.

- similarity:

  Optional square item-by-item expert similarity matrix. When supplied,
  the content-structure analysis is run and reported alongside coverage.

- ...:

  Further arguments passed to
  [`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md).

## Value

An object of class `contentvalid_domain` and `contentvalid_workflow`.
`results` has **one row per blueprint cell**. `details$structure` holds
the content-structure analysis when similarity data was supplied.

## What coverage evidence can and cannot establish

A fully covered blueprint shows that items exist for every intended
cell. It does not show that those items are good ones, that the
blueprint itself is the right description of the domain, or that the
cells are equally important. Coverage is evidence about the item set's
reach, and is properly read alongside item-level relevance evidence and
expert judgement about the blueprint itself.

## References

Sireci, S. G. (1998). The construct of content validity. *Social
Indicators Research, 45*(1-3), 83-117.
[doi:10.1023/A:1006985528729](https://doi.org/10.1023/A%3A1006985528729)

Sireci, S. G., & Geisinger, K. F. (1992). Analyzing test content using
cluster analysis and multidimensional scaling. *Applied Psychological
Measurement, 16*(1), 17-31.
[doi:10.1177/014662169201600102](https://doi.org/10.1177/014662169201600102)

Rovinelli, R. J., & Hambleton, R. K. (1977). On the use of content
specialists in the assessment of criterion-referenced test item
validity. *Dutch Journal of Educational Research, 2*, 49-60.

## See also

[`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md),
[`similarity_from_sort()`](https://juhalt.github.io/contentvalidR/reference/similarity_from_sort.md),
[`ioc()`](https://juhalt.github.io/contentvalidR/reference/ioc.md).

## Examples

``` r
assignments <- data.frame(
  item = paste0("I", 1:7),
  construct = c("Autonomy", "Autonomy", "Autonomy", "Autonomy",
                "Competence", "Competence", "Relatedness")
)
domain_validity(
  assignments,
  cell_col = "construct",
  domain = c("Autonomy", "Competence", "Relatedness", "Belonging")
)
#> Content-domain coverage
#> Items: 7   Blueprint cells: 4
#> Covered: 1   Not covered: 1   Thin: 1   Over-represented: 1
#> 
#> Cells
#>         cell n_items share   recommendation
#>     Autonomy       4   57% Over-represented
#>   Competence       2   29%          Covered
#>  Relatedness       1   14%   Thinly covered
#>    Belonging       0    0%      Not covered
#> 
#> What these columns mean
#>   share -- Share of items. Percentage of all items that fall in this
#>       blueprint cell. (0 to 100%)
#> 
#> What the cell labels mean
#>   Covered -- the cell met the coverage criteria set for this analysis.
#>   Thinly covered -- fewer items than the minimum you set. Over-represented
#>   -- a larger share of the instrument than expected. Not covered -- the
#>   blueprint intends this cell but no item addresses it.
#> 
#> See `contentvalid_glossary()` for all terms, or set 
#> `options(contentvalidR.show_key = FALSE)` to hide this key.
#> 
#> Coverage shows that items exist for each cell. It does not show that 
#> those items are good ones, or that the blueprint is the right 
#> description of the domain.
```

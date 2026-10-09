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

Structure is assessed with a multidimensional scaling and cluster
analysis adapted from Sireci and Geisinger (1992, 1995), run when expert
similarity data is supplied. See
[`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md)
for what differs from their procedure.

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
  it only the cells that already contain items, or that `targets` names,
  can be reported.

- min_items:

  Fewest items a cell may hold before it is flagged as thinly covered.
  With `targets`, a cell is compared with the smaller of `min_items` and
  its own target, so a cell the blueprint gives one item is not thin
  with one.

- over_factor:

  A cell holding more than this multiple of its expected share is
  flagged as over-represented. With `targets`, a cell holding less than
  its expected share divided by `over_factor` is flagged as
  under-represented. This is an attention-drawing heuristic, not a
  standard. With few cells no share can exceed the multiple (two equal
  cells at the default of 2), and the printout says so.

- targets:

  Optional named numeric vector giving the intended number of items per
  cell. When supplied, expected shares come from it rather than from an
  assumption of equal cells, and cells far below their intended share
  are flagged. Without it under-representation is not judged, because an
  equal share is an assumption, not a blueprint. A cell named in
  `targets` is part of the blueprint, so it is reported (as not covered)
  even when no item is assigned to it. With `domain`, every cell
  `targets` names must be in `domain`. A fractional target is rounded up
  where it sets the thin-coverage floor.

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
[`print()`](https://rdrr.io/r/base/print.html) and
[`summary()`](https://rdrr.io/r/base/summary.html) are described in
[contentvalid-methods](https://juhalt.github.io/contentvalidR/reference/contentvalid-methods.md).

**Results columns.**

- `cell`:

  The blueprint cell; with `facet_col`, the two labels joined by
  `" / "`.

- `n_items`:

  Items assigned to the cell.

- `share`:

  `n_items` as a share of all the items.

- `target_items`:

  The cell's entry in `targets`; `NA` without `targets`.

- `expected_share`:

  The cell's share of `targets`, or one over the number of cells without
  them.

- `recommendation`:

  `"Covered"`, `"Not covered"` (no item), `"Thinly covered"` (below the
  floor `min_items` sets), `"Over-represented"`, or
  `"Under-represented"` (judged only against `targets`).

- `status`:

  The shared status: `"Supported"` for `"Covered"`, and `"Review"`
  otherwise.

- `interpretation`:

  The decision explained in a sentence.

## What coverage evidence can and cannot establish

A fully covered blueprint shows that items exist for every intended
cell. It does not show that those items are good ones, that the
blueprint itself is the right description of the domain, or that the
cells are equally important. Coverage is evidence about the item set's
reach, and is properly read alongside item-level relevance evidence and
expert judgment about the blueprint itself.

The coverage tally itself (`min_items`, `over_factor`, `targets`) is
this package's blueprint check, not a published index: it counts items
per cell and draws attention to cells that are empty, thin, or out of
proportion. Sireci (1998) discusses why domain representation belongs in
a content-validity argument alongside item relevance.

## References

Sireci, S. G. (1998). The construct of content validity. *Social
Indicators Research, 45*(1–3), 83–117.
[doi:10.1023/A:1006985528729](https://doi.org/10.1023/A%3A1006985528729)

Sireci, S. G., & Geisinger, K. F. (1992). Analyzing test content using
cluster analysis and multidimensional scaling. *Applied Psychological
Measurement, 16*(1), 17–31.
[doi:10.1177/014662169201600102](https://doi.org/10.1177/014662169201600102)

Sireci, S. G., & Geisinger, K. F. (1995). Using subject-matter experts
to assess content representation: An MDS analysis. *Applied
Psychological Measurement, 19*(3), 241–255.
[doi:10.1177/014662169501900303](https://doi.org/10.1177/014662169501900303)

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
#> <contentvalid_domain> Content-domain coverage
#> Items: 7 | Blueprint cells: 4
#> Criteria: at least 2 items per cell, and no cell above 2 times its expected
#> share (an equal share when no `targets` are given). These criteria are
#> contentvalidR conventions, not published standards.
#> 
#> 1 of 4 cells meets the coverage criteria.
#> Flagged for review: Autonomy (Over-represented), Relatedness (Thinly covered),
#> Belonging (Not covered)
#> 
#> Cells
#>   Cell         Decision          Items  Share  Expected
#>   Autonomy     Over-represented      4    57%       25%
#>   Competence   Covered               2    29%       25%
#>   Relatedness  Thinly covered        1    14%       25%
#>   Belonging    Not covered           0     0%       25%
#> 
#> What these columns mean
#>   Share -- Share of items. Percentage of all items in this cell.
#> 
#> What the decisions mean
#>   Covered -- met the coverage criteria.
#>   Thinly covered -- fewer items than the minimum set for this analysis.
#>   Over-represented -- more than `over_factor` times its expected share of the
#>       items.
#>   Not covered -- the blueprint includes it, but no item addresses it.
#> 
#>   Full definitions: contentvalid_glossary(). To hide this key:
#>   options(contentvalidR.show_key = FALSE).
#> 
#> Coverage shows that items exist for each cell. It does not show that those
#> items are good ones, or that the blueprint is the right description of the
#> domain.
#> 
#> See summary(x) for the cells needing attention.
```

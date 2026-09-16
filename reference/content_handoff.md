# Carry content-validity decisions into empirical validation

Packages the item decisions from a finished content-validity workflow so
they can be carried into an empirical scale-development workflow without
retyping item names or losing the record of why each item was kept.

The result holds the item names that survived content review, the
construct each belongs to where the design defines one, a per-item
evidence table, the statistics behind each decision, and the provenance
of the analysis. It is plain data, so a downstream package can read it
without contentvalidR being installed.

## Usage

``` r
content_handoff(fit, keep = "Supported", round = 1)
```

## Arguments

- fit:

  A fitted `contentvalid_sort`, `contentvalid_rating`, or
  `contentvalid_expert` object.

- keep:

  Statuses that travel forward, defaulting to `"Supported"`. Any of
  `"Supported"`, `"Review"`, `"Insufficient data"`, or
  `"Descriptive only"`.

- round:

  Pretest round this analysis represents. One fit is one round, so this
  defaults to `1` and matters only when stacking rounds by hand.

## Value

An object of class `contentvalid_handoff`, `cv_handoff`, and `list`, as
described under "Object shape".

## Details

Item-level workflows are accepted:
[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md),
[`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md),
and
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md).
[`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
and
[`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md)
are refused, because their rows are judges and blueprint cells rather
than items, so there is no item set to carry forward.

Items that do not meet `keep` are not dropped from the record. They stay
in `item_evidence` with `carried = FALSE`, so a reader can see what was
held back and why. Review is not deletion.

## Object shape (schema version 1)

The object has class `c("contentvalid_handoff", "cv_handoff", "list")`.
A consumer matches on `"cv_handoff"` and reads these fields:

- `items`:

  character vector of the carried item names, that is
  `item_evidence$item[item_evidence$carried]`, unique and in results
  order.

- `scales`:

  named list mapping each construct to its carried items, or `NULL` when
  the design has no construct mapping. Expert relevance and essentiality
  rate a single item set with no construct column, so they produce
  `NULL`. Membership is one to one.

- `item_evidence`:

  data frame with one row per reviewed item: `item`, `scale` (`NA`
  without a construct mapping), `carried`, `status`, `recommendation`,
  `n_judges`, `rule`, and `round`.

- `item_statistics`:

  data frame, one row per item per statistic: `item`, `statistic`,
  `value`, and `criterion` (`NA` when the method sets no explicit
  criterion).

- `provenance`:

  list with `schema_version`, `package`, `package_version`, `workflow`,
  `mode`, `keep`, `method`, `citation`, `settings`, `design`, and
  `created`.

This shape is agreed with the `nomologR` package, which consumes it in
`nomo_screen()` and `nomo_run()`. Neither package depends on the other.

## What a handoff does and does not establish

Surviving content review is evidence about relevance, representation,
and expert judgment. It does not establish that an item will behave well
empirically. An item can be clearly relevant and still correlate poorly
with its construct or load on an unintended factor. That is what the
downstream empirical analysis tests, which is why the item set travels
with its evidence rather than as a bare list of names.

## See also

[`as.data.frame.contentvalid_workflow()`](https://juhalt.github.io/contentvalidR/reference/as.data.frame.contentvalid_workflow.md)
for the full results table, and
[`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
for manuscript tables.

## Examples

``` r
relevance <- matrix(
  c(4,4,4,3, 4,4,3,4, 3,4,4,4, 2,2,1,2),
  nrow = 4,
  dimnames = list(NULL, paste0("Item", 1:4))
)
fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
                       agreement = "none")
handoff <- content_handoff(fit)
handoff
#> contentvalidR handoff (schema version 1)
#> --------------------------------------
#> Workflow: expert-panel (relevance)   contentvalidR 0.4.0   2026-09-16
#> Items carried forward: 3 of 4
#> Carried when status is: Supported
#> Constructs: none in this design; the panel rated one item set.
#> 
#> Held back:
#>   item status recommendation
#>  Item4 Review         Review
#> 
#> Carry these items into the empirical workflow once response data are
#> collected. In nomologR that is nomo_screen(data, items = <handoff>), which
#> screens the same items you retained here.
#> 
#> Surviving content review is evidence about relevance, representation, and
#> expert judgment. It does not establish that an item will behave well
#> empirically: an item can be clearly relevant and still correlate poorly
#> with its construct or load on an unintended factor. Items held back are
#> listed above rather than deleted, so the record stays complete.
#> 
handoff$items
#> [1] "Item1" "Item2" "Item3"
handoff$item_evidence
#>    item scale carried    status recommendation n_judges
#> 1 Item1  <NA>    TRUE Supported Strong support        4
#> 2 Item2  <NA>    TRUE Supported Strong support        4
#> 3 Item3  <NA>    TRUE Supported Strong support        4
#> 4 Item4  <NA>   FALSE    Review         Review        4
#>                                                                                               rule
#> 1 I-CVI >= 1 (common panel-size guideline for 4 experts); modified kappa > 0.74 for strong support
#> 2 I-CVI >= 1 (common panel-size guideline for 4 experts); modified kappa > 0.74 for strong support
#> 3 I-CVI >= 1 (common panel-size guideline for 4 experts); modified kappa > 0.74 for strong support
#> 4 I-CVI >= 1 (common panel-size guideline for 4 experts); modified kappa > 0.74 for strong support
#>   round
#> 1     1
#> 2     1
#> 3     1
#> 4     1
handoff$item_statistics
#>     item      statistic       value criterion round
#> 1  Item1      Aiken's V  0.91666667        NA     1
#> 2  Item2      Aiken's V  0.91666667        NA     1
#> 3  Item3      Aiken's V  0.91666667        NA     1
#> 4  Item4      Aiken's V  0.25000000        NA     1
#> 5  Item1          I-CVI  1.00000000      1.00     1
#> 6  Item2          I-CVI  1.00000000      1.00     1
#> 7  Item3          I-CVI  1.00000000      1.00     1
#> 8  Item4          I-CVI  0.00000000      1.00     1
#> 9  Item1 modified kappa  1.00000000      0.74     1
#> 10 Item2 modified kappa  1.00000000      0.74     1
#> 11 Item3 modified kappa  1.00000000      0.74     1
#> 12 Item4 modified kappa -0.06666667      0.74     1

# Carry items flagged for review as well, when the study protocol says so.
content_handoff(fit, keep = c("Supported", "Review"))$items
#> [1] "Item1" "Item2" "Item3" "Item4"
```

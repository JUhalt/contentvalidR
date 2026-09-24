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
content_handoff(
  fit,
  keep = "Supported",
  round = 1,
  reverse_keyed = NULL,
  response_scale = NULL
)
```

## Arguments

- fit:

  A fitted `contentvalid_sort`, `contentvalid_rating`,
  `contentvalid_expert`, or `contentvalid_delphi` object.

- keep:

  Statuses that travel forward, defaulting to `"Supported"`. Any of
  `"Supported"`, `"Review"`, `"Insufficient data"`, or
  `"Descriptive only"`.

- round:

  Pretest round this analysis represents. One fit is one round, so this
  defaults to `1` and matters only when stacking rounds by hand. It
  cannot be set for a Delphi fit, which dates each item by the round it
  settled in.

- reverse_keyed:

  Names of the reverse-worded items, `character(0)` if none is, or
  `NULL` (the default) to leave keying unrecorded. See "Instrument
  metadata".

- response_scale:

  The lowest and highest answer respondents can give, such as `c(1, 5)`,
  or `NULL` (the default) to leave it unrecorded. This is the scale of
  the instrument, not the scale the panel rated on.

## Value

An object of class `contentvalid_handoff`, `cv_handoff`, and `list`, as
described under "Object shape".

## Details

Item-level workflows are accepted:
[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md),
[`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md),
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md),
and
[`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md).
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
  `n_judges`, `rule`, and `round`. For a Delphi handoff `round` differs
  between items; see "A Delphi handoff". From contentvalidR 0.7.0 it
  also carries `keying`, `response_min`, and `response_max`, described
  under "Instrument metadata".

- `item_statistics`:

  data frame, one row per item per statistic: `item`, `statistic`,
  `value`, `criterion` (`NA` when the method sets no explicit
  criterion), and `round`. Which statistics carry a criterion depends on
  the workflow rather than on the statistic alone: modified kappa
  carries 0.74 from
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md),
  and none from a Delphi handoff, which decides on the consensus
  threshold. From contentvalidR 0.7.0 it also carries `note`, described
  under "The note column". From contentvalidR 0.5.0 it also carries
  `lower`, `upper`, `interval_method`, and `interval_level`, described
  under "Intervals".

- `provenance`:

  list with `schema_version`, `package`, `package_version`, `workflow`,
  `mode`, `keep`, `method`, `citation`, `settings`, `design`, and
  `created`.

- `panel_statistics`:

  added in contentvalidR 0.5.0. Data frame of panel-level statistics,
  with the same columns as `item_statistics` less `item`, including
  `note` from 0.7.0. It holds the panel agreement coefficient when
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  computed one, and has zero rows otherwise.

This shape is agreed with the `nomologR` package, which consumes it in
`nomo_screen()` and `nomo_run()`. Neither package depends on the other.
Fields and columns added within schema version 1 are optional for a
reader, which should check that they are present rather than assume it.

## What version 1 freezes

Schema version 1 is frozen as of contentvalidR 0.7.0. Code that reads a
handoff can rely on all of the following, in every release that reports
`schema_version = 1`:

- The six top-level fields above, under those names.

- In `item_evidence`: `item`, `scale`, `carried`, `status`,
  `recommendation`, `n_judges`, `rule`, `round`, `keying`,
  `response_min`, `response_max`.

- In `item_statistics`: `item`, `statistic`, `value`, `criterion`,
  `round`, `lower`, `upper`, `interval_method`, `interval_level`,
  `note`.

- In `panel_statistics`: the same columns less `item`.

- In `provenance`: `schema_version`, `package`, `package_version`,
  `workflow`, `mode`, `keep`, `method`, `citation`, `settings`,
  `design`, `created`.

Each of those columns keeps its name, its position, and its type. Every
handoff carries every column, including when a workflow has nothing to
put in one: a statistic with no interval carries `NA` in the four
interval columns rather than dropping them, and a workflow with no panel
coefficient returns a zero-row `panel_statistics` with the full set of
columns. A reader can therefore bind handoffs from different workflows
without reconciling their columns.

These are deliberately **not** frozen, and a reader should not depend on
them:

- The set of rows. Which items, which statistics, and how many of each
  depend on the workflow and on the data.

- The values in the `statistic` column. They are labels for display, and
  may be reworded in a minor release; match on the workflow in
  `provenance` instead.

- The text in `note`, `rule`, `recommendation`, and `citation`, which is
  prose for a human reader.

- The contents of `settings` and `design`, which mirror the fitted
  object and grow with it.

Neither is the printed output part of the schema.
[`print()`](https://rdrr.io/r/base/print.html) on a handoff is written
for a person, and its layout and wording may change in any release. Read
the fields.

New optional fields and columns may still be added within version 1, at
the end of a data frame or list. A reader written against this section
keeps working when that happens, provided it addresses columns by name.

## If the schema ever changes

Renaming a field, removing one, changing a type, or changing what a
field means is a version 2 change, not a minor release. It would raise
`provenance$schema_version` to `2L`, and version 1 would keep being
produced for at least one full release cycle so that readers have a
version to fall back on. The release notes would say what moved.

A reader should gate on the version rather than on the contentvalidR
version:

    if (!inherits(h, "cv_handoff") || h$provenance$schema_version != 1L) {
      stop("this reader understands handoff schema version 1 only")
    }

No version 2 is planned.

## The note column

Added in contentvalidR 0.7.0 to `item_statistics` and
`panel_statistics`. It says why a value or interval is absent or
degenerate, in the producing function's own words, so a reader need not
re-derive method-specific semantics. For example, a Delphi stability row
may carry "Kappa is undefined: every rating fell in the same category in
both rounds."

Its contract, agreed with the `nomologR` maintainers:

- It is **display text only**. Never match on it, branch on it, or parse
  it. Its wording may change in any minor release without a schema
  change.

- It is always a character vector with **no `NA`**. `""` means there is
  nothing to say, not that something is missing, so a row can carry a
  value and an empty note.

- It **never replaces the values**. Whether a statistic is undefined,
  and which of the two cases applies, stays readable from `value` and
  `proportion unchanged` as described under "When a stability statistic
  is NA". That inference is the supported way to decide anything.

- Objects from contentvalidR 0.6.0 and earlier have no such column, and
  a reader should treat its absence as every note being empty.

## Intervals

Each statistic's interval travels with it, so a reader can tell a
unanimous four-judge panel from a unanimous twenty-judge one. `lower`
and `upper` are the bounds, `interval_method` names the method, and
`interval_level` is the confidence level, for example `0.95`.

- Aiken's V: the Penfield-Giacobbi score interval.

- I-CVI and Psa: the method chosen with `proportion_ci`, the Wilson
  score interval by default.

- Panel agreement: the item-resampling percentile bootstrap of
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md).

The four columns are `NA` together when a statistic has no interval.
That happens when the method defines none (Csv, HTC, HTD, CVR, the
essential count, modified kappa, IOC, and p-values), when intervals were
switched off with `proportion_ci = "none"`, or when the statistic itself
could not be computed. `NA` there never stands for missing data.

The handoff reports intervals only. It does not turn them into priors or
weights for a later analysis; that is a question for the consuming
package.

## A Delphi handoff

A Delphi study settles one item at a time: an item that reached
consensus early was set aside, and its last round came before the
study's final round. A Delphi handoff therefore carries each item's
evidence **from its own last round**, and `round` holds that round's
index rather than one constant. It is the only workflow where `round`
varies within a handoff.

Each item carries the relevance evidence of its last round, taken from
that round's
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
fit, with intervals: `I-CVI` against the consensus threshold,
`Aiken's V`, and `modified kappa`. Modified kappa carries no criterion
here, because a Delphi decides on the consensus threshold rather than on
the 0.74 rule that
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
applies.

Two more statistics record whether the panel had stopped moving:
`proportion unchanged`, and the stability statistic that ran, named for
its method, such as `weighted kappa (quadratic)` or
`Goodman-Kruskal lambda`. The chi-square methods add `stability p_value`
against `alpha`. Stability travels as evidence beside the decision; it
never decides what is carried, exactly as it never sets an item's status
in
[`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md).

## When a stability statistic is NA

A stability row is always present for a carried item, so an `NA` there
is a statement about the data rather than a missing record. There are
two cases, and they can be told apart from the object alone:

- `proportion unchanged` is also `NA`:

  The item has no pair of consecutive rounds: it was rated in one round
  only, so there was nothing to compare.

- `proportion unchanged` has a value:

  A pair exists, but the statistic is undefined for that data.

In the second case, **read `proportion unchanged`**, which is often the
more informative number. An undefined kappa beside
`proportion unchanged` of 1 is perfect stability that kappa cannot
express: kappa is chance-corrected, and when every paired rating in both
rounds falls in one category, the disagreement expected by chance is
zero, so kappa is 0/0. Reporting only "not estimable" there would
describe a defect that does not exist. Goodman- Kruskal lambda is
undefined when the later round is unanimous, and the chi-square methods
are undefined for a table with fewer than two occupied rows or columns.

[`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md)
states the reason in `details$stability$note`, and from contentvalidR
0.7.0 the handoff carries that sentence in the `note` column of
`item_statistics`, described under "The note column".

## Instrument metadata

Added in contentvalidR 0.7.0, at the request of the `nomologR`
maintainers, because two empirical computations cannot be done correctly
without them.

- `keying` is `1` for a forward-worded item, `-1` for a reverse-worded
  one, and `NA` when nobody said. An even-odd consistency index must
  recode reverse-worded items before splitting the scale, or a perfectly
  consistent respondent looks careless. And a negative corrected
  item-total correlation means opposite things in the two cases: on an
  item that was never recoded it is a coding error, and on a correctly
  coded item it is evidence against the item.

- `response_min` and `response_max` are the lowest and highest answers a
  respondent can give. Screening for out-of-range answers needs the
  scale's limits rather than the observed ones, because a category
  nobody used is still a legal answer, and long-string and within-person
  variability indices mean different things on a two-point and a
  seven-point scale.

**Both come from the analyst, never from the fit.** A content-validity
panel rates relevance or correspondence on its own scale, usually 1 to
4, which is not the scale respondents will answer the items on. Copying
a fit's `lo` and `hi` into `response_min` and `response_max` would give
a downstream reader the wrong limits, and it would then reject every
legitimate top-category answer. So both default to `NA`, which means
*unknown*, and a reader should treat `NA` that way rather than assume a
forward-worded item or an observed range.

Supplying `reverse_keyed` is a statement about every item: the ones
named are reverse-worded and the rest are not. Pass `character(0)` to
record that you checked and none is. So `keying` is either `NA` for
every item or for none of them, and the same holds for the response
scale.

Naming a reverse-worded item without `response_scale` gives a warning,
because such an item cannot be recoded without the scale's limits. A
reader that recodes would otherwise have to refuse later, where the
problem is harder to fix.

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
#> Workflow: expert-panel (relevance)   contentvalidR 0.7.0.9000   2026-09-24
#> Items carried forward: 3 of 4
#> Carried when status is: Supported
#> Constructs: none in this design; the panel rated one item set.
#> Intervals carried: Aiken's V (Penfield-Giacobbi score, 95%); I-CVI (Wilson
#>   score, 95%)
#> 
#> Held back:
#>   item status recommendation
#>  Item4 Review         Review
#> 
#> Carry these items into the empirical workflow once response data are
#> collected. In nomologR that is nomo_screen(data, items = handoff$items),
#> which screens the same items you retained here.
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
#>   round keying response_min response_max
#> 1     1     NA           NA           NA
#> 2     1     NA           NA           NA
#> 3     1     NA           NA           NA
#> 4     1     NA           NA           NA
handoff$item_statistics
#>     item      statistic       value criterion round      lower     upper
#> 1  Item1      Aiken's V  0.91666667        NA     1 0.64612009 0.9851349
#> 2  Item2      Aiken's V  0.91666667        NA     1 0.64612009 0.9851349
#> 3  Item3      Aiken's V  0.91666667        NA     1 0.64612009 0.9851349
#> 4  Item4      Aiken's V  0.25000000        NA     1 0.08894167 0.5323053
#> 5  Item1          I-CVI  1.00000000      1.00     1 0.51010916 1.0000000
#> 6  Item2          I-CVI  1.00000000      1.00     1 0.51010916 1.0000000
#> 7  Item3          I-CVI  1.00000000      1.00     1 0.51010916 1.0000000
#> 8  Item4          I-CVI  0.00000000      1.00     1 0.00000000 0.4898908
#> 9  Item1 modified kappa  1.00000000      0.74     1         NA        NA
#> 10 Item2 modified kappa  1.00000000      0.74     1         NA        NA
#> 11 Item3 modified kappa  1.00000000      0.74     1         NA        NA
#> 12 Item4 modified kappa -0.06666667      0.74     1         NA        NA
#>            interval_method interval_level note
#> 1  Penfield-Giacobbi score           0.95     
#> 2  Penfield-Giacobbi score           0.95     
#> 3  Penfield-Giacobbi score           0.95     
#> 4  Penfield-Giacobbi score           0.95     
#> 5             Wilson score           0.95     
#> 6             Wilson score           0.95     
#> 7             Wilson score           0.95     
#> 8             Wilson score           0.95     
#> 9                     <NA>             NA     
#> 10                    <NA>             NA     
#> 11                    <NA>             NA     
#> 12                    <NA>             NA     

# Carry items flagged for review as well, when the study protocol says so.
content_handoff(fit, keep = c("Supported", "Review"))$items
#> [1] "Item1" "Item2" "Item3" "Item4"
```

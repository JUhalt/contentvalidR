# Compare content-validity evidence across pretest rounds

Compares two or more fitted workflow objects from successive rounds of
the same pretest, reporting which items changed status, which held
steady, and which entered or left the item set.

Scale development is iterative: items get revised and re-tested. The
risk in reporting that process is attributing a status change to
improved items when it actually came from a changed decision rule, a
different panel size, or a different criterion. This function makes that
distinction visible by comparing the `settings` of each round alongside
its results, and flagging rounds whose analysis settings differ.

## Usage

``` r
compare_rounds(..., labels = NULL)
```

## Arguments

- ...:

  Two or more fitted workflow objects, in round order. All must come
  from the same workflow, since status labels from different workflows
  rest on different criteria and are not comparable.

- labels:

  Optional round labels. Defaults to `Round 1`, `Round 2`, and so on, or
  to the names supplied in `...`.

## Value

An object of class `contentvalid_rounds`, a list containing:

- transitions:

  One row per unit, with its status in each round and the direction of
  any change.

- summary:

  Counts of stable, improved, weakened, added, and removed units for
  each consecutive pair of rounds.

- settings_changes:

  Analysis settings that differ between consecutive rounds, which is the
  audit trail for whether a status change can be read as an evidence
  change at all.

- comparable:

  `FALSE` when any consecutive pair differs in settings.

## Reading a comparison

A status change means the evidence crossed a criterion, not that an item
improved by a measurable amount. An item can move from `Review` to
`Supported` on a small change in one judge's rating if it was sitting
near the boundary. Read the transitions together with the underlying
index values in each round's own results.

When `comparable` is `FALSE`, the rounds were analyzed under different
rules, and a status change may reflect only that. Re-analyze the earlier
round under the current settings before reporting a change as progress.

## See also

[`reproducibility_phi()`](https://juhalt.github.io/contentvalidR/reference/reproducibility_phi.md)
for agreement between two independent judge samples analyzed under
identical settings.

## Examples

``` r
round1 <- data.frame(
  item = rep(c("I1", "I2"), each = 6),
  rater = rep(1:6, times = 2),
  assigned_construct = c(rep("A", 5), "B", rep("A", 3), rep("B", 3)),
  target_construct = "A",
  stringsAsFactors = FALSE
)
round2 <- round1
round2$assigned_construct <- c(rep("A", 6), rep("A", 5), "B")
compare_rounds(sort_validity(round1), sort_validity(round2))
#> contentvalidR comparison across pretest rounds
#> ----------------------------------------------
#> Workflow: item-sort | Rounds: 2 | Units compared: 2
#> 
#> Status by round
#>  item Round 1   Round 2       change
#>    I1  Review Supported Strengthened
#>    I2  Review    Review    Unchanged
#> 
#> Round-to-round summary
#>     from      to compared unchanged stronger weaker added removed same settings
#>  Round 1 Round 2        2         1        1      0     0       0           yes
#> 
#> Settings were identical across rounds, so these transitions can be read as
#> changes in evidence.
#> 
#> A status change means the evidence crossed a criterion, not that an item
#> improved by a measurable amount. An item sitting near a boundary can move on
#> a very small change. Read transitions alongside each round's index values.
```

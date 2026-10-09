# Compare content-validity evidence across pretest rounds

Compares two or more fitted workflow objects from successive rounds of
the same pretest, reporting which items changed status, which held
steady, and which entered or left the item set.

Scale development is iterative: items get revised and re-tested. The
risk in reporting that process is attributing a status change to
improved items when it actually came from a changed decision rule, a
different panel size, or a different criterion. This function makes that
distinction visible by comparing the `settings` of each round alongside
its results and flagging rounds that differ. For the item sort and for
expert relevance and essentiality it compares the panel size too,
because the exact tests and Lynn's criterion depend on the number of
judges: 5 of 6 does not meet the item-sort criterion, while the same
share, 10 of 12, does. Where the rule is a fixed share or cut, as in a
Delphi fit, the panel size is not compared: the criterion did not move.

## Usage

``` r
compare_rounds(..., labels = NULL)
```

## Arguments

- ...:

  Two or more fitted workflow objects, in round order. All must come
  from the same workflow, and from the same mode of
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md),
  since status labels from different workflows rest on different
  criteria and are not comparable. Name them to label the rounds:
  `compare_rounds(pilot = f1, revised = f2)`.

- labels:

  Optional round labels. Defaults to the names supplied in `...` when
  every round is named, and otherwise to `Round 1`, `Round 2`, and so
  on, with a warning when only some rounds were named. A label cannot be
  the name of the unit column (`item`, `judge` or `cell`) or `change`.

## Value

An object of class `contentvalid_rounds`, a list containing:

- transitions:

  One row per unit, with its status in each round and, in `change`, how
  its status in the last round compares with the first: `Unchanged`,
  `Strengthened`, `Weakened`, `Changed` (to or from `Descriptive only`,
  which is neither stronger nor weaker), `Added`, `Removed`, or
  `Not in first or last` for a unit present only in the rounds between.
  A unit that changed and changed back reads `Unchanged`; the round
  columns show the path.

- summary:

  For each consecutive pair of rounds, the units compared (present in
  both) and how they split: unchanged, strengthened, weakened, and
  otherwise changed (`n_changed`, to or from `Descriptive only`), which
  add up to `n_compared`; and the units added and removed.

- settings_changes:

  Analysis settings that differ between consecutive rounds, and a
  changed panel size, which is the audit trail for whether a status
  change can be read as an evidence change at all. The values are text;
  a proportion (`alpha`, `consensus_threshold`, `ioc_cut`, `p0`) is
  written as APA writes it, `.05` or `.75`.

- comparable:

  `FALSE` when any consecutive pair differs in settings or, where the
  criterion depends on it, in panel size. The seed and the number of
  bootstrap resamples are ignored, because they cannot change a status.

- panel_compared:

  Whether the panel size was part of the comparison: `TRUE` for the item
  sort and for expert relevance and essentiality.

- mode:

  The mode of
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  fits, `NA` for other workflows.

## Reading a comparison

A status change means the evidence crossed a criterion, not that an item
improved by a measurable amount. An item can move from `Review` to
`Supported` on a small change in one judge's rating if it was sitting
near the boundary. Read the transitions together with the underlying
index values in each round's own results.

When `comparable` is `FALSE`, the rounds were analyzed under different
rules, and a status change may reflect only that. Where a setting
differs, re-analyze the earlier round under the current settings before
reporting a change as progress. Where the panel size differs, compare
the index values themselves, since the criterion moved with the panel.

The fits in `delphi_validity()$details$round_fits` are relevance fits,
so comparing them reads each round against Lynn's I-CVI criterion, not
against the consensus threshold of the Delphi.

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
#> <contentvalid_rounds> Comparison across pretest rounds
#> Workflow: item-sort | Rounds: 2 | Units compared: 2
#> 
#> Of the 2 units present in the first and last rounds, 1 changed status (1
#> stronger, 0 weaker).
#> Status uses the words shared with nomologR: Supported is this analysis's
#> passing decision (Retain), and Review marks an item to look at again, not to
#> delete.
#> 
#> Status by round
#>   Item  Round 1  Round 2    First to last
#>   I1    Review   Supported  Strengthened
#>   I2    Review   Review     Unchanged
#> 
#> Round-to-round summary
#>   From    To      Compared Unchanged Stronger Weaker Added Removed Same rule
#>   Round 1 Round 2        2         1        1      0     0       0 yes
#> 
#>   The settings and the panel size were the same in every round, so these
#>   transitions can be read as changes in evidence.
#> 
#> A status change means the evidence crossed a criterion, not that an item
#> improved by a measurable amount. An item sitting near a boundary can move on a
#> very small change. Read transitions alongside each round's index values.
#> 
#> See summary(x) for the units whose status changed.
```

# Index of item-objective congruence (IOC)

Computes the index of item-objective congruence of Rovinelli and
Hambleton (1977) from expert ratings coded `+1` (the item clearly
measures the objective), `0` (unclear), and `-1` (it clearly does not).
Each judge rates each item against every objective, and the index asks
whether the item was matched to one objective **and not to the others**.

For item \\k\\ and objective \\i\\, with \\N\\ objectives and \\n\\
judges, \$\$I\_{ik} = \frac{(N - 1) \sum_j X\_{ijk} - \sum\_{l \ne i}
\sum_j X\_{ljk}}{2 (N - 1) n},\$\$ which is half the difference between
the judges' mean rating on the objective and their mean rating on the
item's other objectives. It is `+1` only when every judge gives `+1` on
the objective and `-1` on every other, and `.50` when every judge gives
`+1` on the objective and `0` on the others. Rovinelli and Hambleton
applied a criterion of .70 to it.

`mean_rating` is the judges' mean rating on the objective alone. Applied
work often reports that mean as "the IOC" (the sum of the ratings over
the number of experts). It is an ingredient of the index, not the index:
it reaches 1 whenever every judge gives `+1` on that objective, whatever
they say about the others. Versions of this package before 1.0 returned
it in the `ioc` column.

Duplicate item-judge-objective ratings are rejected. Missing ratings may
be removed cellwise with transparent effective judge counts; the index
is then computed from the cell means, which is the same formula when no
rating is missing. The formula of Rovinelli and Hambleton assumes every
judge rated every objective, so this handling of missing ratings is this
package's own: each objective's mean counts once, however many judges
rated it, and an objective no judge rated is left out of the item's
comparison. Pooling every rating on the other objectives instead would
give a different index.

## Usage

``` r
ioc(ratings, na.rm = FALSE)
```

## Arguments

- ratings:

  Data frame with columns `item`, `judge`, `objective`, `score`.

- na.rm:

  Logical. If `FALSE`, missing scores are an error; if `TRUE`, missing
  scores are removed within item-objective cells.

## Value

A data.frame with one row for each item and objective: `item`,
`objective`, `n_total` (rows), `n_judges` (usable ratings), `n_missing`,
`mean_rating` (the judges' mean rating on the objective, -1 to 1),
`n_objectives` (objectives the item has usable ratings on), and `ioc`,
the index. `ioc` is `NA` for an item rated against a single objective,
because the index compares objectives. Items and objectives keep the
order of the data. It prints as a formatted table in APA style; the
values themselves are unrounded, and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the plain data frame.

## References

Rovinelli, R. J., & Hambleton, R. K. (1977). On the use of content
specialists in the assessment of criterion-referenced test item
validity. *Dutch Journal of Educational Research, 2*, 49–60.

## Examples

``` r
df <- data.frame(
  item = rep("I1", 6),
  judge = rep(1:3, 2),
  objective = rep(c("A", "B"), each = 3),
  score = c(1,1,1, 0,-1,0)
)
ioc(df)
#> Index of item-objective congruence (IOC; Rovinelli & Hambleton, 1977)
#> 
#>  item objective judges mean  IOC
#>    I1         A      3 1.00  .67
#>    I1         B      3 -.33 -.67
#> 
#> mean: the judges' mean rating on the objective (-1 to 1). IOC: half the gap
#> between that mean and their mean on the item's other objectives; 1 only when
#> every judge rates +1 on the objective and -1 on every other. Rovinelli and
#> Hambleton applied a criterion of .70.
```

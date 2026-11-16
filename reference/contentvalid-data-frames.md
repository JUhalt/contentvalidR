# Tables from contentvalidR results

[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns a
result's table as an ordinary data frame, for filtering, joining, or
writing to a file. A result that holds several tables returns the one
named by `component`; a single test returns one row. Fitted workflows
have their own method,
[`as.data.frame.contentvalid_workflow()`](https://juhalt.github.io/contentvalidR/reference/as.data.frame.contentvalid_workflow.md).

## Usage

``` r
# S3 method for class 'contentvalid_cvi'
as.data.frame(x, row.names = NULL, optional = FALSE, component = NULL, ...)

# S3 method for class 'contentvalid_gtheory'
as.data.frame(x, row.names = NULL, optional = FALSE, component = NULL, ...)

# S3 method for class 'contentvalid_structure'
as.data.frame(x, row.names = NULL, optional = FALSE, component = NULL, ...)

# S3 method for class 'contentvalid_rounds'
as.data.frame(x, row.names = NULL, optional = FALSE, component = NULL, ...)

# S3 method for class 'contentvalid_handoff'
as.data.frame(x, row.names = NULL, optional = FALSE, component = NULL, ...)

# S3 method for class 'contentvalid_sort_power'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'contentvalid_expert_power'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'contentvalid_agreement'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'contentvalid_binom'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'contentvalid_signal'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'contentvalid_reproducibility'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  A contentvalidR result.

- row.names, optional:

  Accepted for compatibility with
  [`base::as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
  and ignored.

- component:

  The table to return, where a result holds more than one (`NULL`, the
  default, gives the first listed):

  - [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md):
    `"item_level"` (default) or `"scale_level"`.

  - [`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md):
    `"variance_components"` (default), `"coefficients"`, `"dstudy"`, or
    `"judges_needed"`.

  - [`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md):
    `"items"` (default; each item's cluster, blueprint cell and
    coordinates), `"fit"`, or `"cross_tab"`.

  - [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md):
    `"transitions"` (default), `"summary"`, or `"settings_changes"`.

  - [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md):
    `"item_evidence"` (default), `"item_statistics"`, or
    `"panel_statistics"`.

- ...:

  Not used.

## Value

A data frame.
[`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md),
[`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md),
[`reproducibility_phi()`](https://juhalt.github.io/contentvalidR/reference/reproducibility_phi.md)
and
[`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
give one row: an interval becomes two columns, and a two-by-two table
becomes its four counts. For
[`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
the interval's error rate is `ci_alpha`, since `alpha` would read as
Krippendorff's; for
[`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md)
the one-sided interval is marked by `ci_sides` and `ci_level`.

## Interval columns

Where a result carries an interval, its lower and upper bound are two
numeric columns. Their names depend on the result, for historical
reasons. The names are stable, and none will be renamed to match
another.

|  |  |  |
|----|----|----|
| Result | Where | Lower, upper |
| [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md) | `results` | `psa_low`, `psa_high` |
| [`compute_psa()`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md) | its data frame | `psa_low`, `psa_high` |
| [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md) | `results` (Aiken's V) | `ci_low`, `ci_high` |
| [`aikens_v()`](https://juhalt.github.io/contentvalidR/reference/aikens_v.md) | its data frame | `ci_low`, `ci_high` |
| [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md) | `as.data.frame(x)` | `ci_low`, `ci_high` |
| [`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md) | `as.data.frame(x)` | `ci_low`, `ci_high` |
| [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md) | `results` (I-CVI) | `I_CVI_low`, `I_CVI_high` |
| [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) | `item_level` | `I_CVI_low`, `I_CVI_high` |
| [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md) | `scale_summary` | `agreement_low`, `agreement_high` |
| [`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md) | `results` | `stability_low`, `stability_high` |
| [`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md) | `details$stability` | `lower`, `upper` |
| [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md) | `item_statistics` | `lower`, `upper` |
| [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md) | `panel_statistics` | `lower`, `upper` |
| [`content_evidence()`](https://juhalt.github.io/contentvalidR/reference/content_evidence.md) | `evidence` | `lower`, `upper` |

The
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
rows are those of relevance mode, the one mode with intervals. The list
that
[`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
returns holds `ci_low` and `ci_high` under the same names, and the list
that
[`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md)
returns holds both bounds in `conf.int`.
[`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
is formatted for a manuscript, so it writes each interval as one column
of text; take the numbers from the fit.

The confidence level and the interval method are recorded with each
result, though not in the same place:

- A workflow keeps them in `settings`. The level of every interval in
  the fit is `1 - settings$alpha`. The method is
  `settings$proportion_ci` for Psa and the I-CVI, and the `ci_method`
  column of `results` for Aiken's V. Panel agreement and the Delphi
  weighted kappa have percentile bootstrap intervals, from
  `settings$agreement_B` and `settings$B` resamples.

- [`compute_psa()`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md),
  [`aikens_v()`](https://juhalt.github.io/contentvalidR/reference/aikens_v.md),
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md),
  and
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
  use the `alpha` they were called with, so the level is one minus that
  `alpha`.
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) and
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
  also return it as `alpha`, which is `ci_alpha` in the data frame of
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md).
  The method is the `ci` of the call:
  [`aikens_v()`](https://juhalt.github.io/contentvalidR/reference/aikens_v.md)
  names it in its `ci_method` column and
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md)
  returns it as `ci`.
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
  has one method, a percentile bootstrap.

- The data frame of
  [`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md)
  gives the level as `ci_level`, and its `ci_sides` says that the
  interval is one-sided.

- A handoff states both beside each interval, in the `interval_level`
  and `interval_method` columns of its two statistics tables; a row with
  no interval has `NA` in both.
  [`content_evidence()`](https://juhalt.github.io/contentvalidR/reference/content_evidence.md)
  copies the level into `level`, and leaves the method in each stage's
  handoff, in `stages`.

## Examples

``` r
R <- matrix(c(4, 3, 4, 4, 3, 4, 2, 3, 4, 4, 3, 2), 6,
            dimnames = list(NULL, c("I1", "I2")))
as.data.frame(cvi(R >= 3))
#>   item A N     I_CVI I_CVI_low I_CVI_high       Pc kappa_mod
#> 1   I1 6 6 1.0000000 0.6096657  1.0000000 0.015625 1.0000000
#> 2   I2 4 6 0.6666667 0.2999933  0.9032286 0.234375 0.5646259
as.data.frame(cvi(R >= 3), component = "scale_level")
#>   S_CVI_Ave S_CVI_UA n_items
#> 1 0.8333333      0.5       2
as.data.frame(csv_binom_test(16, 20))
#>       p.value estimate    ci_low ci_high critical_n_target passes_chance
#> 1 0.005908966      0.8 0.5989719       1                15          TRUE
#>      decision                               interpretation n_target  N  p0
#> 1 significant Target assignments meet the exact criterion.       16 20 0.5
#>   alpha  ci_sides ci_level
#> 1  0.05 one-sided     0.95
```

# Agreement summary (auxiliary)

Computes Fleiss' kappa via 'irr' if available. This is an auxiliary
compatibility helper, not part of the recommended contentvalidR
workflows.

## Usage

``` r
agreement_summary(ratings)
```

## Arguments

- ratings:

  matrix/data.frame: rows = items, cols = raters (nominal categories)

## Value

list with results, or a message if 'irr' is not installed

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

When 'irr' is installed, the result of
[`irr::kappam.fleiss()`](https://rdrr.io/pkg/irr/man/kappam.fleiss.html).
Otherwise a list with `ok = FALSE` and a `message`, after a message
explaining how to install 'irr'.

## See also

[`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
for panel-level agreement with an evidence-based default coefficient and
a bootstrap interval.

## Examples

``` r
ratings <- data.frame(
  rater1 = c("A", "B", "A", "C"),
  rater2 = c("A", "B", "B", "C"),
  rater3 = c("A", "B", "A", "C")
)
if (requireNamespace("irr", quietly = TRUE)) {
  agreement_summary(ratings)
}
#>  Fleiss' Kappa for m Raters
#> 
#>  Subjects = 4 
#>    Raters = 3 
#>     Kappa = 0.745 
#> 
#>         z = 3.61 
#>   p-value = 0.000308 
```

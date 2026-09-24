# Agreement summary (auxiliary)

Computes Fleiss' (1971) kappa, the extension of Cohen's kappa to many
raters, by calling
[`irr::kappam.fleiss()`](https://rdrr.io/pkg/irr/man/kappam.fleiss.html)
from the irr package (Gamer, Lemon, Fellows, & Singh, 2026) when it is
installed. This is an auxiliary compatibility helper, not part of the
recommended contentvalidR workflows.

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

## References

Fleiss, J. L. (1971). Measuring nominal scale agreement among many
raters. *Psychological Bulletin, 76*(5), 378-382.
[doi:10.1037/h0031619](https://doi.org/10.1037/h0031619)

Gamer, M., Lemon, J., Fellows, I., & Singh, P. (2026). *irr: Various
coefficients of interrater reliability and agreement* (R package version
0.85).
[doi:10.32614/CRAN.package.irr](https://doi.org/10.32614/CRAN.package.irr)

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

# Between-pretest reproducibility (phi) of binary decisions

Auxiliary compatibility diagnostic. Cross-tabulates retention decisions
for the same items across two pretests and reports signed phi and
Pearson's chi-square test without Yates correction. The full 2 x 2 table
is retained even when one response level is absent.

## Usage

``` r
reproducibility_phi(sig1, sig2)
```

## Arguments

- sig1:

  Logical vector of retention decisions from pretest 1.

- sig2:

  Logical vector of retention decisions from pretest 2.

## Value

A list containing the 2 x 2 table, signed phi, chi-square, and p-value.

## Examples

``` r
sig1 <- c(TRUE, TRUE, FALSE, FALSE)
sig2 <- c(TRUE, FALSE, FALSE, TRUE)
reproducibility_phi(sig1, sig2)
#> $table
#>               Pretest2
#> Pretest1       Retain Not retained
#>   Retain            1            1
#>   Not retained      1            1
#> 
#> $phi
#> [1] 0
#> 
#> $chisq
#> [1] 0
#> 
#> $p
#> [1] 1
#> 
```

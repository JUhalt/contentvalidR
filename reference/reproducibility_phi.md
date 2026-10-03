# Between-pretest reproducibility (phi) of binary decisions

Auxiliary compatibility diagnostic. Cross-tabulates retention decisions
for the same items across two pretests and reports signed phi with a
test of association: Pearson's chi-square test without Yates correction,
or Fisher's exact test when an expected count is below 5, where the
chi-square approximation is unreliable. Pretests compare a handful of
items, so the exact test is the usual case. The full 2 x 2 table is
retained even when one response level is absent.

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

A list containing the 2 x 2 table (`table`), signed `phi`, the
chi-square statistic (`chisq`), the number of items (`n`), and `p` with
the test it comes from in `p_method`: `"chi-square"`, or
`"Fisher's exact test"` when an expected count is below 5. `p_chisq`
always holds the chi-square *p* value. It prints as a short report in
APA style; the elements themselves are unrounded.

## Examples

``` r
sig1 <- c(TRUE, TRUE, FALSE, FALSE)
sig2 <- c(TRUE, FALSE, FALSE, TRUE)
reproducibility_phi(sig1, sig2)
#> Retention decisions in two pretests
#> 
#>               Pretest2
#> Pretest1       Retain Not retained
#>   Retain            1            1
#>   Not retained      1            1
#> 
#> phi = .00, Fisher's exact p = 1.000.
#> An expected count is below 5, so the exact test is reported in place of the
#> chi-square approximation (chi-square(1, N = 4) = 0.00, p = 1.000).
```

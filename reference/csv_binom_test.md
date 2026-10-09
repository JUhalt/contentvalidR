# Exact item-sort significance test

Tests whether the number of assignments to an item's intended construct
exceeds the count expected under a binomial model with null probability
`p0`. With the default `p0 = 0.5`, this implements the Howard and Melloy
(2016) retention test for item-sort tasks by testing the
target-assignment count directly. Unlike the legacy critical-Csv
procedure, the count-based test remains applicable when respondents
choose among more than two construct alternatives.

The function name is retained for backward compatibility even though the
inferential test is performed on `n_c`, not on the observed Csv value.

## Usage

``` r
csv_binom_test(n_c, N, p0 = 0.5, alpha = 0.05)
```

## Arguments

- n_c:

  Integer; number of non-missing assignments to the target construct.

- N:

  Integer; total number of non-missing assignments for the item.

- p0:

  Null target-assignment probability. Default `0.5`, following Howard
  and Melloy (2016); see Details.

- alpha:

  Significance level. Default `0.05`. A *p* equal to `alpha` meets the
  criterion; see Details.

## Value

A list containing the exact *p* value, observed target proportion,
one-sided confidence interval at level `1 - alpha`, the minimum critical
target count, a logical `passes_chance` flag (`TRUE` when the count
meets the exact criterion), a backward-compatible `decision` label, and
a plain-language `interpretation`. The inputs are returned too, as
`n_target`, `N`, `p0`, and `alpha`. It prints as a short report in APA
style; the elements themselves are unrounded.

## Details

`p0` is the null probability that a judge assigns the item to its
intended construct. It is not the rate expected from random assignment,
which is 1 divided by the number of constructs offered. Howard and
Melloy (2016) describe .5 as arbitrary and lenient, kept because earlier
work used it, and suggest a higher value such as .6 or .75, chosen
before data collection, when the alternative constructs are clearly
different from the target or the judges are subject-matter experts.

The criterion is met when the exact *p* is at or below `alpha`, so a *p*
equal to `alpha` counts as meeting it, and `critical_n_target` is the
fewest target assignments whose *p* is at or below `alpha`. A strict
"below `alpha`" gives the same decision unless a tail probability equals
`alpha` exactly, which cannot happen at `p0 = 0.5` and `alpha = 0.05`:
every tail probability is then a multiple of 1 / 2^N.

With very few judges no count can reach `alpha`: at `p0 = 0.5` and
`alpha = 0.05`, four judges who all choose the target give *p* = .0625.
`critical_n_target` is then `NA`, and the printout says so.

## References

Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task
methods: The presentation of a new statistical significance formula and
methodological best practices. *Journal of Business and Psychology,
31*(1), 173–186.
[doi:10.1007/s10869-015-9404-y](https://doi.org/10.1007/s10869-015-9404-y)

## Examples

``` r
csv_binom_test(n_c = 15, N = 20)
#> <contentvalid_binom> Howard-Melloy exact test (one-sided)
#> 
#> The item meets the exact target-assignment criterion.
#> 15 of 20 judges assigned the item to its target construct (Psa = .75). If each
#> judge chose the target with probability p0 = .50, a count this high has
#> probability p = .021.
#> At alpha = .05 an item needs at least 15 of 20.
#> One-sided 95% CI for the target rate: [.54, 1.00].
#> 
#> See as.data.frame(x) for the test as one row.
csv_binom_test(n_c = 14, N = 20)
#> <contentvalid_binom> Howard-Melloy exact test (one-sided)
#> 
#> The item does not meet the exact target-assignment criterion.
#> 14 of 20 judges assigned the item to its target construct (Psa = .70). If each
#> judge chose the target with probability p0 = .50, a count this high has
#> probability p = .058.
#> At alpha = .05 an item needs at least 15 of 20.
#> One-sided 95% CI for the target rate: [.49, 1.00].
#> 
#> See as.data.frame(x) for the test as one row.
```

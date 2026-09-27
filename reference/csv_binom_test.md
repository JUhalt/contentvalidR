# Exact item-sort significance test

Tests whether the number of assignments to an item's intended construct
exceeds the count expected under a binomial chance model. With the
default `p0 = 0.5`, this implements the Howard and Melloy (2016)
retention test for item-sort tasks by testing the target-assignment
count directly. Unlike the legacy critical-Csv procedure, the
count-based test remains applicable when respondents choose among more
than two construct alternatives.

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
  and Melloy (2016).

- alpha:

  Significance level. Default `0.05`.

## Value

A list containing the exact p-value, observed target proportion,
one-sided confidence interval, the minimum critical target count, a
logical `passes_chance` flag, a backward-compatible `decision` label,
and a plain-language `interpretation`. The inputs are returned too, as
`n_target`, `N`, `p0`, and `alpha`. It prints as a short report in APA
style; the elements themselves are unrounded.

## References

Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task
methods: The presentation of a new statistical significance formula and
methodological best practices. *Journal of Business and Psychology,
31*(1), 173–186.
[doi:10.1007/s10869-015-9404-y](https://doi.org/10.1007/s10869-015-9404-y)

## Examples

``` r
csv_binom_test(n_c = 15, N = 20)
#> Howard-Melloy exact test (one-tailed)
#> 
#> 15 of 20 judges assigned the item to its target construct (Psa = .75). If
#> judges chose the target at the rate p0 = .50, a count this high has
#> probability p = .021.
#> At alpha = .05 an item needs at least 15 of 20. Decision: significant.
#> One-sided 95% interval for the target rate: [.54, 1.00].
csv_binom_test(n_c = 14, N = 20)
#> Howard-Melloy exact test (one-tailed)
#> 
#> 14 of 20 judges assigned the item to its target construct (Psa = .70). If
#> judges chose the target at the rate p0 = .50, a count this high has
#> probability p = .058.
#> At alpha = .05 an item needs at least 15 of 20. Decision: n.s..
#> One-sided 95% interval for the target rate: [.49, 1.00].
```

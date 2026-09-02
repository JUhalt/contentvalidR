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
and a plain-language `interpretation`.

## References

Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task
methods: The presentation of a new statistical significance formula and
methodological best practices. *Journal of Business and Psychology,
31*(1), 173-186.
[doi:10.1007/s10869-015-9404-y](https://doi.org/10.1007/s10869-015-9404-y)

## Examples

``` r
csv_binom_test(n_c = 15, N = 20)
#> $p.value
#> [1] 0.02069473
#> 
#> $estimate
#> [1] 0.75
#> 
#> $conf.int
#> [1] 0.5444176 1.0000000
#> attr(,"conf.level")
#> [1] 0.95
#> 
#> $critical_n_target
#> [1] 15
#> 
#> $passes_chance
#> [1] TRUE
#> 
#> $decision
#> [1] "significant"
#> 
#> $interpretation
#> [1] "Target assignments exceed the exact chance criterion."
#> 
csv_binom_test(n_c = 14, N = 20)
#> $p.value
#> [1] 0.05765915
#> 
#> $estimate
#> [1] 0.7
#> 
#> $conf.int
#> [1] 0.4921816 1.0000000
#> attr(,"conf.level")
#> [1] 0.95
#> 
#> $critical_n_target
#> [1] 15
#> 
#> $passes_chance
#> [1] FALSE
#> 
#> $decision
#> [1] "n.s."
#> 
#> $interpretation
#> [1] "Target assignments do not exceed the exact chance criterion."
#> 
```

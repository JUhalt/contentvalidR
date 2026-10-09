# Exact power for the item-sort target-count rule

Computes the exact probability that an item will meet the target-count
criterion of Howard and Melloy (2016) for a planned judge sample size
and an assumed true target-assignment probability. This is a binomial
calculation, not a simulation.

## Usage

``` r
sort_power(N, true_p, p0 = 0.5, alpha = 0.05)
```

## Arguments

- N:

  Positive integer judge sample size(s).

- true_p:

  Assumed true probability that a judge assigns the item to its intended
  construct. May be scalar or vector.

- p0:

  Null target-assignment probability for the exact binomial test.
  Default `0.5`, following Howard and Melloy (2016). It is not the rate
  expected from random assignment, which is 1 divided by the number of
  constructs. Howard and Melloy describe .5 as arbitrary and lenient,
  and suggest a higher value such as .6 or .75, chosen before data
  collection, when the alternative constructs are clearly different from
  the target or the judges are subject-matter experts.

- alpha:

  Significance level. Default `0.05`.

## Value

An object of class `contentvalid_sort_power` containing an exact
planning table. When a panel is too small for any count to reach `alpha`
(four or fewer judges at the defaults), `critical_n_target` and
`minimum_observed_psa` are `NA` and `power` is 0: no item can be
retained at that size.

## References

Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task
methods: The presentation of a new statistical significance formula and
methodological best practices. *Journal of Business and Psychology,
31*(1), 173–186.
[doi:10.1007/s10869-015-9404-y](https://doi.org/10.1007/s10869-015-9404-y)

## Examples

``` r
sort_power(N = c(20, 30, 40), true_p = .70)
#> <contentvalid_sort_power> Item-sort planning
#> Retention rule: Howard-Melloy exact test (p0 = .50, alpha = .05)
#> 
#>   Judges  Required  Minimum Psa  Power at .70
#>       20     15/20          .75           .42
#>       30     20/30          .67           .73
#>       40     26/40          .65           .81
#> 
#> Required: target assignments an item needs to be retained. Minimum Psa: the
#> same as a proportion (Psa = proportion of substantive agreement). Power at a
#> value: the exact probability of reaching the required count if each judge
#> assigns the item to its target with that probability.
#> 
#> See plot(x) for the power curve.
sort_power(N = 30, true_p = c(.60, .70, .80))
#> <contentvalid_sort_power> Item-sort planning
#> Retention rule: Howard-Melloy exact test (p0 = .50, alpha = .05)
#> 
#>   Judges  Required  Minimum Psa  Power at .60  Power at .70  Power at .80
#>       30     20/30          .67           .29           .73           .97
#> 
#> Required: target assignments an item needs to be retained. Minimum Psa: the
#> same as a proportion (Psa = proportion of substantive agreement). Power at a
#> value: the exact probability of reaching the required count if each judge
#> assigns the item to its target with that probability.
#> 
#> See plot(x) for the power curve.
```

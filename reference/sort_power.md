# Exact power for the item-sort target-count rule

Computes the exact probability that an item will meet the Howard-Melloy
target-count criterion for a planned judge sample size and an assumed
true target-assignment probability. This is a binomial calculation, not
a simulation.

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

  Null target-assignment probability. Default `0.5`.

- alpha:

  Significance level. Default `0.05`.

## Value

An object of class `contentvalid_sort_power` containing an exact
planning table.

## References

Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task
methods: The presentation of a new statistical significance formula and
methodological best practices. *Journal of Business and Psychology,
31*(1), 173-186.
[doi:10.1007/s10869-015-9404-y](https://doi.org/10.1007/s10869-015-9404-y)

## Examples

``` r
sort_power(N = c(20, 30, 40), true_p = .70)
#> contentvalidR item-sort planning
#> --------------------------------
#> Retention rule: Howard-Melloy exact test (p0 = .50, alpha = .05)
#> 
#>  judges required minimum Psa power at .70
#>      20    15/20         .75          .42
#>      30    20/30         .67          .73
#>      40    26/40         .65          .81
#> 
#> required: target assignments an item needs to be retained. minimum Psa: the
#> same as a proportion. power at p: the exact probability of reaching the
#> required count if each judge assigns the item to its target with probability
#> p.
sort_power(N = 30, true_p = c(.60, .70, .80))
#> contentvalidR item-sort planning
#> --------------------------------
#> Retention rule: Howard-Melloy exact test (p0 = .50, alpha = .05)
#> 
#>  judges required minimum Psa power at .60 power at .70 power at .80
#>      30    20/30         .67          .29          .73          .97
#> 
#> required: target assignments an item needs to be retained. minimum Psa: the
#> same as a proportion. power at p: the exact probability of reaching the
#> required count if each judge assigns the item to its target with probability
#> p.
```

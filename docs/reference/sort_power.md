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

## Examples

``` r
sort_power(N = c(20, 30, 40), true_p = .70)
#> Exact item-sort planning analysis
#> ---------------------------------
#> Retention rule: p0 = 0.50, alpha = 0.050
#> 
#>   N true_p critical_n_target minimum_observed_psa power
#>  20    0.7                15                0.750 0.416
#>  30    0.7                20                0.667 0.730
#>  40    0.7                26                0.650 0.807
#> 
#> Power is the exact probability of reaching the required target-assignment count
#> under the assumed true target-assignment probability.
sort_power(N = 30, true_p = c(.60, .70, .80))
#> Exact item-sort planning analysis
#> ---------------------------------
#> Retention rule: p0 = 0.50, alpha = 0.050
#> 
#>   N true_p critical_n_target minimum_observed_psa power
#>  30    0.6                20                0.667 0.291
#>  30    0.7                20                0.667 0.730
#>  30    0.8                20                0.667 0.974
#> 
#> Power is the exact probability of reaching the required target-assignment count
#> under the assumed true target-assignment probability.
```

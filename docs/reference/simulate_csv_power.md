# Legacy simulation of item-sort target-count power

Auxiliary compatibility helper. For supported exact planning, prefer
[`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md),
which does not require Monte Carlo simulation.

## Usage

``` r
simulate_csv_power(N = 20, true_p = 0.65, reps = 2000, alpha = 0.05)
```

## Arguments

- N:

  Number of judges per item.

- true_p:

  True assignment probability to the target construct.

- reps:

  Number of simulation replications.

- alpha:

  Significance level.

## Value

Estimated power (a number between 0 and 1).

## Examples

``` r
simulate_csv_power(N = 20, true_p = 0.65, reps = 100, alpha = 0.05)
#> [1] 0.31
```

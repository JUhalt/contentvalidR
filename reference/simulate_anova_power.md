# Legacy independent-groups ANOVA power simulator

Simulates a balanced **independent-groups** one-way ANOVA. This helper
is retained for backward compatibility but does not represent the
standard within-judge Hinkin-Tracey design used by
[`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md).
It is an auxiliary compatibility helper and is not a release-defining
workflow.

## Usage

``` r
simulate_anova_power(
  n_raters = 30,
  mean_diff = 0.6,
  sd = 1,
  k_constructs = 5,
  reps = 1000,
  alpha = 0.05
)
```

## Arguments

- n_raters:

  Number of raters per construct (balanced).

- mean_diff:

  Target mean minus other-construct means.

- sd:

  Within-cell standard deviation.

- k_constructs:

  Number of constructs.

- reps:

  Number of simulation replications.

- alpha:

  Significance level.

## Value

Estimated power (numeric in \[0, 1\]).

## Examples

``` r
simulate_anova_power(n_raters = 20, mean_diff = 0.5, sd = 1, k_constructs = 4, reps = 100)
#> [1] 0.4
```

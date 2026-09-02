# Interpret a statistic using Colquitt et al. (2019) norms

Classifies one or more Psa, Csv, HTC, or HTD values using the empirical
percentile bands from Colquitt et al. (2019). These norms were derived
from scale-level averages and from naive judges representative of
substantive study populations. They should therefore be treated as
contextual norms, not pass/fail rules.

When `judge_type = "expert"`, the Colquitt classification is
deliberately not applied because the authors caution against using their
norms for expert judges.

## Usage

``` r
interpret_colquitt(
  value,
  statistic = c("psa", "csv", "htc", "htd"),
  orbiting_r = NULL,
  judge_type = c("naive", "expert")
)
```

## Arguments

- value:

  Numeric value(s) to interpret.

- statistic:

  One of `"psa"`, `"csv"`, `"htc"`, or `"htd"`.

- orbiting_r:

  Optional scalar, or a vector matching `value`, containing the average
  focal-orbiting correlation. `NULL` uses the overall norms.

- judge_type:

  Either `"naive"` or `"expert"`.

## Value

A data.frame with the value, benchmark set, interpretation, and an
applicability flag.

## References

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
*Journal of Applied Psychology, 104*(10), 1243-1265.
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406)

## Examples

``` r
interpret_colquitt(.84, "psa")
#>   statistic value benchmark_set                  benchmark_label interpretation
#> 1       psa  0.84       overall Overall (not correlation-normed)         Strong
#>   applicable
#> 1       TRUE
#>                                                                           note
#> 1 Empirical percentile norm from scale-level averages; not a universal cutoff.
interpret_colquitt(.70, "csv", orbiting_r = .40)
#>   statistic value benchmark_set
#> 1       csv   0.7      moderate
#>                                      benchmark_label interpretation applicable
#> 1 More moderate focal-orbiting correlation (.35-.50)         Strong       TRUE
#>                                                                           note
#> 1 Empirical percentile norm from scale-level averages; not a universal cutoff.
```

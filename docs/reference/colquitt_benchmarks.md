# Colquitt et al. (2019) empirical content-validation benchmarks

Returns the empirical interpretation bands proposed by Colquitt et al.
(2019) for Psa, Csv, HTC, or HTD. The benchmarks were created from
scale-level averages for 112 scales and are percentile-based norms, not
universal psychometric cutoffs.

If `orbiting_r` is supplied, the correlation-conditional benchmark set
is selected. Otherwise the overall, non-correlation-normed criteria are
used.

The published table contains a few rounded boundary overlaps/gaps. This
implementation treats each printed lower bound as the start of its
category and assigns categories from strongest to weakest, yielding
deterministic interpretation at rounded boundaries.

## Usage

``` r
colquitt_benchmarks(
  statistic = c("psa", "csv", "htc", "htd"),
  orbiting_r = NULL
)
```

## Arguments

- statistic:

  One of `"psa"`, `"csv"`, `"htc"`, or `"htd"`.

- orbiting_r:

  Optional average correlation between the focal scale and its orbiting
  scales.

## Value

A data.frame describing the selected benchmark set and its lower
cutpoints.

## References

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243-1265.
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406)

## Examples

``` r
colquitt_benchmarks("psa")
#>   statistic benchmark_set                  benchmark_label interpretation
#> 1       psa       overall Overall (not correlation-normed)    Very Strong
#> 2       psa       overall Overall (not correlation-normed)         Strong
#> 3       psa       overall Overall (not correlation-normed)       Moderate
#> 4       psa       overall Overall (not correlation-normed)           Weak
#> 5       psa       overall Overall (not correlation-normed)        Lack of
#>   percentile minimum
#> 1  80th-99th    0.91
#> 2  60th-79th    0.82
#> 3  40th-59th    0.72
#> 4  20th-39th    0.39
#> 5   0th-19th    -Inf
colquitt_benchmarks("csv", orbiting_r = .40)
#>   statistic benchmark_set                                    benchmark_label
#> 1       csv      moderate More moderate focal-orbiting correlation (.35-.50)
#> 2       csv      moderate More moderate focal-orbiting correlation (.35-.50)
#> 3       csv      moderate More moderate focal-orbiting correlation (.35-.50)
#> 4       csv      moderate More moderate focal-orbiting correlation (.35-.50)
#> 5       csv      moderate More moderate focal-orbiting correlation (.35-.50)
#>   interpretation percentile minimum
#> 1    Very Strong  80th-99th    0.83
#> 2         Strong  60th-79th    0.61
#> 3       Moderate  40th-59th    0.52
#> 4           Weak  20th-39th    0.01
#> 5        Lack of   0th-19th    -Inf
```

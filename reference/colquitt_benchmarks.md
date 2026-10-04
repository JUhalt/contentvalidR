# Colquitt et al. (2019) empirical content-validation benchmarks

Returns the empirical interpretation bands proposed by Colquitt et al.
(2019) for Psa, Csv, HTC, or HTD. The benchmarks were created from
scale-level averages for 112 scales and are percentile-based norms, not
universal psychometric cutoffs.

Colquitt et al. (2019) built these norms from tasks in which naive
judges saw three definitions, the focal construct and two orbiting
constructs, and either sorted each item into one of them (Psa, Csv) or
rated it against each on a 7-point scale (HTC, HTD). They did not
examine tasks offering more or fewer definitions.
[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
and
[`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
therefore add a caution, this package's own, when a study offers a
different number.

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
cutpoints. It prints as a formatted table in APA style; the values
themselves are unrounded, and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the plain data frame.

## References

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243–1265.
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406)

## Examples

``` r
colquitt_benchmarks("psa")
#> <contentvalid_colquitt_norms> Benchmarks for Psa (Colquitt et al., 2019): Overall (not correlation-normed)
#> 
#>   Band         Percentile  Minimum
#>   Very Strong  80th-99th       .91
#>   Strong       60th-79th       .82
#>   Moderate     40th-59th       .72
#>   Weak         20th-39th       .39
#>   Lack of      0th-19th       none
#> 
#> A scale-level mean at or above a band's minimum falls in that band. The bands
#> are percentiles of published scales, not validity cutoffs.
#> 
#> See as.data.frame(x) for the unrounded values.
colquitt_benchmarks("csv", orbiting_r = .40)
#> <contentvalid_colquitt_norms> Benchmarks for Csv (Colquitt et al., 2019): More moderate focal-orbiting correlation (.35-.50)
#> 
#>   Band         Percentile  Minimum
#>   Very Strong  80th-99th       .83
#>   Strong       60th-79th       .61
#>   Moderate     40th-59th       .52
#>   Weak         20th-39th       .01
#>   Lack of      0th-19th       none
#> 
#> A scale-level mean at or above a band's minimum falls in that band. The bands
#> are percentiles of published scales, not validity cutoffs.
#> 
#> See as.data.frame(x) for the unrounded values.
```

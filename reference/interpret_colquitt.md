# Interpret a statistic using Colquitt et al. (2019) norms

Classifies one or more Psa, Csv, HTC, or HTD values using the empirical
percentile bands from Colquitt et al. (2019). These norms were derived
from scale-level averages and from naive judges representative of
substantive study populations. They should therefore be treated as
contextual norms, not pass/fail rules.

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
applicability flag. It prints as a formatted table in APA style; the
values themselves are unrounded, and
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
interpret_colquitt(.84, "psa")
#> Benchmark bands (Colquitt et al., 2019)
#> 
#>  statistic value   band                       benchmarks
#>        Psa   .84 Strong Overall (not correlation-normed)
#> 
#> Empirical percentile norm from scale-level averages; not a universal cutoff.
interpret_colquitt(.70, "csv", orbiting_r = .40)
#> Benchmark bands (Colquitt et al., 2019)
#> 
#>  statistic value   band                                         benchmarks
#>        Csv   .70 Strong More moderate focal-orbiting correlation (.35-.50)
#> 
#> Empirical percentile norm from scale-level averages; not a universal cutoff.
```

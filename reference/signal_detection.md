# Signal-detection summary for binary retention decisions

Auxiliary compatibility diagnostic. Compares a logical vector of pretest
retention decisions with a logical ground-truth criterion (for example,
later CFA retention). Reports a correctly oriented confusion matrix,
accuracy, sensitivity, specificity, signed phi, and Pearson's chi-square
test without Yates correction.

The comparison follows the validation design of Anderson and Gerbing
(1991), who checked pretest assessments of items' substantive validity
against how those items later performed in a confirmatory factor
analysis.

## Usage

``` r
signal_detection(predicted, actual)
```

## Arguments

- predicted:

  Logical vector of predicted retention decisions.

- actual:

  Logical vector of criterion retention decisions.

## Value

A list containing the confusion matrix and diagnostic statistics.

## References

Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
measures in a confirmatory factor analysis with a pretest assessment of
their substantive validities. *Journal of Applied Psychology, 76*(5),
732-740.
[doi:10.1037/0021-9010.76.5.732](https://doi.org/10.1037/0021-9010.76.5.732)

## Examples

``` r
predicted <- c(TRUE, TRUE, FALSE, FALSE)
actual    <- c(TRUE, FALSE, TRUE, FALSE)
signal_detection(predicted, actual)
#> $confusion
#>               Actual
#> Predicted      Retain Not retained
#>   Retain            1            1
#>   Not retained      1            1
#> 
#> $accuracy
#> [1] 0.5
#> 
#> $sensitivity
#> [1] 0.5
#> 
#> $specificity
#> [1] 0.5
#> 
#> $phi
#> [1] 0
#> 
#> $chisq
#> [1] 0
#> 
#> $p
#> [1] 1
#> 
```

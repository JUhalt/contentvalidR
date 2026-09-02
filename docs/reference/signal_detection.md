# Signal-detection summary for binary retention decisions

Auxiliary compatibility diagnostic. Compares a logical vector of pretest
retention decisions with a logical ground-truth criterion (for example,
later CFA retention). Reports a correctly oriented confusion matrix,
accuracy, sensitivity, specificity, signed phi, and Pearson's chi-square
test without Yates correction.

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

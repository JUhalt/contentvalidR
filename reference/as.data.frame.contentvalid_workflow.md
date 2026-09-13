# Extract workflow results as a plain data frame

Returns a fitted workflow's results as an ordinary data frame, so
results can be filtered, joined, or written out without scraping printed
output.

A `workflow` column is prepended so that tables from several analyses
can be stacked and stay identifiable.

## Usage

``` r
# S3 method for class 'contentvalid_workflow'
as.data.frame(
  x,
  row.names = NULL,
  optional = FALSE,
  component = c("results", "scale_summary"),
  include_interpretation = TRUE,
  ...
)
```

## Arguments

- x:

  A fitted `contentvalid_workflow` object.

- row.names, optional:

  Present for compatibility with the generic.

- component:

  Which component to return: `"results"` (the default, one row per unit
  of analysis) or `"scale_summary"`.

- include_interpretation:

  Keep the per-unit interpretation text. It is informative but long, so
  set `FALSE` for compact tables.

- ...:

  Ignored.

## Value

A data frame.

## Filtering is your decision, not the package's

There is deliberately no helper that returns "the items that passed."
Selecting on `status == "Supported"` is a substantive decision that
should appear in your own code where a reader can see it, and `Review`
never means an item must be dropped. Keeping the filter explicit keeps
that judgement visible in the analysis script and in the manuscript.

## Examples

``` r
sorts <- read.csv(
  system.file("extdata", "sort_example.csv", package = "contentvalidR"),
  stringsAsFactors = FALSE
)
fit <- sort_validity(sorts)
head(as.data.frame(fit, include_interpretation = FALSE))
#>    workflow item target n_total  n n_missing n_target competitor n_other_max
#> 1 item-sort   A1      A      20 20         0       18       B; C           1
#> 2 item-sort   A2      A      20 20         0       15          B           3
#> 3 item-sort   B1      B      20 20         0       17          A           2
#> 4 item-sort   B2      B      20 20         0       13          A           5
#> 5 item-sort   C1      C      20 20         0       18       A; B           1
#> 6 item-sort   C2      C      20 20         0       14          B           4
#>    psa  csv      p_value critical_n_target passes_chance recommendation
#> 1 0.90 0.85 0.0002012253                15          TRUE         Retain
#> 2 0.75 0.60 0.0206947327                15          TRUE         Retain
#> 3 0.85 0.75 0.0012884140                15          TRUE         Retain
#> 4 0.65 0.40 0.1315879822                15         FALSE         Review
#> 5 0.90 0.85 0.0002012253                15          TRUE         Retain
#> 6 0.70 0.50 0.0576591492                15         FALSE         Review
#>                                     issue    status
#> 1                               Supported Supported
#> 2                               Supported Supported
#> 3                               Supported Supported
#> 4 Target favored, exact criterion not met    Review
#> 5                               Supported Supported
#> 6 Target favored, exact criterion not met    Review
as.data.frame(fit, component = "scale_summary")
#>    workflow target n_items n_items_usable n_retain n_review mean_psa
#> 1 item-sort      A       2              2        2        0    0.825
#> 2 item-sort      B       2              2        1        1    0.750
#> 3 item-sort      C       2              2        1        1    0.800
#>   psa_strength mean_csv csv_strength orbiting_r
#> 1       Strong    0.725       Strong         NA
#> 2     Moderate    0.575     Moderate         NA
#> 3     Moderate    0.675       Strong         NA
#>                      benchmark_set benchmark_applicable overall_strength
#> 1 Overall (not correlation-normed)                 TRUE           Strong
#> 2 Overall (not correlation-normed)                 TRUE         Moderate
#> 3 Overall (not correlation-normed)                 TRUE         Moderate
#>                                                                                                                             evidence
#> 1                                     Strong normative standing on both definitional correspondence (Psa) and distinctiveness (Csv).
#> 2 Generally supportive normative standing, with at least one dimension in the moderate range; review weaker items before finalizing.
#> 3 Generally supportive normative standing, with at least one dimension in the moderate range; review weaker items before finalizing.
```

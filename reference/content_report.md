# Build a manuscript-ready results table

Formats a fitted workflow's results as a compact table suitable for
pasting into a manuscript or a Quarto or R Markdown document, either as
a data frame or as a Markdown table.

Markdown output is generated directly, so no reporting package is
required to use it. Nothing in the core analysis depends on one.

## Usage

``` r
content_report(
  x,
  digits = 2,
  format = c("data.frame", "markdown"),
  include = c("all", "flagged"),
  caption = NULL
)
```

## Arguments

- x:

  A fitted `contentvalid_workflow` object.

- digits:

  Digits for rounding numeric columns.

- format:

  `"data.frame"` (default) or `"markdown"`.

- include:

  `"all"` (default) or `"flagged"`, which keeps only units whose status
  is not `Supported`.

- caption:

  Optional caption line placed above a Markdown table.

## Value

A data frame, or a character vector of Markdown lines when
`format = "markdown"`. The character vector carries the analysis
provenance as its `"settings"` attribute.

## Reporting the decision rules

A results table alone is not a reproducible report. The thresholds that
produced each status live in the fitted object's `settings`, and are
attached to Markdown output as an attribute so they travel with the
table. Report them alongside it: two analyses of identical data can
disagree entirely because one used a different criterion.

## See also

[`as.data.frame.contentvalid_workflow()`](https://juhalt.github.io/contentvalidR/reference/as.data.frame.contentvalid_workflow.md)
for the untrimmed table, and
[`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
for reporting change across pretest rounds.

## Examples

``` r
sorts <- read.csv(
  system.file("extdata", "sort_example.csv", package = "contentvalidR"),
  stringsAsFactors = FALSE
)
fit <- sort_validity(sorts)
content_report(fit)
#>   item target  n n_target competitor  psa psa_low psa_high  csv p_value
#> 1   A1      A 20       18       B; C 0.90    0.70     0.97 0.85    0.00
#> 2   A2      A 20       15          B 0.75    0.53     0.89 0.60    0.02
#> 3   B1      B 20       17          A 0.85    0.64     0.95 0.75    0.00
#> 4   B2      B 20       13          A 0.65    0.43     0.82 0.40    0.13
#> 5   C1      C 20       18       A; B 0.90    0.70     0.97 0.85    0.00
#> 6   C2      C 20       14          B 0.70    0.48     0.85 0.50    0.06
#>   recommendation    status
#> 1         Retain Supported
#> 2         Retain Supported
#> 3         Retain Supported
#> 4         Review    Review
#> 5         Retain Supported
#> 6         Review    Review
cat(content_report(fit, format = "markdown", include = "flagged"), sep = "\n")
#> | item | target | n | n_target | competitor | psa | psa_low | psa_high | csv | p_value | recommendation | status |
#> | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
#> | B2 | B | 20 | 13 | A | 0.65 | 0.43 | 0.82 | 0.4 | 0.13 | Review | Review |
#> | C2 | C | 20 | 14 | B | 0.70 | 0.48 | 0.85 | 0.5 | 0.06 | Review | Review |
```

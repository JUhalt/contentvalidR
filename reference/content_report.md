# Build a manuscript-ready results table

Formats a fitted workflow's results as a compact table for a manuscript
or a Quarto or R Markdown document. By default the table is written in
APA style (7th ed.): readable column headings, two decimals, no leading
zero on values that cannot exceed 1, *p* values to three decimals or
`< .001`, and intervals as `[LL, UL]` under a heading that names their
level.

Markdown output is generated directly, so no reporting package is
required to use it. Nothing in the core analysis depends on one.

## Usage

``` r
content_report(
  x,
  digits = 2,
  format = c("apa", "data.frame", "markdown"),
  include = c("all", "flagged"),
  caption = NULL
)
```

## Arguments

- x:

  A fitted `contentvalid_workflow` object.

- digits:

  Decimal places for estimates. *p* values always get three, as APA
  requires.

- format:

  `"apa"` (default), a table of formatted text in APA style;
  `"markdown"`, the same table as Markdown lines; or `"data.frame"`, the
  selected columns as rounded numbers under their names in `results`,
  for further computation.

- include:

  `"all"` (default) or `"flagged"`, which keeps only units whose status
  is not `Supported`.

- caption:

  Optional caption line placed above a Markdown table.

## Value

For `"apa"`, a data frame of character columns that prints without row
names; [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
drops its print class. An interval column is named after its estimate
(`V 95% CI`, `I-CVI 95% CI`) and printed under the shared heading
`95% CI`. For `"data.frame"`, a plain data frame with `recommendation`
and `status` columns. For `"markdown"`, a character vector of Markdown
lines that prints as the table, carrying the analysis provenance as its
`"settings"` attribute.

## Changed in 0.9.0

The default is now `format = "apa"`. Earlier versions returned the
numeric table by default, with *p* values rounded to `digits`; use
`format = "data.frame"` for that table, where *p* values now keep three
decimals.

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
#>  item target judges competitor Psa     95% CI Csv      p decision
#>    A1      A  18/20       B; C .90 [.70, .97] .85 < .001   Retain
#>    A2      A  15/20          B .75 [.53, .89] .60   .021   Retain
#>    B1      B  17/20          A .85 [.64, .95] .75   .001   Retain
#>    B2      B  13/20          A .65 [.43, .82] .40   .132   Review
#>    C1      C  18/20       A; B .90 [.70, .97] .85 < .001   Retain
#>    C2      C  14/20          B .70 [.48, .85] .50   .058   Review
content_report(fit, format = "markdown", include = "flagged")
#> | item | target | judges | competitor | Psa | 95% CI | Csv | p | decision |
#> | --- | --- | --- | --- | --- | --- | --- | --- | --- |
#> | B2 | B | 13/20 | A | .65 | [.43, .82] | .40 | .132 | Review |
#> | C2 | C | 14/20 | B | .70 | [.48, .85] | .50 | .058 | Review |
```

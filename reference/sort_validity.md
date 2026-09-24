# Analyze an item-sort content-validity pretest

Provides the recommended user-facing workflow for item-sort studies. At
the item level, `sort_validity()` combines Anderson and Gerbing's (1991)
Psa and Csv statistics with the exact target-count significance test
recommended by Howard and Melloy (2016). Items meeting the exact
criterion are labeled `"Retain"`; items that do not meet it are labeled
`"Review"`, not automatically `"Delete"`.

At the target-scale level, Psa and Csv are averaged across items and
interpreted using the empirical percentile norms from Colquitt et al.
(2019). This mirrors how those norms were constructed. The Colquitt
categories are descriptive benchmarks rather than pass/fail rules.

## Usage

``` r
sort_validity(
  assignments,
  item_col = "item",
  rater_col = "rater",
  assigned_col = "assigned_construct",
  target_col = "target_construct",
  p0 = 0.5,
  alpha = 0.05,
  orbiting_r = NULL,
  judge_type = c("naive", "expert"),
  proportion_ci = c("wilson", "agresti_coull", "exact", "none")
)
```

## Arguments

- assignments:

  A data.frame containing item-sort responses.

- item_col, rater_col, assigned_col, target_col:

  Column names for the item, rater, assigned construct, and intended
  target construct.

- p0:

  Null target-assignment probability for the exact binomial test.
  Default `0.5`, following Howard and Melloy (2016).

- alpha:

  Significance level. Default `0.05`.

- orbiting_r:

  Optional average correlation between each focal/target scale and its
  orbiting scales. For one target, supply one correlation. For multiple
  targets, supply a named numeric vector keyed by target construct. If
  omitted, the overall Colquitt et al. norms are used.

- judge_type:

  Either `"naive"` (the Anderson-Gerbing/Colquitt design) or `"expert"`.
  Colquitt benchmark labels are not applied to expert judges.

- proportion_ci:

  Interval method for Psa: `"wilson"` (default), `"agresti_coull"`,
  `"exact"`, or `"none"`. The interval uses the same `alpha` as the
  exact test. See `ci` in
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) for
  the methods and the evidence for each.

## Value

An object of class `contentvalid_sort` and `contentvalid_workflow`. All
flagship workflow objects expose the common components `results`,
`scale_summary`, `settings`, `design`, and `details`. Item-level
`results` include a standardized `status` field while retaining the
method-specific `recommendation` field.
[`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html), and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) provide
user-facing interpretation.

## References

Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
measures in a confirmatory factor analysis with a pretest assessment of
their substantive validities. *Journal of Applied Psychology, 76*(5),
732-740.
[doi:10.1037/0021-9010.76.5.732](https://doi.org/10.1037/0021-9010.76.5.732)

Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task
methods: The presentation of a new statistical significance formula and
methodological best practices. *Journal of Business and Psychology,
31*(1), 173-186.
[doi:10.1007/s10869-015-9404-y](https://doi.org/10.1007/s10869-015-9404-y)

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243-1265.
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406)

## Examples

``` r
sort_dat <- data.frame(
  item = rep(c("A1", "A2", "A3"), each = 20),
  rater = rep(1:20, 3),
  target_construct = "A",
  assigned_construct = c(
    rep("A", 18), rep("B", 2),
    rep("A", 16), rep("B", 4),
    rep("A", 12), rep("B", 8)
  )
)
fit <- sort_validity(sort_dat)
fit
#> contentvalidR item-sort analysis
#> --------------------------------
#> Items: 3 | Judges: 20 | Target constructs: 1
#> Test: Howard-Melloy exact target-count test (p0 = .50, alpha = .05)
#> Judges: naive, meaning drawn from the kind of people who will answer the
#> items.
#> 
#> 2 of 3 items meet the exact target-assignment criterion.
#> Flagged for review: A3
#> 
#> Item-level evidence
#>  item target decision judges Psa     95% CI Csv competitor      p
#>    A1      A   Retain  18/20 .90 [.70, .97] .80          B < .001
#>    A2      A   Retain  16/20 .80 [.58, .92] .60          B   .006
#>    A3      A   Review  12/20 .60 [.39, .78] .20          B   .252
#> 
#> judges: assignments to the target construct, out of the judges who sorted the
#> item.
#> 95% intervals for proportions: Wilson score (the default). Newcombe (1998)
#> compared seven methods and recommends score intervals over the Wald interval.
#> An interval reflects how few ratings an item received, not whether the right
#> judges were chosen.
#> 
#> Scale-level Colquitt benchmarks
#>  target items mean Psa Psa level mean Csv Csv level
#>       A     3      .77  Moderate      .53  Moderate
#> Benchmark set: Overall (not correlation-normed)
#> 
#> Colquitt labels are empirical percentile norms derived from scale-level
#> averages, not universal cutoffs or automatic scale-retention rules. They
#> place a scale against published scales; Psa and Csv sit on different scales,
#> so their labels are not comparable with each other.
#> 
#> What these columns mean
#>   Psa -- Proportion of Substantive Agreement. Share of judges who assigned
#>       the item to the construct it was written for. Higher means judges
#>       recognized the item as belonging where you intended. (0 to 1; higher
#>       is stronger)
#>   95% CI -- Interval for Psa. Lower and upper limits of an interval around
#>       Psa. A wide interval means few judges sorted the item, so a different
#>       sample of judges could plausibly give a quite different Psa. (between
#>       0 and 1; the method and level are named in the output)
#>   Csv -- Coefficient of Substantive Validity. How much more often the item
#>       went to its intended construct than to the alternative construct
#>       judges chose most. It rewards being distinctly right, not merely
#>       often right. (-1 to 1; 0 means the intended construct and its closest
#>       rival were chosen equally often)
#>   competitor -- Strongest competing construct. The construct, other than
#>       the intended one, that judges chose most often for this item.
#>   p -- Howard-Melloy exact test. Probability of seeing at least this many
#>       target assignments if judges were assigning at the chance rate p0.
#>       Small values mean the item's assignment pattern is unlikely to be
#>       chance. (0 to 1; compared against alpha)
#> 
#> What the status labels mean
#>   Supported -- The evidence met the criteria set for this analysis.
#>   Review -- Something here needs a closer look. This is not an instruction
#>       to delete anything.
#>   Insufficient data -- Too little usable data to reach a judgment.
#>   Descriptive only -- Reported for description only; no decision rule was
#>       applied.
#>   Each workflow also uses its own wording in the decision column (Retain,
#>   Strong support, Typical, Covered, and so on). Those words map onto the
#>   shared statuses above.
#> 
#> See `contentvalid_glossary()` for all terms, or set
#> `options(contentvalidR.show_key = FALSE)` to hide this key.
#> 
#> 'Review' is not an automatic deletion decision. Use theory, construct-domain
#> coverage, item wording, and qualitative judge feedback alongside these
#> statistics.
summary(fit)
#> Summary: item-sort content-validity evidence
#> --------------------------------------------
#> Retain: 2 of 3 | Review: 1 of 3
#> 
#> Scale-level evidence
#>  target items retain review mean Psa Psa level mean Csv Csv level  overall
#>       A     3      2      1      .77  Moderate      .53  Moderate Moderate
#> 
#> A: Generally supportive normative standing, with at least one dimension in
#>   the moderate range; review weaker items before finalizing.
#> 
#> Items needing attention
#>  item target decision Psa Csv competitor    p
#>    A3      A   Review .60 .20          B .252
#> 
#> A3: Target favored, exact criterion not met
#> 
#> Interpret scale norms and item flags alongside theory, domain coverage, and
#> qualitative feedback. This analysis does not by itself establish
#> comprehensiveness or the full content-validity argument.
```

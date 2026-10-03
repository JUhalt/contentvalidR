# Analyze an item-sort content-validity pretest

Provides the recommended user-facing workflow for item-sort studies. At
the item level, `sort_validity()` combines Anderson and Gerbing's (1991)
Psa and Csv statistics with the exact target-count significance test
recommended by Howard and Melloy (2016). Items meeting the exact
criterion are labeled `"Retain"`; items that do not meet it are labeled
`"Review"`, not automatically `"Delete"`. An item sorted by so few
judges that no count could meet the criterion (four or fewer at the
defaults) is labeled `"Insufficient panel"`, with status
`"Insufficient data"`.

Construct and item labels are compared as text after leading and
trailing spaces are removed, so constructs may be coded as numbers, text
or factors. Results list the items in the order they first appear in the
data, or in the order of the levels when the item column is a factor.

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
  proportion_ci = c("wilson", "agresti_coull", "exact", "none"),
  legacy = FALSE,
  n_constructs = NULL
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
  Default `0.5`, following Howard and Melloy (2016). It is not the rate
  expected from random assignment, which is 1 divided by the number of
  constructs. Howard and Melloy describe .5 as arbitrary and lenient,
  and suggest a higher value such as .6 or .75, chosen before data
  collection, when the alternative constructs are clearly different from
  the target or the judges are subject-matter experts.

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
  `"exact"`, or `"none"`. The interval is two-sided at level
  `1 - alpha`, while the exact test is one-sided, so the interval of an
  item that just meets the criterion can still include `p0`. The
  decision comes from the test, not from the interval. See `ci` in
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) for
  the methods and the evidence for each.

- legacy:

  Print the earlier published rules beside the decision, for comparison.
  Default `FALSE`. They are computed either way, stored in
  `details$earlier_methods`, and never change the decision;
  `print(fit, legacy = TRUE)` shows them for any fit.

- n_constructs:

  Optional number of constructs judges could choose among. It is used by
  the comparison block's chance-based extension and by the caution added
  to the Colquitt et al. (2019) bands when it is not three. By default
  it is the number of constructs that appear in the data, which is too
  few when judges were offered a construct none of them chose.

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

## Earlier methods, for comparison

The decision uses the exact test of Howard and Melloy (2016). Two
earlier published rules, and one labeled package extension, are reported
beside it for teaching, the way a methods text reports eta-squared
beside omega-squared. None of them changes the decision:

- **Anderson and Gerbing (1991)** judged Csv against a critical value.
  With `N` judges, `m` is the fewest target assignments whose one-tailed
  binomial probability at .5 falls below `alpha` (their Equation 5), and
  the critical Csv is `(2m - N) / N` (Equation 6): .50 for 20 judges at
  .05. Equation 6 assumes every judge who misses the target picks the
  same rival. When those judges spread across several constructs, the
  leading rival's count falls, so Csv can reach the critical value with
  fewer target assignments than the exact test requires. That is why it
  is not used for the decision.

- **Yao et al. (2008)** required Psa and Csv both to reach .30, which
  they chose for a four-domain sort, where an item assigned at random
  lands in its domain with probability .25 (p. 486). They give no rule
  for other numbers of domains.

- **A contentvalidR extension, not a published rule.** Yao et al.'s
  reasoning carried to `k` constructs as chance plus .05: Psa and Csv
  both at least `1/k + .05`, which is their .30 when `k = 4`. It is
  shown in its own column, marked as an extension, whenever `k` is
  not 4. `k` is `n_constructs` when given, and otherwise the number of
  constructs in the data.

Csv counts only the single most-chosen rival construct (Anderson &
Gerbing, 1991, p. 734). Pooling every other construct into that count
instead gives `2 * Psa - 1`, a different index; the printout notes this.

## References

Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
measures in a confirmatory factor analysis with a pretest assessment of
their substantive validities. *Journal of Applied Psychology, 76*(5),
732–740.
[doi:10.1037/0021-9010.76.5.732](https://doi.org/10.1037/0021-9010.76.5.732)

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243–1265.
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406)

Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task
methods: The presentation of a new statistical significance formula and
methodological best practices. *Journal of Business and Psychology,
31*(1), 173–186.
[doi:10.1007/s10869-015-9404-y](https://doi.org/10.1007/s10869-015-9404-y)

Yao, G., Wu, C.-H., & Yang, C.-T. (2008). Examining the content validity
of the WHOQOL-BREF from respondents' perspective by quantitative
methods. *Social Indicators Research, 85*(3), 483–498.
[doi:10.1007/s11205-007-9112-8](https://doi.org/10.1007/s11205-007-9112-8)

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
#> These bands come from tasks with three definitions (one focal, two orbiting);
#> judges here used 2 (set `n_constructs` if more were offered), so the
#> comparison is approximate. This is a contentvalidR caution: Colquitt et al.
#> do not discuss other numbers.
#> 
#> Colquitt labels are empirical percentile norms derived from scale-level
#> averages, not universal cutoffs or automatic scale-retention rules. They
#> place a scale against published scales; Psa and Csv sit on different scales,
#> so their labels are not comparable with each other.
#> 
#> What these columns mean
#>   Psa -- Proportion of Substantive Agreement. Share of judges who put the
#>       item in the construct it was written for (0 to 1; higher is
#>       stronger).
#>   95% CI -- Interval for Psa. Wider when fewer judges sorted the item; the
#>       method is named above.
#>   Csv -- Coefficient of Substantive Validity. How much more often judges
#>       chose the intended construct than its closest rival (-1 to 1; 0 is a
#>       tie).
#>   competitor -- Strongest competing construct. The construct other than the
#>       intended one that judges chose most often.
#>   p -- Howard-Melloy exact test. Probability of at least this many target
#>       assignments if each judge picked the target at rate p0; compare with
#>       alpha.
#> 
#> What the decisions mean
#>   Retain -- met the exact target-assignment criterion.
#>   Review -- did not meet the exact target-assignment criterion; the
#>       competitor column shows where judges put it instead.
#> 
#> Full definitions: contentvalid_glossary(). To hide this key:
#> options(contentvalidR.show_key = FALSE).
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
#>  target items retain review mean Psa Psa level mean Csv Csv level
#>       A     3      2      1      .77  Moderate      .53  Moderate
#> 
#> A: Mean Psa and mean Csv both fall in the Moderate band of published scales
#>   (Colquitt et al., 2019); review the weaker items before finalizing. These
#>   bands come from tasks with three definitions (one focal, two orbiting);
#>   judges here used 2 (set `n_constructs` if more were offered), so the
#>   comparison is approximate. This is a contentvalidR caution: Colquitt et al.
#>   do not discuss other numbers.
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

# The same result beside the earlier published rules.
print(fit, legacy = TRUE)
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
#> These bands come from tasks with three definitions (one focal, two orbiting);
#> judges here used 2 (set `n_constructs` if more were offered), so the
#> comparison is approximate. This is a contentvalidR caution: Colquitt et al.
#> do not discuss other numbers.
#> 
#> Colquitt labels are empirical percentile norms derived from scale-level
#> averages, not universal cutoffs or automatic scale-retention rules. They
#> place a scale against published scales; Psa and Csv sit on different scales,
#> so their labels are not comparable with each other.
#> 
#> Earlier methods, for comparison (not used for the decision)
#>  item decision Psa Csv A&G (1991) Yao et al. (2008) extension*
#>    A1   Retain .90 .80      meets             meets      meets
#>    A2   Retain .80 .60      meets             meets      meets
#>    A3   Review .60 .20      below             below      below
#> 
#> Anderson and Gerbing (1991): Csv of at least .50, their critical value for 20
#> judges at alpha = .05 (Equations 5 and 6). Their critical value assumes every
#> judge who misses the target picks the same rival. When those judges spread
#> across several constructs, Csv can reach it with fewer target assignments
#> than the exact test needs.
#> Yao et al. (2008): Psa and Csv both at least .30, set for a four-domain sort
#> where chance assignment is .25.
#> * extension: a contentvalidR extension, not a published rule. It carries Yao
#>   et al.'s reasoning to this sort's 2 constructs as chance plus .05, so Psa
#>   and Csv both at least .55 (1/2 + .05).
#> The 2 constructs are the ones judges used. If more were offered, set
#> `n_constructs`, since chance depends on the number offered.
#> Agreement with the decision above: Anderson and Gerbing on 3 of 3 items, Yao
#> et al. on 3 of 3, the extension on 3 of 3.
#> Csv counts only the single most-chosen rival construct (Anderson & Gerbing,
#> 1991, p. 734). Pooling every other construct into it instead gives twice Psa
#> minus one, a different index.
#> 
#> What these columns mean
#>   Psa -- Proportion of Substantive Agreement. Share of judges who put the
#>       item in the construct it was written for (0 to 1; higher is
#>       stronger).
#>   95% CI -- Interval for Psa. Wider when fewer judges sorted the item; the
#>       method is named above.
#>   Csv -- Coefficient of Substantive Validity. How much more often judges
#>       chose the intended construct than its closest rival (-1 to 1; 0 is a
#>       tie).
#>   competitor -- Strongest competing construct. The construct other than the
#>       intended one that judges chose most often.
#>   p -- Howard-Melloy exact test. Probability of at least this many target
#>       assignments if each judge picked the target at rate p0; compare with
#>       alpha.
#> 
#> What the decisions mean
#>   Retain -- met the exact target-assignment criterion.
#>   Review -- did not meet the exact target-assignment criterion; the
#>       competitor column shows where judges put it instead.
#> 
#> Full definitions: contentvalid_glossary(). To hide this key:
#> options(contentvalidR.show_key = FALSE).
#> 
#> 'Review' is not an automatic deletion decision. Use theory, construct-domain
#> coverage, item wording, and qualitative judge feedback alongside these
#> statistics.
```

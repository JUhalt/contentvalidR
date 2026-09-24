# Item-Sort Content Validation: Anderson-Gerbing to Howard-Melloy to Colquitt

## What this workflow answers

Item-sort pretests ask judges to assign candidate items to construct
definitions. The workflow provides two related kinds of evidence:

1.  **Definitional correspondence**: are items assigned to their
    intended construct?
2.  **Definitional distinctiveness**: are items assigned to the intended
    construct more often than to a competing construct?

Anderson and Gerbing (1991) operationalized these ideas with **Psa** and
**Csv**. Howard and Melloy (2016) clarified exact inference for the
target-assignment count, particularly when more than two assignment
alternatives are present. Colquitt et al. (2019) later supplied
empirical interpretation norms based on 112 published scales.

These statistics do not establish the entire content-validity argument.
In particular, they do not establish that the item pool comprehensively
covers the construct domain.

## A reproducible example

``` r

sort_dat <- data.frame(
  item = rep(c("A1", "A2", "A3", "B1", "B2", "B3"), each = 20),
  rater = rep(1:20, 6),
  target_construct = rep(c("A", "A", "A", "B", "B", "B"), each = 20),
  assigned_construct = c(
    rep("A", 18), rep("B", 2),
    rep("A", 16), rep("B", 4),
    rep("A", 13), rep("B", 7),
    rep("B", 18), rep("A", 2),
    rep("B", 17), rep("A", 3),
    rep("B", 14), rep("A", 6)
  )
)

fit <- sort_validity(sort_dat)
fit
#> contentvalidR item-sort analysis
#> --------------------------------
#> Items: 6 | Judges: 20 | Target constructs: 2
#> Test: Howard-Melloy exact target-count test (p0 = .50, alpha = .05)
#> Judges: naive, meaning drawn from the kind of people who will answer the
#> items.
#> 
#> 4 of 6 items meet the exact target-assignment criterion.
#> Flagged for review: A3, B3
#> 
#> Item-level evidence
#>  item target decision judges Psa     95% CI Csv competitor      p
#>    A1      A   Retain  18/20 .90 [.70, .97] .80          B < .001
#>    A2      A   Retain  16/20 .80 [.58, .92] .60          B   .006
#>    A3      A   Review  13/20 .65 [.43, .82] .30          B   .132
#>    B1      B   Retain  18/20 .90 [.70, .97] .80          A < .001
#>    B2      B   Retain  17/20 .85 [.64, .95] .70          A   .001
#>    B3      B   Review  14/20 .70 [.48, .85] .40          A   .058
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
#>       A     3      .78  Moderate      .57  Moderate
#>       B     3      .82  Moderate      .63    Strong
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
```

The item table is intentionally diagnostic rather than merely numeric. A
`Review` flag is not a command to delete an item. The output reports the
strongest competing construct so that researchers can distinguish weak
target correspondence from specific construct overlap.

``` r

summary(fit)
#> Summary: item-sort content-validity evidence
#> --------------------------------------------
#> Retain: 4 of 6 | Review: 2 of 6
#> 
#> Scale-level evidence
#>  target items retain review mean Psa Psa level mean Csv Csv level  overall
#>       A     3      2      1      .78  Moderate      .57  Moderate Moderate
#>       B     3      2      1      .82  Moderate      .63    Strong Moderate
#> 
#> A, B: Generally supportive normative standing, with at least one dimension in
#>   the moderate range; review weaker items before finalizing.
#> 
#> Items needing attention
#>  item target decision Psa Csv competitor    p
#>    A3      A   Review .65 .30          B .132
#>    B3      B   Review .70 .40          A .058
#> 
#> A3, B3: Target favored, exact criterion not met
#> 
#> Interpret scale norms and item flags alongside theory, domain coverage, and
#> qualitative feedback. This analysis does not by itself establish
#> comprehensiveness or the full content-validity argument.
```

## Item-level inference: Howard-Melloy

The default exact test asks whether the target-assignment probability
exceeds `.50`. At `N = 20` and `alpha = .05`, an item needs 15 target
assignments to meet the one-sided exact criterion.

``` r

csv_binom_test(n_c = 15, N = 20)
#> $p.value
#> [1] 0.02069473
#> 
#> $estimate
#> [1] 0.75
#> 
#> $conf.int
#> [1] 0.5444176 1.0000000
#> attr(,"conf.level")
#> [1] 0.95
#> 
#> $critical_n_target
#> [1] 15
#> 
#> $passes_chance
#> [1] TRUE
#> 
#> $decision
#> [1] "significant"
#> 
#> $interpretation
#> [1] "Target assignments exceed the exact chance criterion."
csv_binom_test(n_c = 14, N = 20)
#> $p.value
#> [1] 0.05765915
#> 
#> $estimate
#> [1] 0.7
#> 
#> $conf.int
#> [1] 0.4921816 1.0000000
#> attr(,"conf.level")
#> [1] 0.95
#> 
#> $critical_n_target
#> [1] 15
#> 
#> $passes_chance
#> [1] FALSE
#> 
#> $decision
#> [1] "n.s."
#> 
#> $interpretation
#> [1] "Target assignments do not exceed the exact chance criterion."
```

[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
therefore uses **Retain** to mean “meets this exact statistical
screening criterion” and **Review** to mean “does not meet it.” Revision
or removal remains a substantive decision.

## Scale-level interpretation: Colquitt et al. (2019)

Colquitt et al. did not create their interpretation bands from
individual item values. They averaged Psa and Csv across the items in
each of 112 scales and then created empirical percentile bands.
[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
follows that design: Howard-Melloy is used item by item, while Colquitt
interpretation is reported for each target scale’s mean Psa and mean
Csv.

The default uses the overall norms:

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
colquitt_benchmarks("csv")
#>   statistic benchmark_set                  benchmark_label interpretation
#> 1       csv       overall Overall (not correlation-normed)    Very Strong
#> 2       csv       overall Overall (not correlation-normed)         Strong
#> 3       csv       overall Overall (not correlation-normed)       Moderate
#> 4       csv       overall Overall (not correlation-normed)           Weak
#> 5       csv       overall Overall (not correlation-normed)        Lack of
#>   percentile minimum
#> 1  80th-99th    0.81
#> 2  60th-79th    0.61
#> 3  40th-59th    0.51
#> 4  20th-39th    0.05
#> 5   0th-19th    -Inf
```

The labels—Very Strong, Strong, Moderate, Weak, and Lack of—are
empirical normative standing, **not universal validity cutoffs**.

### Correlation-conditional norms

Colquitt et al. showed that Psa/Csv depend partly on how similar the
focal scale is to its orbiting scales. If substantive data provide an
average focal-orbiting correlation, supply it to the workflow. With
multiple focal scales, use a named vector.

``` r

fit_normed <- sort_validity(
  sort_dat,
  orbiting_r = c(A = .42, B = .28)
)
fit_normed$scale_summary
#>   target n_items n_items_usable n_retain n_review  mean_psa psa_strength
#> 1      A       3              3        2        1 0.7833333     Moderate
#> 2      B       3              3        2        1 0.8166667         Weak
#>    mean_csv csv_strength orbiting_r
#> 1 0.5666667     Moderate       0.42
#> 2 0.6333333         Weak       0.28
#>                                        benchmark_set benchmark_applicable
#> 1 More moderate focal-orbiting correlation (.35-.50)                 TRUE
#> 2       Weaker focal-orbiting correlation (r <= .34)                 TRUE
#>   overall_strength
#> 1         Moderate
#> 2             Weak
#>                                                                                                                                evidence
#> 1    Generally supportive normative standing, with at least one dimension in the moderate range; review weaker items before finalizing.
#> 2 Limited normative standing on at least one dimension; review item wording and construct overlap and consider re-pretesting revisions.
```

The conditional panels are:

- `.34` or below: weaker focal-orbiting correlation;
- `.35` to `.50`: more moderate correlation;
- `.51` or above: stronger correlation.

A given Csv can be more impressive when the focal and orbiting
constructs are closely related, so the appropriate norm can change the
descriptive category.

## Judge type matters

Anderson and Gerbing advocated naïve judges representative of the
population of interest, and Colquitt et al.’s norms were generated with
that kind of judge. Their criteria should not simply be transferred to
expert panels.

``` r

expert_fit <- sort_validity(sort_dat, judge_type = "expert")
expert_fit$scale_summary
#>   target n_items n_items_usable n_retain n_review  mean_psa psa_strength
#> 1      A       3              3        2        1 0.7833333         <NA>
#> 2      B       3              3        2        1 0.8166667         <NA>
#>    mean_csv csv_strength orbiting_r                    benchmark_set
#> 1 0.5666667         <NA>         NA Overall (not correlation-normed)
#> 2 0.6333333         <NA>         NA Overall (not correlation-normed)
#>   benchmark_applicable overall_strength
#> 1                FALSE             <NA>
#> 2                FALSE             <NA>
#>                                                                              evidence
#> 1 Colquitt norms not applied because this workflow was marked as using expert judges.
#> 2 Colquitt norms not applied because this workflow was marked as using expert judges.
```

The Psa/Csv statistics and item-level screening remain available, but
Colquitt normative labels are suppressed.

## Planning judge sample size

Use
[`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md)
to calculate the exact probability that an item will reach the required
target-assignment count under a plausible true target-assignment
probability.

``` r

sort_power(N = c(20, 30, 40), true_p = c(.60, .70, .80))
#> contentvalidR item-sort planning
#> --------------------------------
#> Retention rule: Howard-Melloy exact test (p0 = .50, alpha = .05)
#> 
#>  judges required minimum Psa power at .60 power at .70 power at .80
#>      20    15/20         .75          .13          .42          .80
#>      30    20/30         .67          .29          .73          .97
#>      40    26/40         .65          .32          .81          .99
#> 
#> required: target assignments an item needs to be retained. minimum Psa: the
#> same as a proportion. power at p: the exact probability of reaching the
#> required count if each judge assigns the item to its target with probability
#> p.
```

This is preferable to treating a rule such as “20-40 judges” as a
universal sample-size requirement. Power depends on the assumed
target-assignment probability, `N`, the null probability, and alpha.

## Plotting item evidence

The one-index views remain available:

``` r

plot(fit, metric = "psa")
```

![](item-sort-validity_files/figure-html/unnamed-chunk-8-1.png)

``` r

plot(fit, metric = "csv")
```

![](item-sort-validity_files/figure-html/unnamed-chunk-8-2.png)

For diagnosis, the package also introduces a
**correspondence-distinctiveness evidence map**:

``` r

plot(fit, type = "map")
```

![](item-sort-validity_files/figure-html/unnamed-chunk-9-1.png)

Psa and Csv are shown jointly, review items are labeled by default, and
target- scale averages are added as diamonds. This makes it easier to
distinguish a correspondence problem (low Psa) from a construct-overlap
problem (low or negative Csv). The map does not draw Colquitt cutoff
regions across individual items because those empirical norms were
constructed from scale-level averages.

The exact planning object is also plottable:

``` r

plan <- sort_power(N = seq(10, 50, by = 5), true_p = c(.60, .70, .80))
plot(plan)
```

![](item-sort-validity_files/figure-html/unnamed-chunk-10-1.png)

``` r

plot(plan, type = "critical")
```

![](item-sort-validity_files/figure-html/unnamed-chunk-10-2.png)

No conventional target-power line is imposed unless the analyst supplies
one.

## Earlier rules, for comparison only

`contentvalidR` retains Anderson and Gerbing’s Psa and Csv indices but
does not offer their critical-Csv rule as a way to decide. Howard and
Melloy (2016) showed that the older rule is appropriate for the original
two-choice case but becomes miscalibrated when it is applied to sorts
with more than two construct choices. Their revised target-count
procedure agrees with the older logic in the two-choice case and is
applicable to the broader designs now used in practice.

The earlier rules are still worth seeing, the way a methods course
reports eta-squared beside omega-squared. `legacy = TRUE` prints them
beside the decision, without changing it. In the two-construct sort
above, every judge who misses the target picks the one other construct,
and the two rules agree on every item. The package’s shipped example has
three constructs:

``` r

three <- read.csv(
  system.file("extdata", "sort_example.csv", package = "contentvalidR"),
  stringsAsFactors = FALSE
)
old <- options(contentvalidR.show_key = FALSE)
sort_validity(three, legacy = TRUE)
#> contentvalidR item-sort analysis
#> --------------------------------
#> Items: 6 | Judges: 20 | Target constructs: 3
#> Test: Howard-Melloy exact target-count test (p0 = .50, alpha = .05)
#> Judges: naive, meaning drawn from the kind of people who will answer the
#> items.
#> 
#> 4 of 6 items meet the exact target-assignment criterion.
#> Flagged for review: B2, C2
#> 
#> Item-level evidence
#>  item target decision judges Psa     95% CI Csv competitor      p
#>    A1      A   Retain  18/20 .90 [.70, .97] .85       B; C < .001
#>    A2      A   Retain  15/20 .75 [.53, .89] .60          B   .021
#>    B1      B   Retain  17/20 .85 [.64, .95] .75          A   .001
#>    B2      B   Review  13/20 .65 [.43, .82] .40          A   .132
#>    C1      C   Retain  18/20 .90 [.70, .97] .85       A; B < .001
#>    C2      C   Review  14/20 .70 [.48, .85] .50          B   .058
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
#>       A     2      .82    Strong      .72    Strong
#>       B     2      .75  Moderate      .57  Moderate
#>       C     2      .80  Moderate      .68    Strong
#> Benchmark set: Overall (not correlation-normed)
#> 
#> Colquitt labels are empirical percentile norms derived from scale-level
#> averages, not universal cutoffs or automatic scale-retention rules. They
#> place a scale against published scales; Psa and Csv sit on different scales,
#> so their labels are not comparable with each other.
#> 
#> Earlier methods, for comparison (not used for the decision)
#>  item decision Psa Csv A&G (1991) Yao et al. (2008) extension*
#>    A1   Retain .90 .85      meets             meets      meets
#>    A2   Retain .75 .60      meets             meets      meets
#>    B1   Retain .85 .75      meets             meets      meets
#>    B2   Review .65 .40      below             meets      meets
#>    C1   Retain .90 .85      meets             meets      meets
#>    C2   Review .70 .50      meets             meets      meets
#> 
#> Anderson and Gerbing (1991): Csv of at least .50, their critical value for 20
#> judges at alpha = .05 (Equations 5 and 6). Their critical value assumes every
#> judge who misses the target picks the same rival. When those judges spread
#> across several constructs, Csv can reach it with fewer target assignments
#> than the exact test needs.
#> Yao, Wu and Yang (2008): Psa and Csv both at least .30, set for a four-domain
#> sort where chance assignment is .25.
#> * extension: a contentvalidR extension, not a published rule. It carries Yao
#>   et al.'s reasoning to this sort's 3 constructs as chance plus .05, so Psa
#>   and Csv both at least .38 (1/3 + .05).
#> The 3 constructs are the ones judges used. If more were offered, set
#> `n_constructs`, since chance depends on the number offered.
#> Agreement with the decision above: Anderson and Gerbing on 5 of 6 items, Yao
#> et al. on 4 of 6, the extension on 4 of 6.
#> Csv counts only the single most-chosen rival construct (Anderson & Gerbing,
#> 1991, p. 734). Pooling every other construct into it instead gives twice Psa
#> minus one, a different index.
#> 
#> 'Review' is not an automatic deletion decision. Use theory, construct-domain
#> coverage, item wording, and qualitative judge feedback alongside these
#> statistics.
options(old)
```

Look at C2. Fourteen of 20 judges chose its target, one short of the 15
the exact test needs, so the decision is Review. Anderson and Gerbing’s
rule passes it: their critical Csv of .50 assumes the six judges who
missed the target all chose one rival, but here they split, so Csv
reaches .50 anyway. That is the miscalibration in miniature. Yao, Wu and
Yang’s (2008) .30 cutoffs pass every item, because they were set for
four domains, where chance is .25; with three constructs, chance is
already above .30.

The column marked `extension*` is not a published rule. It is this
package’s extension of Yao et al.’s reasoning to any number of
constructs, chance plus .05, which gives their .30 for four constructs
and .38 for these three, and the printout labels it that way. Chance
depends on how many constructs judges were offered, not how many they
used, so give `n_constructs` when some construct drew no assignments.

## Reporting

A useful report should include:

- who the judges were and why they fit the intended design;
- the focal and orbiting constructs and their definitions;
- the number of judges and missing assignments;
- item-level Psa, Csv, target counts, strongest competitors, and exact
  decisions;
- target-scale mean Psa/Csv and the Colquitt norm set used;
- focal-orbiting correlations if conditional norms were used; and
- the substantive reasoning behind any revisions or removals.

## References

Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
measures in a confirmatory factor analysis with a pretest assessment of
their substantive validities. *Journal of Applied Psychology, 76*(5),
732-740. <https://doi.org/10.1037/0021-9010.76.5.732>

Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task
methods: The presentation of a new statistical significance formula and
methodological best practices. *Journal of Business and Psychology,
31*(1), 173-186. <https://doi.org/10.1007/s10869-015-9404-y>

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243-1265. <https://doi.org/10.1037/apl0000406>

Yao, G., Wu, C.-H., & Yang, C.-T. (2008). Examining the content validity
of the WHOQOL-BREF from respondents’ perspective by quantitative
methods. *Social Indicators Research, 85*(3), 483-498.
<https://doi.org/10.1007/s11205-007-9112-8>

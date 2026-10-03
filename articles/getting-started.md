# Getting Started with contentvalidR

``` r

library(contentvalidR)
```

**Overview**

This vignette introduces the package’s three recommended
content-pretesting workflows—**item sorting**, **construct ratings**,
and **expert panels**.
[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md),
[`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md),
and
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
organize quantitative evidence while keeping substantive decisions
separate from statistical flags.

**A common workflow contract**

All three fitted workflow objects expose `results`, `scale_summary`,
`settings`, `design`, and `details`. Their result tables also contain a
common `status` field: `Supported`, `Review`, `Insufficient data`, or
`Descriptive only`. Method-specific recommendation wording is preserved
alongside that common status. This makes it possible to write reusable
code across workflows without pretending that a Howard-Melloy retention
decision, Hinkin-Tracey screening result, and expert-panel judgment are
substantively identical.

**Sort-based (Psa, Csv, binomial)**

``` r

toy_sort <- data.frame(
  item = rep(paste0("I", 1:4), each = 12),
  rater = rep(1:12, 4),
  target_construct   = rep(c("A","A","B","B"), each = 12),
  assigned_construct = c(
    sample(c("A","B"), 12, TRUE, c(.80,.20)),
    sample(c("A","B"), 12, TRUE, c(.65,.35)),
    sample(c("A","B"), 12, TRUE, c(.70,.30)),
    sample(c("A","B"), 12, TRUE, c(.45,.55))
  )
)
psa <- compute_psa(toy_sort)
csv <- compute_csv(toy_sort)
csv$decision <- vapply(seq_len(nrow(csv)), function(i) {
  csv_binom_test(csv$n_target[i], csv$n[i])$decision
}, character(1))
psa; csv
#> Proportion of substantive agreement (Psa; Anderson & Gerbing, 1991)
#> 
#>  item target judges Psa     95% CI
#>    I1      A   9/12 .75 [.47, .91]
#>    I2      A   5/12 .42 [.19, .68]
#>    I3      B   2/12 .17 [.05, .45]
#>    I4      B   5/12 .42 [.19, .68]
#> 
#> judges: assignments to the target construct, out of the judges who sorted the
#> item.
#> 95% intervals for proportions: Wilson score (the default). Newcombe (1998)
#> compared seven methods and recommends score intervals over the Wald interval.
#> An interval reflects how few ratings an item received, not whether the right
#> judges were chosen.
#> Coefficient of substantive validity (Csv; Anderson & Gerbing, 1991)
#> 
#>  item target judges competitor competitor judges  Csv
#>    I1      A   9/12          B              3/12  .50
#>    I2      A   5/12          B              7/12 -.17
#>    I3      B   2/12          A             10/12 -.67
#>    I4      B   5/12          A              7/12 -.17
#> 
#> Csv is the target count minus the count for the most-chosen other construct,
#> divided by the number of judges.
```

**Interpretation** - **Psa** = share assigning the intended construct. -
**Csv** = margin of wins: \$ \$. - The exact binomial test (null
hypothesis: a target rate of .5 or less) flags items whose target count
meets the criterion. The .5 is a benchmark rate, not the rate random
sorting would give.

**Construct-rating workflow (HTC, HTD, repeated-measures ANOVA)**

``` r

set.seed(2)
toy_ratings <- expand.grid(
  item = c("I1", "I2", "I3"),
  rater = 1:16,
  construct = c("A", "B", "C")
)
toy_ratings$target_construct <- ifelse(toy_ratings$item == "I3", "B", "A")
toy_ratings$rating <- ifelse(
  toy_ratings$construct == toy_ratings$target_construct,
  pmin(5, pmax(1, round(rnorm(nrow(toy_ratings), 4.4, .6)))),
  pmin(5, pmax(1, round(rnorm(nrow(toy_ratings), 2.2, .7))))
)

rating_fit <- rating_validity(toy_ratings, scale_min = 1, scale_max = 5)
rating_fit
#> contentvalidR construct-rating analysis
#> ---------------------------------------
#> Items: 3 | Judges: 16 | Target constructs: 2 | Constructs rated: 3
#> Design: within-judge ratings on a 1 to 5 scale
#> Test: one-way repeated-measures ANOVA (Greenhouse-Geisser corrected omnibus
#> p) plus planned paired target-versus-orbiting contrasts; planned-contrast
#> adjustment: none.
#> Retain: the omnibus p and every contrast p at or below alpha = .05. The
#> contrasts are one-sided: the intended construct rated above every other
#> construct.
#> Judges: naive, meaning drawn from the kind of people who will answer the
#> items.
#> 
#> 3 of 3 items meet the full item-level screening criterion.
#> 
#> Item-level evidence
#>  item target decision  n HTC HTD omnibus p contrast p competitor
#>    I1      A   Retain 16 .82 .49    < .001     < .001          C
#>    I2      A   Retain 16 .89 .51    < .001     < .001          C
#>    I3      B   Retain 16 .88 .54    < .001     < .001          C
#> 
#> n: judges who rated the item against every construct. omnibus p: do the
#> item's ratings differ across constructs (Greenhouse-Geisser corrected).
#> contrast p: the largest p among the planned target-versus-orbiting contrasts,
#> so every contrast is at or below it.
#> 
#> Target-scale Colquitt benchmarks
#>  target items mean HTC HTC level mean HTD   HTD level
#>       A     2      .86  Moderate      .50 Very Strong
#>       B     1      .88    Strong      .54 Very Strong
#> Benchmark set: Overall (not correlation-normed)
#> 
#> Colquitt labels are empirical percentile norms for scale-level HTC and HTD
#> averages, not universal cutoffs. HTC is an average rating and HTD is a
#> difference between ratings, so they sit on different scales with different
#> typical values. A high HTC can be labeled Weak in the same analysis where a
#> much smaller HTD is labeled Very Strong. Compare each index against its own
#> benchmark, never against the other index's number.
#> 
#> What these columns mean
#>   HTC -- Hinkin-Tracey Correspondence. Mean rating against the intended
#>       definition, divided by the number of scale points (1/points to 1).
#>   HTD -- Hinkin-Tracey Distinctiveness. How far that rating exceeds the
#>       other constructs' ratings on average, as a share of the scale
#>       (usually small).
#> 
#> What the decisions mean
#>   Retain -- its ratings differed across constructs (the omnibus test) and
#>       the intended construct was rated above every other (every planned
#>       contrast).
#> 
#> Full definitions: contentvalid_glossary(). To hide this key:
#> options(contentvalidR.show_key = FALSE).
#> 
#> 'Review' is not an automatic deletion decision. Consider construct
#> definitions, item wording, orbiting-construct choice, domain coverage, and
#> qualitative judge feedback.
summary(rating_fit)
#> Summary: construct-rating content-validity evidence
#> ---------------------------------------------------
#> Retain: 3 of 3 | Review: 0 of 3
#> 
#> Scale-level evidence
#>  target items retain review mean HTC HTC level mean HTD   HTD level
#>       A     2      2      0      .86  Moderate      .50 Very Strong
#>       B     1      1      0      .88    Strong      .54 Very Strong
#> 
#> A: Mean HTC falls in the Moderate band and mean HTD in the Very Strong band
#>   of published scales (Colquitt et al., 2019); inspect the weaker items and
#>   construct overlap before finalizing the scale.
#> B: Mean HTC falls in the Strong band and mean HTD in the Very Strong band of
#>   published scales (Colquitt et al., 2019).
#> 
#> All analyzed items met the item-level inferential screening criterion.
#> 
#> Interpret these results alongside theory, domain coverage, and qualitative
#> feedback. The analysis does not by itself establish comprehensiveness or the
#> full content-validity argument.
```

**Interpretation** - **HTC** summarizes definitional correspondence with
the intended construct. - **HTD** summarizes distinctiveness from
orbiting constructs. - The repeated-measures ANOVA tests whether
construct-definition ratings differ for an item. - Planned paired
contrasts ask the direct screening question: is the target rating
significantly higher than every orbiting rating? - Scale-level HTC/HTD
averages can be interpreted using Colquitt et al. (2019) empirical norms
when the judge population matches their intended use.

**Expert-panel workflow**

``` r

expert_ratings <- matrix(
  c(4,4,4,4,4,4,
    4,4,4,3,4,4,
    4,3,4,4,3,4),
  nrow = 6,
  dimnames = list(NULL, paste0("Item", 1:3))
)
expert_fit <- expert_validity(expert_ratings, mode = "relevance", lo = 1, hi = 4)
expert_fit
#> contentvalidR expert-panel analysis
#> -----------------------------------
#> Mode: relevance
#> Items: 3 | Experts/item: 6
#> Scale: 1 to 4 | Relevant: a rating of 3 or higher
#> Mean Aiken V: .94 | S-CVI/Ave: 1.00 | S-CVI/UA: 1.00
#> Panel agreement, Krippendorff's alpha (ordinal): .02, 95% CI [-.13, .15].
#>   Identical rating pairs: 71.1%.
#> 
#> 3 of 3 items meet the I-CVI criterion, all with strong support (modified
#> kappa above .74).
#> 
#>   item       decision N    V      95% CI I-CVI      95% CI kappa
#>  Item1 Strong support 6 1.00 [.82, 1.00]  1.00 [.61, 1.00]  1.00
#>  Item2 Strong support 6  .94  [.74, .99]  1.00 [.61, 1.00]  1.00
#>  Item3 Strong support 6  .89  [.67, .97]  1.00 [.61, 1.00]  1.00
#> 
#> Each 95% CI follows its estimate: Aiken's V has a Penfield-Giacobbi score
#> interval, and I-CVI the proportion interval named below.
#> I-CVI criterion for 6 experts: 5 agreeing (.83), following Lynn (1986); kappa
#> is modified kappa, with values above .74 read as excellent (Polit et al.,
#> 2007).
#> 95% intervals for proportions: Wilson score (the default). Newcombe (1998)
#> compared seven methods and recommends score intervals over the Wald interval.
#> An interval reflects how few ratings an item received, not whether the right
#> judges were chosen.
#> 
#> Panel agreement is one coefficient for the whole panel, whereas modified
#> kappa (the kappa column) describes each item. Alpha can be low when nearly
#> every rating is the same value, even on a panel that agrees closely, so read
#> it beside the share of identical rating pairs. A low alpha with many
#> identical pairs is not by itself evidence of a poor panel. Print
#> `details$agreement` for the full explanation and interval details.
#> 
#> CVI criteria are published panel-size guidelines, not universal validity
#> cutoffs.
#> 
#> What these columns mean
#>   V -- Aiken's V. Mean relevance rating rescaled to run from 0 (lowest
#>       possible) to 1 (highest).
#>   I-CVI -- Item-level Content Validity Index. Share of experts rating the
#>       item relevant, against Lynn's criterion for the panel size (beyond
#>       ten, this package's).
#>   95% CI after I-CVI -- Interval for I-CVI. Wide because expert panels are
#>       small; the method is named above.
#>   kappa -- Modified kappa. I-CVI corrected for chance agreement (at most 1;
#>       below 0 when agreement is below chance).
#>   Panel agreement -- Panel-level agreement. One coefficient for the whole
#>       panel (1 is perfect, 0 is chance); it can be low when nearly every
#>       rating is the same.
#> 
#> What the decisions mean
#>   Strong support -- met the I-CVI criterion, which also puts modified kappa
#>       above .74.
#> 
#> Full definitions: contentvalid_glossary(). To hide this key:
#> options(contentvalidR.show_key = FALSE).
#> 
#> Use quantitative indices alongside expert comments, construct coverage, and
#> comprehensibility review.
summary(expert_fit)
#> Summary: expert-panel content-validity evidence
#> -----------------------------------------------
#> Mode: relevance
#> Supported: 3 | Review: 0
#> Panel agreement, Krippendorff's alpha (ordinal): .02, 95% CI [-.13, .15].
#>   Identical rating pairs: 71.1%.
#> 
#> No items were flagged by the workflow's quantitative review rules.
#> 
#> These summaries support, but do not replace, qualitative content review.
```

Relevance, essentiality, and congruence are intentionally separate
expert tasks. Use `mode = "relevance"` for Aiken V + CVI/modified kappa,
`mode = "essentiality"` for Lawshe CVR, and `mode = "congruence"` for
IOC.

**Bundled reproducible examples**

The package also installs deterministic CSV examples for the three
workflow families and all expert-panel modes. They are synthetic,
contain no participant data, and are regenerated from
`data-raw/build-example-data.R` in the source repository.

``` r

example_files <- c(
  "sort_example.csv",
  "rating_example.csv",
  "expert_relevance_example.csv",
  "expert_essentiality_example.csv",
  "expert_congruence_example.csv"
)
vapply(example_files, function(x) {
  system.file("extdata", x, package = "contentvalidR")
}, character(1))
#>                                                                        sort_example.csv 
#>                "/home/runner/work/_temp/Library/contentvalidR/extdata/sort_example.csv" 
#>                                                                      rating_example.csv 
#>              "/home/runner/work/_temp/Library/contentvalidR/extdata/rating_example.csv" 
#>                                                            expert_relevance_example.csv 
#>    "/home/runner/work/_temp/Library/contentvalidR/extdata/expert_relevance_example.csv" 
#>                                                         expert_essentiality_example.csv 
#> "/home/runner/work/_temp/Library/contentvalidR/extdata/expert_essentiality_example.csv" 
#>                                                           expert_congruence_example.csv 
#>   "/home/runner/work/_temp/Library/contentvalidR/extdata/expert_congruence_example.csv"
```

See
[`vignette("reporting-examples", package = "contentvalidR")`](https://juhalt.github.io/contentvalidR/articles/reporting-examples.md)
for manuscript-ready reporting scaffolds built from those same files.

**Classic indices**

``` r

R <- matrix(sample(1:5, 5*6, replace = TRUE), nrow = 5)
aikens_v(R, lo = 1, hi = 5)
#> Aiken's V (Aiken, 1980)
#> 
#>   item experts   V     95% CI
#>  Item1       5 .60 [.39, .78]
#>  Item2       5 .30 [.15, .52]
#>  Item3       5 .70 [.48, .85]
#>  Item4       5 .35 [.18, .57]
#>  Item5       5 .60 [.39, .78]
#>  Item6       5 .65 [.43, .82]
#> 
#> Scale: 1 to 5.
#> Interval: Penfield-Giacobbi score (Penfield & Giacobbi, 2004).

cvr(essential = c(8,10,5), N = 12)
#> Content validity ratio (CVR; Lawshe, 1975)
#> 
#>   item essential  CVR    p needed meets
#>  Item1      8/12  .33 .194     10    no
#>  Item2     10/12  .67 .019     10   yes
#>  Item3      5/12 -.17 .806     10    no
#> 
#> needed: essential ratings the exact one-tailed binomial test requires at
#> alpha = .05 (Ayre & Scally, 2014).

M <- matrix(sample(0:1, 6*5, replace = TRUE, prob = c(.3,.7)), nrow = 6)
cvi(M)
#> contentvalidR content validity index (CVI)
#> ------------------------------------------
#> Items: 5 | Judges per item: 6
#> S-CVI/Ave: .67 | S-CVI/UA: .20
#> 
#> Item-level results
#>   item agree I-CVI      95% CI   Pc kappa
#>  Item1   3/6   .50  [.19, .81] .312   .27
#>  Item2   4/6   .67  [.30, .90] .234   .56
#>  Item3   3/6   .50  [.19, .81] .312   .27
#>  Item4   6/6  1.00 [.61, 1.00] .016  1.00
#>  Item5   4/6   .67  [.30, .90] .234   .56
#> 
#> agree: judges rating the item relevant, out of those who rated it. Pc: the
#> probability that this many judges would agree by chance. kappa: the modified
#> kappa of Polit, Beck and Owen (2007), the I-CVI chance-corrected by Pc.
#> 
#> 95% intervals for proportions: Wilson score (the default). Newcombe (1998)
#> compared seven methods and recommends score intervals over the Wald interval.
#> An interval reflects how few ratings an item received, not whether the right
#> judges were chosen.
#> 
#> Polit and Beck (2006) recommend reporting both S-CVI/Ave and S-CVI/UA.
#> Interpretation should consider panel size, item purpose, and qualitative
#> expert feedback; CVI statistics alone do not establish comprehensive content
#> validity.

ioc_df <- data.frame(
  item = rep(paste0("I",1:2), each = 9),
  judge = rep(1:3, times = 6),
  objective = rep(rep(LETTERS[1:3], each = 3), times = 2),
  score = sample(c(-1,0,1), 18, replace = TRUE)
)
ioc(ioc_df)
#> Index of item-objective congruence (IOC; Rovinelli & Hambleton, 1977)
#> 
#>  item objective judges mean  IOC
#>    I1         A      3  .00  .08
#>    I1         B      3  .33  .33
#>    I1         C      3 -.67 -.42
#>    I2         A      3  .00  .00
#>    I2         B      3  .00  .00
#>    I2         C      3  .00  .00
#> 
#> mean: the judges' mean rating on the objective (-1 to 1). IOC: half the gap
#> between that mean and their mean on the item's other objectives; 1 only when
#> every judge rates +1 on the objective and -1 on every other. Rovinelli and
#> Hambleton applied a criterion of .70.
```

**Diagnostics & reproducibility**

``` r

truth <- c(TRUE, TRUE, TRUE, FALSE)  # pretend "kept" after CFA
signal_detection(csv$decision == "significant", truth)
#> Retention decisions compared with the actual outcome
#> 
#>               Actual
#> Predicted      Retain Not retained
#>   Retain            0            0
#>   Not retained      3            1
#> 
#> accuracy = .25, sensitivity = .00, specificity = 1.00, phi = NA.

csv2_sig <- sample(c(TRUE, FALSE), nrow(csv), replace = TRUE)
reproducibility_phi(csv$decision == "significant", csv2_sig)
#> Retention decisions in two pretests
#> 
#>               Pretest2
#> Pretest1       Retain Not retained
#>   Retain            0            0
#>   Not retained      1            3
#> 
#> phi = NA.
```

**Power quick-checks**

``` r

sort_power(N = c(20, 30), true_p = c(.65, .75))
#> contentvalidR item-sort planning
#> --------------------------------
#> Retention rule: Howard-Melloy exact test (p0 = .50, alpha = .05)
#> 
#>  judges required minimum Psa power at .65 power at .75
#>      20    15/20         .75          .25          .62
#>      30    20/30         .67          .51          .89
#> 
#> required: target assignments an item needs to be retained. minimum Psa: the
#> same as a proportion. power at a value: the exact probability of reaching the
#> required count if each judge assigns the item to its target with that
#> probability.
```

## References

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243–1265. <https://doi.org/10.1037/apl0000406>

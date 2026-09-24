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
#>   item target n_total  n n_missing n_target       psa    psa_low  psa_high
#> 1   I1      A      12 12         0        9 0.7500000 0.46769467 0.9110583
#> 2   I2      A      12 12         0        5 0.4166667 0.19326031 0.6804887
#> 3   I3      B      12 12         0        2 0.1666667 0.04696514 0.4480309
#> 4   I4      B      12 12         0        5 0.4166667 0.19326031 0.6804887
#>   item target n_total  n n_missing n_target competitor n_other_max        csv
#> 1   I1      A      12 12         0        9          B           3  0.5000000
#> 2   I2      A      12 12         0        5          B           7 -0.1666667
#> 3   I3      B      12 12         0        2          A          10 -0.6666667
#> 4   I4      B      12 12         0        5          A           7 -0.1666667
#>   decision
#> 1     n.s.
#> 2     n.s.
#> 3     n.s.
#> 4     n.s.
```

**Interpretation** - **Psa** = share assigning the intended construct. -
**Csv** = margin of wins: \$ \$. - Binomial test (H0: \$ p ≤ .5 \$)
flags items with above-chance targeting.

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
#> Benchmark set: overall
#> 
#> Colquitt labels are empirical percentile norms for scale-level HTC and HTD
#> averages, not universal cutoffs. HTC is an average rating and HTD is a
#> difference between ratings, so they sit on different scales with different
#> typical values. A high HTC can be labeled Weak in the same analysis where a
#> much smaller HTD is labeled Very Strong. Compare each index against its own
#> benchmark, never against the other index's number.
#> 
#> What these columns mean
#>   HTC -- Hinkin-Tracey Correspondence. Average rating of the item against
#>       its intended construct definition, expressed as a proportion of the
#>       rating scale. (0 to 1; higher is stronger)
#>   HTD -- Hinkin-Tracey Distinctiveness. How far the intended construct's
#>       average rating exceeds the best competing construct's, as a
#>       proportion of the rating scale. It is a difference, so its typical
#>       values are far smaller than HTC's. (usually a small positive number;
#>       higher is stronger)
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
#> 'Review' is not an automatic deletion decision. Consider construct
#> definitions, item wording, orbiting-construct choice, domain coverage, and
#> qualitative judge feedback.
summary(rating_fit)
#> Summary: construct-rating content-validity evidence
#> ---------------------------------------------------
#> Retain: 3 of 3 | Review: 0 of 3
#> 
#> Scale-level evidence
#>  target items retain review mean HTC HTC level mean HTD   HTD level  overall
#>       A     2      2      0      .86  Moderate      .50 Very Strong Moderate
#>       B     1      1      0      .88    Strong      .54 Very Strong   Strong
#> 
#> A: Generally supportive normative standing, with at least one
#>   content-validity dimension in the moderate range; inspect weaker items and
#>   construct overlap before finalizing the scale.
#> B: Strong normative standing on the weaker of definitional correspondence
#>   (HTC) and distinctiveness (HTD).
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
#> Mean Aiken V: .94 | S-CVI/Ave: 1.00 | S-CVI/UA: 1.00
#> Strong support: 3 | Support: 0 | Review: 0
#> Panel agreement, Krippendorff's alpha (ordinal): .02, 95% CI [-.13, .15].
#>   Identical rating pairs: 71.1%.
#> 
#>   item       decision N    V      95% CI I-CVI      95% CI kappa
#>  Item1 Strong support 6 1.00 [.82, 1.00]  1.00 [.61, 1.00]  1.00
#>  Item2 Strong support 6  .94  [.74, .99]  1.00 [.61, 1.00]  1.00
#>  Item3 Strong support 6  .89  [.67, .97]  1.00 [.61, 1.00]  1.00
#> 
#> Each 95% CI follows its estimate: Aiken's V has a Penfield-Giacobbi score
#> interval, and I-CVI the proportion interval named below.
#> I-CVI criterion for 6 experts: 5 agreeing (.83), following Lynn (1986); kappa
#> is modified kappa, with values above .74 read as excellent (Polit, Beck, &
#> Owen, 2007).
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
#>   V -- Aiken's V. Relevance index that rescales the experts' average rating
#>       to run from 0 to 1 given the bounds of the rating scale used. (0 to
#>       1; higher is stronger)
#>   I-CVI -- Item-level Content Validity Index. Proportion of experts who
#>       rated the item as relevant, after applying the relevance cut. (0 to
#>       1; compared against a panel-size guideline)
#>   95% CI after I-CVI -- Interval for I-CVI. Lower and upper limits of an
#>       interval around I-CVI. Expert panels are usually small, so these
#>       intervals are often wide: a single I-CVI value can look more settled
#>       than the number of experts behind it supports. (between 0 and 1; the
#>       method and level are named in the output)
#>   kappa -- Modified kappa. I-CVI adjusted for the chance that experts would
#>       have agreed even if rating at random. With small panels, chance
#>       agreement is substantial, which is why the raw I-CVI alone can
#>       overstate consensus. (0 to 1; higher is stronger)
#>   Panel agreement -- Panel-level agreement. One coefficient describing how
#>       consistently the whole panel rated the item set: Krippendorff's alpha
#>       by default, or Gwet's AC1 if chosen. It is separate from modified
#>       kappa, which describes one item at a time. (1 is perfect agreement
#>       and 0 is agreement no better than chance; it can be low on a
#>       close-agreeing panel whose ratings cluster on one value)
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
#>    item N n_missing    V    ci_low   ci_high               ci_method
#> 1 Item1 5         0 0.60 0.3865815 0.7811935 Penfield-Giacobbi score
#> 2 Item2 5         0 0.30 0.1454772 0.5189728 Penfield-Giacobbi score
#> 3 Item3 5         0 0.70 0.4810272 0.8545228 Penfield-Giacobbi score
#> 4 Item4 5         0 0.35 0.1811918 0.5671457 Penfield-Giacobbi score
#> 5 Item5 5         0 0.60 0.3865815 0.7811935 Penfield-Giacobbi score
#> 6 Item6 5         0 0.65 0.4328543 0.8188082 Penfield-Giacobbi score

cvr(essential = c(8,10,5), N = 12)
#>    item ne  N        cvr    p_value critical_ne critical_cvr  pass
#> 1 Item1  8 12  0.3333333 0.19384766          10    0.6666667 FALSE
#> 2 Item2 10 12  0.6666667 0.01928711          10    0.6666667  TRUE
#> 3 Item3  5 12 -0.1666667 0.80615234          10    0.6666667 FALSE

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
#>   item objective n_total n_judges n_missing        ioc
#> 1   I1         A       3        3         0  0.0000000
#> 2   I1         B       3        3         0  0.3333333
#> 3   I1         C       3        3         0 -0.6666667
#> 4   I2         A       3        3         0  0.0000000
#> 5   I2         B       3        3         0  0.0000000
#> 6   I2         C       3        3         0  0.0000000
```

**Diagnostics & reproducibility**

``` r

truth <- c(TRUE, TRUE, TRUE, FALSE)  # pretend "kept" after CFA
signal_detection(csv$decision == "significant", truth)
#> $confusion
#>               Actual
#> Predicted      Retain Not retained
#>   Retain            0            0
#>   Not retained      3            1
#> 
#> $accuracy
#> [1] 0.25
#> 
#> $sensitivity
#> [1] 0
#> 
#> $specificity
#> [1] 1
#> 
#> $phi
#> [1] NA
#> 
#> $chisq
#> [1] NA
#> 
#> $p
#> [1] NA

csv2_sig <- sample(c(TRUE, FALSE), nrow(csv), replace = TRUE)
reproducibility_phi(csv$decision == "significant", csv2_sig)
#> $table
#>               Pretest2
#> Pretest1       Retain Not retained
#>   Retain            0            0
#>   Not retained      1            3
#> 
#> $phi
#> [1] NA
#> 
#> $chisq
#> [1] NA
#> 
#> $p
#> [1] NA
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
#> same as a proportion. power at p: the exact probability of reaching the
#> required count if each judge assigns the item to its target with probability
#> p.
```

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
#>   item target n_total  n n_missing n_target       psa
#> 1   I1      A      12 12         0        9 0.7500000
#> 2   I2      A      12 12         0        5 0.4166667
#> 3   I3      B      12 12         0        2 0.1666667
#> 4   I4      B      12 12         0        5 0.4166667
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
#> Items: 3 | Raters: 16 | Target scales: 2 | Constructs: 3 
#> Design: within-judge ratings | Scale: 1 to 5 
#> Item inference: one-way repeated-measures ANOVA (Greenhouse-Geisser corrected omnibus p) plus planned paired target-versus-orbiting contrasts 
#> Planned-contrast adjustment: none 
#> Judges: naive 
#> 
#> 3 item(s) meet the full item-level screening criterion; 0 item(s) are flagged for review.
#> 
#> Item-level evidence:
#>  item target n_complete strongest_competitor   htc   htd p_value max_contrast_p
#>    I1      A         16                    C 0.825 0.492       0              0
#>    I2      A         16                    C 0.887 0.508       0              0
#>    I3      B         16                    C 0.875 0.539       0              0
#>  recommendation
#>          Retain
#>          Retain
#>          Retain
#> 
#> Target-scale Colquitt benchmark summary:
#>  target n_items n_htc n_htd mean_htc htc_strength mean_htd htd_strength
#>       A       2     2     2    0.856     Moderate    0.500  Very Strong
#>       B       1     1     1    0.875       Strong    0.539  Very Strong
#>  benchmark_set
#>        overall
#>        overall
#> 
#> Colquitt labels are empirical percentile norms for scale-level HTC/HTD averages, not universal cutoffs.
#> 'Review' is not an automatic deletion decision. Consider construct definitions, item wording,
#> orbiting-construct choice, domain coverage, and qualitative judge feedback.
summary(rating_fit)
#> Summary of construct-rating content-validity evidence
#> ---------------------------------------------------
#> Retain: 3 of 3 item(s)
#> Review: 0 of 3 item(s)
#> 
#> Target-scale evidence:
#>  target n_items n_htc n_htd n_retain n_review mean_htc htc_strength mean_htd
#>       A       2     2     2        2        0    0.856     Moderate    0.500
#>       B       1     1     1        1        0    0.875       Strong    0.539
#>  htd_strength overall_strength
#>   Very Strong         Moderate
#>   Very Strong           Strong
#> 
#> A: Generally supportive normative standing, with at least one content-validity dimension in the moderate range; inspect weaker items and construct overlap before finalizing the scale.
#> B: Strong normative standing on the weaker of definitional correspondence (HTC) and distinctiveness (HTD).
#> 
#> All analyzed items met the item-level inferential screening criterion.
#> 
#> Interpret these results alongside theory, domain coverage, and qualitative feedback.
#> The analysis does not by itself establish comprehensiveness or the full content-validity argument.
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
#> Mean Aiken V: 0.944 | S-CVI/Ave: 1 | S-CVI/UA: 1 
#> Strong support: 3 | Support: 0 | Review: 0 
#> 
#>   item N     V ci_low ci_high I_CVI kappa_mod recommendation
#>  Item1 6 1.000  0.824   1.000     1         1 Strong support
#>  Item2 6 0.944  0.742   0.990     1         1 Strong support
#>  Item3 6 0.889  0.672   0.969     1         1 Strong support
#> 
#> CVI thresholds shown by the workflow are common panel-size guidelines, not universal validity cutoffs.
#> 
#> Use quantitative indices alongside expert comments, construct coverage, and comprehensibility review.
summary(expert_fit)
#> Summary of expert-panel content-validity evidence
#> ---------------------------------------------
#> Mode: relevance 
#> Supported: 3 | Review: 0
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
#> 1 Item1 5         0 0.65 0.4328543 0.8188082 Penfield-Giacobbi score
#> 2 Item2 5         0 0.75 0.5312991 0.8881383 Penfield-Giacobbi score
#> 3 Item3 5         0 0.60 0.3865815 0.7811935 Penfield-Giacobbi score
#> 4 Item4 5         0 0.35 0.1811918 0.5671457 Penfield-Giacobbi score
#> 5 Item5 5         0 0.55 0.3420853 0.7418021 Penfield-Giacobbi score
#> 6 Item6 5         0 0.55 0.3420853 0.7418021 Penfield-Giacobbi score

cvr(essential = c(8,10,5), N = 12)
#>    item ne  N        cvr    p_value critical_ne critical_cvr  pass
#> 1 Item1  8 12  0.3333333 0.19384766          10    0.6666667 FALSE
#> 2 Item2 10 12  0.6666667 0.01928711          10    0.6666667  TRUE
#> 3 Item3  5 12 -0.1666667 0.80615234          10    0.6666667 FALSE

M <- matrix(sample(0:1, 6*5, replace = TRUE, prob = c(.3,.7)), nrow = 6)
cvi(M)
#> Content Validity Index (CVI)
#> ----------------------------
#> Items analyzed: 5 
#> Judges per item: 6 
#> S-CVI/Ave: 0.700 
#> S-CVI/UA : 0.200 
#> 
#> Item-level results (modified kappa is chance-corrected):
#>   item A N I_CVI    Pc kappa_mod
#>  Item1 6 6 1.000 0.016     1.000
#>  Item2 3 6 0.500 0.312     0.273
#>  Item3 4 6 0.667 0.234     0.565
#>  Item4 3 6 0.500 0.312     0.273
#>  Item5 5 6 0.833 0.094     0.816
#> 
#> Interpretation should consider panel size, item purpose, and qualitative expert feedback;
#> CVI statistics alone do not establish comprehensive content validity.

ioc_df <- data.frame(
  item = rep(paste0("I",1:2), each = 9),
  judge = rep(1:3, times = 6),
  objective = rep(rep(LETTERS[1:3], each = 3), times = 2),
  score = sample(c(-1,0,1), 18, replace = TRUE)
)
ioc(ioc_df)
#>   item objective n_total n_judges n_missing        ioc
#> 1   I1         A       3        3         0  0.3333333
#> 2   I1         B       3        3         0  0.3333333
#> 3   I1         C       3        3         0 -0.3333333
#> 4   I2         A       3        3         0  0.0000000
#> 5   I2         B       3        3         0  0.0000000
#> 6   I2         C       3        3         0 -0.6666667
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
#> Exact item-sort planning analysis
#> ---------------------------------
#> Retention rule: p0 = 0.50, alpha = 0.050
#> 
#>   N true_p critical_n_target minimum_observed_psa power
#>  20   0.65                15                0.750 0.245
#>  30   0.65                20                0.667 0.508
#>  20   0.75                15                0.750 0.617
#>  30   0.75                20                0.667 0.894
#> 
#> Power is the exact probability of reaching the required target-assignment count
#> under the assumed true target-assignment probability.
```

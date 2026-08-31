
<!-- README.md is generated from README.Rmd. Please edit that file -->

# contentvalidR

<!-- badges: start -->

[![R-CMD-check](https://github.com/JUhalt/contentvalidR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/JUhalt/contentvalidR/actions/workflows/R-CMD-check.yaml)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
<!-- badges: end -->

**contentvalidR** provides quantitative tools for substantive and
content-oriented scale pretesting. The package is being developed around
three complementary workflows:

1.  **Item sorting** — Anderson & Gerbing (1991) Psa/Csv, exact
    item-level inference following Howard & Melloy (2016), and
    scale-level empirical norms from Colquitt et al. (2019).
2.  **Construct ratings** — Hinkin & Tracey (1999) fully crossed
    ratings, HTC/HTD, Greenhouse-Geisser-aware repeated-measures item
    screening, and Colquitt et al. (2019) scale-level norms.
3.  **Expert panels** — Aiken’s V, Lawshe CVR, CVI/modified kappa, and
    item-objective congruence.

The design goal is **interpretable output rather than coefficient
dumps**. Recommended workflow functions summarize what the evidence
supports, flag items that need attention, and distinguish statistical
screening from substantive decisions.

> Quantitative content-validity statistics are one part of a broader
> validity argument. They complement, rather than replace, construct
> definition, domain coverage, qualitative expert feedback, cognitive
> interviewing, and other evidence about relevance, comprehensiveness,
> and comprehensibility.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("JUhalt/contentvalidR")
```

## Recommended item-sort workflow

``` r
library(contentvalidR)

sort_dat <- data.frame(
  item = rep(c("Clear 1", "Clear 2", "Needs review"), each = 20),
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
#> Items: 3 | Raters: 20 | Target scales: 1 
#> Item inference: Howard-Melloy exact target-count test (p0 = 0.50, alpha = 0.050) 
#> Judges: naive 
#> 
#> 2 item(s) meet the exact target-assignment criterion; 1 item(s) are flagged for review.
#> Review: Needs review 
#> 
#> Item-level evidence:
#>          item target  n n_target competitor psa csv p_value recommendation
#>       Clear 1      A 20       18          B 0.9 0.8   0.000         Retain
#>       Clear 2      A 20       16          B 0.8 0.6   0.006         Retain
#>  Needs review      A 20       12          B 0.6 0.2   0.252         Review
#> 
#> Scale-level Colquitt benchmark summary:
#>  target n_items mean_psa psa_strength mean_csv csv_strength
#>       A       3    0.767     Moderate    0.533     Moderate
#>                     benchmark_set
#>  Overall (not correlation-normed)
#> 
#> Colquitt labels are empirical percentile norms derived from scale-level averages,
#> not universal cutoffs or automatic scale-retention rules.
#> 'Review' is not an automatic deletion decision. Use theory, construct-domain coverage,
#> item wording, and qualitative judge feedback alongside these statistics.
summary(fit)
#> Summary of item-sort content-validity evidence
#> -------------------------------------------
#> Retain: 2 of 3 item(s)
#> Review: 1 of 3 item(s)
#> 
#> Target-scale evidence:
#>  target n_items n_retain n_review mean_psa psa_strength mean_csv csv_strength
#>       A       3        2        1    0.767     Moderate    0.533     Moderate
#>  overall_strength
#>          Moderate
#> 
#> A: Generally supportive normative standing, with at least one dimension in the moderate range; review weaker items before finalizing.
#> 
#> Items needing attention:
#>          item target competitor psa csv p_value
#>  Needs review      A          B 0.6 0.2   0.252
#>                                    issue recommendation
#>  Target favored, exact criterion not met         Review
#> 
#> Interpret scale norms and item flags alongside theory, domain coverage, and qualitative feedback.
#> This analysis does not by itself establish comprehensiveness or the full content-validity argument.
```

The workflow deliberately separates two levels of evidence:

- **Item level:** Psa/Csv plus the exact Howard-Melloy target-count rule
  produce **Retain**, **Review**, or **Insufficient data** flags. The
  output also names the strongest competing construct so a weak item is
  diagnostically useful rather than just “non-significant.”
- **Target-scale level:** Psa and Csv are averaged across the target
  scale’s items and interpreted using Colquitt et al. (2019)’s empirical
  percentile norms for definitional correspondence and distinctiveness.
  This matches how those norms were constructed.

`Review` deliberately does **not** mean automatic deletion. Likewise,
Colquitt categories such as *Strong* or *Moderate* are empirical
normative standing, not universal pass/fail cutoffs.

### Correlation-conditional Colquitt norms

If substantive data provide the average correlation between a focal
scale and its orbiting scales, the workflow can select Colquitt et al.’s
correlation-conditional norm set:

``` r
sort_validity(sort_dat, orbiting_r = .42)$scale_summary
#>   target n_items n_items_usable n_retain n_review  mean_psa psa_strength
#> 1      A       3              3        2        1 0.7666667     Moderate
#>    mean_csv csv_strength orbiting_r
#> 1 0.5333333     Moderate       0.42
#>                                        benchmark_set benchmark_applicable
#> 1 More moderate focal-orbiting correlation (.35-.50)                 TRUE
#>   overall_strength
#> 1         Moderate
#>                                                                                                                             evidence
#> 1 Generally supportive normative standing, with at least one dimension in the moderate range; review weaker items before finalizing.
colquitt_benchmarks("csv", orbiting_r = .42)
#>   statistic benchmark_set                                    benchmark_label
#> 1       csv      moderate More moderate focal-orbiting correlation (.35-.50)
#> 2       csv      moderate More moderate focal-orbiting correlation (.35-.50)
#> 3       csv      moderate More moderate focal-orbiting correlation (.35-.50)
#> 4       csv      moderate More moderate focal-orbiting correlation (.35-.50)
#> 5       csv      moderate More moderate focal-orbiting correlation (.35-.50)
#>   interpretation percentile minimum
#> 1    Very Strong  80th-99th    0.83
#> 2         Strong  60th-79th    0.61
#> 3       Moderate  40th-59th    0.52
#> 4           Weak  20th-39th    0.01
#> 5        Lack of   0th-19th    -Inf
```

The published norms were developed with **naive judges representative of
the target population**. If the sort used expert judges, declare that
explicitly; the package will suppress Colquitt labels rather than apply
an unsupported benchmark:

``` r
sort_validity(sort_dat, judge_type = "expert")$scale_summary
#>   target n_items n_items_usable n_retain n_review  mean_psa psa_strength
#> 1      A       3              3        2        1 0.7666667         <NA>
#>    mean_csv csv_strength orbiting_r                    benchmark_set
#> 1 0.5333333         <NA>         NA Overall (not correlation-normed)
#>   benchmark_applicable overall_strength
#> 1                FALSE             <NA>
#>                                                                              evidence
#> 1 Colquitt norms not applied because this workflow was marked as using expert judges.
```

### Exact planning rather than a judge-count rule of thumb

``` r
sort_power(N = c(20, 30, 40), true_p = c(.60, .70, .80))
#> Exact item-sort planning analysis
#> ---------------------------------
#> Retention rule: p0 = 0.50, alpha = 0.050
#> 
#>   N true_p critical_n_target minimum_observed_psa power
#>  20    0.6                15                0.750 0.126
#>  30    0.6                20                0.667 0.291
#>  40    0.6                26                0.650 0.317
#>  20    0.7                15                0.750 0.416
#>  30    0.7                20                0.667 0.730
#>  40    0.7                26                0.650 0.807
#>  20    0.8                15                0.750 0.804
#>  30    0.8                20                0.667 0.974
#>  40    0.8                26                0.650 0.992
#> 
#> Power is the exact probability of reaching the required target-assignment count
#> under the assumed true target-assignment probability.
```

`sort_power()` gives the exact probability of reaching the Howard-Melloy
retention count under each planned `N` and assumed true
target-assignment probability.

### Low-level statistics

Researchers who need the component statistics directly can still use:

``` r
compute_psa(sort_dat)
#>           item target n_total  n n_missing n_target psa
#> 1      Clear 1      A      20 20         0       18 0.9
#> 2      Clear 2      A      20 20         0       16 0.8
#> 3 Needs review      A      20 20         0       12 0.6
compute_csv(sort_dat)
#>           item target n_total  n n_missing n_target competitor n_other_max csv
#> 1      Clear 1      A      20 20         0       18          B           2 0.8
#> 2      Clear 2      A      20 20         0       16          B           4 0.6
#> 3 Needs review      A      20 20         0       12          B           8 0.2
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
interpret_colquitt(.70, "csv")
#>   statistic value benchmark_set                  benchmark_label interpretation
#> 1       csv   0.7       overall Overall (not correlation-normed)         Strong
#>   applicable
#> 1       TRUE
#>                                                                           note
#> 1 Empirical percentile norm from scale-level averages; not a universal cutoff.
```

Missing assignments are excluded itemwise and are reported explicitly in
`n_missing` so the effective denominator is visible.

## Recommended construct-rating workflow

In the Hinkin-Tracey design, the **same judge rates each item against
every construct definition**. `rating_validity()` treats that dependence
explicitly rather than analyzing the ratings as independent groups.

``` r
set.seed(12)
rating_dat <- expand.grid(
  item = c("A1", "A2", "B1"),
  rater = 1:20,
  construct = c("A", "B", "C")
)
rating_dat$target_construct <- ifelse(rating_dat$item == "B1", "B", "A")
rating_dat$rating <- ifelse(
  rating_dat$construct == rating_dat$target_construct,
  pmin(5, pmax(1, round(rnorm(nrow(rating_dat), 4.4, .6)))),
  pmin(5, pmax(1, round(rnorm(nrow(rating_dat), 2.1, .7))))
)

rfit <- rating_validity(rating_dat, scale_min = 1, scale_max = 5)
rfit
#> contentvalidR construct-rating analysis
#> ---------------------------------------
#> Items: 3 | Raters: 20 | Target scales: 2 | Constructs: 3 
#> Design: within-judge ratings | Scale: 1 to 5 
#> Item inference: one-way repeated-measures ANOVA (Greenhouse-Geisser corrected omnibus p) plus planned paired target-versus-orbiting contrasts 
#> Planned-contrast adjustment: none 
#> Judges: naive 
#> 
#> 3 item(s) meet the full item-level screening criterion; 0 item(s) are flagged for review.
#> 
#> Item-level evidence:
#>  item target n_complete strongest_competitor  htc   htd p_value max_contrast_p
#>    A1      A         20                    C 0.88 0.619       0              0
#>    A2      A         20                    B 0.84 0.531       0              0
#>    B1      B         20                    C 0.89 0.637       0              0
#>  recommendation
#>          Retain
#>          Retain
#>          Retain
#> 
#> Target-scale Colquitt benchmark summary:
#>  target n_items n_htc n_htd mean_htc htc_strength mean_htd htd_strength
#>       A       2     2     2     0.86     Moderate    0.575  Very Strong
#>       B       1     1     1     0.89       Strong    0.637  Very Strong
#>  benchmark_set
#>        overall
#>        overall
#> 
#> Colquitt labels are empirical percentile norms for scale-level HTC/HTD averages, not universal cutoffs.
#> 'Review' is not an automatic deletion decision. Consider construct definitions, item wording,
#> orbiting-construct choice, domain coverage, and qualitative judge feedback.
summary(rfit)
#> Summary of construct-rating content-validity evidence
#> ---------------------------------------------------
#> Retain: 3 of 3 item(s)
#> Review: 0 of 3 item(s)
#> 
#> Target-scale evidence:
#>  target n_items n_htc n_htd n_retain n_review mean_htc htc_strength mean_htd
#>       A       2     2     2        2        0     0.86     Moderate    0.575
#>       B       1     1     1        1        0     0.89       Strong    0.637
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

The workflow combines two descriptive indices with direct item-level
screening:

- **HTC** (Hinkin-Tracey correspondence): how strongly ratings match the
  intended definition;
- **HTD** (Hinkin-Tracey distinctiveness): how much intended-definition
  ratings exceed orbiting-definition ratings;
- a **one-way repeated-measures ANOVA** for each item; and
- **planned paired contrasts** comparing the target definition with each
  orbiting definition.

As with the item-sort workflow, `Retain` and `Review` are screening
labels rather than automatic editorial decisions. The output names the
strongest orbiting competitor so a weak item tells the researcher
*where* the conceptual overlap appears. Colquitt HTC/HTD labels are
applied to target-scale averages, not treated as universal item-level
cutoffs.

Low-level components remain available:

``` r
htc(rating_dat, scale_min = 1, scale_max = 5)
#>   item target n_target target_mean anchors  htc
#> 1   A1      A       20        4.40       5 0.88
#> 2   A2      A       20        4.20       5 0.84
#> 3   B1      B       20        4.45       5 0.89
htd(rating_dat, scale_min = 1, scale_max = 5)
#>   item target n_complete n_pairs target_mean_complete strongest_competitor
#> 1   A1      A         20      40                 4.40                    C
#> 2   A2      A         20      40                 4.20                    B
#> 3   B1      B         20      40                 4.45                    C
#>   competitor_mean anchors     htd
#> 1            1.95       5 0.61875
#> 2            2.10       5 0.53125
#> 3            2.00       5 0.63750
anova_content(rating_dat)
#>   item target design n_raters n_complete n_constructs target_mean
#> 1   A1      A within       20         20            3        4.40
#> 2   A2      A within       20         20            3        4.20
#> 3   B1      B within       20         20            3        4.45
#>   strongest_competitor competitor_mean         F df1 df2            p
#> 1                    C            1.95 108.55245   2  38 1.941920e-16
#> 2                    B            2.10  66.92593   2  38 3.531492e-13
#> 3                    C            2.00  94.20683   2  38 1.873865e-15
#>   epsilon_gg   df1_gg   df2_gg         p_gg     p_screen partial_eta2
#> 1  0.8571129 1.714226 32.57029 2.109513e-14 2.109513e-14    0.8510417
#> 2  0.7606524 1.521305 28.90479 1.544388e-10 1.544388e-10    0.7788793
#> 3  0.9532879 1.906576 36.22494 7.805392e-15 7.805392e-15    0.8321656
#>   min_mean_diff max_contrast_p contrast_pass posthoc_pass
#> 1          2.45   4.238082e-10          TRUE         TRUE
#> 2          2.10   6.543223e-08          TRUE         TRUE
#> 3          2.45   2.290289e-10          TRUE         TRUE
```

## Expert-panel indices

``` r
# Aiken's V: judges x items
R <- matrix(sample(1:5, 5 * 4, replace = TRUE), nrow = 5)
aikens_v(R, lo = 1, hi = 5)
#>    item    V
#> 1 Item1 0.55
#> 2 Item2 0.30
#> 3 Item3 0.20
#> 4 Item4 0.40

# Lawshe CVR
cvr(essential = c(8, 10, 5), N = 12)
#>   item ne  N        cvr critical_ne critical_cvr  pass
#> 1    1  8 12  0.3333333          10    0.6666667 FALSE
#> 2    2 10 12  0.6666667          10    0.6666667  TRUE
#> 3    3  5 12 -0.1666667          10    0.6666667 FALSE

# CVI with Polit-Beck-Owen modified kappa
M <- matrix(
  c(1,1,1,1,
    1,1,1,0,
    1,1,0,0),
  nrow = 4,
  dimnames = list(NULL, c("Item1", "Item2", "Item3"))
)
cvi(M)
#> Content Validity Index (CVI)
#> ----------------------------
#> Items analyzed: 3 
#> Judges per item: 4 
#> S-CVI/Ave: 0.750 
#> S-CVI/UA : 0.333 
#> 
#> Item-level results (modified kappa is chance-corrected):
#>   item A N I_CVI    Pc kappa_mod
#>  Item1 4 4  1.00 0.062     1.000
#>  Item2 3 4  0.75 0.250     0.667
#>  Item3 2 4  0.50 0.375     0.200
#> 
#> Interpretation should consider panel size, item purpose, and qualitative expert feedback;
#> CVI statistics alone do not establish comprehensive content validity.
```

`cvi()` reports I-CVI, S-CVI/Ave, S-CVI/UA, the exact chance-agreement
probability, and modified kappa. Its print method also reminds users
that those indices do not, by themselves, establish the full
content-validity argument.

## Experimental modules

The diagnostic, simulation, and Q-factor helpers remain available while
their APIs and methodological scope are being hardened. The two
recommended primary workflows are now `sort_validity()` and
`rating_validity()`.

## Core methodological references

- Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance
  of measures in a confirmatory factor analysis with a pretest
  assessment of their substantive validities. *Journal of Applied
  Psychology, 76*(5), 732–740.
  <https://doi.org/10.1037/0021-9010.76.5.732>
- Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task
  methods: The presentation of a new statistical significance formula
  and methodological best practices. *Journal of Business and
  Psychology, 31*(1), 173–186.
  <https://doi.org/10.1007/s10869-015-9404-y>
- Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
  Content validation guidelines: Evaluation criteria for definitional
  correspondence and definitional distinctiveness. *Journal of Applied
  Psychology, 104*(10), 1243–1265. <https://doi.org/10.1037/apl0000406>
- Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance
  approach to content validation. *Organizational Research Methods,
  2*(2), 175–186. <https://doi.org/10.1177/109442819922004>
- Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an
  acceptable indicator of content validity? Appraisal and
  recommendations. *Research in Nursing & Health, 30*(4), 459–467.
  <https://doi.org/10.1002/nur.20199>

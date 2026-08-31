
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
2.  **Construct ratings** — Hinkin & Tracey (1999) rating-based
    procedures. This module remains experimental while the
    repeated-rating design is being modernized.
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

## Expert-panel indices

``` r
# Aiken's V: judges x items
R <- matrix(sample(1:5, 5 * 4, replace = TRUE), nrow = 5)
aikens_v(R, lo = 1, hi = 5)
#>    item    V
#> 1 Item1 0.40
#> 2 Item2 0.35
#> 3 Item3 0.50
#> 4 Item4 0.60

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

The rating/ANOVA, diagnostic, simulation, and Q-factor helpers remain
available while their APIs and methodological scope are being hardened.
They should currently be treated as experimental rather than as the
package’s primary public interface.

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
  2*(2), 175–186.
- Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an
  acceptable indicator of content validity? Appraisal and
  recommendations. *Research in Nursing & Health, 30*(4), 459–467.
  <https://doi.org/10.1002/nur.20199>

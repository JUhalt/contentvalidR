
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

1.  **Item sorting** — Anderson & Gerbing (1991) Psa/Csv with exact
    item-sort inference following Howard & Melloy (2016).
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
  item = rep(c("Clear item", "Needs review"), each = 20),
  rater = rep(1:20, 2),
  target_construct = rep("A", 40),
  assigned_construct = c(
    rep("A", 16), rep("B", 4),
    rep("A", 11), rep("B", 9)
  )
)

fit <- sort_validity(sort_dat)
fit
#> contentvalidR item-sort analysis
#> --------------------------------
#> Items: 2 | Raters: 20 | Observed constructs: 2 
#> Inference: Howard-Melloy exact target-count test (p0 = 0.50, alpha = 0.050) 
#> 
#> 1 item(s) meet the exact target-assignment criterion; 1 item(s) are flagged for review.
#> Review: Needs review 
#> 
#>          item target  n n_target  psa csv p_value recommendation
#>    Clear item      A 20       16 0.80 0.6   0.006         Retain
#>  Needs review      A 20       11 0.55 0.1   0.412         Review
#> 
#> 'Review' is not an automatic deletion decision. Use theory, construct-domain coverage,
#> item wording, and qualitative judge feedback alongside these statistics.
summary(fit)
#> Summary of item-sort content-validity evidence
#> -------------------------------------------
#> Retain: 1 of 2 item(s)
#> Review: 1 of 2 item(s)
#> Mean Psa: 0.675 
#> Mean Csv: 0.35 
#> 
#> Items needing attention:
#>          item target  n n_target  psa csv p_value recommendation
#>  Needs review      A 20       11 0.55 0.1   0.412         Review
#> 
#> For items flagged Review, examine weak target correspondence, overlap with an
#> orbiting construct, ambiguous wording, and qualitative judge feedback.
```

`sort_validity()` combines:

- **Psa**: proportion assigned to the intended construct;
- **Csv**: intended assignments minus the most common competing
  assignment, divided by the effective judge count;
- an **exact target-count test** following Howard & Melloy (2016); and
- a restrained recommendation: **Retain**, **Review**, or **Insufficient
  data**.

`Review` deliberately does **not** mean automatic deletion. The
researcher should examine wording, construct overlap, theoretical
coverage, and qualitative feedback before revising or removing an item.

### Low-level statistics

Researchers who need the component statistics directly can still use:

``` r
compute_psa(sort_dat)
#>           item target n_total  n n_missing n_target  psa
#> 1   Clear item      A      20 20         0       16 0.80
#> 2 Needs review      A      20 20         0       11 0.55
compute_csv(sort_dat)
#>           item target n_total  n n_missing n_target n_other_max csv
#> 1   Clear item      A      20 20         0       16           4 0.6
#> 2 Needs review      A      20 20         0       11           9 0.1
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
- Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance
  approach to content validation. *Organizational Research Methods,
  2*(2), 175–186.
- Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an
  acceptable indicator of content validity? Appraisal and
  recommendations. *Research in Nursing & Health, 30*(4), 459–467.
  <https://doi.org/10.1002/nur.20199>

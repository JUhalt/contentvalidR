
<!-- README.md is generated from README.Rmd. Please edit that file -->

``` r
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.path = "man/figures/README-",
  out.width = "100%"
)
set.seed(1)

# Ensure the package is available for this README build
if (!requireNamespace("contentvalidR", quietly = TRUE)) {
  # When building via devtools, fall back to loading the source
  devtools::load_all(quiet = TRUE)
}
```

``` r
library(contentvalidR)
```

**contentvalidR** <!-- badges: start -->
[![R-CMD-check](https://github.com/JUhalt/contentvalidR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/JUhalt/contentvalidR/actions/workflows/R-CMD-check.yaml)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
<!-- badges: end -->

**contentvalidR** provides tools for **substantive/content validity
pretesting**: - Sort-based indices from Anderson & Gerbing (1991):
**Psa** and **Csv** (+ binomial test). - Rating-based **ANOVA** approach
from Hinkin & Tracey (1999) with Tukey post-hoc. - Classic content
validity indices: **CVR**, **IOC**, **Aiken’s V**, **CVI**. -
Diagnostics (signal detection, reproducibility) and small power
simulators.

**Installation**

``` r
# install.packages("devtools")
devtools::install_github("JUhalt/contentvalidR")
```

**Quick Start**

``` r
library(contentvalidR)
```

**1) Sort-based workflow (Psa, Csv, binomial test)**

Create a tiny item-sort dataset: 4 items × 12 raters, with known
targets.

``` r
toy_sort <- data.frame(
  item = rep(paste0("I", 1:4), each = 12),
  rater = rep(1:12, 4),
  target_construct   = rep(c("A","A","B","B"), each = 12),
  assigned_construct = c(
    sample(c("A","B"), 12, TRUE, c(.80,.20)), # I1
    sample(c("A","B"), 12, TRUE, c(.65,.35)), # I2
    sample(c("A","B"), 12, TRUE, c(.70,.30)), # I3
    sample(c("A","B"), 12, TRUE, c(.45,.55))  # I4 (likely weak)
  )
)
```

Compute **Psa** and **Csv**:

``` r
psa <- compute_psa(toy_sort)
csv <- compute_csv(toy_sort)
psa
#>    item  n n_target       psa
#> I1   I1 12        9 0.7500000
#> I2   I2 12        5 0.4166667
#> I3   I3 12        2 0.1666667
#> I4   I4 12        5 0.4166667
csv
#>    item  n n_target n_other_max        csv
#> I1   I1 12        9           3  0.5000000
#> I2   I2 12        5           7 -0.1666667
#> I3   I3 12        2          10 -0.6666667
#> I4   I4 12        5           7 -0.1666667
```

Csv **significance** via a one-sided binomial test (H0: p ≤ .5):

``` r
csv$decision <- vapply(seq_len(nrow(csv)), function(i) {
  out <- csv_binom_test(n_c = csv$n_target[i], N = csv$n[i])
  out$decision
}, character(1))
csv[, c("item","n","n_target","n_other_max","csv","decision")]
#>    item  n n_target n_other_max        csv decision
#> I1   I1 12        9           3  0.5000000     n.s.
#> I2   I2 12        5           7 -0.1666667     n.s.
#> I3   I3 12        2          10 -0.6666667     n.s.
#> I4   I4 12        5           7 -0.1666667     n.s.
```

**2) Rating-based ANOVA workflow**

Raters score each item on **every construct** (Likert-style). We test
that the item’s mean on its **target** exceeds all others (ANOVA +
Tukey).

``` r
toy_ratings <- data.frame(
  item = rep(paste0("I",1:4), each = 30),
  rater = rep(1:30, times = 4),
  construct = rep(rep(LETTERS[1:3], each = 10), times = 4),
  rating = c(
    rnorm(10, 4.3, 0.4), rnorm(20, 2.6, 0.6),   # I1: A high
    rnorm(10, 4.0, 0.5), rnorm(20, 2.7, 0.6),   # I2: A high
    rnorm(10, 2.6, 0.6), rnorm(10, 4.1, 0.5), rnorm(10, 2.6, 0.6), # I3: B high
    rnorm(20, 2.6, 0.6), rnorm(10, 4.0, 0.5)    # I4: C high (we only have A–C)
  )
)
target_map <- c(I1="A", I2="A", I3="B", I4="C")
anova_content(toy_ratings, target_map = target_map)
#>   item target        F df1 df2            p posthoc_pass
#> 1   I1      A 64.46910   2  27 5.230600e-11         TRUE
#> 2   I2      A 26.74394   2  27 3.945020e-07         TRUE
#> 3   I3      B 17.31301   2  27 1.450756e-05         TRUE
#> 4   I4      C 29.66709   2  27 1.530889e-07         TRUE
```

- `p` is the omnibus ANOVA p-value.
- `posthoc_pass = TRUE` means Tukey confirmed the **target mean \> all
  others** at alpha = .05.

**3) Classic indices**

**Aiken’s V** (ordinal ratings on \[1,5\] scale), **CVR**, **CVI**, and
**IOC**.

``` r
# Aiken's V: judges (rows) x items (cols)
R <- matrix(sample(1:5, 5*6, replace = TRUE), nrow = 5,
            dimnames = list(NULL, paste0("Item", 1:6)))
aikens_v(R, lo = 1, hi = 5)
#>    item    V
#> 1 Item1 0.75
#> 2 Item2 0.20
#> 3 Item3 0.35
#> 4 Item4 0.50
#> 5 Item5 0.65
#> 6 Item6 0.55

# CVR: counts of "essential" per item with N judges
cvr(essential = c(8,10,5), N = 12)
#>   item ne  N        cvr critical_ne critical_cvr  pass
#> 1    1  8 12  0.3333333          10    0.6666667 FALSE
#> 2    2 10 12  0.6666667          10    0.6666667  TRUE
#> 3    3  5 12 -0.1666667          10    0.6666667 FALSE

# CVI: binary relevance (1/0), judges (rows) x items (cols)
M <- matrix(sample(0:1, 6*5, replace = TRUE, prob = c(.3,.7)), nrow = 6,
            dimnames = list(NULL, paste0("Item", 1:5)))
cvi(M)
#> $item_level
#>    item A N     I_CVI       Pc  kappa_mod
#> 1 Item1 4 6 0.6666667 0.343750  0.4920635
#> 2 Item2 6 6 1.0000000 0.015625  1.0000000
#> 3 Item3 4 6 0.6666667 0.343750  0.4920635
#> 4 Item4 3 6 0.5000000 0.656250 -0.4545455
#> 5 Item5 5 6 0.8333333 0.109375  0.8128655
#> 
#> $scale_level
#>   S_CVI_Ave
#> 1 0.7333333

# IOC (Rovinelli & Hambleton): scores in {-1,0,+1} by item × objective
ioc_df <- data.frame(
  item = rep(paste0("I",1:2), each = 9),
  judge = rep(1:3, times = 6),
  objective = rep(rep(LETTERS[1:3], each = 3), times = 2),
  score = sample(c(-1,0,1), 18, replace = TRUE)
)
ioc(ioc_df)
#>   item objective n_judges        ioc
#> 1   I1         A        3  0.0000000
#> 2   I2         A        3 -0.3333333
#> 3   I1         B        3  1.0000000
#> 4   I2         B        3  0.6666667
#> 5   I1         C        3 -0.3333333
#> 6   I2         C        3  0.3333333
```

**4) Diagnostics (optional)**

Compare Csv-based decisions to a known “truth” (e.g., later CFA
retention), and estimate reproducibility across two pretests.

``` r
truth <- c(TRUE, TRUE, TRUE, FALSE)  # pretend: which items would be retained
signal_detection(csv$decision == "significant", truth)
#> $confusion
#>          Actual
#> Predicted Retain Delete
#>    Retain      0      3
#>    Delete      0      1
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
#> [1] NaN
#> 
#> $chisq
#> [1] NaN
#> 
#> $p
#> [1] NaN

# pretend a second pretest's decisions:
csv2_sig <- sample(c(TRUE, FALSE), nrow(csv), replace = TRUE)
reproducibility_phi(csv$decision == "significant", csv2_sig)
#> $table
#>        sig2
#> sig1    FALSE TRUE
#>   FALSE     1    3
#> 
#> $phi
#> [1] 0.5
#> 
#> $chisq
#> [1] 1
#> 
#> $p
#> [1] 0.3173105
```

**5) Power (quick sims; keep small in README)**

``` r
simulate_csv_power(N = 20, true_p = 0.65, reps = 200)      # ~fast
#> [1] 0.23
simulate_anova_power(n_raters = 20, mean_diff = 0.5,
                     sd = 1, k_constructs = 3, reps = 100) # ~fast
#> [1] 0.34
```

**Guidance** - When to use what? Use Psa/Csv for quick sort-based
pretests; **ANOVA** for rating studies needing inferential evidence;
triangulate with **Aiken’s V**, **CVR**, **CVI**, **IOC** for
expert-panel contexts. - Keep pretest **N (raters)** realistic (20–40
can go a long way). - Be explicit about **target constructs** and
instructions to raters.

**Citing the methods** - Anderson, J. C., & Gerbing, D. W. (1991).
Predicting the performance of measures in a confirmatory factor analysis
with a pretest assessment of their substantive validities.

- Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance
  approach to content validation.

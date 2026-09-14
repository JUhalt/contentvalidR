# Content Validity Index (CVI)

Computes item-level Content Validity Index (I-CVI), scale-level average
CVI (S-CVI/Ave), universal-agreement CVI (S-CVI/UA), and the modified
kappa described by Polit, Beck, and Owen (2007).

For each item, modified kappa adjusts I-CVI for chance agreement using
the probability of observing exactly `A` agreements among `N` judges:

\$\$P_c = {N \choose A}(0.5)^N\$\$

and

\$\$k^\* = (I_CVI - P_c) / (1 - P_c).\$\$

I-CVI is a proportion of what is usually a small panel, so an interval
is reported alongside it. The interval method is selectable; see `ci`.

## Usage

``` r
cvi(
  binary,
  na.rm = FALSE,
  ci = c("wilson", "agresti_coull", "exact", "none"),
  alpha = 0.05
)
```

## Arguments

- binary:

  Matrix/data.frame with judges in rows and items in columns, coded
  `1 = relevant` and `0 = not relevant`.

- na.rm:

  Logical. If `FALSE` (default), missing ratings are an error. If
  `TRUE`, missing ratings are removed itemwise and each item's effective
  judge count is reported in `N`.

- ci:

  Interval method for I-CVI:

  - `"wilson"` (default): the Wilson (1927) score interval.
    Newcombe (1998) compared seven methods and recommends score
    intervals over the Wald interval.

  - `"agresti_coull"`: the adjusted Wald interval of Agresti and Coull
    (1998), which they show performs well even in small samples. Limits
    are clipped so they stay between 0 and 1.

  - `"exact"`: the Clopper and Pearson (1934) interval. It is
    conservative: Agresti and Coull (1998) show its coverage runs above
    the nominal level.

  - `"none"`: no interval is computed, and the interval columns are
    `NA`.

- alpha:

  Two-sided alpha level for the interval; `0.05` gives a 95% interval.

## Value

A classed list with:

- `item_level`: item, A, N, I_CVI, I_CVI_low, I_CVI_high, Pc, kappa_mod

- `scale_level`: S_CVI_Ave and S_CVI_UA

- `ci` and `alpha`: the interval settings used

## References

Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an
acceptable indicator of content validity? Appraisal and recommendations.
*Research in Nursing & Health, 30*(4), 459-467.
[doi:10.1002/nur.20199](https://doi.org/10.1002/nur.20199)

Wilson, E. B. (1927). Probable inference, the law of succession, and
statistical inference. *Journal of the American Statistical Association,
22*(158), 209-212.
[doi:10.1080/01621459.1927.10502953](https://doi.org/10.1080/01621459.1927.10502953)

Newcombe, R. G. (1998). Two-sided confidence intervals for the single
proportion: Comparison of seven methods. *Statistics in Medicine,
17*(8), 857-872.

Agresti, A., & Coull, B. A. (1998). Approximate is better than "exact"
for interval estimation of binomial proportions. *The American
Statistician, 52*(2), 119-126.
[doi:10.1080/00031305.1998.10480550](https://doi.org/10.1080/00031305.1998.10480550)

Clopper, C. J., & Pearson, E. S. (1934). The use of confidence or
fiducial limits illustrated in the case of the binomial. *Biometrika,
26*(4), 404-413.
[doi:10.1093/biomet/26.4.404](https://doi.org/10.1093/biomet/26.4.404)

## Examples

``` r
M <- matrix(
  c(1,1,1,1, 1,1,1,0, 1,1,0,0),
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
#>   item A N I_CVI I_CVI_low I_CVI_high    Pc kappa_mod
#>  Item1 4 4  1.00     0.510      1.000 0.062     1.000
#>  Item2 3 4  0.75     0.301      0.954 0.250     0.667
#>  Item3 2 4  0.50     0.150      0.850 0.375     0.200
#> 
#> 95% intervals for proportions: Wilson score (the default). Newcombe (1998)
#> compared seven methods and recommends score intervals over the Wald
#> interval. An interval reflects how few ratings an item received, not
#> whether the right judges were chosen.
#> 
#> Interpretation should consider panel size, item purpose, and qualitative expert feedback;
#> CVI statistics alone do not establish comprehensive content validity.
cvi(M, ci = "exact")
#> Content Validity Index (CVI)
#> ----------------------------
#> Items analyzed: 3 
#> Judges per item: 4 
#> S-CVI/Ave: 0.750 
#> S-CVI/UA : 0.333 
#> 
#> Item-level results (modified kappa is chance-corrected):
#>   item A N I_CVI I_CVI_low I_CVI_high    Pc kappa_mod
#>  Item1 4 4  1.00     0.398      1.000 0.062     1.000
#>  Item2 3 4  0.75     0.194      0.994 0.250     0.667
#>  Item3 2 4  0.50     0.068      0.932 0.375     0.200
#> 
#> 95% intervals for proportions: Clopper-Pearson exact. This is conservative:
#> Agresti and Coull (1998) show its coverage runs above the nominal level, so
#> intervals are wider than they need to be. An interval reflects how few
#> ratings an item received, not whether the right judges were chosen.
#> 
#> Interpretation should consider panel size, item purpose, and qualitative expert feedback;
#> CVI statistics alone do not establish comprehensive content validity.
```

# Content Validity Index (CVI)

Computes item-level Content Validity Index (I-CVI), scale-level average
CVI (S-CVI/Ave), universal-agreement CVI (S-CVI/UA), and the modified
kappa described by Polit, Beck, and Owen (2007).

For each item, modified kappa adjusts I-CVI for chance agreement using
the probability of observing exactly `A` agreements among `N` judges:

\$\$P_c = {N \choose A}(0.5)^N\$\$

and

\$\$k^\* = (I_CVI - P_c) / (1 - P_c).\$\$

## Usage

``` r
cvi(binary, na.rm = FALSE)
```

## Arguments

- binary:

  Matrix/data.frame with judges in rows and items in columns, coded
  `1 = relevant` and `0 = not relevant`.

- na.rm:

  Logical. If `FALSE` (default), missing ratings are an error. If
  `TRUE`, missing ratings are removed itemwise and each item's effective
  judge count is reported in `N`.

## Value

A classed list with:

- `item_level`: item, A, N, I_CVI, Pc, kappa_mod

- `scale_level`: S_CVI_Ave and S_CVI_UA

## References

Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an
acceptable indicator of content validity? Appraisal and recommendations.
*Research in Nursing & Health, 30*(4), 459-467.
[doi:10.1002/nur.20199](https://doi.org/10.1002/nur.20199)

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
#>   item A N I_CVI    Pc kappa_mod
#>  Item1 4 4  1.00 0.062     1.000
#>  Item2 3 4  0.75 0.250     0.667
#>  Item3 2 4  0.50 0.375     0.200
#> 
#> Interpretation should consider panel size, item purpose, and qualitative expert feedback;
#> CVI statistics alone do not establish comprehensive content validity.
```

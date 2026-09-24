# Panel-level agreement among expert raters

Summarizes how consistently a panel rated the whole item set, as one
coefficient with a bootstrap interval. This is panel-level evidence. It
complements, and does not replace, item-level indices such as I-CVI and
modified kappa, which describe one item at a time.

Two coefficients are available:

- `"krippendorff"` (default): Krippendorff's alpha, computed from the
  coincidence matrix as described by Krippendorff (2011). It works with
  any number of raters and with missing ratings. Zapf et al. (2016)
  recommend it specifically when data are ordinal or ratings are
  missing, which is typical of expert panels. It is a general
  reliability coefficient (Hayes & Krippendorff, 2007); no publication
  applying it specifically to content-validity panels was found.

- `"ac1"`: Gwet's (2008) AC1, designed for high-agreement data where
  kappa-type coefficients fall. It is never the default: Vach and
  Gerke (2023) show that it rises as ratings concentrate in one category
  even at a fixed level of agreement, and that it can be non-zero when
  raters are independent. Its printed output always repeats that
  critique. AC1 treats the supplied values as unordered categories.

## Usage

``` r
panel_agreement(
  ratings,
  method = c("krippendorff", "ac1"),
  level = c("ordinal", "nominal", "interval"),
  B = 1000,
  alpha = 0.05,
  seed = NULL
)
```

## Arguments

- ratings:

  A numeric matrix or data frame with raters in rows and items in
  columns. Missing ratings are allowed.

- method:

  `"krippendorff"` (default) or `"ac1"`.

- level:

  Measurement level for Krippendorff's alpha: `"ordinal"` (default),
  `"nominal"`, or `"interval"`. Ignored for AC1.

- B:

  Number of bootstrap resamples. Use `0` to skip the interval.

- alpha:

  Two-sided error rate for the bootstrap interval; `0.05` gives a 95%
  interval. This is not Krippendorff's alpha.

- seed:

  Optional seed for a reproducible interval.

## Value

An object of class `contentvalid_agreement`: a list with `method`,
`level`, `estimate`, `ci_low`, `ci_high`, `alpha`, `B`, `n_boot_usable`,
`n_items` (items rated by at least two raters), `n_raters`,
`percent_agreement` (share of within-item rating pairs that are
identical), `interpretation`, and `critique`.

## Why a close-agreeing panel can have a low alpha

Alpha compares observed disagreement with the disagreement expected if
the same ratings were assigned to items at random. When ratings cluster
on a few values, as they do when nearly every item is rated relevant,
very little disagreement is expected by chance, so even a few
disagreements pull alpha down. The output reports the share of identical
rating pairs alongside the coefficient so this pattern is visible rather
than misread as a poor panel.

## Interval

The interval is a percentile bootstrap that resamples items with all of
their ratings intact, the procedure Zapf et al. (2016) evaluated. They
found Krippendorff's original bootstrap reached only about 60% coverage
because it ignores dependence between raters. Zapf et al. evaluated the
procedure for Fleiss' kappa and Krippendorff's alpha; applying it to AC1
is this package's extension. Intervals vary slightly between runs unless
`seed` is set.

## References

Hayes, A. F., & Krippendorff, K. (2007). Answering the call for a
standard reliability measure for coding data. *Communication Methods and
Measures, 1*(1), 77-89.
[doi:10.1080/19312450709336664](https://doi.org/10.1080/19312450709336664)

Krippendorff, K. (2011). *Computing Krippendorff's alpha-reliability.*
Annenberg School for Communication, University of Pennsylvania.
<https://repository.upenn.edu/items/034a6030-c584-4d14-9d3d-7b7e8d16df20>

Zapf, A., Castell, S., Morawietz, L., & Karch, A. (2016). Measuring
inter-rater reliability for nominal data: Which coefficients and
confidence intervals are appropriate? *BMC Medical Research Methodology,
16*, 93.
[doi:10.1186/s12874-016-0200-9](https://doi.org/10.1186/s12874-016-0200-9)

Gwet, K. L. (2008). Computing inter-rater reliability and its variance
in the presence of high agreement. *British Journal of Mathematical and
Statistical Psychology, 61*(1), 29-48.
[doi:10.1348/000711006X126600](https://doi.org/10.1348/000711006X126600)

Wongpakaran, N., Wongpakaran, T., Wedding, D., & Gwet, K. L. (2013). A
comparison of Cohen's kappa and Gwet's AC1 when calculating inter-rater
reliability coefficients: A study conducted with personality disorder
samples. *BMC Medical Research Methodology, 13*, 61.
[doi:10.1186/1471-2288-13-61](https://doi.org/10.1186/1471-2288-13-61)

Vach, W., & Gerke, O. (2023). Gwet's AC1 is not a substitute for Cohen's
kappa: A comparison of basic properties. *MethodsX, 10*, 102212.

Feinstein, A. R., & Cicchetti, D. V. (1990). High agreement but low
kappa: I. The problems of two paradoxes. *Journal of Clinical
Epidemiology, 43*(6), 543-549.
[doi:10.1016/0895-4356(90)90158-L](https://doi.org/10.1016/0895-4356%2890%2990158-L)

## See also

[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
for item-level expert-panel evidence.

## Examples

``` r
ratings <- rbind(
  c(4, 4, 3, 2, 4), c(4, 3, 3, 2, 4), c(3, 4, 4, 1, 4), c(4, 4, 3, 2, 3)
)
panel_agreement(ratings, seed = 1)
#> contentvalidR panel agreement
#> -----------------------------
#> Items rated by two or more raters: 5 | Raters: 4
#> Krippendorff's alpha (ordinal) = .56, 95% CI [-.27, .78]
#> Identical rating pairs: 50.0%
#> 
#> Alpha compares the disagreement observed within items with the disagreement
#> expected if these same ratings were assigned to items at random: 1 means
#> perfect agreement and 0 means agreement no better than chance. Alpha falls
#> when ratings cluster on a few values, because little disagreement is then
#> expected by chance. A high share of identical rating pairs alongside a low
#> alpha reflects that clustering, which is common when nearly every item is
#> rated relevant, and is not by itself evidence of a poor panel.
#> 
#> Krippendorff's alpha is the default because it handles ordinal ratings and
#> missing ratings (Zapf et al., 2016). It is a general reliability coefficient;
#> no publication applying it specifically to content-validity panels was found.
#> 
#> The interval resamples items with all of their ratings, following Zapf et al.
#> (2016), and varies slightly between runs unless `seed` is set.
#> 
#> Panel agreement describes how consistently raters rated these items. It does
#> not show that the items are relevant or that the domain is covered.
panel_agreement(ratings, level = "interval", B = 0)
#> contentvalidR panel agreement
#> -----------------------------
#> Items rated by two or more raters: 5 | Raters: 4
#> Krippendorff's alpha (interval) = .70
#> Identical rating pairs: 50.0%
#> 
#> Alpha compares the disagreement observed within items with the disagreement
#> expected if these same ratings were assigned to items at random: 1 means
#> perfect agreement and 0 means agreement no better than chance. Alpha falls
#> when ratings cluster on a few values, because little disagreement is then
#> expected by chance. A high share of identical rating pairs alongside a low
#> alpha reflects that clustering, which is common when nearly every item is
#> rated relevant, and is not by itself evidence of a poor panel.
#> 
#> Krippendorff's alpha is the default because it handles ordinal ratings and
#> missing ratings (Zapf et al., 2016). It is a general reliability coefficient;
#> no publication applying it specifically to content-validity panels was found.
#> 
#> Panel agreement describes how consistently raters rated these items. It does
#> not show that the items are relevant or that the domain is covered.
panel_agreement(ratings >= 3, method = "ac1", B = 0)
#> contentvalidR panel agreement
#> -----------------------------
#> Items rated by two or more raters: 5 | Raters: 4
#> Gwet's AC1 = 1.00
#> Identical rating pairs: 100.0%
#> 
#> AC1 compares observed agreement with the agreement expected by chance,
#> estimated so that it stays high when nearly every rating falls in one
#> category (Gwet, 2008).
#> 
#> Gwet's AC1 is available but is not the default. Vach and Gerke (2023) show
#> that it rises as ratings concentrate in one category even when agreement is
#> unchanged, that it can be non-zero when raters are independent, and that
#> benchmark labels developed for kappa, such as Landis and Koch's, must not be
#> applied to it.
#> 
#> Panel agreement describes how consistently raters rated these items. It does
#> not show that the items are relevant or that the domain is covered.
```

# Analyze judge and rater heterogeneity in content-validity ratings

Examines whether content-validity conclusions depend on the particular
judges who happened to serve on the panel, rather than reporting only
aggregate indices that average heterogeneity away.

The workflow reports four complementary kinds of evidence:

- **Generalizability.** How dependably the panel's ratings would
  reproduce with a different panel of the same size, via
  [`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md).

- **Severity.** How harsh or lenient each judge is relative to the
  panel, both in raw rating units and, where estimable, on a logit scale
  from a many-facet Rasch model fitted as a logistic regression.

- **Response style.** How much each judge differentiates among items,
  and how much they concentrate on middle or extreme categories.

- **Influence.** Which items would change their CVI-based review status
  if any single judge were removed from the panel.

A judge flagged for `Review` is not a judge to discard. Disagreement may
be substantive expertise rather than error, and removing inconvenient
judges is not a validity procedure. The flag identifies where a
conclusion rests on one person's ratings and therefore deserves a closer
look.

## Usage

``` r
judge_validity(
  ratings,
  lo = 1,
  hi = 4,
  relevance_cut = NULL,
  na.rm = FALSE,
  bias_correct = TRUE,
  severity_cut = 1,
  severity_raw_cut = NULL,
  fit_range = c(0.5, 1.5)
)
```

## Arguments

- ratings:

  A judges-by-items numeric matrix or data frame of relevance ratings:
  one row per judge, one column per item.

- lo, hi:

  Rating-scale bounds.

- relevance_cut:

  Lowest rating treated as relevant. Defaults to `hi - 1`.

- na.rm:

  Permit missing ratings. Generalizability analysis additionally
  requires complete cases and drops incomplete judges, reporting how
  many.

- bias_correct:

  Apply the Wright-Douglas joint-maximum-likelihood bias correction to
  logit severity estimates. See the estimation note below.

- severity_cut:

  Absolute logit severity beyond which a judge is flagged for review.

- severity_raw_cut:

  Absolute severity in rating points beyond which a judge is flagged
  when logit severity is not estimable. Defaults to a quarter of the
  scale range. Severity is signed so that positive values mean the judge
  rates lower than the panel.

- fit_range:

  Length-2 vector giving the acceptable infit/outfit mean square range.
  Values outside it flag erratic or overly predictable judges.

## Value

An object of class `contentvalid_judge` and `contentvalid_workflow`.
Unlike the item-oriented workflows, `results` has **one row per judge**.
`scale_summary` describes the panel, and `details` contains the
generalizability analysis, the facets model, raw rater effects, and the
item-level influence table.

## Estimation note

Logit severity comes from a many-facet Rasch model fitted by joint
maximum likelihood as a logistic regression, the generalized linear
model formulation described by de Boeck and Wilson (2004). Joint maximum
likelihood is known to over-disperse facet estimates in small designs.
The standard Wright-Douglas `(L-1)/L` correction is applied by default
and reported in `settings$bias_correction`, but it reduces rather than
removes that bias. Where precise severity calibration matters, marginal
maximum likelihood estimation is preferable, and the raw rating-unit
severity in `severity_raw` is free of this particular issue.

Severity is estimated from the dichotomized relevance decision,
consistent with how the package computes CVI. Judges and items showing
no variation in that decision carry no information about relative
severity and are excluded from the model, which is reported rather than
silent.

## References

Crocker, L., Llabre, M., & Miller, M. D. (1988). The generalizability of
content validity ratings. *Journal of Educational Measurement, 25*(4),
287-299.
[doi:10.1111/j.1745-3984.1988.tb00309.x](https://doi.org/10.1111/j.1745-3984.1988.tb00309.x)

Engelhard, G. (1994). Examining rater errors in the assessment of
written composition with a many-faceted Rasch model. *Journal of
Educational Measurement, 31*(2), 93-112.
[doi:10.1111/j.1745-3984.1994.tb00436.x](https://doi.org/10.1111/j.1745-3984.1994.tb00436.x)

Linacre, J. M. (1989). *Many-Facet Rasch Measurement.* MESA Press.

de Boeck, P., & Wilson, M. (2004). *Explanatory Item Response Models: A
Generalized Linear and Nonlinear Approach.* Springer.

## See also

[`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md)
for the generalizability analysis alone,
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
for the item-level expert-panel workflow.

## Examples

``` r
ratings <- rbind(
  c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
  c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(4, 3, 4, 3, 1, 2),
  c(4, 4, 3, 4, 2, 2), c(2, 2, 2, 2, 1, 1)
)
dimnames(ratings) <- list(paste0("Judge", 1:8), paste0("Item", 1:6))
fit <- judge_validity(ratings, lo = 1, hi = 4)
fit
#> Judge and rater heterogeneity
#> Judges: 8   Items: 6
#> Dependability (Phi): 0.94   Judge share of variance: 15.6%
#> 
#> Judges
#>   judge mean_rating severity(pts) differentiation n_items_flipped    status
#>  Judge1        3.17         -0.27            0.91               0 Supported
#>  Judge2        3.00         -0.10            1.18               0 Supported
#>  Judge3        3.00         -0.10            1.18               0 Supported
#>  Judge4        3.17         -0.27            0.91               0 Supported
#>  Judge5        3.17         -0.27            1.24               0 Supported
#>  Judge6        2.83          0.06            1.09               0 Supported
#>  Judge7        3.17         -0.27            0.91               0 Supported
#>  Judge8        1.67          1.23            0.48               0    Review
#> Positive severity means the judge rates lower than the panel.
#> 
#> Logit severity not estimated:
#> Judge severity could not be estimated. After removing judges and items with
#> no variation in endorsement, fewer than two judges and two items remained.
#> This usually means the panel agreed almost completely, which is a
#> substantive finding rather than an estimation failure: with near total
#> agreement there are no severity differences to recover.
#> Severity in rating points is reported instead and is used for flagging.
#> 
#> No item's review status depends on any single judge.
#> 
#> What these columns mean
#>   severity -- Judge severity. How harsh or lenient a judge is compared with
#>       the rest of the panel. Positive means the judge rates lower than the
#>       panel. Reported in logits from the facets model when it can be
#>       estimated, otherwise in rating points. (0 means typical of this
#>       panel)
#>   differentiation -- Scale use. How widely a judge spread their ratings
#>       compared with a typical judge on this panel. Values well below 1 mean
#>       the judge distinguished less among items. (1.0 is typical of this
#>       panel)
#>   phi_coefficient -- Dependability coefficient. How dependably the absolute
#>       level of the ratings would reproduce with a different panel of the
#>       same size. Penalized by judge severity differences, and usually the
#>       relevant one for content validity, where items are judged against a
#>       fixed standard. (0 to 1; never exceeds the generalizability
#>       coefficient)
#> 
#> What the status labels mean
#>   Supported -- The evidence met the criteria set for this analysis.
#>   Review -- Something here needs a closer look. This is not an instruction
#>       to delete anything.
#>   Insufficient data -- Too little usable data to reach a judgment.
#>   Each workflow also uses its own wording in the recommendation column
#>   (Retain, Strong support, Typical, Covered, and so on). Those words map
#>   onto the shared statuses above.
#> 
#> See `contentvalid_glossary()` for all terms, or set 
#> `options(contentvalidR.show_key = FALSE)` to hide this key.
#> 
#> A `Review` judge is not a judge to remove. Disagreement can be 
#> substantive expertise; the flag marks where a conclusion rests on 
#> one person's ratings.
summary(fit)
#> Summary: judge and rater heterogeneity
#> Judges: 8   Items: 6
#> Consistent with panel: 7   Flagged for review: 1   Insufficient: 0
#> 
#> Generalizability
#>   Dependability (absolute decisions): 0.942
#>   Generalizability (rank ordering):   0.968
#>   Judges needed by target:
#>  target n_judges_relative n_judges_absolute
#>     0.7                 1                 2
#>     0.8                 2                 2
#>     0.9                 3                 5
#> 
#> Judges flagged for review
#> 
#>   Judge8  (Severe)
#>     This judge is markedly more severe than the panel (1.23 rating
#>     points relative to the panel mean). Consistent severity does not
#>     invalidate their ratings, but it shifts absolute indices such as
#>     CVI, which is why the dependability coefficient is penalized by
#>     judge differences.
#> 
#> This analysis describes how much conclusions depend on these judges. 
#> It does not establish that the items cover the intended content domain.
```

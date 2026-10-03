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
  one row per judge, one column per item. A column whose name looks like
  a rater ID (such as `expert` or `rater_id`) stops the function, so
  remove it, or rename an item that has such a name.

- lo, hi:

  Rating-scale bounds.

- relevance_cut:

  Lowest rating treated as relevant. Defaults to `hi - 1`, and to `hi`
  on a two-point scale. It must lie above `lo`: at `lo` every rating
  would count as relevant.

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
model formulation described by De Boeck and Wilson (2004). Joint maximum
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
287–299.
[doi:10.1111/j.1745-3984.1988.tb00309.x](https://doi.org/10.1111/j.1745-3984.1988.tb00309.x)

De Boeck, P., & Wilson, M. (Eds.). (2004). *Explanatory item response
models: A generalized linear and nonlinear approach*. Springer.
[doi:10.1007/978-1-4757-3990-9](https://doi.org/10.1007/978-1-4757-3990-9)

Engelhard, G. (1994). Examining rater errors in the assessment of
written composition with a many-faceted Rasch model. *Journal of
Educational Measurement, 31*(2), 93–112.
[doi:10.1111/j.1745-3984.1994.tb00436.x](https://doi.org/10.1111/j.1745-3984.1994.tb00436.x)

Linacre, J. M. (1989). *Many-facet Rasch measurement*. MESA Press.

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
#> contentvalidR judge heterogeneity
#> ---------------------------------
#> Judges: 8 | Items: 6
#> Dependability (Phi): .94 | Judge share of variance: 15.6%
#> 
#> 7 of 8 judges are consistent with the panel.
#> Flagged for review: Judge8 (Severe)
#> 
#> Judges
#>   judge decision mean severity scale use flipped
#>  Judge1  Typical 3.17    -0.27      0.91       0
#>  Judge2  Typical 3.00    -0.10      1.18       0
#>  Judge3  Typical 3.00    -0.10      1.18       0
#>  Judge4  Typical 3.17    -0.27      0.91       0
#>  Judge5  Typical 3.17    -0.27      1.24       0
#>  Judge6  Typical 2.83     0.06      1.09       0
#>  Judge7  Typical 3.17    -0.27      0.91       0
#>  Judge8   Severe 1.67     1.23      0.48       0
#> 
#> mean: the judge's mean rating. severity: how far the judge rates below the
#> panel, in rating points (negative is more lenient). flipped: items whose
#> review status changes if this judge is removed.
#> A judge is flagged when severity exceeds 0.75 rating points in either
#> direction, scale use is below 0.50, or any item's status depends on them.
#> 
#> Logit severity not estimated
#> Judge severity could not be estimated. After setting aside judges and items
#> with no variation in endorsement, fewer than two judges and two items
#> remained, usually because each judge endorsed either all of the remaining
#> items or none of them. That happens when the panel agrees almost completely,
#> or when the only disagreement is a judge who rejects every item the others
#> accept. It describes the ratings rather than an estimation failure: a logit
#> scale needs judges whose endorsements vary.
#> Severity in rating points is reported instead and is used for flagging.
#> 
#> No item's review status depends on any single judge.
#> 
#> What these columns mean
#>   severity -- Judge severity. How much harsher (positive) or more lenient
#>       (negative) the judge is than the panel.
#>   scale use -- Scale use. Spread of the judge's ratings compared with a
#>       typical judge (1 is typical; low means few distinctions).
#>   Phi -- Dependability coefficient. How well the absolute ratings would
#>       reproduce with another panel of this size (0 to 1).
#> 
#> What the decisions mean
#>   Typical -- consistent with the panel.
#>   Severe -- rates markedly lower than the panel.
#> 
#> Full definitions: contentvalid_glossary(). To hide this key:
#> options(contentvalidR.show_key = FALSE).
#> 
#> A 'Review' judge is not a judge to remove. Disagreement can be substantive
#> expertise; the flag marks where a conclusion rests on one person's ratings.
summary(fit)
#> Summary: judge and rater heterogeneity
#> --------------------------------------
#> Judges: 8 | Items: 6
#> Consistent with panel: 7 | Flagged for review: 1 | Insufficient: 0
#> 
#> Generalizability
#>   Dependability (absolute decisions): .94
#>   Generalizability (rank ordering):   .97
#> 
#> Judges needed to reach each coefficient
#>  target relative (G) absolute (Phi)
#>     .70            1              2
#>     .80            2              2
#>     .90            3              5
#> 
#> Judges flagged for review
#> 
#>   Judge8 (Severe)
#>     This judge is markedly more severe than the panel (1.23 rating points
#>     relative to the panel mean). Consistent severity does not invalidate
#>     their ratings, but it shifts absolute indices such as CVI, which is why
#>     the dependability coefficient is penalized by judge differences.
#> 
#> This analysis describes how much conclusions depend on these judges. It does
#> not establish that the items cover the intended content domain.
```

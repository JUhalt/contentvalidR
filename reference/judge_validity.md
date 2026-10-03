# Analyze judge and rater heterogeneity in content-validity ratings

Examines whether content-validity conclusions depend on the particular
judges who happened to serve on the panel, rather than reporting only
aggregate indices that average heterogeneity away.

The workflow reports four complementary kinds of evidence:

- **Generalizability.** How dependably the panel's ratings would
  reproduce with a different panel of the same size, via
  [`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md),
  the analysis Crocker et al. (1988) applied to content-validity
  ratings.

- **Severity.** How harsh or lenient each judge is relative to the
  panel, both in raw rating units and, where estimable, on a logit scale
  from a many-facet Rasch model (Linacre, 1989) fitted as a logistic
  regression.

- **Response style.** How much each judge differentiates among items,
  and how much they concentrate on middle or extreme categories, two of
  the rater effects Engelhard (1994) describes.

- **Fragile items.** Which items would change their CVI-based review
  status (Lynn, 1986) if any single judge were removed from the panel.

A judge flagged for `Review` is not a judge to discard. Disagreement may
be substantive expertise rather than error, and removing inconvenient
judges is not a validity procedure. The flag marks a judge whose ratings
deserve a closer look.

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
  fit_range = c(0.5, 1.5),
  fit_min_ratings = 30,
  differentiation_cut = 0.5
)
```

## Arguments

- ratings:

  A judges-by-items numeric matrix or data frame of relevance ratings:
  one row per judge, one column per item. A column whose name looks like
  a rater ID (such as `expert` or `rater_id`) stops the function, so
  remove it, or rename an item that has such a name. Judge names (row
  names) and item names must be unique.

- lo, hi:

  Rating-scale bounds.

- relevance_cut:

  Lowest rating treated as relevant. Defaults to `hi - 1`, and to `hi`
  on a two-point scale. It must lie above `lo`: at `lo` every rating
  would count as relevant.

- na.rm:

  Permit missing ratings. Each judge is then compared with the panel on
  the items that judge rated. Generalizability analysis additionally
  requires complete cases and drops incomplete judges; the printout says
  how many.

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

  Length-2 vector giving the infit/outfit mean-square range read as
  acceptable. The default, 0.5 to 1.5, is the range Linacre (2002) calls
  productive for measurement. A judge above it is flagged as erratic
  when `fit_min_ratings` is met. A judge below it is described, not
  flagged.

- fit_min_ratings:

  Fewest decisions the facets model must have scored for a judge before
  a fit flag is raised. Default 30.

- differentiation_cut:

  Scale use below which a judge is flagged for low differentiation.
  Scale use is the judge's standard deviation over the median judge's.
  Default 0.5.

## Value

An object of class `contentvalid_judge` and `contentvalid_workflow`.
Unlike the item-oriented workflows, `results` has **one row per judge**.
`scale_summary` describes the panel, and `details` contains the
generalizability analysis, the facets model, raw rater effects, and
`influence_items`, the item-level table of fragile items: for each item
its number of raters, the number who rated it relevant, its status with
the full panel, whether that status changes when one judge is removed
(`fragile`; `NA` when it could not be checked), and the judges whose
removal changes it. In `results`, `n_items_flipped` and `flipped_items`
give the same information by judge; they describe the items and are not
a flag.

## What is published and what is this package's choice

The generalizability analysis, the many-facet Rasch model, the infit and
outfit mean squares and the rater effects are published methods, cited
above. These parts are contentvalidR conventions, with no published
standard behind the numbers:

- The cuts that flag a judge: `severity_cut` (1 logit),
  `severity_raw_cut` (a quarter of the scale range) and
  `differentiation_cut` (0.5). The scale-use ratio itself is this
  package's index of the differentiation Engelhard (1994) describes.

- Using Linacre's (2002) 0.5 to 1.5 range as a flag. He offers it as a
  guide to how productive data are for measurement: below 0.5 is "less
  productive for measurement, but not degrading", 1.5 to 2.0 is
  "unproductive for construction of measurement, but not degrading", and
  only above 2.0 does misfit distort the measurement. The package flags
  above 1.5 and never below 0.5 because a high mean square means noise
  in a judge's decisions, which bears on whether to trust them, while a
  low one means decisions more predictable than the model expects. A
  mean square from a handful of yes-or-no decisions varies widely by
  chance even for a judge who fits the model exactly, so a judge above
  the range is flagged only when the model scored at least
  `fit_min_ratings` of their decisions. Thirty follows the guidance in
  the Facets documentation (Linacre, n.d.) that stable estimates need at
  least 30 observations per element. With the item counts usual in
  content validation the fit statistics are therefore shown and not
  flagged.

- The fragile-item check. It reapplies Lynn's (1986) criterion with one
  judge removed. An item one judge away from the other side of the
  criterion for its panel size (at the criterion, or one short of it,
  depending on the size) changes status when any judge on one side is
  removed, so the check describes the item and flags no judge. An item
  rated by three or fewer judges is not checked, because one fewer
  leaves no criterion.

- Applying the Wright-Douglas correction to judges (see the estimation
  note).

## Estimation note

Logit severity comes from a many-facet Rasch model fitted by joint
maximum likelihood as a logistic regression, the generalized linear
model formulation described by De Boeck and Wilson (2004). Joint maximum
likelihood stretches estimates. Wright and Douglas (1977) found that
multiplying item difficulties by `(L - 1) / L`, with `L` the number of
items in the test, approximately removes the bias (see also Wright,
1988). Here the judges stand where the test items do, and the rated
items where the persons do, so the package multiplies the severities by
`(J - 1) / J`, with `J` the number of judges who rated each item in the
model (with missing ratings, the mean of that number over the items),
and the standard errors by its square root, as the Facets documentation
describes for the standard errors (Linacre, n.d.). That application to
judges is this package's choice. The factor is reported in
`settings$bias_correction`. Versions before 1.0 counted items instead,
which left most of the bias in place on a small panel. The correction is
approximate: Wright and Douglas recommended it for tests of more than 20
items, and Wright (1988) notes that it is slightly inexact for very
short tests, which is what a panel of a few judges amounts to. With two
or three judges no single factor is trustworthy. Where precise severity
calibration matters, marginal maximum likelihood estimation is
preferable, and the raw rating-unit severity in `severity_raw` is free
of this particular issue.

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

Linacre, J. M. (n.d.). *Estimation considerations: JMLE estimation bias*
\[Facets help\]. Winsteps.com. Retrieved October 2, 2026, from
<https://www.winsteps.com/facetman/estimationconsiderations.htm>

Linacre, J. M. (1989). *Many-facet Rasch measurement*. MESA Press.

Linacre, J. M. (2002). What do infit and outfit, mean-square and
standardized mean? *Rasch Measurement Transactions, 16*(2), 878.
<https://www.rasch.org/rmt/rmt162f.htm>

Lynn, M. R. (1986). Determination and quantification of content
validity. *Nursing Research, 35*(6), 382–385.
[doi:10.1097/00006199-198611000-00017](https://doi.org/10.1097/00006199-198611000-00017)

Wright, B. D. (1988). The efficacy of unconditional maximum likelihood
bias correction: Comment on Jansen, van den Wollenberg, and Wierda.
*Applied Psychological Measurement, 12*(3), 315–318.
[doi:10.1177/014662168801200309](https://doi.org/10.1177/014662168801200309)

Wright, B. D., & Douglas, G. A. (1977). Best procedures for sample-free
item analysis. *Applied Psychological Measurement, 1*(2), 281–295.
[doi:10.1177/014662167700100216](https://doi.org/10.1177/014662167700100216)

## See also

[`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md)
for the generalizability analysis alone,
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
for the item-level expert-panel workflow.

## Examples

``` r
# Eight judges rate ten items for relevance on a 1-4 scale. Judge8 rates
# lower than the rest, and Item4 is one judge short of the CVI criterion.
ratings <- rbind(
  c(4, 4, 3, 4, 3, 2, 3, 2, 4, 3), c(4, 3, 4, 3, 2, 3, 2, 3, 4, 2),
  c(3, 4, 4, 3, 3, 2, 2, 2, 3, 3), c(4, 4, 3, 2, 3, 3, 3, 1, 4, 2),
  c(4, 3, 3, 4, 2, 2, 3, 2, 3, 3), c(3, 4, 4, 3, 3, 3, 2, 3, 4, 1),
  c(4, 4, 4, 4, 3, 2, 3, 2, 4, 3), c(3, 2, 3, 2, 2, 1, 2, 1, 2, 2)
)
dimnames(ratings) <- list(paste0("Judge", 1:8), paste0("Item", 1:10))
fit <- judge_validity(ratings, lo = 1, hi = 4)
fit
#> contentvalidR judge heterogeneity
#> ---------------------------------
#> Judges: 8 | Items: 10
#> Scale: 1 to 4 | Relevant: a rating of 3 or higher
#> Dependability (Phi): .85 | Judge share of variance: 15.2%
#> 
#> 7 of 8 judges are consistent with the panel.
#> Flagged for review: Judge8 (Severe)
#> 
#> Judges
#>   judge decision mean severity logit infit outfit scale use
#>  Judge1  Typical 3.20    -0.30 -0.40  0.59   0.51      0.98
#>  Judge2  Typical 3.00    -0.10  0.30  1.55   1.59      1.02
#>  Judge3  Typical 2.90     0.00  0.30  0.65   0.59      0.92
#>  Judge4  Typical 2.90     0.00  0.30  1.39   1.54      1.24
#>  Judge5  Typical 2.90     0.00  0.30  0.90   0.82      0.92
#>  Judge6  Typical 3.00    -0.10 -0.40  1.36   1.18      1.17
#>  Judge7  Typical 3.30    -0.40 -0.40  0.59   0.51      1.03
#>  Judge8   Severe 2.00     0.90    NA    NA     NA      0.83
#> 
#> mean: the judge's mean rating. severity: how far the judge rates below the
#> panel, in rating points (negative is more lenient); logit: the same from the
#> facets model, against the judges it placed, which the flags use.
#> 
#> A judge is flagged when severity exceeds 1 logit in either direction (0.75
#> rating points for a judge the model could not place) or scale use is below
#> 0.50. These cuts are contentvalidR conventions, not published standards.
#> 
#> Fit: a judge is flagged as erratic when infit or outfit is above 1.5, the top
#> of the range Linacre (2002) calls productive for measurement, and the model
#> scored at least 30 of their decisions. The flag and the minimum are
#> contentvalidR conventions.
#> Here the model scored at most 6 of any judge's decisions (items every judge
#> agreed on are set aside), so the fit statistics are shown and not flagged.
#> 
#> Items whose status changes if one judge is removed
#>   item relevant status changes without
#>  Item4   6 of 8 Review  Judge4, Judge8
#> 
#> changes without: removing any one of these judges changes the item's status.
#> Such an item is one judge away from the other side of the CVI criterion for
#> its panel size (Lynn, 1986): at the criterion, or one short of it. This
#> describes the item, not the judges named, and is a contentvalidR check, not a
#> published index.
#> 
#> What these columns mean
#>   severity -- Judge severity. How much harsher (positive) or more lenient
#>       (negative) the judge is than the panel.
#>   infit, outfit -- Fit mean squares. How predictable the judge's decisions
#>       are: about 1 is expected, high is erratic, low is more predictable
#>       than expected.
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
#> expertise; the flag marks ratings worth a closer look.
summary(fit)
#> Summary: judge and rater heterogeneity
#> --------------------------------------
#> Judges: 8 | Items: 10
#> Consistent with panel: 7 | Flagged for review: 1 | Insufficient: 0
#> 
#> Generalizability
#>   Dependability (absolute decisions): .85
#>   Generalizability (rank ordering):   .89
#> 
#> Judges needed to reach each coefficient
#>  target relative (G) absolute (Phi)
#>     .70            3              4
#>     .80            5              6
#>     .90           10             13
#> 
#> Judges flagged for review
#> 
#>   Judge8 (Severe)
#>     This judge is markedly more severe than the panel (0.90 rating points
#>     relative to the panel mean). Consistent severity does not invalidate
#>     their ratings, but it shifts absolute indices such as CVI, which is why
#>     the dependability coefficient is penalized by judge differences.
#> 
#> Items whose status changes if one judge is removed
#>   item relevant status changes without
#>  Item4   6 of 8 Review  Judge4, Judge8
#> 
#> changes without: removing any one of these judges changes the item's status.
#> Such an item is one judge away from the other side of the CVI criterion for
#> its panel size (Lynn, 1986): at the criterion, or one short of it. This
#> describes the item, not the judges named, and is a contentvalidR check, not a
#> published index.
#> 
#> This analysis describes how much conclusions depend on these judges. It does
#> not establish that the items cover the intended content domain.
```

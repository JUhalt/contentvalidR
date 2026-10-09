# Generalizability analysis of content-validity ratings

Decomposes judge ratings of items into item, judge, and residual
variance components, then reports how dependably the panel's ratings
generalize over judges.

This follows the generalizability-theory treatment of content-validity
ratings in Crocker et al. (1988). Items are the objects of measurement
and judges are the facet of generalization, so the question the analysis
answers is: *if a different panel of judges of the same size had rated
these items, how similar would the conclusions be?*

Two coefficients are reported because they answer different questions:

- The **generalizability coefficient** (relative, `g_coefficient`)
  concerns the *rank ordering* of items by rated relevance. Use it when
  the decision is comparative, such as selecting the strongest items
  from a pool.

- The **dependability coefficient** (absolute, `phi_coefficient`)
  concerns the *absolute level* of the ratings and is penalized by judge
  severity differences. Use it when the decision is
  criterion-referenced, such as whether items clear a fixed relevance
  standard. Most content-validity decisions are criterion-referenced, so
  `phi_coefficient` is usually the more relevant of the two.

Because a single rating per judge-item cell cannot separate the
judge-by-item interaction from measurement error, the two are reported
together as a single residual component. This is a property of the
design, not of the estimator.

## Usage

``` r
gtheory_content(
  ratings,
  na.rm = FALSE,
  targets = c(0.7, 0.8, 0.9),
  max_judges = 30,
  phi_cut = 0.8
)
```

## Arguments

- ratings:

  A judges-by-items numeric matrix or data frame: one row per judge, one
  column per item. A column whose name looks like a rater ID (such as
  `expert` or `rater_id`) stops the function, so remove it, or rename an
  item that has such a name.

- na.rm:

  If `TRUE`, judges with any missing rating are dropped so that a
  complete crossed design remains, and the number dropped is reported.
  If `FALSE` (default), missing values are an error.

- targets:

  Coefficient targets used for the decision study. Each must lie
  strictly between 0 and 1.

- max_judges:

  Largest panel size shown in the decision-study projection.

- phi_cut:

  Dependability coefficient at or above which the status is
  `"Supported"`. Default .80. Neither Brennan (2001) nor Crocker et
  al. (1988) sets a required value, so this is a contentvalidR
  convention, printed beside the status so a reader can apply another.

## Value

An object of class `contentvalid_gtheory`, a list containing:

- variance_components:

  Source, degrees of freedom, mean squares, estimated variance
  component, and percentage of total variance.

- coefficients:

  Observed-design generalizability and dependability coefficients with
  their error variances.

- dstudy:

  Projected coefficients across panel sizes.

- judges_needed:

  Judges required to reach each target coefficient, for relative and
  absolute decisions. `NA` means the target is not reachable with any
  realistic panel, which happens when items are barely distinguished
  from one another.

- settings, design:

  Analysis settings and realized design metadata.

- status:

  `"Supported"` when the dependability coefficient is at or above
  `phi_cut` and `"Review"` when it is below; `"Descriptive only"` when
  the items show no variance to generalize; and `"Insufficient data"`
  with fewer than two judges or two items.

- interpretation:

  The status in a sentence or two.

The projection and `judges_needed` are estimates from the variance
components of one panel, with no interval. From a small panel they are
rough, so read them as planning figures, not as exact answers.

## Negative variance estimates

ANOVA estimation can yield negative variance components when a true
component is near zero. Negative estimates are truncated to zero for the
coefficient calculations, following standard practice, and the
untruncated estimate is retained in the `variance_raw` column so the
truncation is visible rather than silent.

## References

Brennan, R. L. (2001). *Generalizability theory*. Springer.
[doi:10.1007/978-1-4757-3456-0](https://doi.org/10.1007/978-1-4757-3456-0)

Crocker, L., Llabre, M., & Miller, M. D. (1988). The generalizability of
content validity ratings. *Journal of Educational Measurement, 25*(4),
287–299.
[doi:10.1111/j.1745-3984.1988.tb00309.x](https://doi.org/10.1111/j.1745-3984.1988.tb00309.x)

## Examples

``` r
# Six items rated for relevance by eight judges on a 1-4 scale. Items 1-4 are
# clearly relevant, items 5-6 are marginal, and judge 8 is notably severe.
ratings <- rbind(
  c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
  c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(4, 3, 4, 3, 1, 2),
  c(4, 4, 3, 4, 2, 2), c(3, 3, 3, 2, 1, 1)
)
dimnames(ratings) <- list(paste0("Judge", 1:8), paste0("Item", 1:6))
gtheory_content(ratings)
#> <contentvalid_gtheory> Generalizability analysis
#> Design: items x judges, crossed, one rating per cell
#> Items: 6 | Judges: 8
#> 
#> Observed design
#>   Generalizability coefficient (relative, rank ordering): .97
#>   Dependability coefficient (absolute, fixed standard):   .96
#>   Status: Supported (criterion: Phi >= .80, a contentvalidR convention)
#>   With 8 judges, absolute decisions about these items would generalize to
#>   another panel of the same size at Phi = .96, at or above the .80 criterion.
#>   Judge differences account for 5.8% of total variance.
#> 
#> Variance components
#>   Source    df    MS  Estimate  Used  % of total
#>   item       5  8.58      1.04  1.04        77.1
#>   judge      7  0.70      0.08  0.08         5.8
#>   residual  35  0.23      0.23  0.23        17.1
#> 
#>   MS: mean square. Estimate: the ANOVA estimate of each variance component.
#>   Used: the same with a negative estimate set to 0, which the coefficients use
#>   (Brennan, 2001).
#> 
#> Judges needed to reach each coefficient
#>   Target  Relative (G)  Absolute (Phi)
#>      .70             1               1
#>      .80             1               2
#>      .90             2               3
#>   These panel sizes are estimates from one panel's variance components, with
#>   no interval: read them as planning figures.
#> 
#> A dependability coefficient describes generalization over judges only. It is
#> not evidence that the items cover the intended content domain.
#> 
#> See x$dstudy for the coefficients projected by panel size.
```

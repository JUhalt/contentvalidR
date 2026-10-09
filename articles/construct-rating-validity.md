# Construct-Rating Content Validation: Hinkin-Tracey to Colquitt

``` r

library(contentvalidR)
```

## What the rating workflow asks

The Hinkin and Tracey (1999) content-rating procedure asks judges to
evaluate how well each item corresponds to **each** construct definition
under consideration. The typical design is fully crossed within judges:
the same judge rates an item against the intended definition and against
one or more orbiting definitions.

That design provides two complementary kinds of evidence:

- **Definitional correspondence:** does the item strongly match its
  intended construct?
- **Definitional distinctiveness:** does it match the intended construct
  more strongly than plausible orbiting constructs?

`contentvalidR` keeps those questions separate rather than reducing the
study to a single coefficient.

## Example data

``` r

rating_dat <- expand.grid(
  item = c("A1", "A2", "A3", "B1"),
  rater = 1:24,
  construct = c("A", "B", "C")
)
rating_dat$target_construct <- ifelse(rating_dat$item == "B1", "B", "A")

rating_dat$rating <- ifelse(
  rating_dat$construct == rating_dat$target_construct,
  pmin(5, pmax(1, round(rnorm(nrow(rating_dat), 4.4, .6)))),
  pmin(5, pmax(1, round(rnorm(nrow(rating_dat), 2.2, .8))))
)
```

Each item-judge combination appears once for every construct definition.
A duplicated item-rater-construct row is treated as a data error.

## HTC: definitional correspondence

Following Colquitt et al. (2019), the Hinkin-Tracey correspondence index
is

``` math
HTC = \frac{\bar{x}_{target}}{a},
```

where $`a`$ is the number of response anchors when ratings use a
1-to-$`a`$ scale. `contentvalidR` can also accept an equally spaced
integer scale such as 0-to-4; it shifts that scale internally to the
equivalent 1-to-5 anchor metric before computing HTC.

``` r

htc(rating_dat, scale_min = 1, scale_max = 5)
#> <contentvalid_htc> Hinkin-Tracey correspondence (HTC)
#> Colquitt et al. (2019).
#> 
#>   Item  Target  Judges  Target mean  HTC
#>   A1    A           24         4.38  .88
#>   A2    A           24         4.46  .89
#>   A3    A           24         4.42  .88
#>   B1    B           24         4.58  .92
#> 
#> HTC expresses the mean target rating as a share of the 5-point scale.
#> 
#> See as.data.frame(x) for the unrounded values.
```

Higher HTC means stronger correspondence with the intended definition.
Because the lowest rating still counts as one point, HTC cannot reach 0:
it runs from $`1/a`$ to 1, so from .20 to 1 on a five-point scale.

## HTD: definitional distinctiveness

HTD compares intended-definition ratings with orbiting-definition
ratings:

``` math
HTD = \frac{\text{average}(x_{target} - x_{orbiting})}{a - 1}.
```

The average runs over every judge and every orbiting definition, so HTD
is the intended definition’s average lead over **all** the orbiting
definitions, not its lead over the closest one. It ranges from -1 to 1.
Positive values favor the intended definition; negative values indicate
that orbiting definitions are rated more highly on average.

``` r

htd(rating_dat, scale_min = 1, scale_max = 5)
#> <contentvalid_htd> Hinkin-Tracey distinctiveness (HTD)
#> Colquitt et al. (2019).
#> 
#>   Item  Target  Judges  Target mean  Competitor  Competitor mean  HTD
#>   A1    A           24         4.38  B                      2.38  .56
#>   A2    A           24         4.46  B                      2.00  .63
#>   A3    A           24         4.42  C                      2.25  .55
#>   B1    B           24         4.58  C                      2.17  .61
#> 
#> Competitor: the other construct with the highest mean rating. HTD itself
#> averages the gap over every other construct.
#> 
#> See as.data.frame(x) for the unrounded values.
```

The item-level table also identifies the strongest orbiting competitor.
That is often more useful for revision than merely knowing that
distinctiveness is weak.

## Repeated-measures item screening

Hinkin and Tracey (1999) analyzed these ratings with a one-way ANOVA and
Duncan’s multiple range test, treating the definitions as independent
groups. The same judges provide multiple construct ratings, though, so
those observations are not independent. MacKenzie et al. (2011)
recommend a one-way repeated-measures ANOVA for this task, followed,
when its *F* is significant, by a planned contrast of the intended
definition against the others.
[`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
uses that repeated-measures form for the standard fully crossed design
and follows it with planned paired comparisons of the intended
definition against every orbiting definition.

An item is retained when the omnibus test and then its contrasts pass,
which follows their sequence. Some details are this package’s choices,
not taken from either source: the Greenhouse-Geisser (1959) corrected
*p* is the screening *p* of the omnibus test; there is one one-sided
contrast for each orbiting definition, and every one must pass, where
MacKenzie et al. describe a single contrast; the contrasts are not
adjusted for their number unless you ask (`adjust = "holm"`); and the
tests need at least two judges who rated the item against every
definition.

``` r

aov_out <- anova_content(rating_dat, design = "within")
aov_out
#> <contentvalid_anova> Content-validity ANOVA
#> Adapted from Hinkin and Tracey (1999) and MacKenzie et al. (2011).
#> 
#>   Item Target Judges F test                       p Partial eta^2 Contrast p Met
#>   A1   A          24 F(1.98, 45.65) = 72.64  < .001           .76     < .001 yes
#>   A2   A          24 F(1.62, 37.22) = 105.82 < .001           .82     < .001 yes
#>   A3   A          24 F(2.00, 45.97) = 82.25  < .001           .78     < .001 yes
#>   B1   B          24 F(1.85, 42.61) = 108.29 < .001           .82     < .001 yes
#> 
#> Within-judge omnibus tests are Greenhouse-Geisser corrected, which reduces
#> their degrees of freedom.
#> Contrast p: the largest p among the planned contrasts, each one-sided (the
#> intended construct rated above one of the others), at alpha = .05 with no
#> adjustment for their number. It is -- when a contrast has no p because every
#> judge rated the two constructs the same. Met: whether every contrast passed.
#> attr(x, "contrasts") holds each one.
#> 
#> See as.data.frame(x) for the unrounded values.
attr(aov_out, "contrasts")
#>   item design target competitor  n mean_target mean_competitor mean_diff
#> 1   A1 within      A          B 24    4.375000        2.375000  2.000000
#> 2   A1 within      A          C 24    4.375000        1.916667  2.458333
#> 3   A2 within      A          B 24    4.458333        2.000000  2.458333
#> 4   A2 within      A          C 24    4.458333        1.875000  2.583333
#> 5   A3 within      A          B 24    4.416667        2.208333  2.208333
#> 6   A3 within      A          C 24    4.416667        2.250000  2.166667
#> 7   B1 within      B          A 24    4.583333        2.083333  2.500000
#> 8   B1 within      B          C 24    4.583333        2.166667  2.416667
#>           t df            p        p_adj       dz pass
#> 1  9.591663 23 8.344091e-10 8.344091e-10 1.957890 TRUE
#> 2 11.336315 23 3.409941e-11 3.409941e-11 2.314016 TRUE
#> 3 10.552406 23 1.372752e-10 1.372752e-10 2.154001 TRUE
#> 4 17.643975 23 3.644893e-15 3.644893e-15 3.601561 TRUE
#> 5 11.072214 23 5.409806e-11 5.409806e-11 2.260106 TRUE
#> 6 11.021286 23 5.918580e-11 5.918580e-11 2.249711 TRUE
#> 7 13.133926 23 1.786074e-12 1.786074e-12 2.680951 TRUE
#> 8 14.269216 23 3.241706e-13 3.241706e-13 2.912692 TRUE
```

The omnibus F test asks whether the item’s mean ratings differ somewhere
across definitions. The planned contrasts ask the more direct
content-validity question: is the target mean higher than each orbiting
mean?

With more than two construct definitions, the conventional
repeated-measures F test assumes sphericity. `contentvalidR` prints the
Greenhouse-Geisser corrected test, whose degrees of freedom are
fractional; `as.data.frame(aov_out)$p` holds the uncorrected *p* value.
The planned target-versus-orbiting comparisons are important diagnostic
evidence rather than decorative post-hoc tests.

## Recommended workflow

``` r

fit <- rating_validity(
  rating_dat,
  scale_min = 1,
  scale_max = 5
)
fit
#> <contentvalid_rating> Construct-rating analysis
#> Items: 4 | Judges: 24 | Target constructs: 2 | Constructs rated: 3
#> Design: within-judge ratings on a 1 to 5 scale
#> Test: one-way repeated-measures ANOVA (Greenhouse-Geisser corrected omnibus p)
#> plus planned paired target-versus-orbiting contrasts; planned-contrast
#> adjustment: none.
#> Retain: the omnibus p and every contrast p at or below alpha = .05. The
#> contrasts are one-sided: the intended construct rated above every other
#> construct.
#> Judges: naive, meaning drawn from the kind of people who will answer the
#> items.
#> 
#> 4 of 4 items meet the full item-level screening criterion.
#> 
#> Item-level evidence
#>   Item  Target  Decision   n  HTC  HTD  Omnibus p  Contrast p  Competitor
#>   A1    A       Retain    24  .88  .56     < .001      < .001  B
#>   A2    A       Retain    24  .89  .63     < .001      < .001  B
#>   A3    A       Retain    24  .88  .55     < .001      < .001  C
#>   B1    B       Retain    24  .92  .61     < .001      < .001  C
#> 
#>   n: judges who rated the item against every construct. Omnibus p: do the
#>   item's ratings differ across constructs (Greenhouse-Geisser corrected).
#>   Contrast p: the largest p among the planned target-versus-orbiting
#>   contrasts, so every contrast is at or below it.
#> 
#> Scale-level Colquitt benchmarks
#>   Target  Items  Mean HTC  HTC level    Mean HTD  HTD level
#>   A           3       .88  Strong            .58  Very Strong
#>   B           1       .92  Very Strong       .61  Very Strong
#>   Benchmark set: Overall (not correlation-normed)
#> 
#>   Colquitt labels are empirical percentile norms for scale-level HTC and HTD
#>   averages, not universal cutoffs. HTC is an average rating and HTD is a
#>   difference between ratings, so they sit on different scales with different
#>   typical values. A high HTC can be labeled Weak in the same analysis where a
#>   much smaller HTD is labeled Very Strong. Compare each index against its own
#>   benchmark, never against the other index's number.
#> 
#> What these columns mean
#>   HTC -- Hinkin-Tracey Correspondence. Mean rating against the intended
#>       definition, divided by the number of scale points (1/points to 1).
#>   HTD -- Hinkin-Tracey Distinctiveness. How far that rating exceeds the other
#>       constructs' ratings on average, as a share of the scale (usually small).
#> 
#> What the decisions mean
#>   Retain -- its ratings differed across constructs (the omnibus test) and the
#>       intended construct was rated above every other (every planned contrast).
#> 
#>   Full definitions: contentvalid_glossary(). To hide this key:
#>   options(contentvalidR.show_key = FALSE).
#> 
#> A flag for review is not an automatic deletion decision. Consider construct
#> definitions, item wording, orbiting-construct choice, domain coverage, and
#> qualitative judge feedback.
#> 
#> See summary(x) for the flagged items and content_report(x) for an APA table.
summary(fit)
#> <contentvalid_rating summary> Construct-rating analysis
#> Retain: 4 of 4 | Review: 0 of 4
#> 
#> Scale-level evidence
#>   Target  Items  Retain  Review  Mean HTC  HTC level    Mean HTD  HTD level
#>   A           3       3       0       .88  Strong            .58  Very Strong
#>   B           1       1       0       .92  Very Strong       .61  Very Strong
#> 
#>   HTC = Hinkin-Tracey correspondence; HTD = Hinkin-Tracey distinctiveness
#>   (Colquitt et al., 2019).
#>   A: Mean HTC falls in the Strong band and mean HTD in the Very Strong band of
#>     published scales (Colquitt et al., 2019).
#>   B: Mean HTC and mean HTD both fall in the Very Strong band of published
#>     scales (Colquitt et al., 2019).
#> 
#> All analyzed items met the item-level inferential screening criterion.
#> 
#> Interpret these results alongside theory, domain coverage, and qualitative
#> feedback. The analysis does not by itself establish comprehensiveness or the
#> full content-validity argument.
#> 
#> See summary(x)$reviewed_items for the flagged items as a data frame.
```

The item-level recommendation has deliberately limited meaning:

- **Retain:** the item cleared the package’s inferential screening rule
  in this pretest: its omnibus *p* and every contrast *p* are at or
  below alpha.
- **Review:** the full screening rule was not met; inspect wording,
  construct overlap, and judge feedback.
- **Insufficient data:** fewer than two judges rated the item against
  every definition, so the repeated-measures comparison cannot be made.
  Its HTD, which rests on those judges, is left out of the scale’s mean
  HTD. Its HTC stays in the scale’s mean HTC when at least two judges
  rated the item against its intended definition.

`Review` is not an instruction to delete an item. Content coverage can
be harmed by mechanical item deletion.

## Scale-level Colquitt norms

Colquitt et al. (2019) created empirical norms from **scale-level
averages** of HTC and HTD across 112 published scales.
[`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
therefore averages item HTC/HTD within each target scale before
assigning those descriptive normative labels.

``` r

fit$scale_summary[, c("target", "n_items", "mean_htc", "htc_strength",
                      "mean_htd", "htd_strength")]
#>   target n_items  mean_htc htc_strength  mean_htd htd_strength
#> 1      A       3 0.8833333       Strong 0.5781250  Very Strong
#> 2      B       1 0.9166667  Very Strong 0.6145833  Very Strong
colquitt_benchmarks("htc")
#> <contentvalid_colquitt_norms> Benchmarks for HTC
#> Colquitt et al. (2019). Benchmark set: Overall (not correlation-normed).
#> 
#>   Band         Percentile  Minimum
#>   Very Strong  80th-99th       .91
#>   Strong       60th-79th       .87
#>   Moderate     40th-59th       .84
#>   Weak         20th-39th       .60
#>   Lack of      0th-19th       none
#> 
#> A scale-level mean at or above a band's minimum falls in that band. The bands
#> are percentiles of published scales, not validity cutoffs.
#> 
#> See as.data.frame(x) for the unrounded values.
colquitt_benchmarks("htd")
#> <contentvalid_colquitt_norms> Benchmarks for HTD
#> Colquitt et al. (2019). Benchmark set: Overall (not correlation-normed).
#> 
#>   Band         Percentile  Minimum
#>   Very Strong  80th-99th       .35
#>   Strong       60th-79th       .27
#>   Moderate     40th-59th       .18
#>   Weak         20th-39th       .04
#>   Lack of      0th-19th       none
#> 
#> A scale-level mean at or above a band's minimum falls in that band. The bands
#> are percentiles of published scales, not validity cutoffs.
#> 
#> See as.data.frame(x) for the unrounded values.
```

The overall bands are empirical percentile standing, not universal
validity cutoffs. If the average correlation between a focal scale and
its orbiting scales is known, correlation-conditional norms can be
requested:

``` r

conditional <- rating_validity(
  rating_dat,
  orbiting_r = c(A = .42, B = .55)
)
conditional$scale_summary[, c("target", "orbiting_r", "htc_strength",
                              "htd_strength", "benchmark_set")]
#>   target orbiting_r htc_strength htd_strength benchmark_set
#> 1      A       0.42     Moderate  Very Strong      moderate
#> 2      B       0.55  Very Strong  Very Strong      stronger
```

A given level of distinctiveness can be more impressive when the focal
and orbiting constructs are known to correlate strongly.

## Naive versus expert judges

Colquitt et al.’s normative distributions were developed using naive
judges representative of substantive target populations. Their paper
cautions against applying those norms to expert panels. The package
therefore separates calculation from norm applicability:

``` r

rating_validity(rating_dat, judge_type = "expert")$scale_summary[
  , c("target", "mean_htc", "htc_strength", "mean_htd", "htd_strength")]
#>   target  mean_htc htc_strength  mean_htd htd_strength
#> 1      A 0.8833333         <NA> 0.5781250         <NA>
#> 2      B 0.9166667         <NA> 0.6145833         <NA>
```

HTC/HTD are still computed, but the Colquitt labels are suppressed.
[`print()`](https://rdrr.io/r/base/print.html) and
[`summary()`](https://rdrr.io/r/base/summary.html) leave out the columns
that would hold them; the stored table, shown here, keeps them as `NA`.

## Missing ratings

For HTD and repeated-measures inference, a judge must have a usable
rating for every construct definition presented for that item.
Incomplete profiles are excluded itemwise and counted explicitly in the
output. This preserves the paired design rather than quietly treating
incomplete repeated observations as independent data.

## Plotting

The original one-index views remain available:

``` r

plot(fit, metric = "htc")
```

![HTC for each item on a 0 to 1 scale; filled points are retained items
and open points are items to
review.](construct-rating-validity_files/figure-html/plot-1.png)

``` r

plot(fit, metric = "htd")
```

![HTD for each item on a -1 to 1 scale, with a dotted line at zero;
filled points are retained items and open points are items to
review.](construct-rating-validity_files/figure-html/plot-2.png)

A correspondence-distinctiveness evidence map displays HTC and HTD
together:

``` r

plot(fit, type = "map")
```

![Construct-rating evidence map: each item's HTC on the horizontal axis
against its HTD on the vertical axis. Filled points are retained items,
open points are items to review, and triangles mark each target scale's
mean.](construct-rating-validity_files/figure-html/rating-map-1.png)

Target-scale averages are shown as triangles and items needing review
are labeled by default. As with the item-sort map, Colquitt norm regions
are not drawn across individual items because those benchmarks were
constructed from scale averages.

The **target-versus-competitor gap plot** makes the Hinkin-Tracey
mean-rating logic more directly visible:

``` r

plot(fit, type = "profile")
```

![Construct-rating profile: for each item, its mean rating against the
intended definition (filled) and against the strongest competing
definition (open), joined by a line that is dashed for items to
review.](construct-rating-validity_files/figure-html/rating-profile-1.png)

Filled points are intended-definition means, open points are the
strongest orbiting-definition means, and the connecting segment is the
gap between them. Both means come from the judges who rated the item
against every definition, so the two ends of a segment describe the same
judges. A reversed segment immediately identifies an item whose
strongest competitor outrates its intended definition. An item with too
few complete judges for a decision is marked with a cross and has no
segment. This is a graphical extension of the mean-rating tables used in
the original procedure, not a new statistical cutoff.

## Reporting

A useful report should identify:

1.  the construct definitions and orbiting constructs shown to judges;
2.  the judge population and recruitment method;
3.  the response anchors and rating instructions;
4.  item-level HTC, HTD, repeated-measures omnibus results, and planned
    contrasts;
5.  the strongest orbiting competitor for items needing review;
6.  target-scale mean HTC/HTD and the norm set used, if applicable; and
7.  qualitative feedback and substantive decisions made after the
    pretest.

The quantitative analysis is evidence about definitional correspondence
and distinctiveness. It does not by itself demonstrate that the item
pool comprehensively samples the full construct domain.

## References

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243–1265. <https://doi.org/10.1037/apl0000406>

Greenhouse, S. W., & Geisser, S. (1959). On methods in the analysis of
profile data. *Psychometrika, 24*(2), 95–112.
<https://doi.org/10.1007/BF02289823>

Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach
to content validation. *Organizational Research Methods, 2*(2), 175–186.
<https://doi.org/10.1177/109442819922004>

MacKenzie, S. B., Podsakoff, P. M., & Podsakoff, N. P. (2011). Construct
measurement and validation procedures in MIS and behavioral research:
Integrating new and existing techniques. *MIS Quarterly, 35*(2),
293–334. <https://doi.org/10.2307/23044045>

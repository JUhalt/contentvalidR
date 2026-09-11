# Construct-Rating Content Validation: Hinkin-Tracey to Colquitt

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`contentvalidR`](https://github.com/JUhalt/contentvalidR)`)`

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

\
`rating_dat`` ``<-`` `[`expand.grid`](https://rdrr.io/r/base/expand.grid.html)`(`\
`  item ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"A1"``, ``"A2"``, ``"A3"``, ``"B1"``)``,`\
`  rater ``=`` ``1``:``24``,`\
`  construct ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"A"``, ``"B"``, ``"C"``)`\
`)`\
`rating_dat``$``target_construct`` ``<-`` `[`ifelse`](https://rdrr.io/r/base/ifelse.html)`(``rating_dat``$``item`` ``==`` ``"B1"``, ``"B"``, ``"A"``)`\
\
`rating_dat``$``rating`` ``<-`` `[`ifelse`](https://rdrr.io/r/base/ifelse.html)`(`\
`  ``rating_dat``$``construct`` ``==`` ``rating_dat``$``target_construct``,`\
`  `[`pmin`](https://rdrr.io/r/base/Extremes.html)`(``5``, `[`pmax`](https://rdrr.io/r/base/Extremes.html)`(``1``, `[`round`](https://rdrr.io/r/base/Round.html)`(`[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(`[`nrow`](https://rdrr.io/r/base/nrow.html)`(``rating_dat``)``, ``4.4``, ``.6``)``)``)``)``,`\
`  `[`pmin`](https://rdrr.io/r/base/Extremes.html)`(``5``, `[`pmax`](https://rdrr.io/r/base/Extremes.html)`(``1``, `[`round`](https://rdrr.io/r/base/Round.html)`(`[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(`[`nrow`](https://rdrr.io/r/base/nrow.html)`(``rating_dat``)``, ``2.2``, ``.8``)``)``)``)`\
`)`

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

\
[`htc`](https://juhalt.github.io/contentvalidR/reference/htc.md)`(``rating_dat``, scale_min ``=`` ``1``, scale_max ``=`` ``5``)`\
`#>   item target n_target target_mean anchors       htc`\
`#> 1   A1      A       24    4.375000       5 0.8750000`\
`#> 2   A2      A       24    4.458333       5 0.8916667`\
`#> 3   A3      A       24    4.416667       5 0.8833333`\
`#> 4   B1      B       24    4.583333       5 0.9166667`

Higher HTC means stronger correspondence with the intended definition.

## HTD: definitional distinctiveness

HTD compares intended-definition ratings with orbiting-definition
ratings:

``` math
HTD = \frac{\text{average}(x_{target} - x_{orbiting})}{a - 1}.
```

It ranges from -1 to 1. Positive values favor the intended definition;
negative values indicate that orbiting definitions are rated more highly
on average.

\
[`htd`](https://juhalt.github.io/contentvalidR/reference/htd.md)`(``rating_dat``, scale_min ``=`` ``1``, scale_max ``=`` ``5``)`\
`#>   item target n_complete n_pairs target_mean_complete strongest_competitor`\
`#> 1   A1      A         24      48             4.375000                    B`\
`#> 2   A2      A         24      48             4.458333                    B`\
`#> 3   A3      A         24      48             4.416667                    C`\
`#> 4   B1      B         24      48             4.583333                    C`\
`#>   competitor_mean anchors       htd`\
`#> 1        2.375000       5 0.5572917`\
`#> 2        2.000000       5 0.6302083`\
`#> 3        2.250000       5 0.5468750`\
`#> 4        2.166667       5 0.6145833`

The item-level table also identifies the strongest orbiting competitor.
That is often more useful for revision than merely knowing that
distinctiveness is weak.

## Repeated-measures item screening

The same judges provide multiple construct ratings, so those
observations are not independent.
[`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
uses a one-way repeated-measures ANOVA for the standard fully crossed
design and follows it with planned paired comparisons of the intended
definition against every orbiting definition.

\
`aov_out`` ``<-`` `[`anova_content`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)`(``rating_dat``, design ``=`` ``"within"``)`\
`aov_out`\
`#>   item target design n_raters n_complete n_constructs target_mean`\
`#> 1   A1      A within       24         24            3    4.375000`\
`#> 2   A2      A within       24         24            3    4.458333`\
`#> 3   A3      A within       24         24            3    4.416667`\
`#> 4   B1      B within       24         24            3    4.583333`\
`#>   strongest_competitor competitor_mean         F df1 df2            p`\
`#> 1                    B        2.375000  72.64064   2  46 5.820538e-15`\
`#> 2                    B        2.000000 105.82309   2  46 6.164319e-18`\
`#> 3                    C        2.250000  82.24514   2  46 6.443079e-16`\
`#> 4                    C        2.166667 108.28649   2  46 3.987307e-18`\
`#>   epsilon_gg   df1_gg   df2_gg         p_gg     p_screen partial_eta2`\
`#> 1  0.9923166 1.984633 45.64657 7.290445e-15 7.290445e-15    0.7595165`\
`#> 2  0.8090412 1.618082 37.21590 6.097704e-15 6.097704e-15    0.8214606`\
`#> 3  0.9992587 1.998517 45.96590 6.595204e-16 6.595204e-16    0.7814626`\
`#> 4  0.9262517 1.852503 42.60758 5.895899e-17 5.895899e-17    0.8248106`\
`#>   min_mean_diff max_contrast_p contrast_pass posthoc_pass`\
`#> 1      2.000000   8.344091e-10          TRUE         TRUE`\
`#> 2      2.458333   1.372752e-10          TRUE         TRUE`\
`#> 3      2.166667   5.918580e-11          TRUE         TRUE`\
`#> 4      2.416667   1.786074e-12          TRUE         TRUE`\
[`attr`](https://rdrr.io/r/base/attr.html)`(``aov_out``, ``"contrasts"``)`\
`#>   item design target competitor  n mean_target mean_competitor mean_diff`\
`#> 1   A1 within      A          B 24    4.375000        2.375000  2.000000`\
`#> 2   A1 within      A          C 24    4.375000        1.916667  2.458333`\
`#> 3   A2 within      A          B 24    4.458333        2.000000  2.458333`\
`#> 4   A2 within      A          C 24    4.458333        1.875000  2.583333`\
`#> 5   A3 within      A          B 24    4.416667        2.208333  2.208333`\
`#> 6   A3 within      A          C 24    4.416667        2.250000  2.166667`\
`#> 7   B1 within      B          A 24    4.583333        2.083333  2.500000`\
`#> 8   B1 within      B          C 24    4.583333        2.166667  2.416667`\
`#>           t df            p        p_adj       dz pass`\
`#> 1  9.591663 23 8.344091e-10 8.344091e-10 1.957890 TRUE`\
`#> 2 11.336315 23 3.409941e-11 3.409941e-11 2.314016 TRUE`\
`#> 3 10.552406 23 1.372752e-10 1.372752e-10 2.154001 TRUE`\
`#> 4 17.643975 23 3.644893e-15 3.644893e-15 3.601561 TRUE`\
`#> 5 11.072214 23 5.409806e-11 5.409806e-11 2.260106 TRUE`\
`#> 6 11.021286 23 5.918580e-11 5.918580e-11 2.249711 TRUE`\
`#> 7 13.133926 23 1.786074e-12 1.786074e-12 2.680951 TRUE`\
`#> 8 14.269216 23 3.241706e-13 3.241706e-13 2.912692 TRUE`

The omnibus F test asks whether the item’s mean ratings differ somewhere
across definitions. The planned contrasts ask the more direct
content-validity question: is the target mean higher than each orbiting
mean?

With more than two construct definitions, the conventional
repeated-measures F test assumes sphericity. `contentvalidR` reports
that historical omnibus test but does not hide the assumption. The
planned target-versus-orbiting comparisons are therefore important
diagnostic evidence rather than decorative post-hoc tests.

## Recommended workflow

\
`fit`` ``<-`` `[`rating_validity`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)`(`\
`  ``rating_dat``,`\
`  scale_min ``=`` ``1``,`\
`  scale_max ``=`` ``5`\
`)`\
`fit`\
`#> contentvalidR construct-rating analysis`\
`#> ---------------------------------------`\
`#> Items: 4 | Raters: 24 | Target scales: 2 | Constructs: 3 `\
`#> Design: within-judge ratings | Scale: 1 to 5 `\
`#> Item inference: one-way repeated-measures ANOVA (Greenhouse-Geisser corrected omnibus p) plus planned paired target-versus-orbiting contrasts `\
`#> Planned-contrast adjustment: none `\
`#> Judges: naive `\
`#> `\
`#> 4 item(s) meet the full item-level screening criterion; 0 item(s) are flagged for review.`\
`#> `\
`#> Item-level evidence:`\
`#>  item target n_complete strongest_competitor   htc   htd p_value max_contrast_p`\
`#>    A1      A         24                    B 0.875 0.557       0              0`\
`#>    A2      A         24                    B 0.892 0.630       0              0`\
`#>    A3      A         24                    C 0.883 0.547       0              0`\
`#>    B1      B         24                    C 0.917 0.615       0              0`\
`#>  recommendation`\
`#>          Retain`\
`#>          Retain`\
`#>          Retain`\
`#>          Retain`\
`#> `\
`#> Target-scale Colquitt benchmark summary:`\
`#>  target n_items n_htc n_htd mean_htc htc_strength mean_htd htd_strength`\
`#>       A       3     3     3    0.883       Strong    0.578  Very Strong`\
`#>       B       1     1     1    0.917  Very Strong    0.615  Very Strong`\
`#>  benchmark_set`\
`#>        overall`\
`#>        overall`\
`#> `\
`#> Colquitt labels are empirical percentile norms for scale-level HTC/HTD averages, not universal cutoffs.`\
`#> 'Review' is not an automatic deletion decision. Consider construct definitions, item wording,`\
`#> orbiting-construct choice, domain coverage, and qualitative judge feedback.`\
[`summary`](https://rdrr.io/r/base/summary.html)`(``fit``)`\
`#> Summary of construct-rating content-validity evidence`\
`#> ---------------------------------------------------`\
`#> Retain: 4 of 4 item(s)`\
`#> Review: 0 of 4 item(s)`\
`#> `\
`#> Target-scale evidence:`\
`#>  target n_items n_htc n_htd n_retain n_review mean_htc htc_strength mean_htd`\
`#>       A       3     3     3        3        0    0.883       Strong    0.578`\
`#>       B       1     1     1        1        0    0.917  Very Strong    0.615`\
`#>  htd_strength overall_strength`\
`#>   Very Strong           Strong`\
`#>   Very Strong      Very Strong`\
`#> `\
`#> A: Strong normative standing on the weaker of definitional correspondence (HTC) and distinctiveness (HTD).`\
`#> B: Very Strong normative standing on the weaker of definitional correspondence (HTC) and distinctiveness (HTD).`\
`#> `\
`#> All analyzed items met the item-level inferential screening criterion.`\
`#> `\
`#> Interpret these results alongside theory, domain coverage, and qualitative feedback.`\
`#> The analysis does not by itself establish comprehensiveness or the full content-validity argument.`

The item-level recommendation has deliberately limited meaning:

- **Retain:** the item cleared the package’s inferential screening rule
  in this pretest.
- **Review:** the full screening rule was not met; inspect wording,
  construct overlap, and judge feedback.
- **Insufficient data:** too few complete judge profiles are available
  for the repeated-measures comparison.

`Review` is not an instruction to delete an item. Content coverage can
be harmed by mechanical item deletion.

## Scale-level Colquitt norms

Colquitt et al. (2019) created empirical norms from **scale-level
averages** of HTC and HTD across 112 published scales.
[`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
therefore averages item HTC/HTD within each target scale before
assigning those descriptive normative labels.

\
`fit``$``scale_summary`\
`#>   target n_items n_htc n_htd n_retain n_review n_insufficient  mean_htc`\
`#> 1      A       3     3     3        3        0              0 0.8833333`\
`#> 2      B       1     1     1        1        0              0 0.9166667`\
`#>   htc_strength  mean_htd htd_strength overall_strength orbiting_r benchmark_set`\
`#> 1       Strong 0.5781250  Very Strong           Strong         NA       overall`\
`#> 2  Very Strong 0.6145833  Very Strong      Very Strong         NA       overall`\
`#>                                                                                                       evidence`\
`#> 1      Strong normative standing on the weaker of definitional correspondence (HTC) and distinctiveness (HTD).`\
`#> 2 Very Strong normative standing on the weaker of definitional correspondence (HTC) and distinctiveness (HTD).`\
[`colquitt_benchmarks`](https://juhalt.github.io/contentvalidR/reference/colquitt_benchmarks.md)`(``"htc"``)`\
`#>   statistic benchmark_set                  benchmark_label interpretation`\
`#> 1       htc       overall Overall (not correlation-normed)    Very Strong`\
`#> 2       htc       overall Overall (not correlation-normed)         Strong`\
`#> 3       htc       overall Overall (not correlation-normed)       Moderate`\
`#> 4       htc       overall Overall (not correlation-normed)           Weak`\
`#> 5       htc       overall Overall (not correlation-normed)        Lack of`\
`#>   percentile minimum`\
`#> 1  80th-99th    0.91`\
`#> 2  60th-79th    0.87`\
`#> 3  40th-59th    0.84`\
`#> 4  20th-39th    0.60`\
`#> 5   0th-19th    -Inf`\
[`colquitt_benchmarks`](https://juhalt.github.io/contentvalidR/reference/colquitt_benchmarks.md)`(``"htd"``)`\
`#>   statistic benchmark_set                  benchmark_label interpretation`\
`#> 1       htd       overall Overall (not correlation-normed)    Very Strong`\
`#> 2       htd       overall Overall (not correlation-normed)         Strong`\
`#> 3       htd       overall Overall (not correlation-normed)       Moderate`\
`#> 4       htd       overall Overall (not correlation-normed)           Weak`\
`#> 5       htd       overall Overall (not correlation-normed)        Lack of`\
`#>   percentile minimum`\
`#> 1  80th-99th    0.35`\
`#> 2  60th-79th    0.27`\
`#> 3  40th-59th    0.18`\
`#> 4  20th-39th    0.04`\
`#> 5   0th-19th    -Inf`

The overall bands are empirical percentile standing, not universal
validity cutoffs. If the average correlation between a focal scale and
its orbiting scales is known, correlation-conditional norms can be
requested:

\
[`rating_validity`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)`(`\
`  ``rating_dat``,`\
`  orbiting_r ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``A ``=`` ``.42``, B ``=`` ``.55``)`\
`)``$``scale_summary`\
`#>   target n_items n_htc n_htd n_retain n_review n_insufficient  mean_htc`\
`#> 1      A       3     3     3        3        0              0 0.8833333`\
`#> 2      B       1     1     1        1        0              0 0.9166667`\
`#>   htc_strength  mean_htd htd_strength overall_strength orbiting_r benchmark_set`\
`#> 1     Moderate 0.5781250  Very Strong         Moderate       0.42      moderate`\
`#> 2  Very Strong 0.6145833  Very Strong      Very Strong       0.55      stronger`\
`#>                                                                                                                                                                               evidence`\
`#> 1 Generally supportive normative standing, with at least one content-validity dimension in the moderate range; inspect weaker items and construct overlap before finalizing the scale.`\
`#> 2                                                                         Very Strong normative standing on the weaker of definitional correspondence (HTC) and distinctiveness (HTD).`

A given level of distinctiveness can be more impressive when the focal
and orbiting constructs are known to correlate strongly.

## Naive versus expert judges

Colquitt et al.’s normative distributions were developed using naive
judges representative of substantive target populations. Their paper
cautions against applying those norms to expert panels. The package
therefore separates calculation from norm applicability:

\
[`rating_validity`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)`(``rating_dat``, judge_type ``=`` ``"expert"``)``$``scale_summary`\
`#>   target n_items n_htc n_htd n_retain n_review n_insufficient  mean_htc`\
`#> 1      A       3     3     3        3        0              0 0.8833333`\
`#> 2      B       1     1     1        1        0              0 0.9166667`\
`#>   htc_strength  mean_htd htd_strength overall_strength orbiting_r benchmark_set`\
`#> 1         <NA> 0.5781250         <NA>             <NA>         NA       overall`\
`#> 2         <NA> 0.6145833         <NA>             <NA>         NA       overall`\
`#>                                                                                                        evidence`\
`#> 1 HTC/HTD are reported descriptively; Colquitt et al. (2019) normative labels are suppressed for expert judges.`\
`#> 2 HTC/HTD are reported descriptively; Colquitt et al. (2019) normative labels are suppressed for expert judges.`

HTC/HTD are still computed, but the Colquitt labels are suppressed.

## Missing ratings

For HTD and repeated-measures inference, a judge must have a usable
rating for every construct definition presented for that item.
Incomplete profiles are excluded itemwise and counted explicitly in the
output. This preserves the paired design rather than quietly treating
incomplete repeated observations as independent data.

## Plotting

The original one-index views remain available:

\
[`plot`](https://rdrr.io/r/graphics/plot.default.html)`(``fit``, metric ``=`` ``"htc"``)`

![](construct-rating-validity_files/figure-html/plot-1.png)

\
[`plot`](https://rdrr.io/r/graphics/plot.default.html)`(``fit``, metric ``=`` ``"htd"``)`

![](construct-rating-validity_files/figure-html/plot-2.png)

A correspondence-distinctiveness evidence map displays HTC and HTD
together:

\
[`plot`](https://rdrr.io/r/graphics/plot.default.html)`(``fit``, type ``=`` ``"map"``)`

![](construct-rating-validity_files/figure-html/rating-map-1.png)

Target-scale averages are shown as diamonds and items needing review are
labeled by default. As with the item-sort map, Colquitt norm regions are
not drawn across individual items because those benchmarks were
constructed from scale averages.

The **target-versus-competitor gap plot** makes the Hinkin-Tracey
mean-rating logic more directly visible:

\
[`plot`](https://rdrr.io/r/graphics/plot.default.html)`(``fit``, type ``=`` ``"profile"``)`

![](construct-rating-validity_files/figure-html/rating-profile-1.png)

Filled points are intended-definition means, open points are the
strongest orbiting-definition means, and the connecting segment is the
observed content distinctiveness gap. A reversed segment immediately
identifies an item whose strongest competitor outrates its intended
definition. This is a graphical extension of the mean-rating tables used
in the original procedure, not a new statistical cutoff.

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

Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach
to content validation. *Organizational Research Methods, 2*(2), 175-186.
<https://doi.org/10.1177/109442819922004>

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243-1265. <https://doi.org/10.1037/apl0000406>

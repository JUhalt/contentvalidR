# Analyze a Hinkin-Tracey construct-rating content-validity pretest

Provides the recommended user-facing workflow for a fully crossed
construct-rating study. Judges rate each item against its intended
construct definition and one or more orbiting definitions.
`rating_validity()` combines:

- Hinkin-Tracey correspondence (HTC),

- Hinkin-Tracey distinctiveness (HTD),

- one-way repeated-measures ANOVA (with Greenhouse-Geisser correction)
  for each item, and

- planned paired target-versus-orbiting contrasts.

The rating task is Hinkin and Tracey's (1999). They analyzed it with a
one-way ANOVA and Duncan's multiple range test; the repeated-measures
form used here, with a planned contrast, follows MacKenzie et al.
(2011). See
[`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
for which details are published and which are this package's choices.

Item-level output is diagnostic rather than a coefficient dump: it
identifies the strongest competing construct, describes why an item was
flagged, and labels statistical screening decisions `"Retain"`,
`"Review"`, or `"Insufficient data"`. An item is labeled `"Retain"` when
its omnibus *p* and every contrast *p* are at or below `alpha`.
`"Review"` is not an instruction to delete the item. An item with fewer
than two judges who rated it against every construct is labeled
`"Insufficient data"`.

Each target-scale mean uses the items whose index rests on at least two
judges, so that one judge cannot move a scale's band. HTC rests on every
judge who rated the item against its intended construct (`n_target`);
HTD and the tests rest on the judges who rated it against every
construct (`n_complete`). An item can therefore count toward mean HTC
and not toward mean HTD, and the printout says how many items are behind
each mean when some are left out. The two-judge minimum is this
package's choice.

Colquitt et al. (2019) norms are applied only to **target-scale
averages** of HTC and HTD, matching the level at which those empirical
benchmarks were constructed. The labels are suppressed for expert
judges.

## Usage

``` r
rating_validity(
  ratings,
  item_col = "item",
  rater_col = "rater",
  construct_col = "construct",
  rating_col = "rating",
  target_map = NULL,
  target_col = "target_construct",
  scale_min = 1,
  scale_max = 5,
  alpha = 0.05,
  adjust = c("none", "holm"),
  orbiting_r = NULL,
  judge_type = c("naive", "expert")
)
```

## Arguments

- ratings:

  Long-format rating data.

- item_col, rater_col, construct_col, rating_col:

  Column names.

- target_map:

  Optional named item-to-target mapping.

- target_col:

  Target column used when `target_map` is `NULL`.

- scale_min, scale_max:

  Endpoints of the equally spaced integer rating scale.

- alpha:

  Significance level for item-level inferential screening.

- adjust:

  Adjustment of the planned-contrast *p* values for the number of
  contrasts: `"none"` (the default; each contrast is a planned
  comparison) or `"holm"` (conservative).

- orbiting_r:

  Optional average focal-orbiting correlation. For multiple target
  scales, use a named numeric vector keyed by target.

- judge_type:

  Either `"naive"` or `"expert"`. Colquitt normative labels are not
  applied to expert-judge data.

## Value

An object of class `contentvalid_rating` and `contentvalid_workflow`.
All flagship workflow objects expose the common components `results`,
`scale_summary`, `settings`, `design`, and `details`. Planned contrasts
live in `details$contrasts`; the historical top-level `contrasts`
component is retained as a compatibility alias. Item-level `results`
include a standardized `status` field while retaining the
method-specific `recommendation` field. In `results`, `p_value` is the
Greenhouse-Geisser corrected omnibus *p* and `df1_gg` and `df2_gg` are
its degrees of freedom, where a correction applies (see
[`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md));
`p_omnibus`, `df1` and `df2` are the uncorrected test; and
`max_contrast_p` is the largest *p* among the planned contrasts, `NA`
when a contrast has no *p*. In `scale_summary`, `n_htc` and `n_htd`
count the items in each mean.

## References

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243–1265.
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406)

Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach
to content validation. *Organizational Research Methods, 2*(2), 175–186.
[doi:10.1177/109442819922004](https://doi.org/10.1177/109442819922004)

MacKenzie, S. B., Podsakoff, P. M., & Podsakoff, N. P. (2011). Construct
measurement and validation procedures in MIS and behavioral research:
Integrating new and existing techniques. *MIS Quarterly, 35*(2),
293–334. [doi:10.2307/23044045](https://doi.org/10.2307/23044045)

## Examples

``` r
set.seed(12)
d <- expand.grid(item = c("A1", "A2", "B1"), rater = 1:20,
                 construct = c("A", "B", "C"))
d$target_construct <- ifelse(d$item == "B1", "B", "A")
d$rating <- ifelse(d$construct == d$target_construct,
                   pmin(5, pmax(1, round(rnorm(nrow(d), 4.5, .6)))),
                   pmin(5, pmax(1, round(rnorm(nrow(d), 2.0, .7)))))
fit <- rating_validity(d, scale_min = 1, scale_max = 5)
fit
#> <contentvalid_rating> Construct-rating analysis
#> Items: 3 | Judges: 20 | Target constructs: 2 | Constructs rated: 3
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
#> 3 of 3 items meet the full item-level screening criterion.
#> 
#> Item-level evidence
#>   Item  Target  Decision   n  HTC  HTD  Omnibus p  Contrast p  Competitor
#>   A1    A       Retain    20  .89  .65     < .001      < .001  B
#>   A2    A       Retain    20  .88  .60     < .001      < .001  B
#>   B1    B       Retain    20  .93  .69     < .001      < .001  C
#> 
#>   n: judges who rated the item against every construct. Omnibus p: do the
#>   item's ratings differ across constructs (Greenhouse-Geisser corrected).
#>   Contrast p: the largest p among the planned target-versus-orbiting
#>   contrasts, so every contrast is at or below it.
#> 
#> Scale-level Colquitt benchmarks
#>   Target  Items  Mean HTC  HTC level    Mean HTD  HTD level
#>   A           2       .89  Strong            .63  Very Strong
#>   B           1       .93  Very Strong       .69  Very Strong
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
#> Retain: 3 of 3 | Review: 0 of 3
#> 
#> Scale-level evidence
#>   Target  Items  Retain  Review  Mean HTC  HTC level    Mean HTD  HTD level
#>   A           2       2       0       .89  Strong            .63  Very Strong
#>   B           1       1       0       .93  Very Strong       .69  Very Strong
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

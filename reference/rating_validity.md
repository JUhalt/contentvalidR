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

Item-level output is diagnostic rather than a coefficient dump: it
identifies the strongest competing construct, describes why an item was
flagged, and labels statistical screening decisions `"Retain"`,
`"Review"`, or `"Insufficient data"`. `"Review"` is not an instruction
to delete the item.

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

  Planned-contrast p-value adjustment: `"none"` (historical
  planned-comparison logic) or `"holm"`.

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
method-specific `recommendation` field.

## References

Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach
to content validation. *Organizational Research Methods, 2*(2), 175-186.
[doi:10.1177/109442819922004](https://doi.org/10.1177/109442819922004)

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243-1265.
[doi:10.1037/apl0000406](https://doi.org/10.1037/apl0000406)

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
#> contentvalidR construct-rating analysis
#> ---------------------------------------
#> Items: 3 | Judges: 20 | Target constructs: 2 | Constructs rated: 3
#> Design: within-judge ratings on a 1 to 5 scale
#> Test: one-way repeated-measures ANOVA (Greenhouse-Geisser corrected omnibus
#> p) plus planned paired target-versus-orbiting contrasts; planned-contrast
#> adjustment: none.
#> Judges: naive, meaning drawn from the kind of people who will answer the
#> items.
#> 
#> 3 of 3 items meet the full item-level screening criterion.
#> 
#> Item-level evidence
#>  item target decision  n HTC HTD omnibus p contrast p competitor
#>    A1      A   Retain 20 .89 .65    < .001     < .001          B
#>    A2      A   Retain 20 .88 .60    < .001     < .001          B
#>    B1      B   Retain 20 .93 .69    < .001     < .001          C
#> 
#> n: judges who rated the item against every construct. omnibus p: do the
#> item's ratings differ across constructs (Greenhouse-Geisser corrected).
#> contrast p: the largest p among the planned target-versus-orbiting contrasts,
#> so every contrast is at or below it.
#> 
#> Target-scale Colquitt benchmarks
#>  target items mean HTC   HTC level mean HTD   HTD level
#>       A     2      .89      Strong      .62 Very Strong
#>       B     1      .93 Very Strong      .69 Very Strong
#> Benchmark set: overall
#> 
#> Colquitt labels are empirical percentile norms for scale-level HTC and HTD
#> averages, not universal cutoffs. HTC is an average rating and HTD is a
#> difference between ratings, so they sit on different scales with different
#> typical values. A high HTC can be labeled Weak in the same analysis where a
#> much smaller HTD is labeled Very Strong. Compare each index against its own
#> benchmark, never against the other index's number.
#> 
#> What these columns mean
#>   HTC -- Hinkin-Tracey Correspondence. Average rating of the item against
#>       its intended construct definition, expressed as a proportion of the
#>       rating scale. (0 to 1; higher is stronger)
#>   HTD -- Hinkin-Tracey Distinctiveness. How far the intended construct's
#>       average rating exceeds the best competing construct's, as a
#>       proportion of the rating scale. It is a difference, so its typical
#>       values are far smaller than HTC's. (usually a small positive number;
#>       higher is stronger)
#> 
#> What the status labels mean
#>   Supported -- The evidence met the criteria set for this analysis.
#>   Review -- Something here needs a closer look. This is not an instruction
#>       to delete anything.
#>   Insufficient data -- Too little usable data to reach a judgment.
#>   Descriptive only -- Reported for description only; no decision rule was
#>       applied.
#>   Each workflow also uses its own wording in the decision column (Retain,
#>   Strong support, Typical, Covered, and so on). Those words map onto the
#>   shared statuses above.
#> 
#> See `contentvalid_glossary()` for all terms, or set
#> `options(contentvalidR.show_key = FALSE)` to hide this key.
#> 
#> 'Review' is not an automatic deletion decision. Consider construct
#> definitions, item wording, orbiting-construct choice, domain coverage, and
#> qualitative judge feedback.
summary(fit)
#> Summary: construct-rating content-validity evidence
#> ---------------------------------------------------
#> Retain: 3 of 3 | Review: 0 of 3
#> 
#> Scale-level evidence
#>  target items retain review mean HTC   HTC level mean HTD   HTD level
#>       A     2      2      0      .89      Strong      .62 Very Strong
#>       B     1      1      0      .93 Very Strong      .69 Very Strong
#>      overall
#>       Strong
#>  Very Strong
#> 
#> A: Strong normative standing on the weaker of definitional correspondence
#>   (HTC) and distinctiveness (HTD).
#> B: Very Strong normative standing on the weaker of definitional
#>   correspondence (HTC) and distinctiveness (HTD).
#> 
#> All analyzed items met the item-level inferential screening criterion.
#> 
#> Interpret these results alongside theory, domain coverage, and qualitative
#> feedback. The analysis does not by itself establish comprehensiveness or the
#> full content-validity argument.
```

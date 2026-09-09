# Manuscript-Ready Reporting Examples

## Purpose

This vignette provides reporting scaffolds for the three flagship
workflows. The examples are intentionally conservative: statistical
screening is described as **evidence for retention or review**, not as
proof that an item or scale is content valid. Final decisions should
also consider construct-domain coverage, item wording, qualitative judge
feedback, and the intended use of the measure.

The bundled CSV files are synthetic, deterministic, and regenerated from
`data-raw/build-example-data.R`. They are useful for reproducing the
examples and for seeing the expected input shape before analyzing a new
study.

## Item-sort study

``` r

sort_dat <- read_example("sort_example.csv")
sort_fit <- sort_validity(sort_dat)
sort_sum <- summary(sort_fit)
sort_fit$results
#>   item target n_total  n n_missing n_target competitor n_other_max  psa  csv
#> 1   A1      A      20 20         0       18       B; C           1 0.90 0.85
#> 2   A2      A      20 20         0       15          B           3 0.75 0.60
#> 3   B1      B      20 20         0       17          A           2 0.85 0.75
#> 4   B2      B      20 20         0       13          A           5 0.65 0.40
#> 5   C1      C      20 20         0       18       A; B           1 0.90 0.85
#> 6   C2      C      20 20         0       14          B           4 0.70 0.50
#>        p_value critical_n_target passes_chance recommendation
#> 1 0.0002012253                15          TRUE         Retain
#> 2 0.0206947327                15          TRUE         Retain
#> 3 0.0012884140                15          TRUE         Retain
#> 4 0.1315879822                15         FALSE         Review
#> 5 0.0002012253                15          TRUE         Retain
#> 6 0.0576591492                15         FALSE         Review
#>                                     issue
#> 1                               Supported
#> 2                               Supported
#> 3                               Supported
#> 4 Target favored, exact criterion not met
#> 5                               Supported
#> 6 Target favored, exact criterion not met
#>                                                                                                                                                                               interpretation
#> 1                                                                                                        Target assignment meets the exact retention criterion (strongest competitor: B; C).
#> 2                                                                                                           Target assignment meets the exact retention criterion (strongest competitor: B).
#> 3                                                                                                           Target assignment meets the exact retention criterion (strongest competitor: A).
#> 4 The target was at least as common as any competitor but did not meet the exact retention criterion (strongest competitor: A); review before deciding whether to revise or remove the item.
#> 5                                                                                                        Target assignment meets the exact retention criterion (strongest competitor: A; B).
#> 6 The target was at least as common as any competitor but did not meet the exact retention criterion (strongest competitor: B); review before deciding whether to revise or remove the item.
#>      status
#> 1 Supported
#> 2 Supported
#> 3 Supported
#> 4    Review
#> 5 Supported
#> 6    Review
sort_fit$scale_summary
#>   target n_items n_items_usable n_retain n_review mean_psa psa_strength
#> 1      A       2              2        2        0    0.825       Strong
#> 2      B       2              2        1        1    0.750     Moderate
#> 3      C       2              2        1        1    0.800     Moderate
#>   mean_csv csv_strength orbiting_r                    benchmark_set
#> 1    0.725       Strong         NA Overall (not correlation-normed)
#> 2    0.575     Moderate         NA Overall (not correlation-normed)
#> 3    0.675       Strong         NA Overall (not correlation-normed)
#>   benchmark_applicable overall_strength
#> 1                 TRUE           Strong
#> 2                 TRUE         Moderate
#> 3                 TRUE         Moderate
#>                                                                                                                             evidence
#> 1                                     Strong normative standing on both definitional correspondence (Psa) and distinctiveness (Csv).
#> 2 Generally supportive normative standing, with at least one dimension in the moderate range; review weaker items before finalizing.
#> 3 Generally supportive normative standing, with at least one dimension in the moderate range; review weaker items before finalizing.
```

### Methods scaffold

Report who completed the sort, how the construct definitions were
presented, the available assignment alternatives, and the a priori
screening rule. A concise methods statement can follow this structure:

> Candidate items were evaluated in an item-sort pretest in which judges
> assigned each item to the construct definition that best represented
> its content. We quantified definitional correspondence using the
> proportion of substantive agreement (Psa) and definitional
> distinctiveness using the substantive-validity coefficient (Csv).
> Item-level screening used the exact target-assignment test described
> by Howard and Melloy (2016), with the null target-assignment
> probability and alpha specified a priori. Target-scale mean Psa and
> Csv were interpreted against Colquitt et al. (2019) norms only when
> the judge population matched the intended use of those norms.

### Results scaffold

For this bundled example, 20 judges evaluated 6 items. 4 items met the
exact screening criterion, 2 were flagged for review, and 0 had
insufficient usable assignments.

A manuscript table can usually be built directly from:

``` r

sort_fit$results[c(
  "item", "target", "n", "n_target", "competitor",
  "psa", "csv", "p_value", "status", "recommendation"
)]
#>   item target  n n_target competitor  psa  csv      p_value    status
#> 1   A1      A 20       18       B; C 0.90 0.85 0.0002012253 Supported
#> 2   A2      A 20       15          B 0.75 0.60 0.0206947327 Supported
#> 3   B1      B 20       17          A 0.85 0.75 0.0012884140 Supported
#> 4   B2      B 20       13          A 0.65 0.40 0.1315879822    Review
#> 5   C1      C 20       18       A; B 0.90 0.85 0.0002012253 Supported
#> 6   C2      C 20       14          B 0.70 0.50 0.0576591492    Review
#>   recommendation
#> 1         Retain
#> 2         Retain
#> 3         Retain
#> 4         Review
#> 5         Retain
#> 6         Review
```

Do not report `Review` as synonymous with deletion. A review flag
identifies an item for substantive inspection; retaining an item for
domain coverage can be a reasonable decision when that rationale is
documented.

## Construct-rating study

``` r

rating_dat <- read_example("rating_example.csv")
rating_fit <- rating_validity(rating_dat, scale_min = 1, scale_max = 5)
rating_sum <- summary(rating_fit)
rating_fit$results
#>   item target n_raters n_complete n_incomplete n_constructs target_mean
#> 1   A1      A       24         24            0            3    4.666667
#> 2   A2      A       24         24            0            3    3.666667
#> 3   B1      B       24         24            0            3    4.666667
#> 4   B2      B       24         24            0            3    3.666667
#> 5   C1      C       24         24            0            3    4.666667
#> 6   C2      C       24         24            0            3    3.666667
#>   target_mean_complete strongest_competitor competitor_mean       htc       htd
#> 1             4.666667                    C        2.333333 0.9333333 0.6666667
#> 2             3.666667                    B        3.333333 0.7333333 0.2083333
#> 3             4.666667                    C        2.333333 0.9333333 0.6666667
#> 4             3.666667                    A        3.333333 0.7333333 0.2083333
#> 5             4.666667                    B        2.333333 0.9333333 0.6666667
#> 6             3.666667                    B        3.333333 0.7333333 0.2083333
#>          F df1 df2    p_omnibus epsilon_gg      p_value partial_eta2
#> 1 237.0769   2  46 5.921046e-25  0.7647059 1.274299e-19    0.9115646
#> 2  37.3750   2  46 2.291004e-10  0.6956522 7.375102e-08    0.6190476
#> 3 237.0769   2  46 5.921046e-25  0.7647059 1.274299e-19    0.9115646
#> 4  37.3750   2  46 2.291004e-10  0.6956522 7.375102e-08    0.6190476
#> 5 237.0769   2  46 5.921046e-25  0.7647059 1.274299e-19    0.9115646
#> 6  37.3750   2  46 2.291004e-10  0.6956522 7.375102e-08    0.6190476
#>   min_mean_diff max_contrast_p contrast_pass recommendation
#> 1     2.3333333   1.122784e-13          TRUE         Retain
#> 2     0.3333333   5.173102e-02         FALSE         Review
#> 3     2.3333333   1.122784e-13          TRUE         Retain
#> 4     0.3333333   5.173102e-02         FALSE         Review
#> 5     2.3333333   1.122784e-13          TRUE         Retain
#> 6     0.3333333   5.173102e-02         FALSE         Review
#>                                          issue
#> 1                                    Supported
#> 2 Target highest, planned contrasts incomplete
#> 3                                    Supported
#> 4 Target highest, planned contrasts incomplete
#> 5                                    Supported
#> 6 Target highest, planned contrasts incomplete
#>                                                                                                                                                                                                        interpretation
#> 1                                                               The intended construct is rated higher than all orbiting constructs and all planned contrasts meet the screening criterion (strongest competitor: C).
#> 2 The intended construct has the highest mean but the full inferential screening criterion was not met (strongest competitor: B); review the weakest target-orbiting comparison before revising or removing the item.
#> 3                                                               The intended construct is rated higher than all orbiting constructs and all planned contrasts meet the screening criterion (strongest competitor: C).
#> 4 The intended construct has the highest mean but the full inferential screening criterion was not met (strongest competitor: A); review the weakest target-orbiting comparison before revising or removing the item.
#> 5                                                               The intended construct is rated higher than all orbiting constructs and all planned contrasts meet the screening criterion (strongest competitor: B).
#> 6 The intended construct has the highest mean but the full inferential screening criterion was not met (strongest competitor: B); review the weakest target-orbiting comparison before revising or removing the item.
#>      status
#> 1 Supported
#> 2    Review
#> 3 Supported
#> 4    Review
#> 5 Supported
#> 6    Review
rating_fit$scale_summary
#>   target n_items n_htc n_htd n_retain n_review n_insufficient  mean_htc
#> 1      A       2     2     2        1        1              0 0.8333333
#> 2      B       2     2     2        1        1              0 0.8333333
#> 3      C       2     2     2        1        1              0 0.8333333
#>   htc_strength mean_htd htd_strength overall_strength orbiting_r benchmark_set
#> 1         Weak   0.4375  Very Strong             Weak         NA       overall
#> 2         Weak   0.4375  Very Strong             Weak         NA       overall
#> 3         Weak   0.4375  Very Strong             Weak         NA       overall
#>                                                                                                                                                            evidence
#> 1 Weak normative standing on at least one dimension; review item wording, construct boundaries, and orbiting-construct choice and consider re-pretesting revisions.
#> 2 Weak normative standing on at least one dimension; review item wording, construct boundaries, and orbiting-construct choice and consider re-pretesting revisions.
#> 3 Weak normative standing on at least one dimension; review item wording, construct boundaries, and orbiting-construct choice and consider re-pretesting revisions.
```

### Methods scaffold

> Judges rated every candidate item against each focal and orbiting
> construct definition using the same response scale. We summarized
> correspondence with HTC and distinctiveness with HTD. Because the same
> judges rated the competing definitions, item-level inference used a
> repeated-measures design. Planned paired contrasts compared each
> item’s intended definition with every orbiting definition; omnibus
> Greenhouse-Geisser-corrected inference was used when applicable.
> Scale-level HTC/HTD norms from Colquitt et al. (2019) were treated as
> empirical benchmarks rather than universal item cutoffs.

### Results scaffold

The example contains 6 items rated by 24 judges against 3 construct
definitions. 3 items were supported by the complete screening rule and 3
were flagged for review.

``` r

rating_fit$results[c(
  "item", "target", "n_complete", "strongest_competitor",
  "htc", "htd", "p_value", "max_contrast_p", "status", "recommendation"
)]
#>   item target n_complete strongest_competitor       htc       htd      p_value
#> 1   A1      A         24                    C 0.9333333 0.6666667 1.274299e-19
#> 2   A2      A         24                    B 0.7333333 0.2083333 7.375102e-08
#> 3   B1      B         24                    C 0.9333333 0.6666667 1.274299e-19
#> 4   B2      B         24                    A 0.7333333 0.2083333 7.375102e-08
#> 5   C1      C         24                    B 0.9333333 0.6666667 1.274299e-19
#> 6   C2      C         24                    B 0.7333333 0.2083333 7.375102e-08
#>   max_contrast_p    status recommendation
#> 1   1.122784e-13 Supported         Retain
#> 2   5.173102e-02    Review         Review
#> 3   1.122784e-13 Supported         Retain
#> 4   5.173102e-02    Review         Review
#> 5   1.122784e-13 Supported         Retain
#> 6   5.173102e-02    Review         Review
```

For review items, report the strongest orbiting competitor. That
information turns a generic statement about weak distinctiveness into a
specific diagnostic about where construct overlap may be occurring.

## Expert-panel study

### Relevance

``` r

expert_rel <- read_example("expert_relevance_example.csv")
expert_rel_matrix <- as.matrix(expert_rel[setdiff(names(expert_rel), "expert")])
expert_fit <- expert_validity(
  expert_rel_matrix,
  mode = "relevance",
  lo = 1,
  hi = 4
)
expert_sum <- summary(expert_fit)
expert_fit$results
#>    item N n_missing         V    ci_low   ci_high               ci_method A
#> 1 Item1 8         0 1.0000000 0.8620238 1.0000000 Penfield-Giacobbi score 8
#> 2 Item2 8         0 0.9166667 0.7415120 0.9768412 Penfield-Giacobbi score 8
#> 3 Item3 8         0 0.8333333 0.6414693 0.9332132 Penfield-Giacobbi score 8
#> 4 Item4 8         0 0.5833333 0.3883467 0.7553240 Penfield-Giacobbi score 6
#> 5 Item5 8         0 0.4166667 0.2446760 0.6116533 Penfield-Giacobbi score 2
#>   I_CVI         Pc kappa_mod cvi_criterion kappa_quality  ci_width
#> 1  1.00 0.00390625 1.0000000          0.78     Excellent 0.1379762
#> 2  1.00 0.00390625 1.0000000          0.78     Excellent 0.2353292
#> 3  1.00 0.00390625 1.0000000          0.78     Excellent 0.2917439
#> 4  0.75 0.10937500 0.7192982          0.78          Good 0.3669773
#> 5  0.25 0.10937500 0.1578947          0.78           Low 0.3669773
#>   recommendation
#> 1 Strong support
#> 2 Strong support
#> 3 Strong support
#> 4         Review
#> 5         Review
#>                                                                                                                                                                interpretation
#> 1 The item meets the common panel-size CVI guideline and shows excellent chance-corrected agreement; Aiken's V and its score interval quantify relevance level and precision.
#> 2 The item meets the common panel-size CVI guideline and shows excellent chance-corrected agreement; Aiken's V and its score interval quantify relevance level and precision.
#> 3 The item meets the common panel-size CVI guideline and shows excellent chance-corrected agreement; Aiken's V and its score interval quantify relevance level and precision.
#> 4              The item does not meet the common panel-size CVI guideline; review wording, relevance, construct coverage, and expert comments before revising or removing it.
#> 5              The item does not meet the common panel-size CVI guideline; review wording, relevance, construct coverage, and expert comments before revising or removing it.
#>      status
#> 1 Supported
#> 2 Supported
#> 3 Supported
#> 4    Review
#> 5    Review
expert_fit$scale_summary
#>   n_items n_experts_min n_experts_max mean_Aiken_V S_CVI_Ave S_CVI_UA
#> 1       5             8             8         0.75       0.8      0.6
#>   n_strong_support n_support n_review n_insufficient
#> 1                3         0        2              0
```

> Experts rated the relevance of each candidate item on a bounded
> ordinal scale. We summarized relevance using Aiken’s V with
> Penfield-Giacobbi score confidence intervals and calculated I-CVI with
> Polit-Beck-Owen modified kappa. S-CVI/Ave and S-CVI/UA were reported
> at the scale level. Panel-size CVI guidelines were used as review aids
> and were considered alongside written expert feedback and construct
> coverage.

In this example, 8 experts evaluated 5 items. The workflow identifies 3
supported items and 2 review items under its quantitative rules.

### Essentiality

``` r

expert_ess <- read_example("expert_essentiality_example.csv")
expert_ess_matrix <- as.matrix(expert_ess[setdiff(names(expert_ess), "expert")])
ess_fit <- expert_validity(expert_ess_matrix, mode = "essentiality")
ess_fit$results
#>    item ne  N       cvr     p_value critical_ne critical_cvr  pass
#> 1 Item1 11 12 0.8333333 0.003173828          10    0.6666667  TRUE
#> 2 Item2 10 12 0.6666667 0.019287109          10    0.6666667  TRUE
#> 3 Item3  8 12 0.3333333 0.193847656          10    0.6666667 FALSE
#> 4 Item4  6 12 0.0000000 0.612792969          10    0.6666667 FALSE
#>   recommendation
#> 1      Supported
#> 2      Supported
#> 3         Review
#> 4         Review
#>                                                                                                                                       interpretation
#> 1                                                                 Essential ratings meet the exact one-sided binomial criterion for this panel size.
#> 2                                                                 Essential ratings meet the exact one-sided binomial criterion for this panel size.
#> 3 Essential ratings do not meet the exact panel-size criterion; review the item and expert rationale before deciding whether to revise or remove it.
#> 4 Essential ratings do not meet the exact panel-size criterion; review the item and expert rationale before deciding whether to revise or remove it.
#>      status
#> 1 Supported
#> 2 Supported
#> 3    Review
#> 4    Review
```

For an essentiality task, state that CVR is tied to a different expert
judgment than relevance. Report the effective panel size and exact
critical essential count for each item rather than borrowing a
relevance/CVI threshold.

### Congruence

``` r

expert_ioc <- read_example("expert_congruence_example.csv")
ioc_fit <- expert_validity(expert_ioc, mode = "congruence")
ioc_fit$results
#>   item target target_ioc strongest_competitor competitor_ioc    margin
#> 1   I1      A  1.0000000                    B     -0.6666667 1.6666667
#> 2   I2      B  1.0000000                    A     -0.6666667 1.6666667
#> 3   I3      C  0.8333333                    B      0.5000000 0.3333333
#>   recommendation
#> 1 Target favored
#> 2 Target favored
#> 3 Target favored
#>                                                                                                       interpretation
#> 1 The intended objective has the highest IOC; use the margin and expert comments to judge practical distinctiveness.
#> 2 The intended objective has the highest IOC; use the margin and expert comments to judge practical distinctiveness.
#> 3 The intended objective has the highest IOC; use the margin and expert comments to judge practical distinctiveness.
#>      status
#> 1 Supported
#> 2 Supported
#> 3 Supported
```

For IOC, report the intended objective, target IOC, strongest competing
objective, and target-minus-competitor margin. The margin is diagnostic
evidence about alignment; it is not a newly invented significance test.

## Minimum reproducibility statement

At minimum, a manuscript or supplement should identify the package
version and record the analysis settings that determine the results. For
a fitted workflow:

``` r

packageVersion("contentvalidR")
#> [1] '0.1.0.9000'
sort_fit$settings
#> $method
#> [1] "Anderson-Gerbing Psa/Csv with Howard-Melloy exact inference"
#> 
#> $item_inference
#> [1] "Howard-Melloy exact target-count test"
#> 
#> $scale_benchmarks
#> [1] "Colquitt et al. (2019) empirical percentile norms"
#> 
#> $p0
#> [1] 0.5
#> 
#> $alpha
#> [1] 0.05
#> 
#> $judge_type
#> [1] "naive"
sort_fit$design
#> $type
#> [1] "item-sort"
#> 
#> $n_items
#> [1] 6
#> 
#> $n_raters
#> [1] 20
#> 
#> $n_judges_min
#> [1] 20
#> 
#> $n_judges_max
#> [1] 20
#> 
#> $n_missing
#> [1] 0
#> 
#> $n_target_scales
#> [1] 3
#> 
#> $n_constructs_observed
#> [1] 3
```

A strong reproducibility supplement should also archive the item
wording, construct definitions, judge instructions, anonymized response
data when permitted, and the script that reproduces all tables and
figures.

## Language to avoid

Avoid claims such as “the scale was proven content valid” or “items
failing the cutoff were invalid.” The workflows quantify evidence from a
defined pretest. They do not replace a theory-based definition of the
construct domain or the researcher’s responsibility to justify
substantive item decisions.

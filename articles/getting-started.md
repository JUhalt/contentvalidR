# Getting Started with contentvalidR

``` r

library(contentvalidR)
```

## Overview

contentvalidR analyzes the evidence that judges and experts provide
about a scale’s content before anyone answers it. Each kind of study has
its own workflow function, and each workflow has a guide:

| The study | Workflow | Guide |
|----|----|----|
| Judges sort each item into the construct it best represents | [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md) | [`vignette("item-sort-validity")`](https://juhalt.github.io/contentvalidR/articles/item-sort-validity.md) |
| Judges rate each item against every construct definition | [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md) | [`vignette("construct-rating-validity")`](https://juhalt.github.io/contentvalidR/articles/construct-rating-validity.md) |
| Experts rate each item’s relevance, essentiality, or congruence with an objective | [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md) | [`vignette("expert-panel-validity")`](https://juhalt.github.io/contentvalidR/articles/expert-panel-validity.md) |
| A panel rates the items over several Delphi rounds | [`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md) | [`vignette("delphi-rounds")`](https://juhalt.github.io/contentvalidR/articles/delphi-rounds.md) |
| Do the conclusions depend on the particular judges? | [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md) | “Reading judge heterogeneity” in [`vignette("reading-output")`](https://juhalt.github.io/contentvalidR/articles/reading-output.md) |
| Do the items cover every cell of the blueprint? | [`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md) | “Reading domain coverage” in [`vignette("reading-output")`](https://juhalt.github.io/contentvalidR/articles/reading-output.md) |

Two functions work across the workflows.
[`content_evidence()`](https://juhalt.github.io/contentvalidR/reference/content_evidence.md)
sets several review stages side by side, item by item, and draws them as
figures
([`vignette("reporting-examples")`](https://juhalt.github.io/contentvalidR/articles/reporting-examples.md)).
[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
carries the items a review kept, with the evidence behind each decision,
into the analysis of response data
([`vignette("handoff-to-empirical-validation")`](https://juhalt.github.io/contentvalidR/articles/handoff-to-empirical-validation.md),
and
[`vignette("one-item-set-both-stages")`](https://juhalt.github.io/contentvalidR/articles/one-item-set-both-stages.md)
for one item set followed through both stages).

This vignette runs the first three workflows on small examples and
points to the rest.
[`vignette("reading-output")`](https://juhalt.github.io/contentvalidR/articles/reading-output.md)
explains every part of a printout, and
[`vignette("design-and-reporting")`](https://juhalt.github.io/contentvalidR/articles/design-and-reporting.md)
covers how many judges to recruit and what to report.

## A common workflow contract

All six workflow objects expose `results`, `scale_summary`, `settings`,
`design`, and `details`. Their `results` tables also contain a common
`status` field: `Supported`, `Review`, `Insufficient data`, or
`Descriptive only`. The method’s own decision word, such as `Retain` in
an item sort, is kept beside it as `recommendation`. This makes it
possible to write reusable code across workflows without pretending that
a Howard-Melloy retention decision, a construct-rating screening result,
and an expert-panel judgment are substantively identical.

## Item sort: Psa, Csv, and the exact test

Twelve judges sorted four items into three constructs, A, B, and C.
Items I1 and I2 were written for A, and I3 and I4 for B:

``` r

toy_sort <- data.frame(
  item = rep(paste0("I", 1:4), each = 12),
  rater = rep(1:12, 4),
  target_construct = rep(c("A", "A", "B", "B"), each = 12),
  assigned_construct = c(
    rep("A", 11), "C",
    rep("A", 10), "B", "C",
    rep("B", 7), rep("A", 4), "C",
    rep("B", 4), rep("A", 6), rep("C", 2)
  )
)
sort_fit <- sort_validity(toy_sort)
sort_fit
#> <contentvalid_sort> Item-sort analysis
#> Items: 4 | Judges: 12 | Target constructs: 2
#> Test: Howard-Melloy exact target-count test (p0 = .50, alpha = .05)
#> Judges: naive, meaning drawn from the kind of people who will answer the
#> items.
#> 
#> 2 of 4 items meet the exact target-assignment criterion.
#> Flagged for review: I3, I4
#> 
#> Item-level evidence
#>   Item  Target  Decision  Judges  Psa      95% CI   Csv  Competitor     p
#>   I1    A       Retain     11/12  .92  [.65, .99]   .83  C           .003
#>   I2    A       Retain     10/12  .83  [.55, .95]   .75  B; C        .019
#>   I3    B       Review      7/12  .58  [.32, .81]   .25  A           .387
#>   I4    B       Review      4/12  .33  [.14, .61]  -.17  A           .927
#> 
#>   Judges: assignments to the target construct, out of the judges who sorted
#>   the item.
#>   95% intervals for proportions: Wilson score (the default). Newcombe (1998)
#>   compared seven methods and recommends score intervals over the Wald
#>   interval. An interval reflects how few ratings an item received, not whether
#>   the right people rated it.
#> 
#> Scale-level Colquitt benchmarks
#>   Target  Items  Mean Psa  Psa level  Mean Csv  Csv level
#>   A           2       .88  Strong          .79  Strong
#>   B           2       .46  Weak            .04  Lack of
#>   Benchmark set: Overall (not correlation-normed)
#> 
#>   Colquitt labels are empirical percentile norms derived from scale-level
#>   averages, not universal cutoffs or automatic scale-retention rules. They
#>   place a scale against published scales. Psa and Csv sit on different scales,
#>   so their values cannot be compared with each other; their labels can,
#>   because each is a percentile position among published scales.
#> 
#> What these columns mean
#>   Psa -- Proportion of Substantive Agreement. Share of judges who put the item
#>       in the construct it was written for (0 to 1; higher is stronger).
#>   95% CI -- Interval for Psa. Wider when fewer judges sorted the item; the
#>       method is named above.
#>   Csv -- Coefficient of Substantive Validity. How much more often judges chose
#>       the intended construct than its closest rival (-1 to 1; 0 is a tie).
#>   Competitor -- Strongest competing construct. The construct other than the
#>       intended one that judges chose most often.
#>   p -- Howard-Melloy exact test. Probability of at least this many target
#>       assignments if each judge picked the target at rate p0; compare with
#>       alpha.
#> 
#> What the decisions mean
#>   Retain -- met the exact target-assignment criterion.
#>   Review -- did not meet the exact target-assignment criterion; the competitor
#>       column shows where judges put it instead.
#> 
#>   Full definitions: contentvalid_glossary(). To hide this key:
#>   options(contentvalidR.show_key = FALSE).
#> 
#> A flag for review is not an automatic deletion decision. Use theory,
#> construct-domain coverage, item wording, and qualitative judge feedback
#> alongside these statistics.
#> 
#> See summary(x) for the flagged items and content_report(x) for an APA table.
```

### Interpretation

- **Psa**, the proportion of substantive agreement, is the share of
  judges who assign the item to its intended construct:
  $`\text{Psa} = n_{target} / N`$.
- **Csv**, the substantive-validity coefficient, is the intended
  construct’s margin over its strongest competitor:
  $`\text{Csv} = (n_{target} - n_{competitor}) / N`$. Here
  $`n_{target}`$ counts the assignments to the intended construct,
  $`n_{competitor}`$ those to the most-chosen other construct, and $`N`$
  the judges who sorted the item (Anderson & Gerbing, 1991). A negative
  Csv, as for I4, means a competing construct drew more judges than the
  intended one.
- The exact binomial test of Howard and Melloy (2016) asks whether the
  target count is too large for a target rate of .50 or less. With
  twelve judges an item needs ten target assignments, so I1 and I2 are
  retained and I3 and I4 are flagged for review. The .50 is a benchmark
  rate, not the rate random sorting would give, which is 1 divided by
  the number of constructs.

The components are also available on their own:

``` r

compute_csv(toy_sort)
#> <contentvalid_csv> Coefficient of substantive validity (Csv)
#> Anderson and Gerbing (1991).
#> 
#>   Item  Target  Judges  Competitor  Competitor judges   Csv
#>   I1    A        11/12  C                        1/12   .83
#>   I2    A        10/12  B; C                     1/12   .75
#>   I3    B         7/12  A                        4/12   .25
#>   I4    B         4/12  A                        6/12  -.17
#> 
#> Csv is the target count minus the count for the most-chosen other construct,
#> divided by the number of judges.
#> 
#> See as.data.frame(x) for the unrounded values.
csv_binom_test(n_c = 10, N = 12)
#> <contentvalid_binom> Howard-Melloy exact test (one-sided)
#> 
#> The item meets the exact target-assignment criterion.
#> 10 of 12 judges assigned the item to its target construct (Psa = .83). If each
#> judge chose the target with probability p0 = .50, a count this high has
#> probability p = .019.
#> At alpha = .05 an item needs at least 10 of 12.
#> One-sided 95% CI for the target rate: [.56, 1.00].
#> 
#> See as.data.frame(x) for the test as one row.
```

## Construct ratings: HTC, HTD, and the repeated-measures test

``` r

set.seed(2)
toy_ratings <- expand.grid(
  item = c("I1", "I2", "I3"),
  rater = 1:16,
  construct = c("A", "B", "C")
)
toy_ratings$target_construct <- ifelse(toy_ratings$item == "I3", "B", "A")
toy_ratings$rating <- ifelse(
  toy_ratings$construct == toy_ratings$target_construct,
  pmin(5, pmax(1, round(rnorm(nrow(toy_ratings), 4.4, .6)))),
  pmin(5, pmax(1, round(rnorm(nrow(toy_ratings), 2.2, .7))))
)

rating_fit <- rating_validity(toy_ratings, scale_min = 1, scale_max = 5)
rating_fit
#> <contentvalid_rating> Construct-rating analysis
#> Items: 3 | Judges: 16 | Target constructs: 2 | Constructs rated: 3
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
#>   Item  Target  Decision  Judges  HTC  HTD  Omnibus p  Contrast p  Competitor
#>   I1    A       Retain        16  .83  .49     < .001      < .001  C
#>   I2    A       Retain        16  .89  .51     < .001      < .001  C
#>   I3    B       Retain        16  .88  .54     < .001      < .001  C
#> 
#>   Judges: the number who rated the item against every construct. Omnibus p: do
#>   the item's ratings differ across constructs (Greenhouse-Geisser corrected).
#>   Contrast p: the largest p among the planned target-versus-orbiting
#>   contrasts, so every contrast is at or below it.
#> 
#> Scale-level Colquitt benchmarks
#>   Target  Items  Mean HTC  HTC level  Mean HTD  HTD level
#>   A           2       .86  Moderate        .50  Very Strong
#>   B           1       .88  Strong          .54  Very Strong
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
summary(rating_fit)
#> <contentvalid_rating summary> Construct-rating analysis
#> Retain: 3 of 3 | Review: 0 of 3
#> 
#> Scale-level evidence
#>   Target  Items  Retain  Review  Mean HTC  HTC level  Mean HTD  HTD level
#>   A           2       2       0       .86  Moderate        .50  Very Strong
#>   B           1       1       0       .88  Strong          .54  Very Strong
#> 
#>   HTC = Hinkin-Tracey correspondence; HTD = Hinkin-Tracey distinctiveness
#>   (Colquitt et al., 2019).
#>   A: Mean HTC falls in the Moderate band and mean HTD in the Very Strong band
#>     of published scales (Colquitt et al., 2019). A contentvalidR suggestion
#>     for the lower band, Moderate: inspect the weaker items and construct
#>     overlap before finalizing the scale.
#>   B: Mean HTC falls in the Strong band and mean HTD in the Very Strong band of
#>     published scales (Colquitt et al., 2019).
#> 
#> All analyzed items met the item-level inferential screening criterion.
#> 
#> Interpret these results alongside theory, domain coverage, and qualitative
#> feedback. The analysis does not by itself establish comprehensiveness or the
#> full content-validity argument.
#> 
#> See summary(x)$reviewed_items for the flagged items as a data frame.
```

### Interpretation

- **HTC** summarizes definitional correspondence: how highly judges
  rated the item against its intended construct (Hinkin & Tracey, 1999;
  Colquitt et al., 2019).
- **HTD** summarizes definitional distinctiveness: how far the intended
  construct’s ratings lead the orbiting constructs’ ratings, on average.
- The repeated-measures ANOVA tests whether the construct-definition
  ratings differ for an item.
- Planned paired contrasts ask the direct screening question: is the
  target rating significantly higher than every orbiting rating?
- Scale-level HTC and HTD averages can be read against the empirical
  norms of Colquitt et al. (2019) when the judges are like the naive
  judges those norms came from.

## Expert panels: relevance, essentiality, and congruence

``` r

expert_ratings <- matrix(
  c(4,4,4,4,4,4,
    4,4,4,3,4,4,
    4,3,4,4,3,4),
  nrow = 6,
  dimnames = list(NULL, paste0("Item", 1:3))
)
expert_fit <- expert_validity(expert_ratings, mode = "relevance", lo = 1, hi = 4)
expert_fit
#> <contentvalid_expert> Expert-panel analysis
#> Mode: relevance
#> Items: 3 | Experts per item: 6
#> Scale: 1 to 4 | Relevant: a rating of 3 or higher
#> Mean Aiken's V: .94 | S-CVI/Ave: 1.00 | S-CVI/UA: 1.00
#> Panel agreement, Krippendorff's alpha (ordinal): .02, 95% CI [-.13, .15].
#>   Identical rating pairs: 71%.
#> 
#> 3 of 3 items meet the I-CVI criterion.
#> 
#>   Item   Decision        Experts     V       95% CI  I-CVI       95% CI  Kappa
#>   Item1  Strong support        6  1.00  [.82, 1.00]   1.00  [.61, 1.00]   1.00
#>   Item2  Strong support        6   .94   [.74, .99]   1.00  [.61, 1.00]   1.00
#>   Item3  Strong support        6   .89   [.67, .97]   1.00  [.61, 1.00]   1.00
#> 
#> Each 95% CI follows its estimate: Aiken's V has a Penfield-Giacobbi score
#> interval, and I-CVI the proportion interval named below.
#> I-CVI criterion for 6 experts: 5 agreeing (.83), following Lynn (1986). Kappa
#> is modified kappa, read as excellent above .74 (Polit et al., 2007).
#> 95% intervals for proportions: Wilson score (the default). Newcombe (1998)
#> compared seven methods and recommends score intervals over the Wald interval.
#> An interval reflects how few ratings an item received, not whether the right
#> people rated it.
#> 
#> Panel agreement is one coefficient for the whole panel, whereas modified kappa
#> (the kappa column) describes each item. Alpha can be low when nearly every
#> rating is the same value, even on a panel that agrees closely, so read it
#> beside the share of identical rating pairs. A low alpha with many identical
#> pairs is not by itself evidence of a poor panel. Print x$details$agreement for
#> the full explanation and interval details.
#> 
#> CVI criteria are published panel-size guidelines, not universal validity
#> cutoffs.
#> 
#> What these columns mean
#>   S-CVI/Ave -- Scale-level CVI, averaging method. Mean of the items' I-CVIs;
#>       Polit and Beck (2006) recommend .90 or higher.
#>   S-CVI/UA -- Scale-level CVI, universal agreement. Share of items every
#>       expert rated relevant; it falls as experts are added.
#>   V -- Aiken's V. Mean relevance rating rescaled to run from 0 (lowest
#>       possible) to 1 (highest).
#>   I-CVI -- Item-level Content Validity Index. Share of experts rating the item
#>       relevant, against Lynn's criterion for the panel size (beyond ten, this
#>       package's).
#>   95% CI after I-CVI -- Interval for I-CVI. Wide because expert panels are
#>       small; the method is named above.
#>   Kappa -- Modified kappa. I-CVI corrected for chance agreement (at most 1;
#>       below 0 only when no expert, or one of three, rated it relevant).
#>   Panel agreement -- Panel-level agreement. One coefficient for the whole
#>       panel (1 is perfect, 0 is chance); it can be low when nearly every
#>       rating is the same.
#> 
#> What the decisions mean
#>   Strong support -- met the I-CVI criterion, which also puts modified kappa
#>       above .74.
#> 
#>   Full definitions: contentvalid_glossary(). To hide this key:
#>   options(contentvalidR.show_key = FALSE).
#> 
#> Use quantitative indices alongside expert comments, construct coverage, and
#> comprehensibility review.
#> 
#> See summary(x) for the flagged items and content_report(x) for an APA table.
summary(expert_fit)
#> <contentvalid_expert summary> Expert-panel analysis
#> Mode: relevance
#> Scale: 1 to 4 | Relevant: a rating of 3 or higher
#> Strong support: 3 of 3 | Review: 0 of 3
#> I-CVI criterion for 6 experts: 5 agreeing (.83), following Lynn (1986).
#> Panel agreement, Krippendorff's alpha (ordinal): .02, 95% CI [-.13, .15].
#>   Identical rating pairs: 71%.
#> 
#> No items were flagged by the workflow's quantitative review rules.
#> 
#> These summaries support, but do not replace, qualitative content review.
#> 
#> See summary(x)$reviewed_items for the flagged items as a data frame.
```

Relevance, essentiality, and congruence are intentionally separate
expert tasks. Use `mode = "relevance"` for Aiken’s V with the I-CVI and
modified kappa, `mode = "essentiality"` for Lawshe’s CVR, and
`mode = "congruence"` for the index of item-objective congruence (IOC).
[`vignette("expert-panel-validity")`](https://juhalt.github.io/contentvalidR/articles/expert-panel-validity.md)
walks through all three.

## Delphi rounds

When the same panel rates the items over several rounds, with anonymous
feedback in between,
[`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md)
answers two questions side by side: whether enough experts agree about
an item now (consensus, against a threshold you fix before the study),
and whether experts are still changing their ratings (stability). It
never folds one into the other. See
[`vignette("delphi-rounds")`](https://juhalt.github.io/contentvalidR/articles/delphi-rounds.md).

## Judges and domain coverage

Two workflows ask questions that no item-level index can reach.
[`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
returns one row per judge and asks whether the conclusions depend on the
particular judges who served.
[`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md)
returns one row per cell of the content blueprint and asks whether the
items cover every cell, including a cell no item was written for. Both
are read in
[`vignette("reading-output")`](https://juhalt.github.io/contentvalidR/articles/reading-output.md).

## From review to response data

[`content_evidence()`](https://juhalt.github.io/contentvalidR/reference/content_evidence.md)
brings several review stages together, such as a relevance panel
followed by an item sort, and draws a flow diagram and an evidence
profile for a paper or poster
([`vignette("reporting-examples")`](https://juhalt.github.io/contentvalidR/articles/reporting-examples.md)).
[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
packages a review’s decision for the empirical stage: the items carried
forward, the items held back and why, and two facts only you know, the
reverse-worded items and the response scale:

``` r

handoff <- content_handoff(sort_fit, reverse_keyed = character(0),
                           response_scale = c(1, 5))
handoff$items
#> [1] "I1" "I2"
```

[`vignette("handoff-to-empirical-validation")`](https://juhalt.github.io/contentvalidR/articles/handoff-to-empirical-validation.md)
describes what the handoff holds, and
[`vignette("one-item-set-both-stages")`](https://juhalt.github.io/contentvalidR/articles/one-item-set-both-stages.md)
follows one item set through content review and the analysis of
responses.

## Bundled reproducible examples

The package also installs deterministic CSV examples for the three
workflow families and all expert-panel modes. They are synthetic,
contain no participant data, and are regenerated from
`data-raw/build-example-data.R` in the source repository.

``` r

example_files <- c(
  "sort_example.csv",
  "rating_example.csv",
  "expert_relevance_example.csv",
  "expert_essentiality_example.csv",
  "expert_congruence_example.csv"
)
paths <- vapply(example_files, function(x) {
  system.file("extdata", x, package = "contentvalidR")
}, character(1))
file.exists(paths)
#> [1] TRUE TRUE TRUE TRUE TRUE
```

See
[`vignette("reporting-examples", package = "contentvalidR")`](https://juhalt.github.io/contentvalidR/articles/reporting-examples.md)
for manuscript-ready reporting scaffolds built from those same files.

## Classic indices

``` r

R <- matrix(sample(1:5, 5*6, replace = TRUE), nrow = 5)
aikens_v(R, lo = 1, hi = 5)
#> <contentvalid_aiken> Aiken's V
#> Aiken (1980).
#> 
#>   Item   Experts    V      95% CI
#>   Item1        5  .60  [.39, .78]
#>   Item2        5  .30  [.15, .52]
#>   Item3        5  .70  [.48, .85]
#>   Item4        5  .35  [.18, .57]
#>   Item5        5  .60  [.39, .78]
#>   Item6        5  .65  [.43, .82]
#> 
#> Scale: 1 to 5.
#> Interval: Penfield-Giacobbi score (Penfield & Giacobbi, 2004).
#> 
#> See as.data.frame(x) for the unrounded values.

cvr(essential = c(8,10,5), N = 12)
#> <contentvalid_cvr> Content validity ratio (CVR)
#> Lawshe (1975).
#> 
#>   Item   Essential   CVR     p  Needed  Meets
#>   Item1       8/12   .33  .194      10  no
#>   Item2      10/12   .67  .019      10  yes
#>   Item3       5/12  -.17  .806      10  no
#> 
#> Needed: essential ratings the exact one-sided binomial test requires at
#> alpha = .05 (Ayre & Scally, 2014).
#> 
#> See as.data.frame(x) for the unrounded values.

M <- matrix(sample(0:1, 6*5, replace = TRUE, prob = c(.3,.7)), nrow = 6)
cvi(M)
#> <contentvalid_cvi> Content validity index (CVI)
#> Items: 5 | Experts per item: 6
#> S-CVI/Ave: .67 | S-CVI/UA: .20
#> I-CVI = item-level content validity index; S-CVI/Ave = scale-level CVI, the
#> mean I-CVI; S-CVI/UA = scale-level CVI, the share of items every expert rated
#> relevant (Polit & Beck, 2006).
#> 
#> Item-level results
#>   Item   Agree  I-CVI       95% CI    Pc  Kappa
#>   Item1    3/6    .50   [.19, .81]  .313    .27
#>   Item2    4/6    .67   [.30, .90]  .234    .56
#>   Item3    3/6    .50   [.19, .81]  .313    .27
#>   Item4    6/6   1.00  [.61, 1.00]  .016   1.00
#>   Item5    4/6    .67   [.30, .90]  .234    .56
#> 
#>   Agree: experts rating the item relevant, out of those who rated it. Pc: the
#>   probability that this many experts would agree by chance. Kappa: the
#>   modified kappa of Polit et al. (2007), the I-CVI chance-corrected by Pc.
#> 
#>   95% intervals for proportions: Wilson score (the default). Newcombe (1998)
#>   compared seven methods and recommends score intervals over the Wald
#>   interval. An interval reflects how few ratings an item received, not whether
#>   the right people rated it.
#> 
#> Polit and Beck (2006) recommend reporting both S-CVI/Ave and S-CVI/UA.
#> Interpretation should consider panel size, item purpose, and qualitative
#> expert feedback; CVI statistics alone do not establish comprehensive content
#> validity.
#> 
#> See as.data.frame(x) for the item-level values.

ioc_df <- data.frame(
  item = rep(paste0("I",1:2), each = 9),
  judge = rep(1:3, times = 6),
  objective = rep(rep(LETTERS[1:3], each = 3), times = 2),
  score = sample(c(-1,0,1), 18, replace = TRUE)
)
ioc(ioc_df)
#> <contentvalid_ioc> Index of item-objective congruence (IOC)
#> Rovinelli and Hambleton (1977).
#> 
#>   Item  Objective  Experts  Mean   IOC
#>   I1    A                3   .00   .08
#>   I1    B                3   .33   .33
#>   I1    C                3  -.67  -.42
#>   I2    A                3   .00   .00
#>   I2    B                3   .00   .00
#>   I2    C                3   .00   .00
#> 
#> Mean: the experts' mean rating on the objective (-1 to 1). IOC: half the gap
#> between that mean and their mean on the item's other objectives; 1 only when
#> every expert rates +1 on the objective and -1 on every other. Rovinelli and
#> Hambleton applied a criterion of .70.
#> 
#> See as.data.frame(x) for the unrounded values.
```

## Diagnostics and reproducibility

Two auxiliary helpers compare the sort’s decisions with a later outcome.
Here the later outcome is invented: suppose a confirmatory factor
analysis kept I1, I2, and I3, and a second, independent sort supported
I1, I2, and I4.

``` r

pretest_supported <- sort_fit$results$status == "Supported"
later_retained <- c(TRUE, TRUE, TRUE, FALSE)
signal_detection(pretest_supported, later_retained)
#> <contentvalid_signal> Retention decisions compared with the actual outcome
#> 
#>   Predicted     Actual: Retain  Actual: Not retained
#>   Retain                     2                     0
#>   Not retained               1                     1
#> 
#> accuracy = .75, sensitivity = .67, specificity = 1.00, phi = .58, Fisher's
#> exact p > .999.
#> An expected count is below 5, so the exact test is reported in place of the
#> chi-square approximation (chi-square(1, N = 4) = 1.33, p = .248).
#> 
#> See as.data.frame(x) for the counts and the test as one row.

replication_supported <- c(TRUE, TRUE, FALSE, TRUE)
reproducibility_phi(pretest_supported, replication_supported)
#> <contentvalid_reproducibility> Retention decisions in two pretests
#> 
#>   Pretest1      Pretest2: Retain  Pretest2: Not retained
#>   Retain                       2                       0
#>   Not retained                 1                       1
#> 
#> phi = .58, Fisher's exact p > .999.
#> An expected count is below 5, so the exact test is reported in place of the
#> chi-square approximation (chi-square(1, N = 4) = 1.33, p = .248).
#> 
#> See as.data.frame(x) for the counts and the test as one row.
```

Four items are far too few for either coefficient to mean much; the
example shows the calls. With so few items every expected count is below
5, so both helpers report Fisher’s exact *p*.

## Power quick-checks

[`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md)
gives the exact probability that an item reaches the retention count,
for each number of judges and each rate at which you expect judges to
choose the target.
[`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md)
does the same for the I-CVI criterion of an expert panel; see
[`vignette("design-and-reporting")`](https://juhalt.github.io/contentvalidR/articles/design-and-reporting.md).

``` r

sort_power(N = c(20, 30), true_p = c(.65, .75))
#> <contentvalid_sort_power> Item-sort planning
#> Retention rule: Howard-Melloy exact test (p0 = .50, alpha = .05)
#> 
#>   Judges  Required  Minimum Psa  Power at .65  Power at .75
#>       20     15/20          .75           .25           .62
#>       30     20/30          .67           .51           .89
#> 
#> Required: target assignments an item needs to be retained. Minimum Psa: the
#> same as a proportion (Psa = proportion of substantive agreement). Power at a
#> value: the exact probability of reaching the required count if each judge
#> assigns the item to its target with that probability.
#> 
#> See plot(x) for the power curve.
```

## References

Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
measures in a confirmatory factor analysis with a pretest assessment of
their substantive validities. *Journal of Applied Psychology, 76*(5),
732–740. <https://doi.org/10.1037/0021-9010.76.5.732>

Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
Content validation guidelines: Evaluation criteria for definitional
correspondence and definitional distinctiveness. *Journal of Applied
Psychology, 104*(10), 1243–1265. <https://doi.org/10.1037/apl0000406>

Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach
to content validation. *Organizational Research Methods, 2*(2), 175–186.
<https://doi.org/10.1177/109442819922004>

Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task
methods: The presentation of a new statistical significance formula and
methodological best practices. *Journal of Business and Psychology,
31*(1), 173–186. <https://doi.org/10.1007/s10869-015-9404-y>

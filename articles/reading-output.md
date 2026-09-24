# How to Read contentvalidR Output

``` r

library(contentvalidR)
```

## Who this is for

This vignette is for readers meeting these methods for the first time:
graduate students developing a scale, and researchers who need to report
content-validity evidence without first reading five primary sources.

It walks through what each part of the output means, what it does
**not** mean, and how to describe the result in a manuscript. The other
vignettes show how to *run* each workflow; this one shows how to *read*
what comes back.

If you only remember one thing: **every statistic here is evidence for a
judgment you make, not a judgment the package makes for you.**

## The shared vocabulary

Every flagship workflow returns an object with the same five parts.

| Component | What it holds |
|----|----|
| `results` | One row per unit of analysis, with a status and a plain-language interpretation |
| `scale_summary` | The same evidence aggregated to the scale or panel level |
| `settings` | Every threshold and option that produced this result |
| `design` | What data you actually had: counts, missingness, effective judge numbers |
| `details` | Supporting tables and component analyses |

The unit of analysis in `results` differs by workflow, and this catches
people out.
[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md),
[`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md),
and
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
return **one row per item**.
[`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
returns **one row per judge**.
[`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md)
returns **one row per blueprint cell**.

Every `results` table carries a `status` column drawn from a shared
vocabulary:

``` r

attr(contentvalid_glossary(), "statuses")
#>              status
#> 1         Supported
#> 2            Review
#> 3 Insufficient data
#> 4  Descriptive only
#>                                                                              meaning
#> 1                               The evidence met the criteria set for this analysis.
#> 2 Something here needs a closer look. This is not an instruction to delete anything.
#> 3                                        Too little usable data to reach a judgment.
#> 4                       Reported for description only; no decision rule was applied.
```

`Review` is the one people misread. It does not mean “delete this.” It
means something here rewards a closer look, and you are the one who
looks.

## Reading an item-sort result

``` r

sorts <- read.csv(
  system.file("extdata", "sort_example.csv", package = "contentvalidR"),
  stringsAsFactors = FALSE
)
fit_sort <- sort_validity(sorts)
fit_sort
#> contentvalidR item-sort analysis
#> --------------------------------
#> Items: 6 | Raters: 20 | Target scales: 3 
#> Item inference: Howard-Melloy exact target-count test (p0 = 0.50, alpha = 0.050) 
#> Judges: naive 
#> 
#> 4 item(s) meet the exact target-assignment criterion; 2 item(s) are flagged for review.
#> Review: B2, C2 
#> 
#> Item-level evidence:
#>  item target  n n_target competitor  psa psa_low psa_high  csv p_value
#>    A1      A 20       18       B; C 0.90   0.699    0.972 0.85   0.000
#>    A2      A 20       15          B 0.75   0.531    0.888 0.60   0.021
#>    B1      B 20       17          A 0.85   0.640    0.948 0.75   0.001
#>    B2      B 20       13          A 0.65   0.433    0.819 0.40   0.132
#>    C1      C 20       18       A; B 0.90   0.699    0.972 0.85   0.000
#>    C2      C 20       14          B 0.70   0.481    0.855 0.50   0.058
#>  recommendation
#>          Retain
#>          Retain
#>          Retain
#>          Review
#>          Retain
#>          Review
#> 
#> 95% intervals for proportions: Wilson score (the default). Newcombe (1998)
#> compared seven methods and recommends score intervals over the Wald
#> interval. An interval reflects how few ratings an item received, not
#> whether the right judges were chosen.
#> 
#> Scale-level Colquitt benchmark summary:
#>  target n_items mean_psa psa_strength mean_csv csv_strength
#>       A       2    0.825       Strong    0.725       Strong
#>       B       2    0.750     Moderate    0.575     Moderate
#>       C       2    0.800     Moderate    0.675       Strong
#>                     benchmark_set
#>  Overall (not correlation-normed)
#>  Overall (not correlation-normed)
#>  Overall (not correlation-normed)
#> 
#> Colquitt labels are empirical percentile norms derived from scale-level averages,
#> not universal cutoffs or automatic scale-retention rules. They place a scale
#> against published scales; Psa and Csv sit on different scales, so their labels
#> are not comparable with each other.
#> 
#> What these columns mean
#>   psa -- Proportion of Substantive Agreement. Share of judges who assigned
#>       the item to the construct it was written for. Higher means judges
#>       recognized the item as belonging where you intended. (0 to 1; higher
#>       is stronger)
#>   psa_low/psa_high -- Interval for Psa. Lower and upper limits of an
#>       interval around Psa. A wide interval means few judges sorted the
#>       item, so a different sample of judges could plausibly give a quite
#>       different Psa. (between 0 and 1; the method and level are named in
#>       the output)
#>   csv -- Coefficient of Substantive Validity. How much more often the item
#>       went to its intended construct than to the alternative construct
#>       judges chose most. It rewards being distinctly right, not merely
#>       often right. (-1 to 1; 0 means the intended construct and its closest
#>       rival were chosen equally often)
#>   competitor -- Strongest competing construct. The construct, other than
#>       the intended one, that judges chose most often for this item.
#>   p_value -- Howard-Melloy exact test. Probability of seeing at least this
#>       many target assignments if judges were assigning at the chance rate
#>       p0. Small values mean the item's assignment pattern is unlikely to be
#>       chance. (0 to 1; compared against alpha)
#> 
#> What the status labels mean
#>   Supported -- The evidence met the criteria set for this analysis.
#>   Review -- Something here needs a closer look. This is not an instruction
#>       to delete anything.
#>   Insufficient data -- Too little usable data to reach a judgment.
#>   Descriptive only -- Reported for description only; no decision rule was
#>       applied.
#>   Each workflow also uses its own wording in the recommendation column
#>   (Retain, Strong support, Typical, Covered, and so on). Those words map
#>   onto the shared statuses above.
#> 
#> See `contentvalid_glossary()` for all terms, or set 
#> `options(contentvalidR.show_key = FALSE)` to hide this key.
#> 
#> 'Review' is not an automatic deletion decision. Use theory, construct-domain coverage,
#> item wording, and qualitative judge feedback alongside these statistics.
```

Working across the item table:

- **`n_target` / `n`** — how many judges put the item where you
  intended, out of how many judged it. Always read these before the
  coefficients: an impressive `psa` computed from four judges is not
  impressive.
- **`psa`** — the proportion of judges who assigned the item to its
  intended construct. It answers “did judges recognize what this item is
  about?”
- **`competitor`** — the construct judges picked most often *instead*.
  This is the single most useful diagnostic column in the table, because
  it tells you *where* a weak item drifted, which points at the fix.
- **`csv`** — how much more often the item went to its target than to
  that competitor. An item can have a decent `psa` and a poor `csv` if
  one rival construct keeps attracting it. That pattern means your two
  construct definitions overlap, which is a definitional problem rather
  than a wording problem.
- **`p_value`** — the Howard-Melloy exact test against chance
  assignment.

The scale-level table adds Colquitt strength labels. These are
**percentile positions relative to scales published in the literature**,
not absolute judgments, and they are the most frequently misreported
part of this output.

## The benchmark trap

Here is the misreading to guard against, using construct ratings:

``` r

ratings <- read.csv(
  system.file("extdata", "rating_example.csv", package = "contentvalidR"),
  stringsAsFactors = FALSE
)
fit_rating <- rating_validity(ratings)
fit_rating$scale_summary[, c("target", "mean_htc", "htc_strength",
                             "mean_htd", "htd_strength")]
#>   target  mean_htc htc_strength mean_htd htd_strength
#> 1      A 0.8333333         Weak   0.4375  Very Strong
#> 2      B 0.8333333         Weak   0.4375  Very Strong
#> 3      C 0.8333333         Weak   0.4375  Very Strong
```

An HTC of about 0.83 is labeled `Weak`, while an HTD of about 0.44 in
the same row is labeled `Very Strong`. Read as raw numbers this looks
backwards, and it is a common source of confusion.

The two indices are not on the same scale and their numbers are not
comparable:

- **HTC is an average rating** expressed as a proportion of the scale.
  Across published scales the Moderate band starts at 0.84 and Very
  Strong at 0.91, so 0.83 genuinely sits low *against that
  distribution*.
- **HTD is a difference** between the target rating and the best
  competitor’s, so it is much smaller by construction. Its Moderate band
  starts at 0.18 and Very Strong at 0.35, so 0.44 genuinely sits high.

Compare each index against its own benchmark. Never compare an HTC
number with an HTD number, and never treat a benchmark label as a cutoff
for retention.

``` r

colquitt_benchmarks("htc")
#>   statistic benchmark_set                  benchmark_label interpretation
#> 1       htc       overall Overall (not correlation-normed)    Very Strong
#> 2       htc       overall Overall (not correlation-normed)         Strong
#> 3       htc       overall Overall (not correlation-normed)       Moderate
#> 4       htc       overall Overall (not correlation-normed)           Weak
#> 5       htc       overall Overall (not correlation-normed)        Lack of
#>   percentile minimum
#> 1  80th-99th    0.91
#> 2  60th-79th    0.87
#> 3  40th-59th    0.84
#> 4  20th-39th    0.60
#> 5   0th-19th    -Inf
colquitt_benchmarks("htd")
#>   statistic benchmark_set                  benchmark_label interpretation
#> 1       htd       overall Overall (not correlation-normed)    Very Strong
#> 2       htd       overall Overall (not correlation-normed)         Strong
#> 3       htd       overall Overall (not correlation-normed)       Moderate
#> 4       htd       overall Overall (not correlation-normed)           Weak
#> 5       htd       overall Overall (not correlation-normed)        Lack of
#>   percentile minimum
#> 1  80th-99th    0.35
#> 2  60th-79th    0.27
#> 3  40th-59th    0.18
#> 4  20th-39th    0.04
#> 5   0th-19th    -Inf
```

## Reading expert-panel evidence

``` r

relevance <- read.csv(
  system.file("extdata", "expert_relevance_example.csv", package = "contentvalidR"),
  stringsAsFactors = FALSE
)
panel <- as.matrix(relevance[, setdiff(names(relevance), "expert")])
fit_expert <- expert_validity(panel, mode = "relevance", lo = 1, hi = 4)
fit_expert$results[, c("item", "N", "V", "I_CVI", "I_CVI_low", "I_CVI_high",
                       "kappa_mod", "recommendation")]
#>    item N         V I_CVI  I_CVI_low I_CVI_high kappa_mod recommendation
#> 1 Item1 8 1.0000000  1.00 0.67559244  1.0000000 1.0000000 Strong support
#> 2 Item2 8 0.9166667  1.00 0.67559244  1.0000000 1.0000000 Strong support
#> 3 Item3 8 0.8333333  1.00 0.67559244  1.0000000 1.0000000 Strong support
#> 4 Item4 8 0.5833333  0.75 0.40927543  0.9285208 0.7192982         Review
#> 5 Item5 8 0.4166667  0.25 0.07147921  0.5907246 0.1578947         Review
```

`I_CVI` is the proportion of experts calling the item relevant.
`kappa_mod` corrects that for chance agreement, and the gap between them
matters most with small panels, where several experts can agree by luck
alone. Aiken’s `V` uses the whole rating scale rather than a relevance
cut, so it distinguishes items that `I_CVI` rates identically.

Note that the I-CVI criterion depends on panel size. It follows Lynn
(1986): with three to five experts all must agree, from six one may
disagree, and from nine two may. `cvi_criterion` shows the proportion
that applies to each item’s panel, so 7 of 9 appears as .778. An item
can therefore change status simply because a judge was added or dropped.

### Reading the intervals

`I_CVI_low` and `I_CVI_high` bound the I-CVI. With eight experts, an
item that every expert rated relevant still has a lower limit well below
1: a panel that size cannot rule out a noticeably lower relevance rate.
Read the interval before treating an I-CVI as settled, and report it
alongside the point estimate.

The interval method is a choice. The Wilson score interval is the
default, following Newcombe (1998), and alternatives are available when
a study needs to match earlier work:

``` r

exact <- expert_validity(panel, mode = "relevance", lo = 1, hi = 4,
                         proportion_ci = "exact")
exact$results[, c("item", "I_CVI", "I_CVI_low", "I_CVI_high")]
#>    item I_CVI  I_CVI_low I_CVI_high
#> 1 Item1  1.00 0.63058335  1.0000000
#> 2 Item2  1.00 0.63058335  1.0000000
#> 3 Item3  1.00 0.63058335  1.0000000
#> 4 Item4  0.75 0.34914421  0.9681460
#> 5 Item5  0.25 0.03185403  0.6508558
```

The exact (Clopper-Pearson) interval is conservative, so its limits sit
further apart. The printed output always names the method that produced
the interval.

### Reading panel agreement

Relevance mode also reports one agreement coefficient for the whole
panel, in `scale_summary` as `agreement`, `agreement_low`, and
`agreement_high`. The full result, with its explanation, is in
`details$agreement`, and
[`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
produces the same result directly:

``` r

panel_agreement(panel, seed = 1)
#> Panel-level agreement
#> Items rated by two or more raters: 5   Raters: 8
#> Krippendorff's alpha (ordinal): 0.693   95% interval: 0.071 to 0.86
#> Identical rating pairs: 62.9%
#> 
#> Alpha compares the disagreement observed within items with the disagreement
#> expected if these same ratings were assigned to items at random: 1 means
#> perfect agreement and 0 means agreement no better than chance. Alpha falls
#> when ratings cluster on a few values, because little disagreement is then
#> expected by chance. A high share of identical rating pairs alongside a low
#> alpha reflects that clustering, which is common when nearly every item is
#> rated relevant, and is not by itself evidence of a poor panel.
#> 
#> Krippendorff's alpha is the default because it handles ordinal ratings and
#> missing ratings (Zapf et al., 2016). It is a general reliability
#> coefficient; no publication applying it specifically to content-validity
#> panels was found.
#> 
#> The interval resamples items with all of their ratings, following Zapf et
#> al. (2016), and varies slightly between runs unless `seed` is set.
#> 
#> Panel agreement describes how consistently raters rated these items. 
#> It does not show that the items are relevant or that the domain is covered.
```

Read two numbers together: the coefficient and the share of identical
rating pairs. Krippendorff’s alpha, the default, can be low on a panel
that agrees closely when nearly every rating is the same value, because
chance then predicts very little disagreement. A low alpha next to a
high share of identical pairs reflects that clustering. Agreement
describes the raters, not the items: a consistent panel can still
consistently rate an item as irrelevant.

## Reading judge heterogeneity

[`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
asks a different question: do your conclusions depend on *these
particular judges*?

``` r

judge_ratings <- rbind(
  c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
  c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(4, 3, 4, 3, 1, 2),
  c(4, 4, 3, 4, 2, 2), c(2, 2, 2, 2, 1, 1)
)
dimnames(judge_ratings) <- list(paste0("Judge", 1:8), paste0("Item", 1:6))
fit_judge <- judge_validity(judge_ratings, lo = 1, hi = 4)
fit_judge$results[, c("judge", "mean_rating", "severity_raw",
                      "differentiation", "n_items_flipped", "recommendation")]
#>    judge mean_rating severity_raw differentiation n_items_flipped
#> 1 Judge1    3.166667   -0.2708333       0.9136465               0
#> 2 Judge2    3.000000   -0.1041667       1.1754383               0
#> 3 Judge3    3.000000   -0.1041667       1.1754383               0
#> 4 Judge4    3.166667   -0.2708333       0.9136465               0
#> 5 Judge5    3.166667   -0.2708333       1.2351428               0
#> 6 Judge6    2.833333    0.0625000       1.0863535               0
#> 7 Judge7    3.166667   -0.2708333       0.9136465               0
#> 8 Judge8    1.666667    1.2291667       0.4798707               0
#>   recommendation
#> 1        Typical
#> 2        Typical
#> 3        Typical
#> 4        Typical
#> 5        Typical
#> 6        Typical
#> 7        Typical
#> 8         Severe
```

`severity_raw` is signed so that **positive means harsher**: the judge
rates lower than the panel. `differentiation` near 1 means the judge
used the scale about as widely as everyone else. `n_items_flipped` is
the influence diagnostic: how many items would change review status if
this judge were removed.

A judge flagged here is not a judge to delete. A dissenting expert may
be the one reading the construct definition correctly. The flag tells
you a conclusion rests on one person’s ratings, which is worth knowing
before you write it up.

The panel-level dependability coefficient answers a planning question:

``` r

summary(fit_judge)$gtheory$judges_needed
#>   target n_judges_relative n_judges_absolute
#> 1    0.7                 1                 2
#> 2    0.8                 2                 2
#> 3    0.9                 3                 5
```

That table reports how many judges a target coefficient would need.
Where it returns `NA`, no realistic panel reaches that target, which
usually means the judges barely distinguished the items.

## Reading domain coverage

``` r

assignments <- data.frame(
  item = paste0("I", 1:7),
  construct = c("Autonomy", "Autonomy", "Autonomy", "Autonomy",
                "Competence", "Competence", "Relatedness"),
  stringsAsFactors = FALSE
)
fit_domain <- domain_validity(
  assignments,
  cell_col = "construct",
  domain = c("Autonomy", "Competence", "Relatedness", "Belonging")
)
fit_domain$results[, c("cell", "n_items", "share", "recommendation")]
#>          cell n_items     share   recommendation
#> 1    Autonomy       4 0.5714286 Over-represented
#> 2  Competence       2 0.2857143          Covered
#> 3 Relatedness       1 0.1428571   Thinly covered
#> 4   Belonging       0 0.0000000      Not covered
```

The `Belonging` row is the point of this analysis. No item addresses
that cell, and **no item-level index could ever have told you**, because
relevance statistics can only describe items that exist. A perfect I-CVI
on every item you wrote says nothing about the facet you forgot.

This only works because the full cell list was supplied through
`domain`. Omit it and the analysis can only describe the cells that
already contain items, and the output says so rather than implying
complete coverage.

## Common misreadings

**“Review means delete.”** It does not. It means look closer. Deleting
every flagged item optimizes a statistic at the cost of the content
domain, which is the opposite of content validity.

**“Strong means good.”** Benchmark labels are percentile positions
against published scales. `Strong` means typical of published work, not
that the item is fit for your purpose.

**“One index is enough.”** No single coefficient establishes content
validity. These are components of an argument that also rests on
construct definitions, domain coverage, cognitive interviewing, and
expert comment.

**“The numbers are comparable.”** HTC against HTD, Psa against Csv, or
one index against the benchmark belonging to a different index: these
comparisons are not meaningful.

**“A high coefficient means the domain is covered.”** Relevance and
coverage are different questions. Only
[`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md)
addresses coverage, and only when you give it the full blueprint.

**“More judges always helps.”** More judges narrows intervals, but it
can also change a criterion: the I-CVI guideline shifts at six experts.
Check `judges_needed` rather than assuming.

## Writing it up

A defensible sentence reports the estimate, its precision, the decision
rule you applied, and what you concluded, without implying the statistic
made the decision:

> Six items were sorted by 20 naive judges. Four items met the
> Howard-Melloy exact target-assignment criterion (*p* \< .05). Items B2
> and C2 did not (*psa* = .65 and .70), and in both cases the competing
> construct was the adjacent scale. Rather than removing them, we
> revised their wording to sharpen the distinction from that scale and
> re-sorted.

Report what you cannot establish as well:

> These analyses address definitional correspondence and
> distinctiveness. They do not establish that the item set covers the
> construct domain; coverage was assessed separately against the
> blueprint.

`settings` and `design` hold everything a reader needs to reproduce the
decision rules, so report them rather than only the coefficients:

``` r

fit_sort$settings[c("p0", "alpha", "judge_type")]
#> $p0
#> [1] 0.5
#> 
#> $alpha
#> [1] 0.05
#> 
#> $judge_type
#> [1] "naive"
```

## Turning off the inline key

Printed output includes a key defining each column. Once the terms are
familiar:

``` r

options(contentvalidR.show_key = FALSE)
```

The definitions remain available at any time:

``` r

contentvalid_glossary("expert-panel")
```

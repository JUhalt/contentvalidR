# Expert-Panel Content Validation: Relevance, Essentiality, and Congruence

## Why expert-panel methods need separate modes

Expert-panel content validation is not one statistical task. A relevance
rating, an essential/not-essential judgment, and an item-objective
congruence judgment ask experts different questions and therefore
support different indices.
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
uses an explicit `mode` so those designs are not treated as
interchangeable.

The three modes are:

- **relevance**: Aiken’s V plus CVI and modified kappa, with a
  panel-level agreement coefficient;
- **essentiality**: Lawshe’s CVR with exact binomial inference; and
- **congruence**: Rovinelli-Hambleton IOC.

All three are quantitative complements to qualitative expert comments,
construct coverage, comprehensibility review, and other parts of the
content-validity argument.

## Relevance: Aiken V, score intervals, and CVI

Suppose six experts rate item relevance from 1 (not relevant) to 4
(highly relevant):

``` r

R <- matrix(
  c(4,4,4,4,4,4,
    4,4,4,3,4,4,
    4,3,4,4,3,4,
    3,3,4,3,2,3),
  nrow = 6,
  dimnames = list(NULL, paste0("Item", 1:4))
)

fit <- expert_validity(R, mode = "relevance", lo = 1, hi = 4, seed = 1)
fit
#> contentvalidR expert-panel analysis
#> -----------------------------------
#> Mode: relevance
#> Items: 4 | Experts/item: 6
#> Mean Aiken V: .88 | S-CVI/Ave: .96 | S-CVI/UA: .75
#> Strong support: 4 | Support: 0 | Review: 0
#> Panel agreement, Krippendorff's alpha (ordinal): .37, 95% CI [-.12, .63].
#>   Identical rating pairs: 63.3%.
#> 
#>   item       decision N    V      95% CI I-CVI      95% CI kappa
#>  Item1 Strong support 6 1.00 [.82, 1.00]  1.00 [.61, 1.00]  1.00
#>  Item2 Strong support 6  .94  [.74, .99]  1.00 [.61, 1.00]  1.00
#>  Item3 Strong support 6  .89  [.67, .97]  1.00 [.61, 1.00]  1.00
#>  Item4 Strong support 6  .67  [.44, .84]   .83  [.44, .97]   .82
#> 
#> Each 95% CI follows its estimate: Aiken's V has a Penfield-Giacobbi score
#> interval, and I-CVI the proportion interval named below.
#> I-CVI criterion for 6 experts: 5 agreeing (.83), following Lynn (1986); kappa
#> is modified kappa, with values above .74 read as excellent (Polit, Beck, &
#> Owen, 2007).
#> 95% intervals for proportions: Wilson score (the default). Newcombe (1998)
#> compared seven methods and recommends score intervals over the Wald interval.
#> An interval reflects how few ratings an item received, not whether the right
#> judges were chosen.
#> 
#> Panel agreement is one coefficient for the whole panel, whereas modified
#> kappa (the kappa column) describes each item. Alpha can be low when nearly
#> every rating is the same value, even on a panel that agrees closely, so read
#> it beside the share of identical rating pairs. A low alpha with many
#> identical pairs is not by itself evidence of a poor panel. Print
#> `details$agreement` for the full explanation and interval details.
#> 
#> CVI criteria are published panel-size guidelines, not universal validity
#> cutoffs.
#> 
#> What these columns mean
#>   V -- Aiken's V. Relevance index that rescales the experts' average rating
#>       to run from 0 to 1 given the bounds of the rating scale used. (0 to
#>       1; higher is stronger)
#>   I-CVI -- Item-level Content Validity Index. Proportion of experts who
#>       rated the item as relevant, after applying the relevance cut. (0 to
#>       1; compared against a panel-size guideline)
#>   95% CI after I-CVI -- Interval for I-CVI. Lower and upper limits of an
#>       interval around I-CVI. Expert panels are usually small, so these
#>       intervals are often wide: a single I-CVI value can look more settled
#>       than the number of experts behind it supports. (between 0 and 1; the
#>       method and level are named in the output)
#>   kappa -- Modified kappa. I-CVI adjusted for the chance that experts would
#>       have agreed even if rating at random. With small panels, chance
#>       agreement is substantial, which is why the raw I-CVI alone can
#>       overstate consensus. (0 to 1; higher is stronger)
#>   Panel agreement -- Panel-level agreement. One coefficient describing how
#>       consistently the whole panel rated the item set: Krippendorff's alpha
#>       by default, or Gwet's AC1 if chosen. It is separate from modified
#>       kappa, which describes one item at a time. (1 is perfect agreement
#>       and 0 is agreement no better than chance; it can be low on a
#>       close-agreeing panel whose ratings cluster on one value)
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
#> Use quantitative indices alongside expert comments, construct coverage, and
#> comprehensibility review.
summary(fit)
#> Summary: expert-panel content-validity evidence
#> -----------------------------------------------
#> Mode: relevance
#> Supported: 4 | Review: 0
#> Panel agreement, Krippendorff's alpha (ordinal): .37, 95% CI [-.12, .63].
#>   Identical rating pairs: 63.3%.
#> 
#> No items were flagged by the workflow's quantitative review rules.
#> 
#> These summaries support, but do not replace, qualitative content review.
```

Aiken’s V rescales the bounded expert ratings to the 0-1 interval. The
default confidence interval is the score interval proposed by Penfield
and Giacobbi (2004), rather than a simulation-dependent bootstrap
interval. Bootstrap intervals remain available through the low-level
function:

``` r

aikens_v(R, lo = 1, hi = 4, ci = "bootstrap", B = 200, seed = 1)
#>    item N n_missing         V    ci_low   ci_high            ci_method
#> 1 Item1 6         0 1.0000000 1.0000000 1.0000000 percentile bootstrap
#> 2 Item2 6         0 0.9444444 0.8333333 1.0000000 percentile bootstrap
#> 3 Item3 6         0 0.8888889 0.7763889 1.0000000 percentile bootstrap
#> 4 Item4 6         0 0.6666667 0.5000000 0.8333333 percentile bootstrap
```

For CVI, the workflow dichotomizes ratings at `relevance_cut`. On a 1-4
scale the default is 3, so ratings of 3 or 4 count as relevant. Declare
a different threshold if the study protocol used one.

The workflow reports Lynn’s (1986) panel-size criterion for the I-CVI as
a **review aid**: with three to five experts all must agree, from six
one may disagree, and from nine two may (7 of 9, the .78 usually
quoted). Lynn’s table stops at ten experts; beyond that the package
holds her lowest proportion, 7 of 9. The criterion is not presented as
universal proof that an item is or is not content valid. Modified kappa
provides a chance-corrected complement to I-CVI.

At the scale level, S-CVI/Ave and S-CVI/UA are reported together.
S-CVI/Ave is generally less brittle than universal agreement, but both
should be interpreted alongside the distribution of item-level evidence.

## Panel-level agreement

I-CVI and modified kappa describe one item at a time. Relevance mode
also reports how consistently the panel rated the whole item set, as one
coefficient with a bootstrap interval:

``` r

fit$scale_summary[, c("agreement", "agreement_low", "agreement_high")]
#>   agreement agreement_low agreement_high
#> 1 0.3743873    -0.1210084      0.6340909
fit$details$agreement
#> contentvalidR panel agreement
#> -----------------------------
#> Items rated by two or more raters: 4 | Raters: 6
#> Krippendorff's alpha (ordinal) = .37, 95% CI [-.12, .63]
#> Identical rating pairs: 63.3%
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
#> missing ratings (Zapf et al., 2016). It is a general reliability coefficient;
#> no publication applying it specifically to content-validity panels was found.
#> 
#> The interval resamples items with all of their ratings, following Zapf et al.
#> (2016), and varies slightly between runs unless `seed` is set. In 5 of 1000
#> resamples the coefficient could not be computed, usually because every
#> resampled rating was identical; the interval uses the rest. With few items
#> this interval is imprecise and can be misleading.
#> 
#> Panel agreement describes how consistently raters rated these items. It does
#> not show that the items are relevant or that the domain is covered.
```

The default coefficient is Krippendorff’s alpha. It accepts any number
of experts and missing ratings, and Zapf et al. (2016) recommend it when
ratings are ordinal or incomplete, which describes most expert panels.
It is a general reliability coefficient (Hayes & Krippendorff, 2007)
rather than one developed for content validity; no publication applying
it specifically to content-validity panels was found.

Choose the measurement level that matches the rating scale. Relevance
ratings are treated as ordinal by default.
`agreement_level = "interval"` treats the distances between scale points
as equal, and `"nominal"` treats every disagreement as equally serious:

``` r

expert_validity(R, mode = "relevance", lo = 1, hi = 4,
                agreement_level = "interval", agreement_B = 0)$scale_summary$agreement
#> [1] 0.3715847
```

### Why alpha can be low when experts agree

Alpha compares the disagreement within items with the disagreement
expected if the same ratings were scattered across items at random. When
a panel rates nearly every item 4, very little disagreement is expected
by chance, so a few 3s pull alpha down even though most rating pairs are
identical. Feinstein and Cicchetti (1990) described the same pattern for
kappa. The output reports the share of identical rating pairs next to
alpha so the two can be read together. A low alpha alongside a high
share of identical pairs is not by itself evidence of a poor panel.

### Gwet’s AC1

Gwet’s (2008) AC1 was designed to stay high in that situation, and it is
available with `agreement = "ac1"`. It is never the default. Vach and
Gerke (2023) show that AC1 rises as ratings concentrate in one category
even when agreement does not change, and that it can be above zero when
experts rate independently. Its output always repeats that critique. In
relevance mode, AC1 is computed on the relevant/not-relevant decision at
`relevance_cut`:

``` r

ac1_fit <- expert_validity(R, mode = "relevance", lo = 1, hi = 4,
                           agreement = "ac1", agreement_B = 0)
ac1_fit$details$agreement
#> contentvalidR panel agreement
#> -----------------------------
#> Items rated by two or more raters: 4 | Raters: 6
#> Gwet's AC1 = .91
#> Identical rating pairs: 91.7%
#> 
#> AC1 compares observed agreement with the agreement expected by chance,
#> estimated so that it stays high when nearly every rating falls in one
#> category (Gwet, 2008).
#> 
#> Gwet's AC1 is available but is not the default. Vach and Gerke (2023) show
#> that it rises as ratings concentrate in one category even when agreement is
#> unchanged, that it can be non-zero when raters are independent, and that
#> benchmark labels developed for kappa, such as Landis and Koch's, must not be
#> applied to it.
#> 
#> Panel agreement describes how consistently raters rated these items. It does
#> not show that the items are relevant or that the domain is covered.
```

### The interval

The interval resamples items with all of their ratings intact, the
procedure Zapf et al. (2016) evaluated; they found that Krippendorff’s
original bootstrap, which ignores dependence between raters, reached
only about 60% coverage. The interval varies slightly between runs, so
set `seed` to make it reproducible, or set `agreement_B = 0` to skip it.
[`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
runs the same analysis on any rater-by-item matrix.

## Essentiality: Lawshe CVR with exact critical values

Lawshe’s task asks experts whether an item is essential. With twelve
experts:

``` r

expert_validity(c(10, 8, 6), mode = "essentiality", N = 12)
#> contentvalidR expert-panel analysis
#> -----------------------------------
#> Mode: essentiality
#> Items: 3 | Experts/item: 12
#> Method: Lawshe CVR with exact binomial critical values
#> 
#>   item  decision essential CVR    p
#>  Item1 Supported     10/12 .67 .019
#>  Item2    Review      8/12 .33 .194
#>  Item3    Review      6/12 .00 .613
#> 
#> essential: experts rating the item essential, out of those who rated it.
#> With 12 experts, an item needs at least 10 rating it essential for the exact
#> one-tailed binomial test at alpha = .05 (Ayre & Scally, 2014).
#> 
#> What these columns mean
#>   CVR -- Lawshe's Content Validity Ratio. How far the panel leans toward
#>       calling the item essential rather than merely useful. (-1 to 1; above
#>       0 means more than half the panel called it essential)
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
#> Use quantitative indices alongside expert comments, construct coverage, and
#> comprehensibility review.
```

[`cvr()`](https://juhalt.github.io/contentvalidR/reference/cvr.md)
derives the smallest essential count whose one-sided binomial upper-tail
probability is no greater than `alpha`. This makes the panel-size
dependency explicit and follows the exact-probability logic revisited by
Ayre and Scally (2014).

Judge-by-item binary data can be supplied directly:

``` r

E <- cbind(
  Item1 = c(1,1,1,1,1,1,1,1),
  Item2 = c(1,1,1,1,1,0,0,0)
)
expert_validity(E, mode = "essentiality")
#> contentvalidR expert-panel analysis
#> -----------------------------------
#> Mode: essentiality
#> Items: 2 | Experts/item: 8
#> Method: Lawshe CVR with exact binomial critical values
#> 
#>   item  decision essential  CVR    p
#>  Item1 Supported       8/8 1.00 .004
#>  Item2    Review       5/8  .25 .363
#> 
#> essential: experts rating the item essential, out of those who rated it.
#> With 8 experts, an item needs at least 7 rating it essential for the exact
#> one-tailed binomial test at alpha = .05 (Ayre & Scally, 2014).
#> 
#> What these columns mean
#>   CVR -- Lawshe's Content Validity Ratio. How far the panel leans toward
#>       calling the item essential rather than merely useful. (-1 to 1; above
#>       0 means more than half the panel called it essential)
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
#> Use quantitative indices alongside expert comments, construct coverage, and
#> comprehensibility review.
```

A failure to clear the exact criterion is labeled `Review`, not
automatic deletion. Expert rationales and domain coverage matter when
deciding whether an item should be rewritten, retained for breadth, or
removed.

### Lawshe’s table and its recalculation, for comparison

Lawshe (1975) published a table of minimum CVR values, and Wilson, Pan
and Schumsky (2012) recalculated it. `legacy = TRUE` prints both beside
the exact decision, without changing it:

``` r

old <- options(contentvalidR.show_key = FALSE)
expert_validity(c(9, 8, 7), mode = "essentiality", N = 9, legacy = TRUE)
#> contentvalidR expert-panel analysis
#> -----------------------------------
#> Mode: essentiality
#> Items: 3 | Experts/item: 9
#> Method: Lawshe CVR with exact binomial critical values
#> 
#>   item  decision essential  CVR    p
#>  Item1 Supported       9/9 1.00 .002
#>  Item2 Supported       8/9  .78 .020
#>  Item3    Review       7/9  .56 .090
#> 
#> essential: experts rating the item essential, out of those who rated it.
#> With 9 experts, an item needs at least 8 rating it essential for the exact
#> one-tailed binomial test at alpha = .05 (Ayre & Scally, 2014).
#> 
#> Earlier methods, for comparison (not used for the decision)
#>   item  decision essential  CVR Lawshe (1975) Wilson et al. (2012)
#>  Item1 Supported       9/9 1.00         meets                meets
#>  Item2 Supported       8/9  .78         below                meets
#>  Item3    Review       7/9  .56         below                meets
#> 
#> Lawshe (1975, Table 1): minimum CVR .78 for 9 panelists, labeled a one-tailed
#> test at .05. Wilson, Pan and Schumsky (2012) found the table closer to a
#> two-tailed test.
#> Wilson et al. (2012, Table 2): minimum CVR .55, the normal approximation
#> z/sqrt(N) at one-tailed alpha = .05.
#> Item2 (.778) prints at the Lawshe cutoff of .78 but falls short of it before
#> rounding.
#> The decision above uses the exact binomial test (Ayre & Scally, 2014).
#> Lawshe's content validity index, the mean CVR of the items his table retains:
#> 1.00 (1 item).
#> 
#> Use quantitative indices alongside expert comments, construct coverage, and
#> comprehensibility review.
options(old)
```

Nine experts show why the table was questioned. Eight of nine gives a
CVR of .778, just under Lawshe’s .78, so his table asks for all nine,
while with eight experts it accepts seven. Wilson et al. describe the
anomaly: the minimum rises steadily from 40 experts down to nine, then
drops at eight. The exact test needs eight of nine.

In relevance mode, `legacy = TRUE` adds Fleiss’ (1971) kappa on the
relevant/not-relevant decision and the Polit and Beck (2006) benchmarks
for S-CVI/Ave and S-CVI/UA. It also adds the content validity
coefficient (Ccv) of Hernández-Nieto (2002), which is widely cited,
beside Aiken’s V. Read it as a cautionary example rather than evidence.
Ccv is the mean rating divided by the scale maximum, minus a “chance”
term, (1/J)^J, that depends only on the number of judges and is .00032
for five of them. So on a scale starting at 0 it is Aiken’s V, and on a
scale starting at 1 it cannot fall below one over the scale maximum. It
uses only the mean, so despite the book’s claim it cannot reflect
agreement: in the book’s own Table 7, ratings of 1, 3, 4, 5, 2 and of 3,
3, 3, 3, 3 both score .60. Its .80 cutoff is stated without derivation,
and the book’s own examples do not keep to it.
[`?expert_validity`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
sets out each of these with page references.

## Congruence: item-objective alignment

IOC uses expert ratings of -1, 0, and +1 for item-objective congruence.
A target mapping lets the workflow compare intended and competing
objectives:

``` r

d <- expand.grid(
  item = c("I1", "I2"),
  judge = 1:4,
  objective = c("A", "B")
)
d$target_objective <- ifelse(d$item == "I1", "A", "B")
d$score <- ifelse(d$objective == d$target_objective, 1, -1)

expert_validity(d, mode = "congruence")
#> contentvalidR expert-panel analysis
#> -----------------------------------
#> Mode: congruence
#> Items: 2 | Experts/cell: 4 | Objectives: 2
#> Method: Rovinelli-Hambleton item-objective congruence
#> 
#>  item target       decision target IOC competitor competitor IOC margin
#>    I1      A Target favored       1.00          B          -1.00   2.00
#>    I2      B Target favored       1.00          A          -1.00   2.00
#> 
#> I1, I2: The intended objective has the highest IOC; use the margin and expert
#>   comments to judge practical distinctiveness.
#> 
#> What these columns mean
#>   IOC -- Item-Objective Congruence. How consistently experts linked the
#>       item to the objective it was written for rather than to another
#>       objective. (-1 to 1; higher is stronger)
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
#> Use quantitative indices alongside expert comments, construct coverage, and
#> comprehensibility review.
```

The workflow reports target IOC, the strongest competitor, and their
margin. This is a diagnostic comparison, not a manufactured significance
test. If no target mapping is provided, all IOC cells are returned
descriptively.

## Missing ratings

Missing data are never silently ignored by default. Set `na.rm = TRUE`
only when itemwise/cellwise deletion matches the study protocol.
Effective expert counts and missing counts are then reported so
downstream interpretation uses the actual panel size.

## Plotting expert evidence

Each mode uses a plot matched to the expert task rather than forcing
unlike indices into one generic chart.

``` r

plot(expert_validity(R, mode = "relevance", lo = 1, hi = 4))
```

![](expert-panel-validity_files/figure-html/expert-plots-1.png)

``` r

plot(expert_validity(c(10, 8, 6), mode = "essentiality", N = 12))
```

![](expert-panel-validity_files/figure-html/expert-plots-2.png)

``` r

plot(expert_validity(d, mode = "congruence"))
```

![](expert-panel-validity_files/figure-html/expert-plots-3.png)

Relevance mode displays Aiken’s V with its score interval and overlays
I-CVI as a separate marker. Essentiality mode displays observed CVR
against the exact panel-specific critical CVR. Congruence mode connects
target IOC to the strongest competitor so the alignment margin is
visually explicit. These displays are diagnostic summaries; they do not
create new validity thresholds.

## Reporting

A concise methods/results description should identify:

1.  who the experts were and why they were qualified;
2.  the exact task and response scale;
3.  the index and inference/CI procedure used, and for relevance ratings
    the agreement coefficient and its measurement level;
4.  the panel size, including item-specific missingness;
5.  quantitative item and scale evidence; and
6.  how expert comments, construct coverage, and comprehensibility
    informed the final item decisions.

A content-validity coefficient is evidence about a defined expert task.
It is not, by itself, a complete validity argument.

## References

Aiken, L. R. (1980). Content validity and reliability of single items or
questionnaires. *Educational and Psychological Measurement, 40*(4),
955-959. <https://doi.org/10.1177/001316448004000419>

Lawshe, C. H. (1975). A quantitative approach to content validity.
*Personnel Psychology, 28*(4), 563-575.
<https://doi.org/10.1111/j.1744-6570.1975.tb01393.x>

Ayre, C., & Scally, A. J. (2014). Critical values for Lawshe’s content
validity ratio: Revisiting the original methods of calculation.
*Measurement and Evaluation in Counseling and Development, 47*(1),
79-86. <https://doi.org/10.1177/0748175613513808>

Feinstein, A. R., & Cicchetti, D. V. (1990). High agreement but low
kappa: I. The problems of two paradoxes. *Journal of Clinical
Epidemiology, 43*(6), 543-549.
<https://doi.org/10.1016/0895-4356(90)90158-L>

Fleiss, J. L. (1971). Measuring nominal scale agreement among many
raters. *Psychological Bulletin, 76*(5), 378-382.
<https://doi.org/10.1037/h0031619>

Gwet, K. L. (2008). Computing inter-rater reliability and its variance
in the presence of high agreement. *British Journal of Mathematical and
Statistical Psychology, 61*(1), 29-48.
<https://doi.org/10.1348/000711006X126600>

Hayes, A. F., & Krippendorff, K. (2007). Answering the call for a
standard reliability measure for coding data. *Communication Methods and
Measures, 1*(1), 77-89. <https://doi.org/10.1080/19312450709336664>

Hernández-Nieto, R. (2002). *Contributions to statistical analysis: The
coefficients of proportional variance, content validity and kappa.*
Universidad de Los Andes.

Krippendorff, K. (2011). *Computing Krippendorff’s alpha-reliability.*
Annenberg School for Communication, University of Pennsylvania.

Lynn, M. R. (1986). Determination and quantification of content
validity. *Nursing Research, 35*(6), 382-385.
<https://doi.org/10.1097/00006199-198611000-00017>

Penfield, R. D., & Giacobbi, P. R., Jr. (2004). Applying a score
confidence interval to Aiken’s item content-relevance index.
*Measurement in Physical Education and Exercise Science, 8*(4), 213-225.
<https://doi.org/10.1207/S15327841MPEE0804_3>

Polit, D. F., & Beck, C. T. (2006). The content validity index: Are you
sure you know what’s being reported? Critique and recommendations.
*Research in Nursing & Health, 29*(5), 489-497.
<https://doi.org/10.1002/nur.20147>

Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an
acceptable indicator of content validity? Appraisal and recommendations.
*Research in Nursing & Health, 30*(4), 459-467.
<https://doi.org/10.1002/nur.20199>

Rovinelli, R. J., & Hambleton, R. K. (1977). On the use of content
specialists in the assessment of criterion-referenced test item
validity. *Dutch Journal of Educational Research, 2*, 49-60.

Turner, R. C., & Carlson, L. (2003). Indexes of item-objective
congruence for multidimensional items. *International Journal of
Testing, 3*(2), 163-171. <https://doi.org/10.1207/S15327574IJT0302_5>

Vach, W., & Gerke, O. (2023). Gwet’s AC1 is not a substitute for Cohen’s
kappa: A comparison of basic properties. *MethodsX, 10*, 102212.

Wilson, F. R., Pan, W., & Schumsky, D. A. (2012). Recalculation of the
critical values for Lawshe’s content validity ratio. *Measurement and
Evaluation in Counseling and Development, 45*(3), 197-210.
<https://doi.org/10.1177/0748175612440286>

Zapf, A., Castell, S., Morawietz, L., & Karch, A. (2016). Measuring
inter-rater reliability for nominal data: Which coefficients and
confidence intervals are appropriate? *BMC Medical Research Methodology,
16*, 93. <https://doi.org/10.1186/s12874-016-0200-9>

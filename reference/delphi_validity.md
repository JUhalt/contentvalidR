# Delphi consensus and stability across rounds

Analyzes an expert panel rated over successive Delphi rounds. For each
item it reports consensus in every round and the stability of experts'
ratings between consecutive rounds, and it fits
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
to each round so the usual relevance evidence is available round by
round.

Consensus and stability are different questions. Consensus asks whether
enough experts agree now. Stability asks whether experts are still
changing their answers. A Delphi can reach one without the other, so
both are shown.

## Usage

``` r
delphi_validity(
  ratings,
  expert_col = "expert",
  item_col = "item",
  round_col = "round",
  rating_col = "rating",
  lo,
  hi,
  agree_cut = NULL,
  consensus_threshold = NULL,
  stability = c("kappa", "lambda", "chisq_individual", "chisq_group", "percent_change"),
  kappa_weights = c("quadratic", "linear"),
  alpha = 0.05,
  B = 1000,
  seed = NULL
)
```

## Arguments

- ratings:

  A data frame with one row per expert, item, and round. Rows with a
  missing rating are ignored.

- expert_col, item_col, rating_col:

  Column names in `ratings`.

- round_col:

  Name of the round column. Rounds may be numbers, a factor, or text
  labels that carry a number; see *Round order* in Details.

- lo, hi:

  Lowest and highest points of the rating scale, as whole numbers.

- agree_cut:

  Rating at or above which an expert counts as agreeing. Defaults to
  `hi - 1`, the usual relevance cut on a 4-point scale, and to `hi` on a
  two-point scale. It must lie above `lo`: at `lo` every rating would
  count as agreement.

- consensus_threshold:

  Share of experts that must agree for consensus, between 0 and 1. Fix
  it before the study (Diamond et al., 2014). `NULL` (default) reports
  agreement descriptively.

- stability:

  Stability statistic; see Details.

- kappa_weights:

  `"quadratic"` (default) or `"linear"`, used when
  `stability = "kappa"`.

- alpha:

  Significance level for the chi-square methods, and `1 - alpha` is the
  interval level.

- B:

  Bootstrap resamples for the kappa interval. Use `0` to skip it.

- seed:

  Optional seed for the bootstrap. Every item and pair of rounds is
  resampled from this same seed, so pairs with the same number of paired
  experts draw the same resample indices, and their intervals are not
  independent of one another. The random-number stream of the session is
  left as it was.

## Value

An object of class `contentvalid_delphi` and `contentvalid_workflow`.
`details` holds `consensus` (every item and round), `stability` (every
item and pair of rounds, including `n_paired`, `min_expected` for the
chi-square methods, `n_boot_usable` for the kappa interval, and a `note`
where a statistic is undefined or unreliable), `panel` (experts per
round), and `round_fits`, the
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
fit for each round.

**Results columns.** `results` has one row per item. Consensus is read
in the item's last round, and stability in its last pair of consecutive
rounds:

- `item`:

  The item.

- `n_rounds`:

  Rounds in which the item was rated.

- `last_round`:

  The last of them.

- `n_experts`:

  Experts who rated the item in its last round.

- `prop_agree`:

  The share of them rating it `agree_cut` or higher.

- `consensus`:

  Whether `prop_agree` meets `consensus_threshold`; `NA` when no
  threshold was set.

- `prop_unchanged`:

  The share of experts who kept their rating between the two rounds of
  the last pair, among those who rated the item in both (`n_paired` in
  `details$stability`); `NA` when no expert's ratings could be paired.

- `stability`:

  The statistic chosen in `stability` for that pair: weighted kappa,
  lambda, a chi-square, or the net change.

- `stability_low`, `stability_high`:

  The bootstrap interval for kappa at level `1 - alpha`; `NA` for the
  other methods, with `B = 0`, and where kappa has no interval.

- `stability_df`, `stability_p`:

  The degrees of freedom and *p* of a chi-square; `NA` for the other
  methods.

- `stable`:

  The stability rule's decision for the chi-square and net-change
  methods (see Details); `NA` for kappa and lambda, which apply no rule,
  where the item has no pair, and where the individual chi-square cannot
  be computed.

- `recommendation`:

  `"Consensus"`, `"No consensus"`, `"Descriptive only"` (no
  `consensus_threshold` was set), or `"Insufficient panel"` (fewer than
  three experts rated the item in its last round, whether or not a
  threshold was set). Stability never changes it.

- `interpretation`:

  The decision explained in a sentence. Shares and the threshold are
  percentages to at most one decimal (66.7%), as in the handoff;
  [`print()`](https://rdrr.io/r/base/print.html) and
  [`summary()`](https://rdrr.io/r/base/summary.html) give a share just
  under the threshold, and the threshold, the decimals that tell them
  apart.

- `status`:

  The shared status: `"Supported"` for `"Consensus"`, `"Review"` for
  `"No consensus"`, `"Descriptive only"`, or `"Insufficient data"` for
  `"Insufficient panel"`.

## Details

**Consensus.** An expert agrees with an item when their rating is at
least `agree_cut`. `prop_agree` is the share of responding experts who
agree, which on a relevance scale is the I-CVI. An item reaches
consensus when `prop_agree` meets `consensus_threshold`. There is
deliberately no default threshold: Diamond et al. (2014) recommend
fixing it before the study. Among the 25 studies in their review that
defined consensus as a percentage of agreement, the median threshold was
75%, which describes common practice rather than a validated cutoff. The
function cannot know when a threshold was chosen, so its output says
only that one was supplied. Without a threshold, items are reported as
`Descriptive only`.

**Stability** is computed for each item and each pair of consecutive
rounds, on the experts who rated the item in both. `prop_unchanged`, the
share who kept their rating, is always reported. The `stability`
argument chooses the statistic reported beside it:

- `"kappa"` (default): weighted kappa between each expert's ratings in
  the two rounds (Holey et al., 2007), read as a trend with no cutoff.
  Quadratic weights (the default) make kappa the intraclass correlation
  of the two rounds' ratings in its sums-of-squares form (Fleiss &
  Cohen, 1973). The intraclass correlation computed from mean squares,
  the form most software reports, differs from it by a term that shrinks
  as the panel grows, so with a Delphi-sized panel the two do not match
  exactly. Linear weights count a two-point change twice a one-point
  change (Cohen, 1968). The interval is a percentile bootstrap over the
  experts; see *Reading the kappa interval* below.

- `"lambda"`: Chaffin and Talley's (1980) index of predictive
  association.

- `"chisq_individual"`: Chaffin and Talley's (1980) chi-square test on
  each expert's pair of ratings; a significant result is read as stable.

- `"chisq_group"`: the chi-square test of Dajani et al. (1979) on the
  two rounds' distributions; a non-significant result is read as stable.

- `"percent_change"`: the net change of Scheibe et al. (1975/2002),
  stable below 15%.

The alternatives are published but contested, so the printed output
explains each one's limits. Stability never changes an item's status:
the status rests on consensus in the item's last round, and stability is
read beside it.

Items may enter or leave between rounds. An item's last round is the
last one in which anyone rated it, and stability is computed only
between consecutive rounds in which it was rated. An item rated in
rounds 1 and 3 but not 2 therefore has no pair to compare, and an item
rated in rounds 1, 2 and 4 reports the stability of rounds 1 and 2
beside its round 4 consensus. `details$stability` names the rounds of
every pair.

**Round order.** Numbered rounds are put in numeric order, dates in date
order, and a factor keeps the order of its levels. Text labels are
ordered by the number each carries (`"R1"`, `"Round 2"`, `"wave 10"`),
whatever order the rows are in, when that number is all that differs
between them. Text labels without a number (`"pre"`, `"post"`), or that
differ in more than one number (`"Q4 2023"`, `"Q1 2024"`), cannot be
ordered from the text, so they stop with a request for a factor. The
printout lists the rounds in the order used.

## When a stability statistic is undefined

A stability statistic can be `NA` for different reasons, and
`prop_unchanged` tells them apart. When `prop_unchanged` is also `NA`,
no expert's ratings could be paired, for one of three reasons: the item
was rated in one round only; it was rated in rounds that are not
consecutive; or it was rated in consecutive rounds, but by different
experts, so no expert rated it in both (two disjoint panels, for
example). Only the last case has a row in `details$stability`, with
`n_paired` 0 and a `note` saying so. When `prop_unchanged` has a value,
a pair exists but the statistic is undefined for that data, and
`details$stability$note` says why.

The common case is the one that reads worst if reported bare. Kappa is
chance-corrected, so when every paired rating in both rounds falls in
one category the disagreement expected by chance is zero and kappa is
0/0. There `prop_unchanged` is 1: the panel could not have been more
stable, and saying only "not estimable" would describe a defect that
does not exist. Goodman- Kruskal lambda is undefined when the later
round is unanimous, and the chi-square methods when a table has fewer
than two occupied rows or columns.

## Why kappa has no verbal labels

Landis and Koch (1977) introduced the familiar labels (slight, fair,
moderate, substantial, almost perfect) and called their divisions
clearly arbitrary. Kappa is also low when ratings concentrate in one
category (Feinstein & Cicchetti, 1990), which is where a Delphi aims to
end. In Holey et al. (2007), the statement nearly every expert agreed
with, and ranked most important in every round, had the lowest kappa
between rounds 1 and 2 (.31) and one of the highest between rounds 2 and
3 (.71); they suggest the narrow range of answers as the reason. A label
could therefore worsen as a panel succeeds. Read kappa as a trend, next
to `prop_unchanged`.

## Reading the kappa interval

The interval beside kappa is a percentile bootstrap: the experts are
resampled with replacement, each carrying both of their ratings, kappa
is recomputed in every resample, and the interval runs from the
`alpha / 2` to the `1 - alpha / 2` quantile of those values. The experts
are the units the two rounds cross-classify, so this is the same
resampling scheme Klar et al. (2002) describe for kappa, where the
subjects each contribute one pair of ratings.

Two things about it are worth knowing before the interval is reported.

First, it is not exact at the sizes Delphi panels run to. Klar et al.
(2002) simulated this interval and found that a nominal 95% interval
covered the true value about 83% of the time with 20 units, 89% with 25,
91% with 30, and only reached about 94% from 40 up. Panels smaller than
40 therefore get an interval narrower than its label claims, and the
shortfall grows as the panel shrinks. Report it as a rough indication of
precision rather than as a test of a hypothesis about kappa.

Second, those simulations used an unweighted kappa on two categories,
while this function computes a weighted kappa on an ordinal scale. The
resampling scheme is the same, and nothing in it depends on the number
of categories or on the weights, but its coverage has not been simulated
for that case. Treat the coverage figures above as the shape of the
problem rather than as exact numbers for a Delphi panel.

Set `B = 0` to omit the interval and report kappa beside
`prop_unchanged` alone.

## References

Chaffin, W. W., & Talley, W. K. (1980). Individual stability in Delphi
studies. *Technological Forecasting and Social Change, 16*(1), 67–73.
[doi:10.1016/0040-1625(80)90074-8](https://doi.org/10.1016/0040-1625%2880%2990074-8)

Cohen, J. (1968). Weighted kappa: Nominal scale agreement provision for
scaled disagreement or partial credit. *Psychological Bulletin, 70*(4),
213–220. [doi:10.1037/h0026256](https://doi.org/10.1037/h0026256)

Dajani, J. S., Sincoff, M. Z., & Talley, W. K. (1979). Stability and
agreement criteria for the termination of Delphi studies. *Technological
Forecasting and Social Change, 13*(1), 83–90.
[doi:10.1016/0040-1625(79)90007-6](https://doi.org/10.1016/0040-1625%2879%2990007-6)

Diamond, I. R., Grant, R. C., Feldman, B. M., Pencharz, P. B., Ling, S.
C., Moore, A. M., & Wales, P. W. (2014). Defining consensus: A
systematic review recommends methodologic criteria for reporting of
Delphi studies. *Journal of Clinical Epidemiology, 67*(4), 401–409.
[doi:10.1016/j.jclinepi.2013.12.002](https://doi.org/10.1016/j.jclinepi.2013.12.002)

Feinstein, A. R., & Cicchetti, D. V. (1990). High agreement but low
kappa: I. The problems of two paradoxes. *Journal of Clinical
Epidemiology, 43*(6), 543–549.
[doi:10.1016/0895-4356(90)90158-L](https://doi.org/10.1016/0895-4356%2890%2990158-L)

Fleiss, J. L., & Cohen, J. (1973). The equivalence of weighted kappa and
the intraclass correlation coefficient as measures of reliability.
*Educational and Psychological Measurement, 33*(3), 613–619.
[doi:10.1177/001316447303300309](https://doi.org/10.1177/001316447303300309)

Holey, E. A., Feeley, J. L., Dixon, J., & Whittaker, V. J. (2007). An
exploration of the use of simple statistics to measure consensus and
stability in Delphi studies. *BMC Medical Research Methodology, 7*,
Article 52.
[doi:10.1186/1471-2288-7-52](https://doi.org/10.1186/1471-2288-7-52)

Klar, N., Lipsitz, S. R., Parzen, M., & Leong, T. (2002). An exact
bootstrap confidence interval for kappa in small samples. *Journal of
the Royal Statistical Society: Series D (The Statistician), 51*(4),
467–478.
[doi:10.1111/1467-9884.00331](https://doi.org/10.1111/1467-9884.00331)

Landis, J. R., & Koch, G. G. (1977). The measurement of observer
agreement for categorical data. *Biometrics, 33*(1), 159–174.
[doi:10.2307/2529310](https://doi.org/10.2307/2529310)

Scheibe, M., Skutsch, M., & Schofer, J. (2002). Experiments in Delphi
methodology. In H. A. Linstone & M. Turoff (Eds.), *The Delphi method:
Techniques and applications* (pp. 257–281).
<https://www.foresight.pl/assets/downloads/publications/Turoff_Linstone.pdf>
(Original work published 1975)

## See also

[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
for a single round, and
[`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md),
which accepts the fits in `details$round_fits`.

## Examples

``` r
# Eight experts rate four statements for relevance (1-4) over three rounds.
r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4, 3, 4), S2 = c(2, 3, 2, 1, 3, 2, 2, 3),
            S3 = c(3, 4, 2, 3, 4, 1, 3, 2), S4 = c(4, 3, 4, 2, 3, 3, 4, 2))
r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2, 2, 2),
            S3 = c(3, 3, 3, 3, 4, 2, 3, 3), S4 = c(4, 3, 4, 3, 3, 3, 4, 3))
r3 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 4, 4), S2 = c(2, 2, 2, 1, 2, 2, 2, 2),
            S3 = c(3, 3, 3, 3, 4, 3, 3, 3), S4 = c(4, 3, 4, 3, 4, 3, 4, 3))
long <- function(m, round) {
  data.frame(expert = paste0("E", seq_len(nrow(m))),
             item = rep(colnames(m), each = nrow(m)),
             round = round, rating = as.vector(m))
}
ratings <- rbind(long(r1, 1), long(r2, 2), long(r3, 3))

fit <- delphi_validity(ratings, lo = 1, hi = 4, consensus_threshold = 0.75,
                       B = 200, seed = 1)
fit
#> <contentvalid_delphi> Delphi analysis
#> Items: 4 | Experts: 8 | Rounds: 3 (1, 2, 3)
#> Experts per round: 8, 8, 8
#> Agreement: a rating of 3 or higher on the 1 to 4 scale.
#> Consensus threshold: 75%, as supplied.
#> Stability: weighted kappa (quadratic weights) between consecutive rounds
#> 
#> 3 of 4 items reached consensus in their last round.
#> No consensus: S2
#> Agreed in the other direction (75% or more rated it below 3): S2
#> 
#> Item-level evidence (last round, and the last pair of rounds)
#>   Item  Decision      Last round  Experts  Agree  Unchanged  Kappa       95% CI
#>   S1    Consensus              3        8   1.00        .88    .60  [.00, 1.00]
#>   S2    No consensus           3        8    .00        .88    .67  [.00, 1.00]
#>   S3    Consensus              3        8   1.00        .88    .67  [.00, 1.00]
#>   S4    Consensus              3        8   1.00        .88    .75  [.00, 1.00]
#> 
#>   Agree: share of experts agreeing in the item's last round. Unchanged: share
#>   who kept their rating between the item's last pair of consecutive rounds.
#> 
#> Stability trend (kappa) by pair of rounds
#>   Item  1->2  2->3
#>   S1     .67   .60
#>   S2     .67   .67
#>   S3     .60   .67
#>   S4     .72   .75
#> 
#> Share of experts who kept their rating, by pair of rounds
#>   Item  1->2  2->3
#>   S1     .75   .88
#>   S2     .75   .88
#>   S3     .50   .88
#>   S4     .75   .88
#> 
#>   In some resamples kappa was undefined because every resampled rating fell in
#>   one category. Those intervals use the remaining resamples (n_boot_usable in
#>   details$stability), so treat them as rough.
#> 
#>   Read kappa as a trend across rounds, beside the share of experts who kept
#>   their rating (unchanged), not against a cutoff. Kappa can be low when
#>   ratings concentrate in one category (Feinstein & Cicchetti, 1990), so an
#>   agreeing panel can show a low kappa; Holey et al. (2007) suggest this for
#>   their Statement 7.
#> 
#>   The kappa intervals resample the experts (Klar et al., 2002). With fewer
#>   than about 40 experts they cover less than their stated 95%, so read them as
#>   rough indications of precision, not as tests.
#> 
#>   Diamond et al. (2014) recommend fixing the consensus threshold before the
#>   study. Report whether this one was.
#> 
#> How the stability statistic works
#>   Stability is weighted kappa between each expert's ratings in consecutive
#>   rounds (Holey et al., 2007), with quadratic weights. A change of two scale
#>   points counts four times a change of one. With these weights kappa equals
#>   the intraclass correlation of the two rounds' ratings in its sums-of-squares
#>   form, so a shift of the whole panel counts as instability (Fleiss & Cohen,
#>   1973). The intraclass correlation computed from mean squares, the more
#>   common form, differs from it by a term that shrinks as the panel grows, so
#>   in a panel of Delphi size the two can differ. No verbal labels such as
#>   'substantial' are shown, because kappa can be low when ratings concentrate
#>   in one category, which is where a Delphi aims to end. Feinstein and
#>   Cicchetti (1990) showed it for kappa on two categories, and the same
#>   arithmetic applies to weighted kappa. In Holey et al. (2007), the statement
#>   nearly every expert agreed with had the lowest kappa between rounds 1 and 2
#>   (.31).
#> 
#>   The intervals are percentile bootstraps that resample the experts, the units
#>   the two rounds cross-classify: the procedure Klar et al. (2002) describe for
#>   kappa. They evaluated it for an unweighted kappa on two categories, and a
#>   nominal 95% interval covered about 83% of the time with 20 units and 91%
#>   with 30, reaching 94% only from 40 up.
#> 
#> What these columns mean
#>   Agree -- Share of experts agreeing. Share of experts at or above the
#>       agreement cut in a round; consensus means reaching the consensus
#>       threshold.
#>   Unchanged -- Share of experts keeping their rating. Share of experts giving
#>       the same rating in two consecutive rounds (1 means nobody changed).
#>   Kappa -- Weighted kappa between rounds. Chance-corrected agreement of each
#>       expert's ratings across two rounds; read it as a trend, not against a
#>       cutoff.
#> 
#> What the decisions mean
#>   Consensus -- reached the consensus threshold in its last round.
#>   No consensus -- did not reach the consensus threshold.
#> 
#>   Full definitions: contentvalid_glossary(). To hide this key:
#>   options(contentvalidR.show_key = FALSE).
#> 
#> Consensus is not correctness, and 'No consensus' is not an instruction to drop
#> an item. Read these results with the experts' comments.
#> 
#> See summary(x) for the items without consensus and plot(x) for the rounds.
fit$details$stability
#>   item from_round to_round n_paired prop_unchanged method     value     lower
#> 1   S1          1        2        8          0.750  kappa 0.6666667 0.0000000
#> 2   S1          2        3        8          0.875  kappa 0.6000000 0.0000000
#> 3   S2          1        2        8          0.750  kappa 0.6666667 0.0000000
#> 4   S2          2        3        8          0.875  kappa 0.6666667 0.0000000
#> 5   S3          1        2        8          0.500  kappa 0.6000000 0.0000000
#> 6   S3          2        3        8          0.875  kappa 0.6666667 0.0000000
#> 7   S4          1        2        8          0.750  kappa 0.7241379 0.3425676
#> 8   S4          2        3        8          0.875  kappa 0.7500000 0.0000000
#>       upper df p_value stable min_expected n_low_expected n_boot_usable note
#> 1 1.0000000 NA      NA     NA           NA             NA           196     
#> 2 1.0000000 NA      NA     NA           NA             NA           179     
#> 3 1.0000000 NA      NA     NA           NA             NA           200     
#> 4 1.0000000 NA      NA     NA           NA             NA           188     
#> 5 0.8227778 NA      NA     NA           NA             NA           199     
#> 6 1.0000000 NA      NA     NA           NA             NA           182     
#> 7 1.0000000 NA      NA     NA           NA             NA           200     
#> 8 1.0000000 NA      NA     NA           NA             NA           200     

# A published alternative, with its critique printed.
delphi_validity(ratings, lo = 1, hi = 4, consensus_threshold = 0.75,
                stability = "percent_change")
#> <contentvalid_delphi> Delphi analysis
#> Items: 4 | Experts: 8 | Rounds: 3 (1, 2, 3)
#> Experts per round: 8, 8, 8
#> Agreement: a rating of 3 or higher on the 1 to 4 scale.
#> Consensus threshold: 75%, as supplied.
#> Stability: net percent change (Scheibe et al., 1975/2002) between consecutive
#> rounds
#> 
#> 3 of 4 items reached consensus in their last round.
#> No consensus: S2
#> Agreed in the other direction (75% or more rated it below 3): S2
#> 
#> Item-level evidence (last round, and the last pair of rounds)
#>   Item  Decision      Last round  Experts  Agree  Unchanged  Net change  Stable
#>   S1    Consensus              3        8   1.00        .88         .13  yes
#>   S2    No consensus           3        8    .00        .88         .13  yes
#>   S3    Consensus              3        8   1.00        .88         .13  yes
#>   S4    Consensus              3        8   1.00        .88         .13  yes
#> 
#>   Agree: share of experts agreeing in the item's last round. Unchanged: share
#>   who kept their rating between the item's last pair of consecutive rounds.
#> 
#> Stability trend (net change) by pair of rounds
#>   Item  1->2  2->3
#>   S1     .13   .13
#>   S2     .25   .13
#>   S3     .38   .13
#>   S4     .25   .13
#> 
#> Share of experts who kept their rating, by pair of rounds
#>   Item  1->2  2->3
#>   S1     .75   .88
#>   S2     .75   .88
#>   S3     .50   .88
#>   S4     .75   .88
#> 
#>   Stability is the net change of Scheibe et al. (1975/2002): half the summed
#>   differences between the two rounds' rating distributions, as a share of the
#>   experts compared, with change below 15% read as stable. The authors say the
#>   measure has no statistical theory behind it; the 15% threshold came from the
#>   movement they observed in one classroom Delphi. Experts swapping answers
#>   cancel out, and in a small panel one expert is a large share: with 10
#>   experts one net change is already 10%.
#> 
#>   Diamond et al. (2014) recommend fixing the consensus threshold before the
#>   study. Report whether this one was.
#> 
#> What these columns mean
#>   Agree -- Share of experts agreeing. Share of experts at or above the
#>       agreement cut in a round; consensus means reaching the consensus
#>       threshold.
#>   Unchanged -- Share of experts keeping their rating. Share of experts giving
#>       the same rating in two consecutive rounds (1 means nobody changed).
#>   Net change -- Net change in the rating distribution. How far the
#>       distribution moved between rounds, as a share of the experts (stable
#>       below .15 by its authors' rule).
#> 
#> What the decisions mean
#>   Consensus -- reached the consensus threshold in its last round.
#>   No consensus -- did not reach the consensus threshold.
#> 
#>   Full definitions: contentvalid_glossary(). To hide this key:
#>   options(contentvalidR.show_key = FALSE).
#> 
#> Consensus is not correctness, and 'No consensus' is not an instruction to drop
#> an item. Read these results with the experts' comments.
#> 
#> See summary(x) for the items without consensus and plot(x) for the rounds.
```

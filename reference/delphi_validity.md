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

- expert_col, item_col, round_col, rating_col:

  Column names in `ratings`.

- lo, hi:

  Lowest and highest points of the rating scale, as whole numbers.

- agree_cut:

  Rating at or above which an expert counts as agreeing. Defaults to
  `hi - 1`, the usual relevance cut on a 4-point scale.

- consensus_threshold:

  Share of experts that must agree for consensus, between 0 and 1, fixed
  before the study. `NULL` (default) reports agreement descriptively.

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

  Optional seed for the bootstrap.

## Value

An object of class `contentvalid_delphi` and `contentvalid_workflow`.
`results` has one row per item: its last round, `n_experts` there,
`prop_agree`, `consensus`, and, for the last pair of consecutive rounds,
`prop_unchanged`, `stability` with `stability_low` and `stability_high`
where an interval exists, `stability_p` for the chi-square methods, and
`stable` for the methods that make a decision. `details` holds
`consensus` (every item and round), `stability` (every item and pair of
rounds, including `n_paired`, `min_expected` for the chi-square methods,
`n_boot_usable` for the kappa interval, and a `note` where a statistic
is undefined or unreliable), `panel` (experts per round), and
`round_fits`, the
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
fit for each round.

## Details

**Consensus.** An expert agrees with an item when their rating is at
least `agree_cut`. `prop_agree` is the share of responding experts who
agree, which on a relevance scale is the I-CVI. An item reaches
consensus when `prop_agree` meets `consensus_threshold`. There is
deliberately no default threshold: Diamond et al. (2014) recommend
fixing it before the study, and the 75% median they report describes
common practice rather than a validated cut-off. Without a threshold,
items are reported as `Descriptive only`.

**Stability** is computed for each item and each pair of consecutive
rounds, on the experts who rated the item in both. `prop_unchanged`, the
share who kept their rating, is always reported. The `stability`
argument chooses the statistic reported beside it:

- `"kappa"` (default): weighted kappa between each expert's ratings in
  the two rounds (Holey et al., 2007), read as a trend with no cut-off.
  Quadratic weights (the default) make kappa the intraclass correlation
  of the two rounds' ratings (Fleiss & Cohen, 1973); linear weights
  count a two-point change twice a one-point change (Cohen, 1968). The
  interval resamples experts, which is this package's extension.

- `"lambda"`: Chaffin and Talley's (1980) index of predictive
  association.

- `"chisq_individual"`: Chaffin and Talley's (1980) chi-square test on
  each expert's pair of ratings; a significant result is read as stable.

- `"chisq_group"`: Dajani, Sincoff and Talley's (1979) chi-square test
  on the two rounds' distributions; a non-significant result is read as
  stable.

- `"percent_change"`: Scheibe, Skutsch and Schofer's (1975) net change,
  stable below 15%.

The alternatives are published but contested, so the printed output
explains each one's limits. Stability never changes an item's status:
the status rests on consensus in the item's last round, and stability is
read beside it.

Items may enter or leave between rounds. An item's last round is the
last one in which anyone rated it, and stability is computed only
between consecutive rounds in which it was rated.

## When a stability statistic is undefined

A stability statistic can be `NA` for two different reasons, and
`prop_unchanged` tells them apart. When `prop_unchanged` is also `NA`,
the item has no pair of consecutive rounds: it was rated in one round
only. When `prop_unchanged` has a value, a pair exists but the statistic
is undefined for that data, and `details$stability$note` says why.

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
clearly arbitrary. Kappa also falls when ratings converge on one
category, which is what a Delphi aims for: in Holey et al. (2007), the
statement experts agreed on most had the lowest kappa. A label would
therefore tend to worsen as a panel succeeds. Read kappa as a trend,
next to `prop_unchanged`.

## References

Chaffin, W. W., & Talley, W. K. (1980). Individual stability in Delphi
studies. *Technological Forecasting and Social Change, 16*(1), 67-73.
[doi:10.1016/0040-1625(80)90074-8](https://doi.org/10.1016/0040-1625%2880%2990074-8)

Cohen, J. (1968). Weighted kappa: Nominal scale agreement provision for
scaled disagreement or partial credit. *Psychological Bulletin, 70*(4),
213-220. [doi:10.1037/h0026256](https://doi.org/10.1037/h0026256)

Dajani, J. S., Sincoff, M. Z., & Talley, W. K. (1979). Stability and
agreement criteria for the termination of Delphi studies. *Technological
Forecasting and Social Change, 13*(1), 83-90.
[doi:10.1016/0040-1625(79)90007-6](https://doi.org/10.1016/0040-1625%2879%2990007-6)

Diamond, I. R., Grant, R. C., Feldman, B. M., Pencharz, P. B., Ling, S.
C., Moore, A. M., & Wales, P. W. (2014). Defining consensus: A
systematic review recommends methodologic criteria for reporting of
Delphi studies. *Journal of Clinical Epidemiology, 67*(4), 401-409.
[doi:10.1016/j.jclinepi.2013.12.002](https://doi.org/10.1016/j.jclinepi.2013.12.002)

Fleiss, J. L., & Cohen, J. (1973). The equivalence of weighted kappa and
the intraclass correlation coefficient as measures of reliability.
*Educational and Psychological Measurement, 33*(3), 613-619.
[doi:10.1177/001316447303300309](https://doi.org/10.1177/001316447303300309)

Holey, E. A., Feeley, J. L., Dixon, J., & Whittaker, V. J. (2007). An
exploration of the use of simple statistics to measure consensus and
stability in Delphi studies. *BMC Medical Research Methodology, 7*, 52.
[doi:10.1186/1471-2288-7-52](https://doi.org/10.1186/1471-2288-7-52)

Landis, J. R., & Koch, G. G. (1977). The measurement of observer
agreement for categorical data. *Biometrics, 33*(1), 159-174.
[doi:10.2307/2529310](https://doi.org/10.2307/2529310)

Scheibe, M., Skutsch, M., & Schofer, J. (1975). Experiments in Delphi
methodology. In H. A. Linstone & M. Turoff (Eds.), *The Delphi method:
Techniques and applications*. Addison-Wesley.

Zapf, A., Castell, S., Morawietz, L., & Karch, A. (2016). Measuring
inter-rater reliability for nominal data: Which coefficients and
confidence intervals are appropriate? *BMC Medical Research Methodology,
16*, 93.
[doi:10.1186/s12874-016-0200-9](https://doi.org/10.1186/s12874-016-0200-9)

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
#> contentvalidR Delphi analysis
#> -----------------------------
#> Items: 4 | Experts: 8 | Rounds: 3 (1, 2, 3) 
#> Experts per round: 8, 8, 8 
#> Agreement: a rating of 3 or higher on the 1-4 scale. Consensus threshold:
#> 75%, fixed before the study.
#> Stability: weighted kappa (quadratic weights) between consecutive rounds
#> 
#> 3 item(s) reached consensus in their last round; 1 did not.
#> No consensus: S2 
#> 
#> Item-level evidence (last round, and the last pair of rounds):
#>  item last_round n prop_agree prop_unchanged kappa low high recommendation
#>    S1          3 8          1           0.88  0.60   0    1      Consensus
#>    S2          3 8          0           0.88  0.67   0    1   No consensus
#>    S3          3 8          1           0.88  0.67   0    1      Consensus
#>    S4          3 8          1           0.88  0.75   0    1      Consensus
#> 
#> Stability trend (kappa) by pair of rounds:
#>  item 1->2 2->3
#>    S1 0.67 0.60
#>    S2 0.67 0.67
#>    S3 0.60 0.67
#>    S4 0.72 0.75
#> 
#> Share of experts who kept their rating, by pair of rounds:
#>  item 1->2 2->3
#>    S1 0.75 0.88
#>    S2 0.75 0.88
#>    S3 0.50 0.88
#>    S4 0.75 0.88
#> 
#> In some resamples kappa was undefined because every resampled rating fell
#> in one category. Those intervals use the remaining resamples (n_boot_usable
#> in details$stability), so treat them as rough.
#> 
#> Stability is weighted kappa between each expert's ratings in consecutive
#> rounds (Holey et al., 2007), with quadratic weights. A change of two scale
#> points counts four times a change of one. With these weights kappa equals
#> the intraclass correlation of the two rounds' ratings, so a shift of the
#> whole panel counts as instability (Fleiss & Cohen, 1973). Read kappa as a
#> trend across rounds, not against a cut-off. No verbal labels such as
#> 'substantial' are shown: kappa falls when ratings converge on one category,
#> which is what a Delphi aims for, so a panel whose experts nearly all kept
#> their answer can still show a low kappa. Holey et al. saw this for their
#> most-agreed statement. Read kappa next to prop_unchanged. The intervals are
#> percentile bootstraps that resample experts. That is this package's
#> extension: Zapf et al. (2016) evaluated resampling items for panel
#> coefficients, not experts for a two-round kappa. With few experts the
#> intervals are wide.
#> 
#> What these columns mean
#>   prop_agree -- Share of experts agreeing. Share of the experts rating an
#>       item in a round whose rating was at or above the agreement cut. On a
#>       relevance scale this is the I-CVI. Consensus means it reached the
#>       threshold set before the study. (0 to 1; higher is broader agreement)
#>   prop_unchanged -- Share of experts keeping their rating. Among experts
#>       who rated the item in both of two consecutive rounds, the share who
#>       gave exactly the same rating again. It is the plainest reading of
#>       stability, and it stays meaningful when kappa does not. (0 to 1; 1
#>       means no expert changed their rating)
#>   kappa_w -- Weighted kappa between rounds. Agreement between each expert's
#>       ratings in two consecutive rounds, corrected for chance, with larger
#>       changes counting more. Read it as a trend across rounds. It falls
#>       when ratings bunch in one category, so a converged panel can show a
#>       low kappa even when almost no one changed their rating. (-1 to 1; 1
#>       is perfect stability, 0 is no better than chance)
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
#> Consensus is not correctness, and 'No consensus' is not an instruction to
#> drop an item. Read these results with the experts' comments.
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
#> contentvalidR Delphi analysis
#> -----------------------------
#> Items: 4 | Experts: 8 | Rounds: 3 (1, 2, 3) 
#> Experts per round: 8, 8, 8 
#> Agreement: a rating of 3 or higher on the 1-4 scale. Consensus threshold:
#> 75%, fixed before the study.
#> Stability: net percent change (Scheibe et al., 1975) between consecutive rounds
#> 
#> 3 item(s) reached consensus in their last round; 1 did not.
#> No consensus: S2 
#> 
#> Item-level evidence (last round, and the last pair of rounds):
#>  item last_round n prop_agree prop_unchanged change stable recommendation
#>    S1          3 8          1           0.88   0.12   TRUE      Consensus
#>    S2          3 8          0           0.88   0.12   TRUE   No consensus
#>    S3          3 8          1           0.88   0.12   TRUE      Consensus
#>    S4          3 8          1           0.88   0.12   TRUE      Consensus
#> 
#> Stability trend (change) by pair of rounds:
#>  item 1->2 2->3
#>    S1 0.12 0.12
#>    S2 0.25 0.12
#>    S3 0.38 0.12
#>    S4 0.25 0.12
#> 
#> Share of experts who kept their rating, by pair of rounds:
#>  item 1->2 2->3
#>    S1 0.75 0.88
#>    S2 0.75 0.88
#>    S3 0.50 0.88
#>    S4 0.75 0.88
#> 
#> Stability is Scheibe, Skutsch and Schofer's (1975) net change: half the
#> summed differences between the two rounds' rating distributions, as a share
#> of the experts compared, with change below 15% read as stable. The authors
#> say the measure has no statistical theory behind it; the 15% cut-off came
#> from the movement they observed in one classroom Delphi. Experts swapping
#> answers cancel out, and in a small panel one expert is a large share: with
#> 10 experts one net change is already 10%.
#> 
#> What these columns mean
#>   prop_agree -- Share of experts agreeing. Share of the experts rating an
#>       item in a round whose rating was at or above the agreement cut. On a
#>       relevance scale this is the I-CVI. Consensus means it reached the
#>       threshold set before the study. (0 to 1; higher is broader agreement)
#>   prop_unchanged -- Share of experts keeping their rating. Among experts
#>       who rated the item in both of two consecutive rounds, the share who
#>       gave exactly the same rating again. It is the plainest reading of
#>       stability, and it stays meaningful when kappa does not. (0 to 1; 1
#>       means no expert changed their rating)
#>   percent_change -- Net change in the rating distribution. How far the
#>       panel's rating distribution moved between two rounds, as a share of
#>       the experts compared. Change below 15% is read as stable, a cut-off
#>       its authors set from one study without statistical theory. (0 to 1;
#>       stable below 0.15)
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
#> Consensus is not correctness, and 'No consensus' is not an instruction to
#> drop an item. Read these results with the experts' comments.
```

# Changelog

## contentvalidR 0.10.1.9000 (development version)

Fixes from the audit before 1.0. Some of them change values, so check
any analysis that matches the cases below.

### Removed

- `agreement_summary()` is removed, as announced when it was deprecated
  in 0.9.0. Use
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md),
  which takes raters in rows like every other ratings function. The
  deprecation warning shipped only on GitHub and R-universe, so a user
  updating from 0.4.0 on CRAN meets the removal without it.
- Five returned fields are removed without a notice period, because the
  audit found them wrong or unreachable;
  [`?contentvalidR`](https://juhalt.github.io/contentvalidR/reference/contentvalidR-package.md)
  records the exception to the deprecation policy. Each is explained in
  the section named:
  - `overall_strength` in the `scale_summary` of
    [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
    and
    [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
    (“Congruence and method attribution: values that change”);
  - `n_support` in the `scale_summary` of
    [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
    (same section);
  - `competitor_ioc` in the congruence `results` of
    [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md),
    whose results without a target mapping now have one row per item
    (same section; the congruence handoff statistics `competitor IOC`
    and `IOC margin` give way to `target IOC` and the two mean ratings);
  - `n_influential` in the `scale_summary` of
    [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
    (“Judges, domain and structure: values that change”);
  - `fit_label` in the `fit` table of
    [`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md)
    (same section).

### Item sort: values that change

- **Constructs coded as numbers or factors now give the right counts.**
  When the target construct was a number (1, 2, 3) or a factor,
  [`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md)
  read the target’s count by position in its table, not by label. The
  target count, Csv, the exact *p* value, the Retain or Review decision,
  and the items
  [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
  carried could all be wrong, with no error: an item with 16 of 20
  judges on target could print 4/20, Csv .00, and Review. Every earlier
  release had this, including 0.4.0, the version on CRAN. Constructs
  stored as text in both columns were always right. Rerun any sort whose
  construct columns are numbers or factors. Labels are now compared as
  text, whatever they are stored as, so `target` in `results` is always
  text, and tied competitors are listed in alphabetical order.
- **An item sorted by too few judges for the exact test gets no
  decision.** With four or fewer judges at the defaults no count can
  reach alpha (4 of 4 gives *p* = .0625). Such items were labeled
  `"Review"`, as if judges had disagreed. They are now
  `"Insufficient panel"`, with status `"Insufficient data"`; the
  printout and [`summary()`](https://rdrr.io/r/base/summary.html) say
  why; and the `rule` text in the handoff says that no count can meet
  the test, where it used to read “target assignments \>= NA of 4”.
  Scale means are unchanged: they still average every item that has a
  Psa and a Csv.
- **The
  [`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md)
  interval follows `alpha`.** It was always a 95% interval, so at
  `alpha = .10` a significant result could sit beside an interval that
  included `p0`. It is now one-sided at `1 - alpha`, the level of the
  test, so its lower limit is above `p0` whenever *p* is below alpha. At
  the default alpha nothing changes.
- **[`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md)
  reports a power of 0, not `NA`,** for a panel too small for any count
  to reach alpha, and says so under the table.
- **Leading and trailing spaces in labels are ignored,** non-breaking
  spaces included, in item, judge and construct labels. `"A"` and `" A"`
  were counted as two constructs.
- **Items are listed in the order of the data,** or of the levels when
  the item column is a factor. They used to be sorted as text, so Q10
  came before Q2. The order reaches `results`, the figures, and `items`
  in the handoff, and the rows of `scale_summary` follow the order in
  which each scale first appears. Item names in `results` are always
  text.

### Every workflow: values that change

- **A scale mean exactly on a published Colquitt band minimum now falls
  in that band.** A mean such as 4.35 / 5 is stored a hair under .87 and
  was put in the band below. This affects
  [`interpret_colquitt()`](https://juhalt.github.io/contentvalidR/reference/interpret_colquitt.md)
  and the scale labels of both
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  and
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md).
- **An alpha with more than two decimals is printed in full.**
  `alpha = .001` printed as “alpha = .00” in every workflow and in the
  `rule` text of the handoff. A computed level such as .05 / 3 prints to
  three significant digits (.0167).

### Item sort: other fixes

- Two factor construct columns with different level sets no longer stop
  [`compute_psa()`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md)
  and
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  with “level sets of factors are different”.
- [`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md)
  prints its verdict first, in the item-sort workflow’s words (“meets
  the exact target-assignment criterion”). It printed “Decision: n.s..”
  at the end. The stored `decision` values are unchanged; the stored
  `interpretation` text now says “meet the exact criterion” where it
  said “exceed the exact chance criterion”.
- The
  [`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md)
  printout and figure no longer call the assumed target-assignment
  probability “p”, which APA reserves for a *p* value: the note says
  “power at a value” and the legend “Target rate”.
- The legacy comparison says so when no item has a decision to compare
  with, where it printed “0 of 0 items”.
- “Missing assignments: 2 across 1 items” now reads “1 item”.
- The help for `p0` no longer calls it a chance rate. It is the null
  probability of a target assignment; random assignment would give 1
  divided by the number of constructs. The help now passes on the
  caution Howard and Melloy (2016) give themselves: that .5 is arbitrary
  and lenient.
- The help for `proportion_ci` says the interval is two-sided while the
  test is one-sided, so a retained item’s interval can include `p0`.
- The item-sort and construct-rating vignettes said scale means are
  drawn as diamonds; the figures draw triangles.
- [`?interpret_colquitt`](https://juhalt.github.io/contentvalidR/reference/interpret_colquitt.md)
  gives the full reference for Colquitt et al. (2019).

### Expert panel: values that change

- **On a two-point scale the default cut is the top point.** The cut for
  “relevant” defaulted to `hi - 1`, which is the bottom of a 0/1 or 1/2
  scale, so every rating counted. An item no expert rated relevant got
  an I-CVI of 1.00 and “Strong support”.
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md),
  [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
  and
  [`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md)
  now default to `hi` on a two-point scale, and refuse a cut at the
  bottom of any scale.
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) was
  always right.
- **[`aikens_v()`](https://juhalt.github.io/contentvalidR/reference/aikens_v.md)
  needs `lo` and `hi`.** It assumed a 1-5 scale, while
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  and
  [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
  assume 1-4, so `aikens_v(R)` on 1-4 ratings returned .75 for an item
  every expert rated 4. V depends on the scale, so the scale is no
  longer assumed, and the printout states it.
- **A rater-ID column is no longer analyzed as an item.** With four
  experts on a 1-4 scale, an `expert` column holding 1 to 4 was rated as
  an item and changed S-CVI, the agreement coefficient and the handoff.
  Every function that takes a judge-by-item table now stops when a
  column looks like a rater ID, and says which column to remove. The
  check goes by name (`expert`, `judge`, `rater_id`, `ID` and the like),
  and also catches the row-number column a CSV round trip adds (`X`)
  when it counts 1, 2, 3. It cannot catch an ID column with an item-like
  name, and an item that really is named `Subject` has to be renamed.
  [`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md)
  takes long data and is not affected.
- **An essentiality item rated by too few experts for the exact test
  gets no decision.** With four or fewer experts at the defaults no
  count can reach alpha. Such items were `"Review"`, with a legend
  saying too few experts had rated them essential, even at 4 of 4. They
  are now `"Insufficient panel"`, with status `"Insufficient data"`, the
  printout says why, and the `rule` text in the handoff no longer reads
  “CVR \>= NA, i.e. at least NA of 4”.
- **Named essential counts keep their names.**
  [`cvr()`](https://juhalt.github.io/contentvalidR/reference/cvr.md) and
  `expert_validity(mode = "essentiality")` renamed the items of a named
  count vector to Item1, Item2, so the handoff carried names that
  matched no response data. Names are used when every count has a
  distinct, non-blank name; otherwise the items are numbered, as before.
- **Lawshe’s table at nine panelists.** In the comparison block, 8 of 9
  panelists (a CVR of .778) was reported as below his .78, and the
  vignette said his table asks for all nine. His .78 is 8 of 9 printed
  to two decimals: nine panelists can give no other value near it (Ayre
  & Scally, 2014). The comparison now uses the count each tabled value
  implies, so 8 of 9 meets it and his content validity index includes
  that item. Ten of 13 (.538 against .54) still falls short, the one
  size where his table and the exact test differ.
- **A seed no longer resets the random stream of the session.** Every
  `seed` argument called
  [`set.seed()`](https://rdrr.io/r/base/Random.html) and left it set, so
  a seeded call inside a simulation loop made every later replicate draw
  the same data. Seeded resampling now restores the stream it found.
  Results for a given seed are unchanged.
- **The AC1 bootstrap scores every resample on the same categories.** A
  resample that happened to miss a rating category was scored with fewer
  categories, which pulled the interval down. It affected
  `panel_agreement(method = "ac1")` on scales with three or more
  categories; the point estimate, and AC1 inside
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md),
  are unchanged.

### Expert panel: other fixes

- The relevance printout states the rating scale and the cut it used.
- In
  [`aikens_v()`](https://juhalt.github.io/contentvalidR/reference/aikens_v.md)
  and
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md),
  a rating outside the scale names its column and the scale in the
  error, and says to set `lo` and `hi`.
- [`cvr()`](https://juhalt.github.io/contentvalidR/reference/cvr.md) and
  the essentiality table print “none” where no count can meet the test,
  with a sentence saying why, where they printed `NA`.
  [`summary()`](https://rdrr.io/r/base/summary.html) counts such items
  as “Too few experts”, apart from items no expert rated.
- The essentiality figure marks an item whose panel was too small to
  test with a cross, and its legend lists only what is drawn.
- With panels of different sizes, the Lawshe comparison says that his
  minimum is applied as a count, and no longer reads an unrated first
  item as “no minimum for this panel size”.
- [`?cvr`](https://juhalt.github.io/contentvalidR/reference/cvr.md) no
  longer calls the step in Lawshe’s table at eight experts a defect.
- [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
  prints “undefined” for a coefficient that cannot be computed, where it
  printed “= NA” followed by a note about resamples.

### Delphi and round comparison: values that change

- **Text round labels are ordered by their number, not by row order.**
  Rounds labeled `"R1"`, `"R2"`, `"R3"` were taken in the order the rows
  appeared, so data sorted any other way was analyzed in the wrong
  sequence: the wrong last round, the wrong stability pairs, and so the
  wrong consensus decisions, with no message. Text labels are now
  ordered by the number each carries, so `"wave 10"` follows `"wave 2"`,
  when that number is all that differs between them. Labels with no
  number (`"pre"`, `"post"`), or that differ in more than one number
  (`"Q4 2023"`, `"Q1 2024"`), stop with a request for a factor, because
  their order cannot be read from the text. A date column is ordered by
  date. Numeric and factor rounds are unchanged.
- **[`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
  treats a changed panel size as a changed rule,** where the rule
  depends on it. The exact tests and Lynn’s criterion depend on the
  number of judges, so 5 of 6 and 10 of 12, the same Psa, give different
  decisions. The comparison called such rounds identical in settings and
  their transitions “changes in evidence”. For item-sort fits and for
  expert relevance and essentiality fits, `comparable` is now `FALSE`
  and the printout says the panel changed. Other workflows decide on a
  fixed share or cut, so their panel size is not compared. A changed
  seed or number of bootstrap resamples no longer makes rounds
  non-comparable, because neither can move a status.
- **[`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
  refuses fits from different expert-panel modes,** which it compared as
  if a relevance and an essentiality decision were the same, and refuses
  a round label that is missing, empty, or would overwrite the item or
  change column.
- **The Delphi handoff `rule` text is reworded.** It gives the round by
  its position, so rounds labeled 2, 3, 4 no longer read “round 4 of 3”.
  It says the threshold was supplied, where it stated as fact that it
  was “fixed before the study”, which the software cannot know. An item
  with fewer than three experts in its last round gets its own sentence,
  not the consensus rule, whether or not a threshold was supplied.
  Three-author works are cited with “et al.”, here and in the relevance
  handoff.
- **An item rated in rounds that are not consecutive is described as
  such.** Rated in rounds 1 and 3, it has no pair to compare; the
  handoff note said it “was rated in only one round”. The printout names
  such items, and items whose stability comes from an earlier pair than
  their last round (rated in rounds 1, 2 and 4). For those, the
  stability rows of the handoff carry a note naming the pair, since the
  rows are dated by the last round. The printed trend tables list the
  pairs of rounds in round order; a late-entry item listed first put a
  later pair to the left.
- `results` gains `stability_df`, the degrees of freedom of the
  chi-square stability tests.

### Delphi and round comparison: other fixes

- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) on a Delphi
  fit takes `type`, like the other plot methods with more than one view.
  The earlier name, `which`, is still accepted in its place; giving both
  is an error.
- In the distribution view, a round rated by fewer than three experts is
  marked as no decision. It was drawn as “Met the criterion” when the
  two who rated it agreed, against the fit’s own “Insufficient panel”.
- The stability view scales a chi-square on its own axis. The ticks
  stopped at 1 while the statistic ran to 30, so the figure could not be
  read. The share who kept their rating is drawn only beside the
  statistics that share its 0 to 1 scale. Round-pair labels are placed
  at their own positions; they were swapped when the first item entered
  late.
- The printout no longer says the consensus threshold was “fixed before
  the study”. It says the threshold was supplied, and that Diamond et
  al. (2014) recommend fixing it in advance. Their 75% median is
  described as what it is: the median among the 25 reviewed studies that
  defined consensus as a percentage of agreement.
- The kappa caveat states the interval level in use. It said “their
  stated 95%” under a 90% interval.
- Holey et al. (2007) are cited for what they found: the statement
  nearly all their experts agreed with had the lowest kappa between
  rounds 1 and 2, and one of the highest between rounds 2 and 3. The
  general point, that kappa can be low when ratings concentrate in one
  category, is cited to Feinstein and Cicchetti (1990), who showed it
  for kappa on two categories. The key no longer calls the consensus
  threshold “preset”.
- [`summary()`](https://rdrr.io/r/base/summary.html) of a Delphi fit
  names the items without consensus and those with too few experts
  beside their counts, names the stability statistic in words, and ends
  with the same caution as the printout.
- [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  heads the Delphi stability column with the statistic it holds, and
  reports a chi-square with its leading zero and its degrees of freedom.
- [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
  opens with its verdict: how many units changed status.
- A consensus threshold such as 2/3 prints as 66.7%, not 66.66667%, in
  the header, the figure, the handoff and each item’s interpretation,
  whatever the session’s `digits` option. An interpretation could read
  “67% agreed, against a threshold of 67%” for an item just short of it.
- In the distribution views, a rating between two scale points is drawn
  on the side of the cut where the rule counts it. A 2.5 was rounded up
  into the relevant side, so the bar read 1.00 beside an I-CVI of .83.
- The Delphi vignette restores the option it changes.

### Construct rating: values that change

- **An index from one judge stays out of the scale means.** An item with
  fewer than two judges who rated it against every construct is
  `"Insufficient data"`, yet its HTD, from that one judge, was averaged
  into its scale’s mean and could move the scale’s Colquitt band. Each
  scale mean of
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
  now uses the items whose index rests on at least two judges. HTC rests
  on every judge who rated the item against its intended construct, so
  such an item usually stays in mean HTC and leaves mean HTD only. In
  `scale_summary`, `n_htc` and `n_htd` now count the items in each mean,
  and `results` gains `n_target`, the judges behind HTC. Unlike the item
  sort, this does not depend on alpha.
- **Judges whose ratings run exactly parallel give `F = Inf`.** When
  every judge’s ratings differed across the constructs by the same
  amounts there is no error variance. Rounding left a sum of squares
  near 1e-15 where it should be 0, so the test printed an *F* in the
  quadrillions with degrees of freedom “corrected” by an epsilon built
  from that noise, and the contrasts a *t* of the same size. The error
  is now treated as zero: *F* and the contrast *t* are `Inf`, *p* is 0,
  no sphericity correction is reported, and the printout and the help
  say what happened. When every rating is the same, *F* and *p* are `NA`
  as before.
- **`max_contrast_p` is `NA` when a contrast has no *p*.** When every
  judge rates the intended construct and another the same, that contrast
  cannot be tested and fails. The largest *p* was taken over the other
  contrasts, so an item could show an omnibus *p* and a contrast *p*
  that both met alpha beside a `"Review"` decision. The value is now
  `NA`, and the printout and the handoff note say which constructs tied.
- **Leading and trailing spaces in labels are ignored** in item, judge
  and construct labels and in the names of `target_map`, as in the item
  sort. Names of `target_map` that are the same once trimmed are an
  error.
- **Items are listed in the order of the data,** or of the levels when
  the item column is a factor, in
  [`htc()`](https://juhalt.github.io/contentvalidR/reference/htc.md),
  [`htd()`](https://juhalt.github.io/contentvalidR/reference/htd.md),
  [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
  and
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md).
  They were sorted as text, so Q10 came before Q2. The rows of
  `scale_summary` follow the order in which each scale first appears.
  Item names in `results` are always text.

### Construct rating: other fixes

- **The test is credited to its sources.** The printout and the handoff
  credited the repeated-measures ANOVA with planned contrasts to Hinkin
  and Tracey (1999). They proposed the rating task and analyzed it with
  a one-way ANOVA and Duncan’s multiple range test. The
  repeated-measures ANOVA followed, when its *F* is significant, by a
  planned contrast is MacKenzie et al.’s (2011) recommendation for that
  task. The help for
  [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
  now says which details are published and which are this package’s
  choices (the Greenhouse-Geisser screening *p*, one one-sided contrast
  for each orbiting construct with every one required, no adjustment by
  default, the two-judge minimum, and Welch contrasts in a between-judge
  design). The printout says “Adapted from Hinkin & Tracey (1999) and
  MacKenzie et al. (2011)”, the `rule` text in the handoff says the same
  and names both conditions, and its `citation` adds MacKenzie et
  al. (2011). The numbers are unchanged.
- **HTD is defined as what it is.** The key and the glossary said HTD is
  the lead over the closest rival. It is the intended construct’s lead
  averaged over every other construct, as in Colquitt et al. (2019); the
  closest rival is reported beside it. The range of HTC is given as 1
  divided by the number of scale points to 1 (.20 to 1 on a five-point
  scale); it said 0 to 1.
- The printout of
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
  states its rule and its alpha: Retain means the omnibus *p* and every
  contrast *p* are at or below alpha. The meaning of “Retain” in the key
  names the omnibus test too.
- [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
  prints whole degrees of freedom as whole numbers, “F(2, 14)”, and
  mentions the Greenhouse-Geisser correction only when it changed them.
  With two constructs it printed “F(1.00, 7.00)” under a note about
  fractional degrees of freedom. A missing *F* test prints “–”.
- [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  on a construct-rating fit shows the *F* test, with the degrees of
  freedom its *p* was read from. To keep the table within 80 columns it
  no longer shows the closest competitor; that and partial eta-squared
  are in `format = "data.frame"`, whose new columns sit before
  `p_value`, so read its columns by name. `results` gains `df1_gg` and
  `df2_gg`, the corrected degrees of freedom, after `epsilon_gg`.
- The profile figure draws both ends of each gap from the judges with
  complete ratings, the judges the tests use. The target end used every
  rating, so with missing ratings a gap could point the wrong way for
  its own decision. An item without a decision is marked with a cross
  and has no gap, and the legend lists only what is drawn.
- For expert judges, the scale tables of
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
  and
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  leave out the level columns and the benchmark set, which were printed
  as columns of `NA` under a named benchmark set that was not applied,
  and are headed “means”, not “Colquitt benchmarks”.
- An item whose every contrast passed but whose omnibus test did not is
  told so, with the new `issue` text “Every contrast met, omnibus test
  not met”. Its advice pointed at “the weakest target-orbiting
  comparison”, which had passed. With two constructs this is the usual
  way to miss: the one-sided contrast *p* is half the omnibus *p*.
- In the handoff, the `p_value` of a construct-rating item is the
  omnibus *p*. For an item that meets it and is held back by a contrast,
  the `note` on that row now says so, with the largest contrast *p* or
  the constructs that tied; a missing *p* carries a note saying why.
  With `adjust = "holm"`, the rule and the note say the contrasts were
  Holm-adjusted. No column or statistic is added.
- [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
  prints the alpha and the adjustment its contrasts were judged at, and
  says they are one-sided. Its help describes the columns of the
  contrast table, including that `dz` is Cohen’s *d* with the pooled
  standard deviation in a between-judge design. The help page is titled
  for what it runs, a repeated-measures ANOVA.
- A single `orbiting_r` named for a construct other than the one target
  is an error in
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
  and
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md).
  It was applied to the target whatever its name said.
- When a scale’s means leave items out, a sentence under the table says
  how many items are in each. The columns “with HTC” and “with HTD” are
  gone.
- “Incomplete judge profiles occurred for 1 item-judge profiles” now
  reads “1 item-judge profile was incomplete”, and the sentence says
  which statistics use which judges. “0 of 1 items meet” reads “0 of 1
  item meets”, and “1 of 3 items meet” reads “1 of 3 items meets”.
- The help for `adjust` no longer calls unadjusted contrasts
  “historical”: Hinkin and Tracey (1999) used Duncan’s test, not planned
  contrasts.
- [`?htd`](https://juhalt.github.io/contentvalidR/reference/htd.md)
  gives the full reference for Colquitt et al. (2019). Colquitt et al.
  (2014), no longer cited on any page, leaves the reference lists.
- Label handling is faster on large data with numeric identifiers: each
  distinct value is converted once.

### Judges, domain and structure: values that change

- **An item one judge from the criterion no longer flags its judges.**
  With five of six judges rating an item relevant, removing any of the
  five changes the item’s CVI status, so all five were `"Influential"`
  and flagged for review, and the lone dissenter was the only
  `"Typical"` judge. On a panel of three every judge was `"Influential"`
  for every item, because one judge fewer leaves no criterion at all.
  [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
  now reports such items in their own table, with the judges whose
  removal changes each one, and flags no judge for it. An item rated by
  three or fewer judges is “not checked”. `"Influential"` is no longer a
  decision, `scale_summary` loses `n_influential` and gains
  `n_items_unchecked`, and `details$influence_items` gains `n_raters`,
  `n_relevant` and `changes_without`. Such an item sits at the criterion
  or one short of it, depending on the panel size.
- **Fit statistics flag a judge only above the range, and only with
  enough decisions.** Infit or outfit outside 0.5 to 1.5 sent a judge to
  review either way. That range is Linacre’s (2002) guide to how
  productive data are for measurement: below 0.5 is “less productive for
  measurement, but not degrading”, and misfit distorts the measurement
  only above 2.0. On six to ten items, a third to a half of judges who
  fit the model exactly fell outside it by chance. A judge below the
  range is now described and not flagged (`"Too predictable"` is no
  longer a decision), and a judge above it is `"Erratic"` only when the
  model scored at least `fit_min_ratings` of their decisions (default
  30). With the item counts usual in content validation the fit
  statistics are shown and not flagged, and a judge above the range on
  too few decisions is named with the number scored. Linacre is cited
  only for his own bounds; a `fit_range` set by the analyst is called
  that.
- **Logit severity is corrected by the number of judges.** Joint maximum
  likelihood stretches the judge severities by about J / (J - 1), with J
  the number of judges behind each item parameter. The correction
  multiplied by (L - 1) / L with L the number of items, which left
  nearly all of the stretch in place on a small panel: about 1.4 times
  too large with four judges. It now uses the judges who rated each item
  (their mean over the items when ratings are missing). Printed logits
  change: smaller when the model holds fewer judges than items, slightly
  larger when it holds more. Standard errors are scaled by the square
  root of the factor, as the Facets documentation describes. Applying
  the Wright and Douglas (1977) correction to judges is labeled as this
  package’s choice, with Wright’s
  1988. note that it is inexact for very short tests.
- **With missing ratings a judge is compared on the items they rated.**
  A judge who rated only the low-rated items, exactly as everyone else
  did, was flagged `"Severe"`. Severity in rating points and scale use
  now compare each judge with the panel on the same items. With complete
  ratings the values are computed as before.
- **A judge exactly at a cut is not flagged.** Severity and scale use
  are compared with their cuts allowing for rounding error in the last
  digit, so a judge printed at 0.75 beside “exceeds 0.75” is no longer
  flagged.
- **[`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md)
  clusters the map coordinates.** It named the procedure of Sireci and
  Geisinger (1992, 1995), who clustered the items’ scaling coordinates,
  but clustered the original dissimilarities, so the number of
  dimensions never affected the clusters or the adjusted Rand index. It
  now clusters the coordinates on the retained dimensions with average
  linkage (this package’s choice; the sources checked do not state their
  linkage). Clusters, the adjusted Rand index and the status can change,
  and now depend on `dims`. The help says what still differs from their
  procedure.
- **A one-cell blueprint, or one cluster, has no adjusted Rand index.**
  It was .00 and “Review: correspond only weakly”. It is `NA`, with
  status `"Insufficient data"`, because nothing can be compared.
- **The map’s fit is no longer called Kruskal’s stress-1.** The
  statistic compares the map’s distances with the dissimilarities;
  Kruskal’s (1964) stress-1 belongs to nonmetric scaling and is computed
  differently. It keeps its value and its name in the object, `stress`,
  is printed as “distortion”, and loses the labels “good”, “fair” and
  “poor”, which were his benchmarks for a different quantity. The `fit`
  table loses `fit_label`. The goodness of fit, `gof`, is described as
  the share of the sum of the absolute eigenvalues, which is what it is.
- **[`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md)
  with `targets`.** A cell far below its intended share was `"Covered"`:
  it is now `"Under-represented"` when its share is below the expected
  share divided by `over_factor`. A cell that met a target of one item
  was `"Thinly covered"`: the minimum is now the smaller of `min_items`
  and the cell’s target (rounded up), and the printed criteria say so. A
  cell named in `targets` that holds no item was left out, and its
  target with it; it is now reported as `"Not covered"`. With `domain`,
  a target for a cell not in `domain` is an error. Without `targets`
  nothing changes.
- **[`similarity_from_sort()`](https://juhalt.github.io/contentvalidR/reference/similarity_from_sort.md)
  keeps the items in the order of the data.** It sorted them. A
  `membership` vector built by position to match the old sorted order is
  now misaligned, so name it by item.
- **[`reproducibility_phi()`](https://juhalt.github.io/contentvalidR/reference/reproducibility_phi.md)
  and
  [`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md)
  report Fisher’s exact *p* when an expected count is below 5.** They
  printed a chi-square *p* with R’s warning suppressed, on tables of six
  to twenty items: .121 where the exact *p* is .333. `p` is now the
  exact *p* in that case, `p_method` says which test it is, and
  `p_chisq` keeps the chi-square *p*.

### Judges, domain and structure: other fixes

- The cuts behind a status are arguments, printed beside it and labeled
  as contentvalidR conventions: `phi_cut` in
  [`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md)
  (.80), `ari_cut` in
  [`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md)
  (.60), and `differentiation_cut` and `fit_min_ratings` in
  [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md).
  No published standard sets them. A cut the analyst sets is printed as
  “set for this analysis”, and a value that rounds to its cut gets a
  third decimal (“.797, below the .80”).
- `gtheory_content(max_judges = 1)` no longer stops with “wrong sign in
  ‘by’ argument”.
- [`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md)
  states its coefficient against the criterion. It called any Phi below
  .80 “moderately” generalizable, .31 included. When no item variance is
  found, the text says where the variance is; it said both coefficients
  are 0 when one is undefined. A design too small to analyze prints its
  reason without an empty variance table.
- The projected panel sizes are described as estimates from one panel,
  in the printout, the help and the README, which said the question is
  “answered exactly”.
- A named `membership` whose names do not match the items is an error.
  It was read by position, so one typo reordered the blueprint.
- Equal similarities, repeated judge or item names, and a matrix with no
  rows stop with a message that says what is wrong.
- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) on a content
  structure accepts `xlab`, `pch`, `xlim` and the like: they replace the
  method’s own. A `pch` or `col` with one value per cell is applied by
  cell and kept in the key. A map with one dimension keeps its symbols
  and legend.
- [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
  prints the scale and the relevance cut, the number of missing ratings
  and how many judges Phi rests on (in
  [`summary()`](https://rdrr.io/r/base/summary.html) too), “not
  estimable” where it printed `NA%`, and one judge as “Insufficient
  data”, with nothing after the verdict. `results` gains `n_scored`, the
  decisions the facets model scored for each judge.
- [`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md):
  `scale_summary` gains `n_under` and `settings` gains `over_possible`;
  a cell named twice in `targets` stops; item labels in `similarity` are
  trimmed like the assignments.
  [`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md)
  accepts a factor `membership`.
  [`reproducibility_phi()`](https://juhalt.github.io/contentvalidR/reference/reproducibility_phi.md)
  and
  [`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md)
  return `n` and `p_method` (`NA` when no test can be run), and no
  longer fail on tables of more than about 430 items.
- [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
  ignores the settings the data decide (`bias_correction`,
  `over_possible`), so two rounds analyzed alike stay comparable.
- Judge objects saved before 1.0 print and summarize again.
- [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  for judges shows logit severity, infit and outfit, and drops the count
  of flipped items.
- `chi-square(1, N = 60) = 41.71`: the two-by-two comparators print the
  sample size with the degrees of freedom, as APA asks.
- [`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md)
  says when no cell can be flagged as over-represented (two equal cells
  at the default factor), and its key no longer defines “stress”, which
  that printout does not show.
- [`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
  says its loadings are unrotated and how that differs from the
  published approach. The message about Kaiser’s rule is wrapped.
- [`similarity_from_sort()`](https://juhalt.github.io/contentvalidR/reference/similarity_from_sort.md)
  compares labels as trimmed text;
  [`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md)
  trims cell and item labels.
- The examples for
  [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
  and
  [`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md)
  now show the logit columns and a two-dimensional map whose nine items
  are all visible.
- [`?domain_validity`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md)
  says its structure analysis is adapted from Sireci and Geisinger
  (1992, 1995), as
  [`?content_structure`](https://juhalt.github.io/contentvalidR/reference/content_structure.md)
  does.
- A congruence plot without a target mapping stops before it opens a
  graphics device, so the failed call leaves no empty `Rplots.pdf`.

### Congruence and method attribution: values that change

- **[`ioc()`](https://juhalt.github.io/contentvalidR/reference/ioc.md)
  returns the published index.** Its `ioc` column held each objective’s
  mean rating, which applied work often reports as “the IOC” but which
  reaches 1 whenever every expert gives +1 to the objective, whatever
  they say about the others. It is now the index of Rovinelli and
  Hambleton (1977): half the gap between the mean rating on the
  objective and the mean on the item’s other objectives, 1 only when
  every expert gives +1 to the objective and -1 to every other. The mean
  is kept as `mean_rating`, beside the index in the print, and
  `n_objectives` is added. The index is `NA` for an item rated against
  one objective, because it compares objectives. Items and objectives
  keep the order of the data. With missing ratings each objective’s mean
  counts once, the package’s own handling of an incomplete design, which
  [`?ioc`](https://juhalt.github.io/contentvalidR/reference/ioc.md) and
  the printout say.
- **Congruence decisions use the index and a criterion.** An item was
  `"Target favored"` when the mean on its target beat the mean on every
  other objective, or `"Tie / review"`, so a mean of .25 against -.25
  passed. It is now `"Congruent"` when its index for the target
  objective reaches `ioc_cut`, by default the .70 Rovinelli and
  Hambleton applied, and `"Review"` otherwise; `"Target described"` when
  only the target objective was rated. `results` holds `target_ioc` (the
  index), `target_mean`, `competitor_mean` and `margin` (the gap between
  the means, a description beside the index), with `n_judges`;
  `competitor_ioc` is gone. A criterion set with `ioc_cut` is printed as
  set for the analysis; only .70 is credited to Rovinelli and Hambleton.
  Because the index averages over every other objective, an item can
  meet it while one rival is rated as high as the target; its
  interpretation then says so.
- **Congruence fits saved before 1.0 are not read as the index.** Their
  `target_ioc` held a mean. They still print, with a note, but
  [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md),
  [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  and [`plot()`](https://rdrr.io/r/graphics/plot.default.html) stop and
  ask for a new fit, since anything else would present a mean as the
  index.
- **Congruence without a target mapping has one row per item,** as every
  item-level table does: the objective the item matched best and its
  index. The item-by-objective table is in `details$cells`, and the
  printout shows it.
- **The congruence handoff carries the index.** Its statistics are
  `target IOC` (the index, with `ioc_cut` as the criterion),
  `target mean rating` and `competitor mean rating` (its note names the
  objective); `competitor IOC` and `IOC margin` are gone. Without a
  target mapping each item carries `highest IOC`, its note naming the
  objective.
  [`content_evidence()`](https://juhalt.github.io/contentvalidR/reference/content_evidence.md)
  shows `target IOC`. The schema is unchanged.
- **The relevance decision `"Support"` is gone.** Every count that meets
  Lynn’s criterion puts modified kappa above .74 (the lowest is .76, at
  7 of 9), so an item meeting the criterion always had
  `"Strong support"` and `"Support"` could not occur. `scale_summary`
  loses `n_support`.
- **No “overall” strength in the item-sort and construct-rating
  summaries.** `overall_strength` was the weaker of the two Colquitt et
  al.
  2019. levels, a combination they do not publish. It is gone from
        `scale_summary`, the printouts and the summary tables; the two
        levels stay, each against its published benchmark.

### Congruence and method attribution: other fixes

- Lynn’s (1986) table stops at ten experts. Beyond it the package holds
  her lowest tabled proportion, 7 of 9, and now says that this is its
  own extension wherever it applies it: the relevance printout and its
  closing line and figure legend, the handoff rule (whose citations then
  also include Polit & Beck, 2006, who restate her rule as no lower than
  .78 for six or more experts, though their own recommendation covers
  six to ten), the
  [`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md)
  printout, the fragile-item note of
  [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md),
  the glossary, the help pages and both vignettes. With mixed panel
  sizes the relevance printout now states the criterion it applies.
- [`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md)
  is described as a contentvalidR planning tool, not a published method.
- The Colquitt et al. (2019) bands carry a caution, labeled as this
  package’s own, when judges saw a number of definitions other than
  three: every one of their 112 scales was sorted into, or rated
  against, its own definition and two orbiting ones, and they did not
  examine other numbers. In a sort the count is `n_constructs`, or the
  constructs judges used when it is not given; in ratings it is the
  constructs each scale’s items were rated against, so two focal scales
  with two orbiting constructs each get no caution. The caution is
  printed under the benchmark table too, and `scale_summary` gains
  `n_definitions`.
  [`?colquitt_benchmarks`](https://juhalt.github.io/contentvalidR/reference/colquitt_benchmarks.md)
  describes their design.
- The relevance handoff rule says that meeting the criterion also puts
  modified kappa above .74, in place of a separate kappa rule.
- Verdicts agree in number in every workflow: “1 of 3 items meets the
  exact essentiality criterion.”
- [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  for congruence shows the experts, the index, both means and the
  margin.
- [`?expert_validity`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  cites Rovinelli and Hambleton (1977) and Turner and Carlson (2003),
  and documents `ioc_cut`; the expert-panel vignette cites Turner and
  Carlson too.
- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) for
  congruence shows each item’s index against the criterion line, with
  the two mean ratings below it in gray and a cross for an item with no
  index; the legend gives the criterion’s value.
- When every item was rated against its target objective only, the
  printout says so; it said no target objective was supplied.
  [`summary()`](https://rdrr.io/r/base/summary.html) explains its
  congruence columns, and the handoff names tied rivals as “Objectives
  B, C.”.
- The reporting vignette’s congruence guidance reports the index against
  its criterion, with the means and margin as description.

### Keys, help pages, figures and tables: values that change

- **Report intervals are named after their estimates.**
  [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  returned two columns both named “95% CI” in a relevance report, so
  `tab$"95% CI"` found only the first. Every interval column is now
  named after its estimate (`Psa 95% CI`, `V 95% CI`, `I-CVI 95% CI`),
  and the printed table and the Markdown head it “95% CI”, beside that
  estimate. A column the user renames prints under the new name.
- **[`plot()`](https://rdrr.io/r/graphics/plot.default.html) takes
  `xlab`, `ylab`, `xlim`, `ylim` and `main` everywhere.** Most plot
  methods set these themselves and also passed `...` on, so giving one
  stopped with “formal argument matched by multiple actual arguments”.
  An argument the caller gives now replaces the method’s own, except
  those the figure’s encoding depends on: the frame type, the axes the
  method draws, and the decision symbols a map’s legend keys. A `NULL`
  leaves the method’s value, and an unnamed argument is dropped with a
  warning. In the distribution views and the evidence profile a title is
  drawn once, above the legend, and the item labels take the place of a
  y-axis label.
- **Long item names no longer stop a figure.** The distribution views
  and the evidence profile sized the label margin to the longest name,
  and a long one left no room to draw (“figure margins too large”).
  Labels are measured on the device; one wider than 40% of the width
  left for labels is shortened in the middle, keeping its start and end,
  so names that share an opening stay apart.

### Keys, help pages, figures and tables: other fixes

- [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) works
  on every result:
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md),
  [`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md),
  [`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md),
  [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md),
  [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md),
  [`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md),
  [`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md)
  and
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
  had no method, and
  [`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md),
  [`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md)
  and
  [`reproducibility_phi()`](https://juhalt.github.io/contentvalidR/reference/reproducibility_phi.md)
  gave two to four rows for one test. A result holding several tables
  takes `component`; a single test is one row, with an interval as two
  columns and a two-by-two table as four named counts. The agreement row
  names the interval’s error rate `ci_alpha`, and the binomial row marks
  its interval one-sided. See
  [`?"contentvalid-data-frames"`](https://juhalt.github.io/contentvalidR/reference/contentvalid-data-frames.md).
- The key said modified kappa falls below 0 “when agreement is below
  chance”. It does so only when no expert, or one of three, rated the
  item relevant: 2 of 8 gives .16.
- The relevance key defines S-CVI/Ave and S-CVI/UA, which the header
  prints.
- With `agreement = "ac1"`, the key describes AC1, which is not 0 for
  independent raters and stays high when ratings concentrate; it
  repeated the Krippendorff caution that the coefficient “can be low
  when nearly every rating is the same”. The generic agreement entry now
  describes Krippendorff’s alpha alone.
- The glossary said judge severity is in logits when the model is
  estimable. Its terms now follow the `results` columns: `severity_raw`,
  printed as severity, in rating points, and `severity`, printed as
  logit, from the facets model on the relevant/not-relevant decision,
  which can differ even in sign. The key gives both.
- The domain decision meanings state the rules: more than `over_factor`
  times the expected share, and less than the target share divided by
  it.
- Three-author works are cited with “et al.” in the
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md)
  printout and help, the legacy sort printout and
  [`?sort_validity`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  (Yao et al., 2008), the item-sort and reporting vignettes, and
  DESCRIPTION; “p value” is no longer hyphenated; article numbers read
  “Article 93”.
- Help pages cite every work they list, by author and date: the interval
  methods in
  [`?compute_psa`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md),
  Colquitt et al. (2019) in
  [`?htd`](https://juhalt.github.io/contentvalidR/reference/htd.md),
  Hinkin and Tracey (1999) in
  [`?htc`](https://juhalt.github.io/contentvalidR/reference/htc.md),
  Aiken (1980) in
  [`?aikens_v`](https://juhalt.github.io/contentvalidR/reference/aikens_v.md),
  Howard and Melloy
  2016. in
        [`?simulate_csv_power`](https://juhalt.github.io/contentvalidR/reference/simulate_csv_power.md)
        and
        [`?sort_power`](https://juhalt.github.io/contentvalidR/reference/sort_power.md),
        Feinstein and Cicchetti (1990) and Wongpakaran et al. (2013) in
        [`?panel_agreement`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md),
        and Penfield and Giacobbi (2004), Polit et al. (2007), Hayes and
        Krippendorff
  2017. and Zapf et al. (2016) in
        [`?expert_validity`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md);
        the expert-panel and reading-output vignettes likewise.
- [`?contentvalidR`](https://juhalt.github.io/contentvalidR/reference/contentvalidR-package.md)
  promised [`plot()`](https://rdrr.io/r/graphics/plot.default.html) for
  all six workflows; judge and domain fits have none, and it now says
  how to draw a domain fit’s content map when similarity data were
  supplied.
- The reporting vignettes build their tables with
  [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  rather than from raw `results` columns, and point to the strongest
  competitor and the scale-level CVIs, which those tables leave out.
- `reading-output` says what `Strong` means: the 60th to 79th percentile
  of the scales Colquitt et al. (2019) collected, not “typical of
  published work”.
- The walkthrough says seven items, not five, each set a test for one
  stage; that the fifteen assignments follow from the null probability
  of .50, not from “two plausible answers”; calls `csv` the substantive
  validity coefficient; and no longer says the judges “never
  considered”, or “saw only one of”, the facets of an item four of them
  sorted elsewhere.
- The handoff vignette’s nomologR install line names CRAN as well as
  R-universe, so it works in a fresh library.

### Output style shared with nomologR

The printouts of contentvalidR and nomologR now follow one style, agreed
between the two packages (JUhalt/nomologR#144), so a researcher moving
from content review to empirical validation reads both alike. No stored
number or handoff column changes, and
[`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
gains one field, `n_pairs` (the number of rating pairs behind the share
of identical pairs). The few stored sentences that state a rounded
number or a *p* value now follow the same rules (listed at the end), and
two plot methods gain `type`.

- **Headers.** Every printout opens with the object’s class and a
  plain-language title on one line, with no rule beneath:
  `<contentvalid_sort> Item-sort analysis`; a summary’s tag ends in
  “summary”.
- **Numbers.** Values round half away from zero for display, so 5 of 8
  prints .63, where R’s own rounding gave .62 beside 3 of 8 as .38. A
  value that could not be computed prints “–”, never “NA”. A *p* value
  that would print 1.000 prints “\> .999”. Percentages are whole numbers
  on a base under 100 and carry one decimal on a larger base; the share
  of identical rating pairs follows the same rule, on the number of
  pairs. Delphi interpretations keep one decimal where a share is not
  whole (12.5% of 8 experts), as their stored text always has. Results
  objects keep full precision.
- **Prose** wraps at 79 columns, and so do the keys, the decision
  legends and the glossary. It never breaks inside “p \< .001”, “Phi \>=
  .80”, “N = 40”, “F(2, 14) = 3.21” or an interval.
- **Tables** are indented two spaces, with text left-aligned, numbers
  right-aligned and headings in sentence case; a heading that is data,
  such as an item ID or a round label, keeps its case. A column empty in
  every row is dropped, unless a decision rests on it. A table too wide
  for the console tightens its columns, then drops trailing ones and
  names them with the call that shows them. It never drops the item, its
  decision, the statistic or test the decision rests on, or the
  statistic a component exists to show; a table with nothing else to
  drop prints wider than the console. Different Colquitt benchmark sets
  are named for their targets beneath the scale-level table. The
  item-sort, Delphi and relevance keys leave out a column the table did
  not show. The item similarity matrix prints in blocks of columns that
  fit the console, with its diagonal blank.
- **Sections** indent their content; summaries list flagged units in a
  “Flagged” section, one bullet per unit with a complete sentence, “- B2
  (Review): …”, and define the abbreviations they show. A workflow’s
  printout ends with what the evidence does not decide, and every
  printout ends with one line pointing to what else the object holds
  (“See summary(x) for the flagged items …”; a summary points to its own
  fields, such as `summary(x)$reviewed_items`). Markdown output from
  [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  prints only the lines to paste.
- **Status words.** The handoff and
  [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
  printouts say what the shared status words mean in the workflow’s own
  terms (“Supported is this analysis’s passing decision (Retain)”);
  [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
  keeps the expert-panel `mode` for this. The expert-panel summary
  counts its own decision word (“Strong support: 3 of 5”).
- **Errors** for a wrong choice name the argument and the choices:
  `` `format` must be one of "apa", "data.frame", or "markdown", not "latex". ``
  As with [`match.arg()`](https://rdrr.io/r/base/match.arg.html), `NULL`
  still selects the default.
- **Plots.** Every plot method takes `type`. For the content map and the
  expert power curve the argument is new, so a `type` passed through
  `...` to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html) is
  no longer accepted there. A dashed line marks a reference value, and
  the legend names it.
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) on a judge,
  domain or round-comparison result, which have no figure, stops with a
  message saying so (and, for a domain result with similarity data, how
  to draw its content map) instead of a base-graphics error.
- **Manuscript tables.**
  [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  prints under a header and adds the APA general note: the abbreviations
  in the order the columns show them, a definition of each column whose
  heading alone does not say what it holds, the interval method
  (including the Penfield-Giacobbi interval for V when I-CVI has none),
  any Holm adjustment, the criterion behind the decisions, and “– = not
  computed” when a cell is missing. Judge and domain tables now state
  their criteria, as contentvalidR conventions, and the domain table
  shows each cell’s expected share. Headings are shown in sentence case;
  the names of the returned columns do not change. In Markdown the note
  reads “*Note.* …”, the symbols *p*, *F*, *V*, *n* and *N* are italic,
  and a value that could not be computed is an em dash.
- **Wording.** Published rules are “criteria”, not “cutoffs”; tests are
  “one-sided” throughout; `reverse_keyed` messages say “reverse-keyed”;
  the expert item tables head the per-item count “Experts”;
  earlier-method verdicts read “Meets” and “Below”; both Colquitt
  sections are headed “Scale-level”; closing caveats speak of “a flag
  for review” rather than quoting a label the printout may not show. The
  evidence headline names every stage that held an item back, and an
  agreement interval with no width (every resample gave the same value)
  is said in words.
- [`?contentvalidR`](https://juhalt.github.io/contentvalidR/reference/contentvalidR-package.md)
  and the “Reading the output” article describe the conventions and give
  the crosswalk between the statuses of the two packages.

Stored text that changes so that it matches the printout:

- `content_report(format = "data.frame")` rounds half up, like the APA
  table: 5 of 8 is 0.63 in both (exact ties only).
- A handoff note that gave a largest contrast *p* as “p = 1.000” now
  says “p \> .999”, whenever the *p* would print as 1.000.
- An interpretation that states a rounded value (the adjusted Rand index
  of a content map, Phi of a generalizability analysis, a Delphi
  consensus percentage) rounds half up on an exact tie; a Delphi rule in
  the handoff states its percentage the same way.
- A domain cell’s interpretation states its share as the table does: 13%
  for 1 of 8 (a tie), and one decimal on 100 or more items. An
  over-represented cell’s sentence gives its item count.
- The Markdown note of
  [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  wraps at 79 columns, so it spans several elements of the returned
  vector.

### Release housekeeping

- The lifecycle badge reads “stable”.
- DESCRIPTION names the Hinkin-Tracey correspondence and distinctiveness
  indices in full and credits them, with the benchmarks, to Colquitt et
  al. (2019); it cites MacKenzie et al. (2011) for the repeated-measures
  screening, says the content-structure analysis is adapted from Sireci
  and Geisinger (1992), and wraps at 80 columns.
- [`?cvi`](https://juhalt.github.io/contentvalidR/reference/cvi.md)
  typesets the modified kappa formula with I-CVI as one symbol, and
  gives a plain-text form of both formulas.
- Component printouts put their source on the line beneath the header,
  so every header fits in 80 columns; the help examples print no line
  wider than that, and the Markdown note of
  [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  wraps. The vignettes print narrow selections of their tables.
- [`?panel_agreement`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
  credits the irr package, against which the tests check Krippendorff’s
  alpha and Fleiss’ kappa; irr stays in Suggests.
- The release gate reads the date of the last CRAN release from
  `tools/cran-release-date` and ignores a malformed one.

### Other changes

- The reader in nomologR is now tested against handoffs from
  contentvalidR 0.6.0 through 0.10.1, and the README says so.

## contentvalidR 0.10.1

A documentation release. The README now documents the handoff to
nomologR in its own section, matching the one the nomologR README
carries for the handoff from contentvalidR, so either front page
explains how the two packages connect. Released on GitHub and
R-universe; CRAN keeps 0.4.0 until the joint 1.0.

**No computed value changes.** Across 25 analyses spanning every
workflow, every value 0.10.0 returns is identical in 0.10.1, and no
function, argument, or handoff field changed.

- The README has a section on the handoff to nomologR, just above the
  references: what a handoff carries, the two nomologR calls that read
  it, how to read its decisions, and how the schema is versioned. The
  nomologR README carries the mirror section, so the handoff can be
  found from either package’s front page.
- Krippendorff (2011) now links to the copy on the Annenberg School’s
  site, because the Penn repository copy had become unreliable to reach:
  it answered in 2 to 10 seconds, returned a server error, and timed
  out. It is the same paper, dated 2011.1.25, with its reading list
  updated in 2013. The expert-panel vignette’s reference list now gives
  the link too.
- The reader in nomologR is now tested against handoffs from
  contentvalidR 0.6.0 through 0.10.0, and the README says so.

## contentvalidR 0.10.0

Tenth public release, and the last planned before the joint 1.0 release
candidate on 2026-10-17. v0.10.0 adds figures for papers, posters, and
teaching: the item flow diagram and the item evidence profile of
[`content_evidence()`](https://juhalt.github.io/contentvalidR/reference/content_evidence.md),
and the full distribution of a panel’s ratings, each in APA gray or in
color. It also states the handoff contract nomologR reads, makes this
package’s walkthrough the joint one, and separates the Delphi printout’s
caveats from its teaching.

contentvalidR is on CRAN: 0.4.0 was published there on 2026-09-28. CRAN
asks for updates no more often than every one to two months, so 0.10.0
is released on GitHub and R-universe, and the next CRAN submission is
the joint 1.0.

The package continues to declare `Imports: stats` only.

**No computed value changes.** Across 25 analyses spanning every
workflow, every value 0.9.0 returns is identical in 0.10.0. Relevance
fits gain `details$ratings`. Some printed wording changes: the Delphi
printout’s method paragraphs move into its key,
[`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
prints within 80 columns, the printed handoff advises passing the whole
handoff to nomologR, and the `citation` a handoff carries for
`stability = "percent_change"` reads “Scheibe et al. (1975/2002)”.

**No breaking changes.** The plot methods gain arguments after their
existing ones: `type`, `apa`, and `labels` for expert-panel fits, and
`which = "distribution"`, `apa`, and `labels` for Delphi fits.
`agreement_summary()` remains deprecated and is removed in 1.0.0.

### Figures for papers, posters, and teaching

Each new figure draws what the fits and handoffs already decided, and
says whether it follows a published form or is this package’s own
design.

- **[`content_evidence()`](https://juhalt.github.io/contentvalidR/reference/content_evidence.md)
  (new)** brings the handoffs from several review stages together, such
  as a relevance panel and then an item sort. It prints one row per item
  with each stage’s decision beside the statistic its rule read, and
  draws two figures:
  - `plot(x, type = "flow")`, the item flow diagram, modeled on the
    PRISMA 2020 flow diagram (Page et al., 2021): what each stage
    reviewed, what it held back and the number behind each decision, and
    what went forward;
  - `plot(x)`, the item evidence profile, this package’s own design: one
    panel per stage with each statistic, its interval, and its
    criterion, so agreement and disagreement between methods can be seen
    item by item.
- **The distribution view** draws every rating behind an index as
  diverging stacked bars (Heiberger & Robbins, 2014), split at the cut
  the decision rule counts: `plot(fit, type = "distribution")` for a
  relevance panel and `plot(fit, which = "distribution")` for a Delphi
  study, one bar per round. It shows what the I-CVI cannot: two items at
  1.00, one rated relevant with 4s and the other with 3s. Relevance fits
  now keep their ratings in `details$ratings` to draw it.
- **`apa`** switches these figures between gray (`TRUE`, the default, as
  an APA figure is printed) and a colorblind-safe scheme for slides and
  posters (`FALSE`): teal for evidence that met its criterion, brown for
  evidence under review. Symbols carry the decision either way, so no
  reading depends on color.
- **A relevance panel for the walkthrough items**,
  `walkthrough_relevance.csv`, gives the twelve items a second source of
  content evidence.
  [`vignette("reporting-examples")`](https://juhalt.github.io/contentvalidR/articles/reporting-examples.md)
  uses it to show both figures, with a sample caption. The ratings are
  constructed, and a separate script,
  `data-raw/build-walkthrough-panel.R`, says what each is built to show.
  The three walkthrough files that nomologR ships are unchanged.
- The printed handoff and
  [`vignette("handoff-to-empirical-validation")`](https://juhalt.github.io/contentvalidR/articles/handoff-to-empirical-validation.md)
  now pass the whole handoff to nomologR,
  `nomo_screen(data, items = handoff)`, rather than `handoff$items`, so
  the keying and the reasons for anything held back travel with the
  items. The vignette no longer calls the handoff reader in nomologR
  future work.

### On CRAN

- **contentvalidR 0.4.0 was published on CRAN on 2026-09-28.** The
  README now gives `install.packages("contentvalidR")` first, carries a
  CRAN badge, and explains why CRAN’s version can trail the newest
  release on R-universe: CRAN asks packages to update no more than every
  one to two months.

### Finishing touches before 1.0

- **The Delphi printout separates what changes a reading from what
  teaches it.** Two short caveats always print: read kappa as a trend
  beside the share of experts who kept their rating, not against a
  cut-off; and with fewer than about 40 experts the kappa intervals
  cover less than their stated 95%. The fuller explanation (the weights,
  why kappa falls as a panel converges, Klar et al.’s coverage figures)
  now sits in the key under “How the stability statistic works”, so an
  instructor’s students see it and a researcher can hide it with
  `options(contentvalidR.show_key = FALSE)`. The critique printed for an
  alternative stability method still always prints. The example printout
  goes from 100 lines to 92, or 58 with the key hidden.
- [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
  prints within 80 columns. The strongest competitor, which
  [`htd()`](https://juhalt.github.io/contentvalidR/reference/htd.md) and
  the construct-rating workflow already show, stays in the
  `strongest_competitor` column.
- The website’s Articles menu lists every guide under a heading, in the
  order a course would use them: Start here, Workflow guides, Planning
  and reporting, and After content review. The workflow guides were
  hidden under “More articles”.
- **Scheibe et al. is cited from the edition the package’s method was
  checked against:** the editors’ 2002 web edition of Linstone and
  Turoff, with the chapter’s pages (257–281), a link, and “(Original
  work published 1975)”, as APA 7 requires for a republished work.
  In-text citations read “Scheibe et al. (1975/2002)”, including the
  citation a handoff carries for `stability = "percent_change"`. The
  1975 printing’s pages could not be checked.

### The handoff contract, stated for readers

Asked for by nomologR before handoff schema 1 becomes a 1.0 promise. The
schema and every handoff are unchanged.

- [`?content_handoff`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
  has a new section, “Reading the decisions”: take each item’s decision
  from `carried` and `status`, never re-derive it by comparing `value`
  with `criterion` or by branching on the producer version. The example
  is the nine-expert correction in 0.8.0, where an item’s I-CVI stayed
  at .778 while its decision changed. The section also restates that
  `keying` of `NA` means unknown, never forward-worded.
- [`?content_handoff`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
  says an item sits in at most one scale, the one its
  `item_evidence$scale` names. A test holds the sort, rating, and
  congruence workflows to it, and checks that each refuses an item with
  two targets.

### The joint walkthrough lives here

- [`vignette("one-item-set-both-stages")`](https://juhalt.github.io/contentvalidR/articles/one-item-set-both-stages.md)
  is the joint walkthrough for contentvalidR and nomologR, as the
  maintainer decided for the joint 1.0. It now says so, passes the
  handoff itself to `nomo_screen()` and `nomo_run()` rather than
  `h$items`, and links to the section of the nomologR guided workflow
  that continues from content review. Two stale sentences are corrected.
  The handoff reader in nomologR, which the vignette called future work,
  has shipped. And the nomologR guided workflow starts from the same
  handoff but simulates its own responses, so its screening numbers
  differ from these.
- The walkthrough links to the companion article in nomologR, “From
  content review to empirical screening”, which continues it on the same
  responses. nomologR ships the item and response files of the
  walkthrough unchanged, with the script that generates them.

## contentvalidR 0.9.0

Ninth public release. v0.9.0 is about how the package presents itself
before 1.0. Every reference list is in APA 7 form; printed output is
shorter and says what it means; the component functions and report
tables print in APA style; the figures show the criterion and the
uncertainty; and the README is a front page rather than a manual.

The package continues to declare `Imports: stats` only.

**No computed value changes.** Across 25 analyses spanning every
workflow, every value 0.8.0 returns is identical in 0.9.0. Some wording
changes: the scale-level summaries of the item-sort and construct-rating
workflows name the Colquitt band of the weaker index, counts read “1
item” or “3 items”, and the note when judge severity cannot be estimated
no longer blames near-total agreement when one dissenting judge causes
it.

**Breaking changes.**

- [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  writes an APA table by default. For the numeric table that used to be
  the default, pass `format = "data.frame"`; its *p* values now keep
  three decimals whatever `digits` is.
- The component functions’ results
  ([`compute_psa()`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md),
  [`aikens_v()`](https://juhalt.github.io/contentvalidR/reference/aikens_v.md),
  [`cvr()`](https://juhalt.github.io/contentvalidR/reference/cvr.md),
  and eleven others) gain a class, so they print as formatted tables.
  Every value is unchanged and
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
  the plain data frame; only code that tests `class(x) == "data.frame"`
  exactly would notice.

**Deprecated.** `agreement_summary()` warns and will be removed in
1.0.0; use
[`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md),
which takes raters in rows like every other ratings function.

New: `content_report(format = "apa")`, and
[`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md)
returns its inputs (`n_target`, `N`, `p0`, `alpha`) beside its result.

Published on GitHub and R-universe. 0.4.0 is still in CRAN’s review
queue, and CRAN policy asks that no further version be submitted while
one is pending.

### A README that is a front page

- **The README is a front page rather than a manual.** It ran to about
  1,400 lines of printed output: every workflow in full, the component
  functions, and six copies of the key. It now shows one first analysis
  (the printout, its APA table, and its plot), a table matching each
  question put to judges or experts to its workflow, the sources it is
  built on, and its guide, then how to read the output, what every
  workflow returns, and what you can rely on. The worked examples it
  held live in the vignettes.
- [`vignette("design-and-reporting")`](https://juhalt.github.io/contentvalidR/articles/design-and-reporting.md)
  gains the planning examples the README held:
  [`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md),
  with why a fourth or fifth expert lowers the chance of clearing Lynn’s
  criterion, and
  [`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md),
  with how many judges a design would need. Its method list now names
  all six workflows, and it has a reference list.

### Plots show the criterion and the uncertainty

No computed value changes; this is about what the figures draw.

- **The item-sort Psa plot draws each item’s interval, and a dashed mark
  at the share of judges the exact test needs for that item**, so an
  item is retained when its point reaches its mark. It used to show bare
  points.
- **The expert relevance plot shows Aiken’s V and I-CVI side by side,
  each with its interval**, and a dashed line at the I-CVI criterion
  when every item had the same number of experts (“I-CVI criterion (5 of
  6)”). Before, only V had an interval, and an I-CVI point could hide
  behind V’s.
- **Legends list only what the figure draws** and sit in headroom above
  the data. The item plots offered a “No data” symbol no item used, the
  profile plot a “Review gap” line it had not drawn, and the
  essentiality key sat on its own zero line. The content map’s key is
  titled “Cluster” or “Blueprint cell”, where it showed bare numbers.
- **Axis labels say what is measured** (“Psa: share of judges choosing
  the target”) in place of “Psa correspondence”, and axes for statistics
  that cannot exceed 1 are labeled as APA prints them (.25, .50). No
  figure leaves an empty band for a title unless `main` is given, and
  each restores the graphics settings it changes. Item rows run top to
  bottom in the order of the results table, and scale means are
  triangles, clearly distinct from retained items.
- **Every figure in the README and the vignettes has alt text**
  describing what it shows; 17 of 19 had none.

### Shorter keys, formatted components, and APA report tables

No computed value changes; this is about what is printed.

- **The key under each result explains only what it shows.** It ran 12
  to 36 lines and was often longer than the results. Each column now
  gets one line after its full name, and “What the decisions mean” lists
  only the decision words that appear, saying what each means in that
  workflow (“Retain – met the exact target-assignment criterion”). The
  old legend listed all four shared statuses and left readers to match
  Retain or Typical to them.
  [`contentvalid_glossary()`](https://juhalt.github.io/contentvalidR/reference/contentvalid_glossary.md)
  keeps the full definitions and now lists every workflow’s decision
  words. The item-sort example in the README prints 58 lines instead of
  71.
- **The component functions print as formatted tables.**
  [`compute_psa()`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md),
  [`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md),
  [`htc()`](https://juhalt.github.io/contentvalidR/reference/htc.md),
  [`htd()`](https://juhalt.github.io/contentvalidR/reference/htd.md),
  [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md),
  [`aikens_v()`](https://juhalt.github.io/contentvalidR/reference/aikens_v.md),
  [`cvr()`](https://juhalt.github.io/contentvalidR/reference/cvr.md),
  [`ioc()`](https://juhalt.github.io/contentvalidR/reference/ioc.md),
  [`interpret_colquitt()`](https://juhalt.github.io/contentvalidR/reference/interpret_colquitt.md),
  [`colquitt_benchmarks()`](https://juhalt.github.io/contentvalidR/reference/colquitt_benchmarks.md),
  [`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md),
  [`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md),
  [`reproducibility_phi()`](https://juhalt.github.io/contentvalidR/reference/reproducibility_phi.md),
  and
  [`similarity_from_sort()`](https://juhalt.github.io/contentvalidR/reference/similarity_from_sort.md)
  printed raw data frames and lists, such as a *p* of `1.941920e-16`
  beside seven-digit decimals. They now print as
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md)
  already did: a titled table in APA style with a short note.
  [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
  reports its tests as F(1.71, 32.57) = 108.55. The values are
  unrounded; each result only gains a class,
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
  the plain data frame, and workflow results are unaffected.
  [`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md)
  also returns its inputs.
- **Breaking:
  [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  writes APA tables by default.** The new default `format = "apa"` gives
  readable headings, counts such as 18/20, *p* to three decimals, and
  `[LL, UL]` intervals, and prints without row names;
  `format = "markdown"` writes the same table and prints as the table.
  For the numeric table that used to be the default, pass
  `format = "data.frame"`; its *p* values now keep three decimals
  whatever `digits` is. The construct-rating table shows the contrast
  *p* beside the omnibus *p*, since a Review item can have an omnibus
  *p* below .001.

### `agreement_summary()` is deprecated

- **Deprecated in 0.9.0, to be removed in 1.0.0.** Use
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md).
  `agreement_summary()` is the only function that takes items in rows;
  every other ratings function,
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
  included, takes raters in rows, so one matrix passed to both was read
  two different ways.
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
  also reports an interval and needs no other package.
  `agreement_summary()` still works in 0.9.0 and warns when called.
  Removing it at 1.0.0 leaves nothing deprecated past 1.0, as the
  stability policy in
  [`?contentvalidR`](https://juhalt.github.io/contentvalidR/reference/contentvalidR-package.md)
  sets out.

### References follow APA 7 everywhere

- **One reference list, installed in BibTeX form.** `REFERENCES.bib`
  held 13 of the works the package cites, and one it no longer cited; it
  now holds all 53, generated from the reference list in the README,
  with author names and details checked against the Crossref record for
  each DOI. A test keeps the two in step. The README calls it a
  reference list rather than a bibliography.
- **Every reference list is in alphabetical order**, as APA 7 requires,
  in the README, every help page, and every vignette. They had been
  ordered by topic. Page ranges use en dashes.
- **Corrections found by the check.** De Boeck and Wilson (2004) are the
  editors of *Explanatory item response models*, not its authors. Book
  titles are in sentence case. Four works gain the DOI they lacked
  (Brennan, 2001; De Boeck & Wilson, 2004; Newcombe, 1998; Vach & Gerke,
  2023). Colquitt et al. (2014) and the irr package, both cited in help
  pages, join the list in the README.
- `citation("contentvalidR")` prints the package reference in APA form,
  with its version and “\[Computer software\]”.

### Printed output says what it means

- **The expert-panel print opens with its verdict**, as the other
  workflows’ prints do: how many items met the criterion, then the
  flagged items by name. 0.8.0’s release notes said every print did
  this; the expert-panel print showed only a tally. Items rated by fewer
  than three experts are named too, where the tally left them out.
- **The key no longer says modified kappa runs from 0 to 1.** It falls
  below 0 whenever fewer experts agree than chance predicts: with four
  experts, an item none of them rates relevant has a modified kappa of
  -.07.
- An essentiality panel with no usable ratings no longer prints “an item
  needs at least NA rating it essential”.
- The scale-level summaries of the item-sort and construct-rating
  workflows name the band the weaker index falls in (“The weaker of Psa
  and Csv falls in the Moderate band of published scales”), where they
  spoke of “normative standing”. The construct-rating print names its
  benchmark set the way the item-sort print does.
- Every summary heading has the same form and rule; counts read “1 item”
  or “3 items” rather than “item(s)”; the handoff says held-back items
  are listed only when some are; and the note when judge severity cannot
  be estimated no longer attributes it to near-total agreement when one
  judge rejecting the items the others accept causes it.

No computed value changes.

## contentvalidR 0.8.0

Eighth public release. v0.8.0 is about reading the output and the
literature correctly. Every printed result now reads as a report in APA
style, every source is cited where its method is used, and the earlier
published rules can be shown beside each decision for teaching, each
with its shortcomings stated. One criterion now matches its source, and
the last deprecation is completed, so nothing deprecated is carried into
1.0.

The package continues to declare `Imports: stats` only.

**Results that change.** Values computed by 0.7.0 and 0.8.0 were
compared on 25 analyses spanning every workflow. The only differences
are these:

- **Lynn’s criterion at nine experts.** An item endorsed by 7 of 9
  experts now meets the I-CVI criterion, as Lynn’s (1986) Table 2 says;
  0.7.0 required 8. `cvi_criterion` now shows each panel size’s exact
  cutoff, such as .875 for eight experts, where it showed .78
  throughout. Beyond ten experts, where her table stops, the package
  holds her 7 of 9. That lowers the requirement by one expert at every
  multiple of nine (14 of 18, 21 of 27, 28 of 36, and so on) and at some
  panels above 58. Verdicts at other panel sizes are unchanged.
- **[`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)’s
  influence check.** It removes one judge at a time, so a ten-judge
  panel was checked at nine, where 0.7.0 applied the wrong criterion. On
  a ten-judge panel this could flag every judge as influential. It now
  applies Lynn’s.
- **A label.** A judge whose fit falls below the range is now
  `Too predictable`, not `Erratic`. The status is `Review` either way.
- **One removed column.**
  [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
  no longer returns `posthoc_pass`; read `contrast_pass`, which holds
  the same value.
- **Handoff rule text** reads as counts and APA numbers. The schema is
  unchanged.

**One display default changes.** Print methods now default to
`digits = 2`, as APA reports statistics; `print(x, digits = 3)` restores
the previous precision. Stored values are unaffected.

New arguments: `sort_validity(legacy = , n_constructs = )`,
`expert_validity(legacy = )`, and `legacy` in their
[`print()`](https://rdrr.io/r/base/print.html) methods.

Published on GitHub and R-universe. 0.4.0 is still in CRAN’s review
queue, and CRAN policy asks that no further version be submitted while
one is pending.

### The last deprecation is completed before 1.0

- **Breaking change:
  [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
  no longer returns `posthoc_pass`.** It was a duplicate of
  `contrast_pass`, documented as deprecated in 0.7.0. The written policy
  requires one minor release of notice and allows removal in a minor
  release only before 1.0, so this is the last release that can remove
  it without waiting for 2.0. Read `contrast_pass`, which holds the same
  value. It was the last column, so no other column moves.
- No deprecation is in progress now, so nothing deprecated is carried
  into 1.0.
  [`?contentvalidR`](https://juhalt.github.io/contentvalidR/reference/contentvalidR-package.md)
  records both of
  [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)’s
  completed cycles.

### Earlier methods, for comparison

For teaching, the way a methods text reports eta-squared beside
omega-squared,
[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
and
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
now compute the earlier published rules beside their own.
`legacy = TRUE` prints them under “Earlier methods, for comparison (not
used for the decision)”, and `print(fit, legacy = TRUE)` shows them for
any fit. They are stored in `details$earlier_methods` and never change a
decision. Each follows its source as published, and the tests check each
against the numbers its source prints.

- **Item sort.**
  - Anderson and Gerbing’s (1991) critical Csv, from their Equations 5
    and 6: .50 for 20 judges at .05. The printout explains why it is not
    used to decide: it assumes every judge who misses the target picks
    the same rival, so when they spread across several constructs it can
    pass an item the exact test does not.
  - Yao, Wu and Yang’s (2008) cutoffs, Psa and Csv both at least .30,
    set for a four-domain sort.
  - **A labeled package extension** of Yao et al.’s rule to other
    numbers of constructs: chance plus .05, so Psa and Csv both at least
    `1/k + .05`, which is their .30 at four. It prints in its own column
    marked `*` and is described as “a contentvalidR extension, not a
    published rule”. The new `n_constructs` argument states how many
    constructs judges were offered; by default the package counts the
    ones they used, and says so.
  - A count of how often each earlier rule agrees with the decision, and
    a note that pooling every rival into Csv gives a different index.
- **Expert essentiality.** Lawshe’s (1975) Table 1 minimum CVR, the
  recalculation by Wilson, Pan and Schumsky (2012), `z / sqrt(N)`, and
  Lawshe’s content validity index, the mean CVR of the items his table
  retains. A panel size Lawshe did not tabulate gets no minimum rather
  than an interpolated one. When a CVR prints equal to a cutoff it
  misses, such as 8 of 9 (.778) against Lawshe’s .78, the printout says
  so.
- **Expert relevance.** Fleiss’ (1971) kappa on the
  relevant/not-relevant decision, computed by the package and checked
  against the irr package, and the benchmarks of Polit and Beck (2006):
  .90 for S-CVI/Ave, which is the average congruency percentage, and .80
  for S-CVI/UA.
- **Expert relevance: the content validity coefficient (Ccv) of
  Hernández-Nieto (2002),** beside Aiken’s V, read from the full text of
  the book’s chapter. It is shown because it is widely cited, and never
  informs a decision, because of shortcomings the printout,
  [`?expert_validity`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  and the expert-panel vignette all set out:
  - It uses only each item’s mean, so it cannot reflect agreement,
    although the book says it does. The book’s own Table 7 gives ratings
    of 1, 3, 4, 5, 2 and of 3, 3, 3, 3, 3 the same .60.
  - Its chance correction, (1/J)^J, depends only on the number of
    judges. It is .00032 for five of them.
  - On a scale starting at 0 it is Aiken’s V; on a scale starting at 1
    it cannot fall below one over the maximum.
  - Its .80 and .90 bands are not derived, and the book’s own Example 11
    calls .7968 acceptable.
- The item-sort vignette section that explained why Anderson and
  Gerbing’s rule was “not exposed” now shows it for comparison, using
  the shipped example where it and the exact test disagree. The
  expert-panel vignette shows Lawshe’s anomaly at nine experts.

### Every vignette lists what it cites

- Four vignettes cited works without a reference list, and the
  expert-panel vignette cited Lynn (1986) without listing it. Each now
  has an APA reference list, and
  [`vignette("reading-output")`](https://juhalt.github.io/contentvalidR/articles/reading-output.md),
  which explains the APA number rules, cites the Publication Manual. Yao
  et al. (2008) joins the README references.

### Printed output reads as a report, in APA style

No statistic changes. Only printed output changes, and `results` still
holds every value at full precision.

- **Numbers follow the APA Publication Manual, seventh edition.** A
  statistic that cannot exceed 1 prints without a leading zero (Psa =
  .90, *p* = .021, kappa = -.13). One that can exceed 1 keeps it (a
  chi-square of 0.31, a severity of -0.27 rating points). Values have
  two decimals, and *p* values have three, with anything below .001
  printed as \< .001 rather than 0.000 (Section 6.36). Intervals print
  as `95% CI [.70, .97]` in a column headed with their level (Section
  6.43). `digits` now defaults to 2 in every print method.
- **Every print opens with its verdict.** A sentence says how many items
  met the criterion and names the ones flagged, before any table. The
  decision appears beside each item. Anything that is the same on every
  row, such as the I-CVI criterion for a panel of one size, is stated
  once in a sentence instead of repeated down a column.
- **No more walls of numbers.** Tables are laid out to fit an 80-column
  console (long item names can still widen them), and prose wraps to the
  console width. The [`summary()`](https://rdrr.io/r/base/summary.html)
  methods show flagged items in the same columns as
  [`print()`](https://rdrr.io/r/base/print.html), where the expert-panel
  summary used to print its whole results table. An explanation shared
  by several items, such as a Delphi note or a judge’s flag, is printed
  once with every item it applies to.
- **Planning tables have one row per panel size.**
  [`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md)
  and
  [`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md)
  put each assumed probability in its own column, so ten panel sizes
  take ten rows instead of thirty.
- **The key names columns by the heading you see** (Psa, 95% CI, kappa),
  not by the name of the column in `results`.
- **Headings are words.** `n_target` and `n` print together as judges
  (18/20), `severity(pts)` as severity, `differentiation` as scale use,
  and the recommendation column as decision.
- [`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md)
  prints the degrees of freedom beside a chi-square, as APA reports it.
  [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
  prints infit beside outfit, since either can flag a judge, and states
  the rules that flag one.
- The README and vignettes follow the same rules, and the vignette on
  reading output explains them.

### Two labels now say what they mean

- **[`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
  no longer calls a too-predictable judge “Erratic”.** A fit mean square
  above the range means ratings noisier than the model expects; one
  below it means ratings more predictable than it expects, the opposite
  problem. Both were labeled `Erratic`. The second is now
  `Too predictable`, with its own interpretation. The status is `Review`
  either way, and which judges are flagged does not change. Code that
  matched `recommendation == "Erratic"` to find every misfitting judge
  should also match `"Too predictable"`, or use `status`.
- **The handoff states the I-CVI criterion as a count.** Its `rule` text
  read `I-CVI >= 0.8333333`. It now reads
  `at least 5 of 6 experts rate the item relevant (I-CVI >= .83; Lynn, 1986)`,
  since the decision compares counts, and the handoff now cites Lynn
  (1986). Rule text is prose for a person and outside the frozen schema,
  which is unchanged.

### The I-CVI criterion now matches Lynn’s table

- **Changed result, with nine experts only.** An item endorsed by 7 of 9
  experts now meets the I-CVI criterion; before, it needed 8. The
  criterion was stored as “.78”, which is Lynn’s (1986) 7 of 9 rounded,
  and 7/9 = .778 fell short of the rounded value. Lynn’s Table 2
  requires 7 of 9, and Polit and Beck (2006) say the same in words.
  Every other panel size from three to ten was already right. This
  affects
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  verdicts,
  [`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md)
  planning probabilities, and
  [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)’s
  check of whether one judge moves an item.
- **`cvi_criterion` now shows Lynn’s cutoff for each panel size**, such
  as .833 for six experts and .778 for nine, instead of .78 throughout.
  Verdicts at six, seven, eight and ten experts are unchanged, but the
  printed criterion now matches the verdict beside it: an item is
  supported exactly when its I-CVI reaches the number shown. A test
  checks that for every panel of 3 to 15 experts and every count of
  agreeing experts.
- **Beyond ten experts, the criterion is now labeled an extension.**
  Lynn’s table stops at ten. The package holds her lowest tabled
  proportion, 7 of 9, and says so, where before it applied .78 without
  comment. That also lowers the requirement by one expert at every
  multiple of nine, where 7/9 falls exactly on a whole count (14 of 18,
  21 of 27, 28 of 36, and so on), and at some panels above 58, where .78
  and 7/9 straddle a whole count.
- The rule lives in one place, stored as Lynn’s counts. The three
  functions compare counts of agreeing experts, so no rounding can move
  an item.

### Attribution

- **Every source the package cites is now on its public reference
  list.** The reference list in the README was missing eight sources
  that function help pages cite, including Krippendorff (2011), whose
  alpha is the default panel coefficient, and Schriesheim et al. (1993,
  1999), behind
  [`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md).
- **Four foundational sources are now cited where their methods are
  used,** each checked against the full text:
  - [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md)
    and
    [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
    cite Lynn (1986), the source of the I-CVI and of the panel-size
    criterion
    [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
    applies, and Polit and Beck (2006), who named S-CVI/UA and
    S-CVI/Ave.
    [`?cvi`](https://juhalt.github.io/contentvalidR/reference/cvi.md)
    now explains where each index comes from and why both scale-level
    versions should be reported.
  - [`cvr()`](https://juhalt.github.io/contentvalidR/reference/cvr.md)
    cites Wilson, Pan and Schumsky (2012) and explains why the exact
    values replace Lawshe’s original table: Wilson et al. found the
    table unexplained, non-monotonic at eight experts, and closer to a
    two-tailed than the one-tailed test it was labeled as.
  - `agreement_summary()` credited nobody. It now cites Fleiss (1971)
    for the statistic and the irr package’s authors for the code it
    calls.
- [`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md)
  and
  [`simulate_csv_power()`](https://juhalt.github.io/contentvalidR/reference/simulate_csv_power.md)
  cite Howard and Melloy (2016), whose test they plan for. Two
  incomplete entries are completed.
- **Three instructions that did not work are fixed.**
  [`print()`](https://rdrr.io/r/base/print.html) on a handoff,
  [`vignette("handoff-to-empirical-validation")`](https://juhalt.github.io/contentvalidR/articles/handoff-to-empirical-validation.md),
  and the README all told readers to pass the handoff object to
  `nomologR::nomo_screen()`, which cannot read it until
  [nomologR#46](https://github.com/JUhalt/nomologR/issues/46). All three
  now pass `handoff$items`.

## contentvalidR 0.7.0

Seventh public release. v0.7.0 is about being safe to depend on. It says
in writing what code can rely on from one version to the next, freezes
the handoff object that another package reads, and settles the one
deprecation that a 1.0 release would otherwise lock in. It also adds a
worked example that carries a single item set from an expert panel into
response data, and it corrects the stated basis of the Delphi kappa
interval.

The package continues to declare `Imports: stats` only.

**One breaking change.**
[`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
no longer accepts `posthoc`, and passing it is an error. The argument
has had no effect on any result in any release, and it has warned in
every one since 0.1.0. See below.

No default changes, and no computed value changes. Across all six
workflows, every Delphi stability method, and the bootstrap intervals,
every value 0.6.0 returns is identical in 0.7.0. Handoff objects gain
four columns (`note`, `keying`, `response_min`, `response_max`), all
appended within schema version 1, so a reader written for 0.6.0 still
reads them.

New arguments: `content_handoff(reverse_keyed = , response_scale = )`.
New vignette:
[`vignette("one-item-set-both-stages")`](https://juhalt.github.io/contentvalidR/articles/one-item-set-both-stages.md).
New example data: three `walkthrough_*.csv` files in `inst/extdata`.

Published on GitHub and R-universe. 0.4.0 remains in CRAN’s review
queue, and CRAN policy asks that no further version be submitted while
one is pending.

### The one deprecation in flight is resolved

- **Breaking:
  [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)’s
  `posthoc` argument is removed**
  ([\#60](https://github.com/JUhalt/contentvalidR/issues/60)). Passing
  it is now an error rather than a warning.
  - **Replacement:** none is needed. Tukey/Duncan post-hoc testing was
    dropped before the first release because the Hinkin-Tracey question
    is answered directly by planned target-versus-orbiting contrasts,
    which
    [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
    has always run. The argument has had no effect on any result in any
    version.
  - **It warned from the beginning.** The deprecation warning was in the
    initial commit and stood through 0.1.0, 0.2.0, 0.3.0, 0.3.1, 0.4.0,
    0.5.0, and 0.6.0 — seven releases against the policy’s minimum of
    one.
  - **Why now.** The stability policy removes a deprecation in a minor
    release before 1.0, and only in a major release from 1.0 onward.
    This is the last release that can do it without waiting for 2.0.
  - The argument sat seventh in the signature, ahead of `alpha`, so
    anyone who passes arguments by position past `target_map` should
    check their call.
- **`posthoc_pass` is now documented as deprecated.** It is a duplicate
  of `contrast_pass` and has been returned silently since the first
  release, without ever being marked. It is **still returned and still
  correct**, since the policy requires a release in which reading it
  keeps working; read `contrast_pass` instead. It is the last column, so
  removing it later cannot move another.
- **Both events are recorded here, which is the point.** The policy says
  `NEWS.md` records a deprecation and its removal with the replacement;
  the `posthoc` deprecation was never recorded at all until now.
  [`?contentvalidR`](https://juhalt.github.io/contentvalidR/reference/contentvalidR-package.md)
  now cites `posthoc` as the completed cycle and `posthoc_pass` as the
  one in progress, and the test suite checks that both are in the state
  the policy claims.
- **[`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md)
  moves from Tier 3 to Tier 2.** Tier 3 describes helpers “kept for
  continuity with older analyses”, which are “not recommended workflows”
  and “may be deprecated and removed”. That is the wrong description of
  the Howard and Melloy (2016) exact test that
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  runs on every item. The tiers become promises at 1.0, so a
  load-bearing function had to stop being filed under the one that
  promises least. No code changes.

### One item set carried through both stages

- New
  [`vignette("one-item-set-both-stages")`](https://juhalt.github.io/contentvalidR/articles/one-item-set-both-stages.md)
  follows twelve items from an expert panel through the handoff and into
  response data
  ([\#55](https://github.com/JUhalt/contentvalidR/issues/55)), so the
  pair of stages is demonstrated rather than asserted. Every step runs:
  the second half uses `stats` only, and the `nomologR` call is shown
  but not run, since neither package depends on the other.
- The point of the walkthrough is the disagreement between the stages,
  and it runs in **both** directions.
  - Two items fail content review, for opposite reasons: one keeps its
    target and misses the criterion, the other loses its target to a
    competing facet.
  - Two pass content review and then misbehave. `EF4` is sorted to
    effort regulation by eighteen of twenty judges and carries almost no
    common variance; `TF4` is sorted to one facet and loads on both. A
    panel cannot see either, which is the reason for running the second
    stage.
  - `EF3` is the reverse, and the sharper case: an empirical screen
    flags it and it is worth keeping. Nearly everyone endorses “I finish
    the assignments that count toward my grade” — 96% answer in the top
    two categories — so its variance is a third of every other item’s
    and it cannot correlate strongly with anything. Its correlation
    looks as bad as `EF4`‘s, and only the distribution tells them apart.
    It is also the only item covering the completion of required work,
    so dropping it would narrow the domain the panel defined. Added at
    the nomologR maintainers’ suggestion, so that both packages’
    articles make the same point about it.
  - Meanwhile the item that met the content criterion by a single judge
    behaves perfectly well, so a borderline content result is not read
    as a prediction.
  - `EF2` and `TF2` are written the other way round, and the walkthrough
    passes that to `content_handoff(reverse_keyed = )` along with the
    respondents’ one-to-five scale. It then shows why the handoff has to
    carry both: before recoding, `TF2` correlates at -0.51 with its own
    facet, which looks like the strongest evidence against an item that
    item analysis produces and is in fact a coding error. Recoded with
    the keying and the scale limits the handoff carries, it is +0.51.
    Added together with the keying field, at the nomologR maintainers’
    request, so that no reader ever receives reverse-worded data without
    the means to know it.
- Three new files in `inst/extdata`: `walkthrough_items.csv` (the items,
  their facet, their stems, what each one was built to do, and whether
  it is reverse-worded), `walkthrough_sort.csv` (twenty judges), and
  `walkthrough_responses.csv` (400 respondents, twelve items, a
  two-level `cohort` variable, and the rejected items still present).
  **They are simulated.** No participant was involved and no real
  instrument is reproduced.
- `data-raw/build-walkthrough-data.R` writes all three and states the
  generating model in full: the two correlated facets, every loading,
  the response thresholds, and the single cohort shift. It uses base R
  only and is deterministic. `nomologR` mirrors the response file from
  the same script, so the two packages cannot drift.
- A test file holds the vignette to its claims: which two items the
  panel flags, which met the criterion by one judge, that `EF4` is the
  weak one and `TF4` the ambiguous one, that `EF3` is flagged for
  restricted variance rather than for lacking common variance, and that
  `TF6` is the only item that shifts by cohort. If the data are
  regenerated and a claim stops holding, the suite fails rather than the
  vignette quietly becoming wrong.

### Handoff schema version 1 is frozen

- [`?content_handoff`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
  gains two sections. *What version 1 freezes* names every field and
  column a reader can rely on, states that each keeps its name,
  position, and type, and lists what is deliberately not frozen: which
  rows appear, the labels in the `statistic` column, the prose in
  `note`, `rule`, `recommendation`, and `citation`, the contents of
  `settings` and `design`, and the printed output. *If the schema ever
  changes* gives the version-2 path and the two-line version check a
  reader should gate on.
- The frozen contract is now data rather than prose, so the tests and
  the documentation cannot drift apart. Handoffs from all five workflows
  that can produce one are checked against it, column by column, along
  with the guarantee that makes the freeze useful: every handoff carries
  every column, so a statistic with no interval carries `NA` in all four
  interval columns and a workflow with no panel coefficient returns a
  zero-row `panel_statistics` with the full column set. Handoffs from
  different workflows therefore bind without reconciling them first.
- **Before the freeze closed, it was checked against every reader.**
  - `nomologR` confirmed the frozen list covers everything its reader
    consumes, and named two gaps, each blocking a specific computation
    rather than expressing a preference. Both are added.
  - `solomonR` was asked too
    ([solomonR#32](https://github.com/JUhalt/solomonR/issues/32)): its
    `fit_solomon_sem_latent()` takes item names as character vectors,
    which is exactly what a handoff carries.
- **[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
  gains `reverse_keyed` and `response_scale`,** recorded per item in
  three new `item_evidence` columns: `keying` (`1` forward, `-1`
  reverse-worded), `response_min`, and `response_max`.
  - Keying, because an even-odd consistency index must recode
    reverse-worded items first or a consistent respondent looks
    careless, and because a negative corrected item-total correlation
    means a coding error on an item that was never recoded and evidence
    against the item on one that was.
  - The response scale, because screening for out-of-range answers needs
    the scale’s limits rather than the observed ones: a category nobody
    used is still a legal answer.
  - **Both come from the analyst, never from the fit.** A panel’s `lo`
    and `hi` are the scale the experts rated relevance on, usually 1 to
    4, not the scale respondents answer. Copying them across would hand
    a reader the wrong limits, and it would then reject every legitimate
    top-category answer. So both default to `NA`, meaning unknown, and a
    test guards against the fit’s scale ever leaking into these columns.
  - `reverse_keyed = character(0)` records that someone checked and no
    item is reversed, which is different from not having said.
  - Naming a reverse-worded item without `response_scale` warns, since
    the item cannot be recoded without the scale’s limits. A reader that
    recodes would otherwise refuse one step later, where the omission is
    harder to trace. Suggested by the nomologR maintainers.
- Item text was considered and left out. It was wanted only if every
  workflow that can produce a handoff has the wording, and none of them
  collects it.
- Apart from those three columns, the freeze changes no object: a 0.7.0
  handoff is a 0.6.0 handoff plus them and the `note` column described
  below. All are appended after the original columns, as the additive
  rule requires.

### The kappa interval in a Delphi is a published procedure

- The bootstrap interval beside a Delphi stability kappa was described
  in the output and the help page as this package’s own extension. That
  was wrong. Resampling the units that the two raters cross-classify,
  recomputing kappa, and taking the percentile interval is the procedure
  Klar, Lipsitz, Parzen and Leong (2002) set out; in a Delphi those
  units are the experts, each carrying their rating in both rounds.
- In its place,
  [`?delphi_validity`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md)
  gains *Reading the kappa interval*, which says what the interval is
  and gives the two things a reader needs in order to report it
  honestly: Klar et al.’s measured coverage for a nominal 95% interval
  was about 83% with 20 units, 89% with 25, 91% with 30, and reached 94%
  only from 40 up, so a panel-sized interval is narrower than its label;
  and their simulations used an unweighted kappa on two categories, so
  the ordinal weighted case has not been simulated. The printed output
  carries the short form of both.
- [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md)
  keeps its extension warning for Gwet’s AC1. Zapf et al.
  2016. evaluated the bootstrap for Fleiss’ kappa and Krippendorff’s
        alpha only, and do not discuss AC1 at all, so applying their
        interval to it is an extension. That caveat now travels with the
        number: an AC1 interval in
        [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
        carries it in `panel_statistics$note`, where before it reached
        only the console.
        ([`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
        tabulates item-level evidence and never shows a panel
        coefficient, so there is nothing to carry there.)
- The reference list in the README catches up. It had no Delphi sources
  at all, although the workflow shipped in 0.5.0 and the prose above it
  cites Holey et al., Chaffin and Talley, Dajani et al. and Scheibe et
  al. by name. Nine references are added in APA form with DOIs: those
  four, plus Cohen (1968), Fleiss and Cohen (1973), Landis and Koch
  (1977), Diamond et al. (2014), and Klar et al. (2002).
- Two printed claims fixed. With `B = 0`,
  [`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md)
  still described intervals it had not computed and still printed empty
  `low` and `high` columns; it now omits both. The printed-claims test
  that should have caught this used a statistic that has no interval at
  all, so it passed vacuously.

### A written stability policy

- [`?contentvalidR`](https://juhalt.github.io/contentvalidR/reference/contentvalidR-package.md)
  now states what code can rely on across versions (the 1.0 criteria on
  [nomologR#53](https://github.com/JUhalt/nomologR/issues/53)):
  - the public API in three tiers, from the recommended workflows
    through the component indices to the auxiliary helpers, with every
    exported function placed in one;
  - the deprecation cycle: a warning that names the replacement,
    standing for at least one minor release before anything is removed;
  - a changed default treated as a breaking change, since it can
    silently change published numbers;
  - what the handoff schema guarantees a downstream package;
  - which versions of R are supported.
- Tests keep the policy honest: a newly exported function fails the
  suite until it is classified, and the deprecation the policy cites as
  its worked example is checked to still warn and still work.

### Saying what NA means

- `item_statistics` and `panel_statistics` gain a `note` column,
  carrying the producing function’s own sentence for why a value or
  interval is absent or degenerate, such as “Kappa is undefined: every
  rating fell in the same category in both rounds.”
  - Added so a downstream report can print the reason instead of
    reconstructing method-specific semantics by switching on statistic
    names, which would go silently wrong whenever a method is added. The
    design was argued out with the nomologR maintainers on
    [nomologR#46](https://github.com/JUhalt/nomologR/issues/46).
  - **Display text only.** Never match on it, branch on it, or parse it;
    its wording may change in any minor release.
  - Always character, never `NA`: `""` means there is nothing to say.
  - It never replaces the values. Which of the two `NA` cases applies
    stays readable from `value` and `proportion unchanged`, and that
    remains the supported way to decide anything.
  - Additive within schema version 1: it is appended after every
    existing column, and objects from 0.6.0 and earlier simply have no
    such column.
- Documented the two reasons a Delphi stability statistic can be `NA`
  ([\#48](https://github.com/JUhalt/contentvalidR/issues/48)), which a
  reader can tell apart from the object alone:
  - `proportion unchanged` is also `NA`: the item has no pair of
    consecutive rounds, because it was rated in one round only;
  - `proportion unchanged` has a value: a pair exists, but the statistic
    is undefined for that data.
- The second case is easy to misreport. An undefined kappa beside
  `proportion unchanged` of 1 is **perfect stability that kappa cannot
  express**: kappa is chance-corrected, so when every paired rating in
  both rounds falls in one category, the disagreement expected by chance
  is zero and kappa is 0/0. Saying only “not estimable” would describe a
  defect that does not exist.
- The row is always present, so an `NA` is a statement about the data
  rather than a missing record. Raised by the nomologR maintainers from
  the 0.6.0 fixtures.

## contentvalidR 0.6.0

Sixth public release. v0.6.0 finishes the Delphi workflow: a Delphi
study can now be handed off to empirical validation, carrying for each
item the round it settled in, and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) shows the two
trends a Delphi is about. It also adds a test layer that checks the
package’s printed claims against what the code actually computes.

The package continues to declare `Imports: stats` only.

No default changes. Existing calls return the same values as in 0.5.0.

New method: [`plot()`](https://rdrr.io/r/graphics/plot.default.html) for
[`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md).
[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
accepts a Delphi fit.

Published on GitHub and R-universe. 0.4.0 remains in CRAN’s review
queue, and CRAN policy asks that no further version be submitted while
one is pending.

### Seeing a Delphi’s trends

- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) for
  [`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md)
  ([\#44](https://github.com/JUhalt/contentvalidR/issues/44)), so the
  Delphi workflow matches the others in having one.
  - `which = "consensus"` (default) draws each item’s share of experts
    agreeing, round by round. A line that stops early belongs to an item
    that settled and was set aside, so the picture shows when each item
    left the study.
  - `which = "stability"` draws the stability statistic per pair of
    rounds, with the share of experts who kept their rating as open
    circles.
  - **Nothing is drawn that the analysis did not apply.** The consensus
    threshold appears only when one was set, and kappa gets no shaded
    bands, because its verbal benchmarks are arbitrary and it falls as a
    panel converges.
  - Item labels sit at the end of each line and are nudged apart when
    items finish at the same height.

### Printed claims are tested against what the code computes

- A new test file checks the package’s printed output against the fitted
  objects it describes, rather than against strings copied from the
  print methods
  ([\#41](https://github.com/JUhalt/contentvalidR/issues/41)). A test
  that asserts what the documentation claims can pass while being false.
  It checks that:
  - every number printed for an item is the number the object holds;
  - the printed settings are the settings that ran;
  - a method’s critique appears when that method ran, and not otherwise;
  - percentages written into prose match the computed proportions;
  - a claim about how a statistic was computed holds of the numbers. The
    note that quadratic weighting makes kappa an intraclass correlation
    is checked against the intraclass correlation itself, and is absent
    under linear weights, where it would be false;
  - [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
    claims comparability only when the settings match;
  - the status legend’s example words are real recommendation values in
    some workflow;
  - statistics stay inside the ranges the glossary claims, under
    unanimous, rejected, and evenly split panels.
- `.print_key()` now fails on an unknown term instead of dropping it. A
  typo in a print method’s key used to remove a column’s explanation in
  silence.

### A Delphi study can hand off

- [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
  now accepts a
  [`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md)
  fit ([\#42](https://github.com/JUhalt/contentvalidR/issues/42)). It
  used to refuse one, and its message did not even mention Delphi.
  - **Each item travels with its own last round.** A Delphi settles one
    item at a time: an item that reached consensus early was set aside
    before the final round. `round` now holds that round’s index, so it
    varies between items. This is the first workflow where it carries
    real information.
  - **Relevance evidence comes from the item’s last round,** taken from
    that round’s
    [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
    fit, with intervals: `I-CVI` against the consensus threshold,
    `Aiken's V`, and `modified kappa`. Modified kappa carries no
    criterion, because a Delphi decides on the consensus threshold
    rather than on the 0.74 rule.
  - **Stability travels as evidence**, never as a carry decision:
    `proportion unchanged` plus the statistic that ran, named for its
    method, such as `weighted kappa (quadratic)` or
    `Goodman-Kruskal lambda`. The chi-square methods add
    `stability p_value`. The names are qualified so a downstream report
    cannot misread them
    ([nomologR#46](https://github.com/JUhalt/nomologR/issues/46)).
  - `round` cannot be set by hand for a Delphi fit, since the fit
    supplies it.
- No schema change. These are new values in existing columns, so a
  schema version 1 reader still reads the object.

## contentvalidR 0.5.0

Fifth public release. v0.5.0 adds a workflow for Delphi studies, where
the same expert panel rates items over successive rounds. It reports
consensus and stability as separate questions, and every published
stability method is available with its limits printed. The handoff to
empirical validation now carries each statistic’s interval, so a
downstream analysis can see how much panel evidence stands behind a
number.

The package continues to declare `Imports: stats` only.

No default changes. Existing calls return the same values as in 0.4.0.
[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
objects gain four interval columns in `item_statistics` and a
`panel_statistics` table, within schema version 1.

New function:
[`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md).
New article:
[`vignette("delphi-rounds")`](https://juhalt.github.io/contentvalidR/articles/delphi-rounds.md).

This release is published on GitHub and R-universe. 0.4.0 is still in
CRAN’s review queue, and CRAN policy asks that no further version be
submitted while one is pending, so 0.5.0 will be submitted to CRAN later
as an update.

### Delphi consensus and stability

- New workflow
  [`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md)
  for an expert panel rated over successive Delphi rounds
  ([\#20](https://github.com/JUhalt/contentvalidR/issues/20)). It
  reports two questions separately. **Consensus**: whether enough
  experts agree now. **Stability**: whether experts are still changing
  their ratings.
  - **Consensus** is the share of experts rating an item at or above
    `agree_cut`, which on a relevance scale is the I-CVI. It is judged
    against a `consensus_threshold` fixed before the study. There is
    deliberately no default: without a threshold, results are
    descriptive (Diamond et al., 2014).
  - **Stability** always reports the share of experts who kept their
    rating. Beside it goes one statistic:
    - the default, weighted kappa between rounds (Holey et al., 2007),
      read as a trend. Quadratic weights, the default, make it the
      intraclass correlation of the two rounds (Fleiss & Cohen, 1973);
      linear weights are available (Cohen, 1968);
    - Chaffin & Talley’s (1980) lambda;
    - Chaffin & Talley’s individual chi-square;
    - Dajani, Sincoff & Talley’s (1979) group chi-square;
    - Scheibe, Skutsch & Schofer’s (1975) 15% net-change rule.

    Each alternative’s limits are printed. The two chi-square tests read
    in opposite directions, and the printout says which is which.
  - **No verbal kappa labels.** Landis & Koch (1977) call their
    divisions arbitrary, and kappa falls as a panel converges. When a
    round is unanimous, kappa is 0 however many experts kept their
    rating; the output flags this and points to the share unchanged.
  - **A bootstrap interval for kappa**, resampling experts, marked as
    this package’s extension.
  - **Round-by-round relevance evidence.** Each round is also fitted
    with
    [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md),
    so
    [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
    can read the whole process.
- New vignette,
  [`vignette("delphi-rounds")`](https://juhalt.github.io/contentvalidR/articles/delphi-rounds.md),
  walks through a three-round panel for a graduate reader. Its worked
  example covers:
  - a statement set aside after reaching consensus;
  - an expert leaving the panel;
  - consensus against a statement;
  - a stable split;
  - a panel converging to unanimity, where kappa drops to 0;
  - experts swapping ratings while the overall distribution stays still,
    which only individual stability detects.
- `contentvalid_glossary("delphi")` defines the new columns.
- Every published value used to design the workflow is a test: Cohen’s
  1968. Table 1, Fleiss & Cohen’s equivalence, and the worked examples
        of Dajani et al. and Chaffin & Talley.

### Interval bounds in the handoff

- [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
  now carries each statistic’s interval
  ([\#33](https://github.com/JUhalt/contentvalidR/issues/33)), so a
  reader can tell a unanimous four-judge panel from a unanimous
  twenty-judge one. A unanimous I-CVI from four experts has a Wilson 95%
  lower limit near 0.51.
  - `item_statistics` gains `lower`, `upper`, `interval_method`, and
    `interval_level`. They hold the Penfield-Giacobbi score interval for
    Aiken’s V, and whichever `proportion_ci` method was chosen for I-CVI
    and Psa.
  - A new `panel_statistics` table carries the panel agreement
    coefficient and its bootstrap interval, which are not per item.
  - `NA` in all four columns means the statistic has no interval, never
    missing data.
- These additions stay within schema version 1, as agreed with nomologR
  on [nomologR#46](https://github.com/JUhalt/nomologR/issues/46).
  - Existing fields keep their names, types, meaning, and column
    positions.
  - A reader should check that the new columns are present before using
    them.
- The handoff reports intervals only. It does not turn them into priors
  or weights.

## contentvalidR 0.4.0

CRAN release: 2026-09-28

Fourth public release. v0.4.0 connects content validation to what comes
after it: a documented handoff carries the items that survived content
review, and the evidence behind each decision, into empirical scale
development. It also adds a stricter, selectable criterion for parallel
analysis, and fixes the two packaging problems that returned the 0.3.x
CRAN submissions.

The package continues to declare `Imports: stats` only.

No default changes. Existing calls return the same values as in 0.3.1;
[`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
results gain two fields recording the parallel analysis criterion that
ran.

New function:
[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md).

### Handoff to empirical validation

- Added
  [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md),
  which packages a finished workflow’s item decisions for the next stage
  of scale development
  ([\#27](https://github.com/JUhalt/contentvalidR/issues/27)). It
  carries the item names that survived content review, the construct
  each belongs to where the design defines one, a per-item evidence
  table with the decision rule that was applied, the statistics behind
  each decision, and the provenance of the analysis.
- The object shape is schema version 1, agreed with the `nomologR`
  package, which consumes it in `nomo_screen()` and `nomo_run()`. Every
  field is a base type, so neither package depends on the other.
- Items that do not meet `keep` stay in the evidence table with
  `carried = FALSE` rather than disappearing, and the printed output
  says plainly that surviving content review does not establish how an
  item will behave empirically.
- New vignette, *From Content Validity to Empirical Validation*, running
  from an expert panel through the handoff into an empirical workflow.

### Selectable parallel analysis criterion

- [`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
  gains `parallel_criterion`, choosing what parallel analysis compares
  observed eigenvalues against
  ([\#26](https://github.com/JUhalt/contentvalidR/issues/26)). `"mean"`
  stays the default, the rule Horn (1965) described and Zwick and
  Velicer (1986) evaluated. `"percentile"` compares against an upper
  percentile of the simulated eigenvalue distribution, following
  Glorfeld (1995), who found that Horn’s procedure still tends to retain
  one or two factors too many.
- The percentile level is selectable through `percentile`, defaulting
  to 95. Both criteria read the same simulation, so they are directly
  comparable from one seeded run, and the result records
  `parallel_criterion` and `percentile` alongside the comparison values
  in `parallel_eigen`.

### Packaging

- `.Rbuildignore` now excludes `.git`, `.gitignore`, and
  `.gitattributes`. Building a release tarball from a `git worktree`
  checkout writes `.git` as a *file* rather than a directory, which
  `R CMD build` does not drop, and CRAN’s incoming pretest reported it
  as a hidden file included in error
  ([\#14](https://github.com/JUhalt/contentvalidR/issues/14)).

## contentvalidR 0.3.1

Patch release for the CRAN submission. Package code, documentation of
methods, and results are unchanged from 0.3.0.

- README links to the license and the roadmap now use full URLs. The
  relative links pointed at files that are not part of the built
  package, which CRAN’s incoming checks report as invalid file URIs.

## contentvalidR 0.3.0

Third public release, and the first prepared for CRAN. Every addition
rests on published, verifiable methodology, and one design rule runs
through the release: where more than one published method exists,
researchers choose through an argument whose default is the
best-supported option. Methods with published evidence against them stay
available for reproducing earlier work, but they are never the default,
and selecting one prints the critique.

The package continues to declare `Imports: stats` only.

Two defaults change results for existing code.
[`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
now chooses the number of factors by parallel analysis, and
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
relevance mode now bootstraps an interval for panel agreement, so set
`seed` when printed output must be reproducible. Other existing results
are unchanged; the new interval and agreement columns are additions.

New function:
[`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md).

### Panel-level agreement for expert panels

- Added
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md),
  reporting one coefficient for how consistently an expert panel rated
  the whole item set, with a bootstrap interval. It complements the
  item-level I-CVI and modified kappa rather than replacing them.
- Krippendorff’s alpha is the default, computed from the coincidence
  matrix (Krippendorff, 2011) at a selectable measurement level: ordinal
  (the default), nominal, or interval. It reproduces the worked example
  in Krippendorff (2011) and agrees with
  [`irr::kripp.alpha()`](https://rdrr.io/pkg/irr/man/kripp.alpha.html).
- Gwet’s AC1 (Gwet, 2008) is available but is never the default, and
  selecting it prints the critique in Vach and Gerke (2023).
- Intervals resample items with all of their ratings, following Zapf et
  al. (2016), who found Krippendorff’s original bootstrap under-covered.
- [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  relevance mode reports panel agreement in its scale summary,
  controlled by `agreement`, `agreement_level`, `agreement_B`, and
  `seed`.
- Output reports the share of identical rating pairs next to the
  coefficient, and explains that alpha can be low when ratings cluster
  on one value, so a low alpha on a close-agreeing panel is not read as
  a poor panel.

### Evidence-based factor retention for `qfactor_content()`

- **Behavior change:**
  [`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
  now chooses the number of factors with Horn’s (1965) parallel analysis
  by default, instead of Kaiser’s eigenvalue-greater-than-1 rule. Calls
  that relied on the old default can return a different number of
  factors. Use `retention = "kaiser"` to reproduce earlier results; it
  prints the finding of Zwick and Velicer (1986) that the rule severely
  overestimates the number of components.
- Parallel analysis simulates random data with the same size and missing
  cells as the ratings. New `n_iter` and `seed` arguments control it,
  and the result records `retention`, `k_suggested`, and
  `parallel_eigen`.
- A supplied `k_factors` still takes precedence, and is recorded as
  `retention = "fixed"`.
- [`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
  now cites Schriesheim et al. (1993, 1999), and
  [`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md)
  cites Anderson and Gerbing (1991).

### Packaging

- `DESCRIPTION` now gives DOIs for the methods it cites, and citation
  metadata is stamped for 0.3.0.
- `agreement_summary()` and the
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods for
  sort, rating, expert, and sort-power objects now have runnable
  examples, so every help page shows how to use its function.
  `agreement_summary()` also points to
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md).

### Selectable intervals for proportion indices

- [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) now
  reports an interval for each I-CVI (`I_CVI_low`, `I_CVI_high`), and
  [`compute_psa()`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md)
  does the same for each Psa (`psa_low`, `psa_high`). Both indices
  previously appeared as bare proportions, usually from small panels.
- The interval method is selectable: `ci` in those two functions, and
  `proportion_ci` in
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  and
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md).
  The options are the Wilson score interval (the default; Wilson, 1927),
  which Newcombe (1998) recommends over the Wald interval; the
  Agresti-Coull adjusted Wald interval (Agresti & Coull, 1998); and the
  Clopper-Pearson exact interval (Clopper & Pearson, 1934), which is
  conservative. Printed output names the method, the interval level, and
  the method’s limits.
- The new interval columns have their own names, so they never collide
  with the Aiken’s V `ci_low` and `ci_high` columns in
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md).
- Point estimates are unchanged.

## contentvalidR 0.2.0

Second public release. v0.1.0 established three item-level workflows;
v0.2.0 adds the two questions those workflows could not answer — whether
conclusions depend on the particular judges used, and whether the item
set covers its intended domain — together with multi-round comparison,
expert-panel planning, reporting helpers, and a substantial rework of
how results explain themselves.

The package continues to declare `Imports: stats` only. Every method
here is implemented in base R, so the package installs without a
compiler toolchain.

New flagship workflows:
[`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
and
[`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md).
New supporting functions:
[`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md),
[`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md),
[`similarity_from_sort()`](https://juhalt.github.io/contentvalidR/reference/similarity_from_sort.md),
[`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md),
[`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md),
[`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md),
[`contentvalid_glossary()`](https://juhalt.github.io/contentvalidR/reference/contentvalid_glossary.md),
and an [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
method for workflow objects.

### Multi-round comparison, planning, and reporting

- Added
  [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md),
  comparing two or more fitted workflow objects from successive pretest
  rounds. Reports each unit’s status in every round, whether it
  strengthened, weakened, or held, and which units entered or left the
  item set.
- [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
  also compares the `settings` of each round and marks the comparison as
  not comparable when they differ. This is the audit trail the
  workstream called for: a status change under a changed criterion may
  reflect only the changed rule, and the output says so rather than
  letting a bookkeeping change read as progress.
- Comparisons across different workflows are refused, since status
  labels from different workflows rest on different criteria.
- Added
  [`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md),
  reporting the exact probability that an item clears its expert-panel
  criterion at a given panel size and assumed endorsement probability,
  for the panel-size I-CVI guideline or the Lawshe CVR critical count.
  It reports the consequences of the panel sizes asked about rather than
  recommending one.
- [`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md)
  makes the I-CVI criterion’s step visible instead of smoothing it:
  because the guideline requires unanimity up to five experts and 0.78
  from six, a fourth or fifth expert *lowers* the probability of
  clearing while a sixth raises it sharply. The plot is drawn as a step
  function for the same reason.
- [`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md)
  accepts a `response_rate` below 1, averaging over the realized panel
  size rather than assuming the invited panel arrives intact, which also
  captures the criterion that a smaller realized panel triggers.
- Added an
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) method
  for workflow objects, returning results or the scale summary as a
  plain data frame with a `workflow` column so tables from several
  analyses stack without losing their identity.
- Added
  [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md),
  building a manuscript-ready table as a data frame or as Markdown for
  Quarto and R Markdown. Markdown is generated directly, so no reporting
  package is required and none is added as a dependency. Analysis
  settings travel with Markdown output as an attribute, and columns that
  are entirely missing are dropped.
- No helper is provided that returns “the items that passed.” Filtering
  on status is a substantive decision that belongs in the user’s own
  visible code, and `Review` never means an item must be dropped.

### Interpretable output

- Printed workflow output now defines the abbreviated quantities it
  reports. Each flagship workflow prints a key explaining, in plain
  language, what its columns measure and which direction is stronger,
  followed by the meaning of the shared status labels and a note
  connecting each workflow’s own recommendation wording to them.
- Added
  [`contentvalid_glossary()`](https://juhalt.github.io/contentvalidR/reference/contentvalid_glossary.md),
  a single source of those definitions. The inline keys and the glossary
  read from the same table, so a term cannot be defined differently in
  two places.
- Inline keys can be suppressed with
  `options(contentvalidR.show_key = FALSE)` once the terminology is
  familiar. Substantive cautions are never suppressed by that option.
- Benchmark output now states that strength labels are percentile
  positions relative to published scales and are **not comparable across
  indices**. This addresses a genuine misreading: HTC is an average
  rating while HTD is a difference between ratings, so a scale-level HTC
  of 0.83 is labeled `Weak` in the same row where an HTD of 0.44 is
  labeled `Very Strong`. Output now explains why, rather than leaving
  the contrast looking like an error.
- Added a “How to Read contentvalidR Output” vignette aimed at readers
  meeting these methods for the first time: an annotated walkthrough of
  every flagship workflow’s output field by field, a section on the
  benchmark trap above, a list of common misreadings, and worked
  manuscript language that reports what the analysis does and does not
  establish.
- Added regression coverage asserting that interpretive wording is
  present and stable, that every term shown in a key is defined in the
  glossary, and that the documented HTC/HTD contrast still occurs in the
  shipped example data, so the explanation cannot drift away from the
  behavior it explains.

### Domain coverage and content structure

- Added
  [`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md),
  a flagship workflow assessing whether an item set spans its intended
  content domain. Its `results` table has one row per blueprint cell,
  supporting construct-only or crossed construct-by-facet tables of
  specifications.
- Empty, thinly covered, and over-represented cells are reported against
  explicit, user-settable thresholds rather than silent defaults, and
  over-representation is documented as an attention-drawing heuristic
  rather than a standard. Intended item counts can be supplied through
  `targets` so expected shares come from the blueprint instead of an
  assumption of equal cells.
- Detecting a cell that the blueprint intends but no item addresses
  requires the full cell list to be supplied through `domain`. When it
  is omitted, the output states plainly that empty cells could not be
  detected, rather than implying full coverage.
- Added
  [`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md),
  implementing the multidimensional scaling and hierarchical cluster
  analysis of expert item-similarity data described by Sireci and
  Geisinger (1992, 1995). Correspondence between recovered clusters and
  blueprint cells is quantified with the chance-corrected adjusted Rand
  index and reported alongside the raw cross-tabulation.
- Multidimensional scaling fit is reported across dimensionalities with
  Kruskal stress-1 and its conventional descriptors, documented as
  descriptive conventions rather than rules for deciding how many
  dimensions a content domain has. A requested dimensionality beyond
  what the similarities support is reduced and the reduction is
  reported.
- Added
  [`similarity_from_sort()`](https://juhalt.github.io/contentvalidR/reference/similarity_from_sort.md),
  deriving item similarities from an item-sort task as the proportion of
  judges co-assigning each pair. The documentation states why this is
  weaker evidence than pairwise similarity ratings collected for the
  purpose.
- Added
  [`plot.contentvalid_structure()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_structure.md),
  drawing the expert content map with items labeled by blueprint cell.
- Weak blueprint correspondence is framed as a reason to re-examine the
  blueprint or item wording, explicitly not as grounds for deleting
  items.

### Judge and rater heterogeneity

- Added
  [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md),
  a flagship workflow reporting how far content-validity conclusions
  depend on the particular judges who served on the panel. Unlike the
  item-oriented workflows, its `results` table has one row per judge.
- Added
  [`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md),
  implementing the generalizability-theory treatment of content-validity
  ratings in Crocker, Llabre, and Miller (1988). Reports item, judge,
  and residual variance components, generalizability (relative) and
  dependability (absolute) coefficients, and a decision study giving the
  panel size implied by a target coefficient.
- Added judge severity estimation from a many-facet Rasch model fitted
  as a logistic regression, following the generalized linear model
  formulation of de Boeck and Wilson (2004). Estimation is joint maximum
  likelihood with the standard Wright-Douglas bias correction applied
  and reported; the documentation states that the correction reduces
  rather than removes that bias, and that marginal maximum likelihood is
  preferable where precise calibration matters.
- Judges and items showing no variation in the dichotomized relevance
  decision are excluded from the facets model and reported, rather than
  producing infinite estimates. Because near-complete agreement is
  common in relevance ratings, severity in raw rating points is always
  reported and is used for flagging whenever the logit model is not
  estimable.
- Added descriptive rater-effect summaries for severity,
  differentiation, and central versus extreme category use, following
  the effects named in Engelhard (1994). Halo is deliberately not
  estimated from a single-dimension design, where it is not separable
  from low differentiation.
- Added leave-one-judge-out influence diagnostics identifying items
  whose CVI-based review status would change if any single judge were
  removed, and stating in the output that removing a judge also reduces
  the panel size and can therefore change the CVI criterion itself.
- Output states that a judge flagged for `Review` is not a judge to
  delete: disagreement may be substantive expertise, and the flag marks
  where a conclusion rests on one person’s ratings.
- Zero item-level true-score variance is now reported as a descriptive
  result explaining that judges did not distinguish the items, rather
  than as weak generalizability, and explicitly notes that a uniformly
  relevant item set produces the same value.

### Licensing and project infrastructure

- Relicensed the source to GNU GPL version 3 only (`GPL-3.0-only`; R
  metadata `GPL-3`), retaining the original MIT notice in `inst/NOTICE`.
  The previously published v0.1.0 release keeps its original MIT terms;
  this release does not relicense it retroactively.
- Stamped citation metadata to the released version and aligned the
  README release-status paragraph and roadmap links with the issues and
  milestone they track.
- Added repository infrastructure: contributing, support, security and
  code-of-conduct documents, issue and pull-request templates, and
  pkgdown and test-coverage workflows alongside the existing check
  matrix.
- Replaced the completed pre-v0.1 release roadmap with an active
  post-release development plan, and removed the obsolete committed
  `DESCRIPTION.bak` file.
- Hardened the Ubuntu GitHub Actions setup against stale Google Chrome
  apt repository metadata.
- CRAN submission is deferred to v0.3.0 and tracked separately, so that
  the completed v0.2.0 workstreams reach users through GitHub and the
  R-universe without waiting on a submission round.

## contentvalidR 0.1.0

### First public release

- First public release of `contentvalidR`, providing reproducible
  quantitative tools for substantive and content-oriented scale
  pretesting.
- The recommended API centers on three complementary workflows:
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  for item sorting,
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
  for construct ratings, and
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  for relevance, essentiality, and congruence expert panels.
- Item-sort inference combines Anderson-Gerbing Psa/Csv indices with
  exact Howard-Melloy target-count inference and scale-level Colquitt et
  al. empirical interpretation benchmarks.
- Construct-rating analyses implement Hinkin-Tracey correspondence and
  distinctiveness, repeated-measures item screening with
  Greenhouse-Geisser correction, planned target-versus-orbiting
  contrasts, and Colquitt et al. scale-level interpretation.
- Expert-panel analyses support Aiken’s V with Penfield-Giacobbi score
  confidence intervals, Lawshe CVR with exact inference, CVI/modified
  kappa, and item-objective congruence.
- Flagship workflow objects share a stable user-facing structure, common
  status terminology, informative print/summary/plot methods, explicit
  missingness and design metadata, and restrained review
  recommendations.
- The release includes deterministic example data,
  workflow/design/reporting vignettes, manuscript-ready reporting
  examples, citation metadata, extensive regression and
  boundary-condition tests, and a cross-platform release matrix
  including a dedicated R-devel `--as-cran` NOTE-as-failure gate.
- Quantitative screening is explicitly framed as one component of a
  broader validity argument rather than an automatic item-retention or
  deletion rule.

## contentvalidR 0.0.8.9000

### CRAN and release hardening

- Added a dedicated CRAN-style GitHub Actions job on R-devel with
  NOTE-as-failure, while retaining release/oldrel/devel checks across
  Windows, macOS, and Linux.
- Updated the workflow to `actions/checkout@v7` and current
  `r-lib/actions@v2` conventions.
- Hardened source-package exclusions for generated pkgdown output, CRAN
  submission metadata, check directories, and source tarballs.
- Added a reproducible `data-raw/release-check.R` developer checklist
  covering documentation, tests, README, standard and `--as-cran`
  checks, optional URL/spelling audits, and pkgdown construction.
- Added a draft `cran-comments.md` for the first submission; it is
  excluded from the built package and must be populated with actual
  final check results before submission.
- Synchronized the development roadmap through v0.0.7 and moved the
  remaining CI/public-repository verification items into the v0.0.8
  release checklist.

## contentvalidR 0.0.7.9000

### Documentation and reproducibility

- Added five deterministic, human-readable example datasets for
  item-sort, construct-rating, and all three expert-panel tasks, plus a
  base-R `data-raw/` provenance script that regenerates them.
- Added a manuscript-ready reporting vignette with conservative
  methods/results scaffolds, reproducibility guidance, and examples of
  language that avoids treating statistical review flags as automatic
  validity decisions.
- Added `inst/CITATION` for the package and a centralized
  `inst/REFERENCES.bib` bibliography covering the release-defining
  methods and verified DOIs.
- Completed missing DOI metadata in core function references for Aiken
  V, Hinkin-Tracey ratings, Lawshe CVR, Penfield-Giacobbi score
  intervals, and IOC-related sources.
- Added pkgdown reference/article organization that foregrounds the
  three flagship workflows and clearly separates auxiliary compatibility
  helpers.
- Added clean-install tests for documentation assets, example-data
  schemas, citation metadata, and the pkgdown/reference structure.

## contentvalidR 0.0.6.9000

### Stable user-facing workflow API

- Harmonized
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md),
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md),
  and
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  around a common workflow-object contract: `results`, `scale_summary`,
  `settings`, `design`, and `details`, with a shared
  `contentvalid_workflow` superclass.
- Added a standardized `status` field (`Supported`, `Review`,
  `Insufficient data`, or `Descriptive only`) while preserving
  method-specific `recommendation` wording such as `Retain`,
  `Strong support`, and `Target favored`.
- Harmonized [`summary()`](https://rdrr.io/r/base/summary.html) objects
  around common counts, reviewed-item tables, scale summaries, settings,
  and design metadata; retained `n_retain`, expert `scale`/`flagged`,
  and rating `contrasts` compatibility aliases.
- Standardized design metadata for effective judge ranges and
  missingness reporting across item-sort, construct-rating, and
  expert-panel workflows.
- Standardized validation of `digits` and plot `show_legend` controls
  across the primary workflow methods and exact sort-power planning
  object.
- Added compatibility handling so pre-v0.0.6 expert workflow objects
  remain printable and summarizable.
- Reviewed low-level function names and retained the existing public
  names through v0.1.0; auxiliary diagnostic, simulation, agreement, and
  Q-factor helpers remain available but are not promoted as flagship
  workflows.
- Added API regression tests and updated README/getting-started guidance
  for the unified workflow contract.

## contentvalidR 0.0.5.9000

### Release hardening

- Added centralized validation for logical flags and column-name
  arguments used across public workflows.
- Hardened rating data against non-finite values, malformed/duplicated
  target maps, empty identifiers, and ambiguous multi-scale `orbiting_r`
  specifications.
- Added clearer safeguards for within- versus between-judge ANOVA
  designs and for distinctiveness analyses with fewer than two construct
  definitions.
- Hardened expert-panel congruence target mappings, Aiken/CVI/CVR/IOC
  missing-data flags, alpha/seed/bootstrap inputs, and Colquitt
  benchmark input handling.
- Added defensive validation to legacy/auxiliary Q-factor, agreement,
  and simulation helpers while keeping them outside the recommended
  workflow surface.
- Added a dedicated v0.0.5 regression suite for malformed inputs,
  degenerate designs, legacy-helper contracts, and S3 workflow return
  contracts.
- Added boundary-focused regression coverage for all-missing item
  columns, tiny expert panels, zero-variance/tied rating profiles,
  degenerate diagnostic 2 x 2 tables, and all-missing workflow plots.
- Hardened exact item-sort inputs against non-finite
  counts/probabilities, made Aiken bootstrap intervals safe for
  all-missing item columns, and rejected whitespace-only target
  labels/target-column names.
- Represented unattainable exact CVR critical counts as `NA` (rather
  than an out-of-range sentinel) and hardened regression tests against
  brittle error-message wording.
- Closed the v0.0.5 public-API audit with an explicit namespace/export
  contract and S3 registration regression tests; corrected the generated
  namespace snapshot so
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  is available in clean installs and vignette builds.

## contentvalidR 0.0.4.9000

#### Final visualization polish

- Deterministically stagger nearby target-scale labels on Psa/Csv and
  HTC/HTD evidence maps so similar scale means remain legible without
  manual annotation.
- Draw the exact critical-Psa planning view as an integer-N step
  function, with requested design points overlaid, to reflect the
  discrete binomial retention rule rather than implying smooth
  interpolation.
- Added regression tests for map-label separation and the full integer
  critical-Psa curve.

#### Visualization polish

- Tightened default axis labels and plot keys so diagnostic graphics
  remain readable in smaller RStudio plotting panes.
- Moved profile/expert plot keys into reserved top space and moved
  item-sort power keys to a low-conflict location.
- Added `show_legend = FALSE` to workflow plot methods for
  compact/custom reporting.
- Reduced map-label collisions by separating item labels from
  target-scale-mean labels.
- Fixed the expert-panel vignette plotting object name and aligned the
  item-sort vignette index title with its YAML title.

### Visualization and roadmap closure

- Added correspondence-distinctiveness evidence maps for item-sort
  (Psa/Csv) and construct-rating (HTC/HTD) workflows, with target-scale
  means shown separately from item points.
- Added a Hinkin-Tracey target-versus-strongest-competitor gap plot and
  strengthened expert-panel plots for Aiken V/I-CVI, CVR critical
  values, and IOC target-versus-competitor margins.
- Added plotting for exact item-sort power and the critical observed-Psa
  boundary.
- Added canonical published/hand-worked reference tests, including
  Hinkin-Tracey Study 1 mean ratings, Polit-Beck-Owen modified kappa,
  and the Ayre-Scally N=10 CVR boundary.
- Closed the Anderson-Gerbing legacy-inference decision: Psa/Csv remain
  supported, but the obsolete critical-Csv decision rule is not exposed
  as an alternate workflow because Howard-Melloy is applicable to
  multi-choice sorts and agrees in the original two-choice case.

### Expert-panel workflow and repository hygiene

- Added
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  with relevance, essentiality, and congruence modes plus informative
  [`print()`](https://rdrr.io/r/base/print.html),
  [`summary()`](https://rdrr.io/r/base/summary.html), and
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods.
- Hardened Aiken’s V and made the Penfield-Giacobbi score confidence
  interval the default deterministic interval; bootstrap intervals
  remain available.
- Extended
  [`cvr()`](https://juhalt.github.io/contentvalidR/reference/cvr.md) to
  support item-specific panel sizes and judge-by-item 0/1 input, with
  exact one-sided binomial p-values and critical counts following Ayre
  and Scally’s revisiting of Lawshe’s method.
- Hardened
  [`ioc()`](https://juhalt.github.io/contentvalidR/reference/ioc.md)
  input validation, duplicate detection, and missing-data reporting.
- Added common panel-size CVI guidelines to the user-facing relevance
  workflow while explicitly treating them as review aids rather than
  universal validity cutoffs.
- Updated GitHub Actions from `actions/checkout@v4` to the current
  Node-24-compatible `actions/checkout@v7` line.
- Expanded public README guidance and added a dedicated expert-panel
  vignette.

## contentvalidR 0.0.3.9000

### Modern construct-rating workflow

- Added
  [`htc()`](https://juhalt.github.io/contentvalidR/reference/htc.md) and
  [`htd()`](https://juhalt.github.io/contentvalidR/reference/htd.md) for
  Hinkin-Tracey definitional correspondence and distinctiveness, with
  explicit rating-anchor validation.
- Rebuilt
  [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
  around the fully crossed within-judge design used by the Hinkin-Tracey
  rating procedure. The function now uses a one-way repeated- measures
  ANOVA with Greenhouse-Geisser corrected omnibus inference plus planned
  target-versus-orbiting contrasts and retains a between-judge path only
  for genuinely independent designs. Raw omnibus p values remain
  available for transparency.
- Added
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
  as the recommended user-facing construct-rating workflow, including
  strongest-competitor diagnostics, Retain/Review/ Insufficient-data
  screening, and narrative print/summary output.
- Extended Colquitt et al. (2019) scale-level interpretation to HTC and
  HTD, including focal-orbiting-correlation-conditional norms and
  expert-judge suppression.
- Added
  [`plot.contentvalid_rating()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_rating.md)
  for dependency-free HTC/HTD item plots.
- Added a dedicated Hinkin-Tracey-to-Colquitt vignette and expanded
  tests for rating indices, repeated-measures inference, incomplete
  profiles, and user-facing output.

## contentvalidR 0.0.2.9000

### Modern item-sort workflow

- Added Colquitt et al. (2019) empirical Psa/Csv interpretation bands,
  including overall and focal-orbiting-correlation-conditional norms.
- Colquitt labels are applied to target-scale averages, matching how the
  published norms were constructed, rather than being presented as
  validated item-level cutoffs.
- [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  now reports target-scale definitional correspondence and
  distinctiveness alongside Howard-Melloy item-level Retain/Review
  decisions.
- Added optional focal-orbiting correlations and explicit naive/expert
  judge handling; Colquitt norms are suppressed for expert panels.
- [`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md)
  now reports the strongest competing construct(s), making item
  confusion easier to diagnose.
- Added
  [`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md)
  for exact binomial design/power planning.
- Added
  [`plot.contentvalid_sort()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_sort.md)
  for dependency-free item-level Psa/Csv plots.
- Added a dedicated item-sort vignette and expanded regression tests.

## contentvalidR 0.0.1.9000

### Methodological foundation

- Fixed
  [`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md)
  when all non-target assignments fall in a single construct; unanimous
  assignment to the same wrong construct now correctly yields
  `Csv = -1`.
- [`compute_psa()`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md)
  and
  [`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md)
  now use non-missing itemwise denominators, report `n_total`, `n`, and
  `n_missing`, and validate duplicate item-rater rows and inconsistent
  target mappings.
- Corrected Polit-Beck-Owen modified kappa in
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) to
  use the probability of exactly `A` agreements, and added S-CVI/UA plus
  item-specific effective judge counts.
- Corrected confusion-matrix orientation in
  [`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md)
  and changed phi calculations to preserve the direction of association.
- Reproducibility diagnostics now retain a full 2 x 2 table even when a
  decision level is absent.
- Clarified
  [`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md)
  as exact Howard-Melloy target-count inference and added the critical
  target-assignment count to its output.
- Added
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  as the first recommended user-facing workflow, with classed results,
  informative
  [`print()`](https://rdrr.io/r/base/print.html)/[`summary()`](https://rdrr.io/r/base/summary.html)
  methods, and restrained Retain/Review/Insufficient-data
  recommendations.
- Replaced the placeholder unit test with substantive regression and
  edge-case tests.
- Consolidated GitHub Actions into one cross-platform R CMD check
  workflow and removed an obsolete workflow that tested unsupported R
  versions.

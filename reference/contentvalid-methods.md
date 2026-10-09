# Printing, summarizing, and plotting contentvalidR results

Every contentvalidR result has a
[`print()`](https://rdrr.io/r/base/print.html) method, except those of
three auxiliary helpers:
[`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
returns a plain list, and
[`simulate_csv_power()`](https://juhalt.github.io/contentvalidR/reference/simulate_csv_power.md)
and
[`simulate_anova_power()`](https://juhalt.github.io/contentvalidR/reference/simulate_anova_power.md)
return a number. Nearly every result with a
[`print()`](https://rdrr.io/r/base/print.html) method also has
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html). The six
workflows and
[`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
also have [`summary()`](https://rdrr.io/r/base/summary.html), and the
results that have a figure have
[`plot()`](https://rdrr.io/r/graphics/plot.default.html). This page says
what each method does for each kind of result. The function that made a
result documents the result itself, such as the columns of a workflow's
`results`.

## Value

- [`print()`](https://rdrr.io/r/base/print.html) returns its argument,
  invisibly.

- [`summary()`](https://rdrr.io/r/base/summary.html) returns a list of
  class `summary.` plus the fit's class (`summary.contentvalid_rounds`
  for a comparison of rounds), holding the elements named under
  "summary()" above.

- [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
  a data frame.

- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) of a
  judge-heterogeneity fit, a coverage analysis, or a comparison of
  rounds returns nothing: it stops with an error whose message says
  where to look instead.

## print()

Every printout follows the style shared with nomologR (see
[contentvalidR-package](https://juhalt.github.io/contentvalidR/reference/contentvalidR-package.md)):
a header naming the object's class and what it holds, then the facts of
the design, then the verdict, then tables with numbers in APA style and,
for most results, a key to the columns and decisions shown. A printout
ends with a line pointing to what else the object holds. Only the
display is rounded: the object keeps every value at full precision.
[`print()`](https://rdrr.io/r/base/print.html) returns its argument
invisibly.

Most methods take `digits`, the decimal places for estimates; *p* values
always get three. The item-sort and expert-panel printouts also take
`legacy`, which shows the earlier published rules beside the decision
without changing it, and the glossary takes `width`.
`options(contentvalidR.show_key = FALSE)` hides the keys.

What each kind of result prints:

- **Workflow fits** from
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md),
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md),
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md),
  [`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md),
  [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md),
  and
  [`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md):
  the full evidence, one row per unit of analysis, with the scale- or
  panel-level evidence and what the evidence does not decide.

- **Component indices** from
  [`compute_psa()`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md),
  [`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md),
  [`htc()`](https://juhalt.github.io/contentvalidR/reference/htc.md),
  [`htd()`](https://juhalt.github.io/contentvalidR/reference/htd.md),
  [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md),
  [`aikens_v()`](https://juhalt.github.io/contentvalidR/reference/aikens_v.md),
  [`cvr()`](https://juhalt.github.io/contentvalidR/reference/cvr.md),
  [`ioc()`](https://juhalt.github.io/contentvalidR/reference/ioc.md),
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md),
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md),
  [`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md),
  [`interpret_colquitt()`](https://juhalt.github.io/contentvalidR/reference/interpret_colquitt.md),
  [`colquitt_benchmarks()`](https://juhalt.github.io/contentvalidR/reference/colquitt_benchmarks.md),
  and
  [`similarity_from_sort()`](https://juhalt.github.io/contentvalidR/reference/similarity_from_sort.md):
  the index as a formatted table or a short report. Apart from printing,
  these results behave as the plain data frame, list, or matrix they
  hold.

- **Planning and diagnostics** from
  [`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md),
  [`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md),
  [`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md),
  [`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md),
  [`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md),
  and
  [`reproducibility_phi()`](https://juhalt.github.io/contentvalidR/reference/reproducibility_phi.md):
  the table or test, with a note on how to read it.

- **Reporting and exchange.**
  [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
  prints its APA table with the table's general note, and with
  `format = "markdown"` only the Markdown lines to paste (print them
  from a chunk with `results = "asis"` to render the table).
  [`content_evidence()`](https://juhalt.github.io/contentvalidR/reference/content_evidence.md)
  prints the review stages side by side, item by item;
  [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
  the items carried forward and held back;
  [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
  each unit's status by round; and
  [`contentvalid_glossary()`](https://juhalt.github.io/contentvalidR/reference/contentvalid_glossary.md)
  the definitions.

## summary()

[`summary()`](https://rdrr.io/r/base/summary.html) of a workflow fit
returns an object of class `summary.` plus the fit's class, such as
`summary.contentvalid_sort`. It prints the counts by status, the scale-
or panel-level evidence, and a "Flagged" section with a sentence for
each unit to look at again. The object is a list holding, among others,
`n_items`, `n_supported`, `n_review`, `n_insufficient`, `n_descriptive`,
`scale_summary`, `reviewed_items` (the units whose status is `Review` or
`Insufficient data`), `settings`, and `design`. The Delphi summary adds
`panel` and `stability_method`; the expert-panel summary `mode` and,
when an agreement coefficient was computed, `agreement`; the judge
summary `gtheory`, `influence_items`, and `reviewed_judges`; and the
coverage summary `gaps`, the cells under review.

[`summary()`](https://rdrr.io/r/base/summary.html) of a
[`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
result returns a `summary.contentvalid_rounds` list whose `changed`
holds the units that changed status between the first and last rounds,
entered or left, or appeared only in between, with the counts in
`summary`.

## plot()

Figures are drawn with base graphics, and each has its own help page:
[`plot.contentvalid_sort()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_sort.md),
[`plot.contentvalid_rating()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_rating.md),
[`plot.contentvalid_expert()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_expert.md),
[`plot.contentvalid_delphi()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_delphi.md),
[`plot.contentvalid_evidence()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_evidence.md),
[`plot.contentvalid_structure()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_structure.md),
[`plot.contentvalid_sort_power()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_sort_power.md),
and
[`plot.contentvalid_expert_power()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_expert_power.md).

A judge-heterogeneity fit, a coverage analysis, and a comparison of
rounds have no figure. Their
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods stop
with a message that says where to look instead. A coverage analysis
given similarity data draws its content map with
`plot(x$details$structure)`.

## as.data.frame()

A workflow fit returns its `results` or its `scale_summary`
([`as.data.frame.contentvalid_workflow()`](https://juhalt.github.io/contentvalidR/reference/as.data.frame.contentvalid_workflow.md)).
A component index returns the plain data frame, list, or matrix it
holds, coerced to a data frame, without its print class.
[`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md)
returns its table of text, and
[`content_evidence()`](https://juhalt.github.io/contentvalidR/reference/content_evidence.md)
its long table of evidence, one row per item and stage. The other
results are covered in
[contentvalid-data-frames](https://juhalt.github.io/contentvalidR/reference/contentvalid-data-frames.md).

## Examples

``` r
sort_dat <- data.frame(
  item = rep(c("A1", "A2", "A3"), each = 20),
  rater = rep(1:20, 3),
  target_construct = "A",
  assigned_construct = c(
    rep("A", 18), rep("B", 2),
    rep("A", 16), rep("B", 4),
    rep("A", 12), rep("B", 8)
  )
)
fit <- sort_validity(sort_dat)
print(fit, digits = 3)
#> <contentvalid_sort> Item-sort analysis
#> Items: 3 | Judges: 20 | Target constructs: 1
#> Test: Howard-Melloy exact target-count test (p0 = .50, alpha = .05)
#> Judges: naive, meaning drawn from the kind of people who will answer the
#> items.
#> 
#> 2 of 3 items meet the exact target-assignment criterion.
#> Flagged for review: A3
#> 
#> Item-level evidence
#>   Item  Target  Decision  Judges   Psa        95% CI   Csv  Competitor       p
#>   A1    A       Retain     18/20  .900  [.699, .972]  .800  B           < .001
#>   A2    A       Retain     16/20  .800  [.584, .919]  .600  B             .006
#>   A3    A       Review     12/20  .600  [.387, .781]  .200  B             .252
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
#>   A           3      .767  Moderate       .533  Moderate
#>   Benchmark set: Overall (not correlation-normed)
#>   These bands come from tasks with three definitions (one focal, two
#>   orbiting); judges here used 2 (set `n_constructs` if more were offered), so
#>   the comparison is approximate. This is a contentvalidR caution: Colquitt et
#>   al. do not discuss other numbers.
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
s <- summary(fit)
s$reviewed_items$item
#> [1] "A3"
head(as.data.frame(fit, include_interpretation = FALSE))
#>    workflow item target n_total  n n_missing n_target competitor n_other_max
#> 1 item-sort   A1      A      20 20         0       18          B           2
#> 2 item-sort   A2      A      20 20         0       16          B           4
#> 3 item-sort   A3      A      20 20         0       12          B           8
#>   psa   psa_low  psa_high csv      p_value critical_n_target passes_chance
#> 1 0.9 0.6989664 0.9721335 0.8 0.0002012253                15          TRUE
#> 2 0.8 0.5839826 0.9193423 0.6 0.0059089661                15          TRUE
#> 3 0.6 0.3865815 0.7811935 0.2 0.2517223358                15         FALSE
#>   recommendation                                   issue    status
#> 1         Retain                               Supported Supported
#> 2         Retain                               Supported Supported
#> 3         Review Target favored, exact criterion not met    Review
```

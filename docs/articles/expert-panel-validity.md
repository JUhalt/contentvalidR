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

- **relevance**: Aiken’s V plus CVI and modified kappa;
- **essentiality**: Lawshe’s CVR with exact binomial inference; and
- **congruence**: Rovinelli-Hambleton IOC.

All three are quantitative complements to qualitative expert comments,
construct coverage, comprehensibility review, and other parts of the
content-validity argument.

## Relevance: Aiken V, score intervals, and CVI

Suppose six experts rate item relevance from 1 (not relevant) to 4
(highly relevant):

\
`R`` ``<-`` `[`matrix`](https://rdrr.io/r/base/matrix.html)`(`\
`  `[`c`](https://rdrr.io/r/base/c.html)`(``4``,``4``,``4``,``4``,``4``,``4``,`\
`    ``4``,``4``,``4``,``3``,``4``,``4``,`\
`    ``4``,``3``,``4``,``4``,``3``,``4``,`\
`    ``3``,``3``,``4``,``3``,``2``,``3``)``,`\
`  nrow ``=`` ``6``,`\
`  dimnames ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``NULL``, `[`paste0`](https://rdrr.io/r/base/paste.html)`(``"Item"``, ``1``:``4``)``)`\
`)`\
\
`fit`` ``<-`` `[`expert_validity`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)`(``R``, mode ``=`` ``"relevance"``, lo ``=`` ``1``, hi ``=`` ``4``)`\
`fit`\
`#> contentvalidR expert-panel analysis`\
`#> -----------------------------------`\
`#> Mode: relevance `\
`#> Items: 4 | Experts/item: 6 `\
`#> Mean Aiken V: 0.875 | S-CVI/Ave: 0.958 | S-CVI/UA: 0.75 `\
`#> Strong support: 4 | Support: 0 | Review: 0 `\
`#> `\
`#>   item N     V ci_low ci_high I_CVI kappa_mod recommendation`\
`#>  Item1 6 1.000  0.824   1.000 1.000     1.000 Strong support`\
`#>  Item2 6 0.944  0.742   0.990 1.000     1.000 Strong support`\
`#>  Item3 6 0.889  0.672   0.969 1.000     1.000 Strong support`\
`#>  Item4 6 0.667  0.437   0.837 0.833     0.816 Strong support`\
`#> `\
`#> CVI thresholds shown by the workflow are common panel-size guidelines, not universal validity cutoffs.`\
`#> `\
`#> Use quantitative indices alongside expert comments, construct coverage, and comprehensibility review.`\
[`summary`](https://rdrr.io/r/base/summary.html)`(``fit``)`\
`#> Summary of expert-panel content-validity evidence`\
`#> ---------------------------------------------`\
`#> Mode: relevance `\
`#> Supported: 4 | Review: 0`\
`#> No items were flagged by the workflow's quantitative review rules.`\
`#> `\
`#> These summaries support, but do not replace, qualitative content review.`

Aiken’s V rescales the bounded expert ratings to the 0-1 interval. The
default confidence interval is the score interval proposed by Penfield
and Giacobbi (2004), rather than a simulation-dependent bootstrap
interval. Bootstrap intervals remain available through the low-level
function:

\
[`aikens_v`](https://juhalt.github.io/contentvalidR/reference/aikens_v.md)`(``R``, lo ``=`` ``1``, hi ``=`` ``4``, ci ``=`` ``"bootstrap"``, B ``=`` ``200``, seed ``=`` ``1``)`\
`#>    item N n_missing         V    ci_low   ci_high            ci_method`\
`#> 1 Item1 6         0 1.0000000 1.0000000 1.0000000 percentile bootstrap`\
`#> 2 Item2 6         0 0.9444444 0.8333333 1.0000000 percentile bootstrap`\
`#> 3 Item3 6         0 0.8888889 0.7763889 1.0000000 percentile bootstrap`\
`#> 4 Item4 6         0 0.6666667 0.5000000 0.8333333 percentile bootstrap`

For CVI, the workflow dichotomizes ratings at `relevance_cut`. On a 1-4
scale the default is 3, so ratings of 3 or 4 count as relevant. Declare
a different threshold if the study protocol used one.

The workflow reports common panel-size I-CVI guidelines (1.00 for panels
of 3-5 experts and .78 for 6 or more) as **review aids**. They are not
presented as universal proof that an item is or is not content valid.
Modified kappa provides a chance-corrected complement to I-CVI.

At the scale level, S-CVI/Ave and S-CVI/UA are reported together.
S-CVI/Ave is generally less brittle than universal agreement, but both
should be interpreted alongside the distribution of item-level evidence.

## Essentiality: Lawshe CVR with exact critical values

Lawshe’s task asks experts whether an item is essential. With twelve
experts:

\
[`expert_validity`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``10``, ``8``, ``6``)``, mode ``=`` ``"essentiality"``, N ``=`` ``12``)`\
`#> contentvalidR expert-panel analysis`\
`#> -----------------------------------`\
`#> Mode: essentiality `\
`#> Items: 3 | Experts/item: 12 `\
`#> Method: Lawshe CVR with exact binomial critical values `\
`#> `\
`#>   item ne  N   cvr p_value critical_ne recommendation`\
`#>  Item1 10 12 0.667   0.019          10      Supported`\
`#>  Item2  8 12 0.333   0.194          10         Review`\
`#>  Item3  6 12 0.000   0.613          10         Review`\
`#> `\
`#> Use quantitative indices alongside expert comments, construct coverage, and comprehensibility review.`

[`cvr()`](https://juhalt.github.io/contentvalidR/reference/cvr.md)
derives the smallest essential count whose one-sided binomial upper-tail
probability is no greater than `alpha`. This makes the panel-size
dependency explicit and follows the exact-probability logic revisited by
Ayre and Scally (2014).

Judge-by-item binary data can be supplied directly:

\
`E`` ``<-`` `[`cbind`](https://rdrr.io/r/base/cbind.html)`(`\
`  Item1 ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``1``,``1``,``1``,``1``,``1``,``1``,``1``,``1``)``,`\
`  Item2 ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``1``,``1``,``1``,``1``,``1``,``0``,``0``,``0``)`\
`)`\
[`expert_validity`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)`(``E``, mode ``=`` ``"essentiality"``)`\
`#> contentvalidR expert-panel analysis`\
`#> -----------------------------------`\
`#> Mode: essentiality `\
`#> Items: 2 | Experts/item: 8 `\
`#> Method: Lawshe CVR with exact binomial critical values `\
`#> `\
`#>   item ne N  cvr p_value critical_ne recommendation`\
`#>  Item1  8 8 1.00   0.004           7      Supported`\
`#>  Item2  5 8 0.25   0.363           7         Review`\
`#> `\
`#> Use quantitative indices alongside expert comments, construct coverage, and comprehensibility review.`

A failure to clear the exact criterion is labeled `Review`, not
automatic deletion. Expert rationales and domain coverage matter when
deciding whether an item should be rewritten, retained for breadth, or
removed.

## Congruence: item-objective alignment

IOC uses expert ratings of -1, 0, and +1 for item-objective congruence.
A target mapping lets the workflow compare intended and competing
objectives:

\
`d`` ``<-`` `[`expand.grid`](https://rdrr.io/r/base/expand.grid.html)`(`\
`  item ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"I1"``, ``"I2"``)``,`\
`  judge ``=`` ``1``:``4``,`\
`  objective ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"A"``, ``"B"``)`\
`)`\
`d``$``target_objective`` ``<-`` `[`ifelse`](https://rdrr.io/r/base/ifelse.html)`(``d``$``item`` ``==`` ``"I1"``, ``"A"``, ``"B"``)`\
`d``$``score`` ``<-`` `[`ifelse`](https://rdrr.io/r/base/ifelse.html)`(``d``$``objective`` ``==`` ``d``$``target_objective``, ``1``, ``-``1``)`\
\
[`expert_validity`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)`(``d``, mode ``=`` ``"congruence"``)`\
`#> contentvalidR expert-panel analysis`\
`#> -----------------------------------`\
`#> Mode: congruence `\
`#> Items: 2 | Experts/cell: 4 | Objectives: 2 `\
`#> Method: Rovinelli-Hambleton item-objective congruence `\
`#> `\
`#>  item target target_ioc strongest_competitor competitor_ioc margin`\
`#>    I1      A          1                    B             -1      2`\
`#>    I2      B          1                    A             -1      2`\
`#>  recommendation`\
`#>  Target favored`\
`#>  Target favored`\
`#>                                                                                                      interpretation`\
`#>  The intended objective has the highest IOC; use the margin and expert comments to judge practical distinctiveness.`\
`#>  The intended objective has the highest IOC; use the margin and expert comments to judge practical distinctiveness.`\
`#>     status`\
`#>  Supported`\
`#>  Supported`\
`#> `\
`#> Use quantitative indices alongside expert comments, construct coverage, and comprehensibility review.`

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

\
[`plot`](https://rdrr.io/r/graphics/plot.default.html)`(`[`expert_validity`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)`(``R``, mode ``=`` ``"relevance"``, lo ``=`` ``1``, hi ``=`` ``4``)``)`

![](expert-panel-validity_files/figure-html/expert-plots-1.png)

\
[`plot`](https://rdrr.io/r/graphics/plot.default.html)`(`[`expert_validity`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``10``, ``8``, ``6``)``, mode ``=`` ``"essentiality"``, N ``=`` ``12``)``)`

![](expert-panel-validity_files/figure-html/expert-plots-2.png)

\
[`plot`](https://rdrr.io/r/graphics/plot.default.html)`(`[`expert_validity`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)`(``d``, mode ``=`` ``"congruence"``)``)`

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
3.  the index and inference/CI procedure used;
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

Penfield, R. D., & Giacobbi, P. R., Jr. (2004). Applying a score
confidence interval to Aiken’s item content-relevance index.
*Measurement in Physical Education and Exercise Science, 8*(4), 213-225.
<https://doi.org/10.1207/S15327841MPEE0804_3>

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

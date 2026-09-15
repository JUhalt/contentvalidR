# Glossary of contentvalidR indices and status terms

Plain-language definitions of every abbreviated quantity the package
reports, and of the status labels shared by all flagship workflows.

The same definitions are printed beneath workflow output, so what you
read here is what appears alongside your results. Set
`options(contentvalidR.show_key = FALSE)` to suppress those inline keys
once the terms are familiar.

## Usage

``` r
contentvalid_glossary(workflow = NULL)
```

## Arguments

- workflow:

  Optionally restrict to one workflow: `"item-sort"`,
  `"construct-rating"`, `"expert-panel"`, `"judge-heterogeneity"`, or
  `"domain-coverage"`.

## Value

An object of class `contentvalid_glossary`: a data frame of `term`,
`workflow`, `label`, `definition`, and `range`, carrying the status
definitions as the `"statuses"` attribute.

## A note on benchmark labels

Strength labels such as `Strong` or `Weak` from
[`interpret_colquitt()`](https://juhalt.github.io/contentvalidR/reference/interpret_colquitt.md)
are percentile positions relative to scales published in the measurement
literature. They are not absolute judgments, and they are not comparable
across indices: HTC and HTD sit on different scales with different
typical values, so an HTC of 0.83 can be labeled `Weak` in the same
analysis where an HTD of 0.44 is labeled `Very Strong`. Compare each
index against its own benchmark, never against another index's number.

## See also

[`interpret_colquitt()`](https://juhalt.github.io/contentvalidR/reference/interpret_colquitt.md)
for the benchmark bands themselves.

## Examples

``` r
contentvalid_glossary()
#> contentvalidR glossary
#> 
#> item-sort
#>   psa -- Proportion of Substantive Agreement. Share of judges who assigned
#>       the item to the construct it was written for. Higher means judges
#>       recognized the item as belonging where you intended. (0 to 1; higher
#>       is stronger)
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
#>   psa_low/psa_high -- Interval for Psa. Lower and upper limits of an
#>       interval around Psa. A wide interval means few judges sorted the
#>       item, so a different sample of judges could plausibly give a quite
#>       different Psa. (between 0 and 1; the method and level are named in
#>       the output)
#> 
#> construct-rating
#>   htc -- Hinkin-Tracey Correspondence. Average rating of the item against
#>       its intended construct definition, expressed as a proportion of the
#>       rating scale. (0 to 1; higher is stronger)
#>   htd -- Hinkin-Tracey Distinctiveness. How far the intended construct's
#>       average rating exceeds the best competing construct's, as a
#>       proportion of the rating scale. It is a difference, so its typical
#>       values are far smaller than HTC's. (usually a small positive number;
#>       higher is stronger)
#> 
#> expert-panel
#>   V -- Aiken's V. Relevance index that rescales the experts' average rating
#>       to run from 0 to 1 given the bounds of the rating scale used. (0 to
#>       1; higher is stronger)
#>   I_CVI -- Item-level Content Validity Index. Proportion of experts who
#>       rated the item as relevant, after applying the relevance cut. (0 to
#>       1; compared against a panel-size guideline)
#>   I_CVI_low/I_CVI_high -- Interval for I-CVI. Lower and upper limits of an
#>       interval around I-CVI. Expert panels are usually small, so these
#>       intervals are often wide: a single I-CVI value can look more settled
#>       than the number of experts behind it supports. (between 0 and 1; the
#>       method and level are named in the output)
#>   kappa_mod -- Modified kappa. I-CVI adjusted for the chance that experts
#>       would have agreed even if rating at random. With small panels, chance
#>       agreement is substantial, which is why the raw I-CVI alone can
#>       overstate consensus. (0 to 1; higher is stronger)
#>   agreement -- Panel-level agreement. One coefficient describing how
#>       consistently the whole panel rated the item set: Krippendorff's alpha
#>       by default, or Gwet's AC1 if chosen. It is separate from modified
#>       kappa, which describes one item at a time. (1 is perfect agreement
#>       and 0 is agreement no better than chance; it can be low on a
#>       close-agreeing panel whose ratings cluster on one value)
#>   cvr -- Lawshe's Content Validity Ratio. How far the panel leans toward
#>       calling the item essential rather than merely useful. (-1 to 1; above
#>       0 means more than half the panel called it essential)
#>   ioc -- Item-Objective Congruence. How consistently experts linked the
#>       item to the objective it was written for rather than to another
#>       objective. (-1 to 1; higher is stronger)
#> 
#> judge-heterogeneity
#>   severity -- Judge severity. How harsh or lenient a judge is compared with
#>       the rest of the panel. Positive means the judge rates lower than the
#>       panel. Reported in logits from the facets model when it can be
#>       estimated, otherwise in rating points. (0 means typical of this
#>       panel)
#>   infit/outfit -- Fit mean squares. Whether a judge's pattern of decisions
#>       is as predictable as the model expects. Around 1 is expected; high
#>       values mean erratic ratings, low values mean ratings more predictable
#>       than expected. (around 1.0 is expected)
#>   differentiation -- Scale use. How widely a judge spread their ratings
#>       compared with a typical judge on this panel. Values well below 1 mean
#>       the judge distinguished less among items. (1.0 is typical of this
#>       panel)
#>   g_coefficient -- Generalizability coefficient. How dependably the ranking
#>       of items by rated relevance would reproduce with a different panel of
#>       the same size. Use it for comparative decisions such as picking the
#>       best items from a pool. (0 to 1; higher is stronger)
#>   phi_coefficient -- Dependability coefficient. How dependably the absolute
#>       level of the ratings would reproduce with a different panel of the
#>       same size. Penalized by judge severity differences, and usually the
#>       relevant one for content validity, where items are judged against a
#>       fixed standard. (0 to 1; never exceeds the generalizability
#>       coefficient)
#> 
#> domain-coverage
#>   share -- Share of items. Percentage of all items that fall in this
#>       blueprint cell. (0 to 100%)
#>   adjusted_rand -- Adjusted Rand index. How closely the groupings experts
#>       perceive match the blueprint's cells, corrected for the agreement
#>       expected by chance. (0 is chance agreement, 1 is exact; can be
#>       slightly negative)
#>   stress -- Kruskal stress-1. How much distortion was introduced by
#>       squeezing the similarity data into the chosen number of dimensions.
#>       Lower is a closer fit. (0 is perfect; below 0.10 is conventionally
#>       called fair or better)
#> 
#> status labels
#>   Supported -- The evidence met the criteria set for this analysis.
#>   Review -- Something here needs a closer look. This is not an instruction
#>       to delete anything.
#>   Insufficient data -- Too little usable data to reach a judgment.
#>   Descriptive only -- Reported for description only; no decision rule was
#>       applied.
#> 
#> Strength labels such as Strong or Weak are percentile positions 
#> relative to published scales, not absolute judgments, and are not 
#> comparable across different indices.
contentvalid_glossary("item-sort")
#> contentvalidR glossary
#> 
#> item-sort
#>   psa -- Proportion of Substantive Agreement. Share of judges who assigned
#>       the item to the construct it was written for. Higher means judges
#>       recognized the item as belonging where you intended. (0 to 1; higher
#>       is stronger)
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
#>   psa_low/psa_high -- Interval for Psa. Lower and upper limits of an
#>       interval around Psa. A wide interval means few judges sorted the
#>       item, so a different sample of judges could plausibly give a quite
#>       different Psa. (between 0 and 1; the method and level are named in
#>       the output)
#> 
#> status labels
#>   Supported -- The evidence met the criteria set for this analysis.
#>   Review -- Something here needs a closer look. This is not an instruction
#>       to delete anything.
#>   Insufficient data -- Too little usable data to reach a judgment.
#>   Descriptive only -- Reported for description only; no decision rule was
#>       applied.
#> 
#> Strength labels such as Strong or Weak are percentile positions 
#> relative to published scales, not absolute judgments, and are not 
#> comparable across different indices.
```

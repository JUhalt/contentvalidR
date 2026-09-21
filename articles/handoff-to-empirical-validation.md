# From Content Validity to Empirical Validation

## Where content validity stops

A content-validity pretest answers questions you can ask before anyone
responds to the scale: are these items relevant to the construct, does
the set cover the domain, do experts agree, and is each item congruent
with its intended objective. It cannot answer whether an item will
correlate with its construct, load on the intended factor, behave the
same across groups, or relate to other constructs as theory predicts.
Those questions need response data.

So a pretest ends with a decision: which items go forward into data
collection.
[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
packages that decision, so the item set and the reasons behind it travel
together into the next stage.

## A worked panel

Four experts rate five items for relevance on a 1-4 scale. The last item
is rated poorly, and one is borderline:

``` r

relevance <- matrix(
  c(4,4,4,3,  4,4,3,4,  3,4,4,4,  3,2,3,2,  2,2,1,2),
  nrow = 4,
  dimnames = list(NULL, paste0("Item", 1:5))
)

fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4, seed = 1)
fit$results[, c("item", "N", "V", "I_CVI", "kappa_mod", "status")]
#>    item N         V I_CVI   kappa_mod    status
#> 1 Item1 4 0.9166667   1.0  1.00000000 Supported
#> 2 Item2 4 0.9166667   1.0  1.00000000 Supported
#> 3 Item3 4 0.9166667   1.0  1.00000000 Supported
#> 4 Item4 4 0.5000000   0.5  0.20000000    Review
#> 5 Item5 4 0.2500000   0.0 -0.06666667    Review
```

## The handoff

``` r

handoff <- content_handoff(fit)
handoff
#> contentvalidR handoff (schema version 1)
#> --------------------------------------
#> Workflow: expert-panel (relevance)   contentvalidR 0.6.0.9000   2026-09-21
#> Items carried forward: 3 of 5
#> Carried when status is: Supported
#> Constructs: none in this design; the panel rated one item set.
#> Intervals carried: Aiken's V (Penfield-Giacobbi score, 95%); I-CVI (Wilson
#>   score, 95%)
#> Panel: Krippendorff's alpha (ordinal) = 0.69 (95% interval -0.27 to 0.77)
#> 
#> Held back:
#>   item status recommendation
#>  Item4 Review         Review
#>  Item5 Review         Review
#> 
#> Carry these items into the empirical workflow once response data are
#> collected. In nomologR that is nomo_screen(data, items = <handoff>), which
#> screens the same items you retained here.
#> 
#> Surviving content review is evidence about relevance, representation, and
#> expert judgment. It does not establish that an item will behave well
#> empirically: an item can be clearly relevant and still correlate poorly
#> with its construct or load on an unintended factor. Items held back are
#> listed above rather than deleted, so the record stays complete.
```

## What the object holds

``` r

handoff$items
#> [1] "Item1" "Item2" "Item3"
handoff$item_evidence
#>    item scale carried    status recommendation n_judges
#> 1 Item1  <NA>    TRUE Supported Strong support        4
#> 2 Item2  <NA>    TRUE Supported Strong support        4
#> 3 Item3  <NA>    TRUE Supported Strong support        4
#> 4 Item4  <NA>   FALSE    Review         Review        4
#> 5 Item5  <NA>   FALSE    Review         Review        4
#>                                                                                               rule
#> 1 I-CVI >= 1 (common panel-size guideline for 4 experts); modified kappa > 0.74 for strong support
#> 2 I-CVI >= 1 (common panel-size guideline for 4 experts); modified kappa > 0.74 for strong support
#> 3 I-CVI >= 1 (common panel-size guideline for 4 experts); modified kappa > 0.74 for strong support
#> 4 I-CVI >= 1 (common panel-size guideline for 4 experts); modified kappa > 0.74 for strong support
#> 5 I-CVI >= 1 (common panel-size guideline for 4 experts); modified kappa > 0.74 for strong support
#>   round
#> 1     1
#> 2     1
#> 3     1
#> 4     1
#> 5     1
head(handoff$item_statistics)
#>    item statistic     value criterion round      lower     upper
#> 1 Item1 Aiken's V 0.9166667        NA     1 0.64612009 0.9851349
#> 2 Item2 Aiken's V 0.9166667        NA     1 0.64612009 0.9851349
#> 3 Item3 Aiken's V 0.9166667        NA     1 0.64612009 0.9851349
#> 4 Item4 Aiken's V 0.5000000        NA     1 0.25378160 0.7462184
#> 5 Item5 Aiken's V 0.2500000        NA     1 0.08894167 0.5323053
#> 6 Item1     I-CVI 1.0000000         1     1 0.51010916 1.0000000
#>           interval_method interval_level note
#> 1 Penfield-Giacobbi score           0.95     
#> 2 Penfield-Giacobbi score           0.95     
#> 3 Penfield-Giacobbi score           0.95     
#> 4 Penfield-Giacobbi score           0.95     
#> 5 Penfield-Giacobbi score           0.95     
#> 6            Wilson score           0.95
```

`items` is what the next stage consumes: the carried items only, so what
you read here is exactly what you pass along. `item_evidence` keeps
every reviewed item, including those held back, with the decision rule
that was applied and the effective number of judges behind it.
`item_statistics` stacks the statistics long, one row per item per
statistic, with the criterion each was compared against where the method
sets one.

``` r

str(handoff$provenance[c("schema_version", "workflow", "mode", "keep",
                         "method", "citation")])
#> List of 6
#>  $ schema_version: int 1
#>  $ workflow      : chr "expert-panel"
#>  $ mode          : chr "relevance"
#>  $ keep          : chr "Supported"
#>  $ method        : chr "Aiken V with score intervals plus CVI/modified kappa"
#>  $ citation      : chr [1:3] "Aiken (1980)" "Penfield & Giacobbi (2004)" "Polit, Beck & Owen (2007)"
```

By default only items with a `Supported` status travel. Some protocols
carry items flagged for review, on the grounds that a weak
content-validity result deserves an empirical test rather than deletion.
Say so explicitly:

``` r

content_handoff(fit, keep = c("Supported", "Review"))$items
#> [1] "Item1" "Item2" "Item3" "Item4" "Item5"
```

Items held back are never silently dropped:

``` r

handoff$item_evidence[!handoff$item_evidence$carried,
                      c("item", "status", "recommendation")]
#>    item status recommendation
#> 4 Item4 Review         Review
#> 5 Item5 Review         Review
```

## How much evidence is behind each number

A statistic from four experts is less certain than the same value from
twenty. Each statistic therefore travels with its interval, so the next
stage can see how much panel evidence stands behind it:

``` r

st <- handoff$item_statistics
st[st$statistic == "I-CVI",
   c("item", "value", "lower", "upper", "interval_method", "interval_level")]
#>     item value     lower     upper interval_method interval_level
#> 6  Item1   1.0 0.5101092 1.0000000    Wilson score           0.95
#> 7  Item2   1.0 0.5101092 1.0000000    Wilson score           0.95
#> 8  Item3   1.0 0.5101092 1.0000000    Wilson score           0.95
#> 9  Item4   0.5 0.1500390 0.8499610    Wilson score           0.95
#> 10 Item5   0.0 0.0000000 0.4898908    Wilson score           0.95
```

All four experts rated Items 1 to 3 relevant, so each has an I-CVI of 1.
With only four experts, though, the Wilson interval still reaches down
to about 0.51. A statistic with no interval, such as modified kappa, has
`NA` in all four interval columns. There, `NA` means the method defines
no interval; it does not mean a value is missing.

The agreement coefficient describes the whole panel rather than any one
item, so it travels in its own table:

``` r

handoff$panel_statistics
#>                        statistic     value criterion round      lower     upper
#> 1 Krippendorff's alpha (ordinal) 0.6925356        NA     1 -0.2666667 0.7726496
#>                        interval_method interval_level note
#> 1 item-resampling percentile bootstrap           0.95
```

The handoff reports these intervals and stops there. Whether a later
analysis should weight items by them, and how, is a question for that
analysis.

## Constructs

Item-sort and construct-rating designs map each item to a target
construct, so the handoff carries that mapping as `scales`, ready for a
workflow that models several scales at once:

``` r

sort_dat <- data.frame(
  item = rep(c("A1", "A2", "B1"), each = 12),
  rater = rep(1:12, 3),
  target_construct = c(rep("A", 24), rep("B", 12)),
  assigned_construct = c(rep("A", 11), "B", rep("A", 9), rep("B", 3),
                         rep("B", 10), rep("A", 2))
)
content_handoff(sort_validity(sort_dat), keep = c("Supported", "Review"))$scales
#> $A
#> [1] "A1" "A2"
#> 
#> $B
#> [1] "B1"
```

An expert panel rating one item set for relevance has no construct
column, so `scales` is `NULL`. That is a real difference, not a gap to
paper over: nothing in that design says which construct each item
belongs to, so a downstream workflow should screen those items rather
than invent membership for them.

## Into an empirical workflow

Once responses are collected, the item set carries into the empirical
stage. [nomologR](https://github.com/JUhalt/nomologR) is the companion
package for that stage: it begins where item-level data exist and
follows the measure through screening, dimensionality, measurement
models, reliability, invariance, and nomological networks.

``` r

# install.packages("nomologR", repos = "https://juhalt.r-universe.dev")
library(nomologR)

# `responses` is your collected data: one row per respondent, one column per item.
scr <- nomo_screen(responses, items = handoff)
scr$item_summary
```

That chunk is not evaluated here, because this vignette builds without
nomologR installed and because a content-validity pretest has no
responses to screen.

The object shape is agreed between the two packages as schema version 1,
and every field is a base type: character, logical, numeric, integer,
data frame, list, and Date. Neither package depends on the other, so any
downstream workflow can read the handoff, including one you write
yourself:

``` r

class(handoff)
#> [1] "contentvalid_handoff" "cv_handoff"           "list"
```

## What the handoff does not claim

Carrying an item forward is not a prediction that it will perform. An
item can be clearly relevant to experts and still correlate poorly with
its construct, load on an unintended factor, or behave differently
across groups. The reverse also happens: an item held back on content
grounds cannot be rescued by a strong loading, because a factor loading
says nothing about whether the item belongs to the construct as defined.

Both stages follow the same rule. Flag, explain, and document; never
silently delete. The handoff therefore carries evidence rather than
instructions, and the empirical stage is free to flag an item that
content review supported.

## Reporting the transition

A methods section can state, in one or two sentences, how many items
entered the pretest, how many were carried forward and under which rule,
and where the held-back items went. `item_evidence` is the table behind
that sentence, and `provenance` records the analysis that produced it:

``` r

ev <- handoff$item_evidence
sprintf("%d of %d items were carried forward (%s); %d were held back.",
        length(handoff$items), length(unique(ev$item)),
        paste(handoff$provenance$keep, collapse = ", "), sum(!ev$carried))
#> [1] "3 of 5 items were carried forward (Supported); 2 were held back."
```

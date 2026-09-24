# One Item Set, Both Stages

## The claim this walkthrough is testing

Content review and empirical screening are usually described as two
stages of one process, and then demonstrated separately, on different
data, in different packages. That arrangement hides the only interesting
question: what happens when the two stages disagree about the same item.

They can disagree in both directions. An item can read badly to a panel
and be caught before anyone collects a response. An item can read
perfectly, be kept by every judge, and then carry almost none of the
construct when people answer it. The second case is the reason a pretest
is not a substitute for data.

This vignette follows twelve items through both stages. The data are
**simulated** and were built so that specific items misbehave in
specific ways. Nothing here is a real instrument or a real sample. The
advantage of simulated data is that the right answer is known in
advance, so you can check whether each stage found what was actually put
there.

## The construct and the items

The construct is *Study Persistence*: the tendency to keep working on
academic tasks when they become difficult or uninteresting. It has two
facets, effort regulation (`EF`) and task focus (`TF`). A third
construct, test anxiety (`TA`), is offered to the judges as a distractor
and has no items of its own.

``` r

path <- function(f) system.file("extdata", f, package = "contentvalidR")
items <- read.csv(path("walkthrough_items.csv"), stringsAsFactors = FALSE)

items[c("item", "facet", "stem")]
#>    item facet                                                             stem
#> 1   EF1    EF     When my coursework gets boring, I keep working on it anyway.
#> 2   EF2    EF       I stop studying once the material stops being interesting.
#> 3   EF3    EF             I finish the assignments that count toward my grade.
#> 4   EF4    EF                   I keep to the study schedule I set for myself.
#> 5   EF5    EF                    I get tense when I fall behind on coursework.
#> 6   EF6    EF I finish assignments even when I would rather do something else.
#> 7   TF1    TF                         I stay on one task until it is finished.
#> 8   TF2    TF                            I switch between tasks while I study.
#> 9   TF3    TF                  I keep my attention on the task in front of me.
#> 10  TF4    TF             I keep working through a task without taking breaks.
#> 11  TF5    TF                        I work hard to stay on top of my reading.
#> 12  TF6    TF                               I put my phone away while I study.
```

Each item was also given a job, and the file records what it is, so you
can check the stages against the design rather than take this vignette’s
word for anything. Two are simply written the other way round; five more
are meant to cause trouble:

``` r

subset(items, !startsWith(role, "ordinary"))[c("item", "role")]
#>    item                                                               role
#> 2   EF2                   reverse-worded: behaves as intended once recoded
#> 3   EF3            flagged by an empirical screen and worth keeping anyway
#> 4   EF4      passes content review, then carries almost no common variance
#> 5   EF5 fails content review: the wording pulls judges toward test anxiety
#> 6   EF6        meets the content criterion by one judge, then behaves well
#> 8   TF2                   reverse-worded: behaves as intended once recoded
#> 10  TF4                   passes content review, then loads on both facets
#> 11  TF5     fails content review: a competing facet takes more assignments
#> 12  TF6                             behaves differently in the two cohorts
```

## Stage one: the expert panel

Twenty judges sorted each item into `EF`, `TF`, or `TA`.
[`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
applies the exact target-count test of Howard and Melloy (2016): with
twenty judges and two plausible answers, an item needs fifteen
assignments to its target to meet the criterion.

``` r

sorted <- read.csv(path("walkthrough_sort.csv"), stringsAsFactors = FALSE)
panel <- sort_validity(sorted)

panel$results[c("item", "target", "n_target", "competitor", "n_other_max",
                "csv", "recommendation")]
#>    item target n_target competitor n_other_max   csv recommendation
#> 1   EF1     EF       19         TF           1  0.90         Retain
#> 2   EF2     EF       18     TA; TF           1  0.85         Retain
#> 3   EF3     EF       18         TF           2  0.80         Retain
#> 4   EF4     EF       18         TF           2  0.80         Retain
#> 5   EF5     EF       11         TA           8  0.15         Review
#> 6   EF6     EF       15         TF           3  0.60         Retain
#> 7   TF1     TF       19         EF           1  0.90         Retain
#> 8   TF2     TF       17         EF           2  0.75         Retain
#> 9   TF3     TF       18     EF; TA           1  0.85         Retain
#> 10  TF4     TF       16         EF           4  0.60         Retain
#> 11  TF5     TF        6         EF          13 -0.35         Review
#> 12  TF6     TF       18         EF           2  0.80         Retain
```

Two items are flagged, and for different reasons.

`EF5` (“I get tense when I fall behind on coursework”) still drew more
assignments to effort regulation than anywhere else, but eight of twenty
judges read it as test anxiety. Its target wins and the criterion is not
met.

`TF5` (“I work hard to stay on top of my reading”) is worse: thirteen
judges put it under effort regulation and only six under task focus, so
a competing facet beat the target outright. Its content validity index
for sorting is negative, which is what a negative `csv` means.

``` r

panel$results[panel$results$recommendation == "Review",
              c("item", "csv", "issue")]
#>    item   csv                                   issue
#> 5   EF5  0.15 Target favored, exact criterion not met
#> 11  TF5 -0.35             Competing construct favored
```

`EF6` is worth a second look for the opposite reason. It met the
criterion by exactly one judge:

``` r

panel$results[panel$results$item == "EF6",
              c("item", "n_target", "critical_n_target", "p_value",
                "recommendation")]
#>   item n_target critical_n_target    p_value recommendation
#> 6  EF6       15                15 0.02069473         Retain
```

A result that close to the line is a reason to look at the item, not a
prediction that it will fail later. Keep that in mind; `EF6` comes back.

## The handoff

[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
packages the decision. By default only items whose status is `Supported`
travel forward, so `EF5` and `TF5` stop here.

Two facts about the instrument travel with it as well, and neither is
something the panel could know. Two items are written the other way
round, so that agreeing with them means *less* persistence, and
respondents will answer on a one-to-five scale. The panel sorted items
into facets and never saw that scale, so both have to come from you:

``` r

h <- content_handoff(panel,
                     reverse_keyed = items$item[items$reverse_worded],
                     response_scale = c(1, 5))

h$items
#>  [1] "EF1" "EF2" "EF3" "EF4" "EF6" "TF1" "TF2" "TF3" "TF4" "TF6"
h$scales
#> $EF
#> [1] "EF1" "EF2" "EF3" "EF4" "EF6"
#> 
#> $TF
#> [1] "TF1" "TF2" "TF3" "TF4" "TF6"
```

Nothing is thrown away. The two flagged items stay in the record, marked
as not carried, and every item carries its keying, the rejected ones
included, since a reader recoding the response file needs all of them:

``` r

h$item_evidence[c("item", "carried", "status", "recommendation", "keying")]
#>    item carried    status recommendation keying
#> 1   EF1    TRUE Supported         Retain      1
#> 2   EF2    TRUE Supported         Retain     -1
#> 3   EF3    TRUE Supported         Retain      1
#> 4   EF4    TRUE Supported         Retain      1
#> 5   EF5   FALSE    Review         Review      1
#> 6   EF6    TRUE Supported         Retain      1
#> 7   TF1    TRUE Supported         Retain      1
#> 8   TF2    TRUE Supported         Retain     -1
#> 9   TF3    TRUE Supported         Retain      1
#> 10  TF4    TRUE Supported         Retain      1
#> 11  TF5   FALSE    Review         Review      1
#> 12  TF6    TRUE Supported         Retain      1
```

## Stage two: what the responses say

Four hundred people answered all twelve items on a five-point scale. The
response file keeps the items the panel rejected, because the point of a
walkthrough is to be able to see what would have happened had they been
kept.

``` r

responses <- read.csv(path("walkthrough_responses.csv"),
                      stringsAsFactors = FALSE)
str(responses[1:5])
#> 'data.frame':    400 obs. of  5 variables:
#>  $ respondent: int  1 2 3 4 5 6 7 8 9 10 ...
#>  $ cohort    : chr  "A" "A" "A" "A" ...
#>  $ EF1       : int  3 4 4 5 3 4 1 3 3 3 ...
#>  $ EF2       : int  2 2 3 3 4 4 3 5 5 3 ...
#>  $ EF3       : int  5 5 5 5 5 5 4 4 5 5 ...
```

### Recode first, and see why it matters

Before anything is correlated, the reverse-worded items have to be
turned round. Skip that and look at what happens to `TF2`, “I switch
between tasks while I study”:

``` r

raw <- as.matrix(responses[h$items])
corrected <- function(X, item, set) {
  rest <- setdiff(set, item)
  stats::cor(X[, item], rowSums(X[, rest, drop = FALSE]))
}
round(corrected(raw, "TF2", h$scales$TF), 2)
#> [1] -0.51
```

A negative corrected item-total correlation is about as strong a case
against an item as item analysis produces, and here it means nothing of
the kind. It is a coding error. The same number on a correctly coded
item would be evidence that the item measures the opposite of its facet,
and the advice in the two cases is opposite: fix the scoring, or drop
the item. The response data cannot tell you which case you are in. The
handoff can, because it recorded the keying:

``` r

ev <- h$item_evidence
key <- setNames(ev$keying, ev$item)[h$items]
top <- ev$response_min[1] + ev$response_max[1]

carried <- raw
carried[, key == -1] <- top - carried[, key == -1]

round(corrected(carried, "TF2", h$scales$TF), 2)
#> [1] 0.51
```

Recoding uses the scale’s limits, not the lowest and highest answers
anyone gave, which is why the handoff carries them: had nobody chosen 5,
reversing against the observed maximum would shift every recoded answer
down a point.

### Two factors

Now take the ten carried items, recoded, and ask for two factors:

``` r

fa <- stats::factanal(carried, factors = 2, rotation = "varimax")

round(unclass(fa$loadings), 2)
#>     Factor1 Factor2
#> EF1    0.75    0.09
#> EF2    0.65    0.14
#> EF3    0.38    0.15
#> EF4    0.27    0.08
#> EF6    0.57    0.15
#> TF1    0.20    0.68
#> TF2    0.23    0.57
#> TF3    0.14    0.57
#> TF4    0.52    0.39
#> TF6    0.09    0.60
```

Seven of the ten behave as the panel expected. Three do not, and none of
the three could have been caught by reading the item.

**`EF4` passed content review and carries almost nothing.** Eighteen of
twenty judges sorted “I keep to the study schedule I set for myself”
under effort regulation, which is a fair reading of the words. It is
really about planning, so it shares little variance with the rest of the
facet:

``` r

round(unclass(fa$loadings)["EF4", ], 2)
#> Factor1 Factor2 
#>    0.27    0.08
```

**`TF4` passed content review and belongs to both facets.** “I keep
working through a task without taking breaks” is as much effort as
focus, and the response data say so even though the judges saw only one
of the two:

``` r

round(unclass(fa$loadings)["TF4", ], 2)
#> Factor1 Factor2 
#>    0.52    0.39
```

And `EF6`, the item that met the content criterion by a single judge, is
unremarkable here:

``` r

round(unclass(fa$loadings)["EF6", ], 2)
#> Factor1 Factor2 
#>    0.57    0.15
```

A borderline content result and an empirical failure are different
things. The item the panel worried about is fine; the item eighteen of
twenty judges agreed on is the one that fails.

## The item you should keep anyway

So far the empirical stage has been the one that knows better. `EF3` is
the case that stops that from becoming the moral of the story.

``` r

round(unclass(fa$loadings)["EF3", ], 2)
#> Factor1 Factor2 
#>    0.38    0.15
```

That is low enough for a screening rule written as “flag anything under
.40” to catch it. Compare it with `EF4`, which we have just thrown out,
and the two look like the same kind of problem:

``` r

round(c(EF3 = corrected(carried, "EF3", h$scales$EF),
        EF4 = corrected(carried, "EF4", h$scales$EF)), 2)
#>  EF3  EF4 
#> 0.34 0.23
```

They are not the same problem, and the correlation cannot tell you that.
The distribution can:

``` r

data.frame(
  sd = round(apply(carried, 2, stats::sd), 2),
  top_two = round(colMeans(carried >= 4), 2)
)
#>       sd top_two
#> EF1 1.14    0.40
#> EF2 1.20    0.43
#> EF3 0.51    0.96
#> EF4 1.17    0.40
#> EF6 1.19    0.40
#> TF1 1.24    0.40
#> TF2 1.18    0.41
#> TF3 1.17    0.42
#> TF4 1.21    0.43
#> TF6 1.25    0.46
```

`EF3` is “I finish the assignments that count toward my grade.” Almost
everybody does: 96% of respondents pick one of the top two categories,
and its standard deviation is less than half of every other item’s. A
correlation is bounded by how much the two variables vary, so an item
nearly everyone answers the same way cannot correlate strongly with
anything, however well it measures the construct. `EF4`, by contrast,
has an entirely ordinary spread — its low correlation has no such
excuse, and is telling you the item is about something else.

The content argument then decides it. `EF3` is the only item in the set
about completing required work; every other effort-regulation item is
about how the work *feels* — boring, dull, unappealing. Drop `EF3` for
its correlation and the scale still has five items, but it no longer
covers a part of the domain the panel defined. That is a
content-validity loss that no empirical index reports, because no
empirical index knows what the domain was.

Neither stage overrules the other. `EF4` is the case for not trusting a
panel on its own; `EF3` is the case for not trusting a screen on its
own.

## What a second stage adds beyond factors

The response file carries a `cohort` variable, and one item answers
differently in the two cohorts:

``` r

shifts <- vapply(h$items, function(i) {
  m <- tapply(responses[[i]], responses$cohort, mean)
  unname(m["B"] - m["A"])
}, numeric(1))

round(sort(shifts), 2)
#>   EF1   EF4   TF4   EF6   TF2   EF3   EF2   TF1   TF3   TF6 
#> -0.21 -0.14 -0.07 -0.04 -0.04 -0.02  0.02  0.13  0.16  0.61
```

`TF6` (“I put my phone away while I study”) sits well outside the rest.
Nothing about the item’s wording predicts that, and no panel could have.
Whether the difference matters is a measurement-invariance question,
which belongs to the empirical stage.

The handoff is what carries the decision into that stage. Its `items`
are the item names to screen and its `scales` are the subscales to form,
both in the shape a downstream package needs. `nomologR` is one such
package; it is not a dependency of this one, so the call below is shown
rather than run:

``` r

library(nomologR)

nomo_screen(responses, items = h$items)
```

Reading the handoff object directly, rather than taking `h$items` out of
it, is tracked on
[nomologR#46](https://github.com/JUhalt/nomologR/issues/46).

## The moral, stated plainly

Surviving content review is evidence about relevance, representation,
and whether experts read an item the way it was meant. It is not
evidence that the item measures anything. Of the ten items this panel
carried forward, one carries almost no common variance and one belongs
to a facet the judges never considered. Both read well. That is not a
failure of the panel; it is the boundary of what a panel can see.

The reverse holds just as firmly. A screening index is a number about a
sample, and it does not know which part of the construct an item was
there to cover. `EF3` would be dropped by a rule and kept by anyone who
had read the domain definition.

So the two stages are worth running in that order not because the second
corrects the first, but because each sees something the other cannot.
Content review removes items no amount of data would rescue, and it
removes them before anyone spends a sample on them. Empirical screening
asks the question content review could not. Neither one gets to decide
alone, which is why the handoff carries the evidence forward rather than
just the surviving names.

## Reproducing the data

Every file used here is generated by `data-raw/build-walkthrough-data.R`
in the package sources, which uses only base R and is deterministic. It
states the full generating model: the two-factor structure, every
loading, the factor correlation, the response thresholds, and the single
cohort shift. `nomologR` mirrors the response file from the same script,
so both packages show the same numbers.

## References

Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task
methods: The presentation of a new statistical significance formula and
methodological best practices. *Journal of Business and Psychology,
31*(1), 173-186. <https://doi.org/10.1007/s10869-015-9404-y>

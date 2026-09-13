# Plan an expert panel against an explicit decision criterion

Reports the probability that an item will clear its expert-panel
criterion, given a panel size and an assumed probability that a single
expert endorses the item.

This replaces advice of the form "use six experts" with a question that
has an answer: *if an expert endorses this item with probability `prob`,
how often will a panel of this size actually clear the criterion?*
Nothing here recommends a panel size. It reports the consequences of the
sizes you ask about, so the choice stays yours and stays documented.

## Usage

``` r
expert_power(
  n_experts = 3:12,
  prob = c(0.7, 0.8, 0.9),
  criterion = c("cvi", "cvr"),
  alpha = 0.05,
  response_rate = 1
)
```

## Arguments

- n_experts:

  Panel sizes to evaluate.

- prob:

  Probability that one expert endorses the item, as relevant
  (`criterion = "cvi"`) or essential (`criterion = "cvr"`). Values well
  below 0.5 describe items the panel largely rejects.

- criterion:

  `"cvi"` uses the common panel-size I-CVI guideline: 1.00 for three to
  five experts, 0.78 for six or more. `"cvr"` uses the exact Lawshe
  critical count at level `alpha`.

- alpha:

  Significance level for the CVR criterion. Ignored for CVI.

- response_rate:

  Expected proportion of invited experts who return usable ratings. When
  below 1, `n_experts` is treated as the number invited and the realized
  panel size is averaged over, so the reported probability accounts for
  both a smaller panel and the criterion that a smaller panel triggers.

## Value

An object of class `contentvalid_expert_power`: a list whose `results`
data frame holds one row per panel size and probability, with the
required endorsement count and the probability of clearing.

## Why the curve is not always smooth

The I-CVI criterion is a step function of panel size: it is 1.00 up to
five experts and 0.78 from six. Adding a sixth expert relaxes the
criterion and can raise the clearing probability sharply, while adding a
fourth or fifth expert under unanimity makes clearing *harder*. A
planning curve that rose smoothly with panel size would be hiding this,
so it is reported as it is.

## References

Lynn, M. R. (1986). Determination and quantification of content
validity. *Nursing Research, 35*(6), 382-385.

Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an
acceptable indicator of content validity? *Research in Nursing & Health,
30*(4), 459-467.
[doi:10.1002/nur.20199](https://doi.org/10.1002/nur.20199)

Ayre, C., & Scally, A. J. (2014). Critical values for Lawshe's content
validity ratio. *Measurement and Evaluation in Counseling and
Development, 47*(1), 79-86.
[doi:10.1177/0748175613513808](https://doi.org/10.1177/0748175613513808)

## See also

[`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md)
for item-sort planning, and
[`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md)
whose decision study plans panel size against a generalizability target.

## Examples

``` r
expert_power(n_experts = 3:10, prob = c(0.8, 0.9))
#> Expert-panel planning
#> Criterion: Exact binomial planning against the panel-size I-CVI guideline
#> 
#>  n_experts prob required_endorsements power
#>          3  0.8                     3 0.512
#>          4  0.8                     4 0.410
#>          5  0.8                     5 0.328
#>          6  0.8                     5 0.655
#>          7  0.8                     6 0.577
#>          8  0.8                     7 0.503
#>          9  0.8                     8 0.436
#>         10  0.8                     8 0.678
#>          3  0.9                     3 0.729
#>          4  0.9                     4 0.656
#>          5  0.9                     5 0.590
#>          6  0.9                     5 0.886
#>          7  0.9                     6 0.850
#>          8  0.9                     7 0.813
#>          9  0.9                     8 0.775
#>         10  0.9                     8 0.930
#> Note the step at six experts. The I-CVI guideline requires unanimity with
#> three to five experts and 0.78 from six, so a sixth expert relaxes the
#> criterion while a fourth or fifth makes unanimity harder. That is a
#> property of the guideline, not of the items.
#> This table reports the consequences of the panel sizes you asked about. It
#> does not recommend one. `prob` is an assumption you supply, so treat the
#> result as conditional on it and report the value you assumed.
#> 
expert_power(n_experts = c(5, 10, 15), prob = 0.75, criterion = "cvr")
#> Expert-panel planning
#> Criterion: Exact binomial planning against the Lawshe CVR critical count
#> Alpha: 0.05
#> 
#>  n_experts prob required_endorsements power
#>          5 0.75                     5 0.237
#>         10 0.75                     9 0.244
#>         15 0.75                    12 0.461
#> This table reports the consequences of the panel sizes you asked about. It
#> does not recommend one. `prob` is an assumption you supply, so treat the
#> result as conditional on it and report the value you assumed.
#> 
```

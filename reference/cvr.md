# Lawshe's Content Validity Ratio (CVR)

Computes Lawshe's CVR and exact one-sided binomial inference following
the critical-value logic revisited by Ayre and Scally (2014). Input may
be either counts of experts marking each item essential or a
judge-by-item 0/1 matrix.

Lawshe (1975) published a table of critical values computed by a
colleague, Lowell Schipper, without saying how. Wilson et al. (2012)
read the step from .78 at nine experts to .75 at eight as an anomaly,
and found that the table matches a normal approximation at a two-tailed
.05 level rather than the one-tailed .05 it was labeled with. Ayre and
Scally (2014) then derived exact binomial values, which are the ones
used here, and showed that the step is not an anomaly: .78 is 8 of 9 and
.75 is 7 of 8, the counts the exact test also requires.

## Usage

``` r
cvr(essential, N = NULL, alpha = 0.05, na.rm = FALSE, item_names = NULL)
```

## Arguments

- essential:

  Numeric/integer vector of essential counts, or a matrix/data frame
  with judges in rows, items in columns, coded `1 = essential` and
  `0 = not essential`. In a judge-by-item table every column is an item;
  a column whose name looks like a rater ID (such as `expert` or
  `rater_id`) stops the function, so remove it, or rename an item that
  has such a name.

- N:

  Panel size. Required for count-vector input. May be a scalar or a
  vector matching `essential`. Ignored for matrix input, where effective
  N is calculated itemwise.

- alpha:

  One-sided exact alpha level. Default `.05`.

- na.rm:

  Logical; for matrix input, permit itemwise missing ratings.

- item_names:

  Optional item names for count-vector input. By default the names of
  `essential` are used when every count has a distinct, non-blank name,
  and `Item1`, `Item2`, and so on otherwise.

## Value

A data.frame containing item, `ne`, effective `N`, CVR, exact *p* value,
critical essential count/CVR, and `pass`. With very few experts no count
can reach `alpha` (4 of 4 gives *p* = .0625), so the critical count and
CVR are `NA` and `pass` is `FALSE`; the printout says so. It prints as a
formatted table in APA style; the values themselves are unrounded, and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the plain data frame.

## References

Ayre, C., & Scally, A. J. (2014). Critical values for Lawshe's content
validity ratio: Revisiting the original methods of calculation.
*Measurement and Evaluation in Counseling and Development, 47*(1),
79–86.
[doi:10.1177/0748175613513808](https://doi.org/10.1177/0748175613513808)

Lawshe, C. H. (1975). A quantitative approach to content validity.
*Personnel Psychology, 28*(4), 563–575.
[doi:10.1111/j.1744-6570.1975.tb01393.x](https://doi.org/10.1111/j.1744-6570.1975.tb01393.x)

Wilson, F. R., Pan, W., & Schumsky, D. A. (2012). Recalculation of the
critical values for Lawshe's content validity ratio. *Measurement and
Evaluation in Counseling and Development, 45*(3), 197–210.
[doi:10.1177/0748175612440286](https://doi.org/10.1177/0748175612440286)

## Examples

``` r
cvr(essential = c(8, 10, 5), N = 12)
#> <contentvalid_cvr> Content validity ratio (CVR; Lawshe, 1975)
#> 
#>   Item   Essential   CVR     p  Needed  Meets
#>   Item1       8/12   .33  .194      10  no
#>   Item2      10/12   .67  .019      10  yes
#>   Item3       5/12  -.17  .806      10  no
#> 
#> Needed: essential ratings the exact one-tailed binomial test requires at
#> alpha = .05 (Ayre & Scally, 2014).
#> 
#> See as.data.frame(x) for the unrounded values.
```

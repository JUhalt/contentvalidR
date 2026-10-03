#' Proportion of Substantive Agreement (Psa)
#'
#' @description
#' For each item, computes the proportion of non-missing item-sort responses
#' assigned to the item's intended (target) construct. This is Anderson and
#' Gerbing's (1991) proportion of substantive agreement, \eqn{P_{sa}}.
#'
#' Missing assignments are excluded itemwise and reported in `n_missing` so
#' that the effective denominator is transparent. Psa is a proportion of a
#' finite set of judges, so an interval is reported alongside it; see `ci`.
#'
#' @param assignments A data.frame containing item-sort responses.
#' @param item_col,rater_col,assigned_col,target_col Column names for the item,
#'   rater, assigned construct, and intended target construct.
#' @param ci Interval method for Psa: `"wilson"` (default), the score interval
#'   of Wilson (1927); `"agresti_coull"`, the adjusted Wald interval of Agresti
#'   and Coull (1998); `"exact"`, the Clopper and Pearson (1934) interval; or
#'   `"none"`. Newcombe (1998) compared such methods and recommends score
#'   intervals; the evidence for each is described under `ci` in [cvi()].
#' @param alpha Two-sided alpha level for the interval; `0.05` gives a 95%
#'   interval.
#'
#' @return A data.frame with one row per item and columns `item`, `target`,
#'   `n_total`, `n`, `n_missing`, `n_target`, `psa`, `psa_low`, and `psa_high`.
#'   It prints as a formatted table in APA style; the values themselves are
#'   unrounded, and `as.data.frame()` returns the plain data frame.
#'
#' @references
#' Agresti, A., & Coull, B. A. (1998). Approximate is better than "exact" for
#' interval estimation of binomial proportions. *The American Statistician,
#' 52*(2), 119–126. \doi{10.1080/00031305.1998.10480550}
#'
#' Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
#' measures in a confirmatory factor analysis with a pretest assessment of
#' their substantive validities. *Journal of Applied Psychology, 76*(5),
#' 732–740. \doi{10.1037/0021-9010.76.5.732}
#'
#' Clopper, C. J., & Pearson, E. S. (1934). The use of confidence or fiducial
#' limits illustrated in the case of the binomial. *Biometrika, 26*(4),
#' 404–413. \doi{10.1093/biomet/26.4.404}
#'
#' Newcombe, R. G. (1998). Two-sided confidence intervals for the single
#' proportion: Comparison of seven methods. *Statistics in Medicine, 17*(8),
#' 857–872.
#' \doi{10.1002/(SICI)1097-0258(19980430)17:8<857::AID-SIM777>3.0.CO;2-E}
#'
#' Wilson, E. B. (1927). Probable inference, the law of succession, and
#' statistical inference. *Journal of the American Statistical Association,
#' 22*(158), 209–212. \doi{10.1080/01621459.1927.10502953}
#'
#' @seealso [cvi()] for the same interval methods applied to I-CVI.
#'
#' @examples
#' df <- data.frame(
#'   item = rep(c("I1", "I2"), each = 4),
#'   rater = rep(1:4, 2),
#'   assigned_construct = c("A", "A", "A", "B", "B", "A", "B", "B"),
#'   target_construct = rep(c("A", "B"), each = 4)
#' )
#' compute_psa(df)
#' compute_psa(df, ci = "exact")
#' @export
compute_psa <- function(assignments,
                        item_col = "item",
                        rater_col = "rater",
                        assigned_col = "assigned_construct",
                        target_col = "target_construct",
                        ci = c("wilson", "agresti_coull", "exact", "none"),
                        alpha = 0.05) {
  ci <- .choose(ci)
  d <- .prepare_sort_assignments(
    assignments, item_col, rater_col, assigned_col, target_col
  )

  by_item <- .split_by_item(d)
  rows <- lapply(by_item, function(df) {
    valid <- !is.na(df$assigned)
    n_total <- nrow(df)
    n <- sum(valid)
    n_missing <- n_total - n
    target <- unique(df$target)[1]
    n_target <- if (n > 0L) sum(df$assigned[valid] == target) else 0L
    psa <- if (n > 0L) n_target / n else NA_real_

    data.frame(
      item = df$item[1],
      target = target,
      n_total = n_total,
      n = n,
      n_missing = n_missing,
      n_target = n_target,
      psa = psa,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  interval <- .proportion_ci(out$n_target, out$n, method = ci, alpha = alpha)
  out$psa_low <- interval$low
  out$psa_high <- interval$high
  .tag_component(out, "contentvalid_psa", alpha = alpha, ci_method = ci)
}

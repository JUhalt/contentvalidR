#' Proportion of Substantive Agreement (Psa)
#'
#' @description
#' For each item, computes the proportion of non-missing item-sort responses
#' assigned to the item's intended (target) construct. This is Anderson and
#' Gerbing's (1991) proportion of substantive agreement, \eqn{P_{sa}}.
#'
#' Missing assignments are excluded itemwise and reported in `n_missing` so
#' that the effective denominator is transparent.
#'
#' @param assignments A data.frame containing item-sort responses.
#' @param item_col,rater_col,assigned_col,target_col Column names for the item,
#'   rater, assigned construct, and intended target construct.
#'
#' @return A data.frame with one row per item and columns `item`, `target`,
#'   `n_total`, `n`, `n_missing`, `n_target`, and `psa`.
#'
#' @references
#' Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
#' measures in a confirmatory factor analysis with a pretest assessment of
#' their substantive validities. *Journal of Applied Psychology, 76*(5),
#' 732-740. \doi{10.1037/0021-9010.76.5.732}
#'
#' @examples
#' df <- data.frame(
#'   item = rep(c("I1", "I2"), each = 4),
#'   rater = rep(1:4, 2),
#'   assigned_construct = c("A", "A", "A", "B", "B", "A", "B", "B"),
#'   target_construct = rep(c("A", "B"), each = 4)
#' )
#' compute_psa(df)
#' @export
compute_psa <- function(assignments,
                        item_col = "item",
                        rater_col = "rater",
                        assigned_col = "assigned_construct",
                        target_col = "target_construct") {
  d <- .prepare_sort_assignments(
    assignments, item_col, rater_col, assigned_col, target_col
  )

  by_item <- split(d, d$item, drop = TRUE)
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
  out
}

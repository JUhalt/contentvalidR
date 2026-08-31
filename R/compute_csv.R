#' Substantive Validity Coefficient (Csv)
#'
#' @description
#' For each item, computes Anderson and Gerbing's (1991) substantive-validity
#' coefficient:
#'
#' \deqn{C_{sv} = (n_c - n_o) / N,}
#'
#' where \eqn{n_c} is the number of non-missing assignments to the intended
#' construct, \eqn{n_o} is the largest number of assignments to any one
#' non-target construct, and \eqn{N} is the number of non-missing assignments.
#'
#' Missing assignments are excluded itemwise and reported in `n_missing`.
#'
#' @param assignments A data.frame containing item-sort responses.
#' @param item_col,rater_col,assigned_col,target_col Column names for the item,
#'   rater, assigned construct, and intended target construct.
#'
#' @return A data.frame with one row per item and columns `item`, `target`,
#'   `n_total`, `n`, `n_missing`, `n_target`, `competitor`, `n_other_max`, and `csv`.
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
#'   assigned_construct = c("A", "A", "A", "B", "B", "B", "B", "B"),
#'   target_construct = rep("A", 8)
#' )
#' compute_csv(df)
#' @export
compute_csv <- function(assignments,
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

    if (n == 0L) {
      n_target <- 0L
      n_other <- 0L
      competitor <- NA_character_
      csv <- NA_real_
    } else {
      tab <- table(df$assigned[valid], useNA = "no")
      n_target <- if (target %in% names(tab)) unname(tab[target]) else 0L
      other_counts <- tab[names(tab) != target]
      n_other <- if (length(other_counts) > 0L) max(other_counts) else 0L
      if (length(other_counts) > 0L && n_other > 0L) {
        competitor <- paste(names(other_counts)[other_counts == n_other], collapse = "; ")
      } else {
        competitor <- NA_character_
      }
      csv <- (n_target - n_other) / n
    }

    data.frame(
      item = df$item[1],
      target = target,
      n_total = n_total,
      n = n,
      n_missing = n_missing,
      n_target = as.integer(n_target),
      competitor = competitor,
      n_other_max = as.integer(n_other),
      csv = csv,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

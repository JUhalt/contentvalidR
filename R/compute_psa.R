#' Proportion of Substantive Agreement (Psa)
#'
#' @description
#' Computes, for each item, the proportion of raters who assigned it to its
#' *intended* (target) construct in an item-sort pretest.
#'
#' @param assignments A data.frame with columns: item, rater, assigned_construct, target_construct.
#' @param item_col,rater_col,assigned_col,target_col Column names if yours differ from defaults.
#'
#' @return A data.frame with one row per item: item, n (raters), n_target, psa.
#' @examples
#' df <- data.frame(
#'   item = rep(paste0("I",1:3), each = 10),
#'   rater = rep(1:10, 3),
#'   assigned_construct = sample(c("A","B"), 30, TRUE, c(.7,.3)),
#'   target_construct   = rep(c("A","A","B"), each = 10)
#' )
#' compute_psa(df)
compute_psa <- function(assignments,
                        item_col = "item",
                        rater_col = "rater",
                        assigned_col = "assigned_construct",
                        target_col = "target_construct") {
  stopifnot(all(c(item_col, rater_col, assigned_col, target_col) %in% names(assignments)))
  d <- assignments[, c(item_col, rater_col, assigned_col, target_col)]
  names(d) <- c("item","rater","assigned","target")
  d$hit <- d$assigned == d$target
  agg <- aggregate(hit ~ item, d, function(x) c(n = length(x), n_target = sum(x)))
  out <- do.call(data.frame, agg)
  names(out) <- c("item","n","n_target","psa")
  out$psa <- out$psa / out$n
  out
}

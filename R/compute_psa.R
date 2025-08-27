#' Proportion of Substantive Agreement (Psa)
#'
#' @description
#' For each item, the proportion of raters who assigned it to its target construct.
#'
#' @param assignments data.frame with columns: item, rater, assigned_construct, target_construct
#' @param item_col,rater_col,assigned_col,target_col column names if they differ
#'
#' @return data.frame with columns: item, n, n_target, psa
#' @examples
#' df <- data.frame(
#'   item = rep(paste0("I",1:3), each = 10),
#'   rater = rep(1:10, 3),
#'   assigned_construct = sample(c("A","B"), 30, TRUE, c(.7,.3)),
#'   target_construct   = rep(c("A","A","B"), each = 10)
#' )
#' compute_psa(df)
#' @export
compute_psa <- function(assignments,
                        item_col = "item",
                        rater_col = "rater",
                        assigned_col = "assigned_construct",
                        target_col = "target_construct") {
  stopifnot(all(c(item_col, rater_col, assigned_col, target_col) %in% names(assignments)))
  d <- assignments[, c(item_col, rater_col, assigned_col, target_col)]
  names(d) <- c("item","rater","assigned","target")
  d$hit <- d$assigned == d$target

  by_item <- split(d, d$item)
  rows <- lapply(by_item, function(df) {
    n <- nrow(df)
    n_target <- sum(df$hit, na.rm = TRUE)
    data.frame(item = df$item[1], n = n, n_target = n_target, psa = n_target / n)
  })
  do.call(rbind, rows)
}

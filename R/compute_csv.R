#' Substantive Validity Coefficient (Csv)
#'
#' @description
#' For each item, Csv compares how often raters assign it to the target
#' construct vs. the most common *non-target* construct: \deqn{csv = (n_c - n_o) / N}
#'
#' @param assignments A data.frame with columns: item, rater, assigned_construct, target_construct.
#' @param item_col,rater_col,assigned_col,target_col Column names if yours differ from defaults.
#'
#' @return A data.frame with: item, n, n_target (n_c), n_other_max (n_o), csv.
#' @examples
#' df <- data.frame(
#'   item = rep(paste0("I",1:3), each = 12),
#'   rater = rep(1:12, 3),
#'   assigned_construct = sample(c("A","B","C"), 36, TRUE, c(.6,.25,.15)),
#'   target_construct   = rep(c("A","B","C"), each = 12)
#' )
#' compute_csv(df)
compute_csv <- function(assignments,
                        item_col = "item",
                        rater_col = "rater",
                        assigned_col = "assigned_construct",
                        target_col = "target_construct") {
  stopifnot(all(c(item_col, rater_col, assigned_col, target_col) %in% names(assignments)))
  d <- assignments[, c(item_col, rater_col, assigned_col, target_col)]
  names(d) <- c("item","rater","assigned","target")
  by_item <- split(d, d$item)
  res <- lapply(by_item, function(df) {
    N <- nrow(df)
    tab <- table(df$assigned)
    target_name <- unique(df$target)[1]
    n_c <- if (target_name %in% names(tab)) unname(tab[target_name]) else 0L
    n_o <- if (length(tab) > 1) max(tab[names(tab) != target_name]) else 0L
    csv <- (n_c - n_o) / N
    data.frame(item = unique(df$item)[1], n = N, n_target = n_c, n_other_max = n_o, csv = csv)
  })
  do.call(rbind, res)
}

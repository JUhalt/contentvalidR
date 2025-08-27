#' Item–Objective Congruence (IOC)
#'
#' @description
#' Computes IOC per item per objective from judges' ratings coded in -1, 0, +1
#' following Rovinelli & Hambleton. Provide data in long format.
#'
#' @param ratings data.frame with columns:
#'   item (chr/num), judge (chr/num), objective (chr/num), score (numeric in -1,0,1).
#'
#' @returns data.frame with: item, objective, n_judges, ioc (mean of scores).
#' @examples
#' df <- data.frame(
#'   item = rep(paste0("I",1:3), each = 9),
#'   judge = rep(1:3, times = 9),
#'   objective = rep(rep(LETTERS[1:3], each = 3), times = 3),
#'   score = sample(c(-1,0,1), 27, replace = TRUE)
#' )
#' ioc(df)
#' @export
ioc <- function(ratings) {
  stopifnot(all(c("item","judge","objective","score") %in% names(ratings)))
  d <- ratings[, c("item","judge","objective","score")]
  if (!all(d$score %in% c(-1, 0, 1))) {
    stop("scores must be in {-1, 0, +1}")
  }
  agg <- aggregate(score ~ item + objective, d, function(x) c(n = length(x), mean = mean(x)))
  out <- do.call(data.frame, agg)
  names(out) <- c("item","objective","n_judges","ioc")
  out
}

#' Item-Objective Congruence (IOC)
#'
#' @description
#' Computes item-objective congruence from expert ratings coded `-1`, `0`, and
#' `+1`. Duplicate item-judge-objective ratings are rejected. Missing ratings
#' may be removed cellwise with transparent effective judge counts.
#'
#' @param ratings Data frame with columns `item`, `judge`, `objective`, `score`.
#' @param na.rm Logical. If `FALSE`, missing scores are an error; if `TRUE`,
#'   missing scores are removed within item-objective cells.
#'
#' @return A data.frame with item, objective, total rows, effective judge count,
#'   missing count, and IOC.
#'
#' @references
#' Rovinelli, R. J., & Hambleton, R. K. (1977). On the use of content
#' specialists in the assessment of criterion-referenced test item validity.
#' *Dutch Journal of Educational Research, 2*, 49-60.
#'
#' @examples
#' df <- data.frame(
#'   item = rep("I1", 6),
#'   judge = rep(1:3, 2),
#'   objective = rep(c("A", "B"), each = 3),
#'   score = c(1,1,1, 0,-1,0)
#' )
#' ioc(df)
#' @export
ioc <- function(ratings, na.rm = FALSE) {
  req <- c("item", "judge", "objective", "score")
  if (!is.data.frame(ratings) || !all(req %in% names(ratings))) {
    stop("`ratings` must be a data.frame with item, judge, objective, and score columns.", call. = FALSE)
  }
  d <- ratings[, req, drop = FALSE]
  if (nrow(d) < 1L) stop("`ratings` contains no rows.", call. = FALSE)

  key <- paste(d$item, d$judge, d$objective, sep = "\r")
  if (anyDuplicated(key)) {
    stop("Duplicate item-judge-objective ratings are not allowed.", call. = FALSE)
  }
  if (!is.numeric(d$score)) stop("`score` must be numeric.", call. = FALSE)
  if (!isTRUE(na.rm) && anyNA(d$score)) {
    stop("Missing scores found. Use `na.rm = TRUE` to remove them cellwise.", call. = FALSE)
  }
  if (any(!is.na(d$score) & !(d$score %in% c(-1, 0, 1)))) {
    stop("Scores must be in {-1, 0, +1}.", call. = FALSE)
  }

  groups <- split(d, interaction(d$item, d$objective, drop = TRUE, lex.order = TRUE))
  rows <- lapply(groups, function(g) {
    valid <- !is.na(g$score)
    n_total <- nrow(g)
    n <- sum(valid)
    data.frame(
      item = as.character(g$item[1]),
      objective = as.character(g$objective[1]),
      n_total = n_total,
      n_judges = n,
      n_missing = n_total - n,
      ioc = if (n > 0L) mean(g$score[valid]) else NA_real_,
      row.names = NULL,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out[order(out$item, out$objective), , drop = FALSE]
}

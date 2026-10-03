#' Index of item-objective congruence (IOC)
#'
#' @description
#' Computes the index of item-objective congruence of Rovinelli and Hambleton
#' (1977) from expert ratings coded `+1` (the item clearly measures the
#' objective), `0` (unclear), and `-1` (it clearly does not). Each judge rates each item
#' against every objective, and the index asks whether the item was matched to
#' one objective **and not to the others**.
#'
#' For item \eqn{k} and objective \eqn{i}, with \eqn{N} objectives and \eqn{n}
#' judges,
#' \deqn{I_{ik} = \frac{(N - 1) \sum_j X_{ijk} - \sum_{l \ne i} \sum_j X_{ljk}}{2 (N - 1) n},}
#' which is half the difference between the judges' mean rating on the
#' objective and their mean rating on the item's other objectives. It is `+1`
#' only when every judge gives `+1` on the objective and `-1` on every other,
#' and `.50` when every judge gives `+1` on the objective and `0` on the
#' others. Rovinelli and Hambleton applied a criterion of .70 to it.
#'
#' `mean_rating` is the judges' mean rating on the objective alone. Applied
#' work often reports that mean as "the IOC" (the sum of the ratings over the
#' number of experts). It is an ingredient of the index, not the index: it
#' reaches 1 whenever every judge gives `+1` on that objective, whatever they
#' say about the others. Versions of this package before 1.0 returned it in
#' the `ioc` column.
#'
#' Duplicate item-judge-objective ratings are rejected. Missing ratings may be
#' removed cellwise with transparent effective judge counts; the index is then
#' computed from the cell means, which is the same formula when no rating is
#' missing. The formula of Rovinelli and Hambleton assumes every judge rated
#' every objective, so this handling of missing ratings is this package's own:
#' each objective's mean counts once, however many judges rated it, and an
#' objective no judge rated is left out of the item's comparison. Pooling
#' every rating on the other objectives instead would give a different index.
#'
#' @param ratings Data frame with columns `item`, `judge`, `objective`, `score`.
#' @param na.rm Logical. If `FALSE`, missing scores are an error; if `TRUE`,
#'   missing scores are removed within item-objective cells.
#'
#' @return A data.frame with one row for each item and objective: `item`,
#'   `objective`, `n_total` (rows), `n_judges` (usable ratings), `n_missing`,
#'   `mean_rating` (the judges' mean rating on the objective, -1 to 1),
#'   `n_objectives` (objectives the item has usable ratings on), and `ioc`,
#'   the index. `ioc` is `NA` for an item rated against a single objective,
#'   because the index compares objectives. Items and objectives keep the
#'   order of the data.
#'   It prints as a formatted table in APA style; the values themselves are
#'   unrounded, and `as.data.frame()` returns the plain data frame.
#'
#' @references
#' Rovinelli, R. J., & Hambleton, R. K. (1977). On the use of content
#' specialists in the assessment of criterion-referenced test item validity.
#' *Dutch Journal of Educational Research, 2*, 49–60.
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
  .validate_flag(na.rm, "na.rm")
  req <- c("item", "judge", "objective", "score")
  if (!is.data.frame(ratings) || !all(req %in% names(ratings))) {
    stop("`ratings` must be a data.frame with item, judge, objective, and score columns.", call. = FALSE)
  }
  d <- ratings[, req, drop = FALSE]
  if (nrow(d) < 1L) stop("`ratings` contains no rows.", call. = FALSE)
  .validate_labels(d$item, "item")
  .validate_labels(d$judge, "judge")
  .validate_labels(d$objective, "objective")
  # Labels are compared as trimmed text, and items and objectives keep the
  # order of the data, as in the other workflows.
  d$item <- .as_label(d$item)
  d$judge <- .as_label(d$judge)
  d$objective <- .as_label(d$objective)

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

  items <- unique(d$item)
  rows <- lapply(items, function(it) {
    di <- d[d$item == it, , drop = FALSE]
    objectives <- unique(di$objective)
    cells <- lapply(objectives, function(ob) {
      g <- di[di$objective == ob, , drop = FALSE]
      valid <- !is.na(g$score)
      data.frame(
        item = it, objective = ob,
        n_total = nrow(g), n_judges = sum(valid),
        n_missing = nrow(g) - sum(valid),
        mean_rating = if (any(valid)) mean(g$score[valid]) else NA_real_,
        stringsAsFactors = FALSE
      )
    })
    out <- do.call(rbind, cells)
    rated <- !is.na(out$mean_rating)
    out$n_objectives <- sum(rated)
    # Half the gap between the mean on the objective and the mean on the
    # item's other objectives: the published index, written with means so it
    # holds when a judge skipped a rating.
    out$ioc <- vapply(seq_len(nrow(out)), function(i) {
      others <- rated
      others[i] <- FALSE
      if (!rated[i] || !any(others)) return(NA_real_)
      (out$mean_rating[i] - mean(out$mean_rating[others])) / 2
    }, numeric(1))
    out
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  .tag_component(out, "contentvalid_ioc")
}

#' Hinkin-Tracey correspondence (HTC)
#'
#' @description
#' Computes the Hinkin-Tracey correspondence index for each item. Following
#' Colquitt et al. (2019), HTC is the average definitional-correspondence rating
#' for the intended construct divided by `a`, the number of rating anchors.
#' Ratings are internally shifted to a 1-to-`a` metric when a scale such as
#' 0-to-4 is supplied, preserving the meaning of the published formula.
#'
#' HTC describes definitional correspondence. Higher values indicate that
#' judges see the item as more representative of its intended construct.
#'
#' @param ratings A long-format data.frame containing item, rater, construct,
#'   and rating columns.
#' @param item_col,rater_col,construct_col,rating_col Column names.
#' @param target_map Optional named character vector/list mapping item to target.
#' @param target_col Target column used when `target_map` is `NULL`.
#' @param scale_min,scale_max Endpoints of the equally spaced integer rating
#'   scale (for example, 1 and 5).
#'
#' @return A data.frame with item-level target means, usable target-rating
#'   counts, and HTC.
#'
#' @references
#' Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach to
#' content validation. *Organizational Research Methods, 2*(2), 175-186.
#' \doi{10.1177/109442819922004}
#'
#' Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
#' Content validation guidelines: Evaluation criteria for definitional
#' correspondence and definitional distinctiveness. *Journal of Applied
#' Psychology, 104*(10), 1243-1265. \doi{10.1037/apl0000406}
#'
#' @examples
#' d <- expand.grid(item = "I1", rater = 1:4, construct = c("A", "B"))
#' d$rating <- c(5, 4, 5, 4, 2, 2, 1, 2)
#' htc(d, target_map = c(I1 = "A"), scale_min = 1, scale_max = 5)
#' @export
htc <- function(ratings,
                item_col = "item",
                rater_col = "rater",
                construct_col = "construct",
                rating_col = "rating",
                target_map = NULL,
                target_col = "target_construct",
                scale_min = 1,
                scale_max = 5) {
  d <- .prepare_rating_data(ratings, item_col, rater_col, construct_col,
                            rating_col, target_map, target_col)
  a <- .validate_rating_scale(scale_min, scale_max, d$rating)
  by_item <- split(d, d$item, drop = TRUE)
  rows <- lapply(by_item, function(df) {
    target <- unique(df$target)[1]
    x <- df$rating[df$construct == target & !is.na(df$rating)]
    mean_raw <- if (length(x)) mean(x) else NA_real_
    mean_shifted <- if (length(x)) mean(x - scale_min + 1) else NA_real_
    data.frame(
      item = df$item[1], target = target,
      n_target = length(x), target_mean = mean_raw,
      anchors = a,
      htc = if (length(x)) mean_shifted / a else NA_real_,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Hinkin-Tracey distinctiveness (HTD)
#'
#' @description
#' Computes the Hinkin-Tracey distinctiveness index for each item in a fully
#' crossed, within-judge rating design. For every complete judge, the intended
#' construct rating is contrasted with each orbiting-construct rating. The
#' average of those difference scores is divided by `a - 1`, where `a` is the
#' number of rating anchors. HTD ranges from -1 to 1.
#'
#' @param ratings A long-format data.frame containing item, rater, construct,
#'   and rating columns.
#' @param item_col,rater_col,construct_col,rating_col Column names.
#' @param target_map Optional named item-to-target mapping.
#' @param target_col Target column used when `target_map` is `NULL`.
#' @param scale_min,scale_max Endpoints of the equally spaced integer rating
#'   scale.
#'
#' @return A data.frame containing item-level HTD, the strongest orbiting
#'   construct, complete-judge count, and number of target-orbiting pairs.
#'
#' @references
#' Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
#' *Journal of Applied Psychology, 104*(10), 1243-1265.
#' \doi{10.1037/apl0000406}
#'
#' @examples
#' d <- expand.grid(item = "I1", rater = 1:4, construct = c("A", "B", "C"))
#' d$rating <- c(5,4,5,4, 2,2,1,2, 3,2,2,1)
#' htd(d, target_map = c(I1 = "A"), scale_min = 1, scale_max = 5)
#' @export
htd <- function(ratings,
                item_col = "item",
                rater_col = "rater",
                construct_col = "construct",
                rating_col = "rating",
                target_map = NULL,
                target_col = "target_construct",
                scale_min = 1,
                scale_max = 5) {
  d <- .prepare_rating_data(ratings, item_col, rater_col, construct_col,
                            rating_col, target_map, target_col)
  a <- .validate_rating_scale(scale_min, scale_max, d$rating)
  construct_counts <- vapply(split(d, d$item, drop = TRUE),
                             function(z) length(unique(z$construct)), integer(1))
  too_few <- names(construct_counts)[construct_counts < 2L]
  if (length(too_few)) {
    stop("`htd()` requires at least two construct definitions per item. Check: ",
         paste(too_few, collapse = ", "), ".", call. = FALSE)
  }
  designs <- vapply(split(d, d$item, drop = TRUE), .detect_item_rating_design, character(1))
  between_items <- names(designs)[designs == "between"]
  if (length(between_items)) {
    stop("`htd()` requires a within-judge/fully crossed rating design. Between-judge item(s): ",
         paste(between_items, collapse = ", "), ".", call. = FALSE)
  }
  by_item <- split(d, d$item, drop = TRUE)
  rows <- lapply(by_item, function(df) {
    target <- unique(df$target)[1]
    mat <- .item_rating_matrix(df)
    complete <- stats::complete.cases(mat)
    y <- mat[complete, , drop = FALSE]
    others <- setdiff(colnames(mat), target)

    means <- if (nrow(y)) colMeans(y) else stats::setNames(rep(NA_real_, ncol(mat)), colnames(mat))
    other_means <- means[others]
    competitor <- if (length(other_means) && any(!is.na(other_means))) {
      best <- max(other_means, na.rm = TRUE)
      paste(names(other_means)[!is.na(other_means) & other_means == best], collapse = " / ")
    } else NA_character_
    competitor_mean <- if (is.na(competitor)) NA_real_ else max(other_means, na.rm = TRUE)

    if (nrow(y) == 0L || length(others) == 0L) {
      value <- NA_real_
      n_pairs <- 0L
    } else {
      diffs <- unlist(lapply(others, function(other) y[, target] - y[, other]), use.names = FALSE)
      value <- mean(diffs) / (a - 1)
      n_pairs <- length(diffs)
    }

    data.frame(
      item = df$item[1], target = target,
      n_complete = nrow(y), n_pairs = n_pairs,
      target_mean_complete = if (nrow(y)) mean(y[, target]) else NA_real_,
      strongest_competitor = competitor,
      competitor_mean = competitor_mean,
      anchors = a, htd = value,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

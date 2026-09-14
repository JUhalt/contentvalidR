# Horn's (1965) parallel analysis: mean eigenvalues of correlation matrices from
# random normal data with the same dimensions and missing cells as the ratings.
.parallel_eigen <- function(mat, n_iter, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  missing <- is.na(mat)
  sims <- matrix(NA_real_, nrow = n_iter, ncol = ncol(mat))
  for (i in seq_len(n_iter)) {
    Z <- matrix(stats::rnorm(length(mat)), nrow = nrow(mat))
    Z[missing] <- NA
    C <- suppressWarnings(stats::cor(Z, use = "pairwise.complete.obs"))
    if (all(is.finite(C))) {
      sims[i, ] <- eigen(C, symmetric = TRUE, only.values = TRUE)$values
    }
  }
  usable <- stats::complete.cases(sims)
  if (!any(usable)) {
    stop("Parallel analysis could not simulate usable correlation matrices; ",
         "supply `k_factors` or provide more complete ratings.", call. = FALSE)
  }
  colMeans(sims[usable, , drop = FALSE])
}

.kaiser_critique <- function() {
  paste(
    "Using Kaiser's eigenvalue-greater-than-1 rule, which is not the default.",
    "Zwick and Velicer (1986) found that it severely overestimates the number",
    "of components, while parallel analysis, the default, performed best."
  )
}

#' Q-factor helper for content adequacy (comparator)
#'
#' @description
#' Builds an item-by-item Q-correlation matrix from rating data and runs a
#' factor extraction (PCA by default), following the content-adequacy approach
#' of Schriesheim et al. (1993): judges rate every item against every construct
#' definition, and items that measure the same construct correlate across those
#' ratings. Schriesheim et al. (1999) compared this approach empirically with
#' other content-adequacy methods and found substantial similarity along with
#' some differences. This comparator is retained for compatibility and
#' exploratory use; it is not part of the recommended sort, rating, or
#' expert-panel workflows.
#'
#' @section Number of factors:
#' Unless `k_factors` is supplied, `retention` sets the number of factors:
#'
#' * `"parallel"` (default): Horn's (1965) parallel analysis. The eigenvalues of
#'   the Q-correlation matrix are compared, in order, with the mean eigenvalues
#'   from random normal data of the same size and with the same missing cells.
#'   Factors are retained while the observed eigenvalue is larger. Zwick and
#'   Velicer (1986) found parallel analysis among the most accurate rules.
#'   Results vary slightly between runs unless `seed` is set.
#' * `"kaiser"`: retain eigenvalues greater than 1. This was the default before
#'   contentvalidR 0.3.0 and remains available so earlier results can be
#'   reproduced. It is never the default: Zwick and Velicer (1986) found that it
#'   severely overestimates the number of components, and choosing it prints a
#'   message saying so.
#'
#' Both rules use the eigenvalues of the full Q-correlation matrix, with 1s on
#' the diagonal, whichever extraction `method` is used. At least one factor is always
#' extracted; `k_suggested` shows when a rule suggested none.
#'
#' @param ratings A data.frame with columns for item, rater, construct, rating.
#' @param item_col Name of the item column. Default "item".
#' @param rater_col Name of the rater column. Default "rater".
#' @param construct_col Name of the construct column. Default "construct".
#' @param rating_col Name of the rating column. Default "rating".
#' @param k_factors Optional integer: number of factors to extract. When
#'   supplied, `retention` is ignored.
#' @param method `"pca"` (default) or `"pa"` (principal axis; uses SMCs as initial communalities).
#' @param retention How to choose the number of factors when `k_factors` is
#'   `NULL`: `"parallel"` (default) or `"kaiser"`. See the section below.
#' @param n_iter Number of random data sets for parallel analysis.
#' @param seed Optional seed that makes parallel analysis reproducible.
#'
#' @return A list with components:
#'   - `cor_Q`: item-by-item correlation matrix,
#'   - `eigen`: eigenvalues of `cor_Q`,
#'   - `k`: number of factors used,
#'   - `loadings`: matrix of factor loadings,
#'   - `method`: the extraction method,
#'   - `retention`: `"parallel"`, `"kaiser"`, or `"fixed"` when `k_factors` was
#'     supplied,
#'   - `k_suggested`: the number of factors the retention rule suggested, which
#'     can be 0,
#'   - `parallel_eigen`: mean random-data eigenvalues from parallel analysis, or
#'     `NULL` when parallel analysis was not run.
#'
#' @references
#' Horn, J. L. (1965). A rationale and test for the number of factors in factor
#' analysis. *Psychometrika, 30*(2), 179-185. \doi{10.1007/BF02289447}
#'
#' Schriesheim, C. A., Powers, K. J., Scandura, T. A., Gardiner, C. C., &
#' Lankau, M. J. (1993). Improving construct measurement in management research:
#' Comments and a quantitative approach for assessing the theoretical content
#' adequacy of paper-and-pencil survey-type instruments. *Journal of Management,
#' 19*(2), 385-417. \doi{10.1177/014920639301900208}
#'
#' Schriesheim, C. A., Cogliser, C. C., Scandura, T. A., Lankau, M. J., &
#' Powers, K. J. (1999). An empirical comparison of approaches for
#' quantitatively assessing the content adequacy of paper-and-pencil measurement
#' instruments. *Organizational Research Methods, 2*(2), 140-156.
#' \doi{10.1177/109442819922002}
#'
#' Zwick, W. R., & Velicer, W. F. (1986). Comparison of five rules for
#' determining the number of components to retain. *Psychological Bulletin,
#' 99*(3), 432-442. \doi{10.1037/0033-2909.99.3.432}
#'
#' @examples
#' set.seed(1)
#' df <- data.frame(
#'   item = rep(paste0("I",1:6), each = 30),
#'   rater = rep(1:10, times = 18),
#'   construct = rep(rep(LETTERS[1:3], each = 10), times = 6),
#'   rating = rnorm(180)
#' )
#' qf <- qfactor_content(df, seed = 1)
#' qf$k
#' str(qf$loadings)
#' @export
qfactor_content <- function(ratings,
                            item_col = "item",
                            rater_col = "rater",
                            construct_col = "construct",
                            rating_col = "rating",
                            k_factors = NULL,
                            method = c("pca","pa"),
                            retention = c("parallel", "kaiser"),
                            n_iter = 100,
                            seed = NULL) {
  method <- match.arg(method)
  retention <- match.arg(retention)
  .validate_column_names(item_col, rater_col, construct_col, rating_col)
  if (!is.numeric(n_iter) || length(n_iter) != 1L || !is.finite(n_iter) ||
      n_iter < 1 || n_iter != floor(n_iter)) {
    stop("`n_iter` must be one positive integer.", call. = FALSE)
  }
  if (!is.null(seed) && (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed))) {
    stop("`seed` must be NULL or one number.", call. = FALSE)
  }
  if (!is.data.frame(ratings) || nrow(ratings) < 1L) {
    stop("`ratings` must be a non-empty data.frame.", call. = FALSE)
  }
  needed <- c(item_col, rater_col, construct_col, rating_col)
  if (!all(needed %in% names(ratings))) {
    stop("`ratings` must contain columns: ", paste(needed, collapse = ", "), call. = FALSE)
  }
  d <- ratings[, needed, drop = FALSE]
  names(d) <- c("item","rater","construct","rating")
  .validate_labels(d$item, "item")
  .validate_labels(d$rater, "rater")
  .validate_labels(d$construct, "construct")
  if (!is.numeric(d$rating)) {
    stop("`rating` must be numeric.", call. = FALSE)
  }
  if (any(!is.na(d$rating) & !is.finite(d$rating))) {
    stop("`rating` must contain only finite values or NA.", call. = FALSE)
  }
  key <- paste(d$item, d$rater, d$construct, sep = "\r")
  if (anyDuplicated(key)) {
    stop("Each item-rater-construct combination must appear at most once.", call. = FALSE)
  }

  items <- sort(unique(as.character(d$item)))
  if (length(items) < 2L) {
    stop("Q-factor extraction requires ratings for at least two items.", call. = FALSE)
  }

  RC <- unique(d[c("rater","construct")])
  RC$row_id <- seq_len(nrow(RC))
  d2 <- merge(d, RC, by = c("rater","construct"), all.x = TRUE)
  row_ids <- sort(unique(d2$row_id))
  mat <- matrix(NA_real_, nrow = length(row_ids), ncol = length(items),
                dimnames = list(NULL, items))
  for (it in items) {
    sel <- as.character(d2$item) == it
    mat[d2$row_id[sel], it] <- d2$rating[sel]
  }

  cor_Q <- suppressWarnings(stats::cor(mat, use = "pairwise.complete.obs"))
  if (any(!is.finite(cor_Q))) {
    stop("Q correlations are undefined; provide sufficient overlapping, variable item ratings.", call. = FALSE)
  }

  eg <- eigen(cor_Q, symmetric = TRUE, only.values = TRUE)$values
  parallel_eigen <- NULL
  k <- k_factors
  if (is.null(k)) {
    if (retention == "parallel") {
      parallel_eigen <- .parallel_eigen(mat, as.integer(n_iter), seed)
      above <- eg > parallel_eigen
      k_suggested <- if (all(above)) length(eg) else which.min(above) - 1L
    } else {
      message(.kaiser_critique())
      k_suggested <- sum(eg > 1)
    }
    k <- max(1L, k_suggested)
  } else {
    if (!is.numeric(k) || length(k) != 1L || !is.finite(k) ||
        k < 1 || k != floor(k) || k > ncol(cor_Q)) {
      stop("`k_factors` must be NULL or an integer from 1 through the number of items.", call. = FALSE)
    }
    k <- as.integer(k)
    k_suggested <- k
    retention <- "fixed"
  }

  if (method == "pca") {
    ev <- eigen(cor_Q, symmetric = TRUE)
    load <- ev$vectors[, seq_len(k), drop = FALSE] %*%
      diag(sqrt(pmax(ev$values[seq_len(k)], 0)), nrow = k)
    rownames(load) <- colnames(cor_Q)
    colnames(load) <- paste0("PC", seq_len(k))
  } else {
    inv <- tryCatch(solve(cor_Q), error = function(e) NULL)
    if (is.null(inv) || any(!is.finite(inv)) || any(diag(inv) == 0)) {
      stop("Principal-axis extraction requires a nonsingular Q-correlation matrix.", call. = FALSE)
    }
    smc <- 1 - 1 / diag(inv)
    R <- cor_Q
    diag(R) <- smc
    ev <- eigen(R, symmetric = TRUE)
    load <- ev$vectors[, seq_len(k), drop = FALSE] %*%
      diag(sqrt(pmax(ev$values[seq_len(k)], 0)), nrow = k)
    rownames(load) <- colnames(cor_Q)
    colnames(load) <- paste0("PA", seq_len(k))
  }

  list(cor_Q = cor_Q, eigen = eg, k = k, loadings = load, method = method,
       retention = retention, k_suggested = k_suggested,
       parallel_eigen = parallel_eigen)
}

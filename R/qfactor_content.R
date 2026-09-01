#' Q-factor helper for content adequacy (comparator)
#'
#' @description
#' Builds an item-by-item Q-correlation matrix from rating data and runs
#' a simple factor extraction (PCA by default). This legacy comparator is
#' retained for compatibility and exploratory use; it is not part of the
#' recommended sort, rating, or expert-panel workflows.
#'
#' @param ratings A data.frame with columns for item, rater, construct, rating.
#' @param item_col Name of the item column. Default "item".
#' @param rater_col Name of the rater column. Default "rater".
#' @param construct_col Name of the construct column. Default "construct".
#' @param rating_col Name of the rating column. Default "rating".
#' @param k_factors Optional integer: number of factors to extract. If `NULL`,
#'   uses a simple Kaiser > 1 rule on PCA eigenvalues to suggest k.
#' @param method `"pca"` (default) or `"pa"` (principal axis; uses SMCs as initial communalities).
#'
#' @return A list with components:
#'   - `cor_Q`: item-by-item correlation matrix,
#'   - `eigen`: eigenvalues of `cor_Q`,
#'   - `k`: number of factors used,
#'   - `loadings`: matrix of factor loadings,
#'   - `method`: the extraction method.
#'
#' @examples
#' set.seed(1)
#' df <- data.frame(
#'   item = rep(paste0("I",1:6), each = 30),
#'   rater = rep(1:10, times = 18),
#'   construct = rep(rep(LETTERS[1:3], each = 10), times = 6),
#'   rating = rnorm(180)
#' )
#' qf <- qfactor_content(df)
#' str(qf$loadings)
#' @export
qfactor_content <- function(ratings,
                            item_col = "item",
                            rater_col = "rater",
                            construct_col = "construct",
                            rating_col = "rating",
                            k_factors = NULL,
                            method = c("pca","pa")) {
  method <- match.arg(method)
  .validate_column_names(item_col, rater_col, construct_col, rating_col)
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
  k <- k_factors
  if (is.null(k)) {
    k <- sum(eg > 1)
    if (k < 1) k <- 1L
  } else {
    if (!is.numeric(k) || length(k) != 1L || !is.finite(k) ||
        k < 1 || k != floor(k) || k > ncol(cor_Q)) {
      stop("`k_factors` must be NULL or an integer from 1 through the number of items.", call. = FALSE)
    }
    k <- as.integer(k)
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

  list(cor_Q = cor_Q, eigen = eg, k = k, loadings = load, method = method)
}

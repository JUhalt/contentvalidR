#' Q-factor helper for content adequacy (comparator)
#'
#' @description
#' Builds an item-by-item Q-correlation matrix from rating data and runs
#' a simple factor extraction (PCA by default). This mirrors the Q-matrix
#' comparator used in pretesting workflows; use it alongside ANOVA.
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
  needed <- c(item_col, rater_col, construct_col, rating_col)
  if (!all(needed %in% names(ratings))) {
    stop("`ratings` must contain columns: ", paste(needed, collapse = ", "))
  }
  d <- ratings[, needed]
  names(d) <- c("item","rater","construct","rating")

  # Build a rectangular matrix: rows = rater x construct cells, cols = items
  # Each cell is the rating given to that item for that (rater, construct)
  RC <- unique(d[c("rater","construct")])
  RC$row_id <- seq_len(nrow(RC))
  d2 <- merge(d, RC, by = c("rater","construct"), all.x = TRUE)
  items <- sort(unique(d2$item))
  row_ids <- sort(unique(d2$row_id))
  mat <- matrix(NA_real_, nrow = length(row_ids), ncol = length(items),
                dimnames = list(NULL, items))
  # fill matrix
  # (we avoid tidyr/dplyr to keep dependencies light)
  for (it in items) {
    sel <- d2$item == it
    mat[d2$row_id[sel], it] <- d2$rating[sel]
  }

  # Q-correlation among items
  # pairwise complete obs to allow some missingness
  cor_Q <- suppressWarnings(stats::cor(mat, use = "pairwise.complete.obs"))

  # eigenvalues
  eg <- eigen(cor_Q, symmetric = TRUE, only.values = TRUE)$values

  k <- k_factors
  if (is.null(k)) {
    k <- sum(eg > 1) # simple Kaiser rule
    if (k < 1) k <- 1
  }

  if (method == "pca") {
    # principal components loadings = eigenvectors * sqrt(eigenvalues)
    ev <- eigen(cor_Q, symmetric = TRUE)
    load <- ev$vectors[, seq_len(k), drop = FALSE] %*% diag(sqrt(pmax(ev$values[1:k], 0)), nrow = k)
    rownames(load) <- colnames(cor_Q)
    colnames(load) <- paste0("PC", seq_len(k))
  } else {
    # very simple principal axis using SMCs as initial communalities
    smc <- 1 - 1 / diag(solve(cor_Q))
    R <- cor_Q
    diag(R) <- smc
    ev <- eigen(R, symmetric = TRUE)
    load <- ev$vectors[, seq_len(k), drop = FALSE] %*% diag(sqrt(pmax(ev$values[1:k], 0)), nrow = k)
    rownames(load) <- colnames(cor_Q)
    colnames(load) <- paste0("PA", seq_len(k))
  }

  list(cor_Q = cor_Q, eigen = eg, k = k, loadings = load, method = method)
}

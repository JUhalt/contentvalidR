#' Aiken's V for content validity (ordinal ratings)
#'
#' @description
#' Computes Aiken's V per item from judges' ordinal ratings on a bounded scale [lo, hi].
#' Optionally computes percentile bootstrap confidence intervals.
#'
#' @param ratings matrix/data.frame with rows = judges, cols = items (numeric).
#' @param lo,hi numeric scale bounds (default 1..5).
#' @param ci one of c("none","bootstrap"). If "bootstrap", percentile CI is returned.
#' @param B bootstrap reps (default 500; keep small for CRAN examples).
#' @param alpha CI level (default .05).
#' @param seed optional integer for reproducibility of bootstrap.
#'
#' @returns data.frame: item, V, (optional) ci_low, ci_high.
#' @examples
#' set.seed(1)
#' R <- matrix(sample(1:5, 5*6, replace=TRUE), nrow=5)  # 5 judges x 6 items
#' aikens_v(R, lo=1, hi=5, ci="none")
aikens_v <- function(ratings, lo = 1, hi = 5,
                     ci = c("none","bootstrap"), B = 500, alpha = 0.05, seed = NULL) {
  ci <- match.arg(ci)
  R <- as.matrix(ratings)
  if (!is.numeric(R)) stop("ratings must be numeric")
  if (!all(R >= lo & R <= hi, na.rm = TRUE)) stop("ratings outside [lo, hi]")
  m <- nrow(R)
  k <- hi - lo + 1
  V <- colMeans((R - lo), na.rm = TRUE) / (k - 1)
  out <- data.frame(item = colnames(R) %||% paste0("Item", seq_len(ncol(R))), V = V, row.names = NULL)
  if (ci == "none") return(out)

  # Bootstrap percentile CI
  if (!is.null(seed)) set.seed(seed)
  qlo <- alpha/2; qhi <- 1 - alpha/2
  bootV <- matrix(NA_real_, nrow = B, ncol = ncol(R))
  for (b in seq_len(B)) {
    idx <- sample.int(m, m, replace = TRUE)
    Rb <- R[idx, , drop = FALSE]
    bootV[b, ] <- colMeans((Rb - lo), na.rm = TRUE) / (k - 1)
  }
  out$ci_low  <- apply(bootV, 2, stats::quantile, probs = qlo, na.rm = TRUE)
  out$ci_high <- apply(bootV, 2, stats::quantile, probs = qhi, na.rm = TRUE)
  out
}

# utility for NULL coalescing
`%||%` <- function(a, b) if (is.null(a)) b else a

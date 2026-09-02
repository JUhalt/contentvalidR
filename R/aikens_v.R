#' Aiken's V for expert content-relevance ratings
#'
#' @description
#' Computes Aiken's V per item for bounded ordinal expert ratings. By default,
#' confidence intervals use the score method described by Penfield and
#' Giacobbi (2004). Percentile bootstrap intervals remain available for
#' compatibility and sensitivity analysis.
#'
#' @param ratings Matrix/data.frame with judges in rows and items in columns.
#' @param lo,hi Numeric lower and upper bounds of the rating scale.
#' @param ci Confidence-interval method: `"score"` (default), `"bootstrap"`,
#'   or `"none"`.
#' @param B Number of bootstrap replicates when `ci = "bootstrap"`.
#' @param alpha Two-sided CI alpha level; `.05` gives a 95% interval.
#' @param seed Optional integer seed for bootstrap reproducibility.
#' @param na.rm Logical. If `FALSE` (default), missing ratings are an error.
#'   If `TRUE`, item-specific effective judge counts are used.
#'
#' @return A data.frame with item, effective judge count `N`, number missing,
#'   Aiken's `V`, and (when requested) `ci_low` and `ci_high`.
#'
#' @references
#' Aiken, L. R. (1980). Content validity and reliability of single items or
#' questionnaires. *Educational and Psychological Measurement, 40*(4), 955-959.
#' \doi{10.1177/001316448004000419}
#'
#' Penfield, R. D., & Giacobbi, P. R., Jr. (2004). Applying a score confidence
#' interval to Aiken's item content-relevance index. *Measurement in Physical
#' Education and Exercise Science, 8*(4), 213-225.
#' \doi{10.1207/S15327841MPEE0804_3}
#'
#' @examples
#' R <- matrix(c(4,4,3,4, 4,3,4,4, 3,3,4,4), nrow = 4)
#' colnames(R) <- c("Item1", "Item2", "Item3")
#' aikens_v(R, lo = 1, hi = 4)
#' @export
aikens_v <- function(ratings, lo = 1, hi = 5,
                     ci = c("score", "none", "bootstrap"),
                     B = 500, alpha = 0.05, seed = NULL,
                     na.rm = FALSE) {
  ci <- match.arg(ci)
  .validate_flag(na.rm, "na.rm")
  R <- as.matrix(ratings)

  if (length(dim(R)) != 2L || nrow(R) < 1L || ncol(R) < 1L) {
    stop("`ratings` must contain at least one judge and one item.", call. = FALSE)
  }
  if (!is.numeric(R)) stop("`ratings` must be numeric.", call. = FALSE)
  if (!is.numeric(lo) || length(lo) != 1L || !is.finite(lo) ||
      !is.numeric(hi) || length(hi) != 1L || !is.finite(hi) || hi <= lo) {
    stop("`lo` and `hi` must be finite scalars with `hi > lo`.", call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be one finite number between 0 and 1.", call. = FALSE)
  }
  if (!all(R >= lo & R <= hi, na.rm = TRUE)) {
    stop("Ratings fall outside the specified `lo`/`hi` bounds.", call. = FALSE)
  }
  if (!isTRUE(na.rm) && anyNA(R)) {
    stop("Missing ratings found. Use `na.rm = TRUE` for itemwise deletion.", call. = FALSE)
  }

  item_names <- colnames(R)
  if (is.null(item_names)) item_names <- paste0("Item", seq_len(ncol(R)))
  if (anyNA(item_names) || any(!nzchar(trimws(item_names))) || anyDuplicated(item_names)) {
    stop("Item names must be unique, non-missing, and non-empty.", call. = FALSE)
  }
  N_total <- nrow(R)
  N <- if (isTRUE(na.rm)) colSums(!is.na(R)) else rep.int(N_total, ncol(R))
  n_missing <- N_total - N
  k <- hi - lo

  V <- vapply(seq_len(ncol(R)), function(j) {
    x <- R[, j]
    if (isTRUE(na.rm)) x <- x[!is.na(x)]
    if (length(x) == 0L) return(NA_real_)
    sum(x - lo) / (length(x) * k)
  }, numeric(1))

  out <- data.frame(
    item = item_names,
    N = as.integer(N),
    n_missing = as.integer(n_missing),
    V = V,
    row.names = NULL,
    stringsAsFactors = FALSE
  )

  if (ci == "none") return(out)

  if (ci == "score") {
    z <- stats::qnorm(1 - alpha / 2)
    z2 <- z^2
    denom <- 2 * (N * k + z2)
    radicand <- 4 * N * k * V * (1 - V) + z2
    root <- sqrt(radicand)
    out$ci_low <- (2 * N * k * V + z2 - z * root) / denom
    out$ci_high <- (2 * N * k * V + z2 + z * root) / denom
    out$ci_low[N < 1L] <- NA_real_
    out$ci_high[N < 1L] <- NA_real_
    out$ci_method <- "Penfield-Giacobbi score"
    return(out)
  }

  if (!is.numeric(B) || length(B) != 1L || !is.finite(B) || B < 2 || B != floor(B)) {
    stop("`B` must be an integer of at least 2 for bootstrap intervals.", call. = FALSE)
  }
  B <- as.integer(B)
  if (!is.null(seed)) {
    if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed) || seed != floor(seed)) {
      stop("`seed` must be NULL or one finite integer.", call. = FALSE)
    }
    set.seed(as.integer(seed))
  }
  qlo <- alpha / 2
  qhi <- 1 - alpha / 2
  bootV <- matrix(NA_real_, nrow = B, ncol = ncol(R))

  for (j in seq_len(ncol(R))) {
    x <- R[, j]
    if (isTRUE(na.rm)) x <- x[!is.na(x)]
    if (length(x) < 1L) next
    for (b in seq_len(B)) {
      xb <- x[sample.int(length(x), length(x), replace = TRUE)]
      bootV[b, j] <- sum(xb - lo) / (length(xb) * k)
    }
  }

  boot_quantile <- function(x, prob) {
    x <- x[is.finite(x)]
    if (length(x) == 0L) return(NA_real_)
    unname(stats::quantile(x, probs = prob, names = FALSE))
  }
  out$ci_low <- apply(bootV, 2, boot_quantile, prob = qlo)
  out$ci_high <- apply(bootV, 2, boot_quantile, prob = qhi)
  out$ci_method <- "percentile bootstrap"
  out
}

#' Content Validity Index (CVI)
#'
#' @description
#' Computes item-level Content Validity Index (I-CVI), scale-level average CVI
#' (S-CVI/Ave), universal-agreement CVI (S-CVI/UA), and the modified kappa
#' described by Polit, Beck, and Owen (2007).
#'
#' For each item, modified kappa adjusts I-CVI for chance agreement using the
#' probability of observing exactly `A` agreements among `N` judges:
#'
#' \deqn{P_c = {N \choose A}(0.5)^N}
#'
#' and
#'
#' \deqn{k^* = (I_CVI - P_c) / (1 - P_c).}
#'
#' I-CVI is a proportion of what is usually a small panel, so an interval is
#' reported alongside it. The interval method is selectable; see `ci`.
#'
#' @param binary Matrix/data.frame with judges in rows and items in columns,
#'   coded `1 = relevant` and `0 = not relevant`.
#' @param na.rm Logical. If `FALSE` (default), missing ratings are an error.
#'   If `TRUE`, missing ratings are removed itemwise and each item's effective
#'   judge count is reported in `N`.
#' @param ci Interval method for I-CVI:
#'   * `"wilson"` (default): the Wilson (1927) score interval. Newcombe (1998)
#'     compared seven methods and recommends score intervals over the Wald
#'     interval.
#'   * `"agresti_coull"`: the adjusted Wald interval of Agresti and Coull
#'     (1998), which they show performs well even in small samples. Limits are
#'     clipped so they stay between 0 and 1.
#'   * `"exact"`: the Clopper and Pearson (1934) interval. It is conservative:
#'     Agresti and Coull (1998) show its coverage runs above the nominal level.
#'   * `"none"`: no interval is computed, and the interval columns are `NA`.
#' @param alpha Two-sided alpha level for the interval; `0.05` gives a 95%
#'   interval.
#'
#' @return A classed list with:
#'   - `item_level`: item, A, N, I_CVI, I_CVI_low, I_CVI_high, Pc, kappa_mod
#'   - `scale_level`: S_CVI_Ave and S_CVI_UA
#'   - `ci` and `alpha`: the interval settings used
#'
#' @references
#' Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an acceptable
#' indicator of content validity? Appraisal and recommendations. *Research in
#' Nursing & Health, 30*(4), 459-467. \doi{10.1002/nur.20199}
#'
#' Wilson, E. B. (1927). Probable inference, the law of succession, and
#' statistical inference. *Journal of the American Statistical Association,
#' 22*(158), 209-212. \doi{10.1080/01621459.1927.10502953}
#'
#' Newcombe, R. G. (1998). Two-sided confidence intervals for the single
#' proportion: Comparison of seven methods. *Statistics in Medicine, 17*(8),
#' 857-872.
#'
#' Agresti, A., & Coull, B. A. (1998). Approximate is better than "exact" for
#' interval estimation of binomial proportions. *The American Statistician,
#' 52*(2), 119-126. \doi{10.1080/00031305.1998.10480550}
#'
#' Clopper, C. J., & Pearson, E. S. (1934). The use of confidence or fiducial
#' limits illustrated in the case of the binomial. *Biometrika, 26*(4),
#' 404-413. \doi{10.1093/biomet/26.4.404}
#'
#' @examples
#' M <- matrix(
#'   c(1,1,1,1, 1,1,1,0, 1,1,0,0),
#'   nrow = 4,
#'   dimnames = list(NULL, c("Item1", "Item2", "Item3"))
#' )
#' cvi(M)
#' cvi(M, ci = "exact")
#' @export
cvi <- function(binary,
                na.rm = FALSE,
                ci = c("wilson", "agresti_coull", "exact", "none"),
                alpha = 0.05) {
  .validate_flag(na.rm, "na.rm")
  ci <- match.arg(ci)
  X <- as.matrix(binary)
  if (length(dim(X)) != 2L || nrow(X) < 1L || ncol(X) < 1L) {
    stop("`binary` must contain at least one judge and one item.", call. = FALSE)
  }
  if (!is.numeric(X) && !is.logical(X)) {
    stop("`binary` must contain numeric/logical 0/1 values.", call. = FALSE)
  }

  bad <- !is.na(X) & !(X %in% c(0, 1))
  if (any(bad)) {
    stop("`binary` must contain only 0/1 values (plus NA when `na.rm = TRUE`).", call. = FALSE)
  }
  if (!isTRUE(na.rm) && anyNA(X)) {
    stop("Missing ratings found. Use `na.rm = TRUE` for itemwise deletion.", call. = FALSE)
  }

  item_names <- colnames(X)
  if (is.null(item_names)) item_names <- paste0("Item", seq_len(ncol(X)))
  if (anyNA(item_names) || any(!nzchar(trimws(item_names))) || anyDuplicated(item_names)) {
    stop("Item names must be unique, non-missing, and non-empty.", call. = FALSE)
  }

  N <- if (isTRUE(na.rm)) colSums(!is.na(X)) else rep.int(nrow(X), ncol(X))
  A <- colSums(X, na.rm = isTRUE(na.rm))
  I_CVI <- ifelse(N > 0, A / N, NA_real_)
  Pc <- ifelse(N > 0, stats::dbinom(A, size = N, prob = 0.5), NA_real_)
  kappa_mod <- (I_CVI - Pc) / (1 - Pc)
  kappa_mod[!is.finite(kappa_mod)] <- NA_real_
  interval <- .proportion_ci(A, N, method = ci, alpha = alpha)

  item_level <- data.frame(
    item = item_names,
    A = as.integer(A),
    N = as.integer(N),
    I_CVI = I_CVI,
    I_CVI_low = interval$low,
    I_CVI_high = interval$high,
    Pc = Pc,
    kappa_mod = kappa_mod,
    row.names = NULL,
    stringsAsFactors = FALSE
  )

  valid_items <- is.finite(I_CVI)
  scale_level <- data.frame(
    S_CVI_Ave = if (any(valid_items)) mean(I_CVI[valid_items]) else NA_real_,
    S_CVI_UA = if (any(valid_items)) mean(I_CVI[valid_items] == 1) else NA_real_,
    n_items = sum(valid_items),
    row.names = NULL
  )

  out <- list(
    item_level = item_level,
    scale_level = scale_level,
    na.rm = isTRUE(na.rm),
    ci = ci,
    alpha = alpha
  )
  class(out) <- "contentvalid_cvi"
  out
}

#' @export
print.contentvalid_cvi <- function(x, digits = 3, ...) {
  sl <- x$scale_level
  cat("Content Validity Index (CVI)\n")
  cat(strrep("-", 28), "\n", sep = "")
  cat("Items analyzed:", sl$n_items, "\n")
  if (length(unique(x$item_level$N)) == 1L) {
    cat("Judges per item:", unique(x$item_level$N), "\n")
  } else {
    cat("Judges per item:", min(x$item_level$N), "to", max(x$item_level$N),
        "(itemwise missingness)\n")
  }
  cat("S-CVI/Ave:", format(round(sl$S_CVI_Ave, digits), nsmall = digits), "\n")
  cat("S-CVI/UA :", format(round(sl$S_CVI_UA, digits), nsmall = digits), "\n\n")
  cat("Item-level results (modified kappa is chance-corrected):\n")
  tab <- x$item_level
  numeric_cols <- intersect(c("I_CVI", "I_CVI_low", "I_CVI_high", "Pc", "kappa_mod"), names(tab))
  tab[numeric_cols] <- lapply(tab[numeric_cols], round, digits = digits)
  print(tab, row.names = FALSE)
  if (!is.null(x$ci)) {
    cat("\n")
    cat(strwrap(.proportion_ci_note(x$ci, x$alpha), width = 76), sep = "\n")
  }
  cat("\nInterpretation should consider panel size, item purpose, and qualitative expert feedback;\n")
  cat("CVI statistics alone do not establish comprehensive content validity.\n")
  invisible(x)
}

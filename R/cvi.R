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
#' @param binary Matrix/data.frame with judges in rows and items in columns,
#'   coded `1 = relevant` and `0 = not relevant`.
#' @param na.rm Logical. If `FALSE` (default), missing ratings are an error.
#'   If `TRUE`, missing ratings are removed itemwise and each item's effective
#'   judge count is reported in `N`.
#'
#' @return A classed list with:
#'   - `item_level`: item, A, N, I_CVI, Pc, kappa_mod
#'   - `scale_level`: S_CVI_Ave and S_CVI_UA
#'
#' @references
#' Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an acceptable
#' indicator of content validity? Appraisal and recommendations. *Research in
#' Nursing & Health, 30*(4), 459-467. \doi{10.1002/nur.20199}
#'
#' @examples
#' M <- matrix(
#'   c(1,1,1,1, 1,1,1,0, 1,1,0,0),
#'   nrow = 4,
#'   dimnames = list(NULL, c("Item1", "Item2", "Item3"))
#' )
#' cvi(M)
#' @export
cvi <- function(binary, na.rm = FALSE) {
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

  N <- if (isTRUE(na.rm)) colSums(!is.na(X)) else rep.int(nrow(X), ncol(X))
  A <- colSums(X, na.rm = isTRUE(na.rm))
  I_CVI <- ifelse(N > 0, A / N, NA_real_)
  Pc <- ifelse(N > 0, stats::dbinom(A, size = N, prob = 0.5), NA_real_)
  kappa_mod <- (I_CVI - Pc) / (1 - Pc)
  kappa_mod[!is.finite(kappa_mod)] <- NA_real_

  item_level <- data.frame(
    item = item_names,
    A = as.integer(A),
    N = as.integer(N),
    I_CVI = I_CVI,
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

  out <- list(item_level = item_level, scale_level = scale_level, na.rm = isTRUE(na.rm))
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
  numeric_cols <- c("I_CVI", "Pc", "kappa_mod")
  tab[numeric_cols] <- lapply(tab[numeric_cols], round, digits = digits)
  print(tab, row.names = FALSE)
  cat("\nInterpretation should consider panel size, item purpose, and qualitative expert feedback;\n")
  cat("CVI statistics alone do not establish comprehensive content validity.\n")
  invisible(x)
}

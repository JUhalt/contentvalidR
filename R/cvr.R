#' Lawshe's Content Validity Ratio (CVR)
#'
#' @description
#' Computes Lawshe's CVR and exact one-sided binomial inference following the
#' critical-value logic revisited by Ayre and Scally (2014). Input may be either
#' counts of experts marking each item essential or a judge-by-item 0/1 matrix.
#'
#' @param essential Numeric/integer vector of essential counts, or a matrix/data
#'   frame with judges in rows, items in columns, coded `1 = essential` and
#'   `0 = not essential`.
#' @param N Panel size. Required for count-vector input. May be a scalar or a
#'   vector matching `essential`. Ignored for matrix input, where effective N is
#'   calculated itemwise.
#' @param alpha One-sided exact alpha level. Default `.05`.
#' @param na.rm Logical; for matrix input, permit itemwise missing ratings.
#' @param item_names Optional item names for count-vector input.
#'
#' @return A data.frame containing item, `ne`, effective `N`, CVR, exact
#'   p-value, critical essential count/CVR, and `pass`.
#'
#' @references
#' Lawshe, C. H. (1975). A quantitative approach to content validity.
#' *Personnel Psychology, 28*, 563-575.
#'
#' Ayre, C., & Scally, A. J. (2014). Critical values for Lawshe's content
#' validity ratio: Revisiting the original methods of calculation.
#' *Measurement and Evaluation in Counseling and Development, 47*(1), 79-86.
#' \doi{10.1177/0748175613513808}
#'
#' @examples
#' cvr(essential = c(8, 10, 5), N = 12)
#' @export
cvr <- function(essential, N = NULL, alpha = 0.05, na.rm = FALSE,
                item_names = NULL) {
  .validate_flag(na.rm, "na.rm")
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be one finite number between 0 and 1.", call. = FALSE)
  }

  if (is.matrix(essential) || is.data.frame(essential)) {
    X <- as.matrix(essential)
    if (!is.numeric(X) && !is.logical(X)) {
      stop("Matrix input must contain numeric/logical 0/1 values.", call. = FALSE)
    }
    bad <- !is.na(X) & !(X %in% c(0, 1))
    if (any(bad)) stop("Matrix input must contain only 0/1 values.", call. = FALSE)
    if (!isTRUE(na.rm) && anyNA(X)) {
      stop("Missing ratings found. Use `na.rm = TRUE` for itemwise deletion.", call. = FALSE)
    }
    if (nrow(X) < 1L || ncol(X) < 1L) {
      stop("Matrix input must contain at least one judge and one item.", call. = FALSE)
    }
    item_names <- colnames(X)
    if (is.null(item_names)) item_names <- paste0("Item", seq_len(ncol(X)))
    N <- if (isTRUE(na.rm)) colSums(!is.na(X)) else rep.int(nrow(X), ncol(X))
    essential <- colSums(X, na.rm = isTRUE(na.rm))
  } else {
    essential <- as.numeric(essential)
    if (length(essential) < 1L || any(!is.finite(essential))) {
      stop("`essential` must contain finite counts.", call. = FALSE)
    }
    if (is.null(N)) stop("`N` is required for count-vector input.", call. = FALSE)
    if (length(N) == 1L) N <- rep(N, length(essential))
    if (length(N) != length(essential)) {
      stop("`N` must be scalar or have the same length as `essential`.", call. = FALSE)
    }
    N <- as.numeric(N)
    if (is.null(item_names)) item_names <- paste0("Item", seq_along(essential))
    if (length(item_names) != length(essential)) {
      stop("`item_names` must match the number of items.", call. = FALSE)
    }
  }
  if (anyNA(item_names) || any(!nzchar(trimws(as.character(item_names)))) || anyDuplicated(as.character(item_names))) {
    stop("Item names must be unique, non-missing, and non-empty.", call. = FALSE)
  }

  if (any(N < 0 | !is.finite(N)) || any(essential < 0) || any(essential > N) ||
      any(abs(N - round(N)) > .Machine$double.eps^0.5) ||
      any(abs(essential - round(essential)) > .Machine$double.eps^0.5)) {
    stop("Essential counts and panel sizes must be valid nonnegative integers with `essential <= N`.", call. = FALSE)
  }
  N <- as.integer(N)
  essential <- as.integer(essential)

  critical_ne <- vapply(N, function(n) {
    if (n < 1L) return(NA_integer_)
    candidates <- 0:n
    tails <- stats::pbinom(candidates - 1L, size = n, prob = 0.5,
                           lower.tail = FALSE)
    ok <- which(tails <= alpha)
    if (length(ok) == 0L) NA_integer_ else candidates[min(ok)]
  }, integer(1))

  p_value <- vapply(seq_along(N), function(i) {
    if (N[i] < 1L) return(NA_real_)
    stats::pbinom(essential[i] - 1L, size = N[i], prob = 0.5,
                  lower.tail = FALSE)
  }, numeric(1))

  cvr_vals <- ifelse(N > 0, (essential - N / 2) / (N / 2), NA_real_)
  critical_cvr <- ifelse(
    N > 0 & critical_ne <= N,
    (critical_ne - N / 2) / (N / 2),
    NA_real_
  )
  pass <- !is.na(critical_ne) & N > 0 & essential >= critical_ne

  data.frame(
    item = as.character(item_names),
    ne = essential,
    N = N,
    cvr = cvr_vals,
    p_value = p_value,
    critical_ne = critical_ne,
    critical_cvr = critical_cvr,
    pass = pass,
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

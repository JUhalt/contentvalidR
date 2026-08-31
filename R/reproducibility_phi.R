#' Between-pretest reproducibility (phi) of binary decisions
#'
#' @description
#' Cross-tabulates retention decisions for the same items across two pretests
#' and reports signed phi and Pearson's chi-square test without Yates correction.
#' The full 2 x 2 table is retained even when one response level is absent.
#'
#' @param sig1 Logical vector of retention decisions from pretest 1.
#' @param sig2 Logical vector of retention decisions from pretest 2.
#'
#' @return A list containing the 2 x 2 table, signed phi, chi-square, and p-value.
#' @examples
#' sig1 <- c(TRUE, TRUE, FALSE, FALSE)
#' sig2 <- c(TRUE, FALSE, FALSE, TRUE)
#' reproducibility_phi(sig1, sig2)
#' @export
reproducibility_phi <- function(sig1, sig2) {
  if (!is.logical(sig1) || !is.logical(sig2)) {
    stop("`sig1` and `sig2` must be logical vectors.", call. = FALSE)
  }
  if (length(sig1) != length(sig2) || length(sig1) == 0L) {
    stop("`sig1` and `sig2` must have the same non-zero length.", call. = FALSE)
  }
  if (anyNA(sig1) || anyNA(sig2)) {
    stop("Missing values are not supported in `sig1` or `sig2`.", call. = FALSE)
  }

  f1 <- factor(sig1, levels = c(TRUE, FALSE), labels = c("Retain", "Delete"))
  f2 <- factor(sig2, levels = c(TRUE, FALSE), labels = c("Retain", "Delete"))
  m <- table(Pretest1 = f1, Pretest2 = f2)

  tp <- unname(m["Retain", "Retain"])
  fp <- unname(m["Retain", "Delete"])
  fn <- unname(m["Delete", "Retain"])
  tn <- unname(m["Delete", "Delete"])
  phi <- .signed_phi(tp = tp, tn = tn, fp = fp, fn = fn)

  chisq <- tryCatch(
    suppressWarnings(stats::chisq.test(m, correct = FALSE)),
    error = function(e) NULL
  )

  list(
    table = m,
    phi = phi,
    chisq = if (is.null(chisq) || !is.finite(chisq$statistic)) NA_real_ else unname(chisq$statistic),
    p = if (is.null(chisq) || !is.finite(chisq$p.value)) NA_real_ else chisq$p.value
  )
}

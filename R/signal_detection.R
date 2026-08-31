#' Signal-detection summary for binary retention decisions
#'
#' @description
#' Compares a logical vector of pretest retention decisions with a logical
#' ground-truth criterion (for example, later CFA retention). Reports a correctly
#' oriented confusion matrix, accuracy, sensitivity, specificity, signed phi,
#' and Pearson's chi-square test without Yates correction.
#'
#' @param predicted Logical vector of predicted retention decisions.
#' @param actual Logical vector of criterion retention decisions.
#'
#' @return A list containing the confusion matrix and diagnostic statistics.
#' @examples
#' predicted <- c(TRUE, TRUE, FALSE, FALSE)
#' actual    <- c(TRUE, FALSE, TRUE, FALSE)
#' signal_detection(predicted, actual)
#' @export
signal_detection <- function(predicted, actual) {
  if (!is.logical(predicted) || !is.logical(actual)) {
    stop("`predicted` and `actual` must be logical vectors.", call. = FALSE)
  }
  if (length(predicted) != length(actual) || length(predicted) == 0L) {
    stop("`predicted` and `actual` must have the same non-zero length.", call. = FALSE)
  }
  if (anyNA(predicted) || anyNA(actual)) {
    stop("Missing values are not supported in `predicted` or `actual`.", call. = FALSE)
  }

  tp <- sum(predicted & actual)
  tn <- sum(!predicted & !actual)
  fp <- sum(predicted & !actual)
  fn <- sum(!predicted & actual)

  m <- matrix(
    c(tp, fn, fp, tn),
    nrow = 2,
    byrow = FALSE,
    dimnames = list(
      Predicted = c("Retain", "Delete"),
      Actual = c("Retain", "Delete")
    )
  )

  chisq <- tryCatch(
    suppressWarnings(stats::chisq.test(m, correct = FALSE)),
    error = function(e) NULL
  )
  phi <- .signed_phi(tp = tp, tn = tn, fp = fp, fn = fn)

  list(
    confusion = m,
    accuracy = (tp + tn) / sum(m),
    sensitivity = if ((tp + fn) > 0) tp / (tp + fn) else NA_real_,
    specificity = if ((tn + fp) > 0) tn / (tn + fp) else NA_real_,
    phi = phi,
    chisq = if (is.null(chisq) || !is.finite(chisq$statistic)) NA_real_ else unname(chisq$statistic),
    p = if (is.null(chisq) || !is.finite(chisq$p.value)) NA_real_ else chisq$p.value
  )
}

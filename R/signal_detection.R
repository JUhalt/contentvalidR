#' Signal-detection summary for binary retention decisions
#'
#' @description
#' Auxiliary compatibility diagnostic. Compares a logical vector of pretest
#' retention decisions with a logical ground-truth criterion (for example, later CFA retention). Reports a correctly
#' oriented confusion matrix, accuracy, sensitivity, specificity, signed phi,
#' and a test of association: Pearson's chi-square test without Yates
#' correction, or Fisher's exact test when an expected count is below 5,
#' where the chi-square approximation is unreliable.
#'
#' The comparison follows the validation design of Anderson and Gerbing (1991),
#' who checked pretest assessments of items' substantive validity against how
#' those items later performed in a confirmatory factor analysis.
#'
#' @param predicted Logical vector of predicted retention decisions.
#' @param actual Logical vector of criterion retention decisions.
#'
#' @return A list containing the confusion matrix and diagnostic statistics:
#'   `accuracy`, `sensitivity`, `specificity`, signed `phi`, the chi-square
#'   statistic (`chisq`), the number of items (`n`), and `p` with the test it
#'   comes from in `p_method`: `"chi-square"`, or `"Fisher's exact test"`
#'   when an expected count is below 5. `p_chisq` always holds the chi-square
#'   *p* value.
#'   It prints as a short report in APA style; the elements themselves are
#'   unrounded.
#'
#' @references
#' Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
#' measures in a confirmatory factor analysis with a pretest assessment of their
#' substantive validities. *Journal of Applied Psychology, 76*(5), 732–740.
#' \doi{10.1037/0021-9010.76.5.732}
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
      Predicted = c("Retain", "Not retained"),
      Actual = c("Retain", "Not retained")
    )
  )

  test <- .two_by_two_test(m)
  phi <- .signed_phi(tp = tp, tn = tn, fp = fp, fn = fn)

  out <- list(
    confusion = m,
    accuracy = (tp + tn) / sum(m),
    sensitivity = if ((tp + fn) > 0) tp / (tp + fn) else NA_real_,
    specificity = if ((tn + fp) > 0) tn / (tn + fp) else NA_real_,
    phi = phi,
    chisq = test$chisq,
    p = test$p,
    p_method = test$p_method,
    p_chisq = test$p_chisq,
    n = test$n
  )
  .tag_component(out, "contentvalid_signal")
}

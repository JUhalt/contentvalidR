#' Signal-detection summary (Csv significant vs. “ground truth”)
#'
#' @description
#' Compares a logical vector of Csv-based "retain?" decisions to a logical
#' vector of ground-truth retention (e.g., CFA retained), producing confusion
#' matrix, accuracy, sensitivity, specificity, phi, and chi-square.
#'
#' @param predicted Logical vector: Csv-significant (TRUE/FALSE).
#' @param actual Logical vector: ground-truth retain (TRUE/FALSE).
#'
#' @return A list: confusion (2x2 matrix), accuracy, sensitivity, specificity, phi, chisq, p.
#' @examples
#' predicted <- c(TRUE, TRUE, FALSE, FALSE)
#' actual    <- c(TRUE, FALSE, TRUE, FALSE)
#' signal_detection(predicted, actual)
#' @export
signal_detection <- function(predicted, actual) {
  stopifnot(length(predicted) == length(actual))
  tp <- sum(predicted & actual)
  tn <- sum(!predicted & !actual)
  fp <- sum(predicted & !actual)
  fn <- sum(!predicted & actual)
  m <- matrix(c(tp, fp, fn, tn), nrow = 2,
              dimnames = list(Predicted = c("Retain","Delete"),
                              Actual    = c("Retain","Delete")))
  chisq <- suppressWarnings(chisq.test(m))
  phi <- sqrt(chisq$statistic / sum(m))
  list(confusion = m,
       accuracy = (tp + tn) / sum(m),
       sensitivity = if ((tp + fn) > 0) tp / (tp + fn) else NA_real_,
       specificity = if ((tn + fp) > 0) tn / (tn + fp) else NA_real_,
       phi = unname(phi),
       chisq = unname(chisq$statistic),
       p = chisq$p.value)
}

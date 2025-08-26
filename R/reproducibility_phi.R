#' Between-pretest reproducibility (phi) of Csv significance
#'
#' @description
#' Cross-tabulates Csv-significance decisions for the same items across two
#' pretests and reports phi and chi-square.
#'
#' @param sig1 Logical vector of Csv-significant flags from pretest 1.
#' @param sig2 Logical vector of Csv-significant flags from pretest 2.
#'
#' @return A list: table (2x2), phi, chisq, p.
#' @examples
#' sig1 <- c(TRUE, TRUE, FALSE, FALSE)
#' sig2 <- c(TRUE, FALSE, FALSE, TRUE)
#' reproducibility_phi(sig1, sig2)
reproducibility_phi <- function(sig1, sig2) {
  stopifnot(length(sig1) == length(sig2))
  m <- table(sig1, sig2)
  chisq <- suppressWarnings(chisq.test(m))
  phi <- sqrt(chisq$statistic / sum(m))
  list(table = m, phi = unname(phi), chisq = unname(chisq$statistic), p = chisq$p.value)
}

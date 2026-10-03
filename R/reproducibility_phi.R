#' Between-pretest reproducibility (phi) of binary decisions
#'
#' @description
#' Auxiliary compatibility diagnostic. Cross-tabulates retention decisions for
#' the same items across two pretests and reports signed phi with a test of
#' association: Pearson's chi-square test without Yates correction, or
#' Fisher's exact test when an expected count is below 5, where the
#' chi-square approximation is unreliable. Pretests compare a handful of
#' items, so the exact test is the usual case.
#' The full 2 x 2 table is retained even when one response level is absent.
#'
#' @param sig1 Logical vector of retention decisions from pretest 1.
#' @param sig2 Logical vector of retention decisions from pretest 2.
#'
#' @return A list containing the 2 x 2 table (`table`), signed `phi`, the
#'   chi-square statistic (`chisq`), the number of items (`n`), and `p` with
#'   the test it comes from in `p_method`: `"chi-square"`, or `"Fisher's
#'   exact test"` when an expected count is below 5. `p_chisq` always holds
#'   the chi-square *p* value.
#'   It prints as a short report in APA style; the elements themselves are
#'   unrounded.
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

  f1 <- factor(sig1, levels = c(TRUE, FALSE), labels = c("Retain", "Not retained"))
  f2 <- factor(sig2, levels = c(TRUE, FALSE), labels = c("Retain", "Not retained"))
  m <- table(Pretest1 = f1, Pretest2 = f2)

  tp <- unname(m["Retain", "Retain"])
  fp <- unname(m["Retain", "Not retained"])
  fn <- unname(m["Not retained", "Retain"])
  tn <- unname(m["Not retained", "Not retained"])
  phi <- .signed_phi(tp = tp, tn = tn, fp = fp, fn = fn)

  test <- .two_by_two_test(m)

  out <- list(
    table = m,
    phi = phi,
    chisq = test$chisq,
    p = test$p,
    p_method = test$p_method,
    p_chisq = test$p_chisq,
    n = test$n
  )
  .tag_component(out, "contentvalid_reproducibility")
}

# The test of association for a 2 x 2 table of decisions: Pearson's chi-square
# without Yates correction, and Fisher's exact p in its place when an expected
# count is below 5, the usual condition for the chi-square approximation.
# R's warning about the approximation is not passed on; the choice of test is
# reported instead.
.two_by_two_test <- function(m) {
  n <- sum(m)
  chisq <- tryCatch(
    suppressWarnings(stats::chisq.test(m, correct = FALSE)),
    error = function(e) NULL
  )
  stat <- if (is.null(chisq) || !is.finite(chisq$statistic)) NA_real_ else unname(chisq$statistic)
  p_chisq <- if (is.null(chisq) || !is.finite(chisq$p.value)) NA_real_ else chisq$p.value
  expected <- outer(rowSums(m), colSums(m)) / n
  small <- any(expected < 5)
  # With an empty row or column there is no association to test either way.
  exact <- !is.na(stat) && small
  list(
    chisq = stat,
    p = if (exact) stats::fisher.test(m)$p.value else p_chisq,
    p_method = if (is.na(stat)) NA_character_ else if (exact) "Fisher's exact test" else "chi-square",
    p_chisq = p_chisq,
    n = as.integer(n)
  )
}

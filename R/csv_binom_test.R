#' Binomial test for Csv significance
#'
#' @description
#' Tests whether assignment to the target construct exceeds chance (H0: p <= 0.5; H1: p > 0.5),
#' using the count of target assignments \code{n_c} out of \code{N} raters.
#'
#' @param n_c Integer; number of raters assigning item to the target construct.
#' @param N Integer; total raters for the item.
#' @param p0 Null proportion (default 0.5).
#' @param alpha Significance level (default 0.05).
#'
#' @return A list: p.value, estimate (n_c/N), conf.int, decision ("significant"/"n.s.").
#' @examples
#' csv_binom_test(n_c = 14, N = 20)
csv_binom_test <- function(n_c, N, p0 = 0.5, alpha = 0.05) {
  bt <- binom.test(n_c, N, p = p0, alternative = "greater")
  decision <- if (bt$p.value <= alpha) "significant" else "n.s."
  list(p.value = bt$p.value, estimate = unname(bt$estimate),
       conf.int = bt$conf.int, decision = decision)
}

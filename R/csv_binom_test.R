#' Exact item-sort significance test
#'
#' @description
#' Tests whether the number of assignments to an item's intended construct
#' exceeds the count expected under a binomial chance model. With the default
#' `p0 = 0.5`, this implements the Howard and Melloy (2016) retention test for
#' item-sort tasks by testing the target-assignment count directly. Unlike the
#' legacy critical-Csv procedure, the count-based test remains applicable when
#' respondents choose among more than two construct alternatives.
#'
#' The function name is retained for backward compatibility even though the
#' inferential test is performed on `n_c`, not on the observed Csv value.
#'
#' @param n_c Integer; number of non-missing assignments to the target construct.
#' @param N Integer; total number of non-missing assignments for the item.
#' @param p0 Null target-assignment probability. Default `0.5`, following
#'   Howard and Melloy (2016).
#' @param alpha Significance level. Default `0.05`.
#'
#' @return A list containing the exact p-value, observed target proportion,
#'   one-sided confidence interval, the minimum critical target count,
#'   a logical `passes_chance` flag, a backward-compatible `decision` label,
#'   and a plain-language `interpretation`.
#'
#' @references
#' Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task methods:
#' The presentation of a new statistical significance formula and
#' methodological best practices. *Journal of Business and Psychology, 31*(1),
#' 173-186. \doi{10.1007/s10869-015-9404-y}
#'
#' @examples
#' csv_binom_test(n_c = 15, N = 20)
#' csv_binom_test(n_c = 14, N = 20)
#' @export
csv_binom_test <- function(n_c, N, p0 = 0.5, alpha = 0.05) {
  if (length(N) != 1L || is.na(N) || N < 1 || N != floor(N)) {
    stop("`N` must be a positive integer.", call. = FALSE)
  }
  if (length(n_c) != 1L || is.na(n_c) || n_c < 0 || n_c > N || n_c != floor(n_c)) {
    stop("`n_c` must be an integer between 0 and `N`.", call. = FALSE)
  }
  if (length(p0) != 1L || is.na(p0) || p0 <= 0 || p0 >= 1) {
    stop("`p0` must be a single probability strictly between 0 and 1.", call. = FALSE)
  }
  if (length(alpha) != 1L || is.na(alpha) || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be a single probability strictly between 0 and 1.", call. = FALSE)
  }

  bt <- stats::binom.test(n_c, N, p = p0, alternative = "greater")
  critical_n <- .critical_target_count(N, p0 = p0, alpha = alpha)
  passes <- isTRUE(bt$p.value <= alpha)

  list(
    p.value = bt$p.value,
    estimate = unname(bt$estimate),
    conf.int = bt$conf.int,
    critical_n_target = critical_n,
    passes_chance = passes,
    decision = if (passes) "significant" else "n.s.",
    interpretation = if (passes) {
      "Target assignments exceed the exact chance criterion."
    } else {
      "Target assignments do not exceed the exact chance criterion."
    }
  )
}

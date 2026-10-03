#' Exact item-sort significance test
#'
#' @description
#' Tests whether the number of assignments to an item's intended construct
#' exceeds the count expected under a binomial model with null probability
#' `p0`. With the default `p0 = 0.5`, this implements the Howard and Melloy
#' (2016) retention test for item-sort tasks by testing the target-assignment
#' count directly. Unlike the legacy critical-Csv procedure, the count-based
#' test remains applicable when respondents choose among more than two
#' construct alternatives.
#'
#' The function name is retained for backward compatibility even though the
#' inferential test is performed on `n_c`, not on the observed Csv value.
#'
#' @details
#' `p0` is the null probability that a judge assigns the item to its intended
#' construct. It is not the rate expected from random assignment, which is 1
#' divided by the number of constructs offered. Howard and Melloy (2016)
#' describe .5 as arbitrary and lenient, kept because earlier work used it,
#' and suggest a higher value such as .6 or .75, chosen before data
#' collection, when the alternative constructs are clearly different from the
#' target or the judges are subject-matter experts.
#'
#' The criterion is met when the exact *p* is at or below `alpha`, so a *p*
#' equal to `alpha` counts as meeting it, and `critical_n_target` is the
#' fewest target assignments whose *p* is at or below `alpha`. A strict "below
#' `alpha`" gives the same decision unless a tail probability equals `alpha`
#' exactly, which cannot happen at `p0 = 0.5` and `alpha = 0.05`: every tail
#' probability is then a multiple of 1 / 2^N.
#'
#' With very few judges no count can reach `alpha`: at `p0 = 0.5` and
#' `alpha = 0.05`, four judges who all choose the target give *p* = .0625.
#' `critical_n_target` is then `NA`, and the printout says so.
#'
#' @param n_c Integer; number of non-missing assignments to the target construct.
#' @param N Integer; total number of non-missing assignments for the item.
#' @param p0 Null target-assignment probability. Default `0.5`, following
#'   Howard and Melloy (2016); see Details.
#' @param alpha Significance level. Default `0.05`. A *p* equal to `alpha`
#'   meets the criterion; see Details.
#'
#' @return A list containing the exact *p* value, observed target proportion,
#'   one-sided confidence interval at level `1 - alpha`, the minimum critical
#'   target count, a logical `passes_chance` flag (`TRUE` when the count meets
#'   the exact criterion), a backward-compatible `decision` label, and a
#'   plain-language `interpretation`.
#'   The inputs are returned too, as `n_target`, `N`, `p0`, and `alpha`.
#'   It prints as a short report in APA style; the elements themselves are
#'   unrounded.
#'
#' @references
#' Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task methods:
#' The presentation of a new statistical significance formula and
#' methodological best practices. *Journal of Business and Psychology, 31*(1),
#' 173–186. \doi{10.1007/s10869-015-9404-y}
#'
#' @examples
#' csv_binom_test(n_c = 15, N = 20)
#' csv_binom_test(n_c = 14, N = 20)
#' @export
csv_binom_test <- function(n_c, N, p0 = 0.5, alpha = 0.05) {
  if (!is.numeric(N) || length(N) != 1L || !is.finite(N) || N < 1 || N != floor(N)) {
    stop("`N` must be a positive finite integer.", call. = FALSE)
  }
  if (!is.numeric(n_c) || length(n_c) != 1L || !is.finite(n_c) ||
      n_c < 0 || n_c > N || n_c != floor(n_c)) {
    stop("`n_c` must be a finite integer between 0 and `N`.", call. = FALSE)
  }
  if (!is.numeric(p0) || length(p0) != 1L || !is.finite(p0) || p0 <= 0 || p0 >= 1) {
    stop("`p0` must be one finite probability strictly between 0 and 1.", call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be one finite probability strictly between 0 and 1.", call. = FALSE)
  }

  # The interval is one-sided at 1 - alpha, the level of the test, so the two
  # agree: its lower limit is above p0 when p is below alpha, and equals p0 in
  # the rare case where p equals alpha.
  bt <- stats::binom.test(n_c, N, p = p0, alternative = "greater",
                          conf.level = 1 - alpha)
  critical_n <- .critical_target_count(N, p0 = p0, alpha = alpha)
  passes <- isTRUE(bt$p.value <= alpha)

  out <- list(
    p.value = bt$p.value,
    estimate = unname(bt$estimate),
    conf.int = bt$conf.int,
    critical_n_target = critical_n,
    passes_chance = passes,
    decision = if (passes) "significant" else "n.s.",
    interpretation = if (passes) {
      "Target assignments meet the exact criterion."
    } else if (is.na(critical_n)) {
      paste("No count of target assignments can meet the exact criterion",
            "with this many judges.")
    } else {
      "Target assignments do not meet the exact criterion."
    },
    n_target = n_c, N = N, p0 = p0, alpha = alpha
  )
  .tag_component(out, "contentvalid_binom")
}

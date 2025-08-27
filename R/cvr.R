#' Lawshe's Content Validity Ratio (CVR)
#'
#' @description
#' Computes CVR per item and evaluates significance by deriving the
#' critical number of "essential" ratings via a binomial tail test at p0 = .5.
#'
#' @param essential integer vector of counts (per item) of judges rating the item "essential".
#' @param N integer scalar: number of judges on the panel (same for all items).
#' @param alpha significance level for the one-sided binomial test (default .05).
#'
#' @returns A data.frame with columns: item, ne, N, cvr, critical_ne, critical_cvr, pass.
#' @examples
#' cvr(essential = c(8,10,5), N = 12)
#' @export
cvr <- function(essential, N, alpha = 0.05) {
  stopifnot(length(N) == 1L, N > 0, all(essential >= 0), all(essential <= N))
  # binomial tail: smallest m with P(X >= m | N, .5) <= alpha
  # use pbinom for CDF; tail = 1 - pbinom(m-1, ...)
  m <- NA_integer_
  for (cand in 0:N) {
    if (1 - pbinom(cand - 1, N, 0.5) <= alpha) { m <- cand; break }
  }
  if (is.na(m)) m <- N + 1L  # extremely liberal alpha
  critical_cvr <- (m - (N/2)) / (N/2)
  cvr_vals <- (essential - (N/2)) / (N/2)
  pass <- essential >= m
  out <- data.frame(
    item = seq_along(essential),
    ne = essential,
    N = N,
    cvr = cvr_vals,
    critical_ne = m,
    critical_cvr = critical_cvr,
    pass = pass,
    row.names = NULL
  )
  out
}

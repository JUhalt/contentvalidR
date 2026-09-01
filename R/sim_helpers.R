#' Legacy simulation of item-sort target-count power
#'
#' @description Auxiliary compatibility helper. For supported exact planning, prefer [sort_power()], which does not require Monte Carlo simulation.
#' @param N Number of judges per item.
#' @param true_p True assignment probability to the target construct.
#' @param reps Number of simulation replications.
#' @param alpha Significance level.
#' @return Estimated power (a number between 0 and 1).
#' @examples
#' simulate_csv_power(N = 20, true_p = 0.65, reps = 100, alpha = 0.05)
#' @export
simulate_csv_power <- function(N = 20, true_p = 0.65, reps = 2000, alpha = 0.05) {
  if (!is.numeric(N) || length(N) != 1L || !is.finite(N) || N < 1 || N != floor(N)) {
    stop("`N` must be one positive integer.", call. = FALSE)
  }
  if (!is.numeric(true_p) || length(true_p) != 1L || !is.finite(true_p) || true_p < 0 || true_p > 1) {
    stop("`true_p` must be one probability between 0 and 1.", call. = FALSE)
  }
  if (!is.numeric(reps) || length(reps) != 1L || !is.finite(reps) || reps < 1 || reps != floor(reps)) {
    stop("`reps` must be one positive integer.", call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be one finite probability strictly between 0 and 1.", call. = FALSE)
  }
  hits <- stats::rbinom(as.integer(reps), as.integer(N), true_p)
  pvals <- vapply(hits, function(h) stats::binom.test(h, N, p = 0.5, alternative = "greater")$p.value, numeric(1))
  mean(pvals <= alpha)
}

#' Legacy independent-groups ANOVA power simulator
#'
#' @description
#' Simulates a balanced **independent-groups** one-way ANOVA. This helper is
#' retained for backward compatibility but does not represent the standard
#' within-judge Hinkin-Tracey design used by `rating_validity()`. It is an
#' auxiliary compatibility helper and is not a release-defining workflow.
#'
#' @param n_raters Number of raters per construct (balanced).
#' @param mean_diff Target mean minus other-construct means.
#' @param sd Within-cell standard deviation.
#' @param k_constructs Number of constructs.
#' @param reps Number of simulation replications.
#' @param alpha Significance level.
#' @return Estimated power (numeric in \[0, 1\]).
#' @examples
#' simulate_anova_power(n_raters = 20, mean_diff = 0.5, sd = 1, k_constructs = 4, reps = 100)
#' @export
simulate_anova_power <- function(n_raters = 30, mean_diff = 0.6, sd = 1,
                                 k_constructs = 5, reps = 1000, alpha = 0.05) {
  if (!is.numeric(n_raters) || length(n_raters) != 1L || !is.finite(n_raters) ||
      n_raters < 2 || n_raters != floor(n_raters)) {
    stop("`n_raters` must be one integer of at least 2.", call. = FALSE)
  }
  if (!is.numeric(mean_diff) || length(mean_diff) != 1L || !is.finite(mean_diff)) {
    stop("`mean_diff` must be one finite number.", call. = FALSE)
  }
  if (!is.numeric(sd) || length(sd) != 1L || !is.finite(sd) || sd <= 0) {
    stop("`sd` must be one positive finite number.", call. = FALSE)
  }
  if (!is.numeric(k_constructs) || length(k_constructs) != 1L || !is.finite(k_constructs) ||
      k_constructs < 2 || k_constructs != floor(k_constructs)) {
    stop("`k_constructs` must be one integer of at least 2.", call. = FALSE)
  }
  if (!is.numeric(reps) || length(reps) != 1L || !is.finite(reps) || reps < 1 || reps != floor(reps)) {
    stop("`reps` must be one positive integer.", call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be one finite probability strictly between 0 and 1.", call. = FALSE)
  }
  n_raters <- as.integer(n_raters)
  k_constructs <- as.integer(k_constructs)
  reps <- as.integer(reps)
  power <- 0
  others_mean <- 0
  target_mean <- others_mean + mean_diff
  for (i in seq_len(reps)) {
    y <- c(stats::rnorm(n_raters, target_mean, sd),
           stats::rnorm(n_raters * (k_constructs - 1), others_mean, sd))
    g <- factor(rep(seq_len(k_constructs), each = n_raters))
    a <- stats::aov(y ~ g)
    p <- summary(a)[[1]]$`Pr(>F)`[1]
    power <- power + as.integer(p <= alpha)
  }
  power / reps
}

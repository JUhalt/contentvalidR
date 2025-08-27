#' Simulate power for Csv binomial significance
#' @param N Number of judges per item.
#' @param true_p True assignment probability to the target construct.
#' @param reps Number of simulation replications.
#' @param alpha Significance level.
#' @return Estimated power (a number between 0 and 1).
#' @examples
#' simulate_csv_power(N = 20, true_p = 0.65, reps = 100, alpha = 0.05)
#' @export
simulate_csv_power <- function(N = 20, true_p = 0.65, reps = 2000, alpha = 0.05) {
  hits <- stats::rbinom(reps, N, true_p)
  pvals <- vapply(hits, function(h) stats::binom.test(h, N, p = 0.5, alternative = "greater")$p.value, numeric(1))
  mean(pvals <= alpha)
}

#' Simulate power for ANOVA content test (balanced design)
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

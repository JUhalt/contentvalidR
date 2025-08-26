#' Simulate power for Csv binomial significance
#' @param N judges, @param true_p true assignment prob to target, @param reps simulations
#' @param alpha sig level
#' @returns estimated power
simulate_csv_power <- function(N = 20, true_p = 0.65, reps = 2000, alpha = 0.05) {
  hits <- rbinom(reps, N, true_p)
  pvals <- vapply(hits, function(h) binom.test(h, N, p = 0.5, alternative = "greater")$p.value, numeric(1))
  mean(pvals <= alpha)
}

#' Simulate power for ANOVA content test (very simple, balanced)
#' @param n_raters per construct, @param mean_diff target mean minus others
#' @param sd within-cell sd, @param k_constructs number of constructs, @param reps sims
#' @returns estimated power (omnibus F)
simulate_anova_power <- function(n_raters = 30, mean_diff = 0.6, sd = 1, k_constructs = 5,
                                 reps = 1000, alpha = 0.05) {
  power <- 0
  others_mean <- 0
  target_mean <- others_mean + mean_diff
  for (i in seq_len(reps)) {
    y <- c(rnorm(n_raters, target_mean, sd),
           rnorm(n_raters * (k_constructs - 1), others_mean, sd))
    g <- factor(rep(seq_len(k_constructs), each = n_raters))
    a <- stats::aov(y ~ g)
    p <- summary(a)[[1]]$`Pr(>F)`[1]
    power <- power + as.integer(p <= alpha)
  }
  power / reps
}

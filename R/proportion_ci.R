.proportion_ci_methods <- c("wilson", "agresti_coull", "exact", "none")

# Two-sided interval for a binomial proportion x / n. The methods and their
# sources are documented on cvi() and compute_psa(); this helper only computes.
.proportion_ci <- function(x, n, method = "wilson", alpha = 0.05) {
  method <- match.arg(method, .proportion_ci_methods)
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) ||
      alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be one number strictly between 0 and 1.", call. = FALSE)
  }

  x <- as.numeric(x)
  n <- as.numeric(n)
  low <- rep(NA_real_, length(x))
  high <- rep(NA_real_, length(x))
  if (method == "none") return(list(low = low, high = high))

  ok <- !is.na(x) & !is.na(n) & n > 0
  if (!any(ok)) return(list(low = low, high = high))
  xo <- x[ok]
  no <- n[ok]
  z <- stats::qnorm(1 - alpha / 2)

  if (method == "wilson") {
    p <- xo / no
    denom <- 1 + z^2 / no
    centre <- (p + z^2 / (2 * no)) / denom
    half <- z * sqrt(p * (1 - p) / no + z^2 / (4 * no^2)) / denom
    low[ok] <- centre - half
    high[ok] <- centre + half
  } else if (method == "agresti_coull") {
    n_adj <- no + z^2
    p_adj <- (xo + z^2 / 2) / n_adj
    half <- z * sqrt(p_adj * (1 - p_adj) / n_adj)
    low[ok] <- p_adj - half
    high[ok] <- p_adj + half
  } else {
    lo_e <- rep(0, length(xo))
    hi_e <- rep(1, length(xo))
    some <- xo > 0
    not_all <- xo < no
    lo_e[some] <- stats::qbeta(alpha / 2, xo[some], no[some] - xo[some] + 1)
    hi_e[not_all] <- stats::qbeta(1 - alpha / 2, xo[not_all] + 1, no[not_all] - xo[not_all])
    low[ok] <- lo_e
    high[ok] <- hi_e
  }

  # Agresti-Coull limits can fall outside [0, 1]; the other methods only drift
  # past the bounds by floating-point error at zero or unanimous endorsement.
  list(low = pmax(0, low), high = pmin(1, high))
}

.proportion_ci_note <- function(method, alpha) {
  if (identical(method, "none")) {
    return("Intervals for proportion indices were not computed.")
  }
  level <- paste0(format(100 * (1 - alpha)), "%")
  what <- switch(
    method,
    wilson = paste(
      "Wilson score (the default). Newcombe (1998) compared seven methods and",
      "recommends score intervals over the Wald interval."
    ),
    agresti_coull = paste(
      "Agresti-Coull adjusted Wald. Agresti and Coull (1998) show it performs",
      "well even in small samples. Limits are clipped to [0, 1]."
    ),
    exact = paste(
      "Clopper-Pearson exact. This is conservative: Agresti and Coull (1998)",
      "show its coverage runs above the nominal level, so intervals are wider",
      "than they need to be."
    )
  )
  paste0(
    level, " intervals for proportions: ", what,
    " An interval reflects how few ratings an item received, not whether the",
    " right judges were chosen."
  )
}

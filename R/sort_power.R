#' Exact power for the item-sort target-count rule
#'
#' @description
#' Computes the exact probability that an item will meet the Howard-Melloy
#' target-count criterion for a planned judge sample size and an assumed true
#' target-assignment probability. This is a binomial calculation, not a
#' simulation.
#'
#' @param N Positive integer judge sample size(s).
#' @param true_p Assumed true probability that a judge assigns the item to its
#'   intended construct. May be scalar or vector.
#' @param p0 Null target-assignment probability. Default `0.5`.
#' @param alpha Significance level. Default `0.05`.
#'
#' @return An object of class `contentvalid_sort_power` containing an exact
#'   planning table.
#'
#' @examples
#' sort_power(N = c(20, 30, 40), true_p = .70)
#' sort_power(N = 30, true_p = c(.60, .70, .80))
#' @export
sort_power <- function(N, true_p, p0 = .5, alpha = .05) {
  if (!is.numeric(N) || length(N) < 1L || any(!is.finite(N)) || any(N < 1) || any(N != floor(N))) {
    stop("`N` must contain positive integers.", call. = FALSE)
  }
  if (!is.numeric(true_p) || length(true_p) < 1L || any(!is.finite(true_p)) || any(true_p < 0 | true_p > 1)) {
    stop("`true_p` must contain probabilities between 0 and 1.", call. = FALSE)
  }
  invisible(.critical_target_count(1L, p0 = p0, alpha = alpha))

  grid <- expand.grid(N = as.integer(N), true_p = true_p, KEEP.OUT.ATTRS = FALSE)
  grid$critical_n_target <- vapply(grid$N, .critical_target_count, integer(1), p0 = p0, alpha = alpha)
  grid$power <- stats::pbinom(grid$critical_n_target - 1L, size = grid$N,
                              prob = grid$true_p, lower.tail = FALSE)
  grid$minimum_observed_psa <- grid$critical_n_target / grid$N
  grid <- grid[c("N", "true_p", "critical_n_target", "minimum_observed_psa", "power")]

  out <- list(table = grid, settings = list(p0 = p0, alpha = alpha))
  class(out) <- "contentvalid_sort_power"
  out
}

#' @export
print.contentvalid_sort_power <- function(x, digits = 3, ...) {
  cat("Exact item-sort planning analysis\n")
  cat(strrep("-", 33), "\n", sep = "")
  cat(sprintf("Retention rule: p0 = %.2f, alpha = %.3f\n\n", x$settings$p0, x$settings$alpha))
  tab <- x$table
  tab[c("true_p", "minimum_observed_psa", "power")] <- lapply(
    tab[c("true_p", "minimum_observed_psa", "power")], round, digits = digits
  )
  print(tab, row.names = FALSE)
  cat("\nPower is the exact probability of reaching the required target-assignment count\n")
  cat("under the assumed true target-assignment probability.\n")
  invisible(x)
}


#' Plot exact item-sort planning evidence
#'
#' @description
#' Visualizes either exact Howard-Melloy retention power across planned judge
#' sample sizes or the minimum observed Psa implied by the exact critical target
#' count. The critical view is drawn as a step function over every integer judge
#' count in the displayed range, reflecting the discrete exact-binomial rule.
#' Multiple assumed true target-assignment probabilities are distinguished
#' by line type and plotting symbol rather than color.
#'
#' @param x A `contentvalid_sort_power` object.
#' @param type Either `"power"` or `"critical"`.
#' @param reference_power Optional horizontal reference value for `type = "power"`.
#'   No conventional target is imposed by default.
#' @param show_legend Logical; draw the compact power-series key. Default `TRUE`.
#' @param ... Additional graphical arguments passed to [graphics::plot()].
#' @return The input object invisibly.
#' @export
plot.contentvalid_sort_power <- function(x,
                                         type = c("power", "critical"),
                                         reference_power = NULL,
                                         show_legend = TRUE,
                                         ...) {
  type <- match.arg(type)
  tab <- x$table

  if (type == "critical") {
    requested <- unique(tab[c("N", "critical_n_target", "minimum_observed_psa")])
    requested <- requested[order(requested$N), , drop = FALSE]
    curve <- .critical_psa_curve(
      requested$N,
      p0 = x$settings$p0,
      alpha = x$settings$alpha
    )
    graphics::plot(curve$N, curve$minimum_observed_psa, type = "s", ylim = c(0, 1),
                   xlab = "Judges (N)",
                   ylab = "Minimum Psa for retention", ...)
    graphics::points(requested$N, requested$minimum_observed_psa, pch = 1)
    return(invisible(x))
  }

  ps <- sort(unique(tab$true_p))
  if (!is.null(reference_power)) {
    if (!is.numeric(reference_power) || length(reference_power) != 1L ||
        !is.finite(reference_power) || reference_power < 0 || reference_power > 1) {
      stop("`reference_power` must be NULL or one finite probability between 0 and 1.", call. = FALSE)
    }
  }
  xr <- range(tab$N)
  if (diff(xr) == 0) xr <- xr + c(-0.5, 0.5)
  graphics::plot(xr, c(0, 1), type = "n",
                 xlab = "Judges (N)", ylab = "Exact retention power", ...)
  if (!is.null(reference_power)) graphics::abline(h = reference_power, lty = 3)
  for (i in seq_along(ps)) {
    z <- tab[tab$true_p == ps[i], , drop = FALSE]
    z <- z[order(z$N), , drop = FALSE]
    graphics::lines(z$N, z$power, type = "b", lty = i, pch = ((i - 1L) %% 6L) + 1L)
  }
  if (isTRUE(show_legend)) {
    graphics::legend("topleft", legend = paste0("p = ", format(ps, trim = TRUE)),
                     lty = seq_along(ps), pch = ((seq_along(ps) - 1L) %% 6L) + 1L,
                     bty = "n", cex = 0.72)
  }
  invisible(x)
}

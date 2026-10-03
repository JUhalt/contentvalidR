#' Exact power for the item-sort target-count rule
#'
#' @description
#' Computes the exact probability that an item will meet the target-count
#' criterion of Howard and Melloy (2016) for a planned judge sample size and an assumed true
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
#'   planning table. When a panel is too small for any count to reach `alpha`
#'   (four or fewer judges at the defaults), `critical_n_target` and
#'   `minimum_observed_psa` are `NA` and `power` is 0: no item can be retained
#'   at that size.
#'
#' @references
#' Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task methods:
#' The presentation of a new statistical significance formula and
#' methodological best practices. *Journal of Business and Psychology, 31*(1),
#' 173–186. \doi{10.1007/s10869-015-9404-y}
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
  # When no count can reach alpha (very small panels), no item can be retained,
  # so the power is exactly 0, not undefined.
  grid$power <- ifelse(
    is.na(grid$critical_n_target), 0,
    stats::pbinom(grid$critical_n_target - 1L, size = grid$N,
                  prob = grid$true_p, lower.tail = FALSE)
  )
  grid$minimum_observed_psa <- grid$critical_n_target / grid$N
  grid <- grid[c("N", "true_p", "critical_n_target", "minimum_observed_psa", "power")]

  out <- list(table = grid, settings = list(p0 = p0, alpha = alpha))
  class(out) <- "contentvalid_sort_power"
  out
}

#' @export
print.contentvalid_sort_power <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  .print_header(x, "Item-sort planning")
  cat("Retention rule: Howard-Melloy exact test (p0 = ", .fmt(x$settings$p0),
      ", alpha = ", .fmt_alpha(x$settings$alpha), ")\n", sep = "")

  # The required count depends on the panel size only, so it is one column;
  # power depends on the assumed probability too, so it spreads across columns.
  t <- x$table
  sizes <- sort(unique(t$N))
  first <- t[match(sizes, t$N), , drop = FALSE]
  unreachable <- is.na(first$critical_n_target)
  tab <- data.frame(judges = sizes,
                    required = ifelse(unreachable, "none",
                                      paste0(first$critical_n_target, "/", sizes)),
                    `minimum Psa` = ifelse(unreachable, "--",
                                           .fmt(first$minimum_observed_psa, digits)),
                    stringsAsFactors = FALSE, check.names = FALSE)
  for (p in sort(unique(t$true_p))) {
    sel <- t[t$true_p == p, , drop = FALSE]
    tab[[paste("power at", .fmt(p, digits))]] <-
      .fmt(sel$power[match(sizes, sel$N)], digits)
  }
  cat("\n")
  .print_table(tab, more = "x$table")
  cat("\n")
  .say("Required: target assignments an item needs to be retained. Minimum",
       "Psa: the same as a proportion (Psa = proportion of substantive",
       "agreement). Power at a value: the exact probability of reaching the",
       "required count if each judge assigns the item to its target with that",
       "probability.")
  if (any(unreachable)) {
    cat("\n")
    .say(sprintf(paste("With %s, no count of target assignments reaches",
                       "alpha = %s, so no item can be retained and the power",
                       "is 0."),
                 .or_fewer_judges(max(sizes[unreachable])),
                 .fmt_alpha(x$settings$alpha)))
  }
  .closing(pointer = "See plot(x) for the power curve.")
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
#' @examples
#' plan <- sort_power(N = c(20, 30, 40), true_p = c(.60, .70, .80))
#' plot(plan)
#' plot(plan, type = "critical")
#' @export
plot.contentvalid_sort_power <- function(x,
                                         type = c("power", "critical"),
                                         reference_power = NULL,
                                         show_legend = TRUE,
                                         ...) {
  type <- .choose(type)
  .validate_flag(show_legend, "show_legend")
  op <- .plot_margins(list(...))
  on.exit(graphics::par(op), add = TRUE)
  tab <- x$table

  if (type == "critical") {
    requested <- unique(tab[c("N", "critical_n_target", "minimum_observed_psa")])
    requested <- requested[order(requested$N), , drop = FALSE]
    curve <- .critical_psa_curve(
      requested$N,
      p0 = x$settings$p0,
      alpha = x$settings$alpha
    )
    .plot_with(list(x = curve$N, y = curve$minimum_observed_psa, type = "s", ylim = c(0, 1),
                    yaxt = "n", xlab = "Judges (N)",
                    ylab = "Minimum Psa for retention"), list(...))
    .axis_bounded(2, at = seq(0, 1, 0.25))
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
  .plot_with(list(x = xr, y = c(0, 1), type = "n", yaxt = "n",
                  xlab = "Judges (N)", ylab = "Exact retention power"), list(...))
  .axis_bounded(2, at = seq(0, 1, 0.25))
  # A dashed line marks the reference value, so the curves are solid and
  # told apart by their markers.
  if (!is.null(reference_power)) graphics::abline(h = reference_power, lty = 2)
  marks <- ((seq_along(ps) - 1L) %% 6L) + 1L
  for (i in seq_along(ps)) {
    z <- tab[tab$true_p == ps[i], , drop = FALSE]
    z <- z[order(z$N), , drop = FALSE]
    graphics::lines(z$N, z$power, type = "b", lty = 1, pch = marks[i])
  }
  if (isTRUE(show_legend)) {
    ref <- !is.null(reference_power)
    graphics::legend("topleft",
                     legend = c(paste0("Target rate ", .fmt(ps)),
                                if (ref) paste0("Reference power ",
                                                .fmt(reference_power))),
                     lty = c(rep(1, length(ps)), if (ref) 2),
                     pch = c(marks, if (ref) NA),
                     bty = "n", cex = 0.72)
  }
  invisible(x)
}

# Smallest number of endorsing experts that clears the criterion for a panel of
# size n, or NA when no attainable count clears it.
.cvi_required_count <- function(n) {
  crit <- .cvi_common_criterion(n)
  out <- rep(NA_integer_, length(n))
  ok <- !is.na(crit) & n > 0L
  out[ok] <- as.integer(ceiling(crit[ok] * n[ok] - 1e-9))
  out[!is.na(out) & out > n] <- NA_integer_
  out
}

.cvr_required_count <- function(n, alpha) {
  vapply(n, function(k) {
    if (k < 1L) return(NA_integer_)
    candidates <- 0:k
    tails <- stats::pbinom(candidates - 1L, size = k, prob = 0.5, lower.tail = FALSE)
    ok <- which(tails <= alpha)
    if (!length(ok)) NA_integer_ else candidates[min(ok)]
  }, integer(1))
}

.power_at_panel <- function(n, prob, criterion, alpha) {
  required <- if (criterion == "cvi") {
    .cvi_required_count(n)
  } else {
    .cvr_required_count(n, alpha)
  }
  if (is.na(required)) return(0)
  stats::pbinom(required - 1L, size = n, prob = prob, lower.tail = FALSE)
}

#' Plan an expert panel against an explicit decision criterion
#'
#' @description
#' Reports the probability that an item will clear its expert-panel criterion,
#' given a panel size and an assumed probability that a single expert endorses
#' the item.
#'
#' This replaces advice of the form "use six experts" with a question that has
#' an answer: *if an expert endorses this item with probability `prob`, how
#' often will a panel of this size actually clear the criterion?* Nothing here
#' recommends a panel size. It reports the consequences of the sizes you ask
#' about, so the choice stays yours and stays documented.
#'
#' @param n_experts Panel sizes to evaluate.
#' @param prob Probability that one expert endorses the item, as relevant
#'   (`criterion = "cvi"`) or essential (`criterion = "cvr"`). Values well below
#'   0.5 describe items the panel largely rejects.
#' @param criterion `"cvi"` uses the common panel-size I-CVI guideline: 1.00 for
#'   three to five experts, 0.78 for six or more. `"cvr"` uses the exact
#'   Lawshe critical count at level `alpha`.
#' @param alpha Significance level for the CVR criterion. Ignored for CVI.
#' @param response_rate Expected proportion of invited experts who return usable
#'   ratings. When below 1, `n_experts` is treated as the number invited and the
#'   realized panel size is averaged over, so the reported probability accounts
#'   for both a smaller panel and the criterion that a smaller panel triggers.
#'
#' @return An object of class `contentvalid_expert_power`: a list whose `results`
#'   data frame holds one row per panel size and probability, with the required
#'   endorsement count and the probability of clearing.
#'
#' @section Why the curve is not always smooth:
#' The I-CVI criterion is a step function of panel size: it is 1.00 up to five
#' experts and 0.78 from six. Adding a sixth expert relaxes the criterion and
#' can raise the clearing probability sharply, while adding a fourth or fifth
#' expert under unanimity makes clearing *harder*. A planning curve that rose
#' smoothly with panel size would be hiding this, so it is reported as it is.
#'
#' @references
#' Lynn, M. R. (1986). Determination and quantification of content validity.
#' *Nursing Research, 35*(6), 382-385.
#'
#' Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an acceptable
#' indicator of content validity? *Research in Nursing & Health, 30*(4),
#' 459-467. \doi{10.1002/nur.20199}
#'
#' Ayre, C., & Scally, A. J. (2014). Critical values for Lawshe's content
#' validity ratio. *Measurement and Evaluation in Counseling and Development,
#' 47*(1), 79-86. \doi{10.1177/0748175613513808}
#'
#' @seealso [sort_power()] for item-sort planning, and [gtheory_content()] whose
#'   decision study plans panel size against a generalizability target.
#'
#' @examples
#' expert_power(n_experts = 3:10, prob = c(0.8, 0.9))
#' expert_power(n_experts = c(5, 10, 15), prob = 0.75, criterion = "cvr")
#' @export
expert_power <- function(n_experts = 3:12,
                         prob = c(0.7, 0.8, 0.9),
                         criterion = c("cvi", "cvr"),
                         alpha = 0.05,
                         response_rate = 1) {
  criterion <- match.arg(criterion)

  if (!is.numeric(n_experts) || !length(n_experts) || anyNA(n_experts) ||
      any(!is.finite(n_experts)) || any(n_experts < 1) ||
      any(n_experts != floor(n_experts))) {
    stop("`n_experts` must be positive integers.", call. = FALSE)
  }
  if (!is.numeric(prob) || !length(prob) || anyNA(prob) ||
      any(!is.finite(prob)) || any(prob < 0) || any(prob > 1)) {
    stop("`prob` must be probabilities between 0 and 1.", call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) ||
      alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be one number strictly between 0 and 1.", call. = FALSE)
  }
  if (!is.numeric(response_rate) || length(response_rate) != 1L ||
      !is.finite(response_rate) || response_rate <= 0 || response_rate > 1) {
    stop("`response_rate` must be one number greater than 0 and at most 1.",
         call. = FALSE)
  }

  n_experts <- as.integer(n_experts)
  grid <- expand.grid(n_experts = n_experts, prob = prob,
                      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)

  power <- numeric(nrow(grid))
  required <- rep(NA_integer_, nrow(grid))
  for (i in seq_len(nrow(grid))) {
    n_invited <- grid$n_experts[i]
    p <- grid$prob[i]
    if (response_rate >= 1) {
      power[i] <- .power_at_panel(n_invited, p, criterion, alpha)
      required[i] <- if (criterion == "cvi") {
        .cvi_required_count(n_invited)
      } else {
        .cvr_required_count(n_invited, alpha)
      }
    } else {
      # Average over the realized panel size, which is itself random under a
      # response rate below 1. A smaller realized panel can also change the
      # criterion, and that is captured here rather than assumed away.
      sizes <- 0:n_invited
      weights <- stats::dbinom(sizes, size = n_invited, prob = response_rate)
      conditional <- vapply(sizes, function(m) {
        if (m < 1L) return(0)
        .power_at_panel(m, p, criterion, alpha)
      }, numeric(1))
      power[i] <- sum(weights * conditional)
      required[i] <- NA_integer_
    }
  }

  results <- data.frame(
    n_experts = grid$n_experts,
    prob = grid$prob,
    required_endorsements = required,
    power = power,
    stringsAsFactors = FALSE
  )
  results <- results[order(results$prob, results$n_experts), , drop = FALSE]
  rownames(results) <- NULL

  out <- list(
    results = results,
    settings = list(
      method = if (criterion == "cvi") {
        "Exact binomial planning against the panel-size I-CVI guideline"
      } else {
        "Exact binomial planning against the Lawshe CVR critical count"
      },
      criterion = criterion,
      alpha = alpha,
      response_rate = response_rate
    ),
    design = list(
      type = "expert-panel planning",
      n_panel_sizes = length(n_experts),
      n_probabilities = length(prob)
    )
  )
  class(out) <- "contentvalid_expert_power"
  out
}

#' @export
print.contentvalid_expert_power <- function(x, digits = 3, ...) {
  .validate_digits(digits)
  cat("Expert-panel planning\n")
  cat("Criterion: ", x$settings$method, "\n", sep = "")
  if (x$settings$criterion == "cvr") {
    cat(sprintf("Alpha: %s\n", format(x$settings$alpha)))
  }
  if (x$settings$response_rate < 1) {
    cat(sprintf(paste0(
      "Response rate: %s. Panel sizes are experts invited; the realized panel\n",
      "is averaged over, including the criterion a smaller panel triggers.\n"),
      format(x$settings$response_rate)))
  }

  r <- x$results
  r$power <- round(r$power, digits)
  cat("\n")
  print(r, row.names = FALSE)

  if (x$settings$criterion == "cvi" && x$settings$response_rate >= 1) {
    small <- r[r$n_experts %in% 3:5, , drop = FALSE]
    if (nrow(small)) {
      cat(strwrap(paste(
        "\nNote the step at six experts. The I-CVI guideline requires unanimity",
        "with three to five experts and 0.78 from six, so a sixth expert",
        "relaxes the criterion while a fourth or fifth makes unanimity harder.",
        "That is a property of the guideline, not of the items."
      ), width = 76), sep = "\n")
    }
  }

  cat(strwrap(paste(
    "\nThis table reports the consequences of the panel sizes you asked about.",
    "It does not recommend one. `prob` is an assumption you supply, so treat",
    "the result as conditional on it and report the value you assumed."
  ), width = 76), sep = "\n")
  cat("\n")
  invisible(x)
}

#' Plot an expert-panel planning curve
#'
#' @param x A `contentvalid_expert_power` object.
#' @param show_legend Draw the key identifying each assumed endorsement
#'   probability.
#' @param ... Passed to [graphics::plot()].
#' @return `x`, invisibly. Called for the plot.
#' @examples
#' plot(expert_power(n_experts = 3:12, prob = c(0.7, 0.85)))
#' @export
plot.contentvalid_expert_power <- function(x, show_legend = TRUE, ...) {
  .validate_flag(show_legend, "show_legend")
  r <- x$results
  probs <- sort(unique(r$prob))

  graphics::plot(range(r$n_experts), c(0, 1), type = "n",
                 xlab = "Experts on the panel",
                 ylab = "Probability of clearing the criterion", ...)
  for (i in seq_along(probs)) {
    sub <- r[r$prob == probs[i], , drop = FALSE]
    sub <- sub[order(sub$n_experts), , drop = FALSE]
    # Drawn as a step function: the criterion itself changes with panel size,
    # so joining the points with straight lines would imply smooth behaviour
    # the decision rule does not have.
    graphics::lines(sub$n_experts, sub$power, type = "s",
                    lty = (i - 1L) %% 5L + 1L)
    graphics::points(sub$n_experts, sub$power, pch = (i - 1L) %% 25L + 1L)
  }
  if (isTRUE(show_legend)) {
    graphics::legend("bottomright", legend = paste("prob =", probs),
                     lty = (seq_along(probs) - 1L) %% 5L + 1L,
                     pch = (seq_along(probs) - 1L) %% 25L + 1L,
                     bty = "n", cex = 0.7)
  }
  invisible(x)
}

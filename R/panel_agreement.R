# Gwet's AC1 for any number of raters and categories, following the computation
# in Gwet's own irrCAC implementation: agreement is averaged over items rated by
# at least two raters, category probabilities over every rated item.
.gwet_ac1 <- function(X) {
  rated <- colSums(!is.na(X)) >= 1L
  X <- X[, rated, drop = FALSE]
  values <- sort(unique(as.vector(X[!is.na(X)])))
  q <- length(values)
  empty <- list(estimate = NA_real_, pa = NA_real_, pe = NA_real_, n_items = 0L)
  if (ncol(X) < 1L || q < 1L) return(empty)

  counts <- matrix(
    vapply(seq_len(ncol(X)), function(i) {
      tabulate(match(X[!is.na(X[, i]), i], values), nbins = q)
    }, numeric(q)),
    nrow = q
  )
  r <- colSums(counts)
  paired <- r >= 2
  if (!any(paired)) return(empty)

  pa <- mean(colSums(counts[, paired, drop = FALSE] * (counts[, paired, drop = FALSE] - 1)) /
               (r[paired] * (r[paired] - 1)))
  pi_q <- rowMeans(sweep(counts, 2, r, "/"))
  pe <- if (q >= 2L) sum(pi_q * (1 - pi_q)) / (q - 1) else 0

  list(estimate = (pa - pe) / (1 - pe), pa = pa, pe = pe, n_items = sum(paired))
}

# Share of within-item rating pairs that are identical.
.pair_agreement <- function(X) {
  same <- 0
  total <- 0
  for (u in seq_len(ncol(X))) {
    x <- X[!is.na(X[, u]), u]
    m <- length(x)
    if (m < 2L) next
    counts <- table(x)
    same <- same + sum(counts * (counts - 1))
    total <- total + m * (m - 1)
  }
  if (total == 0) NA_real_ else same / total
}

# Percentile bootstrap resampling items with every rater's rating intact
# (Zapf et al., 2016).
.unit_bootstrap <- function(X, stat, B, alpha, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  n_units <- ncol(X)
  estimates <- vapply(seq_len(B), function(b) {
    stat(X[, sample.int(n_units, n_units, replace = TRUE), drop = FALSE])
  }, numeric(1))
  usable <- is.finite(estimates)
  limits <- if (sum(usable) >= 2L) {
    stats::quantile(estimates[usable], c(alpha / 2, 1 - alpha / 2), names = FALSE)
  } else {
    c(NA_real_, NA_real_)
  }
  list(low = limits[1], high = limits[2], n_usable = sum(usable))
}

.ac1_critique <- function() {
  paste(
    "Gwet's AC1 is available but is not the default. Vach and Gerke (2023)",
    "show that it rises as ratings concentrate in one category even when",
    "agreement is unchanged, that it can be non-zero when raters are",
    "independent, and that benchmark labels developed for kappa, such as",
    "Landis and Koch's, must not be applied to it."
  )
}

#' Panel-level agreement among expert raters
#'
#' @description
#' Summarizes how consistently a panel rated the whole item set, as one
#' coefficient with a bootstrap interval. This is panel-level evidence. It
#' complements, and does not replace, item-level indices such as I-CVI and
#' modified kappa, which describe one item at a time.
#'
#' Two coefficients are available:
#'
#' * `"krippendorff"` (default): Krippendorff's alpha, computed from the
#'   coincidence matrix as described by Krippendorff (2011). It works with any
#'   number of raters and with missing ratings. Zapf et al. (2016) recommend it
#'   specifically when data are ordinal or ratings are missing, which is typical
#'   of expert panels. It is a general reliability coefficient (Hayes &
#'   Krippendorff, 2007); no publication applying it specifically to
#'   content-validity panels was found.
#' * `"ac1"`: Gwet's (2008) AC1, designed for high-agreement data where
#'   kappa-type coefficients fall. It is never the default: Vach and Gerke
#'   (2023) show that it rises as ratings concentrate in one category even at a
#'   fixed level of agreement, and that it can be non-zero when raters are
#'   independent. Its printed output always repeats that critique. AC1 treats
#'   the supplied values as unordered categories.
#'
#' @section Why a close-agreeing panel can have a low alpha:
#' Alpha compares observed disagreement with the disagreement expected if the
#' same ratings were assigned to items at random. When ratings cluster on a few
#' values, as they do when nearly every item is rated relevant, very little
#' disagreement is expected by chance, so even a few disagreements pull alpha
#' down. The output reports the share of identical rating pairs alongside the
#' coefficient so this pattern is visible rather than misread as a poor panel.
#'
#' @section Interval:
#' The interval is a percentile bootstrap that resamples items with all of
#' their ratings intact, the procedure Zapf et al. (2016) evaluated. They found
#' Krippendorff's original bootstrap reached only about 60% coverage because it
#' ignores dependence between raters. Zapf et al. evaluated the procedure for
#' Fleiss' kappa and Krippendorff's alpha; applying it to AC1 is this package's
#' extension. Intervals vary slightly between runs unless `seed` is set.
#'
#' @param ratings A numeric matrix or data frame with raters in rows and items
#'   in columns. Missing ratings are allowed.
#' @param method `"krippendorff"` (default) or `"ac1"`.
#' @param level Measurement level for Krippendorff's alpha: `"ordinal"`
#'   (default), `"nominal"`, or `"interval"`. Ignored for AC1.
#' @param B Number of bootstrap resamples. Use `0` to skip the interval.
#' @param alpha Two-sided error rate for the bootstrap interval; `0.05` gives a
#'   95% interval. This is not Krippendorff's alpha.
#' @param seed Optional seed for a reproducible interval.
#'
#' @return An object of class `contentvalid_agreement`: a list with `method`,
#'   `level`, `estimate`, `ci_low`, `ci_high`, `alpha`, `B`, `n_boot_usable`,
#'   `n_items` (items rated by at least two raters), `n_raters`,
#'   `percent_agreement` (share of within-item rating pairs that are identical),
#'   `interpretation`, and `critique`.
#'
#' @references
#' Hayes, A. F., & Krippendorff, K. (2007). Answering the call for a standard
#' reliability measure for coding data. *Communication Methods and Measures,
#' 1*(1), 77-89. \doi{10.1080/19312450709336664}
#'
#' Krippendorff, K. (2011). *Computing Krippendorff's alpha-reliability.*
#' Annenberg School for Communication, University of Pennsylvania.
#' \url{https://repository.upenn.edu/items/034a6030-c584-4d14-9d3d-7b7e8d16df20}
#'
#' Zapf, A., Castell, S., Morawietz, L., & Karch, A. (2016). Measuring
#' inter-rater reliability for nominal data: Which coefficients and confidence
#' intervals are appropriate? *BMC Medical Research Methodology, 16*, 93.
#' \doi{10.1186/s12874-016-0200-9}
#'
#' Gwet, K. L. (2008). Computing inter-rater reliability and its variance in
#' the presence of high agreement. *British Journal of Mathematical and
#' Statistical Psychology, 61*(1), 29-48. \doi{10.1348/000711006X126600}
#'
#' Wongpakaran, N., Wongpakaran, T., Wedding, D., & Gwet, K. L. (2013). A
#' comparison of Cohen's kappa and Gwet's AC1 when calculating inter-rater
#' reliability coefficients: A study conducted with personality disorder
#' samples. *BMC Medical Research Methodology, 13*, 61.
#' \doi{10.1186/1471-2288-13-61}
#'
#' Vach, W., & Gerke, O. (2023). Gwet's AC1 is not a substitute for Cohen's
#' kappa: A comparison of basic properties. *MethodsX, 10*, 102212.
#'
#' Feinstein, A. R., & Cicchetti, D. V. (1990). High agreement but low kappa:
#' I. The problems of two paradoxes. *Journal of Clinical Epidemiology,
#' 43*(6), 543-549. \doi{10.1016/0895-4356(90)90158-L}
#'
#' @seealso [expert_validity()] for item-level expert-panel evidence.
#'
#' @examples
#' ratings <- rbind(
#'   c(4, 4, 3, 2, 4), c(4, 3, 3, 2, 4), c(3, 4, 4, 1, 4), c(4, 4, 3, 2, 3)
#' )
#' panel_agreement(ratings, seed = 1)
#' panel_agreement(ratings, level = "interval", B = 0)
#' panel_agreement(ratings >= 3, method = "ac1", B = 0)
#' @export
panel_agreement <- function(ratings,
                            method = c("krippendorff", "ac1"),
                            level = c("ordinal", "nominal", "interval"),
                            B = 1000,
                            alpha = 0.05,
                            seed = NULL) {
  method <- match.arg(method)
  level <- match.arg(level)

  X <- as.matrix(ratings)
  if (is.logical(X)) storage.mode(X) <- "numeric"
  if (!is.numeric(X)) stop("`ratings` must be numeric.", call. = FALSE)
  if (any(is.infinite(X))) stop("`ratings` cannot contain infinite values.", call. = FALSE)
  if (nrow(X) < 2L || ncol(X) < 2L) {
    stop("`ratings` needs at least two raters (rows) and two items (columns).",
         call. = FALSE)
  }
  .validate_bootstrap_args(B, seed, "B")
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) ||
      alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be one number strictly between 0 and 1.", call. = FALSE)
  }

  stat <- if (method == "krippendorff") {
    function(M) .krippendorff_alpha(M, level)$estimate
  } else {
    function(M) .gwet_ac1(M)$estimate
  }
  estimate <- stat(X)
  boot <- if (B > 0) {
    .unit_bootstrap(X, stat, as.integer(B), alpha, seed)
  } else {
    list(low = NA_real_, high = NA_real_, n_usable = 0L)
  }
  n_items <- sum(colSums(!is.na(X)) >= 2L)
  pct <- .pair_agreement(X)

  interpretation <- if (n_items == 0L) {
    "No item was rated by at least two raters, so no rating pairs exist and agreement cannot be estimated."
  } else if (is.na(estimate)) {
    paste(
      "Every paired rating was identical, so there is no disagreement to",
      "measure and the coefficient is undefined. The panel agreed completely."
    )
  } else if (method == "krippendorff") {
    paste(
      "Alpha compares the disagreement observed within items with the",
      "disagreement expected if these same ratings were assigned to items at",
      "random: 1 means perfect agreement and 0 means agreement no better than",
      "chance. Alpha falls when ratings cluster on a few values, because little",
      "disagreement is then expected by chance. A high share of identical",
      "rating pairs alongside a low alpha reflects that clustering, which is",
      "common when nearly every item is rated relevant, and is not by itself",
      "evidence of a poor panel."
    )
  } else {
    paste(
      "AC1 compares observed agreement with the agreement expected by chance,",
      "estimated so that it stays high when nearly every rating falls in one",
      "category (Gwet, 2008)."
    )
  }

  out <- list(
    method = method,
    level = if (method == "krippendorff") level else NA_character_,
    estimate = estimate,
    ci_low = boot$low,
    ci_high = boot$high,
    alpha = alpha,
    B = as.integer(B),
    n_boot_usable = boot$n_usable,
    n_items = n_items,
    n_raters = nrow(X),
    percent_agreement = pct,
    interpretation = interpretation,
    critique = if (method == "ac1") .ac1_critique() else NA_character_
  )
  class(out) <- "contentvalid_agreement"
  out
}

#' @export
print.contentvalid_agreement <- function(x, digits = 3, ...) {
  .validate_digits(digits)
  label <- .agreement_label(x$method, x$level)

  cat("Panel-level agreement\n")
  cat(sprintf("Items rated by two or more raters: %d   Raters: %d\n", x$n_items, x$n_raters))
  cat(label, ": ", format(round(x$estimate, digits)), sep = "")
  if (is.finite(x$ci_low) && is.finite(x$ci_high)) {
    cat(sprintf("   %s%% interval: %s to %s",
                format(100 * (1 - x$alpha)),
                format(round(x$ci_low, digits)),
                format(round(x$ci_high, digits))))
  }
  cat("\n")
  if (is.finite(x$percent_agreement)) {
    cat("Identical rating pairs: ", format(round(100 * x$percent_agreement, 1)), "%\n", sep = "")
  }

  cat("\n")
  cat(strwrap(x$interpretation, width = 76), sep = "\n")

  if (x$method == "krippendorff") {
    cat("\n")
    cat(strwrap(paste(
      "Krippendorff's alpha is the default because it handles ordinal ratings",
      "and missing ratings (Zapf et al., 2016). It is a general reliability",
      "coefficient; no publication applying it specifically to content-validity",
      "panels was found."
    ), width = 76), sep = "\n")
  } else {
    cat("\n")
    cat(strwrap(x$critique, width = 76), sep = "\n")
  }

  if (x$B > 0) {
    cat("\n")
    note <- paste(
      "The interval resamples items with all of their ratings, following Zapf",
      "et al. (2016), and varies slightly between runs unless `seed` is set."
    )
    if (x$method == "ac1") {
      note <- paste(
        note,
        "Zapf et al. evaluated this procedure for Fleiss' kappa and Krippendorff's",
        "alpha; applying it to AC1 is this package's extension."
      )
    }
    if (x$n_boot_usable < x$B) {
      note <- paste0(
        note, " In ", x$B - x$n_boot_usable, " of ", x$B, " resamples the",
        " coefficient could not be computed, usually because every resampled",
        " rating was identical; the interval uses the rest. With few items this",
        " interval is imprecise and can be misleading."
      )
    }
    cat(strwrap(note, width = 76), sep = "\n")
  }

  cat("\nPanel agreement describes how consistently raters rated these items.",
      "\nIt does not show that the items are relevant or that the domain is covered.\n")
  invisible(x)
}

# Headline and reading note for panel agreement inside expert_validity() output.
.expert_agreement_line <- function(ag, digits) {
  if (is.null(ag)) {
    return("Panel agreement: not estimated; it needs at least two experts and two items.")
  }
  head <- paste0("Panel agreement, ", .agreement_label(ag$method, ag$level), ": ")
  if (ag$n_items == 0L) return(paste0(head, "not estimable; no item has two ratings."))
  if (is.na(ag$estimate)) return(paste0(head, "undefined; every paired rating was identical."))

  out <- paste0(head, format(round(ag$estimate, digits)))
  if (is.finite(ag$ci_low) && is.finite(ag$ci_high)) {
    out <- paste0(out, " (", format(100 * (1 - ag$alpha)), "% interval ",
                  format(round(ag$ci_low, digits)), " to ",
                  format(round(ag$ci_high, digits)), ")")
  }
  if (is.finite(ag$percent_agreement)) {
    out <- paste0(out, ". Identical rating pairs: ",
                  format(round(100 * ag$percent_agreement, 1)), "%")
  }
  out
}

.expert_agreement_note <- function(ag) {
  if (ag$method == "ac1") {
    return(paste("AC1 here uses the relevant/not-relevant decision at relevance_cut.",
                 .ac1_critique()))
  }
  paste(
    "Panel agreement is one coefficient for the whole panel, whereas kappa_mod",
    "describes each item. Alpha can be low when nearly every rating is the same",
    "value, even on a panel that agrees closely, so read it beside the share of",
    "identical rating pairs. A low alpha with many identical pairs is not by",
    "itself evidence of a poor panel. Print `details$agreement` for the full",
    "explanation and interval details."
  )
}

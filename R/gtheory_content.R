# Largest panel size treated as attainable. Beyond this, a target coefficient is
# reported as unreachable rather than as a number no study could field.
.gtheory_max_panel <- 1000L

.gtheory_mean_squares <- function(X) {
  # X is a judges-by-items numeric matrix with no missing values.
  n_j <- nrow(X)
  n_i <- ncol(X)
  grand <- mean(X)
  judge_means <- rowMeans(X)
  item_means <- colMeans(X)

  ss_judge <- n_i * sum((judge_means - grand)^2)
  ss_item <- n_j * sum((item_means - grand)^2)
  resid <- X - outer(judge_means, rep(1, n_i)) -
    outer(rep(1, n_j), item_means) + grand
  ss_resid <- sum(resid^2)

  df_judge <- n_j - 1L
  df_item <- n_i - 1L
  df_resid <- df_judge * df_item

  list(
    n_judges = n_j,
    n_items = n_i,
    ss_judge = ss_judge,
    ss_item = ss_item,
    ss_resid = ss_resid,
    df_judge = df_judge,
    df_item = df_item,
    df_resid = df_resid,
    ms_judge = if (df_judge > 0L) ss_judge / df_judge else NA_real_,
    ms_item = if (df_item > 0L) ss_item / df_item else NA_real_,
    ms_resid = if (df_resid > 0L) ss_resid / df_resid else NA_real_
  )
}

.gtheory_coefficients <- function(var_item, var_judge, var_resid, n_judges) {
  rel_error <- var_resid / n_judges
  abs_error <- (var_judge + var_resid) / n_judges
  g <- if (!is.finite(var_item) || (var_item + rel_error) <= 0) NA_real_ else var_item / (var_item + rel_error)
  phi <- if (!is.finite(var_item) || (var_item + abs_error) <= 0) NA_real_ else var_item / (var_item + abs_error)
  list(g = g, phi = phi, rel_error = rel_error, abs_error = abs_error)
}

.gtheory_judges_needed <- function(target, var_item, error_var) {
  if (!is.finite(var_item) || var_item <= 0 || !is.finite(error_var)) return(NA_integer_)
  if (error_var <= 0) return(1L)
  if (target <= 0 || target >= 1) return(NA_integer_)
  needed <- target * error_var / (var_item * (1 - target))
  # A target can require a panel far larger than any study would field. Report
  # that as unattainable rather than printing an absurd number or overflowing.
  if (!is.finite(needed) || needed > .gtheory_max_panel) return(NA_integer_)
  as.integer(max(1L, ceiling(needed)))
}

#' Generalizability analysis of content-validity ratings
#'
#' @description
#' Decomposes judge ratings of items into item, judge, and residual variance
#' components, then reports how dependably the panel's ratings generalize over
#' judges.
#'
#' This follows the generalizability-theory treatment of content-validity
#' ratings in Crocker, Llabre, and Miller (1988). Items are the objects of
#' measurement and judges are the facet of generalization, so the question the
#' analysis answers is: *if a different panel of judges of the same size had
#' rated these items, how similar would the conclusions be?*
#'
#' Two coefficients are reported because they answer different questions:
#'
#' * The **generalizability coefficient** (relative, `g_coefficient`) concerns
#'   the *rank ordering* of items by rated relevance. Use it when the decision
#'   is comparative, such as selecting the strongest items from a pool.
#' * The **dependability coefficient** (absolute, `phi_coefficient`) concerns
#'   the *absolute level* of the ratings and is penalized by judge severity
#'   differences. Use it when the decision is criterion-referenced, such as
#'   whether items clear a fixed relevance standard. Most content-validity
#'   decisions are criterion-referenced, so `phi_coefficient` is usually the
#'   more relevant of the two.
#'
#' Because a single rating per judge-item cell cannot separate the judge-by-item
#' interaction from measurement error, the two are reported together as a single
#' residual component. This is a property of the design, not of the estimator.
#'
#' @param ratings A judges-by-items numeric matrix or data frame: one row per
#'   judge, one column per item.
#' @param na.rm If `TRUE`, judges with any missing rating are dropped so that a
#'   complete crossed design remains, and the number dropped is reported. If
#'   `FALSE` (default), missing values are an error.
#' @param targets Coefficient targets used for the decision study. Each must lie
#'   strictly between 0 and 1.
#' @param max_judges Largest panel size shown in the decision-study projection.
#'
#' @return An object of class `contentvalid_gtheory`, a list containing:
#'   \describe{
#'     \item{variance_components}{Source, degrees of freedom, mean squares,
#'       estimated variance component, and percentage of total variance.}
#'     \item{coefficients}{Observed-design generalizability and dependability
#'       coefficients with their error variances.}
#'     \item{dstudy}{Projected coefficients across panel sizes.}
#'     \item{judges_needed}{Judges required to reach each target coefficient,
#'       for relative and absolute decisions. `NA` means the target is not
#'       reachable with any realistic panel, which happens when items are barely
#'       distinguished from one another.}
#'     \item{settings, design}{Analysis settings and realized design metadata.}
#'   }
#'
#' @section Negative variance estimates:
#' ANOVA estimation can yield negative variance components when a true component
#' is near zero. Negative estimates are truncated to zero for the coefficient
#' calculations, following standard practice, and the untruncated estimate is
#' retained in the `variance_raw` column so the truncation is visible rather
#' than silent.
#'
#' @references
#' Crocker, L., Llabre, M., & Miller, M. D. (1988). The generalizability of
#' content validity ratings. *Journal of Educational Measurement, 25*(4),
#' 287-299. \doi{10.1111/j.1745-3984.1988.tb00309.x}
#'
#' Brennan, R. L. (2001). *Generalizability Theory.* Springer.
#'
#' @examples
#' # Six items rated for relevance by eight judges on a 1-4 scale. Items 1-4 are
#' # clearly relevant, items 5-6 are marginal, and judge 8 is notably severe.
#' ratings <- rbind(
#'   c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
#'   c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(4, 3, 4, 3, 1, 2),
#'   c(4, 4, 3, 4, 2, 2), c(3, 3, 3, 2, 1, 1)
#' )
#' dimnames(ratings) <- list(paste0("Judge", 1:8), paste0("Item", 1:6))
#' gtheory_content(ratings)
#' @export
gtheory_content <- function(ratings,
                            na.rm = FALSE,
                            targets = c(0.70, 0.80, 0.90),
                            max_judges = 30) {
  .validate_flag(na.rm, "na.rm")

  if (!is.numeric(targets) || !length(targets) || anyNA(targets) ||
      any(!is.finite(targets)) || any(targets <= 0) || any(targets >= 1)) {
    stop("`targets` must be numbers strictly between 0 and 1.", call. = FALSE)
  }
  if (!is.numeric(max_judges) || length(max_judges) != 1L || !is.finite(max_judges) ||
      max_judges < 1 || max_judges != floor(max_judges)) {
    stop("`max_judges` must be one positive integer.", call. = FALSE)
  }

  X <- as.matrix(ratings)
  if (!is.numeric(X)) {
    stop("`ratings` must be numeric.", call. = FALSE)
  }
  if (any(is.infinite(X))) {
    stop("`ratings` cannot contain infinite values.", call. = FALSE)
  }
  if (is.null(colnames(X))) colnames(X) <- paste0("Item", seq_len(ncol(X)))
  if (is.null(rownames(X))) rownames(X) <- paste0("Judge", seq_len(nrow(X)))

  n_judges_input <- nrow(X)
  n_missing <- sum(is.na(X))
  n_dropped <- 0L

  if (n_missing > 0L) {
    if (!na.rm) {
      stop("`ratings` contains missing values; set `na.rm = TRUE` to drop ",
           "judges with incomplete ratings.", call. = FALSE)
    }
    keep <- stats::complete.cases(X)
    n_dropped <- sum(!keep)
    X <- X[keep, , drop = FALSE]
  }

  n_judges <- nrow(X)
  n_items <- ncol(X)

  design <- list(
    type = "generalizability (items x judges, crossed, single rating per cell)",
    n_items = n_items,
    n_judges = n_judges,
    n_judges_input = n_judges_input,
    n_judges_dropped = n_dropped,
    n_missing = n_missing
  )
  settings <- list(
    method = "Crocker-Llabre-Miller generalizability analysis of content-validity ratings",
    na.rm = isTRUE(na.rm),
    targets = targets,
    max_judges = as.integer(max_judges),
    object_of_measurement = "item",
    facet = "judge"
  )

  insufficient <- n_judges < 2L || n_items < 2L
  if (insufficient) {
    out <- list(
      variance_components = data.frame(
        source = c("item", "judge", "residual"),
        df = NA_integer_, ms = NA_real_,
        variance_raw = NA_real_, variance = NA_real_, percent = NA_real_,
        stringsAsFactors = FALSE
      ),
      coefficients = data.frame(
        n_judges = n_judges, g_coefficient = NA_real_, phi_coefficient = NA_real_,
        rel_error_var = NA_real_, abs_error_var = NA_real_,
        stringsAsFactors = FALSE
      ),
      dstudy = data.frame(),
      judges_needed = data.frame(
        target = targets, n_judges_relative = NA_integer_,
        n_judges_absolute = NA_integer_, stringsAsFactors = FALSE
      ),
      settings = settings,
      design = design,
      status = "Insufficient data",
      interpretation = paste(
        "At least two judges and two items with complete ratings are required to",
        "separate item, judge, and residual variance. No generalizability",
        "coefficient can be estimated from this design."
      )
    )
    class(out) <- "contentvalid_gtheory"
    return(out)
  }

  ms <- .gtheory_mean_squares(X)

  var_item_raw <- (ms$ms_item - ms$ms_resid) / n_judges
  var_judge_raw <- (ms$ms_judge - ms$ms_resid) / n_items
  var_resid_raw <- ms$ms_resid

  var_item <- max(0, var_item_raw)
  var_judge <- max(0, var_judge_raw)
  var_resid <- max(0, var_resid_raw)

  total <- var_item + var_judge + var_resid
  pct <- if (total > 0) c(var_item, var_judge, var_resid) / total * 100 else rep(NA_real_, 3L)

  variance_components <- data.frame(
    source = c("item", "judge", "residual"),
    df = c(ms$df_item, ms$df_judge, ms$df_resid),
    ms = c(ms$ms_item, ms$ms_judge, ms$ms_resid),
    variance_raw = c(var_item_raw, var_judge_raw, var_resid_raw),
    variance = c(var_item, var_judge, var_resid),
    percent = pct,
    stringsAsFactors = FALSE
  )

  obs <- .gtheory_coefficients(var_item, var_judge, var_resid, n_judges)
  coefficients <- data.frame(
    n_judges = n_judges,
    g_coefficient = obs$g,
    phi_coefficient = obs$phi,
    rel_error_var = obs$rel_error,
    abs_error_var = obs$abs_error,
    stringsAsFactors = FALSE
  )

  sizes <- sort(unique(c(seq_len(min(10L, as.integer(max_judges))),
                         seq(2L, as.integer(max_judges), by = 2L),
                         n_judges)))
  sizes <- sizes[sizes >= 1L & sizes <= max(as.integer(max_judges), n_judges)]
  proj <- lapply(sizes, function(k) {
    cf <- .gtheory_coefficients(var_item, var_judge, var_resid, k)
    data.frame(n_judges = k, g_coefficient = cf$g, phi_coefficient = cf$phi,
               stringsAsFactors = FALSE)
  })
  dstudy <- do.call(rbind, proj)
  rownames(dstudy) <- NULL

  judges_needed <- data.frame(
    target = targets,
    n_judges_relative = vapply(
      targets, function(t) .gtheory_judges_needed(t, var_item, var_resid), integer(1)
    ),
    n_judges_absolute = vapply(
      targets, function(t) .gtheory_judges_needed(t, var_item, var_judge + var_resid), integer(1)
    ),
    stringsAsFactors = FALSE
  )

  no_item_variance <- !is.na(obs$phi) && var_item <= 0

  status <- if (is.na(obs$phi) || no_item_variance) {
    "Descriptive only"
  } else if (obs$phi >= 0.80) {
    "Supported"
  } else {
    "Review"
  }

  judge_share <- if (total > 0) var_judge / total * 100 else NA_real_
  interpretation <- if (is.na(obs$phi)) {
    paste(
      "Every rating was effectively identical, so no variance could be",
      "partitioned and no dependability coefficient could be computed.",
      "Treat the ratings as descriptive."
    )
  } else if (no_item_variance) {
    paste(
      "No item-level true-score variance was detected: the judges did not",
      "reliably distinguish these items from one another, and essentially all",
      "variation is disagreement within judge-item cells. Both coefficients are",
      "therefore 0, which is not a statement that the items are poor -- a",
      "uniformly relevant item set produces this result too. It does mean these",
      "ratings cannot support comparisons among the items, and that a larger",
      "panel would not change that. Use item-level relevance evidence instead."
    )
  } else if (obs$phi >= 0.80) {
    sprintf(paste(
      "With %d judges, absolute decisions about these items would generalize",
      "dependably to another panel of the same size (Phi = %.2f). Judge",
      "differences account for %.1f%% of total variance."
    ), n_judges, obs$phi, judge_share)
  } else {
    sprintf(paste(
      "With %d judges, absolute decisions about these items generalize only",
      "moderately to another panel of the same size (Phi = %.2f). Judge",
      "differences account for %.1f%% of total variance. See `judges_needed`",
      "for the panel size implied by a higher target, and review judge-level",
      "severity before treating borderline items as settled."
    ), n_judges, obs$phi, judge_share)
  }

  out <- list(
    variance_components = variance_components,
    coefficients = coefficients,
    dstudy = dstudy,
    judges_needed = judges_needed,
    settings = settings,
    design = design,
    status = status,
    interpretation = interpretation
  )
  class(out) <- "contentvalid_gtheory"
  out
}

#' @export
print.contentvalid_gtheory <- function(x, digits = 3, ...) {
  .validate_digits(digits)
  cat("Generalizability analysis of content-validity ratings\n")
  cat("Design: items x judges, crossed, one rating per cell\n")
  cat(sprintf("Items: %d   Judges: %d\n", x$design$n_items, x$design$n_judges))
  if (isTRUE(x$design$n_judges_dropped > 0L)) {
    cat(sprintf("Judges dropped for incomplete ratings: %d of %d\n",
                x$design$n_judges_dropped, x$design$n_judges_input))
  }
  cat("\nVariance components\n")
  vc <- x$variance_components
  vc$ms <- round(vc$ms, digits)
  vc$variance_raw <- round(vc$variance_raw, digits)
  vc$variance <- round(vc$variance, digits)
  vc$percent <- round(vc$percent, 1)
  print(vc, row.names = FALSE)

  cf <- x$coefficients
  cat("\nObserved design\n")
  cat(sprintf("  Generalizability coefficient (relative, rank ordering): %s\n",
              format(round(cf$g_coefficient, digits))))
  cat(sprintf("  Dependability coefficient (absolute, fixed standard):   %s\n",
              format(round(cf$phi_coefficient, digits))))

  if (nrow(x$judges_needed)) {
    cat("\nJudges required to reach each target\n")
    print(x$judges_needed, row.names = FALSE)
  }

  cat("\nStatus: ", x$status, "\n", sep = "")
  cat(strwrap(x$interpretation, width = 76), sep = "\n")
  cat("\nA dependability coefficient describes generalization over judges only.",
      "\nIt is not evidence that the items cover the intended content domain.\n")
  invisible(x)
}

# Internal helpers for judge/rater heterogeneity analysis.

# Iteratively drop judges and items whose endorsement rate is 0 or 1. Such
# elements carry no information about relative severity and produce infinite
# maximum-likelihood estimates (perfect separation). This is standard practice
# in Rasch estimation; the dropped elements are reported rather than hidden.
.facets_trim_extremes <- function(B, max_iter = 10L) {
  keep_j <- rep(TRUE, nrow(B))
  keep_i <- rep(TRUE, ncol(B))

  for (iter in seq_len(max_iter)) {
    sub <- B[keep_j, keep_i, drop = FALSE]
    if (!nrow(sub) || !ncol(sub)) break

    jr <- rowMeans(sub, na.rm = TRUE)
    ir <- colMeans(sub, na.rm = TRUE)
    bad_j <- !is.finite(jr) | jr <= 0 | jr >= 1
    bad_i <- !is.finite(ir) | ir <= 0 | ir >= 1

    if (!any(bad_j) && !any(bad_i)) break
    keep_j[which(keep_j)[bad_j]] <- FALSE
    keep_i[which(keep_i)[bad_i]] <- FALSE
  }

  list(keep_judges = keep_j, keep_items = keep_i)
}

# Dichotomous many-facet Rasch model fitted as a logistic regression:
#   logit P(endorse) = item_effect - judge_severity
# The generalized linear model formulation of Rasch-family models follows
# de Boeck & Wilson (2004). Estimation is joint maximum likelihood, so the
# Wright-Douglas (L-1)/L bias correction is applied and reported.
.facets_severity <- function(B, bias_correct = TRUE) {
  n_j <- nrow(B)
  judge_names <- rownames(B)
  if (is.null(judge_names)) judge_names <- paste0("Judge", seq_len(n_j))

  empty <- data.frame(
    judge = judge_names,
    severity = NA_real_,
    se = NA_real_,
    infit = NA_real_,
    outfit = NA_real_,
    estimable = FALSE,
    stringsAsFactors = FALSE
  )

  trim <- .facets_trim_extremes(B)
  n_drop_j <- sum(!trim$keep_judges)
  n_drop_i <- sum(!trim$keep_items)
  sub <- B[trim$keep_judges, trim$keep_items, drop = FALSE]

  if (nrow(sub) < 2L || ncol(sub) < 2L) {
    return(list(
      table = empty,
      estimable = FALSE,
      n_judges_dropped = n_drop_j,
      n_items_dropped = n_drop_i,
      bias_correction = NA_real_,
      reason = paste(
        "Judge severity could not be estimated. After removing judges and items",
        "with no variation in endorsement, fewer than two judges and two items",
        "remained. This usually means the panel agreed almost completely, which",
        "is a substantive finding rather than an estimation failure: with near",
        "total agreement there are no severity differences to recover."
      )
    ))
  }

  sub_judges <- rownames(sub)
  long <- data.frame(
    y = as.vector(sub),
    judge = factor(rep(sub_judges, times = ncol(sub)), levels = sub_judges),
    item = factor(rep(colnames(sub), each = nrow(sub)), levels = colnames(sub)),
    stringsAsFactors = FALSE
  )
  long <- long[!is.na(long$y), , drop = FALSE]

  fit <- try(
    suppressWarnings(stats::glm(y ~ item + judge, family = stats::binomial(), data = long)),
    silent = TRUE
  )
  if (inherits(fit, "try-error") || !isTRUE(fit$converged)) {
    return(list(
      table = empty, estimable = FALSE,
      n_judges_dropped = n_drop_j, n_items_dropped = n_drop_i,
      bias_correction = NA_real_,
      reason = "The facets model did not converge, so judge severity is not reported."
    ))
  }

  beta <- stats::coef(fit)
  V <- stats::vcov(fit)
  ok <- !is.na(beta)
  beta <- beta[ok]
  V <- V[ok, ok, drop = FALSE]

  # Map model coefficients onto one effect per judge. The reference judge has an
  # effect of exactly 0 under treatment contrasts, so its row is all zeros.
  k <- length(sub_judges)
  A <- matrix(0, nrow = k, ncol = length(beta),
              dimnames = list(sub_judges, names(beta)))
  for (idx in seq_along(sub_judges)) {
    nm <- paste0("judge", sub_judges[idx])
    if (nm %in% colnames(A)) A[idx, nm] <- 1
  }

  # Centre the judge effects so severity is expressed against the panel mean,
  # then negate: a judge less likely to endorse is more severe.
  C <- diag(k) - matrix(1 / k, nrow = k, ncol = k)
  L <- -C %*% A
  severity <- as.vector(L %*% beta)
  se <- sqrt(pmax(0, diag(L %*% V %*% t(L))))

  correction <- 1
  if (isTRUE(bias_correct)) {
    n_items_used <- ncol(sub)
    if (n_items_used > 1L) correction <- (n_items_used - 1L) / n_items_used
    severity <- severity * correction
    se <- se * correction
  }

  # Infit and outfit mean squares from standardized residuals.
  p <- stats::fitted(fit)
  resid <- long$y - p
  w <- p * (1 - p)
  infit <- rep(NA_real_, k)
  outfit <- rep(NA_real_, k)
  for (idx in seq_len(k)) {
    sel <- long$judge == sub_judges[idx]
    if (!any(sel)) next
    wi <- w[sel]
    ri <- resid[sel]
    usable <- wi > .Machine$double.eps
    if (!any(usable)) next
    outfit[idx] <- mean((ri[usable]^2) / wi[usable])
    denom <- sum(wi)
    if (denom > .Machine$double.eps) infit[idx] <- sum(ri^2) / denom
  }

  out <- empty
  idx <- match(sub_judges, out$judge)
  out$severity[idx] <- severity
  out$se[idx] <- se
  out$infit[idx] <- infit
  out$outfit[idx] <- outfit
  out$estimable[idx] <- TRUE

  list(
    table = out,
    estimable = TRUE,
    n_judges_dropped = n_drop_j,
    n_items_dropped = n_drop_i,
    bias_correction = correction,
    reason = NA_character_
  )
}

# Descriptive rater effects computed on the full polytomous ratings, following
# the effects named in Engelhard (1994). Halo is deliberately not estimated
# here: with one rating per judge-item cell on a single dimension, halo is not
# separable from low differentiation.
.rater_effects <- function(X, lo, hi) {
  n_j <- nrow(X)
  judge_names <- rownames(X)
  if (is.null(judge_names)) judge_names <- paste0("Judge", seq_len(n_j))

  grand <- mean(X, na.rm = TRUE)
  judge_mean <- rowMeans(X, na.rm = TRUE)
  judge_sd <- apply(X, 1L, function(z) {
    z <- z[!is.na(z)]
    if (length(z) < 2L) NA_real_ else stats::sd(z)
  })

  typical_sd <- stats::median(judge_sd, na.rm = TRUE)
  differentiation <- if (is.na(typical_sd) || typical_sd <= 0) {
    rep(NA_real_, n_j)
  } else {
    judge_sd / typical_sd
  }

  # Middle categories are the scale points strictly inside the endpoints.
  middle_prop <- apply(X, 1L, function(z) {
    z <- z[!is.na(z)]
    if (!length(z)) return(NA_real_)
    mean(z > lo & z < hi)
  })
  extreme_prop <- apply(X, 1L, function(z) {
    z <- z[!is.na(z)]
    if (!length(z)) return(NA_real_)
    mean(z <= lo | z >= hi)
  })

  data.frame(
    judge = judge_names,
    n_ratings = as.integer(rowSums(!is.na(X))),
    mean_rating = judge_mean,
    sd_rating = judge_sd,
    # Signed so that positive means more severe, matching the logit severity
    # scale: a judge who rates lower than the panel is harsher.
    severity_raw = grand - judge_mean,
    differentiation = differentiation,
    central_prop = middle_prop,
    extreme_prop = extreme_prop,
    stringsAsFactors = FALSE
  )
}

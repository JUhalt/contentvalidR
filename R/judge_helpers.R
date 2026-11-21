# Internal helpers for judge/rater heterogeneity analysis.

# Iteratively drop judges and items whose endorsement rate is 0 or 1. Such
# elements carry no information about relative severity and produce infinite
# maximum-likelihood estimates (perfect separation). This is standard practice
# in Rasch estimation; the dropped elements are reported rather than hidden.
# Dropping one can leave another with no variation, or with no decision at
# all, so the rounds go on until none is left. A round that does not stop
# drops at least one judge or item, so the loop always ends.
.facets_trim_extremes <- function(B) {
  keep_j <- rep(TRUE, nrow(B))
  keep_i <- rep(TRUE, ncol(B))

  repeat {
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

# Whether the relevance decisions are separated, so that the facets model has
# no maximum-likelihood estimates (Albert & Anderson, 1984). Each decision is
# an arrow: from a judge to an item the judge endorsed, and from an item to a
# judge who rejected it. If some arrow lies on no closed loop, the judges and
# items it leads back from (those with a path to its tail) form a group whose
# judges endorsed every other item they rated and whose items every other
# judge rejected. Moving that group away from the rest (its judges more
# lenient, its items lower) fits those decisions better without bound. If every arrow lies on a loop, a move that fits no
# decision worse must move every judge and item on a loop together, so it
# changes no fitted value and no such group exists. With .facets_unlinked(),
# this asks that every judge and item reach every other along the arrows:
# the package's construction, for judges and items, of the condition
# Fischer (1981) gives for the Rasch model's estimates to exist. It uses no
# threshold. `B` holds 0, 1 or NA, with judges in rows.
.facets_separated <- function(B) {
  n_j <- nrow(B)
  n <- n_j + ncol(B)
  cell <- which(!is.na(B), arr.ind = TRUE)
  yes <- B[cell] == 1
  from <- ifelse(yes, cell[, 1], n_j + cell[, 2])
  to <- ifelse(yes, n_j + cell[, 2], cell[, 1])
  # Which judge or item has a path to which. Squaring the matrix doubles the
  # length of path it covers, until nothing changes.
  reach <- diag(n) > 0
  reach[cbind(from, to)] <- TRUE
  repeat {
    longer <- (reach %*% reach) > 0
    if (identical(longer, reach)) break
    reach <- longer
  }
  # An arrow lies on a loop when its head has a path back to its tail.
  !all(reach[cbind(to, from)])
}

# Whether the judges and items fall into groups that share no decision, as
# missing ratings can leave them. Nothing then places the severities of one
# group against those of another, so the model has no single scale for them
# (Fischer, 1981), and glm() would fix one judge in each group arbitrarily.
# `B` holds 0, 1 or NA, with judges in rows.
.facets_unlinked <- function(B) {
  n_j <- nrow(B)
  n <- n_j + ncol(B)
  cell <- which(!is.na(B), arr.ind = TRUE)
  link <- diag(n) > 0
  link[cbind(cell[, 1], n_j + cell[, 2])] <- TRUE
  link[cbind(n_j + cell[, 2], cell[, 1])] <- TRUE
  repeat {
    longer <- (link %*% link) > 0
    if (identical(longer, link)) break
    link <- longer
  }
  !all(link[1, ])
}

# Dichotomous many-facet Rasch model fitted as a logistic regression:
#   logit P(endorse) = item_effect - judge_severity
# The generalized linear model formulation of Rasch-family models follows
# De Boeck & Wilson (2004). Estimation is joint maximum likelihood, which
# stretches the judge severities by about J / (J - 1), J being the number of
# decisions behind each item parameter: the judges who rated the item. Wright
# and Douglas's (1977) correction, (L - 1) / L for the L items of a test taken
# by many persons, is applied with the judges in the place of the test items
# and the rated items in the place of the persons. With missing ratings J is
# the mean number of judges per item in the model; with complete ratings it is
# the number of judges in the model. Applying the correction to judges is this
# package's choice, and Wright (1988) notes that it is slightly inexact for
# very short tests, which a small panel is.
# `control` reaches glm(): judge_validity() leaves it at glm()'s default, and
# the tests use it to make glm() stop short, which otherwise happens only on
# some platforms (whether a long, nearly ordered set of decisions converges
# within 25 iterations depends on the floating-point arithmetic).
.facets_severity <- function(B, bias_correct = TRUE,
                             control = stats::glm.control()) {
  n_j <- nrow(B)
  judge_names <- rownames(B)
  # The model is built from the names, so defaults are set on the matrix too.
  if (is.null(judge_names)) {
    judge_names <- paste0("Judge", seq_len(n_j))
    rownames(B) <- judge_names
  }
  if (is.null(colnames(B))) colnames(B) <- paste0("Item", seq_len(ncol(B)))

  empty <- data.frame(
    judge = judge_names,
    severity = NA_real_,
    se = NA_real_,
    infit = NA_real_,
    outfit = NA_real_,
    # Decisions the model scored for this judge: what a fit mean square
    # rests on.
    n_scored = 0L,
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
        "Judge severity could not be estimated. After setting aside judges and",
        "items with no variation in endorsement, fewer than two judges and two",
        "items remained, usually because each judge endorsed either all of the",
        "remaining items or none of them. That happens when the panel agrees",
        "almost completely,",
        "or when the only disagreement is a judge who rejects every item the",
        "others accept. It describes the ratings rather than an estimation",
        "failure: a logit scale needs judges whose endorsements vary."
      )
    ))
  }

  if (.facets_unlinked(sub)) {
    return(list(
      table = empty, estimable = FALSE,
      n_judges_dropped = n_drop_j, n_items_dropped = n_drop_i,
      bias_correction = NA_real_,
      reason = paste(
        "Judge severity could not be estimated on the logit scale. The",
        "judges fall into groups that rated no item in common, so nothing",
        "places the severities of one group against those of another, and",
        "the model has no single scale for them (Fischer, 1981)."
      )
    ))
  }

  if (.facets_separated(sub)) {
    return(list(
      table = empty, estimable = FALSE,
      n_judges_dropped = n_drop_j, n_items_dropped = n_drop_i,
      bias_correction = NA_real_,
      reason = paste(
        "Judge severity could not be estimated on the logit scale. The",
        "relevance decisions split the judges and items into two groups: the",
        "judges of the first endorsed every item of the second that they",
        "rated, and the judges of the second rejected every item of the first",
        "that they rated. The farther apart the model places the two groups,",
        "the better it fits those decisions, so the maximum-likelihood",
        "estimates do not exist (Albert & Anderson, 1984)."
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
    suppressWarnings(stats::glm(y ~ item + judge, family = stats::binomial(),
                                data = long, control = control)),
    silent = TRUE
  )
  # The estimates exist here, but glm() can still stop short of them, as on
  # a long staircase of decisions with two of them flipped.
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
    # The count is the judges behind each item, not the number of items: see
    # the note above this function. With complete ratings it is exactly k.
    per_item <- colSums(!is.na(sub))
    j_bar <- if (all(per_item == k)) k else mean(per_item)
    if (j_bar > 1) correction <- (j_bar - 1) / j_bar
    severity <- severity * correction
    # The standard errors are stretched by about the square root of the same
    # factor (Linacre, n.d.).
    se <- se * sqrt(correction)
  }

  # Infit and outfit mean squares from standardized residuals.
  p <- stats::fitted(fit)
  resid <- long$y - p
  w <- p * (1 - p)
  infit <- rep(NA_real_, k)
  outfit <- rep(NA_real_, k)
  n_scored <- integer(k)
  for (idx in seq_len(k)) {
    # Trimming leaves every judge in the model with decisions of both kinds.
    sel <- long$judge == sub_judges[idx]
    n_scored[idx] <- sum(sel)
    wi <- w[sel]
    ri <- resid[sel]
    usable <- wi > .Machine$double.eps
    # Every fitted probability of this judge sits where the inverse link of
    # binomial() clamps it (a logit beyond 30), so no residual can be scaled.
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
  out$n_scored[idx] <- n_scored
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

  spread <- function(z) {
    z <- z[!is.na(z)]
    if (length(z) < 2L) NA_real_ else stats::sd(z)
  }
  judge_mean <- rowMeans(X, na.rm = TRUE)
  judge_mean[is.nan(judge_mean)] <- NA_real_
  judge_sd <- apply(X, 1L, spread)
  item_mean <- colMeans(X, na.rm = TRUE)

  # A judge is compared with the panel on the items that judge rated. With
  # complete ratings this is the grand mean less the judge's mean, and the
  # judge's spread over the median spread. With missing ratings, a judge who
  # rated only the low-rated items exactly as everyone else did is not made
  # to look severe, or undiscriminating, by the items they did not rate.
  severity_raw <- if (!anyNA(X)) {
    # The same quantity, computed as it always was, so that complete ratings
    # give bit-identical values and a judge at a cut stays on the same side.
    mean(X) - judge_mean
  } else {
    vapply(seq_len(n_j), function(j) {
      rated <- !is.na(X[j, ])
      if (!any(rated)) return(NA_real_)
      mean(item_mean[rated] - X[j, rated])
    }, numeric(1))
  }
  severity_raw <- unname(severity_raw)
  differentiation <- vapply(seq_len(n_j), function(j) {
    rated <- !is.na(X[j, ])
    if (is.na(judge_sd[j])) return(NA_real_)
    typical <- stats::median(apply(X[, rated, drop = FALSE], 1L, spread),
                             na.rm = TRUE)
    if (is.na(typical) || typical <= 0) NA_real_ else judge_sd[j] / typical
  }, numeric(1))

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
    severity_raw = severity_raw,
    differentiation = differentiation,
    central_prop = middle_prop,
    extreme_prop = extreme_prop,
    stringsAsFactors = FALSE
  )
}

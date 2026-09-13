.judge_item_status <- function(B) {
  # B: judges-by-items binary relevance matrix. Returns the item-level CVI
  # decision that a panel of this size would support.
  n <- colSums(!is.na(B))
  agree <- colSums(B, na.rm = TRUE)
  icvi <- ifelse(n > 0L, agree / n, NA_real_)
  crit <- .cvi_common_criterion(n)
  ifelse(is.na(crit) | is.na(icvi), NA_character_,
         ifelse(icvi >= crit, "Support", "Review"))
}

.judge_influence <- function(B) {
  n_j <- nrow(B)
  items <- colnames(B)
  full <- .judge_item_status(B)

  flipped <- vector("list", n_j)
  n_flipped <- integer(n_j)
  for (j in seq_len(n_j)) {
    drop_status <- .judge_item_status(B[-j, , drop = FALSE])
    changed <- which(
      (is.na(full) != is.na(drop_status)) |
        (!is.na(full) & !is.na(drop_status) & full != drop_status)
    )
    flipped[[j]] <- items[changed]
    n_flipped[j] <- length(changed)
  }

  fragile <- rep(FALSE, length(items))
  for (j in seq_len(n_j)) fragile[items %in% flipped[[j]]] <- TRUE

  list(
    n_flipped = n_flipped,
    flipped_items = vapply(
      flipped,
      function(z) if (!length(z)) NA_character_ else paste(z, collapse = ", "),
      character(1)
    ),
    item_table = data.frame(
      item = items,
      status_full_panel = full,
      fragile = fragile,
      stringsAsFactors = FALSE
    )
  )
}

#' Analyze judge and rater heterogeneity in content-validity ratings
#'
#' @description
#' Examines whether content-validity conclusions depend on the particular judges
#' who happened to serve on the panel, rather than reporting only aggregate
#' indices that average heterogeneity away.
#'
#' The workflow reports four complementary kinds of evidence:
#'
#' * **Generalizability.** How dependably the panel's ratings would reproduce
#'   with a different panel of the same size, via [gtheory_content()].
#' * **Severity.** How harsh or lenient each judge is relative to the panel,
#'   both in raw rating units and, where estimable, on a logit scale from a
#'   many-facet Rasch model fitted as a logistic regression.
#' * **Response style.** How much each judge differentiates among items, and how
#'   much they concentrate on middle or extreme categories.
#' * **Influence.** Which items would change their CVI-based review status if any
#'   single judge were removed from the panel.
#'
#' A judge flagged for `Review` is not a judge to discard. Disagreement may be
#' substantive expertise rather than error, and removing inconvenient judges is
#' not a validity procedure. The flag identifies where a conclusion rests on one
#' person's ratings and therefore deserves a closer look.
#'
#' @param ratings A judges-by-items numeric matrix or data frame of relevance
#'   ratings: one row per judge, one column per item.
#' @param lo,hi Rating-scale bounds.
#' @param relevance_cut Lowest rating treated as relevant. Defaults to `hi - 1`.
#' @param na.rm Permit missing ratings. Generalizability analysis additionally
#'   requires complete cases and drops incomplete judges, reporting how many.
#' @param bias_correct Apply the Wright-Douglas joint-maximum-likelihood bias
#'   correction to logit severity estimates. See the estimation note below.
#' @param severity_cut Absolute logit severity beyond which a judge is flagged
#'   for review.
#' @param severity_raw_cut Absolute severity in rating points beyond which a
#'   judge is flagged when logit severity is not estimable. Defaults to a
#'   quarter of the scale range. Severity is signed so that positive values
#'   mean the judge rates lower than the panel.
#' @param fit_range Length-2 vector giving the acceptable infit/outfit mean
#'   square range. Values outside it flag erratic or overly predictable judges.
#'
#' @return An object of class `contentvalid_judge` and `contentvalid_workflow`.
#'   Unlike the item-oriented workflows, `results` has **one row per judge**.
#'   `scale_summary` describes the panel, and `details` contains the
#'   generalizability analysis, the facets model, raw rater effects, and the
#'   item-level influence table.
#'
#' @section Estimation note:
#' Logit severity comes from a many-facet Rasch model fitted by joint maximum
#' likelihood as a logistic regression, the generalized linear model
#' formulation described by de Boeck and Wilson (2004). Joint maximum
#' likelihood is known to over-disperse facet estimates in small designs. The
#' standard Wright-Douglas `(L-1)/L` correction is applied by default and
#' reported in `settings$bias_correction`, but it reduces rather than removes
#' that bias. Where precise severity calibration matters, marginal maximum
#' likelihood estimation is preferable, and the raw rating-unit severity in
#' `severity_raw` is free of this particular issue.
#'
#' Severity is estimated from the dichotomized relevance decision, consistent
#' with how the package computes CVI. Judges and items showing no variation in
#' that decision carry no information about relative severity and are excluded
#' from the model, which is reported rather than silent.
#'
#' @references
#' Crocker, L., Llabre, M., & Miller, M. D. (1988). The generalizability of
#' content validity ratings. *Journal of Educational Measurement, 25*(4),
#' 287-299. \doi{10.1111/j.1745-3984.1988.tb00309.x}
#'
#' Engelhard, G. (1994). Examining rater errors in the assessment of written
#' composition with a many-faceted Rasch model. *Journal of Educational
#' Measurement, 31*(2), 93-112. \doi{10.1111/j.1745-3984.1994.tb00436.x}
#'
#' Linacre, J. M. (1989). *Many-Facet Rasch Measurement.* MESA Press.
#'
#' de Boeck, P., & Wilson, M. (2004). *Explanatory Item Response Models: A
#' Generalized Linear and Nonlinear Approach.* Springer.
#'
#' @seealso [gtheory_content()] for the generalizability analysis alone,
#'   [expert_validity()] for the item-level expert-panel workflow.
#'
#' @examples
#' ratings <- rbind(
#'   c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
#'   c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(4, 3, 4, 3, 1, 2),
#'   c(4, 4, 3, 4, 2, 2), c(2, 2, 2, 2, 1, 1)
#' )
#' dimnames(ratings) <- list(paste0("Judge", 1:8), paste0("Item", 1:6))
#' fit <- judge_validity(ratings, lo = 1, hi = 4)
#' fit
#' summary(fit)
#' @export
judge_validity <- function(ratings,
                           lo = 1,
                           hi = 4,
                           relevance_cut = NULL,
                           na.rm = FALSE,
                           bias_correct = TRUE,
                           severity_cut = 1,
                           severity_raw_cut = NULL,
                           fit_range = c(0.5, 1.5)) {
  .validate_flag(na.rm, "na.rm")
  .validate_flag(bias_correct, "bias_correct")

  if (!is.numeric(lo) || length(lo) != 1L || !is.finite(lo) ||
      !is.numeric(hi) || length(hi) != 1L || !is.finite(hi) || hi <= lo) {
    stop("`lo` and `hi` must be finite scalars with `hi > lo`.", call. = FALSE)
  }
  if (is.null(relevance_cut)) relevance_cut <- hi - 1
  if (!is.numeric(relevance_cut) || length(relevance_cut) != 1L ||
      !is.finite(relevance_cut) || relevance_cut < lo || relevance_cut > hi) {
    stop("`relevance_cut` must lie within the rating scale.", call. = FALSE)
  }
  if (!is.numeric(severity_cut) || length(severity_cut) != 1L ||
      !is.finite(severity_cut) || severity_cut <= 0) {
    stop("`severity_cut` must be one positive number.", call. = FALSE)
  }
  if (is.null(severity_raw_cut)) severity_raw_cut <- 0.25 * (hi - lo)
  if (!is.numeric(severity_raw_cut) || length(severity_raw_cut) != 1L ||
      !is.finite(severity_raw_cut) || severity_raw_cut <= 0) {
    stop("`severity_raw_cut` must be one positive number.", call. = FALSE)
  }
  if (!is.numeric(fit_range) || length(fit_range) != 2L || anyNA(fit_range) ||
      any(!is.finite(fit_range)) || fit_range[1] <= 0 || fit_range[2] <= fit_range[1]) {
    stop("`fit_range` must be two increasing positive numbers.", call. = FALSE)
  }

  X <- as.matrix(ratings)
  if (!is.numeric(X)) stop("`ratings` must be numeric.", call. = FALSE)
  if (any(is.infinite(X))) stop("`ratings` cannot contain infinite values.", call. = FALSE)
  if (!na.rm && anyNA(X)) {
    stop("`ratings` contains missing values; set `na.rm = TRUE` to allow them.",
         call. = FALSE)
  }
  outside <- !is.na(X) & (X < lo | X > hi)
  if (any(outside)) {
    stop("`ratings` contains values outside the [lo, hi] scale bounds.", call. = FALSE)
  }
  if (is.null(rownames(X))) rownames(X) <- paste0("Judge", seq_len(nrow(X)))
  if (is.null(colnames(X))) colnames(X) <- paste0("Item", seq_len(ncol(X)))

  n_judges <- nrow(X)
  n_items <- ncol(X)

  B <- ifelse(is.na(X), NA_real_, as.numeric(X >= relevance_cut))
  dim(B) <- dim(X)
  dimnames(B) <- dimnames(X)

  effects <- .rater_effects(X, lo = lo, hi = hi)
  facets <- .facets_severity(B, bias_correct = bias_correct)
  influence <- if (n_judges >= 3L) {
    .judge_influence(B)
  } else {
    list(n_flipped = rep(NA_integer_, n_judges),
         flipped_items = rep(NA_character_, n_judges),
         item_table = data.frame(item = colnames(X),
                                 status_full_panel = .judge_item_status(B),
                                 fragile = NA, stringsAsFactors = FALSE))
  }
  gt <- gtheory_content(X, na.rm = TRUE)

  res <- effects
  res$severity <- facets$table$severity
  res$se <- facets$table$se
  res$infit <- facets$table$infit
  res$outfit <- facets$table$outfit
  res$severity_estimable <- facets$table$estimable
  res$n_items_flipped <- influence$n_flipped
  res$flipped_items <- influence$flipped_items

  # Logit severity is unavailable whenever the panel agrees almost completely,
  # which is common in relevance ratings. Fall back to rating-unit severity so
  # a plainly harsh or lenient judge is still flagged.
  too_severe <- ifelse(
    !is.na(res$severity),
    abs(res$severity) > severity_cut,
    !is.na(res$severity_raw) & abs(res$severity_raw) > severity_raw_cut
  )
  severity_shown <- ifelse(!is.na(res$severity), res$severity, res$severity_raw)
  severity_units <- ifelse(!is.na(res$severity), "logit", "rating points")
  misfit <- (!is.na(res$outfit) & (res$outfit < fit_range[1] | res$outfit > fit_range[2])) |
    (!is.na(res$infit) & (res$infit < fit_range[1] | res$infit > fit_range[2]))
  influential <- !is.na(res$n_items_flipped) & res$n_items_flipped > 0L
  low_diff <- !is.na(res$differentiation) & res$differentiation < 0.5
  insufficient <- res$n_ratings < 2L

  res$recommendation <- ifelse(
    insufficient, "Insufficient data",
    ifelse(influential, "Influential",
           ifelse(misfit, "Erratic",
                  ifelse(too_severe,
                         ifelse(severity_shown > 0, "Severe", "Lenient"),
                         ifelse(low_diff, "Low differentiation", "Typical")))))

  res$status <- ifelse(
    insufficient, "Insufficient data",
    ifelse(influential | misfit | too_severe | low_diff, "Review", "Supported")
  )

  res$interpretation <- vapply(seq_len(nrow(res)), function(i) {
    if (insufficient[i]) {
      return("This judge supplied fewer than two usable ratings, so no heterogeneity evidence can be computed for them.")
    }
    if (influential[i]) {
      return(sprintf(paste(
        "Removing this judge would change the review status of %d item(s): %s.",
        "The panel's conclusion about those items rests on this one judge.",
        "Read their ratings and any written comments before treating those",
        "items as settled. Note that removing a judge also reduces the panel",
        "size, which can itself change the CVI criterion."
      ), res$n_items_flipped[i], res$flipped_items[i]))
    }
    if (misfit[i]) {
      return(paste(
        "This judge's endorsement pattern fits the model poorly. High values",
        "indicate ratings that are erratic given the rest of the panel; low",
        "values indicate ratings that are more predictable than expected.",
        "Check whether they interpreted the construct definition differently."
      ))
    }
    if (too_severe[i]) {
      return(sprintf(paste(
        "This judge is markedly %s than the panel (%.2f %s relative to the",
        "panel mean). Consistent severity does not invalidate their ratings,",
        "but it shifts absolute indices such as CVI, which is why the",
        "dependability coefficient is penalized by judge differences."
      ), if (severity_shown[i] > 0) "more severe" else "more lenient",
         severity_shown[i], severity_units[i]))
    }
    if (low_diff[i]) {
      return(paste(
        "This judge used a narrower range of the scale than the rest of the",
        "panel, so their ratings distinguish less among items. This may reflect",
        "a genuine view that the items are similar, or reluctance to use the",
        "full scale."
      ))
    }
    "This judge's severity, scale use, and fit are consistent with the rest of the panel, and no item's review status depends on them."
  }, character(1))

  res <- res[c("judge", "n_ratings", "mean_rating", "sd_rating", "severity_raw",
               "severity", "se", "infit", "outfit", "severity_estimable",
               "differentiation", "central_prop", "extreme_prop",
               "n_items_flipped", "flipped_items",
               "recommendation", "status", "interpretation")]
  rownames(res) <- NULL

  vc <- gt$variance_components
  judge_pct <- vc$percent[vc$source == "judge"]

  scale_summary <- data.frame(
    n_judges = n_judges,
    n_items = n_items,
    g_coefficient = gt$coefficients$g_coefficient,
    phi_coefficient = gt$coefficients$phi_coefficient,
    judge_variance_pct = if (length(judge_pct)) judge_pct else NA_real_,
    n_typical = sum(res$status == "Supported", na.rm = TRUE),
    n_review = sum(res$status == "Review", na.rm = TRUE),
    n_influential = sum(influential, na.rm = TRUE),
    n_fragile_items = sum(influence$item_table$fragile, na.rm = TRUE),
    severity_estimable = facets$estimable,
    stringsAsFactors = FALSE
  )

  settings <- list(
    method = "Generalizability analysis, joint-ML facets severity, and leave-one-judge-out influence",
    lo = lo, hi = hi, relevance_cut = relevance_cut,
    na.rm = isTRUE(na.rm),
    bias_correct = isTRUE(bias_correct),
    bias_correction = facets$bias_correction,
    severity_cut = severity_cut,
    fit_range = fit_range,
    severity_scale = "logit (dichotomized relevance decision)"
  )
  design <- list(
    type = "judge heterogeneity (judges x items)",
    n_items = n_items,
    n_judges = n_judges,
    n_judges_min = min(colSums(!is.na(X))),
    n_judges_max = max(colSums(!is.na(X))),
    n_missing = sum(is.na(X)),
    n_judges_not_estimable = sum(!facets$table$estimable),
    n_items_dropped_from_model = facets$n_items_dropped,
    gtheory_judges_dropped = gt$design$n_judges_dropped
  )

  .new_contentvalid_workflow(
    subclass = "contentvalid_judge",
    workflow = "judge-heterogeneity",
    results = res,
    scale_summary = scale_summary,
    settings = settings,
    design = design,
    details = list(
      gtheory = gt,
      facets = facets,
      rater_effects = effects,
      influence_items = influence$item_table,
      severity_note = facets$reason
    )
  )
}

#' @export
print.contentvalid_judge <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  s <- x$scale_summary
  cat("Judge and rater heterogeneity\n")
  cat(sprintf("Judges: %d   Items: %d\n", s$n_judges, s$n_items))
  cat(sprintf("Dependability (Phi): %s   Judge share of variance: %s%%\n",
              format(round(s$phi_coefficient, digits)),
              format(round(s$judge_variance_pct, 1))))

  cat("\nJudges\n")
  estimable <- isTRUE(s$severity_estimable)
  cols <- c("judge", "mean_rating", "severity_raw")
  if (estimable) cols <- c(cols, "severity", "outfit")
  cols <- c(cols, "differentiation", "n_items_flipped", "status")
  show <- x$results[cols]
  names(show)[names(show) == "severity_raw"] <- "severity(pts)"
  if (estimable) names(show)[names(show) == "severity"] <- "severity(logit)"
  num <- vapply(show, is.numeric, logical(1))
  show[num] <- lapply(show[num], round, digits)
  print(show, row.names = FALSE)
  cat("Positive severity means the judge rates lower than the panel.\n")

  if (!estimable) {
    cat("\nLogit severity not estimated:\n")
    cat(strwrap(x$details$severity_note, width = 76), sep = "\n")
    cat(strwrap(paste(
      "Severity in rating points is reported instead and is used for flagging."
    ), width = 76), sep = "\n")
  }

  if (isTRUE(s$n_fragile_items > 0L)) {
    fragile <- x$details$influence_items
    cat(sprintf("\n%d item(s) change review status if a single judge is removed: %s\n",
                s$n_fragile_items,
                paste(fragile$item[fragile$fragile %in% TRUE], collapse = ", ")))
  } else if (s$n_judges >= 3L) {
    cat("\nNo item's review status depends on any single judge.\n")
  }

  cat("\nA `Review` judge is not a judge to remove. Disagreement can be",
      "\nsubstantive expertise; the flag marks where a conclusion rests on",
      "\none person's ratings.\n")
  invisible(x)
}

#' @export
summary.contentvalid_judge <- function(object, ...) {
  core <- .workflow_summary_core(object)
  core$n_judges <- object$design$n_judges
  core$severity_estimable <- object$scale_summary$severity_estimable
  core$severity_note <- object$details$severity_note
  core$gtheory <- object$details$gtheory
  core$influence_items <- object$details$influence_items
  core$reviewed_judges <- object$results[object$results$status == "Review", , drop = FALSE]
  class(core) <- "summary.contentvalid_judge"
  core
}

#' @export
print.summary.contentvalid_judge <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  cat("Summary: judge and rater heterogeneity\n")
  cat(sprintf("Judges: %d   Items: %d\n", x$n_judges, x$n_items))
  cat(sprintf("Consistent with panel: %d   Flagged for review: %d   Insufficient: %d\n",
              x$n_supported, x$n_review, x$n_insufficient))

  cat("\nGeneralizability\n")
  gt <- x$gtheory
  cat(sprintf("  Dependability (absolute decisions): %s\n",
              format(round(gt$coefficients$phi_coefficient, 3))))
  cat(sprintf("  Generalizability (rank ordering):   %s\n",
              format(round(gt$coefficients$g_coefficient, 3))))
  if (nrow(gt$judges_needed)) {
    cat("  Judges needed by target:\n")
    print(gt$judges_needed, row.names = FALSE)
  }

  if (nrow(x$reviewed_judges)) {
    cat("\nJudges flagged for review\n")
    for (i in seq_len(nrow(x$reviewed_judges))) {
      row <- x$reviewed_judges[i, ]
      cat(sprintf("\n  %s  (%s)\n", row$judge, row$recommendation))
      cat(strwrap(row$interpretation, width = 72, prefix = "    "), sep = "\n")
    }
  } else {
    cat("\nNo judge was flagged for review.\n")
  }

  fragile <- x$influence_items
  if (is.data.frame(fragile) && any(fragile$fragile %in% TRUE)) {
    cat("\nItems whose review status depends on a single judge\n")
    print(fragile[fragile$fragile %in% TRUE, c("item", "status_full_panel")],
          row.names = FALSE)
  }

  cat("\nThis analysis describes how much conclusions depend on these judges.",
      "\nIt does not establish that the items cover the intended content domain.\n")
  invisible(x)
}

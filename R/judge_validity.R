.judge_item_status <- function(B) {
  # B: judges-by-items binary relevance matrix. Returns the item-level CVI
  # decision that a panel of this size would support.
  n <- colSums(!is.na(B))
  agree <- colSums(B, na.rm = TRUE)
  req <- .cvi_required_count(n)
  ifelse(is.na(req) | n == 0L, NA_character_,
         ifelse(agree >= req, "Support", "Review"))
}

# Which items change their CVI decision when one judge is removed. This is a
# fact about the item: it is one judge from the other side of the criterion
# for its panel size (at the criterion, or one short of it). It is
# reported item by item, and no judge is flagged for it, because every judge
# on the deciding side of such an item "changes" it alike.
#
# The comparison needs a criterion on both sides. Lynn's (1986) table starts
# at three experts, so an item rated by three or fewer judges cannot be
# checked: one fewer leaves no criterion. That is "not checked" (NA), never a
# change.
.judge_influence <- function(B) {
  n_j <- nrow(B)
  items <- colnames(B)
  judges <- rownames(B)
  full <- .judge_item_status(B)
  n_raters <- colSums(!is.na(B))
  n_relevant <- colSums(B, na.rm = TRUE)

  flips <- matrix(NA, nrow = n_j, ncol = length(items))
  for (j in seq_len(n_j)) {
    drop_status <- .judge_item_status(B[-j, , drop = FALSE])
    both <- !is.na(full) & !is.na(drop_status)
    flips[j, both] <- full[both] != drop_status[both]
  }

  checked <- colSums(is.na(flips)) == 0L & n_j > 0L
  fragile <- ifelse(checked, colSums(flips, na.rm = TRUE) > 0L, NA)
  without <- vapply(seq_along(items), function(i) {
    if (!isTRUE(fragile[i])) return(NA_character_)
    paste(judges[flips[, i] %in% TRUE], collapse = ", ")
  }, character(1))

  any_checked <- rowSums(!is.na(flips)) > 0L
  n_flipped <- ifelse(any_checked, rowSums(flips, na.rm = TRUE), NA)
  flipped_items <- vapply(seq_len(n_j), function(j) {
    z <- items[flips[j, ] %in% TRUE]
    if (!length(z)) NA_character_ else paste(z, collapse = ", ")
  }, character(1))

  list(
    n_flipped = as.integer(n_flipped),
    flipped_items = flipped_items,
    item_table = data.frame(
      item = items,
      n_raters = as.integer(n_raters),
      n_relevant = as.integer(n_relevant),
      status_full_panel = full,
      fragile = fragile,
      changes_without = without,
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
#'   with a different panel of the same size, via [gtheory_content()], the
#'   analysis Crocker et al. (1988) applied to content-validity ratings.
#' * **Severity.** How harsh or lenient each judge is relative to the panel,
#'   both in raw rating units and, where estimable, on a logit scale from a
#'   many-facet Rasch model (Linacre, 1989) fitted as a logistic regression.
#' * **Response style.** How much each judge differentiates among items, and how
#'   much they concentrate on middle or extreme categories, two of the rater
#'   effects Engelhard (1994) describes.
#' * **Fragile items.** Which items would change their CVI-based review status
#'   (Lynn, 1986) if any single judge were removed from the panel.
#'
#' A judge flagged for `Review` is not a judge to discard. Disagreement may be
#' substantive expertise rather than error, and removing inconvenient judges is
#' not a validity procedure. The flag marks a judge whose ratings deserve a
#' closer look.
#'
#' @param ratings A judges-by-items numeric matrix or data frame of relevance
#'   ratings: one row per judge, one column per item. A column whose name
#'   looks like a rater ID (such as `expert` or `rater_id`) stops the
#'   function, so remove it, or rename an item that has such a name. Judge
#'   names (row names) and item names must be unique.
#' @param lo,hi Rating-scale bounds.
#' @param relevance_cut Lowest rating treated as relevant. Defaults to
#'   `hi - 1`, and to `hi` on a two-point scale. It must lie above `lo`: at
#'   `lo` every rating would count as relevant.
#' @param na.rm Permit missing ratings. Each judge is then compared with the
#'   panel on the items that judge rated. Generalizability analysis
#'   additionally requires complete cases and drops incomplete judges; the
#'   printout says how many.
#' @param bias_correct Apply the Wright-Douglas joint-maximum-likelihood bias
#'   correction to logit severity estimates. See the estimation note below.
#' @param severity_cut Absolute logit severity beyond which a judge is flagged
#'   for review.
#' @param severity_raw_cut Absolute severity in rating points beyond which a
#'   judge is flagged when logit severity is not estimable. Defaults to a
#'   quarter of the scale range. Severity is signed so that positive values
#'   mean the judge rates lower than the panel.
#' @param fit_range Length-2 vector giving the infit/outfit mean-square range
#'   read as acceptable. The default, 0.5 to 1.5, is the range Linacre (2002)
#'   calls productive for measurement. A judge above it is flagged as erratic
#'   when `fit_min_ratings` is met. A judge below it is described, not
#'   flagged.
#' @param fit_min_ratings Fewest decisions the facets model must have scored
#'   for a judge before a fit flag is raised. Default 30.
#' @param differentiation_cut Scale use below which a judge is flagged for low
#'   differentiation. Scale use is the judge's standard deviation over the
#'   median judge's. Default 0.5.
#'
#' @return An object of class `contentvalid_judge` and `contentvalid_workflow`.
#'   Unlike the item-oriented workflows, `results` has **one row per judge**.
#'   `scale_summary` describes the panel, and `details` contains the
#'   generalizability analysis, the facets model, raw rater effects, and
#'   `influence_items`, the item-level table of fragile items: for each item
#'   its number of raters, the number who rated it relevant, its status with
#'   the full panel, whether that status changes when one judge is removed
#'   (`fragile`; `NA` when it could not be checked), and the judges whose
#'   removal changes it. In `results`, `n_items_flipped` and `flipped_items`
#'   give the same information by judge; they describe the items and are not
#'   a flag.
#'
#' @section What is published and what is this package's choice:
#' The generalizability analysis, the many-facet Rasch model, the infit and
#' outfit mean squares and the rater effects are published methods, cited
#' above. These parts are contentvalidR conventions, with no published
#' standard behind the numbers:
#'
#' * The cuts that flag a judge: `severity_cut` (1 logit),
#'   `severity_raw_cut` (a quarter of the scale range) and
#'   `differentiation_cut` (0.5). The scale-use ratio itself is this
#'   package's index of the differentiation Engelhard (1994) describes.
#' * Using Linacre's (2002) 0.5 to 1.5 range as a flag. He offers it as a
#'   guide to how productive data are for measurement: below 0.5 is "less
#'   productive for measurement, but not degrading", 1.5 to 2.0 is
#'   "unproductive for construction of measurement, but not degrading", and
#'   only above 2.0 does misfit distort the measurement. The package flags
#'   above 1.5 and never below 0.5 because a high mean square means noise in
#'   a judge's decisions, which bears on whether to trust them, while a low
#'   one means decisions more predictable than the model expects. A mean square from
#'   a handful of yes-or-no decisions varies widely by chance even for a
#'   judge who fits the model exactly, so a judge above the range is flagged
#'   only when the model scored at least `fit_min_ratings` of their
#'   decisions. Thirty follows the guidance in the Facets documentation
#'   (Linacre, n.d.) that stable estimates need at least 30 observations per
#'   element. With the item counts usual in content validation the fit
#'   statistics are therefore shown and not flagged.
#' * The fragile-item check. It reapplies Lynn's (1986) criterion with one
#'   judge removed. An item one judge away from the other side of the
#'   criterion for its panel size (at the criterion, or one short of it,
#'   depending on the size) changes status when any judge on one side is
#'   removed, so the check describes the item and flags no judge. An item
#'   rated by three or fewer judges is not checked, because one fewer leaves
#'   no criterion.
#' * Applying the Wright-Douglas correction to judges (see the estimation
#'   note).
#'
#' @section Estimation note:
#' Logit severity comes from a many-facet Rasch model fitted by joint maximum
#' likelihood as a logistic regression, the generalized linear model
#' formulation described by De Boeck and Wilson (2004). Joint maximum
#' likelihood stretches estimates. Wright and Douglas (1977) found that
#' multiplying item difficulties by `(L - 1) / L`, with `L` the number of
#' items in the test, approximately removes the bias (see also Wright, 1988).
#' Here the judges stand where the test items do, and the rated items where
#' the persons do, so the package multiplies the severities by
#' `(J - 1) / J`, with `J` the number of judges who rated each item in the
#' model (with missing ratings, the mean of that number over the items), and
#' the standard errors by its square root, as the Facets documentation
#' describes for the standard errors (Linacre, n.d.). That application to
#' judges is this package's choice. The factor is reported in
#' `settings$bias_correction`. Versions before 1.0 counted items instead,
#' which left most of the bias in place on a small panel. The correction is
#' approximate: Wright and Douglas recommended it for tests of more than 20
#' items, and Wright (1988) notes that it is slightly inexact for very short
#' tests, which is what a panel of a few judges amounts to. With two or
#' three judges no single factor is trustworthy. Where precise severity
#' calibration matters,
#' marginal maximum likelihood estimation is preferable, and the raw
#' rating-unit severity in `severity_raw` is free of this particular issue.
#'
#' Severity is estimated from the dichotomized relevance decision, consistent
#' with how the package computes CVI. Judges and items showing no variation in
#' that decision carry no information about relative severity and are excluded
#' from the model, which is reported rather than silent.
#'
#' @references
#' Crocker, L., Llabre, M., & Miller, M. D. (1988). The generalizability of
#' content validity ratings. *Journal of Educational Measurement, 25*(4),
#' 287–299. \doi{10.1111/j.1745-3984.1988.tb00309.x}
#'
#' De Boeck, P., & Wilson, M. (Eds.). (2004). *Explanatory item response models:
#' A generalized linear and nonlinear approach*. Springer.
#' \doi{10.1007/978-1-4757-3990-9}
#'
#' Engelhard, G. (1994). Examining rater errors in the assessment of written
#' composition with a many-faceted Rasch model. *Journal of Educational
#' Measurement, 31*(2), 93–112. \doi{10.1111/j.1745-3984.1994.tb00436.x}
#'
#' Linacre, J. M. (n.d.). *Estimation considerations: JMLE estimation bias*
#' \[Facets help\]. Winsteps.com. Retrieved October 2, 2026, from
#' <https://www.winsteps.com/facetman/estimationconsiderations.htm>
#'
#' Linacre, J. M. (1989). *Many-facet Rasch measurement*. MESA Press.
#'
#' Linacre, J. M. (2002). What do infit and outfit, mean-square and
#' standardized mean? *Rasch Measurement Transactions, 16*(2), 878.
#' <https://www.rasch.org/rmt/rmt162f.htm>
#'
#' Lynn, M. R. (1986). Determination and quantification of content validity.
#' *Nursing Research, 35*(6), 382–385.
#' \doi{10.1097/00006199-198611000-00017}
#'
#' Wright, B. D. (1988). The efficacy of unconditional maximum likelihood bias
#' correction: Comment on Jansen, van den Wollenberg, and Wierda. *Applied
#' Psychological Measurement, 12*(3), 315–318.
#' \doi{10.1177/014662168801200309}
#'
#' Wright, B. D., & Douglas, G. A. (1977). Best procedures for sample-free
#' item analysis. *Applied Psychological Measurement, 1*(2), 281–295.
#' \doi{10.1177/014662167700100216}
#'
#' @seealso [gtheory_content()] for the generalizability analysis alone,
#'   [expert_validity()] for the item-level expert-panel workflow.
#'
#' @examples
#' # Eight judges rate ten items for relevance on a 1-4 scale. Judge8 rates
#' # lower than the rest, and Item4 is one judge short of the CVI criterion.
#' ratings <- rbind(
#'   c(4, 4, 3, 4, 3, 2, 3, 2, 4, 3), c(4, 3, 4, 3, 2, 3, 2, 3, 4, 2),
#'   c(3, 4, 4, 3, 3, 2, 2, 2, 3, 3), c(4, 4, 3, 2, 3, 3, 3, 1, 4, 2),
#'   c(4, 3, 3, 4, 2, 2, 3, 2, 3, 3), c(3, 4, 4, 3, 3, 3, 2, 3, 4, 1),
#'   c(4, 4, 4, 4, 3, 2, 3, 2, 4, 3), c(3, 2, 3, 2, 2, 1, 2, 1, 2, 2)
#' )
#' dimnames(ratings) <- list(paste0("Judge", 1:8), paste0("Item", 1:10))
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
                           fit_range = c(0.5, 1.5),
                           fit_min_ratings = 30,
                           differentiation_cut = 0.5) {
  .validate_flag(na.rm, "na.rm")
  .validate_flag(bias_correct, "bias_correct")

  if (!is.numeric(lo) || length(lo) != 1L || !is.finite(lo) ||
      !is.numeric(hi) || length(hi) != 1L || !is.finite(hi) || hi <= lo) {
    stop("`lo` and `hi` must be finite scalars with `hi > lo`.", call. = FALSE)
  }
  if (is.null(relevance_cut)) relevance_cut <- .default_cut(lo, hi)
  .validate_cut(relevance_cut, lo, hi, "relevance_cut")
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
  if (!is.numeric(fit_min_ratings) || length(fit_min_ratings) != 1L ||
      !is.finite(fit_min_ratings) || fit_min_ratings < 1 ||
      fit_min_ratings != floor(fit_min_ratings)) {
    stop("`fit_min_ratings` must be one positive integer.", call. = FALSE)
  }
  if (!is.numeric(differentiation_cut) || length(differentiation_cut) != 1L ||
      !is.finite(differentiation_cut) || differentiation_cut <= 0) {
    stop("`differentiation_cut` must be one positive number.", call. = FALSE)
  }

  .check_no_id_column(ratings, "ratings")
  X <- as.matrix(ratings)
  # Checked first: an empty data frame becomes a logical matrix.
  if (!nrow(X) || !ncol(X)) {
    stop("`ratings` must have at least one judge (row) and one item (column).",
         call. = FALSE)
  }
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
  .check_unique_names(rownames(X), "judge", "row")
  .check_unique_names(colnames(X), "item", "column")

  n_judges <- nrow(X)
  n_items <- ncol(X)

  B <- ifelse(is.na(X), NA_real_, as.numeric(X >= relevance_cut))
  dim(B) <- dim(X)
  dimnames(B) <- dimnames(X)

  effects <- .rater_effects(X, lo = lo, hi = hi)
  facets <- .facets_severity(B, bias_correct = bias_correct)
  influence <- .judge_influence(B)
  gt <- gtheory_content(X, na.rm = TRUE)

  res <- effects
  res$severity <- facets$table$severity
  res$se <- facets$table$se
  res$infit <- facets$table$infit
  res$outfit <- facets$table$outfit
  res$n_scored <- facets$table$n_scored
  res$severity_estimable <- facets$table$estimable
  res$n_items_flipped <- influence$n_flipped
  res$flipped_items <- influence$flipped_items

  # Logit severity is unavailable whenever the panel agrees almost completely,
  # which is common in relevance ratings. Fall back to rating-unit severity so
  # a plainly harsh or lenient judge is still flagged.
  # A judge exactly at a cut is not beyond it, whatever the last bit of the
  # arithmetic says.
  tol <- sqrt(.Machine$double.eps)
  too_severe <- ifelse(
    !is.na(res$severity),
    abs(res$severity) > severity_cut + tol,
    !is.na(res$severity_raw) & abs(res$severity_raw) > severity_raw_cut + tol
  )
  severity_shown <- ifelse(!is.na(res$severity), res$severity, res$severity_raw)
  severity_units <- ifelse(!is.na(res$severity), "logit", "rating points")
  # Above the range the decisions are noisier than the model expects; below it
  # they are more predictable. Only the first is a flag, and only when the
  # mean square rests on enough decisions to mean something.
  over_fit_range <- (!is.na(res$outfit) & res$outfit > fit_range[2]) |
    (!is.na(res$infit) & res$infit > fit_range[2])
  under_fit_range <- !over_fit_range &
    ((!is.na(res$outfit) & res$outfit < fit_range[1]) |
       (!is.na(res$infit) & res$infit < fit_range[1]))
  enough_for_fit <- res$n_scored >= fit_min_ratings
  erratic <- over_fit_range & enough_for_fit
  low_diff <- !is.na(res$differentiation) &
    res$differentiation < differentiation_cut - tol
  # One judge has no panel to be compared with.
  insufficient <- res$n_ratings < 2L | n_judges < 2L

  res$recommendation <- ifelse(
    insufficient, "Insufficient data",
    ifelse(erratic, "Erratic",
           ifelse(too_severe,
                  ifelse(severity_shown > 0, "Severe", "Lenient"),
                  ifelse(low_diff, "Low differentiation", "Typical"))))

  res$status <- ifelse(
    insufficient, "Insufficient data",
    ifelse(erratic | too_severe | low_diff, "Review", "Supported")
  )

  res$interpretation <- vapply(seq_len(nrow(res)), function(i) {
    if (insufficient[i]) {
      if (n_judges < 2L) {
        return("There is only one judge, so there is no panel to compare them with.")
      }
      return("This judge supplied fewer than two usable ratings, so no heterogeneity evidence can be computed for them.")
    }
    # A mean square outside the range that is not a flag is still described.
    fit_note <- if (over_fit_range[i] && !erratic[i]) {
      sprintf(paste(
        " Their infit or outfit is above %s, but it rests on %s, too few for",
        "a fit flag (`fit_min_ratings` is %d): a mean square from so few",
        "decisions varies widely by chance."
      ), format(fit_range[2]), .n_noun(res$n_scored[i], "scored decision"),
         as.integer(fit_min_ratings))
    } else if (under_fit_range[i]) {
      paste0(sprintf(paste(
        " Their infit or outfit is below %s: their decisions follow the",
        "panel's ordering of the items more closely than the model expects,",
        "which is not a flag."
      ), format(fit_range[1])),
      if (fit_range[1] == 0.5) {
        paste(" Linacre (2002) describes such values as less productive for",
              "measurement but not degrading.")
      })
    } else {
      ""
    }
    if (erratic[i]) {
      return(sprintf(paste(
        "This judge's endorsements fit the model poorly (infit or outfit",
        "above %s, %s): their decisions depart from the panel's ordering",
        "of the items. Check whether they interpreted the construct",
        "definition differently."
      ), format(fit_range[2]),
      if (fit_range[2] == 1.5) {
        "the upper end of the range Linacre, 2002, calls productive for measurement"
      } else {
        "the upper bound set for this analysis"
      }))
    }
    if (too_severe[i]) {
      return(paste0(sprintf(paste(
        "This judge is markedly %s than the panel (%.2f %s relative to the",
        "panel mean). Consistent severity does not invalidate their ratings,",
        "but it shifts absolute indices such as CVI, which is why the",
        "dependability coefficient is penalized by judge differences."
      ), if (severity_shown[i] > 0) "more severe" else "more lenient",
         severity_shown[i], severity_units[i]), fit_note))
    }
    if (low_diff[i]) {
      return(paste0(paste(
        "This judge used a narrower range of the scale than the rest of the",
        "panel, so their ratings distinguish less among items. This may reflect",
        "a genuine view that the items are similar, or reluctance to use the",
        "full scale."
      ), fit_note))
    }
    paste0("This judge's severity and scale use are consistent with the rest of the panel.",
           fit_note)
  }, character(1))

  res <- res[c("judge", "n_ratings", "mean_rating", "sd_rating", "severity_raw",
               "severity", "se", "infit", "outfit", "n_scored",
               "severity_estimable",
               "differentiation", "central_prop", "extreme_prop",
               "n_items_flipped", "flipped_items",
               "recommendation", "status", "interpretation")]
  rownames(res) <- NULL

  vc <- gt$variance_components
  judge_pct <- vc$percent[vc$source == "judge"]
  items_table <- influence$item_table

  scale_summary <- data.frame(
    n_judges = n_judges,
    n_items = n_items,
    g_coefficient = gt$coefficients$g_coefficient,
    phi_coefficient = gt$coefficients$phi_coefficient,
    judge_variance_pct = if (length(judge_pct)) judge_pct else NA_real_,
    n_typical = sum(res$status == "Supported", na.rm = TRUE),
    n_review = sum(res$status == "Review", na.rm = TRUE),
    n_fragile_items = sum(items_table$fragile, na.rm = TRUE),
    n_items_unchecked = sum(is.na(items_table$fragile)),
    severity_estimable = facets$estimable,
    stringsAsFactors = FALSE
  )

  settings <- list(
    method = "Generalizability analysis, joint-ML facets severity, and leave-one-judge-out item check",
    lo = lo, hi = hi, relevance_cut = relevance_cut,
    na.rm = isTRUE(na.rm),
    bias_correct = isTRUE(bias_correct),
    bias_correction = facets$bias_correction,
    severity_cut = severity_cut,
    severity_raw_cut = severity_raw_cut,
    fit_range = fit_range,
    fit_min_ratings = as.integer(fit_min_ratings),
    differentiation_cut = differentiation_cut,
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
      influence_items = items_table,
      severity_note = facets$reason
    )
  )
}

# The fragile items as a printable table: how many judges rated each relevant,
# its status with the full panel, and whose removal changes it.
.fragile_items_table <- function(items) {
  f <- items[items$fragile %in% TRUE, , drop = FALSE]
  # An object saved before 1.0 holds only the item and its status.
  if (!all(c("n_raters", "n_relevant", "status_full_panel", "changes_without") %in%
           names(f))) {
    return(data.frame(item = f$item, stringsAsFactors = FALSE))
  }
  data.frame(
    item = f$item,
    relevant = paste(f$n_relevant, "of", f$n_raters),
    status = f$status_full_panel,
    `changes without` = f$changes_without,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

# Prints that table, or one wrapped sentence for each item when long judge
# names would push a row past the console width.
.print_fragile_items <- function(items) {
  tab <- .fragile_items_table(items)
  widths <- vapply(names(tab), function(nm) {
    max(nchar(c(nm, tab[[nm]])))
  }, numeric(1))
  if (sum(widths) + length(widths) <= 78) {
    .print_table(tab)
    return(invisible(NULL))
  }
  for (i in seq_len(nrow(tab))) {
    .say(paste0(tab$item[i], ": ", tab$relevant[i], " relevant (",
                tab$status[i], "); changes without ",
                tab$`changes without`[i], "."), indent = 1L, exdent = 3L)
  }
  invisible(NULL)
}

# Sentences about the fragile-item check, shared by print and summary.
.fragile_items_notes <- function(items) {
  unchecked <- sum(is.na(items$fragile))
  c(
    if (any(items$fragile %in% TRUE)) {
      paste("changes without: removing any one of these judges changes the",
            "item's status. Such an item is one judge away from the other",
            "side of the CVI criterion for its panel size (Lynn, 1986): at the",
            "criterion, or one short of it. This describes the item, not the",
            "judges named, and is a contentvalidR check, not a published",
            "index.")
    },
    if (unchecked > 0L) {
      paste("Not checked:", .n_noun(unchecked, "item"),
            "rated by three or fewer judges, where one judge fewer leaves no",
            "CVI criterion to compare with.")
    }
  )
}

# How many judges Phi rests on when some judges left items unrated, as a
# clause for the missing-ratings line.
.phi_judges_clause <- function(n_judges, dropped) {
  if (!isTRUE(dropped > 0L)) return("")
  kept <- n_judges - dropped
  if (kept < 2L) {
    return("; fewer than two judges rated every item, so Phi is not estimable")
  }
  paste0("; Phi uses the ", .n_noun(kept, "judge"), " who rated every item")
}

# The fit rule as printed. Linacre is cited only for his own bound, and judges
# above the bound on too few scored decisions are named, so that a high mean
# square beside "Typical" is explained.
.judge_fit_lines <- function(r, st) {
  upper <- st$fit_range[2]
  min_n <- st$fit_min_ratings
  out <- paste0(
    "Fit: a judge is flagged as erratic when infit or outfit is above ",
    format(upper), ", ",
    if (upper == 1.5) {
      "the top of the range Linacre (2002) calls productive for measurement"
    } else {
      "the upper bound set for this analysis"
    },
    ", and the model scored at least ", min_n, " of their decisions. The ",
    "flag and the minimum are contentvalidR conventions."
  )
  above <- (!is.na(r$infit) & r$infit > upper) |
    (!is.na(r$outfit) & r$outfit > upper)
  few <- above & r$n_scored < min_n
  if (!any(r$n_scored >= min_n)) {
    out <- c(out, paste0(
      "Here the model scored at most ", max(r$n_scored), " of any judge's ",
      "decisions (items every judge agreed on are set aside), so the fit ",
      "statistics are shown and not flagged."
    ))
  } else if (any(few)) {
    out <- c(out, paste0(
      "Above ", format(upper), " on too few scored decisions to flag: ",
      paste0(r$judge[few], " (", r$n_scored[few], ")", collapse = ", "), "."
    ))
  }
  out
}

#' @export
print.contentvalid_judge <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  s <- x$scale_summary
  st <- x$settings
  d <- x$design
  r <- x$results
  cat("contentvalidR judge heterogeneity\n")
  cat(strrep("-", 33), "\n", sep = "")
  cat("Judges: ", s$n_judges, " | Items: ", s$n_items, "\n", sep = "")
  cat("Scale: ", .fmt_scale(st$lo), " to ", .fmt_scale(st$hi),
      " | Relevant: a rating of ", .fmt_scale(st$relevance_cut),
      if (st$relevance_cut < st$hi) " or higher", "\n", sep = "")
  cat("Dependability (Phi): ",
      if (is.na(s$phi_coefficient)) "not estimable" else
        .fmt(s$phi_coefficient, digits),
      " | Judge share of variance: ",
      if (is.na(s$judge_variance_pct)) "not estimable" else
        paste0(formatC(s$judge_variance_pct, format = "f", digits = 1), "%"),
      "\n", sep = "")
  if (isTRUE(d$n_missing > 0L)) {
    .say(paste0(
      "Missing ratings: ", d$n_missing, ". Each judge is compared with the ",
      "panel on the items they rated",
      .phi_judges_clause(s$n_judges, d$gtheory_judges_dropped),
      "."))
  }
  cat("\n")
  n_ok <- sum(r$status == "Supported")
  if (s$n_judges < 2L) {
    # Nothing below applies to a single judge: no flag, no model, no check.
    .say("One judge is not a panel: there is nothing to compare them with.")
    return(invisible(x))
  } else {
    .say(paste0(n_ok, " of ", .n_noun(nrow(r), "judge is", "judges are"),
                " consistent with the panel."))
  }
  flagged <- r$status == "Review"
  if (any(flagged)) {
    .say("Flagged for review:",
         paste0(r$judge[flagged], " (", r$recommendation[flagged], ")",
                collapse = ", "))
  }

  cat("\nJudges\n")
  estimable <- isTRUE(s$severity_estimable)
  show <- data.frame(judge = r$judge, decision = r$recommendation,
                     mean = .fmt(r$mean_rating, digits, bounded = FALSE),
                     severity = .fmt(r$severity_raw, digits, bounded = FALSE),
                     stringsAsFactors = FALSE, check.names = FALSE)
  if (estimable) {
    show$logit <- .fmt(r$severity, digits, bounded = FALSE)
    show$infit <- .fmt(r$infit, digits, bounded = FALSE)
    show$outfit <- .fmt(r$outfit, digits, bounded = FALSE)
  }
  show$`scale use` <- .fmt(r$differentiation, digits, bounded = FALSE)
  .print_table(show)
  cat("\n")
  .say(paste0(
    "mean: the judge's mean rating. severity: how far the judge rates below ",
    "the panel, in rating points (negative is more lenient)",
    if (estimable) paste0("; logit: the same from the facets model, against ",
                          "the judges it placed, which the flags use") else "",
    "."
  ))
  cat("\n")
  # Objects saved before 1.0 carry no differentiation_cut or fit_min_ratings.
  diff_cut <- if (is.null(st$differentiation_cut)) 0.5 else st$differentiation_cut
  points_rule <- paste0(.fmt(st$severity_raw_cut, digits, bounded = FALSE),
                        " rating points")
  .say(paste0(
    "A judge is flagged when severity exceeds ",
    if (estimable) paste0(format(st$severity_cut), " logit") else points_rule,
    " in either direction",
    if (estimable && anyNA(r$severity)) {
      paste0(" (", points_rule, " for a judge the model could not place)")
    },
    " or scale use is below ",
    .fmt(diff_cut, digits, bounded = FALSE),
    ". These cuts are contentvalidR conventions, not published standards."
  ))
  if (estimable && !is.null(r$n_scored) && !is.null(st$fit_min_ratings)) {
    cat("\n")
    for (line in .judge_fit_lines(r, st)) .say(line)
  }

  if (!estimable) {
    cat("\nLogit severity not estimated\n")
    .say(x$details$severity_note)
    .say("Severity in rating points is reported instead and is used for",
         "flagging.")
  }

  items <- x$details$influence_items
  if (isTRUE(s$n_fragile_items > 0L)) {
    cat("\nItems whose status changes if one judge is removed\n")
    .print_fragile_items(items)
    cat("\n")
  } else if (any(items$fragile %in% FALSE)) {
    cat("\nNo item's review status depends on any single judge.\n")
  } else {
    cat("\n")
  }
  for (line in .fragile_items_notes(items)) .say(line)

  if (.show_key()) {
    terms <- c("severity", "differentiation", "phi_coefficient")
    headings <- c("severity", "scale use", "Phi")
    if (estimable) {
      terms <- append(terms, "infit/outfit", after = 1L)
      headings <- append(headings, "infit, outfit", after = 1L)
    }
    .print_key(terms, headings = headings)
    .print_decision_legend(x$results$recommendation, "judge")
    .print_key_footer()
  }

  cat("\n")
  .say("A 'Review' judge is not a judge to remove. Disagreement can be",
       "substantive expertise; the flag marks ratings worth a closer look.")
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
  core$n_missing <- object$design$n_missing
  core$gtheory_judges_dropped <- object$design$gtheory_judges_dropped
  core$reviewed_judges <- object$results[object$results$status == "Review", , drop = FALSE]
  class(core) <- "summary.contentvalid_judge"
  core
}

#' @export
print.summary.contentvalid_judge <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  cat("Summary: judge and rater heterogeneity\n")
  cat(strrep("-", 38), "\n", sep = "")
  cat("Judges: ", x$n_judges, " | Items: ", x$n_items, "\n", sep = "")
  cat("Consistent with panel: ", x$n_supported, " | Flagged for review: ",
      x$n_review, " | Insufficient: ", x$n_insufficient, "\n", sep = "")

  cat("\nGeneralizability\n")
  gt <- x$gtheory
  na_words <- function(v) if (is.na(v)) "not estimable" else .fmt(v, digits)
  cat("  Dependability (absolute decisions): ",
      na_words(gt$coefficients$phi_coefficient), "\n", sep = "")
  cat("  Generalizability (rank ordering):   ",
      na_words(gt$coefficients$g_coefficient), "\n", sep = "")
  if (isTRUE(x$n_missing > 0L)) {
    .say(paste0("Missing ratings: ", x$n_missing,
                .phi_judges_clause(x$n_judges, x$gtheory_judges_dropped), "."),
         indent = 2L, exdent = 2L)
  }
  if (nrow(gt$judges_needed) && !identical(gt$status, "Insufficient data")) {
    cat("\nJudges needed to reach each coefficient\n")
    .print_table(.judges_needed_table(gt$judges_needed, digits))
  }

  if (nrow(x$reviewed_judges)) {
    cat("\nJudges flagged for review\n")
    # Judges flagged for the same reason share one explanation.
    rj <- x$reviewed_judges
    for (txt in unique(rj$interpretation)) {
      same <- rj$interpretation == txt
      cat("\n")
      .say(paste0(paste0(rj$judge[same], collapse = ", "), " (",
                  rj$recommendation[same][1], ")"), indent = 2L, exdent = 4L)
      .say(txt, indent = 4L)
    }
  } else {
    cat("\nNo judge was flagged for review.\n")
  }

  fragile <- x$influence_items
  if (is.data.frame(fragile)) {
    if (any(fragile$fragile %in% TRUE)) {
      cat("\nItems whose status changes if one judge is removed\n")
      .print_fragile_items(fragile)
      cat("\n")
    } else if (any(is.na(fragile$fragile))) {
      cat("\n")
    }
    for (line in .fragile_items_notes(fragile)) .say(line)
  }

  cat("\n")
  .say("This analysis describes how much conclusions depend on these judges.",
       "It does not establish that the items cover the intended content",
       "domain.")
  invisible(x)
}

# Lynn (1986, Table 2): the fewest experts, out of a panel of n, whose
# endorsement establishes an item's content validity beyond the .05 level. Up
# to five experts all must agree; from six, one may disagree, and two from nine.
# Stored as counts because Lynn published them as counts. The ".78" usually
# quoted is her 7 of 9 rounded, and comparing an I-CVI against the rounded
# value demands 8 of 9 -- one expert more than Lynn requires.
.cvi_lynn_minimum <- c(`3` = 3L, `4` = 4L, `5` = 5L, `6` = 5L, `7` = 6L,
                       `8` = 7L, `9` = 7L, `10` = 8L)

# Smallest number of endorsing experts that meets the criterion for a panel of
# size n; NA below three experts, which Lynn considers too few. Lynn's table
# stops at ten. Beyond it the package holds her lowest tabled proportion, 7 of
# 9, which extends her rule rather than being part of it.
.cvi_required_count <- function(n) {
  out <- rep(NA_integer_, length(n))
  small <- !is.na(n) & n >= 3L & n <= 10L
  out[small] <- unname(.cvi_lynn_minimum[as.character(n[small])])
  large <- !is.na(n) & n > 10L
  out[large] <- as.integer(ceiling(7 / 9 * n[large] - 1e-9))
  out
}

# The same criterion as a proportion, for display beside the I-CVI. Decisions
# compare counts, never this proportion, so no rounding can move an item.
.cvi_common_criterion <- function(N) {
  req <- .cvi_required_count(N)
  ifelse(is.na(req), NA_real_, req / N)
}

.kappa_quality <- function(k) {
  ifelse(
    is.na(k), NA_character_,
    ifelse(k > 0.74, "Excellent",
           ifelse(k >= 0.60, "Good",
                  ifelse(k >= 0.40, "Fair", "Low")))
  )
}

#' Analyze expert-panel content-validity evidence
#'
#' @description
#' Provides a user-facing workflow for three common expert-panel tasks:
#'
#' * `mode = "relevance"`: bounded ordinal relevance ratings, combining Aiken's
#'   V (with Penfield-Giacobbi score intervals), CVI/modified kappa, and a
#'   panel-level agreement coefficient.
#' * `mode = "essentiality"`: Lawshe CVR with exact binomial critical values.
#' * `mode = "congruence"`: Rovinelli-Hambleton item-objective congruence.
#'
#' Quantitative results are presented as evidence for item review rather than
#' as a substitute for expert comments, construct coverage, comprehensibility,
#' or other parts of a content-validity argument.
#'
#' @param data Ratings data. For relevance, a judge-by-item numeric matrix/data
#'   frame. For essentiality, either a judge-by-item 0/1 matrix/data frame or a
#'   vector of essential counts. For congruence, a long data frame accepted by
#'   [ioc()].
#' @param mode One of `"relevance"`, `"essentiality"`, or `"congruence"`.
#' @param lo,hi Rating-scale bounds for relevance mode.
#' @param relevance_cut Lowest rating treated as relevant for CVI. Defaults to
#'   `hi - 1`, e.g., 3 on a 1-4 scale or 4 on a 1-5 scale.
#' @param N Panel size for essential-count vector input.
#' @param alpha Inferential/CI alpha level.
#' @param na.rm Permit itemwise/cellwise missing ratings where supported.
#' @param target_col In congruence mode, optional column identifying each
#'   item's intended objective. If absent, IOC cells are returned descriptively.
#' @param proportion_ci Interval method for I-CVI in relevance mode:
#'   `"wilson"` (default), `"agresti_coull"`, `"exact"`, or `"none"`. The
#'   interval uses the same `alpha` as Aiken's V. See `ci` in [cvi()] for the
#'   methods and the evidence for each.
#' @param agreement Panel-level agreement coefficient for relevance mode:
#'   `"krippendorff"` (default), `"ac1"`, or `"none"`. Krippendorff's alpha uses
#'   the relevance ratings at `agreement_level`; Gwet's AC1 uses the
#'   relevant/not-relevant decision. See [panel_agreement()] for the evidence
#'   behind each, including why AC1 is never the default. Panels with fewer
#'   than two experts or two items report no agreement coefficient.
#' @param agreement_level Measurement level for Krippendorff's alpha:
#'   `"ordinal"` (default), `"nominal"`, or `"interval"`. Ignored for AC1.
#' @param agreement_B Bootstrap resamples for the agreement interval; `0` skips
#'   the interval.
#' @param seed Optional seed that makes the agreement interval reproducible.
#' @param legacy Print the earlier published rules beside the decision, for
#'   comparison, in relevance and essentiality modes. Default `FALSE`. They are
#'   computed either way, stored in `details$earlier_methods`, and never change
#'   the decision; `print(fit, legacy = TRUE)` shows them for any fit.
#'
#' @section Earlier methods, for comparison:
#' The decisions use Lynn's (1986) criterion in relevance mode and the exact
#' binomial test (Ayre & Scally, 2014) in essentiality mode. Earlier rules are
#' reported beside them for teaching, and none changes a decision:
#'
#' * **Essentiality.** Lawshe's (1975) Table 1 gives a minimum CVR for 5 to 15
#'   panelists, then every fifth panel size to 40; other sizes have no minimum.
#'   He labeled it a one-tailed test at .05. Wilson, Pan and Schumsky (2012)
#'   found the table closer to a two-tailed test and recomputed it by the
#'   normal approximation, `z / sqrt(N)` for a one-tailed test at `alpha`
#'   (their Table 2). Lawshe's content validity index for the whole set is the
#'   mean CVR of the items his table retains (Lawshe, 1975).
#' * **Relevance.** Fleiss' (1971) kappa, his kappa for many raters and nominal
#'   categories, on the relevant/not-relevant decision. It needs every expert to
#'   rate every item. The printout also notes that S-CVI/Ave is the average
#'   congruency percentage, for which Polit and Beck (2006) recommend .90 or
#'   higher, while calling .80 a reasonable, even strict, criterion for
#'   S-CVI/UA.
#'
#' @return An object of class `contentvalid_expert` and
#'   `contentvalid_workflow`. All flagship workflow objects expose the common
#'   components `results`, `scale_summary`, `settings`, `design`, and `details`.
#'   The historical top-level `scale` component is retained as a compatibility
#'   alias for `scale_summary`. Results include a standardized `status` field
#'   while retaining mode-specific `recommendation` wording. In relevance mode,
#'   `scale_summary` also holds `agreement`, `agreement_low`, and
#'   `agreement_high`, and `details$agreement` holds the full
#'   [panel_agreement()] result.
#'
#' @references
#' Penfield, R. D., & Giacobbi, P. R., Jr. (2004). Applying a score confidence
#' interval to Aiken's item content-relevance index. *Measurement in Physical
#' Education and Exercise Science, 8*(4), 213-225.
#' \doi{10.1207/s15327841mpee0804_3}
#'
#' Ayre, C., & Scally, A. J. (2014). Critical values for Lawshe's content
#' validity ratio: Revisiting the original methods of calculation.
#' *Measurement and Evaluation in Counseling and Development, 47*(1), 79-86.
#' \doi{10.1177/0748175613513808}
#'
#' Lynn, M. R. (1986). Determination and quantification of content validity.
#' *Nursing Research, 35*(6), 382-385.
#' \doi{10.1097/00006199-198611000-00017}
#'
#' Polit, D. F., & Beck, C. T. (2006). The content validity index: Are you
#' sure you know what's being reported? Critique and recommendations.
#' *Research in Nursing & Health, 29*(5), 489-497. \doi{10.1002/nur.20147}
#'
#' Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an acceptable
#' indicator of content validity? *Research in Nursing & Health, 30*(4),
#' 459-467. \doi{10.1002/nur.20199}
#'
#' Hayes, A. F., & Krippendorff, K. (2007). Answering the call for a standard
#' reliability measure for coding data. *Communication Methods and Measures,
#' 1*(1), 77-89. \doi{10.1080/19312450709336664}
#'
#' Zapf, A., Castell, S., Morawietz, L., & Karch, A. (2016). Measuring
#' inter-rater reliability for nominal data: Which coefficients and confidence
#' intervals are appropriate? *BMC Medical Research Methodology, 16*, 93.
#' \doi{10.1186/s12874-016-0200-9}
#'
#' Lawshe, C. H. (1975). A quantitative approach to content validity.
#' *Personnel Psychology, 28*(4), 563-575.
#' \doi{10.1111/j.1744-6570.1975.tb01393.x}
#'
#' Wilson, F. R., Pan, W., & Schumsky, D. A. (2012). Recalculation of the
#' critical values for Lawshe's content validity ratio. *Measurement and
#' Evaluation in Counseling and Development, 45*(3), 197-210.
#' \doi{10.1177/0748175612440286}
#'
#' Fleiss, J. L. (1971). Measuring nominal scale agreement among many raters.
#' *Psychological Bulletin, 76*(5), 378-382. \doi{10.1037/h0031619}
#'
#' @examples
#' relevance <- matrix(
#'   c(4,4,4,3, 4,4,3,4, 3,4,4,4, 4,3,4,4),
#'   nrow = 4,
#'   dimnames = list(NULL, paste0("Item", 1:4))
#' )
#' fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4, seed = 1)
#' fit
#' summary(fit)
#'
#' # Essential counts from 12 experts, beside Lawshe's table and Wilson et al.
#' expert_validity(c(12, 10, 8, 6), mode = "essentiality", N = 12,
#'                 legacy = TRUE)
#' @export
expert_validity <- function(data,
                            mode = c("relevance", "essentiality", "congruence"),
                            lo = 1,
                            hi = 4,
                            relevance_cut = NULL,
                            N = NULL,
                            alpha = 0.05,
                            na.rm = FALSE,
                            target_col = "target_objective",
                            proportion_ci = c("wilson", "agresti_coull", "exact", "none"),
                            agreement = c("krippendorff", "ac1", "none"),
                            agreement_level = c("ordinal", "nominal", "interval"),
                            agreement_B = 1000,
                            seed = NULL,
                            legacy = FALSE) {
  mode <- match.arg(mode)
  proportion_ci <- match.arg(proportion_ci)
  agreement <- match.arg(agreement)
  agreement_level <- match.arg(agreement_level)
  .validate_flag(na.rm, "na.rm")
  .validate_flag(legacy, "legacy")

  if (mode == "relevance") {
    if (!is.numeric(lo) || length(lo) != 1L || !is.finite(lo) ||
        !is.numeric(hi) || length(hi) != 1L || !is.finite(hi) || hi <= lo) {
      stop("`lo` and `hi` must be finite scalars with `hi > lo`.", call. = FALSE)
    }
    if (is.null(relevance_cut)) relevance_cut <- hi - 1
    if (!is.numeric(relevance_cut) || length(relevance_cut) != 1L ||
        !is.finite(relevance_cut) || relevance_cut < lo || relevance_cut > hi) {
      stop("`relevance_cut` must lie within the rating scale.", call. = FALSE)
    }

    R <- as.matrix(data)
    aiken <- aikens_v(R, lo = lo, hi = hi, ci = "score",
                      alpha = alpha, na.rm = na.rm)
    B <- ifelse(is.na(R), NA_real_, as.numeric(R >= relevance_cut))
    dim(B) <- dim(R)
    dimnames(B) <- dimnames(R)
    cv <- cvi(B, na.rm = na.rm, ci = proportion_ci, alpha = alpha)

    idx <- match(aiken$item, cv$item_level$item)
    item <- cbind(
      aiken,
      cv$item_level[idx, c("A", "I_CVI", "I_CVI_low", "I_CVI_high", "Pc", "kappa_mod"),
                    drop = FALSE]
    )
    item$cvi_criterion <- .cvi_common_criterion(item$N)
    item$kappa_quality <- .kappa_quality(item$kappa_mod)
    item$ci_width <- item$ci_high - item$ci_low
    item$recommendation <- ifelse(
      item$N < 3L,
      "Insufficient panel",
      ifelse(
        !is.na(item$cvi_criterion) & item$A >= .cvi_required_count(item$N),
        ifelse(item$kappa_mod > 0.74, "Strong support", "Support"),
        "Review"
      )
    )
    item$interpretation <- vapply(seq_len(nrow(item)), function(i) {
      if (item$N[i] < 3L) {
        return("Fewer than three usable expert ratings are available; treat the quantitative result as descriptive.")
      }
      if (item$recommendation[i] == "Strong support") {
        return("The item meets the common panel-size CVI guideline and shows excellent chance-corrected agreement; Aiken's V and its score interval quantify relevance level and precision.")
      }
      if (item$recommendation[i] == "Support") {
        return("The item meets the common panel-size CVI guideline; inspect Aiken's V, interval precision, and expert comments before finalizing wording.")
      }
      "The item does not meet the common panel-size CVI guideline; review wording, relevance, construct coverage, and expert comments before revising or removing it."
    }, character(1))

    agree <- NULL
    if (agreement != "none") {
      .validate_bootstrap_args(agreement_B, seed, "agreement_B")
      if (nrow(R) >= 2L && ncol(R) >= 2L) {
        # Alpha uses the ratings at the chosen level; AC1 uses the
        # relevant/not-relevant decision, the categorical judgment it was built for.
        agree <- panel_agreement(
          if (agreement == "ac1") B else R,
          method = agreement, level = agreement_level,
          B = agreement_B, alpha = alpha, seed = seed
        )
      }
    }

    sl <- cv$scale_level
    scale <- data.frame(
      n_items = nrow(item),
      n_experts_min = min(item$N),
      n_experts_max = max(item$N),
      mean_Aiken_V = if (all(is.na(item$V))) NA_real_ else mean(item$V, na.rm = TRUE),
      S_CVI_Ave = sl$S_CVI_Ave,
      S_CVI_UA = sl$S_CVI_UA,
      agreement = if (is.null(agree)) NA_real_ else agree$estimate,
      agreement_low = if (is.null(agree)) NA_real_ else agree$ci_low,
      agreement_high = if (is.null(agree)) NA_real_ else agree$ci_high,
      n_strong_support = sum(item$recommendation == "Strong support"),
      n_support = sum(item$recommendation == "Support"),
      n_review = sum(item$recommendation == "Review"),
      n_insufficient = sum(item$recommendation == "Insufficient panel"),
      stringsAsFactors = FALSE
    )

    item$status <- .workflow_status_from_recommendation(item$recommendation)
    settings <- list(
      method = "Aiken V with score intervals plus CVI/modified kappa",
      lo = lo, hi = hi, relevance_cut = relevance_cut,
      alpha = alpha, na.rm = isTRUE(na.rm),
      judge_type = "expert",
      aiken_ci = "Penfield-Giacobbi score",
      proportion_ci = proportion_ci,
      agreement = agreement,
      agreement_level = if (agreement == "krippendorff") agreement_level else NA_character_,
      agreement_B = agreement_B,
      seed = seed
    )
    design <- list(
      type = "expert-panel relevance",
      n_items = nrow(item),
      n_judges = nrow(R),
      n_judges_min = if (nrow(item)) min(item$N) else 0L,
      n_judges_max = if (nrow(item)) max(item$N) else 0L,
      n_missing = sum(is.na(R))
    )
    out <- .new_contentvalid_workflow(
      subclass = "contentvalid_expert",
      workflow = "expert-panel",
      mode = mode,
      results = item,
      scale_summary = scale,
      settings = settings,
      design = design,
      details = list(
        cvi = cv, agreement = agree,
        earlier_methods = .relevance_earlier_methods(B, scale, show = legacy)
      ),
      legacy = list(scale = scale)
    )
  } else if (mode == "essentiality") {
    res <- cvr(data, N = N, alpha = alpha, na.rm = na.rm)
    res$recommendation <- ifelse(
      res$N < 1L,
      "Insufficient data",
      ifelse(res$pass, "Supported", "Review")
    )
    res$interpretation <- ifelse(
      res$N < 1L,
      "No usable expert ratings are available.",
      ifelse(
        res$pass,
        "Essential ratings meet the exact one-sided binomial criterion for this panel size.",
        "Essential ratings do not meet the exact panel-size criterion; review the item and expert rationale before deciding whether to revise or remove it."
      )
    )
    res$status <- .workflow_status_from_recommendation(res$recommendation)
    scale <- data.frame(
      n_items = nrow(res),
      n_supported = sum(res$status == "Supported"),
      n_review = sum(res$status == "Review"),
      n_insufficient = sum(res$status == "Insufficient data"),
      stringsAsFactors = FALSE
    )
    matrix_input <- is.matrix(data) || is.data.frame(data)
    settings <- list(
      alpha = alpha, na.rm = isTRUE(na.rm), judge_type = "expert",
      method = "Lawshe CVR with exact binomial critical values"
    )
    design <- list(
      type = "expert-panel essentiality",
      n_items = nrow(res),
      n_judges = if (matrix_input) nrow(data) else if (length(unique(res$N)) == 1L) unique(res$N) else NA_integer_,
      n_judges_min = if (nrow(res)) min(res$N) else 0L,
      n_judges_max = if (nrow(res)) max(res$N) else 0L,
      n_missing = if (matrix_input) sum(is.na(as.matrix(data))) else NA_integer_
    )
    out <- .new_contentvalid_workflow(
      subclass = "contentvalid_expert",
      workflow = "expert-panel",
      mode = mode,
      results = res,
      scale_summary = scale,
      settings = settings,
      design = design,
      details = list(
        earlier_methods = .essentiality_earlier_methods(res, alpha, show = legacy)
      ),
      legacy = list(scale = scale)
    )
  } else {
    if (!is.data.frame(data)) {
      stop("Congruence mode requires a long data.frame.", call. = FALSE)
    }
    cells <- ioc(data, na.rm = na.rm)
    if (!is.character(target_col) || length(target_col) != 1L || is.na(target_col) ||
        !nzchar(trimws(target_col))) {
      stop("`target_col` must be one non-empty column name.", call. = FALSE)
    }
    has_target <- target_col %in% names(data)

    if (!has_target) {
      res <- cells
      res$recommendation <- "Descriptive only"
      res$interpretation <- "No target-objective column was supplied; IOC is reported descriptively for each item-objective cell."
    } else {
      map <- unique(data[, c("item", target_col), drop = FALSE])
      names(map) <- c("item", "target")
      if (anyNA(map$target) || any(!nzchar(trimws(as.character(map$target))))) {
        stop("Target-objective mappings cannot be missing or empty.", call. = FALSE)
      }
      counts <- table(map$item)
      if (any(counts != 1L)) {
        stop("Each item must map to exactly one target objective.", call. = FALSE)
      }
      available <- split(as.character(data$objective), as.character(data$item), drop = TRUE)
      invalid_target <- vapply(seq_len(nrow(map)), function(i) {
        !as.character(map$target[i]) %in% unique(available[[as.character(map$item[i])]])
      }, logical(1))
      if (any(invalid_target)) {
        stop("Target objective is absent from the rated objectives for item(s): ",
             paste(as.character(map$item[invalid_target]), collapse = ", "), ".", call. = FALSE)
      }

      by_item <- split(cells, cells$item, drop = TRUE)
      rows <- lapply(by_item, function(g) {
        target <- as.character(map$target[match(g$item[1], map$item)])
        target_row <- g[g$objective == target, , drop = FALSE]
        competitors <- g[g$objective != target, , drop = FALSE]
        target_ioc <- if (nrow(target_row) == 1L) target_row$ioc else NA_real_
        if (nrow(competitors) > 0L && any(is.finite(competitors$ioc))) {
          mx <- max(competitors$ioc, na.rm = TRUE)
          strongest <- paste(competitors$objective[competitors$ioc == mx], collapse = ", ")
        } else {
          mx <- NA_real_
          strongest <- NA_character_
        }
        margin <- if (is.finite(target_ioc) && is.finite(mx)) target_ioc - mx else NA_real_
        rec <- if (!is.finite(target_ioc)) {
          "Insufficient data"
        } else if (!is.finite(mx)) {
          "Target described"
        } else if (margin > 0) {
          "Target favored"
        } else if (margin == 0) {
          "Tie / review"
        } else {
          "Review"
        }
        data.frame(
          item = g$item[1], target = target,
          target_ioc = target_ioc,
          strongest_competitor = strongest,
          competitor_ioc = mx,
          margin = margin,
          recommendation = rec,
          stringsAsFactors = FALSE
        )
      })
      res <- do.call(rbind, rows)
      rownames(res) <- NULL
      res$interpretation <- vapply(seq_len(nrow(res)), function(i) {
        switch(
          res$recommendation[i],
          "Target favored" = "The intended objective has the highest IOC; use the margin and expert comments to judge practical distinctiveness.",
          "Tie / review" = "The intended objective ties the strongest competing objective; review conceptual boundaries and item wording.",
          "Review" = "A competing objective has higher IOC than the intended objective; review target alignment and expert rationale.",
          "Target described" = "The intended objective has usable IOC evidence, but no competing objective is available for a distinctiveness comparison.",
          "Insufficient data" = "The intended objective lacks usable expert ratings."
        )
      }, character(1))
    }

    res$status <- .workflow_status_from_recommendation(res$recommendation)
    scale <- data.frame(
      n_items = length(unique(cells$item)),
      n_supported = sum(res$status == "Supported", na.rm = TRUE),
      n_review = sum(res$status == "Review", na.rm = TRUE),
      n_insufficient = sum(res$status == "Insufficient data", na.rm = TRUE),
      n_descriptive = sum(res$status == "Descriptive only", na.rm = TRUE),
      stringsAsFactors = FALSE
    )
    settings <- list(
      na.rm = isTRUE(na.rm), target_col = if (has_target) target_col else NULL,
      judge_type = "expert",
      method = "Rovinelli-Hambleton item-objective congruence"
    )
    design <- list(
      type = "expert-panel congruence",
      n_items = length(unique(cells$item)),
      n_judges = length(unique(data$judge)),
      n_judges_min = if (nrow(cells)) min(cells$n_judges) else 0L,
      n_judges_max = if (nrow(cells)) max(cells$n_judges) else 0L,
      n_missing = sum(cells$n_missing),
      n_objectives = length(unique(data$objective))
    )
    out <- .new_contentvalid_workflow(
      subclass = "contentvalid_expert",
      workflow = "expert-panel",
      mode = mode,
      results = res,
      scale_summary = scale,
      settings = settings,
      design = design,
      details = list(cells = cells),
      legacy = list(scale = scale)
    )
  }

  out
}

# The printed item table for one expert-panel mode, from any subset of the
# results rows. print() shows every item; summary() shows the flagged ones.
.expert_item_table <- function(r, mode, digits, alpha) {
  if (mode == "relevance") {
    ci <- .ci_label(alpha)
    tab <- data.frame(item = r$item, decision = r$recommendation, N = r$N,
                      V = .fmt(r$V, digits),
                      stringsAsFactors = FALSE, check.names = FALSE)
    # Objects saved before the interval columns existed still print.
    if (all(c("ci_low", "ci_high") %in% names(r))) {
      tab[[ci]] <- .fmt_ci(r$ci_low, r$ci_high, digits)
    }
    tab$`I-CVI` <- .fmt(r$I_CVI, digits)
    if (all(c("I_CVI_low", "I_CVI_high") %in% names(r))) {
      tab <- cbind(tab, stats::setNames(
        data.frame(.fmt_ci(r$I_CVI_low, r$I_CVI_high, digits),
                   stringsAsFactors = FALSE), ci))
    }
    tab$kappa <- .fmt(r$kappa_mod, digits)
    # One panel size means one criterion, stated once rather than on every row.
    sizes <- unique(r$N[!is.na(r$cvi_criterion)])
    if (length(sizes) > 1L) tab$`I-CVI needed` <- .fmt(r$cvi_criterion, digits)
    return(tab)
  }
  if (mode == "essentiality") {
    tab <- data.frame(item = r$item, decision = r$recommendation,
                      essential = paste0(r$ne, "/", r$N),
                      CVR = .fmt(r$cvr, digits), p = .fmt_p(r$p_value),
                      stringsAsFactors = FALSE, check.names = FALSE)
    if (length(unique(r$N)) > 1L) tab$needed <- r$critical_ne
    return(tab)
  }
  tab <- data.frame(item = r$item, stringsAsFactors = FALSE, check.names = FALSE)
  if ("target" %in% names(r)) tab$target <- r$target
  tab$decision <- r$recommendation
  if ("target_ioc" %in% names(r)) {
    # IOC lies in [-1, 1]; the margin between two IOCs can reach 2, so it
    # keeps its leading zero (APA 7, Section 6.36).
    tab$`target IOC` <- .fmt(r$target_ioc, digits)
    tab$competitor <- r$strongest_competitor
    tab$`competitor IOC` <- .fmt(r$competitor_ioc, digits)
    tab$margin <- .fmt(r$margin, digits, bounded = FALSE)
  } else {
    num <- names(r)[vapply(r, is.numeric, logical(1))]
    for (col in num) tab[[col]] <- .fmt(r[[col]], digits)
  }
  tab
}

#' @export
print.contentvalid_expert <- function(x, digits = 2, legacy = NULL, ...) {
  .validate_digits(digits)
  cat("contentvalidR expert-panel analysis\n")
  cat(strrep("-", 35), "\n", sep = "")
  cat("Mode: ", x$mode, "\n", sep = "")
  d <- .workflow_design(x)
  # Objects saved before panel agreement existed carry no agreement setting.
  show_agreement <- identical(x$mode, "relevance") &&
    is.character(x$settings$agreement) && !identical(x$settings$agreement, "none")
  missing_line <- function(unit) {
    if (!is.null(d$n_missing) && is.finite(d$n_missing) && d$n_missing > 0L) {
      .say(paste0("Missing ratings: ", d$n_missing, "; each ", unit,
                  " uses the experts who rated it."))
    }
  }

  if (x$mode == "relevance") {
    s <- x$scale[1, ]
    cat("Items: ", s$n_items, " | Experts/item: ", s$n_experts_min,
        if (s$n_experts_min != s$n_experts_max) paste0("-", s$n_experts_max),
        "\n", sep = "")
    cat("Mean Aiken V: ", .fmt(s$mean_Aiken_V, digits),
        " | S-CVI/Ave: ", .fmt(s$S_CVI_Ave, digits),
        " | S-CVI/UA: ", .fmt(s$S_CVI_UA, digits), "\n", sep = "")
    cat("Strong support: ", s$n_strong_support, " | Support: ", s$n_support,
        " | Review: ", s$n_review, "\n", sep = "")
    if (show_agreement) {
      .say(.expert_agreement_line(x$details$agreement, digits), exdent = 2)
    }
    missing_line("item")
    cat("\n")
    r <- x$results
    ci <- .ci_label(x$settings$alpha)
    sizes <- unique(r$N[!is.na(r$cvi_criterion)])
    .print_table(.expert_item_table(r, "relevance", digits, x$settings$alpha))
    cat("\n")
    .say("Each", ci, "follows its estimate: Aiken's V has a Penfield-Giacobbi",
         "score interval, and I-CVI the proportion interval named below.")
    if (length(sizes) == 1L) {
      need <- .cvi_required_count(sizes)
      .say(sprintf(paste("I-CVI criterion for %d experts: %d agreeing (%s),",
                         "following Lynn (1986); kappa is modified kappa,",
                         "with values above .74 read as excellent (Polit,",
                         "Beck, & Owen, 2007)."),
                   sizes, need, .fmt(need / sizes, digits)))
    }
    if (!is.null(x$settings$proportion_ci)) {
      .say(.proportion_ci_note(x$settings$proportion_ci, x$settings$alpha))
    }
    if (show_agreement && !is.null(x$details$agreement)) {
      cat("\n")
      .say(.expert_agreement_note(x$details$agreement))
    }
    cat("\n")
    .say("CVI criteria are published panel-size guidelines, not universal",
         "validity cutoffs.")
  } else if (x$mode == "essentiality") {
    cat("Items: ", d$n_items, " | Experts/item: ", d$n_judges_min,
        if (d$n_judges_min != d$n_judges_max) paste0("-", d$n_judges_max),
        "\n", sep = "")
    missing_line("item")
    .say("Method:", x$settings$method)
    cat("\n")
    r <- x$results
    sizes <- unique(r$N)
    .print_table(.expert_item_table(r, "essentiality", digits,
                                    x$settings$alpha))
    cat("\n")
    .say("essential: experts rating the item essential, out of those who",
         "rated it.")
    if (length(sizes) == 1L) {
      .say(sprintf(paste("With %d experts, an item needs at least %d rating it",
                         "essential for the exact one-tailed binomial test at",
                         "alpha = %s (Ayre & Scally, 2014)."),
                   sizes, r$critical_ne[1], .fmt(x$settings$alpha)))
    }
  } else {
    cat("Items: ", d$n_items, " | Experts/cell: ", d$n_judges_min,
        if (d$n_judges_min != d$n_judges_max) paste0("-", d$n_judges_max),
        " | Objectives: ", d$n_objectives, "\n", sep = "")
    missing_line("cell")
    .say("Method:", x$settings$method)
    cat("\n")
    r <- x$results
    .print_table(.expert_item_table(r, "congruence", digits, x$settings$alpha))
    # Each distinct interpretation is printed once, with the items it covers.
    if ("interpretation" %in% names(r)) {
      cat("\n")
      .say_grouped(r$item, r$interpretation)
    }
  }

  # Congruence has no earlier rule to compare, so it never prints a block.
  em <- if (is.list(x$details)) x$details$earlier_methods else NULL
  if (!is.null(em) && .show_earlier(x, legacy)) {
    if (x$mode == "relevance") .print_relevance_earlier(em, digits)
    if (x$mode == "essentiality") .print_essentiality_earlier(em, digits)
  }

  if (.show_key()) {
    ci <- .ci_label(x$settings$alpha)
    switch(
      x$mode,
      relevance = .print_key(
        c("V", "I_CVI", "I_CVI_low/I_CVI_high", "kappa_mod",
          if (show_agreement) "agreement"),
        headings = c("V", "I-CVI", paste(ci, "after I-CVI"), "kappa",
                     if (show_agreement) "Panel agreement")),
      essentiality = .print_key("cvr", headings = "CVR"),
      .print_key("ioc", headings = "IOC")
    )
    .print_status_legend()
    .print_key_footer()
  }

  cat("\n")
  .say("Use quantitative indices alongside expert comments, construct",
       "coverage, and comprehensibility review.")
  invisible(x)
}

#' @export
summary.contentvalid_expert <- function(object, ...) {
  out <- .workflow_summary_core(object)
  out$mode <- object$mode
  out$agreement <- if (is.list(object$details)) object$details$agreement else NULL
  # Compatibility aliases retained for pre-v0.0.6 user code.
  out$scale <- out$scale_summary
  out$flagged <- out$reviewed_items
  class(out) <- c("summary.contentvalid_expert", "summary.contentvalid_workflow")
  out
}

#' @export
print.summary.contentvalid_expert <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  cat("Summary: expert-panel content-validity evidence\n")
  cat(strrep("-", 47), "\n", sep = "")
  cat("Mode: ", x$mode, "\n", sep = "")
  cat("Supported: ", x$n_supported, " | Review: ", x$n_review, sep = "")
  if (x$n_insufficient > 0L) cat(" | Insufficient data: ", x$n_insufficient, sep = "")
  if (x$n_descriptive > 0L) cat(" | Descriptive only: ", x$n_descriptive, sep = "")
  cat("\n")
  if (identical(x$mode, "relevance") && is.character(x$settings$agreement) &&
      !identical(x$settings$agreement, "none")) {
    .say(.expert_agreement_line(x$agreement, digits), exdent = 2L)
  }
  f <- x$flagged
  if (nrow(f) == 0L) {
    cat("\nNo items were flagged by the workflow's quantitative review rules.\n")
  } else {
    cat("\nItems needing review or more usable ratings\n")
    .print_table(.expert_item_table(f, x$mode, digits, x$settings$alpha))
    if ("interpretation" %in% names(f)) {
      cat("\n")
      .say_grouped(f$item, f$interpretation)
    }
  }
  cat("\n")
  .say("These summaries support, but do not replace, qualitative content",
       "review.")
  invisible(x)
}

#' Plot expert-panel content-validity results
#'
#' @description
#' Draws a mode-specific evidence plot. Relevance mode shows Aiken's V with its
#' score confidence interval and overlays I-CVI as a separate marker. Essentiality
#' mode shows each observed CVR against its item-specific critical CVR. Congruence
#' mode uses a target-versus-strongest-competitor gap plot when a target mapping is
#' available.
#'
#' @param x A `contentvalid_expert` object.
#' @param show_legend Logical; draw the compact plot key. Default `TRUE`.
#' @param ... Additional graphical arguments passed to [graphics::plot()].
#' @return The input object invisibly.
#' @examples
#' relevance <- matrix(
#'   c(4,4,4,3, 4,4,3,4, 3,4,4,4, 4,3,4,4),
#'   nrow = 4,
#'   dimnames = list(NULL, paste0("Item", 1:4))
#' )
#' plot(expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
#'                      agreement = "none"))
#' plot(expert_validity(c(10, 8, 6), mode = "essentiality", N = 12))
#' @export
plot.contentvalid_expert <- function(x, show_legend = TRUE, ...) {
  .validate_flag(show_legend, "show_legend")
  if (x$mode == "relevance") {
    r <- x$results
    y <- seq_len(nrow(r))
    graphics::plot(r$V, y, xlim = c(0, 1), ylim = c(0.5, nrow(r) + 1.25), yaxt = "n",
                   xlab = "Relevance index", ylab = "", pch = 19, ...)
    graphics::axis(2, at = y, labels = r$item, las = 1)
    good_ci <- is.finite(r$ci_low) & is.finite(r$ci_high)
    graphics::segments(r$ci_low[good_ci], y[good_ci], r$ci_high[good_ci], y[good_ci])
    good_cvi <- is.finite(r$I_CVI)
    graphics::points(r$I_CVI[good_cvi], y[good_cvi], pch = 1)
    if (isTRUE(show_legend)) {
      graphics::legend("top", legend = c("Aiken V", "I-CVI", "Score CI"),
                       pch = c(19, 1, NA), lty = c(NA, NA, 1), bty = "n",
                       horiz = TRUE, cex = 0.68, x.intersp = 0.7)
    }
  } else if (x$mode == "essentiality") {
    r <- x$results
    y <- seq_len(nrow(r))
    graphics::plot(r$cvr, y, xlim = c(-1, 1), ylim = c(0.5, nrow(r) + 1.25), yaxt = "n",
                   xlab = "CVR", ylab = "", pch = 19, ...)
    graphics::axis(2, at = y, labels = r$item, las = 1)
    graphics::abline(v = 0, lty = 3)
    good <- is.finite(r$critical_cvr) & is.finite(r$cvr)
    graphics::segments(r$critical_cvr[good], y[good], r$cvr[good], y[good])
    graphics::points(r$critical_cvr[good], y[good], pch = 1)
    if (isTRUE(show_legend)) {
      graphics::legend("top", legend = c("Observed", "Critical"),
                       pch = c(19, 1), bty = "n", horiz = TRUE, cex = 0.70)
    }
  } else {
    r <- x$results
    if (!"target_ioc" %in% names(r)) {
      stop("Congruence plots require a target-objective mapping.", call. = FALSE)
    }
    y <- seq_len(nrow(r))
    graphics::plot(r$target_ioc, y, xlim = c(-1, 1), ylim = c(0.5, nrow(r) + 1.25), yaxt = "n",
                   xlab = "IOC", ylab = "", pch = 19, ...)
    graphics::axis(2, at = y, labels = r$item, las = 1)
    graphics::abline(v = 0, lty = 3)
    good <- is.finite(r$competitor_ioc) & is.finite(r$target_ioc)
    graphics::segments(r$competitor_ioc[good], y[good], r$target_ioc[good], y[good])
    graphics::points(r$competitor_ioc[good], y[good], pch = 1)
    if (isTRUE(show_legend)) {
      graphics::legend("top", legend = c("Target", "Competitor"),
                       pch = c(19, 1), bty = "n", horiz = TRUE, cex = 0.70)
    }
  }
  invisible(x)
}

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

# The bands of Cicchetti and Sparrow (1981) and Fleiss (1981), which Polit et
# al. (2007) apply to modified kappa: above .74 excellent, .60 to .74 good,
# .40 to .59 fair, and below .40 poor, the word that scheme uses.
.kappa_quality <- function(k) {
  ifelse(
    is.na(k), NA_character_,
    ifelse(k > 0.74, "Excellent",
           ifelse(k >= 0.60, "Good",
                  ifelse(k >= 0.40, "Fair", "Poor")))
  )
}

#' Analyze expert-panel content-validity evidence
#'
#' @description
#' Provides a user-facing workflow for three common expert-panel tasks:
#'
#' * `mode = "relevance"`: bounded ordinal relevance ratings, combining Aiken's
#'   (1980) V (with the score intervals of Penfield and Giacobbi, 2004), the
#'   CVI with the modified kappa of Polit et al. (2007), and a
#'   panel-level agreement coefficient.
#' * `mode = "essentiality"`: Lawshe CVR with exact binomial critical values.
#' * `mode = "congruence"`: the index of item-objective congruence of
#'   Rovinelli and Hambleton (1977), from ratings of +1, 0, or -1 on each
#'   objective (see [ioc()]).
#'
#' Quantitative results are presented as evidence for item review rather than
#' as a substitute for expert comments, construct coverage, comprehensibility,
#' or other parts of a content-validity argument.
#'
#' In essentiality mode an item rated by so few experts that no count could
#' meet the exact test (four or fewer at the default `alpha`) is labeled
#' `"Insufficient panel"`, with status `"Insufficient data"`, as an item rated
#' by fewer than three experts is in relevance mode. It is not `"Review"`,
#' which would say the experts had disagreed.
#'
#' @param data Ratings data. For relevance, a judge-by-item numeric matrix/data
#'   frame. For essentiality, either a judge-by-item 0/1 matrix/data frame or a
#'   vector of essential counts, whose names become the item names when every
#'   count has a distinct name. For congruence, a long data frame accepted by
#'   [ioc()]. In a judge-by-item table every column is an item; a column whose
#'   name looks like a rater ID (such as `expert` or `rater_id`) stops the
#'   function, so remove it, or rename an item that has such a name.
#' @param mode One of `"relevance"`, `"essentiality"`, or `"congruence"`.
#' @param lo,hi Rating-scale bounds for relevance mode. The default is the
#'   1-4 relevance scale; give the bounds for any other scale, because Aiken's
#'   V and the relevance cut both depend on them. The printout states the
#'   scale that was used.
#' @param relevance_cut Lowest rating treated as relevant for CVI. Defaults to
#'   `hi - 1`, e.g., 3 on a 1-4 scale or 4 on a 1-5 scale, and to `hi` on a
#'   two-point scale. The default assumes scale points one unit apart, so set
#'   the cut yourself on any other scale. It must lie above `lo`: at `lo`
#'   every rating would count as relevant.
#' @param N Panel size for essential-count vector input.
#' @param alpha Inferential/CI alpha level.
#' @param na.rm Permit itemwise/cellwise missing ratings where supported.
#' @param target_col In congruence mode, optional column identifying each
#'   item's intended objective. If absent, every item-objective index is
#'   described and no decision is made.
#' @param ioc_cut In congruence mode, the lowest index of item-objective
#'   congruence that counts as congruent. The default, .70, is the criterion
#'   Rovinelli and Hambleton (1977) applied. Turner and Carlson (2003) extend
#'   the index to items written for more than one objective, which this
#'   package does not do.
#' @param proportion_ci Interval method for I-CVI in relevance mode:
#'   `"wilson"` (default), `"agresti_coull"`, `"exact"`, or `"none"`. The
#'   interval uses the same `alpha` as Aiken's V. See `ci` in [cvi()] for the
#'   methods and the evidence for each.
#' @param agreement Panel-level agreement coefficient for relevance mode:
#'   `"krippendorff"` (default), `"ac1"`, or `"none"`. Krippendorff's alpha
#'   (Hayes & Krippendorff, 2007), which Zapf et al. (2016) recommend for
#'   ordinal or incomplete ratings, uses the relevance ratings at
#'   `agreement_level`; Gwet's AC1 uses the
#'   relevant/not-relevant decision. See [panel_agreement()] for the evidence
#'   behind each, including why AC1 is never the default. Panels with fewer
#'   than two experts or two items report no agreement coefficient.
#' @param agreement_level Measurement level for Krippendorff's alpha:
#'   `"ordinal"` (default), `"nominal"`, or `"interval"`. Ignored for AC1.
#' @param agreement_B Bootstrap resamples for the agreement interval; `0` skips
#'   the interval.
#' @param seed Optional seed that makes the agreement interval reproducible.
#'   The random-number stream of the session is left as it was.
#' @param legacy Print the earlier published rules beside the decision, for
#'   comparison, in relevance and essentiality modes. Default `FALSE`. They are
#'   computed either way, stored in `details$earlier_methods`, and never change
#'   the decision; `print(fit, legacy = TRUE)` shows them for any fit.
#'
#' @section Earlier methods, for comparison:
#' The decisions use Lynn's (1986) criterion in relevance mode (beyond the ten
#' experts her table covers, this package's extension holding her 7 of 9) and
#' the exact binomial test (Ayre & Scally, 2014) in essentiality mode. Earlier rules are
#' reported beside them for teaching, and none changes a decision:
#'
#' * **Essentiality.** Lawshe's (1975) Table 1 gives a minimum CVR for 5 to 15
#'   panelists, then every fifth panel size to 40; other sizes have no minimum.
#'   He labeled it a one-tailed test at .05. Wilson et al. (2012) found the
#'   table closer to a two-tailed test and recomputed it by the normal
#'   approximation, `z / sqrt(N)` for a one-tailed test at `alpha` (their
#'   Table 2). An item meets Lawshe's minimum when its essential count reaches
#'   the count that minimum implies: 8 of 9 for his .78, which is .778 printed
#'   to two decimals (Ayre & Scally, 2014). Lawshe's content validity index
#'   for the whole set is the mean CVR of the items his table retains (Lawshe,
#'   1975).
#' * **Relevance.** Fleiss' (1971) kappa, his kappa for many raters and nominal
#'   categories, on the relevant/not-relevant decision. It needs every expert to
#'   rate every item. The printout also notes that S-CVI/Ave is the average
#'   congruency percentage, for which Polit and Beck (2006) recommend .90 or
#'   higher, while calling .80 a reasonable, even strict, criterion for
#'   S-CVI/UA.
#' * **Relevance: the content validity coefficient (Ccv) of Hernández-Nieto
#'   (2002).** For
#'   each item, the mean rating divided by the scale maximum, minus
#'   \eqn{(1/J)^J} for the \eqn{J} judges who rated it; the total is the mean
#'   over items (Hernández-Nieto, 2002, pp. 130-137). The book calls a value
#'   below .80 unacceptable, .80 to .90 satisfactory, and .90 or higher
#'   excellent (p. 120). It is shown beside Aiken's V because it is widely
#'   cited, and it never informs a decision here, because of its shortcomings:
#'   * It uses only each item's mean rating, so it cannot reflect agreement
#'     among judges, although the book presents it as measuring agreement as
#'     well as validity (p. 157). The book's own Table 7 (pp. 148-149) gives
#'     ratings of 1, 3, 4, 5, 2 and of 3, 3, 3, 3, 3 the same .60.
#'   * The correction for chance, \eqn{(1/J)^J}, is derived by setting the
#'     probability that a judge gives a score at random to \eqn{1/J}, one over
#'     the number of judges (p. 136), so it depends on neither the ratings nor
#'     the number of scale points. It is .037 for three judges, .0039 for four,
#'     and .00032 for five, so it barely changes the value.
#'   * On a scale starting at 0, the book's preferred scale (pp. 119-120), Ccv
#'     before the correction equals Aiken's V. On a scale starting at 1 it
#'     cannot fall below 1 divided by the scale maximum (the book notes .33 on
#'     a 1-3 scale, p. 160), so it does not reach 0 even when every judge gives
#'     the lowest rating. A scale starting below 0 has no Ccv.
#'   * The .80 and .90 bands come without derivation, a sampling distribution,
#'     or a test, and the book does not keep to them: its Example 11 labels
#'     .7968 acceptable (p. 155). The package applies the bands as stated on
#'     p. 120.
#'   * The book's tables mix .0032 and .00032 for the five-judge correction.
#'     The package uses the formula, \eqn{(1/5)^5 = .00032}, which reproduces
#'     the book's worked totals where they are consistent (for example,
#'     .33268 and .99968, pp. 146-148).
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
#'   In relevance mode, `results` also holds `cvi_criterion`, the I-CVI that
#'   Lynn's criterion asks of the item's panel size, shown for reading (the
#'   decision compares counts), and `kappa_quality`, the band of `kappa_mod`
#'   in the guidelines of Cicchetti and Sparrow (1981) and Fleiss (1981), as
#'   cited in Polit et al. (2007), who apply them to modified kappa:
#'   `"Excellent"` above .74, `"Good"` from .60 to .74, `"Fair"` from .40 to
#'   .59, and `"Poor"` below .40. The band describes the item and decides
#'   nothing; every item that meets the I-CVI criterion is `"Excellent"`.
#'
#' @references
#' Aiken, L. R. (1980). Content validity and reliability of single items or
#' questionnaires. *Educational and Psychological Measurement, 40*(4), 955–959.
#' \doi{10.1177/001316448004000419}
#'
#' Ayre, C., & Scally, A. J. (2014). Critical values for Lawshe's content
#' validity ratio: Revisiting the original methods of calculation.
#' *Measurement and Evaluation in Counseling and Development, 47*(1), 79–86.
#' \doi{10.1177/0748175613513808}
#'
#' Fleiss, J. L. (1971). Measuring nominal scale agreement among many raters.
#' *Psychological Bulletin, 76*(5), 378–382. \doi{10.1037/h0031619}
#'
#' Hayes, A. F., & Krippendorff, K. (2007). Answering the call for a standard
#' reliability measure for coding data. *Communication Methods and Measures,
#' 1*(1), 77–89. \doi{10.1080/19312450709336664}
#'
#' Hernández-Nieto, R. (2002). *Contributions to statistical analysis: The
#' coefficients of proportional variance, content validity and kappa*.
#' BookSurge.
#'
#' Lawshe, C. H. (1975). A quantitative approach to content validity.
#' *Personnel Psychology, 28*(4), 563–575.
#' \doi{10.1111/j.1744-6570.1975.tb01393.x}
#'
#' Lynn, M. R. (1986). Determination and quantification of content validity.
#' *Nursing Research, 35*(6), 382–385.
#' \doi{10.1097/00006199-198611000-00017}
#'
#' Penfield, R. D., & Giacobbi, P. R., Jr. (2004). Applying a score confidence
#' interval to Aiken's item content-relevance index. *Measurement in Physical
#' Education and Exercise Science, 8*(4), 213–225.
#' \doi{10.1207/s15327841mpee0804_3}
#'
#' Polit, D. F., & Beck, C. T. (2006). The content validity index: Are you
#' sure you know what's being reported? Critique and recommendations.
#' *Research in Nursing & Health, 29*(5), 489–497. \doi{10.1002/nur.20147}
#'
#' Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an acceptable
#' indicator of content validity? Appraisal and recommendations. *Research in
#' Nursing & Health, 30*(4), 459–467. \doi{10.1002/nur.20199}
#'
#' Rovinelli, R. J., & Hambleton, R. K. (1977). On the use of content
#' specialists in the assessment of criterion-referenced test item validity.
#' *Dutch Journal of Educational Research, 2*, 49–60.
#'
#' Turner, R. C., & Carlson, L. (2003). Indexes of item-objective congruence
#' for multidimensional items. *International Journal of Testing, 3*(2),
#' 163–171. \doi{10.1207/S15327574IJT0302_5}
#'
#' Wilson, F. R., Pan, W., & Schumsky, D. A. (2012). Recalculation of the
#' critical values for Lawshe's content validity ratio. *Measurement and
#' Evaluation in Counseling and Development, 45*(3), 197–210.
#' \doi{10.1177/0748175612440286}
#'
#' Zapf, A., Castell, S., Morawietz, L., & Karch, A. (2016). Measuring
#' inter-rater reliability for nominal data: Which coefficients and confidence
#' intervals are appropriate? *BMC Medical Research Methodology, 16*, Article 93.
#' \doi{10.1186/s12874-016-0200-9}
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
                            ioc_cut = 0.70,
                            proportion_ci = c("wilson", "agresti_coull", "exact", "none"),
                            agreement = c("krippendorff", "ac1", "none"),
                            agreement_level = c("ordinal", "nominal", "interval"),
                            agreement_B = 1000,
                            seed = NULL,
                            legacy = FALSE) {
  mode <- .choose(mode)
  proportion_ci <- .choose(proportion_ci)
  agreement <- .choose(agreement)
  agreement_level <- .choose(agreement_level)
  .validate_flag(na.rm, "na.rm")
  .validate_flag(legacy, "legacy")

  if (mode == "relevance") {
    if (!is.numeric(lo) || length(lo) != 1L || !is.finite(lo) ||
        !is.numeric(hi) || length(hi) != 1L || !is.finite(hi) || hi <= lo) {
      stop("`lo` and `hi` must be finite scalars with `hi > lo`.", call. = FALSE)
    }
    if (is.null(relevance_cut)) relevance_cut <- .default_cut(lo, hi)
    .validate_cut(relevance_cut, lo, hi, "relevance_cut")

    .check_no_id_column(data, "data")
    R <- as.matrix(data)
    aiken <- .untag_component(aikens_v(R, lo = lo, hi = hi, ci = "score",
                                       alpha = alpha, na.rm = na.rm))
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
    # Every count that meets the criterion gives modified kappa above .74, the
    # band Polit et al. (2007) read as excellent: the lowest is .76,
    # for 7 of 9. So an item that meets the criterion has strong support, and
    # no weaker tier can occur.
    item$recommendation <- ifelse(
      item$N < 3L,
      "Insufficient panel",
      ifelse(
        !is.na(item$cvi_criterion) & item$A >= .cvi_required_count(item$N),
        "Strong support",
        "Review"
      )
    )
    item$interpretation <- vapply(seq_len(nrow(item)), function(i) {
      if (item$N[i] < 3L) {
        return("Fewer than three usable expert ratings are available; treat the quantitative result as descriptive.")
      }
      if (item$recommendation[i] == "Strong support") {
        return("The item meets the panel-size I-CVI criterion, which also puts its modified kappa above .74; Aiken's V and its score interval quantify relevance level and precision.")
      }
      "The item does not meet the panel-size I-CVI criterion; review wording, relevance, construct coverage, and expert comments before revising or removing it."
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
        # Kept for plot(type = "distribution"), which draws every rating
        # rather than the share that met the cut.
        ratings = R,
        # The ratings' columns are the items in `item`'s order, which is how
        # aikens_v() returns them.
        earlier_methods = .relevance_earlier_methods(
          B, scale, show = legacy, R = R, items = item$item, lo = lo, hi = hi,
          V = item$V
        )
      ),
      legacy = list(scale = scale)
    )
  } else if (mode == "essentiality") {
    if (is.matrix(data) || is.data.frame(data)) .check_no_id_column(data, "data")
    res <- .untag_component(cvr(data, N = N, alpha = alpha, na.rm = na.rm))
    # With very few experts no count can reach alpha (4 of 4 gives p = .0625),
    # so no decision is possible, whatever the experts said.
    too_few <- res$N >= 1L & is.na(res$critical_ne)
    res$recommendation <- ifelse(
      res$N < 1L,
      "Insufficient data",
      ifelse(too_few, "Insufficient panel",
             ifelse(res$pass, "Supported", "Review"))
    )
    res$interpretation <- ifelse(
      res$N < 1L,
      "No usable expert ratings are available.",
      ifelse(
        too_few,
        sprintf(paste("With %s, no count of essential ratings can reach alpha",
                      "= %s, so the exact test cannot decide this item."),
                ifelse(res$N == 1L, "1 expert", paste(res$N, "experts")),
                .fmt_alpha(alpha)),
        ifelse(
          res$pass,
          "Essential ratings meet the exact one-sided binomial criterion for this panel size.",
          "Essential ratings do not meet the exact panel-size criterion; review the item and expert rationale before deciding whether to revise or remove it."
        )
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
    if (!is.numeric(ioc_cut) || length(ioc_cut) != 1L || !is.finite(ioc_cut) ||
        ioc_cut <= 0 || ioc_cut > 1) {
      stop("`ioc_cut` must be one number above 0 and at most 1.", call. = FALSE)
    }
    cells <- .untag_component(ioc(data, na.rm = na.rm))
    if (!is.character(target_col) || length(target_col) != 1L || is.na(target_col) ||
        !nzchar(trimws(target_col))) {
      stop("`target_col` must be one non-empty column name.", call. = FALSE)
    }
    has_target <- target_col %in% names(data)
    items <- unique(cells$item)
    by_item <- split(cells, factor(cells$item, levels = items))

    if (!has_target) {
      # One row per item, as in every item-level workflow: the objective the
      # item matched best. The full item-by-objective table is in
      # `details$cells`, and the printout shows it.
      rows <- lapply(by_item, function(g) {
        best <- if (any(is.finite(g$ioc))) max(g$ioc, na.rm = TRUE) else NA_real_
        data.frame(
          item = g$item[1],
          n_objectives = g$n_objectives[1],
          best_objective = if (is.na(best)) {
            NA_character_
          } else {
            paste(g$objective[g$ioc %in% best], collapse = ", ")
          },
          best_ioc = best,
          recommendation = "Descriptive only",
          interpretation = paste(
            "No target-objective column was supplied, so the index of",
            "item-objective congruence is described for each objective",
            "without a decision."
          ),
          stringsAsFactors = FALSE
        )
      })
      res <- do.call(rbind, rows)
      rownames(res) <- NULL
    } else {
      map <- unique(data.frame(item = .as_label(data$item),
                               target = .as_label(data[[target_col]]),
                               stringsAsFactors = FALSE))
      if (anyNA(map$target) || any(!nzchar(map$target))) {
        stop("Target-objective mappings cannot be missing or empty.", call. = FALSE)
      }
      counts <- table(map$item)
      if (any(counts != 1L)) {
        stop("Each item must map to exactly one target objective.", call. = FALSE)
      }
      invalid_target <- vapply(seq_len(nrow(map)), function(i) {
        !map$target[i] %in% cells$objective[cells$item == map$item[i]]
      }, logical(1))
      if (any(invalid_target)) {
        stop("Target objective is absent from the rated objectives for item(s): ",
             paste(map$item[invalid_target], collapse = ", "), ".", call. = FALSE)
      }

      rows <- lapply(by_item, function(g) {
        target <- map$target[match(g$item[1], map$item)]
        target_row <- g[g$objective == target, , drop = FALSE]
        competitors <- g[g$objective != target, , drop = FALSE]
        target_mean <- target_row$mean_rating
        target_ioc <- target_row$ioc
        # The closest other objective, by the judges' mean rating on it. The
        # margin over it is a description beside the index, not a rule.
        if (nrow(competitors) > 0L && any(is.finite(competitors$mean_rating))) {
          mx <- max(competitors$mean_rating, na.rm = TRUE)
          strongest <- paste(
            competitors$objective[competitors$mean_rating %in% mx],
            collapse = ", "
          )
        } else {
          mx <- NA_real_
          strongest <- NA_character_
        }
        rec <- if (!is.finite(target_mean)) {
          "Insufficient data"
        } else if (!is.finite(target_ioc)) {
          "Target described"
        } else if (target_ioc >= ioc_cut - 1e-9) {
          "Congruent"
        } else {
          "Review"
        }
        data.frame(
          item = g$item[1], target = target,
          n_judges = target_row$n_judges,
          target_ioc = target_ioc,
          target_mean = target_mean,
          strongest_competitor = strongest,
          competitor_mean = mx,
          margin = if (is.finite(target_mean) && is.finite(mx)) target_mean - mx else NA_real_,
          recommendation = rec,
          stringsAsFactors = FALSE
        )
      })
      res <- do.call(rbind, rows)
      rownames(res) <- NULL
      cut_txt <- .fmt(ioc_cut)
      res$interpretation <- vapply(seq_len(nrow(res)), function(i) {
        if (res$recommendation[i] == "Congruent") {
          margin <- res$margin[i]
          # The index averages over every other objective, so with several
          # objectives it can meet the criterion while one rival is rated as
          # high as the target.
          if (is.finite(margin) && margin <= 0) {
            return(sprintf(paste0(
              "The index of item-objective congruence for the intended ",
              "objective is at or above %s, because it averages over the ",
              "other objectives, but the experts rated %s %s the intended ",
              "objective. Review the item's wording against that objective."),
              cut_txt, res$strongest_competitor[i],
              if (margin < 0) "higher than" else "as high as"))
          }
          return(sprintf(paste(
            "The index of item-objective congruence for the intended",
            "objective is at or above %s: the experts matched the item to it",
            "and not to the other objectives."), cut_txt))
        }
        if (res$recommendation[i] == "Target described") {
          return(paste(
            "The item was rated against its intended objective only, so the",
            "index, which compares objectives, cannot be computed. The mean",
            "rating on the objective is described."))
        }
        if (res$recommendation[i] == "Insufficient data") {
          return("The intended objective lacks usable expert ratings.")
        }
        # Below the criterion: say which way it fell short.
        margin <- res$margin[i]
        why <- if (is.finite(margin) && margin < 0) {
          paste0("the experts rated ", res$strongest_competitor[i],
                 " higher than the intended objective")
        } else if (is.finite(margin) && margin == 0) {
          paste0("the experts rated ", res$strongest_competitor[i],
                 " as high as the intended objective")
        } else if (is.finite(res$target_mean[i]) && res$target_mean[i] <= 0) {
          "the experts did not, on balance, match the item to its intended objective"
        } else {
          paste("the experts matched the item to its intended objective but",
                "did not clearly rule out the others")
        }
        sprintf(paste0("The index of item-objective congruence for the ",
                       "intended objective is below %s: %s. Review the item's ",
                       "wording against the objectives and the experts' ",
                       "comments."), cut_txt, why)
      }, character(1))
    }

    res$status <- .workflow_status_from_recommendation(res$recommendation)
    scale <- data.frame(
      n_items = length(items),
      n_supported = sum(res$status == "Supported", na.rm = TRUE),
      n_review = sum(res$status == "Review", na.rm = TRUE),
      n_insufficient = sum(res$status == "Insufficient data", na.rm = TRUE),
      n_descriptive = sum(res$status == "Descriptive only", na.rm = TRUE),
      stringsAsFactors = FALSE
    )
    settings <- list(
      na.rm = isTRUE(na.rm), target_col = if (has_target) target_col else NULL,
      ioc_cut = ioc_cut,
      judge_type = "expert",
      method = "Index of item-objective congruence (Rovinelli & Hambleton, 1977)"
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
# The criterion each item needs is a column when panel sizes differ (`needed`;
# by default, when they differ among the rows given), since then no single
# criterion can be stated beside the table.
.expert_item_table <- function(r, mode, digits, alpha, needed = NULL) {
  if (mode == "relevance") {
    ci <- .ci_label(alpha)
    tab <- data.frame(item = r$item, decision = r$recommendation, experts = r$N,
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
    if (is.null(needed)) {
      needed <- length(unique(r$N[!is.na(r$cvi_criterion)])) > 1L
    }
    if (needed) tab$`I-CVI needed` <- .fmt(r$cvi_criterion, digits)
    return(tab)
  }
  if (mode == "essentiality") {
    tab <- data.frame(item = r$item, decision = r$recommendation,
                      essential = paste0(r$ne, "/", r$N),
                      CVR = .fmt(r$cvr, digits), p = .fmt_p(r$p_value),
                      stringsAsFactors = FALSE, check.names = FALSE)
    # "none" where no count can meet the test at that panel size, and "--"
    # where no expert rated the item, as cvr() prints them.
    if (is.null(needed)) needed <- length(unique(r$N)) > 1L
    if (needed) {
      tab$needed <- ifelse(is.na(r$critical_ne),
                           ifelse(r$N >= 1L, "none", "--"),
                           as.character(r$critical_ne))
    }
    return(tab)
  }
  tab <- data.frame(item = r$item, stringsAsFactors = FALSE, check.names = FALSE)
  if ("target" %in% names(r)) tab$target <- r$target
  tab$decision <- r$recommendation
  if ("target_ioc" %in% names(r) && "target_mean" %in% names(r)) {
    tab$experts <- r$n_judges
    tab$IOC <- .fmt(r$target_ioc, digits)
    tab$mean <- .fmt(r$target_mean, digits)
    tab$competitor <- r$strongest_competitor
    tab$`competitor mean` <- .fmt(r$competitor_mean, digits)
    # A mean lies in [-1, 1]; the margin between two means can reach 2, so it
    # keeps its leading zero (APA 7, Section 6.36).
    tab$margin <- .fmt(r$margin, digits, bounded = FALSE)
  } else if ("best_ioc" %in% names(r)) {
    tab$objectives <- r$n_objectives
    tab$`best objective` <- r$best_objective
    tab$`best IOC` <- .fmt(r$best_ioc, digits)
  } else {
    # An object saved before 1.0, whose columns held the mean ratings.
    num <- names(r)[vapply(r, is.numeric, logical(1))]
    for (col in num) tab[[col]] <- .fmt(r[[col]], digits, bounded = FALSE)
  }
  tab
}

# The item-by-objective table for congruence: every objective each item was
# rated against, with the mean rating and the index.
.ioc_cells_table <- function(cells, digits) {
  data.frame(item = cells$item, objective = cells$objective,
             experts = cells$n_judges, mean = .fmt(cells$mean_rating, digits),
             IOC = .fmt(cells$ioc, digits),
             stringsAsFactors = FALSE, check.names = FALSE)
}

# What the congruence item table's columns hold, for the headings it printed
# (.print_table() returns them): an item rated against its target objective
# alone has no index, competitor or margin, and the console may drop a column
# for width.
.congruence_column_note <- function(shown) {
  has <- function(h) h %in% shown
  out <- c(
    if (has("IOC")) "IOC: the index for the target objective.",
    if (has("mean")) {
      paste("Mean: the experts' mean rating on the target objective",
            "(-1 to 1).")
    },
    if (has("competitor mean")) {
      "Competitor mean: the highest mean on another objective."
    },
    if (has("margin")) {
      paste("Margin: mean less competitor mean, a description beside the",
            "index, not part of its criterion.")
    },
    if (has("best IOC")) {
      paste("Best IOC: the highest index over the item's objectives,",
            "described without a decision.")
    }
  )
  if (length(out)) paste(out, collapse = " ")
}

# A congruence fit saved before 1.0 decided on mean ratings, which it stored
# as `target_ioc`, and holds no index. It cannot be read as the index, so the
# print shows it as it is and everything else asks for a new fit.
.congruence_pre10 <- function(fit) {
  identical(fit$mode, "congruence") && is.data.frame(fit$results) &&
    !any(c("target_mean", "best_ioc") %in% names(fit$results))
}

.congruence_pre10_message <- function() {
  paste("This congruence fit was made before contentvalidR 1.0. Its",
        "`target_ioc` holds a mean rating, not the index of item-objective",
        "congruence, and its decision used the highest mean. Fit it again",
        "with expert_validity() to get the index and its criterion.")
}

# The criterion as text, credited to Rovinelli and Hambleton only when it is
# the .70 they applied.
.ioc_cut_source <- function(cut, digits = 2) {
  if (isTRUE(all.equal(cut, 0.70))) {
    paste0(.fmt(cut, digits), ", the criterion Rovinelli and Hambleton applied")
  } else {
    paste0(.fmt(cut, digits), ", set for this analysis (Rovinelli and Hambleton",
           " applied .70)")
  }
}

# The rating scale and the relevance cut, which decide every relevance index,
# as one header line; NULL for a fit that does not record them.
.relevance_scale_line <- function(st) {
  if (!is.numeric(st$lo) || !is.numeric(st$hi) ||
      !is.numeric(st$relevance_cut)) {
    return(NULL)
  }
  pts <- .fmt_scale(c(st$lo, st$hi, st$relevance_cut))
  sprintf("Scale: %s to %s | Relevant: a rating of %s%s", pts[1], pts[2],
          pts[3], if (st$relevance_cut < st$hi) " or higher" else "")
}

# Lynn's (1986) I-CVI criterion as a sentence, from the panel sizes that have
# one: the count for a single size, or, for several, what the "I-CVI needed"
# column holds (`column`) or the range of sizes when no table shows it.
.relevance_criterion_text <- function(sizes, digits = 2, column = TRUE) {
  sizes <- sort(unique(sizes[!is.na(sizes)]))
  if (!length(sizes)) return(NULL)
  if (length(sizes) == 1L) {
    need <- .cvi_required_count(sizes)
    return(sprintf("I-CVI criterion for %d experts: %d agreeing (%s), %s.",
                   sizes, need, .fmt(need / sizes, digits),
                   if (sizes > 10L) {
                     paste("holding the lowest proportion in Lynn's (1986)",
                           "table, 7 of 9, beyond the ten experts it covers",
                           "(a contentvalidR extension)")
                   } else {
                     "following Lynn (1986)"
                   }))
  }
  paste0(if (column) {
           paste("I-CVI needed: the criterion of Lynn (1986) for each item's",
                 "panel size")
         } else {
           sprintf(paste("I-CVI criterion: the count of Lynn (1986) for each",
                         "item's panel size, from %d to %d experts here"),
                   min(sizes), max(sizes))
         },
         if (any(sizes > 10L)) {
           paste0(", holding her lowest tabled proportion, 7 of 9, beyond the",
                  " ten experts her table covers (a contentvalidR extension)")
         }, ".")
}

# The exact test behind an essentiality decision, stated whatever the panel
# sizes: the count for a single size, what the "Needed" column holds
# (`column`), or the test alone when no count can be stated.
.essentiality_criterion_text <- function(n, critical, alpha, column = FALSE) {
  test <- sprintf(paste("the exact one-sided binomial test at alpha = %s",
                        "(Ayre & Scally, 2014)"), .fmt_alpha(alpha))
  one <- unique(n)
  if (length(one) == 1L && isTRUE(one >= 1L) && !is.na(critical[1])) {
    return(sprintf(paste("With %d experts, an item needs at least %d rating",
                         "it essential for %s."), one, critical[1], test))
  }
  if (column) {
    return(paste0("Needed: the fewest essential ratings that meet, for the ",
                  "item's panel size, ", test,
                  if (any(is.na(critical) & n >= 1L)) {
                    "; none where no count can meet it"
                  }, "."))
  }
  paste0("Each decision uses ", test, ".")
}

# The opening verdict every workflow print shares: how many items met the
# criterion, then the items flagged and the items with too little data, by name.
.expert_verdict <- function(r, mode, alpha = 0.05) {
  n <- nrow(r)
  if (is.null(r$status)) {
    r$status <- .workflow_status_from_recommendation(r$recommendation)
  }
  if (identical(mode, "relevance")) {
    # Meeting the criterion is what Strong support means; that it also puts
    # modified kappa above .74 is said once, beside the criterion.
    met <- sum(r$recommendation %in% "Strong support")
    .say(sprintf("%d of %s %s the I-CVI criterion.", met, .n_noun(n, "item"),
                 if (met == 1L || n == 1L) "meets" else "meet"))
  } else if (identical(mode, "essentiality")) {
    met <- sum(r$status %in% "Supported")
    .say(met, "of", .n_noun(n, "item"),
         if (met == 1L || n == 1L) "meets" else "meet",
         "the exact essentiality criterion.")
  } else if (!"target" %in% names(r)) {
    .say("No target objective was supplied, so the index of item-objective",
         "congruence is described for every item and objective, without a",
         "decision.")
  } else if (all(r$recommendation %in% "Target described")) {
    .say("Every item was rated against its target objective only, so no",
         "index of item-objective congruence could be computed and no item",
         "has a decision.")
  } else {
    met <- sum(r$status %in% "Supported")
    .say(met, "of", .n_noun(n, "item"),
         if (met == 1L || n == 1L) "meets" else "meet",
         "the congruence criterion for the target objective.")
  }
  review <- r$item[r$status %in% "Review"]
  if (length(review)) .say("Flagged for review:", paste(review, collapse = ", "))
  small <- identical(mode, "essentiality") &
    r$recommendation %in% "Insufficient panel"
  thin <- r$item[r$status %in% "Insufficient data" & !small]
  if (length(thin)) {
    .say(if (identical(mode, "relevance")) {
      "Too few experts to judge (fewer than three):"
    } else {
      "Insufficient data:"
    }, paste(thin, collapse = ", "))
  }
  if (any(small)) {
    .say(sprintf(
      paste("Too few experts for the exact test: %s. With %s, no count of",
            "essential ratings can reach alpha = %s, so these items have no",
            "decision."),
      paste(r$item[small], collapse = ", "),
      .or_fewer(max(r$N[small]), "expert"), .fmt_alpha(alpha)
    ))
  }
  invisible(NULL)
}

#' @export
print.contentvalid_expert <- function(x, digits = 2, legacy = NULL, ...) {
  .validate_digits(digits)
  # Checked first, so a bad argument fails before anything is printed.
  show_earlier <- .show_earlier(x, legacy)
  .print_header(x, "Expert-panel analysis")
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
    cat("Items: ", s$n_items, " | Experts per item: ", s$n_experts_min,
        if (s$n_experts_min != s$n_experts_max) paste0(" to ", s$n_experts_max),
        "\n", sep = "")
    # The scale and the cut decide every index below, so they are stated.
    scale_line <- .relevance_scale_line(x$settings)
    if (length(scale_line)) .say(scale_line)
    cat("Mean Aiken's V: ", .fmt(s$mean_Aiken_V, digits),
        " | S-CVI/Ave: ", .fmt(s$S_CVI_Ave, digits),
        " | S-CVI/UA: ", .fmt(s$S_CVI_UA, digits), "\n", sep = "")
    if (show_agreement) {
      .say(.expert_agreement_line(x$details$agreement, digits), exdent = 2)
    }
    missing_line("item")
    cat("\n")
    .expert_verdict(x$results, "relevance")
    cat("\n")
    r <- x$results
    ci <- .ci_label(x$settings$alpha)
    sizes <- unique(r$N[!is.na(r$cvi_criterion)])
    # I-CVI and, with panels of several sizes, the criterion each item was
    # held to decide, so a narrow console never drops them.
    shown <- .print_table(.expert_item_table(r, "relevance", digits,
                                             x$settings$alpha),
                          keep = c(.table_keep, "I-CVI", "I-CVI needed"))
    # Each interval follows its estimate, so a column's estimate says whose
    # interval was printed.
    ci_after <- function(est) {
      i <- match(est, shown)
      !is.na(i) && i < length(shown) && identical(shown[i + 1L], ci)
    }
    v_ci <- ci_after("V")
    cvi_ci <- ci_after("I-CVI")
    cat("\n")
    # The notes explain only the columns the console had room for.
    if (v_ci && cvi_ci) {
      .say("Each", ci, "follows its estimate: Aiken's V has a",
           "Penfield-Giacobbi score interval, and I-CVI the proportion",
           "interval named below.")
    } else if (v_ci) {
      .say("The", ci, "follows Aiken's V: a Penfield-Giacobbi score interval.")
    } else if (cvi_ci) {
      .say("The", ci, "follows I-CVI: the proportion interval named below.")
    }
    # That meeting the criterion puts modified kappa above .74 is said once:
    # here, unless the key's decision legend says it.
    legend_says <- .show_key() && any(r$recommendation %in% "Strong support")
    .say(.relevance_criterion_text(sizes, digits,
                                   column = "I-CVI needed" %in% shown),
         if ("kappa" %in% shown && legend_says) {
           paste("Kappa is modified kappa, read as excellent above .74",
                 "(Polit et al., 2007).")
         } else if ("kappa" %in% shown) {
           paste("Kappa is modified kappa; meeting the I-CVI criterion puts",
                 "it above .74, the band read as excellent (Polit et al.,",
                 "2007).")
         })
    # The interval method is named when that interval is shown, and its
    # absence explained when none was computed.
    if (!is.null(x$settings$proportion_ci) &&
        (cvi_ci || identical(x$settings$proportion_ci, "none"))) {
      .say(.proportion_ci_note(x$settings$proportion_ci, x$settings$alpha))
    }
    if (show_agreement && !is.null(x$details$agreement)) {
      cat("\n")
      note <- .expert_agreement_note(x$details$agreement)
      # A kappa column the console had no room for is not pointed to.
      if (!"kappa" %in% shown) {
        note <- sub(" (the kappa column)", "", note, fixed = TRUE)
      }
      .say(note)
    }
    cat("\n")
    if (any(sizes > 10L)) {
      .say("Lynn's (1986) criteria, extended past ten experts by this package,",
           "are panel-size guidelines, not universal validity cutoffs.")
    } else {
      .say("CVI criteria are published panel-size guidelines, not universal",
           "validity cutoffs.")
    }
  } else if (x$mode == "essentiality") {
    cat("Items: ", d$n_items, " | Experts per item: ", d$n_judges_min,
        if (d$n_judges_min != d$n_judges_max) paste0(" to ", d$n_judges_max),
        "\n", sep = "")
    missing_line("item")
    .say("Method:", x$settings$method)
    cat("\n")
    .expert_verdict(x$results, "essentiality", alpha = x$settings$alpha)
    cat("\n")
    r <- x$results
    # With panels of several sizes the count each item needed is the
    # criterion it was held to, so a narrow console never drops it.
    shown <- .print_table(.expert_item_table(r, "essentiality", digits,
                                             x$settings$alpha),
                          keep = c(.table_keep, "needed"))
    cat("\n")
    .say("Essential: experts rating the item essential, out of those who",
         "rated it.")
    # The test, its alpha and its source are stated whatever the panel sizes.
    .say(.essentiality_criterion_text(r$N, r$critical_ne, x$settings$alpha,
                                      column = "needed" %in% shown))
  } else {
    cat("Items: ", d$n_items, " | Experts per cell: ", d$n_judges_min,
        if (d$n_judges_min != d$n_judges_max) paste0(" to ", d$n_judges_max),
        " | Objectives: ", d$n_objectives, "\n", sep = "")
    missing_line("cell")
    .say("Method:", x$settings$method)
    if (.congruence_pre10(x)) {
      cat("\n")
      .say(.congruence_pre10_message())
      cat("\n")
      print(.untag_component(x$results))
      return(invisible(x))
    }
    cut <- x$settings$ioc_cut
    targeted <- "target_mean" %in% names(x$results)
    if (targeted && is.numeric(cut)) {
      .say(paste0("Criterion: IOC at or above ", .ioc_cut_source(cut, digits),
                  "."))
    }
    if (!is.null(d$n_missing) && isTRUE(d$n_missing > 0L)) {
      .say("With missing ratings the index is computed from the mean rating",
           "on each objective, this package's handling of an incomplete",
           "design.")
    }
    cat("\n")
    .expert_verdict(x$results, "congruence")
    cat("\n")
    r <- x$results
    cells <- if (is.list(x$details)) x$details$cells else NULL
    if (!targeted && is.data.frame(cells) && "mean_rating" %in% names(cells)) {
      # Without targets the item-by-objective table is the result.
      shown <- .print_table(.ioc_cells_table(cells, digits),
                            more = "x$details$cells")
      cat("\n")
      .say("Mean: the experts' mean rating on the objective (-1 to 1). IOC:",
           "half the gap between that mean and their mean on the item's other",
           "objectives.")
    } else {
      shown <- .print_table(.expert_item_table(r, "congruence", digits,
                                               x$settings$alpha))
      cat("\n")
      .say(.congruence_column_note(shown))
    }
    # Each distinct interpretation is printed once, with the items it covers.
    if (targeted && "interpretation" %in% names(r)) {
      cat("\n")
      .say_grouped(r$item, r$interpretation)
    }
  }

  # Congruence has no earlier rule to compare, so it never prints a block.
  em <- if (is.list(x$details)) x$details$earlier_methods else NULL
  if (!is.null(em) && show_earlier) {
    if (x$mode == "relevance") .print_relevance_earlier(em, digits)
    if (x$mode == "essentiality") .print_essentiality_earlier(em, digits)
  }

  if (.show_key()) {
    ci <- .ci_label(x$settings$alpha)
    switch(
      x$mode,
      relevance = .print_key(
        c("S_CVI_Ave", "S_CVI_UA", "V", "I_CVI", "I_CVI_low/I_CVI_high",
          "kappa_mod",
          if (show_agreement) {
            if (identical(x$settings$agreement, "ac1")) "agreement_ac1" else "agreement"
          }),
        headings = c("S-CVI/Ave", "S-CVI/UA", "V", "I-CVI",
                     paste(ci, "after I-CVI"), "kappa",
                     if (show_agreement) "Panel agreement"),
        # The facts and the panel line are always shown; a table column only
        # when the console had room for it (the I-CVI interval is the second
        # interval column).
        shown = c("S-CVI/Ave", "S-CVI/UA", "Panel agreement",
                  intersect(c("V", "I-CVI", "kappa"), shown),
                  if (cvi_ci) paste(ci, "after I-CVI"))),
      essentiality = .print_key("cvr", headings = "CVR", shown = shown),
      # An item rated against its target alone has no index to explain.
      .print_key(c("ioc", "ioc"), headings = c("IOC", "best IOC"),
                 shown = shown)
    )
    .print_decision_legend(x$results$recommendation, x$mode)
    .print_key_footer()
  }

  .closing(c("Use quantitative indices alongside expert comments, construct",
             "coverage, and comprehensibility review."),
           "See summary(x) for the flagged items and content_report(x) for an APA table.")
  invisible(x)
}

#' @export
summary.contentvalid_expert <- function(object, ...) {
  out <- .workflow_summary_core(object)
  out$mode <- object$mode
  out$agreement <- if (is.list(object$details)) object$details$agreement else NULL
  # What the criterion needs depends on every item's panel size, not only on
  # the flagged items', so the sizes are kept for the printout.
  r <- object$results
  out$criterion <- if (identical(object$mode, "relevance") &&
                       all(c("N", "cvi_criterion") %in% names(r))) {
    list(sizes = unique(r$N[!is.na(r$cvi_criterion)]))
  } else if (identical(object$mode, "essentiality") &&
             all(c("N", "critical_ne") %in% names(r))) {
    list(n = r$N, critical = r$critical_ne)
  }
  # Compatibility aliases retained for pre-v0.0.6 user code.
  out$scale <- out$scale_summary
  out$flagged <- out$reviewed_items
  class(out) <- c("summary.contentvalid_expert", "summary.contentvalid_workflow")
  out
}

#' @export
print.summary.contentvalid_expert <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  .print_header(x, "Expert-panel analysis")
  cat("Mode: ", x$mode, "\n", sep = "")
  relevance <- identical(x$mode, "relevance")
  essentiality <- identical(x$mode, "essentiality")
  if (relevance) {
    scale_line <- .relevance_scale_line(x$settings)
    if (length(scale_line)) .say(scale_line)
  }
  passing <- switch(x$mode, relevance = "Strong support",
                    essentiality = "Supported", congruence = "Congruent",
                    "Supported")
  cat(passing, ": ", x$n_supported, " of ", x$n_items, " | Review: ",
      x$n_review, " of ", x$n_items, sep = "")
  # Two reasons for no decision, counted apart: too few experts for any count
  # to meet the exact test, and no usable rating at all.
  n_few <- if (identical(x$mode, "essentiality")) {
    sum(x$flagged$recommendation %in% "Insufficient panel")
  } else {
    0L
  }
  if (n_few > 0L) cat(" | Too few experts: ", n_few, sep = "")
  if (x$n_insufficient - n_few > 0L) {
    cat(" | Insufficient data: ", x$n_insufficient - n_few, sep = "")
  }
  if (x$n_descriptive > 0L) cat(" | Descriptive only: ", x$n_descriptive, sep = "")
  cat("\n")
  # The criterion the decisions applied, as the printout states it: with
  # panels of several sizes, the flagged table gives each item's.
  cr <- x$criterion
  several <- FALSE
  if (relevance && length(cr$sizes)) {
    several <- length(cr$sizes) > 1L
    .say(.relevance_criterion_text(cr$sizes, digits, column = FALSE))
  } else if (essentiality && length(cr$n)) {
    several <- length(unique(cr$n)) > 1L
    .say(.essentiality_criterion_text(cr$n, cr$critical, x$settings$alpha))
  } else if (identical(x$mode, "congruence") &&
             "target_mean" %in% names(x$flagged) &&
             is.numeric(x$settings$ioc_cut)) {
    .say(paste0("Criterion: IOC at or above ",
                .ioc_cut_source(x$settings$ioc_cut, digits), "."))
  }
  if (relevance && is.character(x$settings$agreement) &&
      !identical(x$settings$agreement, "none")) {
    .say(.expert_agreement_line(x$agreement, digits), exdent = 2L)
  }
  f <- x$flagged
  if (nrow(f) == 0L) {
    .end_section()
    cat("\n")
    .say("No items were flagged by the workflow's quantitative review rules.")
  } else {
    .section("Flagged")
    shown <- .print_table(
      .expert_item_table(f, x$mode, digits, x$settings$alpha,
                         needed = if (relevance || essentiality) several),
      keep = c(.table_keep, "I-CVI", "I-CVI needed", "needed", "IOC"),
      more = "x$flagged"
    )
    cat("\n")
    if (identical(x$mode, "congruence") && "target_mean" %in% names(f)) {
      .say(.congruence_column_note(shown))
    } else {
      .say(switch(x$mode,
                  relevance = paste0(
                    "V = Aiken's content validity coefficient; I-CVI = ",
                    "item-level content validity index",
                    if ("I-CVI needed" %in% shown) {
                      paste("; I-CVI needed = the I-CVI the criterion asks of",
                            "the item's panel size")
                    }, "."),
                  essentiality = paste0(
                    "CVR = content validity ratio",
                    if ("needed" %in% shown) {
                      paste0("; Needed = the fewest essential ratings that ",
                             "meet the test for the item's panel size",
                             if (any(is.na(f$critical_ne) & f$N >= 1L)) {
                               ", none where no count can meet it"
                             })
                    }, "."),
                  "IOC = index of item-objective congruence."))
    }
    if ("interpretation" %in% names(f)) {
      cat("\n")
      .say_flagged(f$item, f$recommendation, f$interpretation)
    }
  }
  .closing(c("These summaries support, but do not replace, qualitative content",
             "review."),
           "See summary(x)$reviewed_items for the flagged items as a data frame.")
  invisible(x)
}

#' Plot expert-panel content-validity results
#'
#' @description
#' Draws a mode-specific evidence plot, one row per item with the first item at
#' the top. Relevance mode shows Aiken's V and I-CVI side by side, each with its
#' interval, and a dashed line at the I-CVI criterion when every item had the
#' same number of experts. Essentiality mode shows each observed CVR against the
#' CVR the exact test needs for that item. Congruence mode shows each item's
#' index for its intended objective against the `ioc_cut` criterion (dashed),
#' with the experts' mean ratings on the target and on the closest other
#' objective in gray, when a target mapping is available; an item with no
#' index is marked with a cross.
#'
#' In relevance mode, `type = "distribution"` draws every expert's rating as
#' a diverging stacked bar (Heiberger & Robbins, 2014), split at the relevance
#' cut. Ratings below the cut extend left and ratings at or above it extend
#' right, so the right-hand length is the item's I-CVI, read against the dashed
#' criterion line. The number beside each bar is that I-CVI, and the symbol is
#' the decision the fit made. It shows what the index cannot: two items with
#' the same I-CVI, one rated relevant with 4s and the other with 3s.
#'
#' @param x A `contentvalid_expert` object.
#' @param show_legend Logical; draw the compact plot key. Default `TRUE`.
#' @param type `"item"` (default) for the evidence plot described above, or
#'   `"distribution"` for the rating distributions (relevance mode only).
#' @param apa Used by `type = "distribution"`. `TRUE` (default) draws in gray,
#'   with darker meaning a higher rating, as an APA figure is printed. `FALSE`
#'   draws ratings below the cut in brown and ratings at or above it in teal,
#'   a colorblind-safe scheme for slides and posters. The symbol beside each
#'   bar carries the decision either way. The `"item"` plot is always gray.
#' @param labels For `type = "distribution"`, one label per rating category,
#'   lowest first, such as `c("Not relevant", "Somewhat relevant", "Quite
#'   relevant", "Highly relevant")`. Defaults to `"Rated 1"`, `"Rated 2"`,
#'   and so on.
#' @param ... Additional graphical arguments passed to [graphics::plot()].
#' @return The input object invisibly.
#' @references
#' Heiberger, R. M., & Robbins, N. B. (2014). Design of diverging stacked bar
#' charts for Likert scales and other applications. *Journal of Statistical
#' Software, 57*(5), 1–32. \doi{10.18637/jss.v057.i05}
#' @examples
#' relevance <- matrix(
#'   c(4,4,4,3, 4,4,3,4, 3,4,4,4, 4,3,4,4),
#'   nrow = 4,
#'   dimnames = list(NULL, paste0("Item", 1:4))
#' )
#' fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
#'                        agreement = "none")
#' plot(fit)
#' plot(fit, type = "distribution")
#' plot(fit, type = "distribution", apa = FALSE)
#' plot(expert_validity(c(10, 8, 6), mode = "essentiality", N = 12))
#' @export
plot.contentvalid_expert <- function(x, show_legend = TRUE,
                                     type = c("item", "distribution"),
                                     apa = TRUE, labels = NULL, ...) {
  .validate_flag(show_legend, "show_legend")
  .validate_flag(apa, "apa")
  type <- .choose(type)
  if (type == "distribution") {
    if (!identical(x$mode, "relevance")) {
      stop("The distribution view draws relevance ratings, so it needs a ",
           "relevance-mode fit.", call. = FALSE)
    }
    R <- x$details$ratings
    if (is.null(R)) {
      stop("This fit does not carry its ratings, because it was made by an ",
           "earlier version of contentvalidR. Fit it again to draw the ",
           "distribution view.", call. = FALSE)
    }
    r <- x$results
    crit <- unique(r$cvi_criterion[is.finite(r$cvi_criterion)])
    .plot_rating_distribution(
      rounds = list(R), items = as.character(r$item), lo = x$settings$lo,
      hi = x$settings$hi, cut = x$settings$relevance_cut,
      criterion = if (length(crit) == 1L) crit else NULL,
      status = list(stats::setNames(r$status, r$item)), value_label = "I-CVI",
      axis_label = "Share of experts (left: below the relevance cut; right: relevant)",
      labels = labels, apa = apa, show_legend = show_legend, ...
    )
    return(invisible(x))
  }
  # Checked before the margins are set, so a plot that cannot be drawn does
  # not open a graphics device.
  if (.congruence_pre10(x)) stop(.congruence_pre10_message(), call. = FALSE)
  if (identical(x$mode, "congruence") &&
      !all(c("target_ioc", "target_mean") %in% names(x$results))) {
    stop("Congruence plots require a target-objective mapping.", call. = FALSE)
  }
  op <- .plot_margins(list(...))
  on.exit(graphics::par(op), add = TRUE)
  r <- x$results
  n <- nrow(r)
  # The first item is drawn at the top, in the order of the results table.
  y <- rev(seq_len(n))
  top <- n + 0.5
  ci_label <- .ci_label(if (is.numeric(x$settings$alpha)) x$settings$alpha else 0.05)

  if (x$mode == "relevance") {
    .plot_with(list(x = NA, xlim = c(0, 1), ylim = c(0.5, n + 1.35), xaxt = "n",
                    yaxt = "n", xlab = "Relevance (0 to 1)", ylab = ""), list(...))
    .axis_bounded(1, at = seq(0, 1, 0.25))
    graphics::axis(2, at = y, labels = r$item, las = 1)
    # The I-CVI criterion depends on the panel size, so it is drawn as a line
    # only when every item had the same number of experts.
    crit <- unique(r$cvi_criterion[is.finite(r$cvi_criterion)])
    one_crit <- length(crit) == 1L
    if (one_crit) .vline_below(crit, 0.5, top, lty = 2)
    # Aiken's V just above each item's row, I-CVI just below, each with its
    # interval, so the two never hide each other.
    yv <- y + 0.15
    yc <- y - 0.15
    v_ci <- is.finite(r$ci_low) & is.finite(r$ci_high)
    graphics::segments(r$ci_low[v_ci], yv[v_ci], r$ci_high[v_ci], yv[v_ci])
    c_ci <- is.finite(r$I_CVI_low) & is.finite(r$I_CVI_high)
    graphics::segments(r$I_CVI_low[c_ci], yc[c_ci], r$I_CVI_high[c_ci], yc[c_ci])
    graphics::points(r$V, yv, pch = 19)
    graphics::points(r$I_CVI, yc, pch = 1)
    if (isTRUE(show_legend)) {
      need <- if (one_crit) {
        size <- unique(r$N[is.finite(r$cvi_criterion)])
        if (length(size) == 1L) {
          sprintf("I-CVI criterion (%d of %d%s)", .cvi_required_count(size), size,
                  if (size > 10L) ", package extension" else "")
        } else "I-CVI criterion"
      }
      .legend_top(c("Aiken's V", "I-CVI", ci_label, need),
                  c(19, 1, NA, if (one_crit) NA),
                  c(NA, NA, 1, if (one_crit) 2))
    }
  } else if (x$mode == "essentiality") {
    .plot_with(list(x = NA, xlim = c(-1, 1), ylim = c(0.5, n + 1.35), xaxt = "n",
                    yaxt = "n", xlab = "CVR (-1 to 1)", ylab = ""), list(...))
    .axis_bounded(1, at = seq(-1, 1, 0.5))
    graphics::axis(2, at = y, labels = r$item, las = 1)
    .vline_below(0, 0.5, top)
    good <- is.finite(r$critical_cvr) & is.finite(r$cvr)
    # A panel too small for the exact test has no needed value to draw, so its
    # CVR is marked with a cross: no decision, as in the other figures.
    undecided <- is.finite(r$cvr) & !is.finite(r$critical_cvr)
    graphics::segments(r$critical_cvr[good], y[good], r$cvr[good], y[good])
    graphics::points(r$critical_cvr[good], y[good], pch = 1)
    graphics::points(r$cvr[!undecided], y[!undecided], pch = 19)
    graphics::points(r$cvr[undecided], y[undecided], pch = 4)
    if (isTRUE(show_legend)) {
      # Only what was drawn is listed.
      .legend_top(c(if (any(good)) c("Observed CVR", "Needed (exact test)"),
                    if (any(undecided)) "Too few experts to test"),
                  c(if (any(good)) c(19, 1), if (any(undecided)) 4))
    }
  } else {
    # Each item's index against the criterion, with the experts' mean rating
    # on the target objective and on the closest other objective for context.
    cut <- x$settings$ioc_cut
    .plot_with(list(x = NA, xlim = c(-1, 1), ylim = c(0.5, n + 1.35), xaxt = "n",
                    yaxt = "n", xlab = "IOC and mean rating (-1 to 1)",
                    ylab = ""), list(...))
    .axis_bounded(1, at = seq(-1, 1, 0.5))
    graphics::axis(2, at = y, labels = r$item, las = 1)
    .vline_below(0, 0.5, top)
    if (is.numeric(cut)) .vline_below(cut, 0.5, top, lty = 2)
    # The index on the item's row; the two means just below it, so a mean
    # equal to the index stays visible.
    has_ioc <- is.finite(r$target_ioc)
    t_mean <- is.finite(r$target_mean)
    c_mean <- is.finite(r$competitor_mean)
    both <- t_mean & c_mean
    ym <- y - 0.22
    graphics::segments(r$competitor_mean[both], ym[both], r$target_mean[both],
                       ym[both], col = "grey60")
    graphics::points(r$competitor_mean[c_mean], ym[c_mean], pch = 1, col = "grey40")
    graphics::points(r$target_mean[t_mean], ym[t_mean], pch = 2, col = "grey40")
    graphics::points(r$target_ioc[has_ioc], y[has_ioc], pch = 19)
    # An item with no index has no decision: a cross at 0, as in the other
    # expert figures.
    graphics::points(rep(0, sum(!has_ioc)), y[!has_ioc], pch = 4)
    if (isTRUE(show_legend)) {
      crit_lab <- if (is.numeric(cut)) paste0("Criterion (", .fmt(cut), ")")
      .legend_top(c(if (any(has_ioc)) "IOC", if (any(t_mean)) "Mean: target",
                    if (any(c_mean)) "Mean: competitor",
                    if (any(!has_ioc)) "No index",
                    crit_lab),
                  c(if (any(has_ioc)) 19, if (any(t_mean)) 2,
                    if (any(c_mean)) 1, if (any(!has_ioc)) 4,
                    if (is.numeric(cut)) NA),
                  c(if (any(has_ioc)) NA, if (any(t_mean)) NA,
                    if (any(c_mean)) NA, if (any(!has_ioc)) NA,
                    if (is.numeric(cut)) 2),
                  col = c(if (any(has_ioc)) "black", if (any(t_mean)) "grey40",
                          if (any(c_mean)) "grey40", if (any(!has_ioc)) "black",
                          if (is.numeric(cut)) "black"))
    }
  }
  invisible(x)
}

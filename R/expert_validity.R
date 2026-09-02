.cvi_common_criterion <- function(N) {
  out <- rep(NA_real_, length(N))
  out[N >= 3L & N <= 5L] <- 1.00
  out[N >= 6L] <- 0.78
  out
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
#'   V (with Penfield-Giacobbi score intervals) and CVI/modified kappa.
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
#'
#' @return An object of class `contentvalid_expert` and
#'   `contentvalid_workflow`. All flagship workflow objects expose the common
#'   components `results`, `scale_summary`, `settings`, `design`, and `details`.
#'   The historical top-level `scale` component is retained as a compatibility
#'   alias for `scale_summary`. Results include a standardized `status` field
#'   while retaining mode-specific `recommendation` wording.
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
#' Polit, D. F., Beck, C. T., & Owen, S. V. (2007). Is the CVI an acceptable
#' indicator of content validity? *Research in Nursing & Health, 30*(4),
#' 459-467. \doi{10.1002/nur.20199}
#'
#' @examples
#' relevance <- matrix(
#'   c(4,4,4,3, 4,4,3,4, 3,4,4,4, 4,3,4,4),
#'   nrow = 4,
#'   dimnames = list(NULL, paste0("Item", 1:4))
#' )
#' fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4)
#' fit
#' summary(fit)
#' @export
expert_validity <- function(data,
                            mode = c("relevance", "essentiality", "congruence"),
                            lo = 1,
                            hi = 4,
                            relevance_cut = NULL,
                            N = NULL,
                            alpha = 0.05,
                            na.rm = FALSE,
                            target_col = "target_objective") {
  mode <- match.arg(mode)
  .validate_flag(na.rm, "na.rm")

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
    cv <- cvi(B, na.rm = na.rm)

    idx <- match(aiken$item, cv$item_level$item)
    item <- cbind(
      aiken,
      cv$item_level[idx, c("A", "I_CVI", "Pc", "kappa_mod"), drop = FALSE]
    )
    item$cvi_criterion <- .cvi_common_criterion(item$N)
    item$kappa_quality <- .kappa_quality(item$kappa_mod)
    item$ci_width <- item$ci_high - item$ci_low
    item$recommendation <- ifelse(
      item$N < 3L,
      "Insufficient panel",
      ifelse(
        !is.na(item$cvi_criterion) & item$I_CVI >= item$cvi_criterion,
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

    sl <- cv$scale_level
    scale <- data.frame(
      n_items = nrow(item),
      n_experts_min = min(item$N),
      n_experts_max = max(item$N),
      mean_Aiken_V = if (all(is.na(item$V))) NA_real_ else mean(item$V, na.rm = TRUE),
      S_CVI_Ave = sl$S_CVI_Ave,
      S_CVI_UA = sl$S_CVI_UA,
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
      aiken_ci = "Penfield-Giacobbi score"
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
      details = list(cvi = cv),
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
      details = list(),
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

#' @export
print.contentvalid_expert <- function(x, digits = 3, ...) {
  .validate_digits(digits)
  cat("contentvalidR expert-panel analysis\n")
  cat(strrep("-", 35), "\n", sep = "")
  cat("Mode:", x$mode, "\n")
  d <- .workflow_design(x)

  if (x$mode == "relevance") {
    s <- x$scale[1, ]
    cat("Items:", s$n_items,
        "| Experts/item:", paste0(s$n_experts_min, if (s$n_experts_min != s$n_experts_max) paste0("-", s$n_experts_max) else ""), "\n")
    cat("Mean Aiken V:", round(s$mean_Aiken_V, digits),
        "| S-CVI/Ave:", round(s$S_CVI_Ave, digits),
        "| S-CVI/UA:", round(s$S_CVI_UA, digits), "\n")
    cat("Strong support:", s$n_strong_support,
        "| Support:", s$n_support,
        "| Review:", s$n_review, "\n")
    if (!is.null(d$n_missing) && is.finite(d$n_missing) && d$n_missing > 0L) {
      cat("Missing ratings:", d$n_missing, "; effective expert N is used itemwise.\n")
    }
    cat("\n")
    tab <- x$results[c("item", "N", "V", "ci_low", "ci_high", "I_CVI", "kappa_mod", "recommendation")]
    num <- c("V", "ci_low", "ci_high", "I_CVI", "kappa_mod")
    tab[num] <- lapply(tab[num], round, digits = digits)
    print(tab, row.names = FALSE)
    cat("\nCVI thresholds shown by the workflow are common panel-size guidelines, not universal validity cutoffs.\n")
  } else if (x$mode == "essentiality") {
    cat("Items:", d$n_items,
        "| Experts/item:", paste0(d$n_judges_min,
        if (d$n_judges_min != d$n_judges_max) paste0("-", d$n_judges_max) else ""), "\n")
    if (!is.null(d$n_missing) && is.finite(d$n_missing) && d$n_missing > 0L) {
      cat("Missing ratings:", d$n_missing, "; effective expert N is used itemwise.\n")
    }
    cat("Method:", x$settings$method, "\n\n")
    tab <- x$results[c("item", "ne", "N", "cvr", "p_value", "critical_ne", "recommendation")]
    tab[c("cvr", "p_value")] <- lapply(tab[c("cvr", "p_value")], round, digits = digits)
    print(tab, row.names = FALSE)
  } else {
    cat("Items:", d$n_items,
        "| Experts/cell:", paste0(d$n_judges_min,
        if (d$n_judges_min != d$n_judges_max) paste0("-", d$n_judges_max) else ""),
        "| Objectives:", d$n_objectives, "\n")
    if (!is.null(d$n_missing) && is.finite(d$n_missing) && d$n_missing > 0L) {
      cat("Missing ratings:", d$n_missing, "; effective expert N is used cellwise.\n")
    }
    cat("Method:", x$settings$method, "\n\n")
    tab <- x$results
    numeric_cols <- names(tab)[vapply(tab, is.numeric, logical(1))]
    tab[numeric_cols] <- lapply(tab[numeric_cols], round, digits = digits)
    print(tab, row.names = FALSE)
  }

  cat("\nUse quantitative indices alongside expert comments, construct coverage, and comprehensibility review.\n")
  invisible(x)
}

#' @export
summary.contentvalid_expert <- function(object, ...) {
  out <- .workflow_summary_core(object)
  out$mode <- object$mode
  # Compatibility aliases retained for pre-v0.0.6 user code.
  out$scale <- out$scale_summary
  out$flagged <- out$reviewed_items
  class(out) <- c("summary.contentvalid_expert", "summary.contentvalid_workflow")
  out
}

#' @export
print.summary.contentvalid_expert <- function(x, digits = 3, ...) {
  .validate_digits(digits)
  cat("Summary of expert-panel content-validity evidence\n")
  cat(strrep("-", 45), "\n", sep = "")
  cat("Mode:", x$mode, "\n")
  cat("Supported:", x$n_supported, "| Review:", x$n_review)
  if (x$n_insufficient > 0L) cat(" | Insufficient data:", x$n_insufficient)
  if (x$n_descriptive > 0L) cat(" | Descriptive only:", x$n_descriptive)
  cat("\n")
  if (nrow(x$flagged) == 0L) {
    cat("No items were flagged by the workflow's quantitative review rules.\n")
  } else {
    cat(nrow(x$flagged), "item/result row(s) need review or additional usable ratings.\n")
    print(x$flagged, row.names = FALSE)
  }
  cat("\nThese summaries support, but do not replace, qualitative content review.\n")
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

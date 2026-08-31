.rating_scale_summary <- function(results, orbiting_r = NULL, judge_type = "naive") {
  targets <- unique(results$target)
  r_map <- .resolve_rating_orbiting_r(targets, orbiting_r)
  rank <- c("Lack of" = 1L, Weak = 2L, Moderate = 3L, Strong = 4L, `Very Strong` = 5L)

  rows <- lapply(targets, function(target) {
    z <- results[results$target == target, , drop = FALSE]
    n_htc <- sum(!is.na(z$htc))
    n_htd <- sum(!is.na(z$htd))
    mean_htc <- if (n_htc == 0L) NA_real_ else mean(z$htc, na.rm = TRUE)
    mean_htd <- if (n_htd == 0L) NA_real_ else mean(z$htd, na.rm = TRUE)
    r <- unname(r_map[target])
    r_arg <- if (is.na(r)) NULL else r
    htc_i <- interpret_colquitt(mean_htc, "htc", orbiting_r = r_arg, judge_type = judge_type)
    htd_i <- interpret_colquitt(mean_htd, "htd", orbiting_r = r_arg, judge_type = judge_type)
    hs <- htc_i$interpretation[1]
    ds <- htd_i$interpretation[1]
    overall <- if (is.na(hs) || is.na(ds)) NA_character_ else {
      if (unname(rank[hs]) <= unname(rank[ds])) hs else ds
    }

    partial_note <- if (n_htc < nrow(z) || n_htd < nrow(z)) {
      paste0(" Normative averages use ", n_htc, "/", nrow(z), " item(s) for HTC and ",
             n_htd, "/", nrow(z), " item(s) for HTD because of missing/insufficient data.")
    } else ""
    evidence <- if (judge_type == "expert") {
      paste0("HTC/HTD are reported descriptively; Colquitt et al. (2019) normative labels are suppressed for expert judges.", partial_note)
    } else if (is.na(overall)) {
      paste0("Insufficient scale-level rating evidence is available for normative interpretation.", partial_note)
    } else if (overall %in% c("Very Strong", "Strong")) {
      paste0(overall, " normative standing on the weaker of definitional correspondence (HTC) and distinctiveness (HTD).", partial_note)
    } else if (overall == "Moderate") {
      paste0("Generally supportive normative standing, with at least one content-validity dimension in the moderate range; inspect weaker items and construct overlap before finalizing the scale.", partial_note)
    } else {
      paste0(overall, " normative standing on at least one dimension; review item wording, construct boundaries, and orbiting-construct choice and consider re-pretesting revisions.", partial_note)
    }

    data.frame(
      target = target,
      n_items = nrow(z),
      n_htc = n_htc,
      n_htd = n_htd,
      n_retain = sum(z$recommendation == "Retain"),
      n_review = sum(z$recommendation == "Review"),
      n_insufficient = sum(z$recommendation == "Insufficient data"),
      mean_htc = mean_htc,
      htc_strength = hs,
      mean_htd = mean_htd,
      htd_strength = ds,
      overall_strength = overall,
      orbiting_r = r,
      benchmark_set = htc_i$benchmark_set[1],
      evidence = evidence,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Analyze a Hinkin-Tracey construct-rating content-validity pretest
#'
#' @description
#' Provides the recommended user-facing workflow for a fully crossed
#' construct-rating study. Judges rate each item against its intended construct
#' definition and one or more orbiting definitions. `rating_validity()` combines:
#'
#' * Hinkin-Tracey correspondence (HTC),
#' * Hinkin-Tracey distinctiveness (HTD),
#' * one-way repeated-measures ANOVA (with Greenhouse-Geisser correction) for each item, and
#' * planned paired target-versus-orbiting contrasts.
#'
#' Item-level output is diagnostic rather than a coefficient dump: it identifies
#' the strongest competing construct, describes why an item was flagged, and
#' labels statistical screening decisions `"Retain"`, `"Review"`, or
#' `"Insufficient data"`. `"Review"` is not an instruction to delete the item.
#'
#' Colquitt et al. (2019) norms are applied only to **target-scale averages** of
#' HTC and HTD, matching the level at which those empirical benchmarks were
#' constructed. The labels are suppressed for expert judges.
#'
#' @param ratings Long-format rating data.
#' @param item_col,rater_col,construct_col,rating_col Column names.
#' @param target_map Optional named item-to-target mapping.
#' @param target_col Target column used when `target_map` is `NULL`.
#' @param scale_min,scale_max Endpoints of the equally spaced integer rating
#'   scale.
#' @param alpha Significance level for item-level inferential screening.
#' @param adjust Planned-contrast p-value adjustment: `"none"` (historical
#'   planned-comparison logic) or `"holm"`.
#' @param orbiting_r Optional average focal-orbiting correlation. For multiple
#'   target scales, use a named numeric vector keyed by target.
#' @param judge_type Either `"naive"` or `"expert"`. Colquitt normative labels
#'   are not applied to expert-judge data.
#'
#' @return An object of class `contentvalid_rating` containing item-level
#'   `results`, `scale_summary`, full planned `contrasts`, settings, and design
#'   information.
#'
#' @references
#' Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach to
#' content validation. *Organizational Research Methods, 2*(2), 175-186.
#'
#' Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
#' Content validation guidelines: Evaluation criteria for definitional
#' correspondence and definitional distinctiveness. *Journal of Applied
#' Psychology, 104*(10), 1243-1265. \doi{10.1037/apl0000406}
#'
#' @examples
#' set.seed(12)
#' d <- expand.grid(item = c("A1", "A2", "B1"), rater = 1:20,
#'                  construct = c("A", "B", "C"))
#' d$target_construct <- ifelse(d$item == "B1", "B", "A")
#' d$rating <- ifelse(d$construct == d$target_construct,
#'                    pmin(5, pmax(1, round(rnorm(nrow(d), 4.5, .6)))),
#'                    pmin(5, pmax(1, round(rnorm(nrow(d), 2.0, .7)))))
#' fit <- rating_validity(d, scale_min = 1, scale_max = 5)
#' fit
#' summary(fit)
#' @export
rating_validity <- function(ratings,
                            item_col = "item",
                            rater_col = "rater",
                            construct_col = "construct",
                            rating_col = "rating",
                            target_map = NULL,
                            target_col = "target_construct",
                            scale_min = 1,
                            scale_max = 5,
                            alpha = 0.05,
                            adjust = c("none", "holm"),
                            orbiting_r = NULL,
                            judge_type = c("naive", "expert")) {
  adjust <- match.arg(adjust)
  judge_type <- match.arg(judge_type)
  d <- .prepare_rating_data(ratings, item_col, rater_col, construct_col,
                            rating_col, target_map, target_col)
  anchors <- .validate_rating_scale(scale_min, scale_max, d$rating)

  designs <- vapply(split(d, d$item, drop = TRUE), .detect_item_rating_design, character(1))
  between_items <- names(designs)[designs == "between"]
  if (length(between_items)) {
    stop("`rating_validity()` requires a within-judge/fully crossed rating design. Item(s) detected as between-judge: ",
         paste(between_items, collapse = ", "),
         ". Use `anova_content(..., design = \"between\")` only for a genuinely independent-rater design.",
         call. = FALSE)
  }

  htc_out <- htc(ratings, item_col, rater_col, construct_col, rating_col,
                 target_map, target_col, scale_min, scale_max)
  htd_out <- htd(ratings, item_col, rater_col, construct_col, rating_col,
                 target_map, target_col, scale_min, scale_max)
  anova_out <- anova_content(
    ratings,
    item_col = item_col,
    rater_col = rater_col,
    construct_col = construct_col,
    rating_col = rating_col,
    target_map = target_map,
    target_col = target_col,
    design = "within",
    alpha = alpha,
    adjust = adjust
  )

  idx_h <- match(anova_out$item, htc_out$item)
  idx_d <- match(anova_out$item, htd_out$item)
  results <- data.frame(
    item = anova_out$item,
    target = anova_out$target,
    n_raters = anova_out$n_raters,
    n_complete = anova_out$n_complete,
    n_incomplete = anova_out$n_raters - anova_out$n_complete,
    n_constructs = anova_out$n_constructs,
    target_mean = htc_out$target_mean[idx_h],
    target_mean_complete = htd_out$target_mean_complete[idx_d],
    strongest_competitor = htd_out$strongest_competitor[idx_d],
    competitor_mean = htd_out$competitor_mean[idx_d],
    htc = htc_out$htc[idx_h],
    htd = htd_out$htd[idx_d],
    F = anova_out$F,
    df1 = anova_out$df1,
    df2 = anova_out$df2,
    p_omnibus = anova_out$p,
    epsilon_gg = anova_out$epsilon_gg,
    p_value = anova_out$p_screen,
    partial_eta2 = anova_out$partial_eta2,
    min_mean_diff = anova_out$min_mean_diff,
    max_contrast_p = anova_out$max_contrast_p,
    contrast_pass = anova_out$contrast_pass,
    stringsAsFactors = FALSE
  )

  results$recommendation <- vapply(seq_len(nrow(results)), function(i) {
    if (results$n_complete[i] < 2L || is.na(results$htc[i]) || is.na(results$htd[i])) return("Insufficient data")
    if (isTRUE(results$p_value[i] <= alpha) && isTRUE(results$contrast_pass[i])) "Retain" else "Review"
  }, character(1))

  results$issue <- vapply(seq_len(nrow(results)), function(i) {
    if (results$recommendation[i] == "Insufficient data") return("Insufficient complete ratings")
    if (!is.na(results$competitor_mean[i]) && results$competitor_mean[i] > results$target_mean_complete[i]) return("Orbiting construct rated higher")
    if (!is.na(results$competitor_mean[i]) && results$competitor_mean[i] == results$target_mean_complete[i]) return("Target tied with strongest competitor")
    if (is.na(results$p_value[i]) || results$p_value[i] > alpha) return("No omnibus separation detected")
    if (!isTRUE(results$contrast_pass[i])) return("Target highest, planned contrasts incomplete")
    "Supported"
  }, character(1))

  results$interpretation <- vapply(seq_len(nrow(results)), function(i) {
    comp <- if (is.na(results$strongest_competitor[i])) "no identifiable orbiting competitor" else
      paste0("strongest competitor: ", results$strongest_competitor[i])
    if (results$recommendation[i] == "Insufficient data") {
      return("Too few judges have complete ratings across all construct definitions to evaluate this item reliably.")
    }
    if (results$issue[i] == "Orbiting construct rated higher") {
      return(paste0("The intended construct was not rated highest (", comp,
                    "); review wording and the conceptual boundary between the target and orbiting construct."))
    }
    if (results$issue[i] == "Target tied with strongest competitor") {
      return(paste0("The intended construct tied the strongest orbiting construct (", comp,
                    "); the item does not show clear definitional distinctiveness."))
    }
    if (results$recommendation[i] == "Retain") {
      return(paste0("The intended construct is rated higher than all orbiting constructs and all planned contrasts meet the screening criterion (", comp, ")."))
    }
    paste0("The intended construct has the highest mean but the full inferential screening criterion was not met (",
           comp, "); review the weakest target-orbiting comparison before revising or removing the item.")
  }, character(1))

  scale_summary <- .rating_scale_summary(results, orbiting_r = orbiting_r,
                                         judge_type = judge_type)
  contrasts <- attr(anova_out, "contrasts")

  out <- list(
    results = results,
    scale_summary = scale_summary,
    contrasts = contrasts,
    settings = list(
      method = "Hinkin-Tracey within-judge ratings",
      item_inference = "one-way repeated-measures ANOVA (Greenhouse-Geisser corrected omnibus p) plus planned paired target-versus-orbiting contrasts",
      scale_benchmarks = "Colquitt et al. (2019) empirical percentile norms",
      scale_min = scale_min,
      scale_max = scale_max,
      anchors = anchors,
      alpha = alpha,
      adjust = adjust,
      judge_type = judge_type
    ),
    design = list(
      n_items = nrow(results),
      n_raters = length(unique(d$rater)),
      n_target_scales = length(unique(d$target)),
      n_constructs_observed = length(unique(d$construct))
    )
  )
  class(out) <- "contentvalid_rating"
  out
}

#' @export
print.contentvalid_rating <- function(x, digits = 3, ...) {
  r <- x$results
  cat("contentvalidR construct-rating analysis\n")
  cat(strrep("-", 39), "\n", sep = "")
  cat("Items:", x$design$n_items, "| Raters:", x$design$n_raters,
      "| Target scales:", x$design$n_target_scales,
      "| Constructs:", x$design$n_constructs_observed, "\n")
  cat("Design: within-judge ratings | Scale:", x$settings$scale_min, "to", x$settings$scale_max, "\n")
  cat("Item inference:", x$settings$item_inference, "\n")
  cat("Planned-contrast adjustment:", x$settings$adjust, "\n")
  cat("Judges:", x$settings$judge_type, "\n\n")

  n_retain <- sum(r$recommendation == "Retain")
  n_review <- sum(r$recommendation == "Review")
  n_insufficient <- sum(r$recommendation == "Insufficient data")
  cat(n_retain, "item(s) meet the full item-level screening criterion;",
      n_review, "item(s) are flagged for review")
  if (n_insufficient) cat(";", n_insufficient, "item(s) have insufficient data")
  cat(".\n")
  if (n_review) cat("Review:", paste(r$item[r$recommendation == "Review"], collapse = ", "), "\n")
  if (any(r$n_incomplete > 0L)) {
    cat("Incomplete judge profiles occurred for", sum(r$n_incomplete),
        "item-judge profile(s); repeated-measures tests use complete judges itemwise.\n")
  }

  cat("\nItem-level evidence:\n")
  tab <- r[c("item", "target", "n_complete", "strongest_competitor",
             "htc", "htd", "p_value", "max_contrast_p", "recommendation")]
  num <- c("htc", "htd", "p_value", "max_contrast_p")
  tab[num] <- lapply(tab[num], round, digits = digits)
  print(tab, row.names = FALSE)

  cat("\nTarget-scale Colquitt benchmark summary:\n")
  s <- x$scale_summary[c("target", "n_items", "n_htc", "n_htd", "mean_htc", "htc_strength",
                         "mean_htd", "htd_strength", "benchmark_set")]
  s[c("mean_htc", "mean_htd")] <- lapply(s[c("mean_htc", "mean_htd")], round, digits = digits)
  print(s, row.names = FALSE)

  if (x$settings$judge_type == "expert") {
    cat("\nColquitt benchmark labels are suppressed because the analysis was marked as using expert judges.\n")
  } else {
    cat("\nColquitt labels are empirical percentile norms for scale-level HTC/HTD averages, not universal cutoffs.\n")
  }
  cat("'Review' is not an automatic deletion decision. Consider construct definitions, item wording,\n")
  cat("orbiting-construct choice, domain coverage, and qualitative judge feedback.\n")
  invisible(x)
}

#' @export
summary.contentvalid_rating <- function(object, ...) {
  out <- list(
    n_items = nrow(object$results),
    n_retain = sum(object$results$recommendation == "Retain"),
    n_review = sum(object$results$recommendation == "Review"),
    n_insufficient = sum(object$results$recommendation == "Insufficient data"),
    scale_summary = object$scale_summary,
    reviewed_items = object$results[object$results$recommendation != "Retain", , drop = FALSE],
    settings = object$settings
  )
  class(out) <- "summary.contentvalid_rating"
  out
}

#' @export
print.summary.contentvalid_rating <- function(x, digits = 3, ...) {
  cat("Summary of construct-rating content-validity evidence\n")
  cat(strrep("-", 51), "\n", sep = "")
  cat("Retain:", x$n_retain, "of", x$n_items, "item(s)\n")
  cat("Review:", x$n_review, "of", x$n_items, "item(s)\n")
  if (x$n_insufficient) cat("Insufficient data:", x$n_insufficient, "item(s)\n")

  cat("\nTarget-scale evidence:\n")
  s <- x$scale_summary[c("target", "n_items", "n_htc", "n_htd", "n_retain", "n_review",
                         "mean_htc", "htc_strength", "mean_htd", "htd_strength",
                         "overall_strength")]
  s[c("mean_htc", "mean_htd")] <- lapply(s[c("mean_htc", "mean_htd")], round, digits = digits)
  print(s, row.names = FALSE)
  for (i in seq_len(nrow(x$scale_summary))) {
    cat("\n", x$scale_summary$target[i], ": ", x$scale_summary$evidence[i], sep = "")
  }
  cat("\n")

  if (nrow(x$reviewed_items)) {
    cat("\nItems needing attention:\n")
    show <- x$reviewed_items[c("item", "target", "strongest_competitor", "htc", "htd",
                                "p_value", "max_contrast_p", "issue", "recommendation")]
    num <- c("htc", "htd", "p_value", "max_contrast_p")
    show[num] <- lapply(show[num], round, digits = digits)
    print(show, row.names = FALSE)
  } else {
    cat("\nAll analyzed items met the item-level inferential screening criterion.\n")
  }

  cat("\nInterpret these results alongside theory, domain coverage, and qualitative feedback.\n")
  cat("The analysis does not by itself establish comprehensiveness or the full content-validity argument.\n")
  invisible(x)
}

#' Plot Hinkin-Tracey item-level rating evidence
#'
#' @param x A `contentvalid_rating` object.
#' @param metric Either `"htc"` or `"htd"`.
#' @param ... Additional graphical arguments passed to [graphics::plot()].
#'
#' @return The input object invisibly.
#' @export
plot.contentvalid_rating <- function(x, metric = c("htc", "htd"), ...) {
  metric <- match.arg(metric)
  r <- x$results
  y <- r[[metric]]
  pch <- ifelse(r$recommendation == "Retain", 19,
                ifelse(r$recommendation == "Review", 1, 4))
  ylim <- if (metric == "htc") c(0, 1) else c(-1, 1)
  ylab <- if (metric == "htc") "HTC (definitional correspondence)" else
    "HTD (definitional distinctiveness)"
  graphics::plot(seq_along(y), y, xaxt = "n", xlab = "Item", ylab = ylab,
                 ylim = ylim, pch = pch, ...)
  graphics::axis(1, at = seq_along(y), labels = r$item, las = 2)
  if (metric == "htd") graphics::abline(h = 0, lty = 3)
  graphics::legend("bottomright", legend = c("Retain", "Review", "Insufficient data"),
                   pch = c(19, 1, 4), bty = "n")
  invisible(x)
}

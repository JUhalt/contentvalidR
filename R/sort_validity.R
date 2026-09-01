.resolve_orbiting_r <- function(targets, orbiting_r) {
  targets <- as.character(targets)
  if (is.null(orbiting_r)) {
    return(stats::setNames(rep(NA_real_, length(targets)), targets))
  }
  if (!is.numeric(orbiting_r) || any(!is.finite(orbiting_r)) || any(orbiting_r < -1 | orbiting_r > 1)) {
    stop("`orbiting_r` must contain finite correlations between -1 and 1.", call. = FALSE)
  }
  if (length(targets) == 1L && length(orbiting_r) == 1L) {
    return(stats::setNames(as.numeric(orbiting_r), targets))
  }
  if (is.null(names(orbiting_r)) || any(names(orbiting_r) == "")) {
    stop("For multiple target constructs, `orbiting_r` must be a named numeric vector keyed by target construct.", call. = FALSE)
  }
  missing_targets <- setdiff(targets, names(orbiting_r))
  if (length(missing_targets)) {
    stop("`orbiting_r` is missing target construct(s): ", paste(missing_targets, collapse = ", "), call. = FALSE)
  }
  stats::setNames(as.numeric(orbiting_r[targets]), targets)
}

.sort_scale_summary <- function(results, orbiting_r, judge_type) {
  targets <- unique(as.character(results$target))
  r_map <- .resolve_orbiting_r(targets, orbiting_r)
  strength_rank <- c("Lack of" = 1L, Weak = 2L, Moderate = 3L, Strong = 4L, `Very Strong` = 5L)

  rows <- lapply(targets, function(target) {
    z <- results[results$target == target, , drop = FALSE]
    usable <- !is.na(z$psa) & !is.na(z$csv)
    mean_psa <- if (any(usable)) mean(z$psa[usable]) else NA_real_
    mean_csv <- if (any(usable)) mean(z$csv[usable]) else NA_real_
    r <- unname(r_map[target])
    r_arg <- if (is.na(r)) NULL else r

    psa_i <- interpret_colquitt(mean_psa, "psa", orbiting_r = r_arg, judge_type = judge_type)
    csv_i <- interpret_colquitt(mean_csv, "csv", orbiting_r = r_arg, judge_type = judge_type)

    if (!psa_i$applicable || !csv_i$applicable || is.na(mean_psa) || is.na(mean_csv)) {
      evidence <- if (judge_type == "expert") {
        "Colquitt norms not applied because this workflow was marked as using expert judges."
      } else {
        "Insufficient usable item-level statistics for a scale-level benchmark summary."
      }
      weakest <- NA_character_
    } else {
      labels <- c(psa_i$interpretation, csv_i$interpretation)
      weakest <- labels[which.min(strength_rank[labels])]
      if (strength_rank[weakest] >= 4L) {
        evidence <- "Strong normative standing on both definitional correspondence (Psa) and distinctiveness (Csv)."
      } else if (strength_rank[weakest] == 3L) {
        evidence <- "Generally supportive normative standing, with at least one dimension in the moderate range; review weaker items before finalizing."
      } else {
        evidence <- "Limited normative standing on at least one dimension; review item wording and construct overlap and consider re-pretesting revisions."
      }
    }

    if (nrow(z) == 1L && judge_type == "naive") {
      evidence <- paste0(evidence, " Colquitt norms were derived from averages across multi-item scales; interpret this single-item target cautiously.")
    }

    data.frame(
      target = target,
      n_items = nrow(z),
      n_items_usable = sum(usable),
      n_retain = sum(z$recommendation == "Retain"),
      n_review = sum(z$recommendation == "Review"),
      mean_psa = mean_psa,
      psa_strength = psa_i$interpretation,
      mean_csv = mean_csv,
      csv_strength = csv_i$interpretation,
      orbiting_r = if (is.null(r_arg)) NA_real_ else r,
      benchmark_set = psa_i$benchmark_label,
      benchmark_applicable = psa_i$applicable,
      overall_strength = weakest,
      evidence = evidence,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Analyze an item-sort content-validity pretest
#'
#' @description
#' Provides the recommended user-facing workflow for item-sort studies. At the
#' item level, `sort_validity()` combines Anderson and Gerbing's (1991) Psa and
#' Csv statistics with the exact target-count significance test recommended by
#' Howard and Melloy (2016). Items meeting the exact criterion are labeled
#' `"Retain"`; items that do not meet it are labeled `"Review"`, not
#' automatically `"Delete"`.
#'
#' At the target-scale level, Psa and Csv are averaged across items and
#' interpreted using the empirical percentile norms from Colquitt et al. (2019).
#' This mirrors how those norms were constructed. The Colquitt categories are
#' descriptive benchmarks rather than pass/fail rules.
#'
#' @param assignments A data.frame containing item-sort responses.
#' @param item_col,rater_col,assigned_col,target_col Column names for the item,
#'   rater, assigned construct, and intended target construct.
#' @param p0 Null target-assignment probability for the exact binomial test.
#'   Default `0.5`, following Howard and Melloy (2016).
#' @param alpha Significance level. Default `0.05`.
#' @param orbiting_r Optional average correlation between each focal/target
#'   scale and its orbiting scales. For one target, supply one correlation. For
#'   multiple targets, supply a named numeric vector keyed by target construct.
#'   If omitted, the overall Colquitt et al. norms are used.
#' @param judge_type Either `"naive"` (the Anderson-Gerbing/Colquitt design) or
#'   `"expert"`. Colquitt benchmark labels are not applied to expert judges.
#'
#' @return An object of class `contentvalid_sort` with item-level `results`, a
#'   target-level `scale_summary`, design information, and settings. `print()`,
#'   `summary()`, and `plot()` provide user-facing interpretation.
#'
#' @references
#' Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
#' measures in a confirmatory factor analysis with a pretest assessment of
#' their substantive validities. *Journal of Applied Psychology, 76*(5),
#' 732-740. \doi{10.1037/0021-9010.76.5.732}
#'
#' Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task methods:
#' The presentation of a new statistical significance formula and
#' methodological best practices. *Journal of Business and Psychology, 31*(1),
#' 173-186. \doi{10.1007/s10869-015-9404-y}
#'
#' Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
#' Content validation guidelines: Evaluation criteria for definitional
#' correspondence and definitional distinctiveness. *Journal of Applied
#' Psychology, 104*(10), 1243-1265. \doi{10.1037/apl0000406}
#'
#' @examples
#' sort_dat <- data.frame(
#'   item = rep(c("A1", "A2", "A3"), each = 20),
#'   rater = rep(1:20, 3),
#'   target_construct = "A",
#'   assigned_construct = c(
#'     rep("A", 18), rep("B", 2),
#'     rep("A", 16), rep("B", 4),
#'     rep("A", 12), rep("B", 8)
#'   )
#' )
#' fit <- sort_validity(sort_dat)
#' fit
#' summary(fit)
#' @export
sort_validity <- function(assignments,
                          item_col = "item",
                          rater_col = "rater",
                          assigned_col = "assigned_construct",
                          target_col = "target_construct",
                          p0 = 0.5,
                          alpha = 0.05,
                          orbiting_r = NULL,
                          judge_type = c("naive", "expert")) {
  judge_type <- match.arg(judge_type)
  invisible(.critical_target_count(1L, p0 = p0, alpha = alpha))

  psa <- compute_psa(assignments, item_col, rater_col, assigned_col, target_col)
  csv <- compute_csv(assignments, item_col, rater_col, assigned_col, target_col)

  idx <- match(csv$item, psa$item)
  results <- csv
  results$psa <- psa$psa[idx]
  results <- results[c(
    "item", "target", "n_total", "n", "n_missing", "n_target",
    "competitor", "n_other_max", "psa", "csv"
  )]

  tests <- lapply(seq_len(nrow(results)), function(i) {
    if (results$n[i] < 1L) return(NULL)
    csv_binom_test(results$n_target[i], results$n[i], p0 = p0, alpha = alpha)
  })
  results$p_value <- vapply(tests, function(z) if (is.null(z)) NA_real_ else z$p.value, numeric(1))
  results$critical_n_target <- vapply(tests, function(z) if (is.null(z)) NA_integer_ else z$critical_n_target, integer(1))
  results$passes_chance <- vapply(tests, function(z) if (is.null(z)) FALSE else z$passes_chance, logical(1))
  results$recommendation <- ifelse(results$n < 1L, "Insufficient data",
                                   ifelse(results$passes_chance, "Retain", "Review"))
  results$issue <- vapply(seq_len(nrow(results)), function(i) {
    if (results$n[i] < 1L) return("No usable assignments")
    if (results$passes_chance[i]) return("Supported")
    if (!is.na(results$csv[i]) && results$csv[i] < 0) return("Competing construct favored")
    if (!is.na(results$csv[i]) && results$csv[i] == 0) return("Target tied with strongest competitor")
    "Target favored, exact criterion not met"
  }, character(1))
  results$interpretation <- vapply(seq_len(nrow(results)), function(i) {
    competitor <- if (is.na(results$competitor[i])) "no observed competitor" else paste0("strongest competitor: ", results$competitor[i])
    if (results$n[i] < 1L) return("No non-missing assignments are available for this item.")
    if (results$passes_chance[i]) {
      return(paste0("Target assignment meets the exact retention criterion (", competitor,")."))
    }
    if (results$csv[i] < 0) {
      return(paste0("A competing construct received more assignments than the target (", competitor, "); review construct overlap and item wording."))
    }
    paste0("The target was at least as common as any competitor but did not meet the exact retention criterion (", competitor, "); review before deciding whether to revise or remove the item.")
  }, character(1))

  d <- .prepare_sort_assignments(assignments, item_col, rater_col, assigned_col, target_col)
  scale_summary <- .sort_scale_summary(results, orbiting_r = orbiting_r, judge_type = judge_type)

  out <- list(
    results = results,
    scale_summary = scale_summary,
    settings = list(
      item_inference = "Howard-Melloy exact target-count test",
      scale_benchmarks = "Colquitt et al. (2019) empirical percentile norms",
      p0 = p0,
      alpha = alpha,
      judge_type = judge_type
    ),
    design = list(
      n_items = nrow(results),
      n_raters = length(unique(d$rater)),
      n_target_scales = length(unique(d$target)),
      n_constructs_observed = length(unique(c(as.character(d$target), as.character(d$assigned[!is.na(d$assigned)]))))
    )
  )
  class(out) <- "contentvalid_sort"
  out
}

#' @export
print.contentvalid_sort <- function(x, digits = 3, ...) {
  r <- x$results
  n_retain <- sum(r$recommendation == "Retain")
  n_review <- sum(r$recommendation == "Review")
  n_insufficient <- sum(r$recommendation == "Insufficient data")

  cat("contentvalidR item-sort analysis\n")
  cat(strrep("-", 32), "\n", sep = "")
  cat("Items:", x$design$n_items, "| Raters:", x$design$n_raters,
      "| Target scales:", x$design$n_target_scales, "\n")
  cat("Item inference:", x$settings$item_inference,
      sprintf("(p0 = %.2f, alpha = %.3f)", x$settings$p0, x$settings$alpha), "\n")
  cat("Judges:", x$settings$judge_type, "\n\n")

  cat(n_retain, "item(s) meet the exact target-assignment criterion;",
      n_review, "item(s) are flagged for review")
  if (n_insufficient > 0L) cat(";", n_insufficient, "item(s) have insufficient data")
  cat(".\n")
  if (n_review > 0L) cat("Review:", paste(r$item[r$recommendation == "Review"], collapse = ", "), "\n")
  if (n_insufficient > 0L) cat("Insufficient data:", paste(r$item[r$recommendation == "Insufficient data"], collapse = ", "), "\n")
  if (any(r$n_missing > 0L)) {
    cat("Missing assignments:", sum(r$n_missing), "across", sum(r$n_missing > 0L),
        "item(s); effective N is used itemwise.\n")
  }

  cat("\nItem-level evidence:\n")
  tab <- r[c("item", "target", "n", "n_target", "competitor", "psa", "csv", "p_value", "recommendation")]
  tab[c("psa", "csv", "p_value")] <- lapply(tab[c("psa", "csv", "p_value")], round, digits = digits)
  print(tab, row.names = FALSE)

  cat("\nScale-level Colquitt benchmark summary:\n")
  s <- x$scale_summary[c("target", "n_items", "mean_psa", "psa_strength", "mean_csv", "csv_strength", "benchmark_set")]
  s[c("mean_psa", "mean_csv")] <- lapply(s[c("mean_psa", "mean_csv")], round, digits = digits)
  print(s, row.names = FALSE)

  if (x$settings$judge_type == "expert") {
    cat("\nColquitt benchmark labels are not applied because the analysis was marked as using expert judges.\n")
  } else {
    cat("\nColquitt labels are empirical percentile norms derived from scale-level averages,\n")
    cat("not universal cutoffs or automatic scale-retention rules.\n")
  }
  cat("'Review' is not an automatic deletion decision. Use theory, construct-domain coverage,\n")
  cat("item wording, and qualitative judge feedback alongside these statistics.\n")
  invisible(x)
}

#' @export
summary.contentvalid_sort <- function(object, ...) {
  r <- object$results
  out <- list(
    n_items = nrow(r),
    n_retain = sum(r$recommendation == "Retain"),
    n_review = sum(r$recommendation == "Review"),
    n_insufficient = sum(r$recommendation == "Insufficient data"),
    scale_summary = object$scale_summary,
    reviewed_items = r[r$recommendation != "Retain", , drop = FALSE],
    settings = object$settings
  )
  class(out) <- "summary.contentvalid_sort"
  out
}

#' @export
print.summary.contentvalid_sort <- function(x, digits = 3, ...) {
  cat("Summary of item-sort content-validity evidence\n")
  cat(strrep("-", 43), "\n", sep = "")
  cat("Retain:", x$n_retain, "of", x$n_items, "item(s)\n")
  cat("Review:", x$n_review, "of", x$n_items, "item(s)\n")
  if (x$n_insufficient > 0L) cat("Insufficient data:", x$n_insufficient, "item(s)\n")

  cat("\nTarget-scale evidence:\n")
  s <- x$scale_summary[c("target", "n_items", "n_retain", "n_review", "mean_psa", "psa_strength", "mean_csv", "csv_strength", "overall_strength")]
  s[c("mean_psa", "mean_csv")] <- lapply(s[c("mean_psa", "mean_csv")], round, digits = digits)
  print(s, row.names = FALSE)
  for (i in seq_len(nrow(x$scale_summary))) {
    cat("\n", x$scale_summary$target[i], ": ", x$scale_summary$evidence[i], sep = "")
  }
  cat("\n")

  if (nrow(x$reviewed_items) > 0L) {
    cat("\nItems needing attention:\n")
    show <- x$reviewed_items[c("item", "target", "competitor", "psa", "csv", "p_value", "issue", "recommendation")]
    show[c("psa", "csv", "p_value")] <- lapply(show[c("psa", "csv", "p_value")], round, digits = digits)
    print(show, row.names = FALSE)
  } else {
    cat("\nAll analyzed items met the exact target-assignment criterion.\n")
  }

  cat("\nInterpret scale norms and item flags alongside theory, domain coverage, and qualitative feedback.\n")
  cat("This analysis does not by itself establish comprehensiveness or the full content-validity argument.\n")
  invisible(x)
}

#' Plot item-sort evidence
#'
#' @description
#' Draws either the original one-index item plot or a correspondence-distinctiveness
#' evidence map. The map places Psa on the x-axis and Csv on the y-axis so that
#' intended-construct correspondence and distinctiveness can be inspected together.
#' Target-scale means are added as diamonds when available. Colquitt benchmark bands
#' are deliberately not drawn across item points because those norms were developed
#' for scale-level averages rather than individual items.
#'
#' @param x A `contentvalid_sort` object.
#' @param metric Either `"psa"` or `"csv"` for `type = "item"`.
#' @param type Either `"item"` for the original one-index plot or `"map"` for the
#'   correspondence-distinctiveness evidence map.
#' @param label Which item labels to draw on the map: `"review"` (default), `"all"`,
#'   or `"none"`.
#' @param show_legend Logical; draw the compact plot key. Default `TRUE`.
#' @param ... Additional graphical arguments passed to [graphics::plot()].
#'
#' @return The input object invisibly.
#' @export
plot.contentvalid_sort <- function(x,
                                   metric = c("psa", "csv"),
                                   type = c("item", "map"),
                                   label = c("review", "all", "none"),
                                   show_legend = TRUE,
                                   ...) {
  type <- match.arg(type)
  label <- match.arg(label)
  r <- x$results

  if (type == "item") {
    metric <- match.arg(metric)
    y <- r[[metric]]
    pch <- ifelse(r$recommendation == "Retain", 19,
                  ifelse(r$recommendation == "Review", 1, 4))
    ylim <- if (metric == "psa") c(0, 1) else c(-1, 1)
    ylab <- if (metric == "psa") "Psa correspondence" else "Csv distinctiveness"

    graphics::plot(seq_along(y), y, xaxt = "n", xlab = "Item", ylab = ylab,
                   ylim = ylim, pch = pch, ...)
    graphics::axis(1, at = seq_along(y), labels = r$item, las = 2)
    if (metric == "csv") graphics::abline(h = 0, lty = 3)
    if (isTRUE(show_legend)) {
      graphics::legend("bottomleft", legend = c("Retain", "Review", "No data"),
                       pch = c(19, 1, 4), bty = "n", cex = 0.72)
    }
    return(invisible(x))
  }

  ok <- is.finite(r$psa) & is.finite(r$csv)
  pch <- ifelse(r$recommendation == "Retain", 19,
                ifelse(r$recommendation == "Review", 1, 4))
  graphics::plot(r$psa[ok], r$csv[ok], xlim = c(0, 1), ylim = c(-1, 1),
                 xlab = "Psa correspondence",
                 ylab = "Csv distinctiveness",
                 pch = pch[ok], ...)
  graphics::abline(h = 0, lty = 3)

  lab_idx <- switch(
    label,
    review = which(ok & r$recommendation != "Retain"),
    all = which(ok),
    none = integer(0)
  )
  if (length(lab_idx)) {
    graphics::text(r$psa[lab_idx], r$csv[lab_idx], labels = r$item[lab_idx],
                   pos = 3, cex = 0.70, offset = 0.35)
  }

  s <- x$scale_summary
  s_ok <- is.finite(s$mean_psa) & is.finite(s$mean_csv)
  if (any(s_ok)) {
    sx <- s$mean_psa[s_ok]
    sy <- s$mean_csv[s_ok]
    graphics::points(sx, sy, pch = 18, cex = 1.25)
    label_y <- .map_scale_label_y(sx, sy)
    graphics::text(sx, label_y, labels = s$target[s_ok], cex = 0.72)
  }

  if (isTRUE(show_legend)) {
    legend_labels <- c("Retain", "Review")
    legend_pch <- c(19, 1)
    if (any(s_ok)) {
      legend_labels <- c(legend_labels, "Scale mean")
      legend_pch <- c(legend_pch, 18)
    }
    graphics::legend("bottomleft", legend = legend_labels, pch = legend_pch,
                     bty = "n", cex = 0.72)
  }
  invisible(x)
}

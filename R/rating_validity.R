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
    htc_i <- .untag_component(interpret_colquitt(mean_htc, "htc", orbiting_r = r_arg, judge_type = judge_type))
    htd_i <- .untag_component(interpret_colquitt(mean_htd, "htd", orbiting_r = r_arg, judge_type = judge_type))
    hs <- htc_i$interpretation[1]
    ds <- htd_i$interpretation[1]
    overall <- if (is.na(hs) || is.na(ds)) NA_character_ else {
      if (unname(rank[hs]) <= unname(rank[ds])) hs else ds
    }

    partial_note <- if (n_htc < nrow(z) || n_htd < nrow(z)) {
      paste0(" Normative averages use ", n_htc, " of ", .n_noun(nrow(z), "item"),
             " for HTC and ", n_htd, " of ", nrow(z), " for HTD because some",
             " items had missing or insufficient data.")
    } else ""
    evidence <- if (judge_type == "expert") {
      paste0("HTC/HTD are reported descriptively; Colquitt et al. (2019) normative labels are suppressed for expert judges.", partial_note)
    } else if (is.na(overall)) {
      paste0("Insufficient scale-level rating evidence is available for normative interpretation.", partial_note)
    } else {
      band <- sprintf(paste("The weaker of HTC and HTD falls in the %s band of",
                            "published scales (Colquitt et al., 2019)"), overall)
      advice <- if (overall %in% c("Very Strong", "Strong")) {
        "."
      } else if (overall == "Moderate") {
        "; inspect the weaker items and construct overlap before finalizing the scale."
      } else {
        paste("; review item wording, construct boundaries, and the choice of",
              "orbiting constructs, and consider pretesting the revised items again.")
      }
      paste0(band, advice, partial_note)
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
#' @return An object of class `contentvalid_rating` and
#'   `contentvalid_workflow`. All flagship workflow objects expose the common
#'   components `results`, `scale_summary`, `settings`, `design`, and `details`.
#'   Planned contrasts live in `details$contrasts`; the historical top-level
#'   `contrasts` component is retained as a compatibility alias. Item-level
#'   `results` include a standardized `status` field while retaining the
#'   method-specific `recommendation` field.
#'
#' @references
#' Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
#' Content validation guidelines: Evaluation criteria for definitional
#' correspondence and definitional distinctiveness. *Journal of Applied
#' Psychology, 104*(10), 1243–1265. \doi{10.1037/apl0000406}
#'
#' Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach to
#' content validation. *Organizational Research Methods, 2*(2), 175–186.
#' \doi{10.1177/109442819922004}
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
  construct_counts <- vapply(split(d, d$item, drop = TRUE),
                             function(z) length(unique(z$construct)), integer(1))
  too_few <- names(construct_counts)[construct_counts < 2L]
  if (length(too_few)) {
    stop("`rating_validity()` requires at least two construct definitions per item. Check: ",
         paste(too_few, collapse = ", "), ".", call. = FALSE)
  }

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
  # The components print as formatted tables; the workflow's results must not.
  htc_out <- .untag_component(htc_out)
  htd_out <- .untag_component(htd_out)
  anova_out <- .untag_component(anova_out)

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

  results$status <- .workflow_status_from_recommendation(results$recommendation)

  settings <- list(
    method = "Hinkin-Tracey within-judge ratings",
    item_inference = "one-way repeated-measures ANOVA (Greenhouse-Geisser corrected omnibus p) plus planned paired target-versus-orbiting contrasts",
    scale_benchmarks = "Colquitt et al. (2019) empirical percentile norms",
    scale_min = scale_min,
    scale_max = scale_max,
    anchors = anchors,
    alpha = alpha,
    adjust = adjust,
    judge_type = judge_type
  )
  design <- list(
    type = "within-judge construct-rating",
    n_items = nrow(results),
    n_raters = length(unique(d$rater)),
    n_judges_min = if (nrow(results)) min(results$n_complete) else 0L,
    n_judges_max = if (nrow(results)) max(results$n_complete) else 0L,
    n_missing = sum(is.na(d$rating)),
    n_incomplete_profiles = sum(results$n_incomplete),
    n_target_scales = length(unique(d$target)),
    n_constructs_observed = length(unique(d$construct))
  )

  .new_contentvalid_workflow(
    subclass = "contentvalid_rating",
    workflow = "construct-rating",
    results = results,
    scale_summary = scale_summary,
    settings = settings,
    design = design,
    details = list(contrasts = contrasts),
    legacy = list(contrasts = contrasts)
  )
}

#' @export
print.contentvalid_rating <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  r <- x$results
  s <- x$settings
  cat("contentvalidR construct-rating analysis\n")
  cat(strrep("-", 39), "\n", sep = "")
  cat("Items: ", x$design$n_items, " | Judges: ", x$design$n_raters,
      " | Target constructs: ", x$design$n_target_scales,
      " | Constructs rated: ", x$design$n_constructs_observed, "\n", sep = "")
  cat("Design: within-judge ratings on a ", s$scale_min, " to ", s$scale_max,
      " scale\n", sep = "")
  .say(paste0("Test: ", s$item_inference, "; planned-contrast adjustment: ",
              s$adjust, "."))
  .say(if (identical(s$judge_type, "expert")) {
    "Judges: content experts."
  } else {
    "Judges: naive, meaning drawn from the kind of people who will answer the items."
  })
  cat("\n")

  review <- r$item[r$recommendation == "Review"]
  insufficient <- r$item[r$recommendation == "Insufficient data"]
  .say(sum(r$recommendation == "Retain"), "of", nrow(r),
       "items meet the full item-level screening criterion.")
  if (length(review)) .say("Flagged for review:", paste(review, collapse = ", "))
  if (length(insufficient)) {
    .say("Insufficient data:", paste(insufficient, collapse = ", "))
  }
  if (any(r$n_incomplete > 0L)) {
    .say("Incomplete judge profiles occurred for", sum(r$n_incomplete),
         "item-judge profiles; each item's tests use the judges who rated it",
         "against every construct.")
  }

  cat("\nItem-level evidence\n")
  tab <- data.frame(item = r$item, target = r$target,
                    decision = r$recommendation, n = r$n_complete,
                    HTC = .fmt(r$htc, digits), HTD = .fmt(r$htd, digits),
                    `omnibus p` = .fmt_p(r$p_value),
                    `contrast p` = .fmt_p(r$max_contrast_p),
                    competitor = r$strongest_competitor,
                    stringsAsFactors = FALSE, check.names = FALSE)
  .print_table(tab)
  cat("\n")
  .say("n: judges who rated the item against every construct. omnibus p: do",
       "the item's ratings differ across constructs (Greenhouse-Geisser",
       "corrected). contrast p: the largest p among the planned",
       "target-versus-orbiting contrasts, so every contrast is at or below it.")

  sc <- x$scale_summary
  cat("\nTarget-scale Colquitt benchmarks\n")
  # The stored code ("overall") prints as the label the item-sort print uses.
  labels <- vapply(as.character(sc$benchmark_set), function(s) {
    lab <- if (is.na(s)) NULL else .colquitt_norm_label(s)
    if (is.null(lab)) s else lab
  }, character(1), USE.NAMES = FALSE)
  sets <- unique(labels)
  st <- data.frame(target = sc$target, items = sc$n_items,
                   `mean HTC` = .fmt(sc$mean_htc, digits), `HTC level` = sc$htc_strength,
                   `mean HTD` = .fmt(sc$mean_htd, digits), `HTD level` = sc$htd_strength,
                   stringsAsFactors = FALSE, check.names = FALSE)
  # Item counts behind each mean are shown only when some items lacked a value.
  if (any(sc$n_htc != sc$n_items | sc$n_htd != sc$n_items, na.rm = TRUE)) {
    st$`items with HTC` <- sc$n_htc
    st$`items with HTD` <- sc$n_htd
  }
  if (length(sets) > 1L) st$benchmarks <- labels
  .print_table(st)
  if (length(sets) == 1L) .say("Benchmark set:", sets)

  cat("\n")
  if (identical(s$judge_type, "expert")) {
    .say("Colquitt benchmark labels are suppressed because the analysis was",
         "marked as using expert judges.")
  } else {
    .say("Colquitt labels are empirical percentile norms for scale-level HTC",
         "and HTD averages, not universal cutoffs. HTC is an average rating",
         "and HTD is a difference between ratings, so they sit on different",
         "scales with different typical values. A high HTC can be labeled",
         "Weak in the same analysis where a much smaller HTD is labeled Very",
         "Strong. Compare each index against its own benchmark, never against",
         "the other index's number.")
  }

  if (.show_key()) {
    .print_key(c("htc", "htd"), headings = c("HTC", "HTD"))
    .print_decision_legend(x$results$recommendation, "construct-rating")
    .print_key_footer()
  }

  cat("\n")
  .say("'Review' is not an automatic deletion decision. Consider construct",
       "definitions, item wording, orbiting-construct choice, domain coverage,",
       "and qualitative judge feedback.")
  invisible(x)
}

#' @export
summary.contentvalid_rating <- function(object, ...) {
  out <- .workflow_summary_core(object)
  # Compatibility alias retained for pre-v0.0.6 user code.
  out$n_retain <- out$n_supported
  class(out) <- c("summary.contentvalid_rating", "summary.contentvalid_workflow")
  out
}

#' @export
print.summary.contentvalid_rating <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  cat("Summary: construct-rating content-validity evidence\n")
  cat(strrep("-", 51), "\n", sep = "")
  cat("Retain: ", x$n_retain, " of ", x$n_items, " | Review: ", x$n_review,
      " of ", x$n_items, sep = "")
  if (x$n_insufficient) cat(" | Insufficient data: ", x$n_insufficient, sep = "")
  cat("\n")

  cat("\nScale-level evidence\n")
  s <- x$scale_summary
  tab <- data.frame(target = s$target, items = s$n_items,
                    stringsAsFactors = FALSE, check.names = FALSE)
  # Counts of items with an HTC or HTD only matter when some item lacked one.
  if (any(s$n_htc != s$n_items | s$n_htd != s$n_items, na.rm = TRUE)) {
    tab$`with HTC` <- s$n_htc
    tab$`with HTD` <- s$n_htd
  }
  tab$retain <- s$n_retain
  tab$review <- s$n_review
  tab$`mean HTC` <- .fmt(s$mean_htc, digits)
  tab$`HTC level` <- s$htc_strength
  tab$`mean HTD` <- .fmt(s$mean_htd, digits)
  tab$`HTD level` <- s$htd_strength
  tab$overall <- s$overall_strength
  .print_table(tab)
  cat("\n")
  .say_grouped(s$target, s$evidence)

  f <- x$reviewed_items
  if (nrow(f)) {
    cat("\nItems needing attention\n")
    .print_table(data.frame(
      item = f$item, target = f$target, decision = f$recommendation,
      HTC = .fmt(f$htc, digits), HTD = .fmt(f$htd, digits),
      `omnibus p` = .fmt_p(f$p_value), `contrast p` = .fmt_p(f$max_contrast_p),
      competitor = f$strongest_competitor,
      stringsAsFactors = FALSE, check.names = FALSE
    ))
    cat("\n")
    .say_grouped(f$item, f$issue)
  } else {
    cat("\nAll analyzed items met the item-level inferential screening criterion.\n")
  }

  cat("\n")
  .say("Interpret these results alongside theory, domain coverage, and",
       "qualitative feedback. The analysis does not by itself establish",
       "comprehensiveness or the full content-validity argument.")
  invisible(x)
}

#' Plot Hinkin-Tracey rating evidence
#'
#' @description
#' Provides three complementary views of a construct-rating pretest. `"item"`
#' reproduces the original one-index plot, `"map"` places HTC against HTD to show
#' correspondence and distinctiveness jointly, and `"profile"` draws a target-versus-
#' strongest-competitor gap plot on the original response scale, first item at
#' the top, with a dashed gap for items to review. The latter is a
#' graphical analogue of the mean-rating tables used in Hinkin and Tracey (1999).
#'
#' @param x A `contentvalid_rating` object.
#' @param metric Either `"htc"` or `"htd"` for `type = "item"`.
#' @param type One of `"item"`, `"map"`, or `"profile"`.
#' @param label Which item labels to draw on the map: `"review"` (default), `"all"`,
#'   or `"none"`.
#' @param show_legend Logical; draw the compact plot key. Default `TRUE`.
#' @param ... Additional graphical arguments passed to [graphics::plot()].
#'
#' @return The input object invisibly.
#' @examples
#' set.seed(12)
#' d <- expand.grid(item = c("A1", "A2", "B1"), rater = 1:20,
#'                  construct = c("A", "B", "C"))
#' d$target_construct <- ifelse(d$item == "B1", "B", "A")
#' d$rating <- ifelse(d$construct == d$target_construct,
#'                    pmin(5, pmax(1, round(rnorm(nrow(d), 4.5, .6)))),
#'                    pmin(5, pmax(1, round(rnorm(nrow(d), 2.0, .7)))))
#' fit <- rating_validity(d, scale_min = 1, scale_max = 5)
#' plot(fit)
#' plot(fit, type = "map")
#' plot(fit, type = "profile")
#' @export
plot.contentvalid_rating <- function(x,
                                     metric = c("htc", "htd"),
                                     type = c("item", "map", "profile"),
                                     label = c("review", "all", "none"),
                                     show_legend = TRUE,
                                     ...) {
  type <- match.arg(type)
  label <- match.arg(label)
  .validate_flag(show_legend, "show_legend")
  op <- .plot_margins(list(...))
  on.exit(graphics::par(op), add = TRUE)
  r <- x$results
  pch <- .decision_pch(r$recommendation)
  htc_lab <- "HTC: target rating as a share of the scale"
  htd_lab <- "HTD: lead of the target over the other constructs"

  if (type == "item") {
    metric <- match.arg(metric)
    y <- r[[metric]]
    xs <- seq_along(y)
    lo <- if (metric == "htc") 0 else -1
    graphics::plot(xs, y, type = "n", xaxt = "n", yaxt = "n", xlab = "Item",
                   ylab = if (metric == "htc") htc_lab else htd_lab,
                   xlim = c(0.5, length(y) + 0.5),
                   ylim = c(lo, 1 + 0.2 * (1 - lo)), ...)
    graphics::axis(1, at = xs, labels = r$item, las = 2)
    .axis_bounded(2, at = if (metric == "htc") seq(0, 1, 0.25) else seq(-1, 1, 0.5))
    if (metric == "htd") .hline(0)
    has <- is.finite(y)
    graphics::points(xs[has], y[has], pch = pch[has])
    graphics::points(xs[!has], rep(lo, sum(!has)), pch = 4)
    if (isTRUE(show_legend)) {
      leg <- .decision_legend(r$recommendation)
      .legend_top(leg$legend, leg$pch)
    }
    return(invisible(x))
  }

  if (type == "map") {
    ok <- is.finite(r$htc) & is.finite(r$htd)
    graphics::plot(r$htc[ok], r$htd[ok], xlim = c(0, 1), ylim = c(-1, 1.4),
                   xaxt = "n", yaxt = "n", xlab = htc_lab, ylab = htd_lab,
                   pch = pch[ok], ...)
    .axis_bounded(1, at = seq(0, 1, 0.25))
    .axis_bounded(2, at = seq(-1, 1, 0.5))
    .hline(0)

    lab_idx <- switch(
      label,
      review = which(ok & r$recommendation != "Retain"),
      all = which(ok),
      none = integer(0)
    )
    if (length(lab_idx)) {
      graphics::text(r$htc[lab_idx], r$htd[lab_idx], labels = r$item[lab_idx],
                     pos = 3, cex = 0.70, offset = 0.35)
    }

    s <- x$scale_summary
    s_ok <- is.finite(s$mean_htc) & is.finite(s$mean_htd)
    if (any(s_ok)) {
      sx <- s$mean_htc[s_ok]
      sy <- s$mean_htd[s_ok]
      graphics::points(sx, sy, pch = 17, cex = 1.1)
      label_y <- .map_scale_label_y(sx, sy)
      graphics::text(sx, label_y, labels = s$target[s_ok], cex = 0.72)
    }
    if (isTRUE(show_legend)) {
      leg <- .decision_legend(r$recommendation[ok])
      .legend_top(c(leg$legend, if (any(s_ok)) "Scale mean"),
                  c(leg$pch, if (any(s_ok)) 17))
    }
    return(invisible(x))
  }

  # The first item is drawn at the top, in the order of the results table.
  n <- nrow(r)
  y <- rev(seq_len(n))
  xlim <- c(x$settings$scale_min, x$settings$scale_max)
  graphics::plot(NA, xlim = xlim, ylim = c(0.5, n + 1.25), yaxt = "n",
                 xlab = "Mean rating against each definition", ylab = "", ...)
  graphics::axis(2, at = y, labels = r$item, las = 1)
  both <- is.finite(r$target_mean) & is.finite(r$competitor_mean)
  review <- .workflow_status_from_recommendation(r$recommendation) %in% "Review"
  if (any(both)) {
    graphics::segments(r$competitor_mean[both], y[both], r$target_mean[both],
                       y[both], lty = ifelse(review[both], 2, 1))
    graphics::points(r$competitor_mean[both], y[both], pch = 1)
  }
  target_ok <- is.finite(r$target_mean)
  graphics::points(r$target_mean[target_ok], y[target_ok], pch = 19)
  if (isTRUE(show_legend)) {
    gaps <- c(if (any(both & !review)) "Gap (retain)",
              if (any(both & review)) "Gap (review)")
    .legend_top(c("Target", "Top competitor", gaps),
                c(19, 1, rep(NA, length(gaps))),
                c(NA, NA, c(if (any(both & !review)) 1, if (any(both & review)) 2)))
  }
  invisible(x)
}

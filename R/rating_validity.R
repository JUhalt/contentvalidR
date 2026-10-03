.rating_scale_summary <- function(results, orbiting_r = NULL, judge_type = "naive",
                                  n_definitions = NULL) {
  targets <- unique(results$target)
  r_map <- .resolve_rating_orbiting_r(targets, orbiting_r)
  rank <- c("Lack of" = 1L, Weak = 2L, Moderate = 3L, Strong = 4L, `Very Strong` = 5L)

  rows <- lapply(targets, function(target) {
    z <- results[results$target == target, , drop = FALSE]
    # Each scale mean uses the items whose index rests on at least two judges,
    # so one judge cannot move a scale's band. The two indices rest on
    # different judges: HTC on everyone who rated the item against its
    # intended construct, HTD on those who rated it against every construct.
    # An item can therefore be in mean HTC and out of mean HTD.
    in_htc <- !is.na(z$htc) & z$n_target >= 2L
    in_htd <- !is.na(z$htd) & z$n_complete >= 2L
    n_htc <- sum(in_htc)
    n_htd <- sum(in_htd)
    mean_htc <- if (n_htc == 0L) NA_real_ else mean(z$htc[in_htc])
    mean_htd <- if (n_htd == 0L) NA_real_ else mean(z$htd[in_htd])
    r <- unname(r_map[target])
    r_arg <- if (is.na(r)) NULL else r
    htc_i <- .untag_component(interpret_colquitt(mean_htc, "htc", orbiting_r = r_arg, judge_type = judge_type))
    htd_i <- .untag_component(interpret_colquitt(mean_htd, "htd", orbiting_r = r_arg, judge_type = judge_type))
    hs <- htc_i$interpretation[1]
    ds <- htd_i$interpretation[1]
    # Each index is read against its own benchmark, as Colquitt et al. (2019)
    # publish them; they publish no combined band. The advice follows the
    # weaker of the two.
    weaker <- if (is.na(hs) || is.na(ds)) NA_character_ else {
      if (unname(rank[hs]) <= unname(rank[ds])) hs else ds
    }

    partial_note <- if (n_htc < nrow(z) || n_htd < nrow(z)) {
      paste0(" Here ", .rating_means_used(n_htc, n_htd, nrow(z)), "; ",
             .rating_left_out, ".")
    } else ""
    evidence <- if (judge_type == "expert") {
      paste0("HTC/HTD are reported descriptively; Colquitt et al. (2019) normative labels are suppressed for expert judges.", partial_note)
    } else if (is.na(weaker)) {
      paste0("Insufficient scale-level rating evidence is available for normative interpretation.", partial_note)
    } else {
      band <- if (identical(hs, ds)) {
        sprintf(paste("Mean HTC and mean HTD both fall in the %s band of",
                      "published scales (Colquitt et al., 2019)"), hs)
      } else {
        sprintf(paste("Mean HTC falls in the %s band and mean HTD in the %s",
                      "band of published scales (Colquitt et al., 2019)"),
                hs, ds)
      }
      advice <- if (weaker %in% c("Very Strong", "Strong")) {
        "."
      } else if (weaker == "Moderate") {
        "; inspect the weaker items and construct overlap before finalizing the scale."
      } else {
        paste("; review item wording, construct boundaries, and the choice of",
              "orbiting constructs, and consider pretesting the revised items again.")
      }
      paste0(band, advice, .colquitt_definitions_caution(n_definitions),
             partial_note)
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

# Why an item is missing from a scale mean, in the words every place uses.
.rating_left_out <- "an index that rests on fewer than two judges is left out"

# One sentence for each target scale whose means leave items out. Empty when
# every item is in its scale's means.
.rating_partial_means <- function(sc) {
  part <- which(sc$n_htc != sc$n_items | sc$n_htd != sc$n_items)
  vapply(part, function(i) {
    paste0(sc$target[i], ": ",
           .rating_means_used(sc$n_htc[i], sc$n_htd[i], sc$n_items[i]),
           "; ", .rating_left_out, ".")
  }, character(1))
}

# "mean HTC and mean HTD use 2 of 3 items".
.rating_means_used <- function(n_htc, n_htd, n_items) {
  if (n_htc == n_htd) {
    sprintf("mean HTC and mean HTD use %d of %s", n_htc, .n_noun(n_items, "item"))
  } else {
    sprintf("mean HTC uses %d and mean HTD %d of %s", n_htc, n_htd,
            .n_noun(n_items, "item"))
  }
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
#' The rating task is Hinkin and Tracey's (1999). They analyzed it with a
#' one-way ANOVA and Duncan's multiple range test; the repeated-measures form
#' used here, with a planned contrast, follows MacKenzie et al. (2011). See
#' [anova_content()] for which details are published and which are this
#' package's choices.
#'
#' Item-level output is diagnostic rather than a coefficient dump: it identifies
#' the strongest competing construct, describes why an item was flagged, and
#' labels statistical screening decisions `"Retain"`, `"Review"`, or
#' `"Insufficient data"`. An item is labeled `"Retain"` when its omnibus *p*
#' and every contrast *p* are at or below `alpha`. `"Review"` is not an
#' instruction to delete the item. An item with fewer than two judges who
#' rated it against every construct is labeled `"Insufficient data"`.
#'
#' Each target-scale mean uses the items whose index rests on at least two
#' judges, so that one judge cannot move a scale's band. HTC rests on every
#' judge who rated the item against its intended construct (`n_target`); HTD
#' and the tests rest on the judges who rated it against every construct
#' (`n_complete`). An item can therefore count toward mean HTC and not toward
#' mean HTD, and the printout says how many items are behind each mean when
#' some are left out. The two-judge minimum is this package's choice.
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
#' @param adjust Adjustment of the planned-contrast *p* values for the number
#'   of contrasts: `"none"` (the default; each contrast is a planned
#'   comparison) or `"holm"` (conservative).
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
#'   method-specific `recommendation` field. In `results`, `p_value` is the
#'   Greenhouse-Geisser corrected omnibus *p* and `df1_gg` and `df2_gg` are its
#'   degrees of freedom, where a correction applies (see [anova_content()]);
#'   `p_omnibus`, `df1` and `df2` are the uncorrected test; and
#'   `max_contrast_p` is the largest *p* among the planned contrasts, `NA`
#'   when a contrast has no *p*. In `scale_summary`, `n_htc` and `n_htd` count
#'   the items in each mean.
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
#' MacKenzie, S. B., Podsakoff, P. M., & Podsakoff, N. P. (2011). Construct
#' measurement and validation procedures in MIS and behavioral research:
#' Integrating new and existing techniques. *MIS Quarterly, 35*(2), 293–334.
#' \doi{10.2307/23044045}
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
    # Judges who rated the item against its intended construct: what HTC
    # rests on, where HTD and the tests rest on `n_complete`.
    n_target = htc_out$n_target[idx_h],
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
    # The corrected degrees of freedom that go with p_value, the corrected p.
    df1_gg = anova_out$df1_gg,
    df2_gg = anova_out$df2_gg,
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
    if (is.na(results$p_value[i]) || results$p_value[i] > alpha) {
      return(if (isTRUE(results$contrast_pass[i])) {
        "Every contrast met, omnibus test not met"
      } else {
        "No omnibus separation detected"
      })
    }
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
    # Held back by the omnibus test alone: the contrasts are not the place to
    # look, so the advice does not point at them.
    if (isTRUE(results$contrast_pass[i])) {
      return(paste0(
        "Every planned contrast met the screening criterion, but the omnibus ",
        "test, which comes first in the procedure (MacKenzie et al., 2011), ",
        "did not (", comp, "), so the item is not retained.",
        if (results$n_constructs[i] == 2L) {
          paste(" With two constructs the one-sided contrast p is half the",
                "omnibus p, so the contrast can pass where the omnibus test",
                "does not.")
        } else {
          ""
        }
      ))
    }
    paste0("The intended construct has the highest mean but the full inferential screening criterion was not met (",
           comp, "); review the weakest target-orbiting comparison before revising or removing the item.")
  }, character(1))

  scale_summary <- .rating_scale_summary(results, orbiting_r = orbiting_r,
                                         judge_type = judge_type,
                                         n_definitions = length(unique(d$construct)))
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
  # The rule and its alpha, so the decisions below can be checked by hand.
  .say(paste0("Retain: the omnibus p and every contrast p at or below alpha = ",
              .fmt_alpha(s$alpha), ". The contrasts are one-sided: the ",
              "intended construct rated above every other construct."))
  .say(if (identical(s$judge_type, "expert")) {
    "Judges: content experts."
  } else {
    "Judges: naive, meaning drawn from the kind of people who will answer the items."
  })
  cat("\n")

  review <- r$item[r$recommendation == "Review"]
  insufficient <- r$item[r$recommendation == "Insufficient data"]
  # "1 of 3 items meets", "2 of 3 items meet", "0 of 1 item meets": the verb
  # is singular for a count of one or a set of one.
  n_retain <- sum(r$recommendation == "Retain")
  .say(n_retain, "of", .n_noun(nrow(r), "item"),
       if (n_retain == 1L || nrow(r) == 1L) "meets" else "meet",
       "the full item-level screening criterion.")
  if (length(review)) .say("Flagged for review:", paste(review, collapse = ", "))
  if (length(insufficient)) {
    .say("Insufficient data:", paste(insufficient, collapse = ", "))
  }
  if (any(r$n_incomplete > 0L)) {
    n_inc <- sum(r$n_incomplete)
    .say(n_inc, if (n_inc == 1L) "item-judge profile was" else
           "item-judge profiles were",
         "incomplete; each item's tests and HTD use the judges who rated it",
         "against every construct, while HTC uses every rating against the",
         "intended construct.")
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
  .say(paste0(
    "n: judges who rated the item against every construct. omnibus p: do ",
    "the item's ratings differ across constructs (Greenhouse-Geisser ",
    "corrected). contrast p: the largest ",
    if (identical(s$adjust, "holm")) "Holm-adjusted ",
    "p among the planned target-versus-orbiting contrasts, so every contrast ",
    "is at or below it",
    # A contrast with no p fails, and leaves no largest p to report.
    if (anyNA(r$max_contrast_p[r$recommendation != "Insufficient data"])) {
      paste("; NA when a contrast could not be tested because every judge",
            "rated the intended construct and another the same")
    },
    "."))

  sc <- x$scale_summary
  expert <- identical(s$judge_type, "expert")
  # Without benchmarks the table holds means only, and is headed as such.
  cat(if (expert) "\nTarget-scale means\n" else
    "\nTarget-scale Colquitt benchmarks\n")
  # The stored code ("overall") prints as the label the item-sort print uses.
  labels <- vapply(as.character(sc$benchmark_set), function(s) {
    lab <- if (is.na(s)) NULL else .colquitt_norm_label(s)
    if (is.null(lab)) s else lab
  }, character(1), USE.NAMES = FALSE)
  sets <- unique(labels)
  st <- data.frame(target = sc$target, items = sc$n_items,
                   `mean HTC` = .fmt(sc$mean_htc, digits),
                   stringsAsFactors = FALSE, check.names = FALSE)
  # No benchmark is applied for expert judges, so no level columns and no
  # benchmark set are shown for them.
  if (!expert) st$`HTC level` <- sc$htc_strength
  st$`mean HTD` <- .fmt(sc$mean_htd, digits)
  if (!expert) st$`HTD level` <- sc$htd_strength
  if (!expert && length(sets) > 1L) st$benchmarks <- labels
  .print_table(st)
  # How many items are behind each mean, said only when some were left out.
  for (line in .rating_partial_means(sc)) .say(line)
  if (!expert && length(sets) == 1L) .say("Benchmark set:", sets)

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
  # The sentence under the table says how many items are behind each mean
  # when some were left out.
  tab$retain <- s$n_retain
  tab$review <- s$n_review
  tab$`mean HTC` <- .fmt(s$mean_htc, digits)
  tab$`HTC level` <- s$htc_strength
  tab$`mean HTD` <- .fmt(s$mean_htd, digits)
  tab$`HTD level` <- s$htd_strength
  # Expert-judge analyses carry no benchmark labels, so the columns that
  # would hold them are left out. The judge type decides, as in the main
  # print, so a naive-judge analysis keeps the columns even when empty.
  if (identical(x$settings$judge_type, "expert")) {
    tab <- tab[!names(tab) %in% c("HTC level", "HTD level")]
  }
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
#' the top, with a dashed gap for items to review. The profile view is a
#' graphical analogue of the mean-rating tables used in Hinkin and Tracey
#' (1999). Both ends of a gap are means over the judges who rated the item
#' against every construct, the judges the tests use. An item without a
#' decision has no gap: a cross marks its mean target rating.
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
#'
#' @references
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
  lay <- .rating_profile_layout(r)
  n <- nrow(r)
  y <- rev(seq_len(n))
  xlim <- c(x$settings$scale_min, x$settings$scale_max)
  # A key of five entries takes two rows, and the headroom to hold them.
  two_rows <- length(lay$legend) > 4L
  graphics::plot(NA, xlim = xlim,
                 ylim = c(0.5, n + if (two_rows) 1.7 else 1.25), yaxt = "n",
                 xlab = "Mean rating against each definition", ylab = "", ...)
  graphics::axis(2, at = y, labels = r$item, las = 1)
  both <- lay$both
  if (any(both)) {
    graphics::segments(lay$competitor[both], y[both], lay$target[both],
                       y[both], lty = ifelse(lay$review[both], 2, 1))
    graphics::points(lay$competitor[both], y[both], pch = 1)
    graphics::points(lay$target[both], y[both], pch = 19)
  }
  graphics::points(lay$cross[lay$loose], y[lay$loose], pch = 4)
  if (isTRUE(show_legend)) {
    .legend_top(lay$legend, lay$pch, lay$lty,
                ncol = if (two_rows) 3L else NULL)
  }
  invisible(x)
}

# What the profile view draws, worked out apart from the drawing so it can be
# checked: for each item the two ends of its gap, whether a gap is drawn, and
# the key that names only what is drawn.
.rating_profile_layout <- function(r) {
  status <- .workflow_status_from_recommendation(r$recommendation)
  review <- status %in% "Review"
  decided <- status %in% c("Supported", "Review")
  # Both ends of a gap come from the judges with complete ratings, the judges
  # the tests use. The mean over every target rating can sit elsewhere when
  # ratings are missing, and a gap drawn from it could contradict the
  # decision. Objects saved before that column existed fall back to it.
  target <- if ("target_mean_complete" %in% names(r)) {
    r$target_mean_complete
  } else {
    r$target_mean
  }
  both <- decided & is.finite(target) & is.finite(r$competitor_mean)
  # An item without a decision gets no gap: a cross at its target mean, from
  # whatever ratings it has.
  loose <- !both & is.finite(r$target_mean)
  retain_gap <- any(both & !review)
  review_gap <- any(both & review)
  list(
    target = target, competitor = r$competitor_mean, cross = r$target_mean,
    both = both, loose = loose, review = review,
    legend = c(if (any(both)) c("Target", "Top competitor"),
               if (retain_gap) "Gap (retain)", if (review_gap) "Gap (review)",
               if (any(loose)) "No decision"),
    pch = c(if (any(both)) c(19, 1), if (retain_gap) NA, if (review_gap) NA,
            if (any(loose)) 4),
    lty = c(if (any(both)) c(NA, NA), if (retain_gap) 1, if (review_gap) 2,
            if (any(loose)) NA)
  )
}

# A single correlation for a single target may be unnamed. A name is a claim
# about which scale the value belongs to, so a name that is not the target's
# is reported, not ignored.
.check_single_orbiting_r <- function(orbiting_r, target) {
  nm <- names(orbiting_r)
  if (is.null(nm) || is.na(nm)) return(invisible(NULL))
  # Trimmed once, of every kind of space, for both questions: is there a
  # name, and is it the target's.
  nm <- trimws(nm, whitespace = "[\\h\\v]")
  if (!nzchar(nm)) return(invisible(NULL))
  if (!identical(nm, target)) {
    stop("`orbiting_r` is named '", nm, "', but the only target is '", target,
         "'. Name it for that target, or leave it unnamed.", call. = FALSE)
  }
  invisible(NULL)
}

.resolve_orbiting_r <- function(targets, orbiting_r) {
  targets <- as.character(targets)
  if (is.null(orbiting_r)) {
    return(stats::setNames(rep(NA_real_, length(targets)), targets))
  }
  if (!is.numeric(orbiting_r) || any(!is.finite(orbiting_r)) || any(orbiting_r < -1 | orbiting_r > 1)) {
    stop("`orbiting_r` must contain finite correlations between -1 and 1.", call. = FALSE)
  }
  if (length(targets) == 1L && length(orbiting_r) == 1L) {
    .check_single_orbiting_r(orbiting_r, targets)
    return(stats::setNames(as.numeric(orbiting_r), targets))
  }
  # Target labels are trimmed, so the names that key this vector are too.
  if (!is.null(names(orbiting_r))) {
    names(orbiting_r) <- trimws(names(orbiting_r), whitespace = "[\\h\\v]")
  }
  if (is.null(names(orbiting_r)) || any(names(orbiting_r) == "") || anyDuplicated(names(orbiting_r))) {
    stop("For multiple target constructs, `orbiting_r` must be a uniquely named numeric vector keyed by target construct.", call. = FALSE)
  }
  missing_targets <- setdiff(targets, names(orbiting_r))
  if (length(missing_targets)) {
    stop("`orbiting_r` is missing target construct(s): ", paste(missing_targets, collapse = ", "), call. = FALSE)
  }
  stats::setNames(as.numeric(orbiting_r[targets]), targets)
}

.sort_scale_summary <- function(results, orbiting_r, judge_type,
                                n_definitions = NULL, how = "offered") {
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

    psa_i <- .untag_component(interpret_colquitt(mean_psa, "psa", orbiting_r = r_arg, judge_type = judge_type))
    csv_i <- .untag_component(interpret_colquitt(mean_csv, "csv", orbiting_r = r_arg, judge_type = judge_type))

    if (!psa_i$applicable || !csv_i$applicable || is.na(mean_psa) || is.na(mean_csv)) {
      evidence <- if (judge_type == "expert") {
        "Colquitt norms not applied because this workflow was marked as using expert judges."
      } else {
        "Insufficient usable item-level statistics for a scale-level benchmark summary."
      }
      weakest <- NA_character_
    } else {
      # Each index is read against its own benchmark, as Colquitt et al.
      # (2019) publish them; they publish no combined band. The advice
      # follows the weaker of the two.
      labels <- c(psa_i$interpretation, csv_i$interpretation)
      weakest <- labels[which.min(strength_rank[labels])]
      band <- if (identical(labels[1], labels[2])) {
        sprintf(paste("Mean Psa and mean Csv both fall in the %s band of",
                      "published scales (Colquitt et al., 2019)"), labels[1])
      } else {
        sprintf(paste("Mean Psa falls in the %s band and mean Csv in the %s",
                      "band of published scales (Colquitt et al., 2019)"),
                labels[1], labels[2])
      }
      evidence <- if (strength_rank[weakest] >= 4L) {
        paste0(band, ".")
      } else if (strength_rank[weakest] == 3L) {
        paste0(band, "; review the weaker items before finalizing.")
      } else {
        paste0(band, "; review item wording and construct overlap, and consider",
               " pretesting the revised items again.")
      }
      evidence <- paste0(evidence, .colquitt_definitions_caution(n_definitions, how))
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
      n_definitions = if (is.null(n_definitions)) NA_integer_ else as.integer(n_definitions),
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
#' automatically `"Delete"`. An item sorted by so few judges that no count
#' could meet the criterion (four or fewer at the defaults) is labeled
#' `"Insufficient panel"`, with status `"Insufficient data"`.
#'
#' Construct and item labels are compared as text after leading and trailing
#' spaces are removed, so constructs may be coded as numbers, text or factors.
#' Results list the items in the order they first appear in the data, or in
#' the order of the levels when the item column is a factor.
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
#'   Default `0.5`, following Howard and Melloy (2016). It is not the rate
#'   expected from random assignment, which is 1 divided by the number of
#'   constructs. Howard and Melloy describe .5 as arbitrary and lenient, and
#'   suggest a higher value such as .6 or .75, chosen before data collection,
#'   when the alternative constructs are clearly different from the target or
#'   the judges are subject-matter experts.
#' @param alpha Significance level. Default `0.05`.
#' @param orbiting_r Optional average correlation between each focal/target
#'   scale and its orbiting scales. For one target, supply one correlation. For
#'   multiple targets, supply a named numeric vector keyed by target construct.
#'   If omitted, the overall Colquitt et al. norms are used.
#' @param judge_type Either `"naive"` (the Anderson-Gerbing/Colquitt design) or
#'   `"expert"`. Colquitt benchmark labels are not applied to expert judges.
#' @param proportion_ci Interval method for Psa: `"wilson"` (default),
#'   `"agresti_coull"`, `"exact"`, or `"none"`. The interval is two-sided at
#'   level `1 - alpha`, while the exact test is one-sided, so the interval of
#'   an item that just meets the criterion can still include `p0`. The
#'   decision comes from the test, not from the interval. See `ci` in [cvi()]
#'   for the methods and the evidence for each.
#' @param legacy Print the earlier published rules beside the decision, for
#'   comparison. Default `FALSE`. They are computed either way, stored in
#'   `details$earlier_methods`, and never change the decision; `print(fit,
#'   legacy = TRUE)` shows them for any fit.
#' @param n_constructs Optional number of constructs judges could choose among.
#'   It is used by the comparison block's chance-based extension and by the
#'   caution added to the Colquitt et al. (2019) bands when it is not three.
#'   By default it is the number of constructs that appear in the data, which
#'   is too few when judges were offered a construct none of them chose.
#'
#' @return An object of class `contentvalid_sort` and `contentvalid_workflow`.
#'   All flagship workflow objects expose the common components `results`,
#'   `scale_summary`, `settings`, `design`, and `details`. Item-level `results`
#'   include a standardized `status` field while retaining the method-specific
#'   `recommendation` field. `print()`, `summary()`, and `plot()` provide
#'   user-facing interpretation.
#'
#' @section Earlier methods, for comparison:
#' The decision uses the exact test of Howard and Melloy (2016). Two earlier
#' published rules, and one labeled package extension, are reported beside it
#' for teaching, the way a methods text reports eta-squared beside
#' omega-squared. None of them changes the decision:
#'
#' * **Anderson and Gerbing (1991)** judged Csv against a critical value. With
#'   `N` judges, `m` is the fewest target assignments whose one-tailed binomial
#'   probability at .5 falls below `alpha` (their Equation 5), and the critical
#'   Csv is `(2m - N) / N` (Equation 6): .50 for 20 judges at .05. Equation 6
#'   assumes every judge who misses the target picks the same rival. When those
#'   judges spread across several constructs, the leading rival's count falls,
#'   so Csv can reach the critical value with fewer target assignments than
#'   the exact test requires. That is why it is not used for the decision.
#' * **Yao, Wu and Yang (2008)** required Psa and Csv both to reach .30, which
#'   they chose for a four-domain sort, where an item assigned at random lands
#'   in its domain with probability .25 (p. 486). They give no rule for other
#'   numbers of domains.
#' * **A contentvalidR extension, not a published rule.** Yao et al.'s
#'   reasoning carried to `k` constructs as chance plus .05: Psa and Csv both
#'   at least `1/k + .05`, which is their .30 when `k = 4`. It is shown in its
#'   own column, marked as an extension, whenever `k` is not 4. `k` is
#'   `n_constructs` when given, and otherwise the number of constructs in the
#'   data.
#'
#' Csv counts only the single most-chosen rival construct (Anderson & Gerbing,
#' 1991, p. 734). Pooling every other construct into that count instead gives
#' `2 * Psa - 1`, a different index; the printout notes this.
#'
#' @references
#' Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
#' measures in a confirmatory factor analysis with a pretest assessment of
#' their substantive validities. *Journal of Applied Psychology, 76*(5),
#' 732–740. \doi{10.1037/0021-9010.76.5.732}
#'
#' Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
#' Content validation guidelines: Evaluation criteria for definitional
#' correspondence and definitional distinctiveness. *Journal of Applied
#' Psychology, 104*(10), 1243–1265. \doi{10.1037/apl0000406}
#'
#' Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task methods:
#' The presentation of a new statistical significance formula and
#' methodological best practices. *Journal of Business and Psychology, 31*(1),
#' 173–186. \doi{10.1007/s10869-015-9404-y}
#'
#' Yao, G., Wu, C.-H., & Yang, C.-T. (2008). Examining the content validity of
#' the WHOQOL-BREF from respondents' perspective by quantitative methods.
#' *Social Indicators Research, 85*(3), 483–498.
#' \doi{10.1007/s11205-007-9112-8}
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
#'
#' # The same result beside the earlier published rules.
#' print(fit, legacy = TRUE)
#' @export
sort_validity <- function(assignments,
                          item_col = "item",
                          rater_col = "rater",
                          assigned_col = "assigned_construct",
                          target_col = "target_construct",
                          p0 = 0.5,
                          alpha = 0.05,
                          orbiting_r = NULL,
                          judge_type = c("naive", "expert"),
                          proportion_ci = c("wilson", "agresti_coull", "exact", "none"),
                          legacy = FALSE,
                          n_constructs = NULL) {
  judge_type <- match.arg(judge_type)
  proportion_ci <- match.arg(proportion_ci)
  .validate_flag(legacy, "legacy")
  if (!is.null(n_constructs) &&
      (!is.numeric(n_constructs) || length(n_constructs) != 1L ||
       !is.finite(n_constructs) || n_constructs != floor(n_constructs) ||
       n_constructs < 2)) {
    stop("`n_constructs` must be NULL or one whole number of at least 2.",
         call. = FALSE)
  }
  invisible(.critical_target_count(1L, p0 = p0, alpha = alpha))

  psa <- compute_psa(assignments, item_col, rater_col, assigned_col, target_col,
                     ci = proportion_ci, alpha = alpha)
  csv <- compute_csv(assignments, item_col, rater_col, assigned_col, target_col)
  # The components print as formatted tables; the workflow's results must not.
  psa <- .untag_component(psa)
  csv <- .untag_component(csv)

  idx <- match(csv$item, psa$item)
  results <- csv
  results$psa <- psa$psa[idx]
  results$psa_low <- psa$psa_low[idx]
  results$psa_high <- psa$psa_high[idx]
  results <- results[c(
    "item", "target", "n_total", "n", "n_missing", "n_target",
    "competitor", "n_other_max", "psa", "psa_low", "psa_high", "csv"
  )]

  tests <- lapply(seq_len(nrow(results)), function(i) {
    if (results$n[i] < 1L) return(NULL)
    .untag_component(csv_binom_test(results$n_target[i], results$n[i], p0 = p0,
                                    alpha = alpha))
  })
  results$p_value <- vapply(tests, function(z) if (is.null(z)) NA_real_ else z$p.value, numeric(1))
  results$critical_n_target <- vapply(tests, function(z) if (is.null(z)) NA_integer_ else z$critical_n_target, integer(1))
  results$passes_chance <- vapply(tests, function(z) if (is.null(z)) FALSE else z$passes_chance, logical(1))
  # With very few judges no count can reach alpha (4 of 4 gives p = .0625 at
  # p0 = .5), so no decision is possible, whatever the judges did.
  too_few <- results$n >= 1L & is.na(results$critical_n_target)
  results$recommendation <- ifelse(
    results$n < 1L, "Insufficient data",
    ifelse(too_few, "Insufficient panel",
           ifelse(results$passes_chance, "Retain", "Review"))
  )
  results$issue <- vapply(seq_len(nrow(results)), function(i) {
    if (results$n[i] < 1L) return("No usable assignments")
    if (too_few[i]) return("Too few judges for the exact test")
    if (results$passes_chance[i]) return("Supported")
    if (!is.na(results$csv[i]) && results$csv[i] < 0) return("Competing construct favored")
    if (!is.na(results$csv[i]) && results$csv[i] == 0) return("Target tied with strongest competitor")
    "Target favored, exact criterion not met"
  }, character(1))
  results$interpretation <- vapply(seq_len(nrow(results)), function(i) {
    competitor <- if (is.na(results$competitor[i])) "no observed competitor" else paste0("strongest competitor: ", results$competitor[i])
    if (results$n[i] < 1L) return("No non-missing assignments are available for this item.")
    if (too_few[i]) {
      return(sprintf(
        paste("With %s, no count of target assignments can reach alpha = %s,",
              "so the exact test cannot decide this item (%s)."),
        .n_noun(results$n[i], "judge"), .fmt_alpha(alpha), competitor
      ))
    }
    if (results$passes_chance[i]) {
      return(paste0("Target assignment meets the exact retention criterion (", competitor,")."))
    }
    if (results$csv[i] < 0) {
      return(paste0("A competing construct received more assignments than the target (", competitor, "); review construct overlap and item wording."))
    }
    paste0("The target was at least as common as any competitor but did not meet the exact retention criterion (", competitor, "); review before deciding whether to revise or remove the item.")
  }, character(1))

  d <- .prepare_sort_assignments(assignments, item_col, rater_col, assigned_col, target_col)
  # The definitions judges could choose among: what Colquitt et al.'s norms
  # assume to be three.
  n_definitions <- if (!is.null(n_constructs)) {
    as.integer(n_constructs)
  } else {
    length(unique(c(as.character(d$target), as.character(d$assigned[!is.na(d$assigned)]))))
  }
  scale_summary <- .sort_scale_summary(results, orbiting_r = orbiting_r,
                                       judge_type = judge_type,
                                       n_definitions = n_definitions,
                                       how = if (is.null(n_constructs)) "used" else "offered")

  results$status <- .workflow_status_from_recommendation(results$recommendation)

  settings <- list(
    method = "Anderson-Gerbing Psa/Csv with Howard-Melloy exact inference",
    item_inference = "Howard-Melloy exact target-count test",
    scale_benchmarks = "Colquitt et al. (2019) empirical percentile norms",
    p0 = p0,
    alpha = alpha,
    judge_type = judge_type,
    proportion_ci = proportion_ci
  )
  design <- list(
    type = "item-sort",
    n_items = nrow(results),
    n_raters = length(unique(d$rater)),
    n_judges_min = if (nrow(results)) min(results$n) else 0L,
    n_judges_max = if (nrow(results)) max(results$n) else 0L,
    n_missing = sum(results$n_missing),
    n_target_scales = length(unique(d$target)),
    n_constructs_observed = length(unique(c(as.character(d$target), as.character(d$assigned[!is.na(d$assigned)])))),
    # Whether the number of constructs offered was given, or is only what
    # judges used.
    n_constructs_given = !is.null(n_constructs)
  )
  if (!is.null(n_constructs) && n_constructs < design$n_constructs_observed) {
    stop("`n_constructs` is ", n_constructs, ", but the data use ",
         design$n_constructs_observed, " constructs. It should count every ",
         "construct judges could choose.", call. = FALSE)
  }

  .new_contentvalid_workflow(
    subclass = "contentvalid_sort",
    workflow = "item-sort",
    results = results,
    scale_summary = scale_summary,
    settings = settings,
    design = design,
    details = list(
      earlier_methods = .sort_earlier_methods(
        results, alpha,
        if (is.null(n_constructs)) design$n_constructs_observed else
          as.integer(n_constructs),
        show = legacy, constructs_given = !is.null(n_constructs)
      )
    )
  )
}

#' @export
print.contentvalid_sort <- function(x, digits = 2, legacy = NULL, ...) {
  .validate_digits(digits)
  # Checked first, so a bad argument fails before anything is printed.
  show_earlier <- .show_earlier(x, legacy)
  r <- x$results
  s <- x$settings
  review <- r$item[r$recommendation == "Review"]
  insufficient <- r$item[r$recommendation == "Insufficient data"]
  too_few <- r$recommendation == "Insufficient panel"

  cat("contentvalidR item-sort analysis\n")
  cat(strrep("-", 32), "\n", sep = "")
  cat("Items: ", x$design$n_items, " | Judges: ", x$design$n_raters,
      " | Target constructs: ", x$design$n_target_scales, "\n", sep = "")
  .say("Test: ", s$item_inference, " (p0 = ", .fmt(s$p0), ", alpha = ",
       .fmt_alpha(s$alpha), ")", sep = "")
  .say(if (identical(s$judge_type, "expert")) {
    "Judges: content experts."
  } else {
    "Judges: naive, meaning drawn from the kind of people who will answer the items."
  })
  cat("\n")

  met <- sum(r$recommendation == "Retain")
  .say(met, "of", .n_noun(nrow(r), "item"),
       if (met == 1L || nrow(r) == 1L) "meets" else "meet",
       "the exact target-assignment criterion.")
  if (length(review)) .say("Flagged for review:", paste(review, collapse = ", "))
  if (length(insufficient)) {
    .say("Insufficient data:", paste(insufficient, collapse = ", "))
  }
  if (any(too_few)) {
    .say(sprintf(
      paste("Too few judges for the exact test: %s. With %s, no count of",
            "target assignments can reach alpha = %s, so %s no decision."),
      paste(r$item[too_few], collapse = ", "),
      .or_fewer_judges(max(r$n[too_few])), .fmt_alpha(s$alpha),
      if (sum(too_few) == 1L) "this item has" else "these items have"
    ))
  }
  if (any(r$n_missing > 0L)) {
    .say("Missing assignments:", sum(r$n_missing), "across",
         paste0(.n_noun(sum(r$n_missing > 0L), "item"),
                "; each item uses the judges who sorted it."))
  }

  # The decision sits beside the item so a row reads left to right; each
  # interval gets its own column after its estimate, as APA tables do.
  cat("\nItem-level evidence\n")
  ci <- .ci_label(s$alpha)
  tab <- data.frame(item = r$item, target = r$target,
                    decision = r$recommendation,
                    judges = paste0(r$n_target, "/", r$n),
                    Psa = .fmt(r$psa, digits),
                    stringsAsFactors = FALSE, check.names = FALSE)
  # Objects saved before the interval columns existed still print.
  has_ci <- all(c("psa_low", "psa_high") %in% names(r)) && any(!is.na(r$psa_low))
  if (has_ci) tab[[ci]] <- .fmt_ci(r$psa_low, r$psa_high, digits)
  tab$Csv <- .fmt(r$csv, digits)
  tab$competitor <- r$competitor
  tab$p <- .fmt_p(r$p_value)
  .print_table(tab)
  cat("\n")
  .say("judges: assignments to the target construct, out of the judges who",
       "sorted the item.")
  if (!is.null(s$proportion_ci)) .say(.proportion_ci_note(s$proportion_ci, s$alpha))

  sc <- x$scale_summary
  expert <- identical(s$judge_type, "expert")
  # Without benchmarks the table holds means only, and is headed as such.
  cat(if (expert) "\nScale-level means\n" else
    "\nScale-level Colquitt benchmarks\n")
  sets <- unique(sc$benchmark_set)
  st <- data.frame(target = sc$target, items = sc$n_items,
                   `mean Psa` = .fmt(sc$mean_psa, digits),
                   stringsAsFactors = FALSE, check.names = FALSE)
  # No benchmark is applied for expert judges, so no level columns and no
  # benchmark set are shown for them.
  if (!expert) st$`Psa level` <- sc$psa_strength
  st$`mean Csv` <- .fmt(sc$mean_csv, digits)
  if (!expert) st$`Csv level` <- sc$csv_strength
  # A benchmark set shared by every scale is stated once, not on every row.
  if (!expert && length(sets) > 1L) st$benchmarks <- sc$benchmark_set
  .print_table(st)
  if (!expert && length(sets) == 1L) .say("Benchmark set:", sets)
  if (!expert) {
    how <- if (isTRUE(x$design$n_constructs_given)) "offered" else "used"
    for (line in .colquitt_caution_lines(sc, how)) .say(line)
  }

  cat("\n")
  if (identical(s$judge_type, "expert")) {
    .say("Colquitt benchmark labels are not applied because the analysis was",
         "marked as using expert judges.")
  } else {
    .say("Colquitt labels are empirical percentile norms derived from",
         "scale-level averages, not universal cutoffs or automatic",
         "scale-retention rules. They place a scale against published scales;",
         "Psa and Csv sit on different scales, so their labels are not",
         "comparable with each other.")
  }

  if (show_earlier) {
    .print_sort_earlier(x$details$earlier_methods, digits)
  }

  if (.show_key()) {
    .print_key(c("psa", "psa_low/psa_high", "csv", "competitor", "p_value"),
               headings = c("Psa", ci, "Csv", "competitor", "p"))
    .print_decision_legend(x$results$recommendation, "item-sort")
    .print_key_footer()
  }

  cat("\n")
  .say("'Review' is not an automatic deletion decision. Use theory,",
       "construct-domain coverage, item wording, and qualitative judge",
       "feedback alongside these statistics.")
  invisible(x)
}

#' @export
summary.contentvalid_sort <- function(object, ...) {
  out <- .workflow_summary_core(object)
  # Compatibility aliases retained for pre-v0.0.6 user code.
  out$n_retain <- out$n_supported
  class(out) <- c("summary.contentvalid_sort", "summary.contentvalid_workflow")
  out
}

#' @export
print.summary.contentvalid_sort <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  cat("Summary: item-sort content-validity evidence\n")
  cat(strrep("-", 44), "\n", sep = "")
  cat("Retain: ", x$n_retain, " of ", x$n_items, " | Review: ", x$n_review,
      " of ", x$n_items, sep = "")
  # Two different reasons for no decision, counted apart: too few judges for
  # any count to meet the test, and no judge at all.
  n_few <- sum(x$reviewed_items$recommendation %in% "Insufficient panel")
  if (n_few > 0L) cat(" | Too few judges: ", n_few, sep = "")
  if (x$n_insufficient - n_few > 0L) {
    cat(" | Insufficient data: ", x$n_insufficient - n_few, sep = "")
  }
  cat("\n")

  cat("\nScale-level evidence\n")
  s <- x$scale_summary
  tab <- data.frame(
    target = s$target, items = s$n_items, retain = s$n_retain,
    review = s$n_review, `mean Psa` = .fmt(s$mean_psa, digits),
    `Psa level` = s$psa_strength, `mean Csv` = .fmt(s$mean_csv, digits),
    `Csv level` = s$csv_strength,
    stringsAsFactors = FALSE, check.names = FALSE
  )
  # Expert-judge analyses carry no benchmark labels, so the columns that
  # would hold them are left out. The judge type decides, as in the main
  # print.
  if (identical(x$settings$judge_type, "expert")) {
    tab <- tab[!names(tab) %in% c("Psa level", "Csv level")]
  }
  .print_table(tab)
  cat("\n")
  .say_grouped(s$target, s$evidence)

  f <- x$reviewed_items
  if (nrow(f) > 0L) {
    cat("\nItems needing attention\n")
    .print_table(data.frame(
      item = f$item, target = f$target, decision = f$recommendation,
      Psa = .fmt(f$psa, digits), Csv = .fmt(f$csv, digits),
      competitor = f$competitor, p = .fmt_p(f$p_value),
      stringsAsFactors = FALSE, check.names = FALSE
    ))
    cat("\n")
    .say_grouped(f$item, f$issue)
  } else {
    cat("\nAll analyzed items met the exact target-assignment criterion.\n")
  }

  cat("\n")
  .say("Interpret scale norms and item flags alongside theory, domain",
       "coverage, and qualitative feedback. This analysis does not by itself",
       "establish comprehensiveness or the full content-validity argument.")
  invisible(x)
}

#' Plot item-sort evidence
#'
#' @description
#' Draws either the original one-index item plot or a correspondence-distinctiveness
#' evidence map. The Psa item plot draws each item's interval and a dashed mark
#' at the share of judges the exact test needs for that item, so an item is
#' retained when its point reaches its mark. The map places Psa on the x-axis and Csv on the y-axis so that
#' intended-construct correspondence and distinctiveness can be inspected together.
#' Target-scale means are added as triangles when available. Colquitt benchmark bands
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
#' plot(fit)
#' plot(fit, type = "map")
#' @export
plot.contentvalid_sort <- function(x,
                                   metric = c("psa", "csv"),
                                   type = c("item", "map"),
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
  psa_lab <- "Psa: share of judges choosing the target"
  csv_lab <- "Csv: lead of the target over its top rival"

  if (type == "item") {
    metric <- match.arg(metric)
    y <- r[[metric]]
    xs <- seq_along(y)
    lo <- if (metric == "psa") 0 else -1
    # Headroom above 1 holds the legend, clear of the data.
    .plot_with(list(x = xs, y = y, type = "n", xaxt = "n", yaxt = "n", xlab = "Item",
                    ylab = if (metric == "psa") psa_lab else csv_lab,
                    xlim = c(0.5, length(y) + 0.5),
                    ylim = c(lo, 1 + 0.2 * (1 - lo))), list(...))
    graphics::axis(1, at = xs, labels = r$item, las = 2)
    .axis_bounded(2, at = if (metric == "psa") seq(0, 1, 0.25) else seq(-1, 1, 0.5))
    leg <- .decision_legend(r$recommendation)
    lg <- leg$legend
    lp <- leg$pch
    ll <- rep(NA, length(lg))
    if (metric == "psa") {
      ci <- is.finite(r$psa_low) & is.finite(r$psa_high)
      if (any(ci)) {
        graphics::segments(xs[ci], r$psa_low[ci], xs[ci], r$psa_high[ci])
        lg <- c(lg, .ci_label(x$settings$alpha))
        lp <- c(lp, NA)
        ll <- c(ll, 1)
      }
      # The exact test compares counts, so each item's criterion is the count
      # it needs over the judges who sorted it.
      crit <- r$critical_n_target / r$n
      ok <- is.finite(crit)
      if (any(ok)) {
        graphics::segments(xs[ok] - 0.3, crit[ok], xs[ok] + 0.3, crit[ok], lty = 2)
        lg <- c(lg, "Criterion (exact test)")
        lp <- c(lp, NA)
        ll <- c(ll, 2)
      }
    } else {
      .hline(0)
    }
    has <- is.finite(y)
    graphics::points(xs[has], y[has], pch = pch[has])
    graphics::points(xs[!has], rep(lo, sum(!has)), pch = 4)
    if (isTRUE(show_legend)) .legend_top(lg, lp, ll)
    return(invisible(x))
  }

  ok <- is.finite(r$psa) & is.finite(r$csv)
  .plot_with(list(x = r$psa[ok], y = r$csv[ok], xlim = c(0, 1), ylim = c(-1, 1.4),
                  xaxt = "n", yaxt = "n", xlab = psa_lab, ylab = csv_lab,
                  pch = pch[ok]), list(...))
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
    graphics::text(r$psa[lab_idx], r$csv[lab_idx], labels = r$item[lab_idx],
                   pos = 3, cex = 0.70, offset = 0.35)
  }

  s <- x$scale_summary
  s_ok <- is.finite(s$mean_psa) & is.finite(s$mean_csv)
  if (any(s_ok)) {
    sx <- s$mean_psa[s_ok]
    sy <- s$mean_csv[s_ok]
    graphics::points(sx, sy, pch = 17, cex = 1.1)
    label_y <- .map_scale_label_y(sx, sy)
    graphics::text(sx, label_y, labels = s$target[s_ok], cex = 0.72)
  }

  if (isTRUE(show_legend)) {
    leg <- .decision_legend(r$recommendation[ok])
    .legend_top(c(leg$legend, if (any(s_ok)) "Scale mean"),
                c(leg$pch, if (any(s_ok)) 17))
  }
  invisible(x)
}

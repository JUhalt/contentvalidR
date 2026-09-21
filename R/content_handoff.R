# Schema version 1 of the handoff object, agreed with the nomologR maintainers
# on 2026-09-16. The consumer matches on the "cv_handoff" class and reads the
# documented fields, so neither package depends on the other. Add fields in a
# minor release if needed; only `schema_version` gates a reader.
.handoff_schema_version <- 1L

# The frozen contract for version 1, as data rather than prose, so the
# documentation and the tests read from one source. Adding an optional field
# means adding it here; changing or removing anything here means version 2.
.handoff_schema <- function() {
  statistics <- c(item = "character", statistic = "character",
                  value = "numeric", criterion = "numeric", round = "integer",
                  lower = "numeric", upper = "numeric",
                  interval_method = "character", interval_level = "numeric",
                  note = "character")
  list(
    version = .handoff_schema_version,
    top_level = c("items", "scales", "item_evidence", "item_statistics",
                  "provenance", "panel_statistics"),
    item_evidence = c(item = "character", scale = "character",
                      carried = "logical", status = "character",
                      recommendation = "character", n_judges = "integer",
                      rule = "character", round = "integer"),
    item_statistics = statistics,
    panel_statistics = statistics[names(statistics) != "item"],
    provenance = c(schema_version = "integer", package = "character",
                   package_version = "character", workflow = "character",
                   mode = "character", keep = "character",
                   method = "character", citation = "character",
                   settings = "list", design = "list", created = "Date")
  )
}

.handoff_stat <- function(items, statistic, value, criterion = NA_real_,
                          lower = NA_real_, upper = NA_real_,
                          interval_method = NA_character_,
                          interval_level = NA_real_, note = "") {
  out <- data.frame(
    item = as.character(items),
    statistic = statistic,
    value = as.numeric(value),
    criterion = as.numeric(criterion),
    lower = as.numeric(lower),
    upper = as.numeric(upper),
    interval_method = as.character(interval_method),
    interval_level = as.numeric(interval_level),
    # rep_len keeps a zero-row block zero-row: the default is length 1.
    note = .handoff_note(rep_len(note, length(items))),
    stringsAsFactors = FALSE
  )
  .handoff_no_interval(out)
}

# `note` is display text, so it is always a character vector with no NA: empty
# means there is nothing to say, never that something is missing.
.handoff_note <- function(note) {
  note <- as.character(note)
  note[is.na(note)] <- ""
  trimws(note)
}

# Agreed with nomologR (#46): NA in the four interval columns means "this
# statistic has no interval", never missing data. A row whose bounds could not
# be computed therefore carries no method or level either, so the four columns
# are NA together or not at all.
.handoff_no_interval <- function(stats) {
  none <- !is.finite(stats$lower) | !is.finite(stats$upper) |
    is.na(stats$interval_method)
  stats$lower[none] <- NA_real_
  stats$upper[none] <- NA_real_
  stats$interval_method[none] <- NA_character_
  stats$interval_level[none] <- NA_real_
  stats
}

.handoff_interval_label <- function(method) {
  if (!is.character(method) || length(method) != 1L) return(NA_character_)
  switch(method,
         wilson = "Wilson score",
         agresti_coull = "Agresti-Coull",
         exact = "Clopper-Pearson exact",
         NA_character_)
}

.handoff_column <- function(results, name) {
  if (name %in% names(results)) results[[name]] else NA_real_
}

# The panel-level agreement interval is not per item, so it travels in its own
# table with the same columns as `item_statistics`, less `item`.
.handoff_panel_statistics <- function(fit, round) {
  out <- data.frame(statistic = character(0), value = numeric(0),
                    criterion = numeric(0), round = integer(0),
                    lower = numeric(0), upper = numeric(0),
                    interval_method = character(0), interval_level = numeric(0),
                    note = character(0), stringsAsFactors = FALSE)
  ag <- if (is.list(fit$details)) fit$details$agreement else NULL
  if (!inherits(ag, "contentvalid_agreement")) return(out)

  has_interval <- is.finite(ag$ci_low) && is.finite(ag$ci_high)
  note <- c(
    if (!is.finite(ag$estimate)) {
      "The coefficient is undefined for these ratings, so it has no interval."
    } else if (!has_interval) {
      paste("The bootstrap interval could not be computed: too few resamples",
            "produced a usable coefficient.")
    },
    # The console warns that the interval for AC1 is unvalidated. The caveat
    # belongs with the number wherever it is shown, not only where it was
    # computed (#56).
    if (identical(ag$method, "ac1") && has_interval) {
      paste("Zapf et al. (2016) evaluated this bootstrap for Fleiss' kappa",
            "and Krippendorff's alpha, not for AC1. Applying it here is this",
            "package's extension, and its coverage is unknown.")
    }
  )

  row <- .handoff_no_interval(data.frame(
    statistic = .agreement_label(ag$method, ag$level),
    value = as.numeric(ag$estimate),
    criterion = NA_real_,
    round = as.integer(round),
    lower = as.numeric(ag$ci_low),
    upper = as.numeric(ag$ci_high),
    interval_method = "item-resampling percentile bootstrap",
    interval_level = 1 - ag$alpha,
    note = paste(note, collapse = " "),
    stringsAsFactors = FALSE
  ))
  rbind(out, row)
}

# delphi_validity() records why a statistic is undefined; the handoff carries
# that sentence so a reader need not re-derive method-specific semantics. An
# item rated in a single round has no pair at all, and therefore no row in the
# fit to take a note from, so that sentence is written here.
.handoff_delphi_notes <- function(fit, results) {
  stab <- fit$details$stability
  vapply(seq_len(nrow(results)), function(i) {
    rows <- which(stab$item == results$item[i])
    if (!length(rows)) {
      return(paste("This item was rated in only one round, so there was no",
                   "pair of rounds to compare."))
    }
    stab$note[rows[length(rows)]]
  }, character(1))
}

# A Delphi study ends one item at a time: an item settles in the round where it
# was last rated, which is earlier than the final round when it was set aside.
# Its evidence therefore comes from its own last round, and `round` carries that
# round's index rather than a constant.
.handoff_delphi_spec <- function(fit, results) {
  s <- fit$settings
  level <- 1 - s$alpha
  rounds <- fit$design$rounds
  round_index <- match(results$last_round, rounds)
  threshold <- s$consensus_threshold

  rule <- if (is.null(threshold)) {
    rep(paste("no consensus threshold was set before the study, so agreement",
              "is descriptive (Diamond et al., 2014)"), nrow(results))
  } else {
    sprintf(paste("consensus when at least %s%% of experts rated the item %s or",
                  "higher on the %s-%s scale, with the threshold fixed before",
                  "the study (Diamond et al., 2014); settled in round %s of %d"),
            format(100 * threshold), format(s$agree_cut), format(s$lo),
            format(s$hi), results$last_round, length(rounds))
  }

  stability_label <- switch(
    s$stability,
    kappa = paste0("weighted kappa (", s$kappa_weights, ")"),
    lambda = "Goodman-Kruskal lambda",
    chisq_individual = "individual chi-square",
    chisq_group = "group chi-square",
    percent_change = "net percent change"
  )
  stability_citation <- switch(
    s$stability,
    kappa = c("Holey et al. (2007)", "Cohen (1968)", "Fleiss & Cohen (1973)"),
    lambda = "Chaffin & Talley (1980)",
    chisq_individual = "Chaffin & Talley (1980)",
    chisq_group = "Dajani, Sincoff & Talley (1979)",
    percent_change = "Scheibe, Skutsch & Schofer (1975)"
  )

  # Relevance evidence comes from each item's own last round, so the interval
  # columns are the ones that round's expert_validity() fit already computed.
  last_fit_stat <- function(column) {
    out <- rep(NA_real_, nrow(results))
    for (r in unique(round_index)) {
      rf <- fit$details$round_fits[[r]]
      rows <- which(round_index == r)
      idx <- match(results$item[rows], rf$results$item)
      if (column %in% names(rf$results)) out[rows] <- rf$results[[column]][idx]
    }
    out
  }
  proportion_label <- .handoff_interval_label(
    fit$details$round_fits[[1]]$settings$proportion_ci
  )

  statistics <- rbind(
    .handoff_stat(results$item, "I-CVI", results$prop_agree,
                  if (is.null(threshold)) NA_real_ else threshold,
                  lower = last_fit_stat("I_CVI_low"),
                  upper = last_fit_stat("I_CVI_high"),
                  interval_method = proportion_label,
                  interval_level = level),
    .handoff_stat(results$item, "Aiken's V", last_fit_stat("V"),
                  lower = last_fit_stat("ci_low"),
                  upper = last_fit_stat("ci_high"),
                  interval_method = "Penfield-Giacobbi score",
                  interval_level = level),
    # No criterion: a Delphi decides on the consensus threshold, not on the
    # 0.74 kappa rule that expert_validity() applies.
    .handoff_stat(results$item, "modified kappa", last_fit_stat("kappa_mod")),
    .handoff_stat(results$item, "proportion unchanged", results$prop_unchanged),
    .handoff_stat(results$item, stability_label, results$stability,
                  criterion = if (s$stability == "percent_change") {
                    .delphi_scheibe_cut
                  } else {
                    NA_real_
                  },
                  lower = results$stability_low,
                  upper = results$stability_high,
                  interval_method = if (s$stability == "kappa") {
                    "expert-resampling percentile bootstrap"
                  } else {
                    NA_character_
                  },
                  interval_level = level,
                  note = .handoff_delphi_notes(fit, results))
  )
  if (s$stability %in% c("chisq_individual", "chisq_group")) {
    statistics <- rbind(
      statistics,
      .handoff_stat(results$item, "stability p_value", results$stability_p,
                    s$alpha)
    )
  }

  list(
    scale = rep(NA_character_, nrow(results)),
    n_judges = as.integer(results$n_experts),
    rule = rule,
    round = as.integer(round_index),
    citation = c("Holey et al. (2007)", "Diamond et al. (2014)",
                 setdiff(stability_citation, "Holey et al. (2007)"),
                 "Aiken (1980)", "Polit, Beck & Owen (2007)"),
    statistics = statistics
  )
}

# Per-workflow evidence: the construct each item belongs to, the effective judge
# count, the decision rule in words, the citations for the method that ran, and
# the statistics that rule was applied to.
.handoff_spec <- function(fit, results) {
  alpha <- if (is.null(fit$settings$alpha)) NA_real_ else fit$settings$alpha
  level <- 1 - alpha
  proportion_label <- .handoff_interval_label(fit$settings$proportion_ci)
  n <- nrow(results)
  blank <- .handoff_stat(character(0), character(0), numeric(0), numeric(0),
                         numeric(0), numeric(0), character(0), numeric(0))

  if (inherits(fit, "contentvalid_sort")) {
    return(list(
      scale = as.character(results$target),
      n_judges = as.integer(results$n),
      rule = sprintf(
        paste("target assignments >= %d of %d (exact binomial target-count",
              "test; Howard & Melloy, 2016), alpha = %s"),
        as.integer(results$critical_n_target), as.integer(results$n), format(alpha)
      ),
      citation = c("Anderson & Gerbing (1991)", "Howard & Melloy (2016)",
                   "Colquitt et al. (2019)"),
      statistics = rbind(
        .handoff_stat(results$item, "Psa", results$psa,
                      results$critical_n_target / results$n,
                      lower = .handoff_column(results, "psa_low"),
                      upper = .handoff_column(results, "psa_high"),
                      interval_method = proportion_label,
                      interval_level = level),
        .handoff_stat(results$item, "Csv", results$csv),
        .handoff_stat(results$item, "p_value", results$p_value, alpha)
      )
    ))
  }

  if (inherits(fit, "contentvalid_delphi")) return(.handoff_delphi_spec(fit, results))

  if (inherits(fit, "contentvalid_rating")) {
    return(list(
      scale = as.character(results$target),
      n_judges = as.integer(results$n_complete),
      rule = rep(sprintf(
        paste("Greenhouse-Geisser corrected omnibus test plus planned",
              "target-versus-orbiting contrasts (Hinkin & Tracey, 1999),",
              "alpha = %s"), format(alpha)), n),
      citation = c("Hinkin & Tracey (1999)", "Colquitt et al. (2019)"),
      statistics = rbind(
        .handoff_stat(results$item, "HTC", results$htc),
        .handoff_stat(results$item, "HTD", results$htd),
        .handoff_stat(results$item, "p_value", results$p_value, alpha)
      )
    ))
  }

  mode <- if (is.null(fit$mode)) NA_character_ else fit$mode

  if (identical(mode, "relevance")) {
    rule <- ifelse(
      is.na(results$cvi_criterion),
      "fewer than three usable expert ratings; treated as insufficient",
      sprintf(paste("I-CVI >= %s (common panel-size guideline for %d experts);",
                    "modified kappa > 0.74 for strong support"),
              format(results$cvi_criterion), as.integer(results$N))
    )
    return(list(
      scale = rep(NA_character_, n),
      n_judges = as.integer(results$N),
      rule = rule,
      citation = c("Aiken (1980)", "Penfield & Giacobbi (2004)",
                   "Polit, Beck & Owen (2007)"),
      statistics = rbind(
        .handoff_stat(results$item, "Aiken's V", results$V,
                      lower = .handoff_column(results, "ci_low"),
                      upper = .handoff_column(results, "ci_high"),
                      interval_method = if (is.null(fit$settings$aiken_ci)) {
                        NA_character_
                      } else {
                        fit$settings$aiken_ci
                      },
                      interval_level = level),
        .handoff_stat(results$item, "I-CVI", results$I_CVI, results$cvi_criterion,
                      lower = .handoff_column(results, "I_CVI_low"),
                      upper = .handoff_column(results, "I_CVI_high"),
                      interval_method = proportion_label,
                      interval_level = level),
        .handoff_stat(results$item, "modified kappa", results$kappa_mod, 0.74)
      )
    ))
  }

  if (identical(mode, "essentiality")) {
    return(list(
      scale = rep(NA_character_, n),
      n_judges = as.integer(results$N),
      rule = sprintf(
        paste("CVR >= %s, i.e. at least %d of %d judges rating the item",
              "essential (exact binomial; Ayre & Scally, 2014), alpha = %s"),
        format(round(results$critical_cvr, 3)), as.integer(results$critical_ne),
        as.integer(results$N), format(alpha)
      ),
      citation = c("Lawshe (1975)", "Ayre & Scally (2014)"),
      statistics = rbind(
        .handoff_stat(results$item, "CVR", results$cvr, results$critical_cvr),
        .handoff_stat(results$item, "essential count", results$ne, results$critical_ne),
        .handoff_stat(results$item, "p_value", results$p_value, alpha)
      )
    ))
  }

  # Congruence, with a target mapping: the target objective is the construct.
  if ("target_ioc" %in% names(results)) {
    cells <- if (is.list(fit$details)) fit$details$cells else NULL
    n_judges <- rep(NA_integer_, n)
    if (is.data.frame(cells) && all(c("item", "objective", "n_judges") %in% names(cells))) {
      idx <- match(paste(results$item, results$target),
                   paste(cells$item, cells$objective))
      n_judges <- as.integer(cells$n_judges[idx])
    }
    return(list(
      scale = as.character(results$target),
      n_judges = n_judges,
      rule = rep(paste("target-objective IOC exceeds the strongest competing",
                       "objective (Rovinelli & Hambleton, 1977)"), n),
      citation = c("Rovinelli & Hambleton (1977)", "Turner & Carlson (2003)"),
      statistics = rbind(
        .handoff_stat(results$item, "target IOC", results$target_ioc),
        .handoff_stat(results$item, "competitor IOC", results$competitor_ioc),
        .handoff_stat(results$item, "IOC margin", results$margin, 0)
      )
    ))
  }

  # Congruence without a target mapping: descriptive cells, no decision rule.
  list(
    scale = rep(NA_character_, n),
    n_judges = if ("n_judges" %in% names(results)) as.integer(results$n_judges) else rep(NA_integer_, n),
    rule = rep(paste("no target-objective mapping was supplied; IOC is reported",
                     "descriptively"), n),
    citation = c("Rovinelli & Hambleton (1977)", "Turner & Carlson (2003)"),
    statistics = if ("ioc" %in% names(results)) {
      .handoff_stat(results$item, "IOC", results$ioc)
    } else {
      blank
    }
  )
}

#' Carry content-validity decisions into empirical validation
#'
#' @description
#' Packages the item decisions from a finished content-validity workflow so they
#' can be carried into an empirical scale-development workflow without retyping
#' item names or losing the record of why each item was kept.
#'
#' The result holds the item names that survived content review, the construct
#' each belongs to where the design defines one, a per-item evidence table, the
#' statistics behind each decision, and the provenance of the analysis. It is
#' plain data, so a downstream package can read it without contentvalidR being
#' installed.
#'
#' @details
#' Item-level workflows are accepted: [sort_validity()], [rating_validity()],
#' [expert_validity()], and [delphi_validity()]. [judge_validity()] and
#' [domain_validity()] are refused, because their rows are judges and blueprint
#' cells rather than items, so there is no item set to carry forward.
#'
#' Items that do not meet `keep` are not dropped from the record. They stay in
#' `item_evidence` with `carried = FALSE`, so a reader can see what was held
#' back and why. Review is not deletion.
#'
#' @section Object shape (schema version 1):
#' The object has class `c("contentvalid_handoff", "cv_handoff", "list")`. A
#' consumer matches on `"cv_handoff"` and reads these fields:
#'
#' \describe{
#'   \item{`items`}{character vector of the carried item names, that is
#'     `item_evidence$item[item_evidence$carried]`, unique and in results order.}
#'   \item{`scales`}{named list mapping each construct to its carried items, or
#'     `NULL` when the design has no construct mapping. Expert relevance and
#'     essentiality rate a single item set with no construct column, so they
#'     produce `NULL`. Membership is one to one.}
#'   \item{`item_evidence`}{data frame with one row per reviewed item: `item`,
#'     `scale` (`NA` without a construct mapping), `carried`, `status`,
#'     `recommendation`, `n_judges`, `rule`, and `round`. For a Delphi handoff
#'     `round` differs between items; see "A Delphi handoff".}
#'   \item{`item_statistics`}{data frame, one row per item per statistic:
#'     `item`, `statistic`, `value`, `criterion` (`NA` when the method sets
#'     no explicit criterion), and `round`. Which statistics carry a criterion
#'     depends on the workflow rather than on the statistic alone: modified
#'     kappa carries 0.74 from [expert_validity()], and none from a Delphi
#'     handoff, which decides on the consensus threshold. From contentvalidR
#'     0.7.0 it also carries `note`, described under "The note column". From
#'     contentvalidR 0.5.0 it also
#'     carries `lower`, `upper`, `interval_method`, and `interval_level`,
#'     described under "Intervals".}
#'   \item{`provenance`}{list with `schema_version`, `package`,
#'     `package_version`, `workflow`, `mode`, `keep`, `method`, `citation`,
#'     `settings`, `design`, and `created`.}
#'   \item{`panel_statistics`}{added in contentvalidR 0.5.0. Data frame of
#'     panel-level statistics, with the same columns as `item_statistics` less
#'     `item`, including `note` from 0.7.0. It holds the panel agreement
#'     coefficient when [expert_validity()] computed one, and has zero rows
#'     otherwise.}
#' }
#'
#' This shape is agreed with the `nomologR` package, which consumes it in
#' `nomo_screen()` and `nomo_run()`. Neither package depends on the other.
#' Fields and columns added within schema version 1 are optional for a reader,
#' which should check that they are present rather than assume it.
#'
#' @section What version 1 freezes:
#' Schema version 1 is frozen as of contentvalidR 0.7.0. Code that reads a
#' handoff can rely on all of the following, in every release that reports
#' `schema_version = 1`:
#'
#' * The six top-level fields above, under those names.
#' * In `item_evidence`: `item`, `scale`, `carried`, `status`,
#'   `recommendation`, `n_judges`, `rule`, `round`.
#' * In `item_statistics`: `item`, `statistic`, `value`, `criterion`, `round`,
#'   `lower`, `upper`, `interval_method`, `interval_level`, `note`.
#' * In `panel_statistics`: the same columns less `item`.
#' * In `provenance`: `schema_version`, `package`, `package_version`,
#'   `workflow`, `mode`, `keep`, `method`, `citation`, `settings`, `design`,
#'   `created`.
#'
#' Each of those columns keeps its name, its position, and its type. Every
#' handoff carries every column, including when a workflow has nothing to put
#' in one: a statistic with no interval carries `NA` in the four interval
#' columns rather than dropping them, and a workflow with no panel coefficient
#' returns a zero-row `panel_statistics` with the full set of columns. A reader
#' can therefore bind handoffs from different workflows without reconciling
#' their columns.
#'
#' These are deliberately **not** frozen, and a reader should not depend on
#' them:
#'
#' * The set of rows. Which items, which statistics, and how many of each
#'   depend on the workflow and on the data.
#' * The values in the `statistic` column. They are labels for display, and may
#'   be reworded in a minor release; match on the workflow in `provenance`
#'   instead.
#' * The text in `note`, `rule`, `recommendation`, and `citation`, which is
#'   prose for a human reader.
#' * The contents of `settings` and `design`, which mirror the fitted object
#'   and grow with it.
#'
#' Neither is the printed output part of the schema. `print()` on a handoff is
#' written for a person, and its layout and wording may change in any release.
#' Read the fields.
#'
#' New optional fields and columns may still be added within version 1, at the
#' end of a data frame or list. A reader written against this section keeps
#' working when that happens, provided it addresses columns by name.
#'
#' @section If the schema ever changes:
#' Renaming a field, removing one, changing a type, or changing what a field
#' means is a version 2 change, not a minor release. It would raise
#' `provenance$schema_version` to `2L`, and version 1 would keep being
#' produced for at least one full release cycle so that readers have a
#' version to fall back on. The release notes would say what moved.
#'
#' A reader should gate on the version rather than on the contentvalidR
#' version:
#'
#' ```r
#' if (!inherits(h, "cv_handoff") || h$provenance$schema_version != 1L) {
#'   stop("this reader understands handoff schema version 1 only")
#' }
#' ```
#'
#' No version 2 is planned.
#'
#' @section The note column:
#' Added in contentvalidR 0.7.0 to `item_statistics` and `panel_statistics`.
#' It says why a value or interval is absent or degenerate, in the producing
#' function's own words, so a reader need not re-derive method-specific
#' semantics. For example, a Delphi stability row may carry "Kappa is
#' undefined: every rating fell in the same category in both rounds."
#'
#' Its contract, agreed with the `nomologR` maintainers:
#'
#' * It is **display text only**. Never match on it, branch on it, or parse
#'   it. Its wording may change in any minor release without a schema change.
#' * It is always a character vector with **no `NA`**. `""` means there is
#'   nothing to say, not that something is missing, so a row can carry a value
#'   and an empty note.
#' * It **never replaces the values**. Whether a statistic is undefined, and
#'   which of the two cases applies, stays readable from `value` and
#'   `proportion unchanged` as described under "When a stability statistic is
#'   NA". That inference is the supported way to decide anything.
#' * Objects from contentvalidR 0.6.0 and earlier have no such column, and a
#'   reader should treat its absence as every note being empty.
#'
#' @section Intervals:
#' Each statistic's interval travels with it, so a reader can tell a unanimous
#' four-judge panel from a unanimous twenty-judge one. `lower` and `upper` are
#' the bounds, `interval_method` names the method, and `interval_level` is the
#' confidence level, for example `0.95`.
#'
#' * Aiken's V: the Penfield-Giacobbi score interval.
#' * I-CVI and Psa: the method chosen with `proportion_ci`, the Wilson score
#'   interval by default.
#' * Panel agreement: the item-resampling percentile bootstrap of
#'   [panel_agreement()].
#'
#' The four columns are `NA` together when a statistic has no interval. That
#' happens when the method defines none (Csv, HTC, HTD, CVR, the essential
#' count, modified kappa, IOC, and p-values), when intervals were switched off
#' with `proportion_ci = "none"`, or when the statistic itself could not be
#' computed. `NA` there never stands for missing data.
#'
#' The handoff reports intervals only. It does not turn them into priors or
#' weights for a later analysis; that is a question for the consuming package.
#'
#' @section A Delphi handoff:
#' A Delphi study settles one item at a time: an item that reached consensus
#' early was set aside, and its last round came before the study's final round.
#' A Delphi handoff therefore carries each item's evidence **from its own last
#' round**, and `round` holds that round's index rather than one constant. It is
#' the only workflow where `round` varies within a handoff.
#'
#' Each item carries the relevance evidence of its last round, taken from that
#' round's [expert_validity()] fit, with intervals: `I-CVI` against the
#' consensus threshold, `Aiken's V`, and `modified kappa`. Modified kappa
#' carries no criterion here, because a Delphi decides on the consensus
#' threshold rather than on the 0.74 rule that [expert_validity()] applies.
#'
#' Two more statistics record whether the panel had stopped moving:
#' `proportion unchanged`, and the stability statistic that ran, named for its
#' method, such as `weighted kappa (quadratic)` or `Goodman-Kruskal lambda`.
#' The chi-square methods add `stability p_value` against `alpha`. Stability
#' travels as evidence beside the decision; it never decides what is carried,
#' exactly as it never sets an item's status in [delphi_validity()].
#'
#' @section When a stability statistic is NA:
#' A stability row is always present for a carried item, so an `NA` there is a
#' statement about the data rather than a missing record. There are two cases,
#' and they can be told apart from the object alone:
#'
#' \describe{
#'   \item{`proportion unchanged` is also `NA`}{The item has no pair of
#'     consecutive rounds: it was rated in one round only, so there was nothing
#'     to compare.}
#'   \item{`proportion unchanged` has a value}{A pair exists, but the
#'     statistic is undefined for that data.}
#' }
#'
#' In the second case, **read `proportion unchanged`**, which is often the more
#' informative number. An undefined kappa beside `proportion unchanged` of 1 is
#' perfect stability that kappa cannot express: kappa is chance-corrected, and
#' when every paired rating in both rounds falls in one category, the
#' disagreement expected by chance is zero, so kappa is 0/0. Reporting only
#' "not estimable" there would describe a defect that does not exist. Goodman-
#' Kruskal lambda is undefined when the later round is unanimous, and the
#' chi-square methods are undefined for a table with fewer than two occupied
#' rows or columns.
#'
#' `delphi_validity()` states the reason in `details$stability$note`, and from
#' contentvalidR 0.7.0 the handoff carries that sentence in the `note` column
#' of `item_statistics`, described under "The note column".
#'
#' @section What a handoff does and does not establish:
#' Surviving content review is evidence about relevance, representation, and
#' expert judgment. It does not establish that an item will behave well
#' empirically. An item can be clearly relevant and still correlate poorly with
#' its construct or load on an unintended factor. That is what the downstream
#' empirical analysis tests, which is why the item set travels with its
#' evidence rather than as a bare list of names.
#'
#' @param fit A fitted `contentvalid_sort`, `contentvalid_rating`,
#'   `contentvalid_expert`, or `contentvalid_delphi` object.
#' @param keep Statuses that travel forward, defaulting to `"Supported"`. Any of
#'   `"Supported"`, `"Review"`, `"Insufficient data"`, or `"Descriptive only"`.
#' @param round Pretest round this analysis represents. One fit is one round, so
#'   this defaults to `1` and matters only when stacking rounds by hand. It
#'   cannot be set for a Delphi fit, which dates each item by the round it
#'   settled in.
#'
#' @return An object of class `contentvalid_handoff`, `cv_handoff`, and `list`,
#'   as described under "Object shape".
#'
#' @seealso [as.data.frame.contentvalid_workflow()] for the full results table,
#'   and [content_report()] for manuscript tables.
#'
#' @examples
#' relevance <- matrix(
#'   c(4,4,4,3, 4,4,3,4, 3,4,4,4, 2,2,1,2),
#'   nrow = 4,
#'   dimnames = list(NULL, paste0("Item", 1:4))
#' )
#' fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
#'                        agreement = "none")
#' handoff <- content_handoff(fit)
#' handoff
#' handoff$items
#' handoff$item_evidence
#' handoff$item_statistics
#'
#' # Carry items flagged for review as well, when the study protocol says so.
#' content_handoff(fit, keep = c("Supported", "Review"))$items
#' @export
content_handoff <- function(fit, keep = "Supported", round = 1) {
  item_classes <- c("contentvalid_sort", "contentvalid_rating",
                    "contentvalid_expert", "contentvalid_delphi")
  if (!inherits(fit, item_classes, which = FALSE)) {
    stop("`fit` must be a sort, rating, expert-panel, or Delphi workflow ",
         "object. judge_validity() and domain_validity() results describe ",
         "judges and blueprint cells rather than items, so they carry no item ",
         "set.", call. = FALSE)
  }

  # A Delphi fit dates each item by the round it settled in, so `round` is read
  # from the fit rather than supplied.
  if (inherits(fit, "contentvalid_delphi") && !missing(round)) {
    stop("For a Delphi fit, `round` comes from the round each item settled ",
         "in, so it cannot be set here.", call. = FALSE)
  }

  valid <- .status_definitions()$status
  if (!is.character(keep) || !length(keep) || anyNA(keep) || !all(keep %in% valid)) {
    stop("`keep` must be one or more of: ", paste(valid, collapse = ", "), ".",
         call. = FALSE)
  }
  if (!is.numeric(round) || length(round) != 1L || !is.finite(round) ||
      round < 1 || round != floor(round)) {
    stop("`round` must be one positive integer.", call. = FALSE)
  }

  results <- .with_workflow_status(fit$results)
  if (!"item" %in% names(results)) {
    stop("This workflow's results have no `item` column, so there is no item ",
         "set to carry forward.", call. = FALSE)
  }

  spec <- .handoff_spec(fit, results)
  # One round per item: a constant everywhere except a Delphi handoff, where
  # each item carries the round it settled in.
  item_round <- if (is.null(spec$round)) {
    rep(as.integer(round), nrow(results))
  } else {
    as.integer(spec$round)
  }
  names(item_round) <- as.character(results$item)

  evidence <- data.frame(
    item = as.character(results$item),
    scale = spec$scale,
    carried = as.character(results$status) %in% keep,
    status = as.character(results$status),
    recommendation = if ("recommendation" %in% names(results)) {
      as.character(results$recommendation)
    } else {
      NA_character_
    },
    n_judges = spec$n_judges,
    rule = spec$rule,
    round = unname(item_round),
    stringsAsFactors = FALSE
  )
  rownames(evidence) <- NULL

  # Statistics cover every reviewed item, carried or not, so a held-back item
  # can be reported with the numbers behind its status.
  # The interval columns follow `round`, so the schema version 1 columns keep
  # their positions as well as their names.
  statistics <- spec$statistics
  statistics$round <- unname(item_round[as.character(statistics$item)])
  statistics <- statistics[c("item", "statistic", "value", "criterion", "round",
                             "lower", "upper", "interval_method",
                             "interval_level", "note")]
  rownames(statistics) <- NULL

  items <- unique(evidence$item[evidence$carried])
  scales <- NULL
  if (!all(is.na(evidence$scale))) {
    carried <- evidence[evidence$carried & !is.na(evidence$scale), , drop = FALSE]
    scales <- lapply(split(carried$item, carried$scale, drop = TRUE), unique)
  }

  out <- list(
    items = items,
    scales = scales,
    item_evidence = evidence,
    item_statistics = statistics,
    provenance = list(
      schema_version = .handoff_schema_version,
      package = "contentvalidR",
      package_version = as.character(getNamespaceVersion("contentvalidR")),
      workflow = .workflow_name(fit),
      mode = if (is.null(fit$mode)) NA_character_ else fit$mode,
      keep = keep,
      method = if (is.null(fit$settings$method)) NA_character_ else fit$settings$method,
      citation = spec$citation,
      settings = fit$settings,
      design = .workflow_design(fit),
      created = Sys.Date()
    ),
    panel_statistics = .handoff_panel_statistics(fit, round)
  )
  class(out) <- c("contentvalid_handoff", "cv_handoff", "list")
  out
}

#' @export
print.contentvalid_handoff <- function(x, ...) {
  p <- x$provenance
  cat("contentvalidR handoff (schema version ", p$schema_version, ")\n", sep = "")
  cat(strrep("-", 38), "\n", sep = "")
  cat("Workflow: ", p$workflow, sep = "")
  if (!is.na(p$mode)) cat(" (", p$mode, ")", sep = "")
  cat("   contentvalidR ", p$package_version, "   ", format(p$created), "\n", sep = "")
  cat("Items carried forward: ", length(x$items), " of ",
      length(unique(x$item_evidence$item)), "\n", sep = "")
  cat("Carried when status is: ", paste(p$keep, collapse = ", "), "\n", sep = "")

  if (is.null(x$scales)) {
    cat("Constructs: none in this design; the panel rated one item set.\n")
  } else {
    cat("Constructs: ", paste(sprintf("%s (%d)", names(x$scales),
                                      lengths(x$scales)), collapse = ", "),
        "\n", sep = "")
  }

  st <- x$item_statistics
  if (!is.null(st$interval_method) && any(!is.na(st$interval_method))) {
    carried <- unique(st[!is.na(st$interval_method),
                         c("statistic", "interval_method", "interval_level")])
    cat(strwrap(paste0("Intervals carried: ", paste(sprintf(
      "%s (%s, %s%%)", carried$statistic, carried$interval_method,
      format(100 * carried$interval_level)
    ), collapse = "; ")), width = 76, exdent = 2), sep = "\n")
  }

  ps <- x$panel_statistics
  if (is.data.frame(ps) && nrow(ps)) {
    for (i in seq_len(nrow(ps))) {
      line <- sprintf("Panel: %s = %s", ps$statistic[i],
                      format(round(ps$value[i], 2), nsmall = 2))
      if (!is.na(ps$interval_method[i])) {
        line <- sprintf("%s (%s%% interval %s to %s)", line,
                        format(100 * ps$interval_level[i]),
                        format(round(ps$lower[i], 2), nsmall = 2),
                        format(round(ps$upper[i], 2), nsmall = 2))
      }
      cat(line, "\n", sep = "")
    }
  }

  held <- x$item_evidence[!x$item_evidence$carried, , drop = FALSE]
  if (nrow(held)) {
    cat("\nHeld back:\n")
    print(held[c("item", "status", "recommendation")], row.names = FALSE)
  }

  cat("\n")
  cat(strwrap(paste(
    "Carry these items into the empirical workflow once response data are",
    "collected. In nomologR that is nomo_screen(data, items = <handoff>), which",
    "screens the same items you retained here."
  ), width = 76), sep = "\n")

  cat("\n")
  cat(strwrap(paste(
    "Surviving content review is evidence about relevance, representation, and",
    "expert judgment. It does not establish that an item will behave well",
    "empirically: an item can be clearly relevant and still correlate poorly",
    "with its construct or load on an unintended factor. Items held back are",
    "listed above rather than deleted, so the record stays complete."
  ), width = 76), sep = "\n")
  cat("\n")
  invisible(x)
}

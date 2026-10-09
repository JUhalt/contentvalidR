# Columns worth carrying into a manuscript table, per workflow. Everything else
# stays available through as.data.frame(); this is a reporting selection, not a
# claim that the omitted columns do not matter.
.report_columns <- function(x) {
  cols <- switch(
    class(x)[1],
    contentvalid_sort = c("item", "target", "n", "n_target", "competitor",
                          "psa", "psa_low", "psa_high", "csv", "p_value"),
    contentvalid_rating = c("item", "target", "n_complete", "strongest_competitor",
                            "htc", "htd", "F", "df1", "df2", "df1_gg", "df2_gg",
                            "partial_eta2", "p_value", "max_contrast_p"),
    contentvalid_expert = c("item", "target", "N", "n_judges", "V", "ci_low",
                            "ci_high", "I_CVI",
                            "I_CVI_low", "I_CVI_high", "kappa_mod", "cvr",
                            "p_value", "target_ioc", "target_mean",
                            "strongest_competitor", "competitor_mean", "margin",
                            "best_objective", "best_ioc"),
    contentvalid_judge = c("judge", "n_ratings", "mean_rating", "severity_raw",
                           "severity", "infit", "outfit", "differentiation"),
    contentvalid_domain = c("cell", "n_items", "share"),
    contentvalid_delphi = c("item", "last_round", "n_experts", "prop_agree",
                            "prop_unchanged", "stability", "stability_low",
                            "stability_high", "stability_df", "stability_p",
                            "stable"),
    character(0)
  )
  intersect(cols, names(x$results))
}

.md_escape <- function(x) gsub("|", "\\|", as.character(x), fixed = TRUE)

# APA sets statistical symbols in italics. Markdown can, so the symbols that
# stand alone in a heading or the note (p, F, V, n, N) are italicized there;
# the console and the names on the object stay plain.
.md_symbols <- function(x) {
  gsub("(?<![A-Za-z0-9*'.-])([pFVnN])(?![A-Za-z0-9*'(-])", "*\\1*", x,
       perl = TRUE)
}

.as_markdown_table <- function(df) {
  if (!nrow(df)) return(character(0))
  # Text is not padded: a Markdown cell needs no alignment.
  cells <- lapply(df, function(col) {
    .md_escape(if (is.character(col)) col else format(col, trim = TRUE))
  })
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  rule <- paste0("| ", paste(rep("---", length(df)), collapse = " | "), " |")
  rows <- vapply(seq_len(nrow(df)), function(i) {
    paste0("| ", paste(vapply(cells, function(col) col[i], character(1)),
                       collapse = " | "), " |")
  }, character(1))
  c(header, rule, rows)
}

#' Extract workflow results as a plain data frame
#'
#' @description
#' Returns a fitted workflow's results as an ordinary data frame, so results can
#' be filtered, joined, or written out without scraping printed output.
#'
#' A `workflow` column is prepended so that tables from several analyses can be
#' stacked and stay identifiable.
#'
#' @param x A fitted `contentvalid_workflow` object.
#' @param row.names,optional Present for compatibility with the generic.
#' @param component Which component to return: `"results"` (the default, one row
#'   per unit of analysis) or `"scale_summary"`.
#' @param include_interpretation Keep the per-unit interpretation text. It is
#'   informative but long, so set `FALSE` for compact tables.
#' @param ... Ignored.
#'
#' @return A data frame.
#'
#' @section Filtering is your decision, not the package's:
#' There is deliberately no helper that returns "the items that passed."
#' Selecting on `status == "Supported"` is a substantive decision that should
#' appear in your own code where a reader can see it, and `Review` never means
#' an item must be dropped. Keeping the filter explicit keeps that judgment
#' visible in the analysis script and in the manuscript.
#'
#' @examples
#' sorts <- read.csv(
#'   system.file("extdata", "sort_example.csv", package = "contentvalidR"),
#'   stringsAsFactors = FALSE
#' )
#' fit <- sort_validity(sorts)
#' head(as.data.frame(fit, include_interpretation = FALSE))
#' as.data.frame(fit, component = "scale_summary")[, c("target", "mean_psa",
#'                                                   "psa_strength")]
#' @export
as.data.frame.contentvalid_workflow <- function(x,
                                                row.names = NULL,
                                                optional = FALSE,
                                                component = c("results", "scale_summary"),
                                                include_interpretation = TRUE,
                                                ...) {
  component <- .choose(component)
  .validate_flag(include_interpretation, "include_interpretation")

  out <- if (component == "results") x$results else .workflow_scale_summary(x)
  out <- as.data.frame(out, stringsAsFactors = FALSE)

  if (component == "results" && !include_interpretation &&
      "interpretation" %in% names(out)) {
    out$interpretation <- NULL
  }

  if (nrow(out)) {
    out <- cbind(workflow = .workflow_name(x), out, stringsAsFactors = FALSE)
  }
  rownames(out) <- row.names
  out
}

# APA 7 display of a workflow's results for a manuscript table: one entry per
# column, in order. `type` says how the cells are written (see format_apa.R);
# `cols` names the results columns the cell is built from. A column whose
# inputs are absent or entirely missing is left out.
.report_spec <- function(x) {
  ci <- .ci_label(if (is.numeric(x$settings$alpha)) x$settings$alpha else 0.05)
  s <- function(heading, type, ...) list(heading = heading, type = type, cols = c(...))
  switch(
    class(x)[1],
    contentvalid_sort = list(
      s("item", "text", "item"), s("target", "text", "target"),
      s("judges", "count", "n_target", "n"), s("competitor", "text", "competitor"),
      s("Psa", "prop", "psa"), s(ci, "ci", "psa_low", "psa_high"),
      s("Csv", "prop", "csv"), s("p", "p", "p_value"),
      s("decision", "text", "recommendation")
    ),
    contentvalid_rating = list(
      s("item", "text", "item"), s("target", "text", "target"),
      s("judges", "int", "n_complete"),
      s("HTC", "prop", "htc"), s("HTD", "prop", "htd"),
      # The test behind the omnibus p, with the corrected degrees of freedom
      # that p was read from. The table is kept to one 80-column block, so
      # the closest competitor and partial eta-squared are left to
      # `format = "data.frame"` and to the fit's own printout.
      s("F test", "ftest", "F", "df1", "df2", "df1_gg", "df2_gg"),
      s("p", "p", "p_value"), s("contrast p", "p", "max_contrast_p"),
      s("decision", "text", "recommendation")
    ),
    contentvalid_expert = switch(
      x$mode,
      relevance = list(
        s("item", "text", "item"), s("experts", "int", "N"),
        s("V", "prop", "V"), s(ci, "ci", "ci_low", "ci_high"),
        s("I-CVI", "prop", "I_CVI"), s(ci, "ci", "I_CVI_low", "I_CVI_high"),
        s("kappa", "prop", "kappa_mod"), s("decision", "text", "recommendation")
      ),
      essentiality = list(
        s("item", "text", "item"), s("essential", "count", "ne", "N"),
        s("CVR", "prop", "cvr"), s("p", "p", "p_value"),
        s("decision", "text", "recommendation")
      ),
      list(
        s("item", "text", "item"), s("target", "text", "target"),
        s("experts", "int", "n_judges"),
        s("IOC", "prop", "target_ioc"), s("mean", "prop", "target_mean"),
        s("competitor", "text", "strongest_competitor"),
        s("competitor mean", "prop", "competitor_mean"),
        s("margin", "num", "margin"),
        s("best objective", "text", "best_objective"),
        s("best IOC", "prop", "best_ioc"),
        s("decision", "text", "recommendation")
      )
    ),
    contentvalid_judge = list(
      s("judge", "text", "judge"), s("ratings", "int", "n_ratings"),
      s("mean", "num", "mean_rating"), s("severity", "num", "severity_raw"),
      s("logit", "num", "severity"), s("infit", "num", "infit"),
      s("outfit", "num", "outfit"), s("scale use", "num", "differentiation"),
      s("decision", "text", "recommendation")
    ),
    contentvalid_domain = list(
      s("cell", "text", "cell"), s("items", "int", "n_items"),
      s("share", "percent", "share"), s("expected", "percent", "expected_share"),
      s("decision", "text", "recommendation")
    ),
    contentvalid_delphi = {
      # The column is headed by the statistic it holds. A chi-square can
      # exceed 1, so it keeps its leading zero and is reported with its df.
      method <- x$settings$stability
      chisq <- method %in% c("chisq_individual", "chisq_group")
      heading <- if (is.null(method)) "stability" else switch(
        method, kappa = "kappa", lambda = "lambda", percent_change = "net change",
        "chi-square"
      )
      c(
        list(
          s("item", "text", "item"), s("last round", "text", "last_round"),
          s("experts", "int", "n_experts"), s("agree", "prop", "prop_agree"),
          s("unchanged", "prop", "prop_unchanged")
        ),
        if (chisq) list(s("df", "int", "stability_df")),
        list(
          s(heading, if (chisq) "num" else "prop", "stability"),
          s(ci, "ci", "stability_low", "stability_high"),
          s("p", "p", "stability_p"),
          s("decision", "text", "recommendation")
        )
      )
    },
    list()
  )
}

.report_cells <- function(res, entry, digits, base = NA) {
  v <- lapply(entry$cols, function(cl) res[[cl]])
  switch(
    entry$type,
    text = ifelse(is.na(v[[1]]), .missing_mark, as.character(v[[1]])),
    int = ifelse(is.na(v[[1]]), .missing_mark, format(v[[1]], trim = TRUE)),
    count = ifelse(is.na(v[[1]]) | is.na(v[[2]]), .missing_mark,
                   paste0(v[[1]], "/", v[[2]])),
    prop = .fmt(v[[1]], digits),
    num = .fmt(v[[1]], digits, bounded = FALSE),
    percent = .fmt_pct(v[[1]], base = base),
    p = .fmt_p(v[[1]]),
    # Corrected degrees of freedom where a correction applied, the plain
    # ones otherwise (an F of Inf has no error variance to correct).
    ftest = ifelse(is.na(v[[1]]), "--",
                   .fmt_f_test(v[[1]],
                               ifelse(is.na(v[[4]]), v[[2]], v[[4]]),
                               ifelse(is.na(v[[5]]), v[[3]], v[[5]]), digits)),
    ci = .fmt_ci(v[[1]], v[[2]], digits)
  )
}

.report_apa_table <- function(x, res, digits) {
  spec <- .report_spec(x)
  # A share is read against every item in the analysis, also when the table
  # keeps only the flagged cells.
  base <- if ("n_items" %in% names(x$results)) {
    sum(x$results$n_items, na.rm = TRUE)
  } else {
    NA
  }
  cols <- list()
  headings <- character(0)
  is_ci <- logical(0)
  for (entry in spec) {
    if (!all(entry$cols %in% names(res))) next
    if (nrow(res) && all(is.na(res[[entry$cols[1]]]))) next
    cols[[length(cols) + 1L]] <- .report_cells(res, entry, digits, base)
    headings <- c(headings, entry$heading)
    is_ci <- c(is_ci, identical(entry$type, "ci"))
  }
  # An interval is named after its estimate in the object ("V 95% CI",
  # "I-CVI 95% CI"), whatever else the table holds, while the printed table
  # and the Markdown head it "95% CI", beside that estimate. The map from
  # name to printed heading is kept, so a column the user renames prints
  # under the new name. Headings are put in sentence case only where they
  # are shown, so the names on the object stay the ones code relies on.
  names_out <- headings
  at <- which(is_ci & seq_along(headings) > 1L)
  names_out[at] <- paste(headings[at - 1L], headings[at])
  tab <- as.data.frame(cols, stringsAsFactors = FALSE)
  names(tab) <- names_out
  if (length(at)) attr(tab, "display") <- stats::setNames(headings[at], names_out[at])
  attr(tab, "note") <- .report_note(
    x, headings, has_missing = any(vapply(tab, function(v) any(v == .missing_mark),
                                          logical(1))),
    decisions = res$recommendation
  )
  tab
}


# The general note of an APA table (Section 7.14): the abbreviations in the
# order the columns show them, what each column a reader could not otherwise
# interpret holds, the interval method, then the criterion that produced the
# decisions shown. Shared in form with nomologR.
.report_note <- function(x, headings, has_missing = FALSE, decisions = NULL) {
  abbrev <- c(
    Psa = "proportion of substantive agreement",
    Csv = "coefficient of substantive validity",
    HTC = "Hinkin-Tracey correspondence",
    HTD = "Hinkin-Tracey distinctiveness",
    V = "Aiken's content validity coefficient",
    `I-CVI` = "item-level content validity index",
    CVR = "content validity ratio",
    IOC = "index of item-objective congruence",
    CI = "confidence interval"
  )
  seen <- character(0)
  for (h in headings) {
    words <- strsplit(h, " ", fixed = TRUE)[[1]]
    seen <- c(seen, setdiff(intersect(words, names(abbrev)), seen))
  }
  defs <- if (length(seen)) {
    paste0(paste(paste(seen, "=", abbrev[seen]), collapse = "; "), ".")
  }
  st <- x$settings
  alpha <- if (is.numeric(st$alpha)) st$alpha else 0.05
  ci <- .ci_label(alpha)
  columns <- .report_column_notes(x, headings)
  interval <- NULL
  if (any(headings == ci)) {
    prop <- .handoff_interval_label(st$proportion_ci)
    interval <- switch(
      class(x)[1],
      contentvalid_sort = if (!is.na(prop)) sprintf("%s = %s confidence interval.", ci, prop),
      contentvalid_expert = if (!is.na(prop)) {
        sprintf(paste("%s = Penfield-Giacobbi score confidence interval for V",
                      "and %s confidence interval for I-CVI."), ci, prop)
      } else {
        sprintf("%s = Penfield-Giacobbi score confidence interval for V.", ci)
      },
      contentvalid_delphi = sprintf("%s = percentile bootstrap confidence interval.", ci),
      NULL
    )
  }
  criterion <- switch(
    class(x)[1],
    contentvalid_sort = sprintf(paste(
      "Retain = at least the number of target assignments the exact one-sided",
      "binomial test needs at alpha = %s with p0 = %s (Howard & Melloy, 2016)."),
      .fmt_alpha(alpha), .fmt(st$p0)),
    contentvalid_rating = sprintf(paste(
      "Retain = omnibus p and every one-sided %scontrast p at or below alpha =",
      "%s (MacKenzie et al., 2011)."),
      if (identical(st$adjust, "holm")) "Holm-adjusted " else "",
      .fmt_alpha(alpha)),
    contentvalid_expert = switch(
      x$mode,
      relevance = paste0(
        "Strong support = at least the number of experts rating the item ",
        "relevant that Lynn's (1986) criterion requires for the panel size",
        if (any(x$results$N > 10, na.rm = TRUE)) {
          ", held at her 7 of 9 beyond ten experts (a contentvalidR extension)"
        }, "."),
      essentiality = sprintf(paste(
        "Supported = an essential count that meets the exact one-sided",
        "binomial test at alpha = %s (Ayre & Scally, 2014)."), .fmt_alpha(alpha)),
      congruence = if (is.numeric(st$ioc_cut)) {
        cut <- .fmt(st$ioc_cut)
        if (isTRUE(all.equal(st$ioc_cut, 0.70))) {
          paste0("Congruent = IOC at or above ", cut, ", the criterion ",
                 "Rovinelli and Hambleton (1977) applied.")
        } else {
          paste0("Congruent = IOC at or above ", cut, ", set for this ",
                 "analysis; Rovinelli and Hambleton (1977) applied .70.")
        }
      }
    ),
    contentvalid_delphi = if (is.numeric(st$consensus_threshold)) {
      sprintf("Consensus = at least %s of experts agreeing in the last round.",
              .delphi_percent(st$consensus_threshold))
    },
    contentvalid_judge = .report_judge_criterion(st, decisions),
    contentvalid_domain = .report_domain_criterion(st, decisions),
    NULL
  )
  missing <- if (has_missing) "-- = not computed."
  txt <- c(defs, columns, interval, criterion, missing)
  if (!length(txt)) return(NULL)
  paste(txt, collapse = " ")
}


# What a column holds, for the columns whose heading alone does not say:
# one sentence each, in the order the table shows them.
.report_column_notes <- function(x, headings) {
  has <- function(h) any(tolower(headings) == tolower(h))
  st <- x$settings
  out <- switch(
    class(x)[1],
    contentvalid_sort = c(
      if (has("judges")) {
        "Judges = target assignments, out of the judges who sorted the item."
      }
    ),
    contentvalid_rating = c(
      if (has("judges")) {
        "Judges = judges who rated the item against every construct."
      },
      if (has("F test")) {
        paste("F test = within-judge omnibus test, with Greenhouse-Geisser",
              "corrected degrees of freedom where the correction applied.")
      },
      if (has("contrast p")) {
        paste0("Contrast p = the largest one-sided ",
               if (identical(st$adjust, "holm")) "Holm-adjusted ",
               "p among the planned contrasts of the intended construct with ",
               "each other construct.")
      }
    ),
    contentvalid_expert = switch(
      x$mode,
      relevance = c(
        if (has("kappa")) "Kappa = modified kappa (Polit et al., 2007)."
      ),
      essentiality = c(
        if (has("essential")) {
          "Essential = experts rating the item essential, out of those who rated it."
        }
      ),
      c(
        if (has("mean")) {
          paste("Mean = the experts' mean rating of the item on its intended",
                "objective (-1 to 1).")
        },
        if (has("competitor mean")) {
          "Competitor mean = the same for the closest other objective."
        },
        if (has("margin")) "Margin = mean minus competitor mean.",
        if (has("best objective")) {
          "Best objective = the objective with the highest IOC."
        }
      )
    ),
    contentvalid_delphi = c(
      if (has("agree")) {
        sprintf(paste("Agree = share of experts rating the item %s or higher",
                      "in its last round."), .fmt_scale(st$agree_cut))
      },
      if (has("unchanged")) {
        paste("Unchanged = share of experts who kept their rating between",
              "the item's last two consecutive rounds.")
      },
      switch(
        if (is.null(st$stability)) "" else st$stability,
        kappa = if (has("kappa")) {
          sprintf("Kappa = %s-weighted kappa between those rounds.",
                  st$kappa_weights)
        },
        lambda = if (has("lambda")) {
          "Lambda = Goodman-Kruskal lambda between those rounds."
        },
        percent_change = if (has("net change")) {
          paste("Net change = net change in the rating distribution between",
                "those rounds, read as stable below .15 (Scheibe et al.,",
                "1975/2002).")
        },
        chisq_individual = if (has("chi-square")) {
          paste("Chi-square = individual stability chi-square between those",
                "rounds (Chaffin & Talley, 1980).")
        },
        chisq_group = if (has("chi-square")) {
          paste("Chi-square = group stability chi-square between those rounds",
                "(Dajani et al., 1979).")
        },
        NULL
      )
    ),
    contentvalid_judge = c(
      if (has("ratings")) "Ratings = items the judge rated.",
      if (has("mean")) "Mean = the judge's mean rating.",
      if (has("severity")) {
        paste("Severity = how far the judge rates below the panel, in rating",
              "points (positive is harsher).")
      },
      if (has("logit")) {
        paste("Logit = severity from the many-facet Rasch model of the",
              "relevant/not-relevant decision.")
      },
      if (has("infit") || has("outfit")) {
        "Infit, Outfit = fit mean squares (about 1 is expected)."
      },
      if (has("scale use")) {
        paste("Scale use = spread of the judge's ratings relative to a typical",
              "judge on this panel (1 is typical).")
      }
    ),
    contentvalid_domain = c(
      if (has("share")) "Share = percentage of all items in the cell.",
      if (has("expected")) {
        if (isTRUE(st$targets_supplied)) {
          "Expected = the cell's share of the targets in the blueprint."
        } else {
          "Expected = an equal share of the items for every cell."
        }
      }
    ),
    NULL
  )
  if (length(out)) paste(out, collapse = " ")
}

# The rules behind a judge's flag, for the decisions the table shows. They
# are this package's conventions, which a manuscript table should say.
.report_judge_criterion <- function(st, decisions) {
  if (!is.list(st) || !is.numeric(st$severity_cut)) return(NULL)
  shown <- unique(as.character(decisions))
  rules <- c(
    if (any(shown %in% c("Severe", "Lenient"))) {
      sprintf(paste("Severe or Lenient = severity beyond %s logit, or beyond",
                    "%s rating points for a judge the model could not place"),
              format(st$severity_cut),
              .fmt(st$severity_raw_cut, 2, bounded = FALSE))
    },
    if ("Erratic" %in% shown && is.numeric(st$fit_range)) {
      sprintf("Erratic = infit or outfit above %s, on at least %d scored decisions",
              format(st$fit_range[2]), as.integer(st$fit_min_ratings))
    },
    if ("Low differentiation" %in% shown) {
      diff_cut <- if (is.null(st$differentiation_cut)) 0.5 else st$differentiation_cut
      sprintf("Low differentiation = scale use below %s",
              .fmt(diff_cut, 2, bounded = FALSE))
    }
  )
  if (!length(rules)) return(NULL)
  paste0(paste(rules, collapse = "; "),
         ". These cuts are contentvalidR conventions, not published standards.")
}

# The rules behind a cell's decision, for the decisions the table shows.
.report_domain_criterion <- function(st, decisions) {
  if (!is.list(st) || !is.numeric(st$min_items)) return(NULL)
  shown <- unique(as.character(decisions))
  f <- format(st$over_factor)
  rules <- c(
    if ("Not covered" %in% shown) "Not covered = no item addresses the cell",
    if ("Thinly covered" %in% shown) {
      paste0("Thinly covered = fewer than ", .n_noun(st$min_items, "item"),
             if (isTRUE(st$targets_supplied) && st$min_items > 1L) {
               " (or the cell's target, if smaller)"
             })
    },
    if ("Over-represented" %in% shown) {
      paste0("Over-represented = more than ", f, " times the expected share")
    },
    if ("Under-represented" %in% shown) {
      paste0("Under-represented = less than 1/", f, " of the expected share")
    }
  )
  if (!length(rules)) return(NULL)
  paste0(paste(rules, collapse = "; "),
         ". These criteria are contentvalidR conventions, not published standards.")
}

# The headings a reader sees: an interval named after its estimate is
# printed under its shared heading, unless the user renamed it.
.report_display <- function(tab) {
  map <- attr(tab, "display")
  out <- as.data.frame(tab)
  if (length(map)) {
    nm <- names(out)
    hit <- nm %in% names(map)
    nm[hit] <- map[nm[hit]]
    names(out) <- nm
  }
  out
}

#' Build a manuscript-ready results table
#'
#' @description
#' Formats a fitted workflow's results as a compact table for a manuscript or a
#' Quarto or R Markdown document. By default the table is written in APA style
#' (7th ed.): readable column headings, two decimals, no leading zero on values
#' that cannot exceed 1, *p* values to three decimals or `< .001`, and intervals
#' as `[LL, UL]` under a heading that names their level.
#'
#' Markdown output is generated directly, so no reporting package is required to
#' use it. Nothing in the core analysis depends on one.
#'
#' @param x A fitted `contentvalid_workflow` object.
#' @param digits Decimal places for estimates. *p* values always get three, as
#'   APA requires.
#' @param format `"apa"` (default), a table of formatted text in APA style;
#'   `"markdown"`, the same table as Markdown lines; or `"data.frame"`, the
#'   selected columns as rounded numbers under their names in `results`, for
#'   further computation.
#' @param include `"all"` (default) or `"flagged"`, which keeps only units whose
#'   status is not `Supported`.
#' @param caption Optional caption line placed above a Markdown table.
#'
#' @return For `"apa"`, a data frame of character columns that prints without
#'   row names; `as.data.frame()` drops its print class. An interval column is
#'   named after its estimate (`V 95% CI`, `I-CVI 95% CI`) and printed under
#'   the shared heading `95% CI`. For `"data.frame"`, a
#'   plain data frame with `recommendation` and `status` columns. For
#'   `"markdown"`, a character vector of Markdown lines that prints as the
#'   table, carrying the analysis provenance as its `"settings"` attribute.
#'
#' @section Changed in 0.9.0:
#' The default is now `format = "apa"`. Earlier versions returned the numeric
#' table by default, with *p* values rounded to `digits`; use
#' `format = "data.frame"` for that table, where *p* values now keep three
#' decimals.
#'
#' @section Changed in 1.0.0:
#' Numbers in `format = "data.frame"` round half up, as the APA table does,
#' so an exact tie such as 5 of 8 judges (.625) is 0.63 in both, where R's
#' own rounding gave 0.62. The APA table prints under a header and carries
#' its general note as the `"note"` attribute.
#'
#' @section Reporting the decision rules:
#' A results table alone is not a reproducible report. The thresholds that
#' produced each status live in the fitted object's `settings`, and are attached
#' to Markdown output as an attribute so they travel with the table. Report them
#' alongside it: two analyses of identical data can disagree entirely because
#' one used a different criterion.
#'
#' @seealso [as.data.frame.contentvalid_workflow()] for the untrimmed table, and
#'   [compare_rounds()] for reporting change across pretest rounds.
#'
#' @examples
#' sorts <- read.csv(
#'   system.file("extdata", "sort_example.csv", package = "contentvalidR"),
#'   stringsAsFactors = FALSE
#' )
#' fit <- sort_validity(sorts)
#' content_report(fit)
#' content_report(fit, format = "markdown", include = "flagged")
#' @export
content_report <- function(x,
                           digits = 2,
                           format = c("apa", "data.frame", "markdown"),
                           include = c("all", "flagged"),
                           caption = NULL) {
  if (!inherits(x, "contentvalid_workflow")) {
    stop("`x` must be a fitted contentvalidR workflow object.", call. = FALSE)
  }
  if (.congruence_pre10(x)) stop(.congruence_pre10_message(), call. = FALSE)
  format <- .choose(format)
  include <- .choose(include)
  .validate_digits(digits)
  if (!is.null(caption) &&
      (!is.character(caption) || length(caption) != 1L || is.na(caption))) {
    stop("`caption` must be one character string or NULL.", call. = FALSE)
  }

  res <- x$results
  if (include == "flagged") {
    res <- res[!is.na(res$status) & res$status != "Supported", , drop = FALSE]
  }
  rownames(res) <- NULL

  if (format != "data.frame") {
    tab <- .report_apa_table(x, res, digits)
    if (format == "apa") {
      class(tab) <- c("contentvalid_report", "data.frame")
      return(tab)
    }
    lines <- character(0)
    if (!is.null(caption)) lines <- c(lines, caption, "")
    lines <- c(lines, if (!nrow(tab)) {
      "_No units matched the requested selection._"
    } else {
      md <- .report_display(tab)
      names(md) <- .md_symbols(.sentence_case(names(md)))
      # APA marks a value that could not be computed with an em dash.
      md[] <- lapply(md, function(v) {
        v <- sub("^F[(]", "*F*(", v)
        ifelse(v == .missing_mark, "\u2014", v)
      })
      note <- attr(tab, "note")
      c(.as_markdown_table(md),
        if (length(note)) {
          # A Markdown paragraph may break across lines, so the note is
          # wrapped like the console.
          note <- .md_symbols(gsub(.missing_mark, "\u2014", note, fixed = TRUE))
          c("", strwrap(paste0("*Note.* ", note), width = 79))
        })
    })
    attr(lines, "settings") <- x$settings
    class(lines) <- "contentvalid_markdown"
    return(lines)
  }

  keep <- unique(c(.report_columns(x), "recommendation", "status"))
  keep <- intersect(keep, names(res))
  tab <- res[, keep, drop = FALSE]

  # A column that is entirely missing carries no information for a reader. The
  # workflow's own output explains why it could not be computed, so a manuscript
  # table is better without a column of NAs.
  if (nrow(tab)) {
    all_missing <- vapply(tab, function(col) all(is.na(col)), logical(1))
    if (any(all_missing) && !all(all_missing)) {
      tab <- tab[, !all_missing, drop = FALSE]
    }
  }

  num <- vapply(tab, is.numeric, logical(1))
  # p values keep the three decimals APA asks for, whatever `digits` is.
  # Rounding is half up, as in the APA table, so the two formats agree on an
  # exact tie such as 5 of 8 (.63).
  is_p <- names(tab) %in% c("p_value", "max_contrast_p", "stability_p")
  tab[num & !is_p] <- lapply(tab[num & !is_p], .half_up, digits = digits)
  tab[num & is_p] <- lapply(tab[num & is_p], .half_up, digits = max(3L, digits))
  tab
}

#' @export
print.contentvalid_report <- function(x, ...) {
  .print_header(x, "Results table in APA style")
  cat("\n")
  if (!nrow(x)) {
    .say("No units matched the requested selection.")
  } else {
    .print_table(.report_display(x), keep = c(.table_keep, "I-CVI", "IOC"))
    note <- attr(x, "note")
    if (length(note)) {
      cat("\n")
      .say(paste("Note.", note))
    }
  }
  .closing(pointer = paste('See content_report(fit, format = "markdown") for',
                           "the table as Markdown, ready for a manuscript."))
  invisible(x)
}

#' @export
as.data.frame.contentvalid_report <- function(x, ...) {
  class(x) <- "data.frame"
  attr(x, "display") <- NULL
  attr(x, "note") <- NULL
  x
}

#' @export
print.contentvalid_markdown <- function(x, ...) {
  cat(unclass(x), sep = "\n")
  invisible(x)
}

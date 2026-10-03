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
    contentvalid_expert = c("item", "N", "V", "ci_low", "ci_high", "I_CVI",
                            "I_CVI_low", "I_CVI_high", "kappa_mod", "cvr",
                            "p_value", "ioc"),
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

.as_markdown_table <- function(df) {
  if (!nrow(df)) return(character(0))
  cells <- lapply(df, function(col) .md_escape(format(col, trim = TRUE)))
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
#' as.data.frame(fit, component = "scale_summary")
#' @export
as.data.frame.contentvalid_workflow <- function(x,
                                                row.names = NULL,
                                                optional = FALSE,
                                                component = c("results", "scale_summary"),
                                                include_interpretation = TRUE,
                                                ...) {
  component <- match.arg(component)
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
        s("target IOC", "prop", "target_ioc"),
        s("competitor", "text", "strongest_competitor"),
        s("competitor IOC", "prop", "competitor_ioc"),
        s("margin", "num", "margin"),
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
      s("share", "percent", "share"), s("decision", "text", "recommendation")
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

.report_cells <- function(res, entry, digits) {
  v <- lapply(entry$cols, function(cl) res[[cl]])
  switch(
    entry$type,
    text = ifelse(is.na(v[[1]]), "", as.character(v[[1]])),
    int = ifelse(is.na(v[[1]]), "NA", format(v[[1]], trim = TRUE)),
    count = ifelse(is.na(v[[1]]) | is.na(v[[2]]), "NA", paste0(v[[1]], "/", v[[2]])),
    prop = .fmt(v[[1]], digits),
    num = .fmt(v[[1]], digits, bounded = FALSE),
    percent = ifelse(is.na(v[[1]]), "NA", paste0(round(100 * v[[1]]), "%")),
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
  cols <- list()
  headings <- character(0)
  for (entry in spec) {
    if (!all(entry$cols %in% names(res))) next
    if (nrow(res) && all(is.na(res[[entry$cols[1]]]))) next
    cols[[length(cols) + 1L]] <- .report_cells(res, entry, digits)
    headings <- c(headings, entry$heading)
  }
  tab <- as.data.frame(cols, stringsAsFactors = FALSE)
  names(tab) <- headings
  tab
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
#'   row names; `as.data.frame()` drops its print class. For `"data.frame"`, a
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
  format <- match.arg(format)
  include <- match.arg(include)
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
      .as_markdown_table(tab)
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
  is_p <- names(tab) %in% c("p_value", "max_contrast_p", "stability_p")
  tab[num & !is_p] <- lapply(tab[num & !is_p], round, digits = digits)
  tab[num & is_p] <- lapply(tab[num & is_p], round, digits = max(3L, digits))
  tab
}

#' @export
print.contentvalid_report <- function(x, ...) {
  if (!nrow(x)) {
    cat("No units matched the requested selection.\n")
  } else {
    .print_table(as.data.frame(x))
  }
  invisible(x)
}

#' @export
as.data.frame.contentvalid_report <- function(x, ...) {
  class(x) <- "data.frame"
  x
}

#' @export
print.contentvalid_markdown <- function(x, ...) {
  cat(unclass(x), sep = "\n")
  invisible(x)
}

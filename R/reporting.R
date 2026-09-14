# Columns worth carrying into a manuscript table, per workflow. Everything else
# stays available through as.data.frame(); this is a reporting selection, not a
# claim that the omitted columns do not matter.
.report_columns <- function(x) {
  cols <- switch(
    class(x)[1],
    contentvalid_sort = c("item", "target", "n", "n_target", "competitor",
                          "psa", "psa_low", "psa_high", "csv", "p_value"),
    contentvalid_rating = c("item", "target", "n_complete", "strongest_competitor",
                            "htc", "htd", "p_value"),
    contentvalid_expert = c("item", "N", "V", "ci_low", "ci_high", "I_CVI",
                            "I_CVI_low", "I_CVI_high", "kappa_mod", "cvr",
                            "p_value", "ioc"),
    contentvalid_judge = c("judge", "n_ratings", "mean_rating", "severity_raw",
                           "severity", "outfit", "differentiation",
                           "n_items_flipped"),
    contentvalid_domain = c("cell", "n_items", "share"),
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

#' Build a manuscript-ready results table
#'
#' @description
#' Formats a fitted workflow's results as a compact table suitable for pasting
#' into a manuscript or a Quarto or R Markdown document, either as a data frame
#' or as a Markdown table.
#'
#' Markdown output is generated directly, so no reporting package is required to
#' use it. Nothing in the core analysis depends on one.
#'
#' @param x A fitted `contentvalid_workflow` object.
#' @param digits Digits for rounding numeric columns.
#' @param format `"data.frame"` (default) or `"markdown"`.
#' @param include `"all"` (default) or `"flagged"`, which keeps only units whose
#'   status is not `Supported`.
#' @param caption Optional caption line placed above a Markdown table.
#'
#' @return A data frame, or a character vector of Markdown lines when
#'   `format = "markdown"`. The character vector carries the analysis provenance
#'   as its `"settings"` attribute.
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
#' cat(content_report(fit, format = "markdown", include = "flagged"), sep = "\n")
#' @export
content_report <- function(x,
                           digits = 2,
                           format = c("data.frame", "markdown"),
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
  tab[num] <- lapply(tab[num], round, digits = digits)
  rownames(tab) <- NULL

  if (format == "data.frame") return(tab)

  lines <- character(0)
  if (!is.null(caption)) lines <- c(lines, caption, "")
  if (!nrow(tab)) {
    lines <- c(lines, "_No units matched the requested selection._")
  } else {
    lines <- c(lines, .as_markdown_table(tab))
  }
  attr(lines, "settings") <- x$settings
  lines
}

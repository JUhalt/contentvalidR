# Central definitions for every abbreviated quantity the package prints.
# Output keys and the exported glossary both read from here so that a term is
# never defined in two places and never drifts between them.

.term_defs <- function() {
  rbind(
    data.frame(
      term = "psa", workflow = "item-sort",
      label = "Proportion of Substantive Agreement",
      definition = paste(
        "Share of judges who assigned the item to the construct it was written",
        "for. Higher means judges recognized the item as belonging where you",
        "intended."
      ),
      range = "0 to 1; higher is stronger",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "csv", workflow = "item-sort",
      label = "Coefficient of Substantive Validity",
      definition = paste(
        "How much more often the item went to its intended construct than to",
        "the alternative construct judges chose most. It rewards being",
        "distinctly right, not merely often right."
      ),
      range = "-1 to 1; 0 means the intended construct and its closest rival were chosen equally often",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "competitor", workflow = "item-sort",
      label = "Strongest competing construct",
      definition = "The construct, other than the intended one, that judges chose most often for this item.",
      range = "",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "p_value", workflow = "item-sort",
      label = "Howard-Melloy exact test",
      definition = paste(
        "Probability of seeing at least this many target assignments if judges",
        "were assigning at the chance rate p0. Small values mean the item's",
        "assignment pattern is unlikely to be chance."
      ),
      range = "0 to 1; compared against alpha",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "htc", workflow = "construct-rating",
      label = "Hinkin-Tracey Correspondence",
      definition = paste(
        "Average rating of the item against its intended construct definition,",
        "expressed as a proportion of the rating scale."
      ),
      range = "0 to 1; higher is stronger",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "htd", workflow = "construct-rating",
      label = "Hinkin-Tracey Distinctiveness",
      definition = paste(
        "How far the intended construct's average rating exceeds the best",
        "competing construct's, as a proportion of the rating scale. It is a",
        "difference, so its typical values are far smaller than HTC's."
      ),
      range = "usually a small positive number; higher is stronger",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "V", workflow = "expert-panel",
      label = "Aiken's V",
      definition = paste(
        "Relevance index that rescales the experts' average rating to run from",
        "0 to 1 given the bounds of the rating scale used."
      ),
      range = "0 to 1; higher is stronger",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "I_CVI", workflow = "expert-panel",
      label = "Item-level Content Validity Index",
      definition = "Proportion of experts who rated the item as relevant, after applying the relevance cut.",
      range = "0 to 1; compared against a panel-size guideline",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "kappa_mod", workflow = "expert-panel",
      label = "Modified kappa",
      definition = paste(
        "I-CVI adjusted for the chance that experts would have agreed even if",
        "rating at random. With small panels, chance agreement is substantial,",
        "which is why the raw I-CVI alone can overstate consensus."
      ),
      range = "0 to 1; higher is stronger",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "cvr", workflow = "expert-panel",
      label = "Lawshe's Content Validity Ratio",
      definition = "How far the panel leans toward calling the item essential rather than merely useful.",
      range = "-1 to 1; above 0 means more than half the panel called it essential",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "ioc", workflow = "expert-panel",
      label = "Item-Objective Congruence",
      definition = "How consistently experts linked the item to the objective it was written for rather than to another objective.",
      range = "-1 to 1; higher is stronger",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "severity", workflow = "judge-heterogeneity",
      label = "Judge severity",
      definition = paste(
        "How harsh or lenient a judge is compared with the rest of the panel.",
        "Positive means the judge rates lower than the panel. Reported in logits",
        "from the facets model when it can be estimated, otherwise in rating",
        "points."
      ),
      range = "0 means typical of this panel",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "infit/outfit", workflow = "judge-heterogeneity",
      label = "Fit mean squares",
      definition = paste(
        "Whether a judge's pattern of decisions is as predictable as the model",
        "expects. Around 1 is expected; high values mean erratic ratings, low",
        "values mean ratings more predictable than expected."
      ),
      range = "around 1.0 is expected",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "differentiation", workflow = "judge-heterogeneity",
      label = "Scale use",
      definition = paste(
        "How widely a judge spread their ratings compared with a typical judge",
        "on this panel. Values well below 1 mean the judge distinguished less",
        "among items."
      ),
      range = "1.0 is typical of this panel",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "g_coefficient", workflow = "judge-heterogeneity",
      label = "Generalizability coefficient",
      definition = paste(
        "How dependably the ranking of items by rated relevance would reproduce",
        "with a different panel of the same size. Use it for comparative",
        "decisions such as picking the best items from a pool."
      ),
      range = "0 to 1; higher is stronger",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "phi_coefficient", workflow = "judge-heterogeneity",
      label = "Dependability coefficient",
      definition = paste(
        "How dependably the absolute level of the ratings would reproduce with a",
        "different panel of the same size. Penalized by judge severity",
        "differences, and usually the relevant one for content validity, where",
        "items are judged against a fixed standard."
      ),
      range = "0 to 1; never exceeds the generalizability coefficient",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "share", workflow = "domain-coverage",
      label = "Share of items",
      definition = "Percentage of all items that fall in this blueprint cell.",
      range = "0 to 100%",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "adjusted_rand", workflow = "domain-coverage",
      label = "Adjusted Rand index",
      definition = paste(
        "How closely the groupings experts perceive match the blueprint's cells,",
        "corrected for the agreement expected by chance."
      ),
      range = "0 is chance agreement, 1 is exact; can be slightly negative",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "stress", workflow = "domain-coverage",
      label = "Kruskal stress-1",
      definition = paste(
        "How much distortion was introduced by squeezing the similarity data",
        "into the chosen number of dimensions. Lower is a closer fit."
      ),
      range = "0 is perfect; below 0.10 is conventionally called fair or better",
      stringsAsFactors = FALSE
    )
  )
}

.status_definitions <- function() {
  data.frame(
    status = c("Supported", "Review", "Insufficient data", "Descriptive only"),
    meaning = c(
      "The evidence met the criteria set for this analysis.",
      "Something here needs a closer look. This is not an instruction to delete anything.",
      "Too little usable data to reach a judgement.",
      "Reported for description only; no decision rule was applied."
    ),
    stringsAsFactors = FALSE
  )
}

.show_key <- function() {
  isTRUE(getOption("contentvalidR.show_key", TRUE))
}

.print_key <- function(terms, width = 76) {
  defs <- .term_defs()
  defs <- defs[defs$term %in% terms, , drop = FALSE]
  if (!nrow(defs)) return(invisible(NULL))
  defs <- defs[match(terms[terms %in% defs$term], defs$term), , drop = FALSE]

  cat("\nWhat these columns mean\n")
  for (i in seq_len(nrow(defs))) {
    body <- defs$definition[i]
    if (nzchar(defs$range[i])) body <- paste0(body, " (", defs$range[i], ")")
    cat(strwrap(paste0(defs$term[i], " -- ", defs$label[i], ". ", body),
                width = width, initial = "  ", prefix = "      "), sep = "\n")
  }
  invisible(NULL)
}

.print_status_legend <- function(width = 76, statuses = NULL) {
  d <- .status_definitions()
  if (!is.null(statuses)) {
    d <- d[d$status %in% statuses, , drop = FALSE]
    if (!nrow(d)) return(invisible(NULL))
  }
  cat("\nWhat the status labels mean\n")
  for (i in seq_len(nrow(d))) {
    cat(strwrap(paste0(d$status[i], " -- ", d$meaning[i]),
                width = width, initial = "  ", prefix = "      "), sep = "\n")
  }
  cat(strwrap(paste(
    "Each workflow also uses its own wording in the recommendation column",
    "(Retain, Strong support, Typical, Covered, and so on). Those words map",
    "onto the shared statuses above."
  ), width = width, initial = "  ", prefix = "  "), sep = "\n")
  invisible(NULL)
}

#' Glossary of contentvalidR indices and status terms
#'
#' @description
#' Plain-language definitions of every abbreviated quantity the package reports,
#' and of the status labels shared by all flagship workflows.
#'
#' The same definitions are printed beneath workflow output, so what you read
#' here is what appears alongside your results. Set
#' `options(contentvalidR.show_key = FALSE)` to suppress those inline keys once
#' the terms are familiar.
#'
#' @param workflow Optionally restrict to one workflow: `"item-sort"`,
#'   `"construct-rating"`, `"expert-panel"`, `"judge-heterogeneity"`, or
#'   `"domain-coverage"`.
#'
#' @return An object of class `contentvalid_glossary`: a data frame of `term`,
#'   `workflow`, `label`, `definition`, and `range`, carrying the status
#'   definitions as the `"statuses"` attribute.
#'
#' @section A note on benchmark labels:
#' Strength labels such as `Strong` or `Weak` from [interpret_colquitt()] are
#' percentile positions relative to scales published in the measurement
#' literature. They are not absolute judgements, and they are not comparable
#' across indices: HTC and HTD sit on different scales with different typical
#' values, so an HTC of 0.83 can be labelled `Weak` in the same analysis where
#' an HTD of 0.44 is labelled `Very Strong`. Compare each index against its own
#' benchmark, never against another index's number.
#'
#' @seealso [interpret_colquitt()] for the benchmark bands themselves.
#'
#' @examples
#' contentvalid_glossary()
#' contentvalid_glossary("item-sort")
#' @export
contentvalid_glossary <- function(workflow = NULL) {
  defs <- .term_defs()
  if (!is.null(workflow)) {
    if (!is.character(workflow) || length(workflow) != 1L || is.na(workflow)) {
      stop("`workflow` must be one workflow name or NULL.", call. = FALSE)
    }
    known <- unique(defs$workflow)
    if (!workflow %in% known) {
      stop("`workflow` must be one of: ", paste(known, collapse = ", "), ".",
           call. = FALSE)
    }
    defs <- defs[defs$workflow == workflow, , drop = FALSE]
  }
  rownames(defs) <- NULL
  attr(defs, "statuses") <- .status_definitions()
  class(defs) <- c("contentvalid_glossary", "data.frame")
  defs
}

#' @export
print.contentvalid_glossary <- function(x, width = 76, ...) {
  cat("contentvalidR glossary\n")
  for (wf in unique(x$workflow)) {
    cat("\n", wf, "\n", sep = "")
    sub <- x[x$workflow == wf, , drop = FALSE]
    for (i in seq_len(nrow(sub))) {
      body <- sub$definition[i]
      if (nzchar(sub$range[i])) body <- paste0(body, " (", sub$range[i], ")")
      cat(strwrap(paste0(sub$term[i], " -- ", sub$label[i], ". ", body),
                  width = width, initial = "  ", prefix = "      "), sep = "\n")
    }
  }

  st <- attr(x, "statuses")
  if (is.data.frame(st) && nrow(st)) {
    cat("\nstatus labels\n")
    for (i in seq_len(nrow(st))) {
      cat(strwrap(paste0(st$status[i], " -- ", st$meaning[i]),
                  width = width, initial = "  ", prefix = "      "), sep = "\n")
    }
  }
  cat("\nStrength labels such as Strong or Weak are percentile positions",
      "\nrelative to published scales, not absolute judgements, and are not",
      "\ncomparable across different indices.\n")
  invisible(x)
}

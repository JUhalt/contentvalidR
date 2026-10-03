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
        "Probability of seeing at least this many target assignments if each",
        "judge chose the intended construct with probability p0. The default,",
        ".50, is the benchmark Howard and Melloy (2016) used; it is not the",
        "rate expected from random assignment, which is 1 divided by the",
        "number of constructs. Small values mean judges chose the intended",
        "construct more often than that benchmark."
      ),
      range = "0 to 1; compared against alpha",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "htc", workflow = "construct-rating",
      label = "Hinkin-Tracey Correspondence",
      definition = paste(
        "Average rating of the item against its intended construct definition,",
        "divided by the number of scale points. The lowest possible rating",
        "still counts as one point, so the index cannot reach 0."
      ),
      range = "1 / (scale points) to 1, so .20 to 1 on a 5-point scale; higher is stronger",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "htd", workflow = "construct-rating",
      label = "Hinkin-Tracey Distinctiveness",
      definition = paste(
        "How far the intended construct's rating exceeds the other constructs'",
        "ratings, averaged over every other construct and every judge, as a",
        "proportion of the widest possible difference. It is a difference, so",
        "its typical values are far smaller than HTC's."
      ),
      range = "-1 to 1, usually a small positive number; higher is stronger",
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
      range = paste("0 to 1; compared with Lynn's (1986) criterion for the",
                    "panel size, which this package extends past ten experts",
                    "at her 7 of 9"),
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "I_CVI_low/I_CVI_high", workflow = "expert-panel",
      label = "Interval for I-CVI",
      definition = paste(
        "Lower and upper limits of an interval around I-CVI. Expert panels are",
        "usually small, so these intervals are often wide: a single I-CVI value",
        "can look more settled than the number of experts behind it supports."
      ),
      range = "between 0 and 1; the method and level are named in the output",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "psa_low/psa_high", workflow = "item-sort",
      label = "Interval for Psa",
      definition = paste(
        "Lower and upper limits of an interval around Psa. A wide interval means",
        "few judges sorted the item, so a different sample of judges could",
        "plausibly give a quite different Psa."
      ),
      range = "between 0 and 1; the method and level are named in the output",
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
      range = paste("at most 1; below 0 only when no expert, or one of three,",
                    "rated the item relevant; higher is stronger"),
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "agreement", workflow = "expert-panel",
      label = "Panel-level agreement",
      definition = paste(
        "One coefficient describing how consistently the whole panel rated the",
        "item set: Krippendorff's alpha by default, or Gwet's AC1 if chosen. It",
        "is separate from modified kappa, which describes one item at a time."
      ),
      range = paste(
        "1 is perfect agreement and 0 is agreement no better than chance; it can",
        "be low on a close-agreeing panel whose ratings cluster on one value"
      ),
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "agreement_ac1", workflow = "expert-panel",
      label = "Panel-level agreement (Gwet's AC1)",
      definition = paste(
        "One coefficient describing how consistently the whole panel made the",
        "relevant/not-relevant decision, with chance agreement estimated so",
        "that it stays small when nearly every rating falls in one category.",
        "It is separate from modified kappa, which describes one item at a time."
      ),
      range = paste(
        "1 is perfect agreement and 0 is agreement no better than chance; it",
        "stays high when nearly every rating is the same"
      ),
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "S_CVI_Ave", workflow = "expert-panel",
      label = "Scale-level CVI, averaging method",
      definition = paste(
        "The mean of the items' I-CVIs, the same quantity as the average",
        "congruency percentage. Polit and Beck (2006) recommend .90 or higher."
      ),
      range = "0 to 1",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "S_CVI_UA", workflow = "expert-panel",
      label = "Scale-level CVI, universal agreement",
      definition = paste(
        "The share of items that every expert rated relevant. It falls as",
        "experts are added, so Polit and Beck (2006) recommend reporting it",
        "beside S-CVI/Ave."
      ),
      range = "0 to 1",
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
      label = "Index of item-objective congruence",
      definition = paste(
        "Whether experts matched the item to an objective and not to the",
        "item's other objectives: half the gap between their mean rating on",
        "the objective and their mean rating on the others (Rovinelli &",
        "Hambleton, 1977). It is 1 only when every expert rates the item +1 on",
        "the objective and -1 on every other."
      ),
      range = "-1 to 1; Rovinelli and Hambleton applied a criterion of .70",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "severity", workflow = "judge-heterogeneity",
      label = "Judge severity",
      definition = paste(
        "How harsh or lenient a judge is compared with the panel, on the items",
        "that judge rated, in rating points. Positive means the judge rates",
        "lower than the panel. The logit column gives the same from the facets",
        "model when it can be estimated, and the flags then use it."
      ),
      range = "0 means typical of this panel",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "logit", workflow = "judge-heterogeneity",
      label = "Judge severity in logits",
      definition = paste(
        "Severity estimated by the many-facet Rasch model on the",
        "relevant/not-relevant decision, against the judges the model placed,",
        "and corrected for the bias of joint maximum likelihood. Positive means",
        "harsher."
      ),
      range = "0 means typical of the judges placed; flagged beyond the logit cut",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "infit/outfit", workflow = "judge-heterogeneity",
      label = "Fit mean squares",
      definition = paste(
        "Whether a judge's pattern of decisions is as predictable as the model",
        "expects. Around 1 is expected; high values mean erratic ratings, low",
        "values mean ratings more predictable than expected. Linacre (2002)",
        "calls 0.5 to 1.5 productive for measurement. Only a value above that",
        "range is flagged, and only when it rests on enough decisions."
      ),
      range = "around 1.0 is expected; 0.5 to 1.5 is productive for measurement",
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
      label = "Map distortion",
      definition = paste(
        "How far the distances on the content map depart from the experts'",
        "dissimilarities: the root of their squared differences over the",
        "squared dissimilarities. Lower is a closer map. It is not Kruskal's",
        "(1964) stress-1, which belongs to nonmetric scaling, so his verbal",
        "benchmarks do not apply to it."
      ),
      range = "0 is an exact map; no published benchmark applies",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "prop_agree", workflow = "delphi",
      label = "Share of experts agreeing",
      definition = paste(
        "Share of the experts rating an item in a round whose rating was at",
        "or above the agreement cut. On a relevance scale this is the I-CVI.",
        "Consensus means it reached the consensus threshold supplied."
      ),
      range = "0 to 1; higher is broader agreement",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "prop_unchanged", workflow = "delphi",
      label = "Share of experts keeping their rating",
      definition = paste(
        "Among experts who rated the item in both of two consecutive rounds,",
        "the share who gave exactly the same rating again. It is the plainest",
        "reading of stability, and it stays meaningful when kappa does not."
      ),
      range = "0 to 1; 1 means no expert changed their rating",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "kappa_w", workflow = "delphi",
      label = "Weighted kappa between rounds",
      definition = paste(
        "Agreement between each expert's ratings in two consecutive rounds,",
        "corrected for chance, with larger changes counting more. Read it as",
        "a trend across rounds. It can be low when ratings bunch in one",
        "category, so a converged panel can show a low kappa even when almost",
        "no one changed their rating."
      ),
      range = "-1 to 1; 1 is perfect stability, 0 is no better than chance",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "lambda", workflow = "delphi",
      label = "Goodman-Kruskal lambda, an index of predictive association",
      definition = paste(
        "How much knowing an expert's earlier rating improves a guess at their",
        "later one. It measures predictability, not agreement: experts who all",
        "moved up one category would still score 1."
      ),
      range = "0 to 1; undefined when the later round is unanimous",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "chi_sq_individual", workflow = "delphi",
      label = "Individual stability chi-square",
      definition = paste(
        "Tests whether experts' later ratings depend on their earlier ones.",
        "A significant result is read as stability. It needs expected counts",
        "of at least 5, which small panels rarely have."
      ),
      range = "0 or more; read with its p value",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "chi_sq_group", workflow = "delphi",
      label = "Group stability chi-square",
      definition = paste(
        "Tests whether the two rounds' rating distributions differ. A",
        "non-significant result is read as stability, so small panels often",
        "look stable because the test has little power, and experts swapping",
        "ratings go unseen."
      ),
      range = "0 or more; read with its p value",
      stringsAsFactors = FALSE
    ),
    data.frame(
      term = "percent_change", workflow = "delphi",
      label = "Net change in the rating distribution",
      definition = paste(
        "How far the panel's rating distribution moved between two rounds, as",
        "a share of the experts compared. Change below 15% is read as stable,",
        "a cutoff its authors set from one study without statistical theory."
      ),
      range = "0 to 1; stable below .15",
      stringsAsFactors = FALSE
    )
  )
}

# One line per term for the key printed under results. The full definitions
# stay in .term_defs() and contentvalid_glossary(); a test requires every term
# to have one here.
.term_short <- function() {
  c(
    psa = "Share of judges who put the item in the construct it was written for (0 to 1; higher is stronger).",
    csv = "How much more often judges chose the intended construct than its closest rival (-1 to 1; 0 is a tie).",
    competitor = "The construct other than the intended one that judges chose most often.",
    p_value = "Probability of at least this many target assignments if each judge picked the target at rate p0; compare with alpha.",
    htc = "Mean rating against the intended definition, divided by the number of scale points (1/points to 1).",
    htd = "How far that rating exceeds the other constructs' ratings on average, as a share of the scale (usually small).",
    V = "Mean relevance rating rescaled to run from 0 (lowest possible) to 1 (highest).",
    I_CVI = "Share of experts rating the item relevant, against Lynn's criterion for the panel size (extended past ten experts).",
    `I_CVI_low/I_CVI_high` = "Wide because expert panels are small; the method is named above.",
    `psa_low/psa_high` = "Wider when fewer judges sorted the item; the method is named above.",
    kappa_mod = "I-CVI corrected for chance agreement (at most 1; below 0 only when no expert, or one of three, rated it relevant).",
    agreement = "One coefficient for the whole panel (1 is perfect, 0 is chance); it can be low when nearly every rating is the same.",
    agreement_ac1 = "Panel agreement on the relevant/not-relevant decision (1 is perfect, 0 is chance); stays high as ratings concentrate.",
    S_CVI_Ave = "Mean of the items' I-CVIs; Polit and Beck (2006) recommend .90 or higher.",
    S_CVI_UA = "Share of items every expert rated relevant; it falls as experts are added.",
    cvr = "Lean of the panel toward calling the item essential (-1 to 1; above 0 means more than half did).",
    ioc = "Whether experts matched the item to this objective and not to the others (-1 to 1; criterion .70).",
    severity = "How much harsher (positive) or more lenient (negative) the judge is than the panel, in rating points.",
    logit = "The same from the facets model, against the judges it placed; the flags use it when it is estimable.",
    `infit/outfit` = "How predictable the judge's decisions are: about 1 is expected, high is erratic, low is more predictable than expected.",
    differentiation = "Spread of the judge's ratings compared with a typical judge (1 is typical; low means few distinctions).",
    g_coefficient = "How well the ranking of items would reproduce with another panel of this size (0 to 1).",
    phi_coefficient = "How well the absolute ratings would reproduce with another panel of this size (0 to 1).",
    share = "Percentage of all items in this cell.",
    adjusted_rand = "Match between the experts' groupings and the blueprint, corrected for chance (0 is chance, 1 is exact).",
    stress = "How far the map's distances depart from the experts' dissimilarities (0 is an exact map; no benchmark applies).",
    prop_agree = "Share of experts at or above the agreement cut in a round; consensus means reaching the consensus threshold.",
    prop_unchanged = "Share of experts giving the same rating in two consecutive rounds (1 means nobody changed).",
    kappa_w = "Chance-corrected agreement of each expert's ratings across two rounds; read it as a trend, not against a cutoff.",
    lambda = "How much an expert's earlier rating predicts the later one (0 to 1): predictability, not agreement.",
    chi_sq_individual = "Tests whether later ratings depend on earlier ones; needs expected counts of 5 or more.",
    chi_sq_group = "Tests whether the two rounds' distributions differ; small panels often look stable for lack of power.",
    percent_change = "Net change in the rating distribution between rounds (stable below .15 by its authors' rule)."
  )
}

# What each word in a workflow's decision column means, shown under results for
# the words that actually appear. A test checks every word a workflow can
# produce has an entry.
.decision_meanings <- function(workflow) {
  switch(
    workflow,
    "item-sort" = c(
      Retain = "met the exact target-assignment criterion.",
      Review = "did not meet the exact target-assignment criterion; the competitor column shows where judges put it instead.",
      "Insufficient panel" = "too few judges sorted it for any count to meet the exact criterion.",
      "Insufficient data" = "no judge sorted it."
    ),
    "construct-rating" = c(
      Retain = "its ratings differed across constructs (the omnibus test) and the intended construct was rated above every other (every planned contrast).",
      Review = "did not meet every criterion; the competitor column shows the closest rival.",
      "Insufficient data" = "fewer than two judges rated it against every construct."
    ),
    relevance = c(
      "Strong support" = "met the I-CVI criterion, which also puts modified kappa above .74.",
      Review = "did not meet the I-CVI criterion.",
      "Insufficient panel" = "fewer than three experts rated it."
    ),
    essentiality = c(
      Supported = "enough experts rated it essential to pass the exact test.",
      Review = "too few experts rated it essential to pass the exact test.",
      "Insufficient panel" = "too few experts rated it for any count to pass the exact test.",
      "Insufficient data" = "no expert rated it."
    ),
    congruence = c(
      Congruent = "its index of item-objective congruence met the criterion.",
      Review = "its index fell below the criterion; the margin shows how its intended objective compares with the closest other.",
      "Target described" = "only its intended objective was rated, so there is nothing to compare.",
      "Insufficient data" = "no usable ratings for its intended objective.",
      "Descriptive only" = "no intended objective was given, so the index is only described."
    ),
    delphi = c(
      Consensus = "reached the consensus threshold in its last round.",
      "No consensus" = "did not reach the consensus threshold.",
      "Descriptive only" = "no consensus threshold was set, so agreement is only described.",
      "Insufficient panel" = "fewer than three experts rated it in its last round."
    ),
    judge = c(
      Typical = "consistent with the panel.",
      Severe = "rates markedly lower than the panel.",
      Lenient = "rates markedly higher than the panel.",
      Erratic = "decisions noisier than the model expects (infit or outfit above the range).",
      "Low differentiation" = "draws few distinctions among items compared with other judges.",
      "Insufficient data" = "fewer than two usable ratings, or no other judge to compare with."
    ),
    domain = c(
      Covered = "met the coverage criteria.",
      "Thinly covered" = "fewer items than the minimum set (or its target, if smaller).",
      "Over-represented" = "more than `over_factor` times its expected share of the items.",
      "Under-represented" = "less than its target share divided by `over_factor`.",
      "Not covered" = "the blueprint includes it, but no item addresses it."
    ),
    stop("No decision meanings for workflow '", workflow, "'.", call. = FALSE)
  )
}

# Explains the decision words present in `decisions`, in the order defined.
.print_decision_legend <- function(decisions, workflow, width = 76) {
  meanings <- .decision_meanings(workflow)
  present <- meanings[names(meanings) %in% as.character(decisions)]
  if (!length(present)) return(invisible(NULL))
  cat("\nWhat the decisions mean\n")
  for (nm in names(present)) {
    cat(strwrap(paste0(nm, " -- ", present[[nm]]), width = width,
                initial = "  ", prefix = "      "), sep = "\n")
  }
  invisible(NULL)
}

.status_definitions <- function() {
  data.frame(
    status = c("Supported", "Review", "Insufficient data", "Descriptive only"),
    meaning = c(
      "The evidence met the criteria set for this analysis.",
      "Something here needs a closer look. This is not an instruction to delete anything.",
      "Too little usable data to reach a judgment.",
      "Reported for description only; no decision rule was applied."
    ),
    stringsAsFactors = FALSE
  )
}

.show_key <- function() {
  isTRUE(getOption("contentvalidR.show_key", TRUE))
}

# `terms` are glossary ids. When a table prints a column under a different
# heading, pass `headings` (same length as `terms`) so the key names the column
# the reader can see, not the id behind it.
.print_key <- function(terms, width = 76, headings = terms) {
  stopifnot(length(headings) == length(terms))
  shown <- stats::setNames(headings, terms)
  defs <- .term_defs()
  # A term with no definition would otherwise be dropped in silence, so a typo
  # in a print method's key would quietly stop explaining a column.
  unknown <- setdiff(terms, defs$term)
  if (length(unknown)) {
    stop("Unknown glossary term(s): ", paste(unknown, collapse = ", "), ".",
         call. = FALSE)
  }
  defs <- defs[defs$term %in% terms, , drop = FALSE]
  if (!nrow(defs)) return(invisible(NULL))
  defs <- defs[match(terms[terms %in% defs$term], defs$term), , drop = FALSE]

  short <- .term_short()
  cat("\nWhat these columns mean\n")
  for (i in seq_len(nrow(defs))) {
    body <- short[[defs$term[i]]]
    cat(strwrap(paste0(shown[[defs$term[i]]], " -- ", defs$label[i], ". ", body),
                width = width, initial = "  ", prefix = "      "), sep = "\n")
  }
  invisible(NULL)
}

.print_key_footer <- function() {
  cat("\nFull definitions: contentvalid_glossary(). To hide this key:\n",
      "options(contentvalidR.show_key = FALSE).\n", sep = "")
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
#'   `"construct-rating"`, `"expert-panel"`, `"judge-heterogeneity"`,
#'   `"domain-coverage"`, or `"delphi"`.
#'
#' @return An object of class `contentvalid_glossary`: a data frame of `term`,
#'   `workflow`, `label`, `definition`, and `range`, carrying the status
#'   definitions as the `"statuses"` attribute.
#'
#' @section A note on benchmark labels:
#' Strength labels such as `Strong` or `Weak` from [interpret_colquitt()] are
#' percentile positions relative to scales published in the measurement
#' literature. They are not absolute judgments, and they are not comparable
#' across indices: HTC and HTD sit on different scales with different typical
#' values, so an HTC of .83 can be labeled `Weak` in the same analysis where
#' an HTD of .44 is labeled `Very Strong`. Compare each index against its own
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
    # The words each workflow prints in its decision column.
    sets <- switch(wf,
                   "expert-panel" = c("relevance", "essentiality", "congruence"),
                   "judge-heterogeneity" = "judge",
                   "domain-coverage" = "domain",
                   wf)
    for (s in sets) {
      cat("  decisions", if (length(sets) > 1L) paste0(" (", s, ")"), ":\n",
          sep = "")
      meanings <- .decision_meanings(s)
      for (nm in names(meanings)) {
        cat(strwrap(paste0(nm, " -- ", meanings[[nm]]), width = width,
                    initial = "    ", prefix = "        "), sep = "\n")
      }
    }
  }

  st <- attr(x, "statuses")
  if (is.data.frame(st) && nrow(st)) {
    cat("\nstatus labels\n")
    for (i in seq_len(nrow(st))) {
      cat(strwrap(paste0(st$status[i], " -- ", st$meaning[i]),
                  width = width, initial = "  ", prefix = "      "), sep = "\n")
    }
    cat(strwrap(paste("Each decision word above maps onto one of these",
                      "statuses, stored in the `status` column of `results`."),
                width = width, initial = "  ", prefix = "  "), sep = "\n")
  }
  cat("\n")
  .say("Strength labels such as Strong or Weak are percentile positions",
       "relative to published scales, not absolute judgments, and are not",
       "comparable across different indices.")
  invisible(x)
}

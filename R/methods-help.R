#' Printing, summarizing, and plotting contentvalidR results
#'
#' @description
#' Every contentvalidR result has a `print()` method, except those of three
#' auxiliary helpers: [qfactor_content()] returns a plain list, and
#' [simulate_csv_power()] and [simulate_anova_power()] return a number.
#' Nearly every result with a `print()` method also has `as.data.frame()`.
#' The six workflows and [compare_rounds()] also have
#' `summary()`, and the results that have a figure have `plot()`. This page
#' says what each method does for each kind of result. The function that
#' made a result documents the result itself, such as the columns of a
#' workflow's `results`.
#'
#' @section print():
#' Every printout follows the style shared with nomologR (see
#' [contentvalidR-package]): a header naming the object's class and what it
#' holds, then the facts of the design, then the verdict, then tables with
#' numbers in APA style and, for most results, a key to the columns and
#' decisions shown. A printout ends with a line pointing to what else the
#' object holds. Only the display is rounded: the object keeps every value at
#' full precision. `print()` returns its argument invisibly.
#'
#' Most methods take `digits`, the decimal places for estimates; *p* values
#' always get three. The item-sort and expert-panel printouts also take
#' `legacy`, which shows the earlier published rules beside the decision
#' without changing it, and the glossary takes `width`.
#' `options(contentvalidR.show_key = FALSE)` hides the keys.
#'
#' What each kind of result prints:
#' * **Workflow fits** from [sort_validity()], [rating_validity()],
#'   [expert_validity()], [delphi_validity()], [judge_validity()], and
#'   [domain_validity()]: the full evidence, one row per unit of analysis,
#'   with the scale- or panel-level evidence and what the evidence does not
#'   decide.
#' * **Component indices** from [compute_psa()], [compute_csv()], [htc()],
#'   [htd()], [anova_content()], [aikens_v()], [cvr()], [ioc()], [cvi()],
#'   [panel_agreement()], [csv_binom_test()], [interpret_colquitt()],
#'   [colquitt_benchmarks()], and [similarity_from_sort()]: the index as a
#'   formatted table or a short report. Apart from printing, these results
#'   behave as the plain data frame, list, or matrix they hold.
#' * **Planning and diagnostics** from [sort_power()], [expert_power()],
#'   [gtheory_content()], [content_structure()], [signal_detection()], and
#'   [reproducibility_phi()]: the table or test, with a note on how to read
#'   it.
#' * **Reporting and exchange.** [content_report()] prints its APA table with
#'   the table's general note, and with `format = "markdown"` only the
#'   Markdown lines to paste (print them from a chunk with
#'   `results = "asis"` to render the table). [content_evidence()] prints the
#'   review stages side by side, item by item; [content_handoff()] the items
#'   carried forward and held back; [compare_rounds()] each unit's status by
#'   round; and [contentvalid_glossary()] the definitions.
#'
#' @section summary():
#' `summary()` of a workflow fit returns an object of class `summary.` plus
#' the fit's class, such as `summary.contentvalid_sort`. It prints the counts
#' by status, the scale- or panel-level evidence, and a "Flagged" section
#' with a sentence for each unit to look at again. The object is a list
#' holding, among others, `n_items`, `n_supported`, `n_review`,
#' `n_insufficient`, `n_descriptive`, `scale_summary`, `reviewed_items` (the
#' units whose status is `Review` or `Insufficient data`), `settings`, and
#' `design`. The Delphi summary adds `panel` and `stability_method`; the
#' expert-panel summary `mode` and, when an agreement coefficient was
#' computed, `agreement`; the judge summary `gtheory`, `influence_items`, and
#' `reviewed_judges`; and the coverage summary `gaps`, the cells under
#' review.
#'
#' `summary()` of a [compare_rounds()] result returns a
#' `summary.contentvalid_rounds` list whose `changed` holds the units that
#' changed status between the first and last rounds, entered or left, or
#' appeared only in between, with the counts in `summary`.
#'
#' @section plot():
#' Figures are drawn with base graphics, and each has its own help page:
#' [plot.contentvalid_sort()], [plot.contentvalid_rating()],
#' [plot.contentvalid_expert()], [plot.contentvalid_delphi()],
#' [plot.contentvalid_evidence()], [plot.contentvalid_structure()],
#' [plot.contentvalid_sort_power()], and [plot.contentvalid_expert_power()].
#'
#' A judge-heterogeneity fit, a coverage analysis, and a comparison of rounds
#' have no figure. Their `plot()` methods stop with a message that says where
#' to look instead. A coverage analysis given similarity data draws its
#' content map with `plot(x$details$structure)`.
#'
#' @section as.data.frame():
#' A workflow fit returns its `results` or its `scale_summary`
#' ([as.data.frame.contentvalid_workflow()]). A component index returns the
#' plain data frame, list, or matrix it holds, coerced to a data frame,
#' without its print class. [content_report()] returns its table of text,
#' and [content_evidence()] its long table of evidence, one row per item and
#' stage. The other results are covered in [contentvalid-data-frames].
#'
#' @return
#' * `print()` returns its argument, invisibly.
#' * `summary()` returns a list of class `summary.` plus the fit's class
#'   (`summary.contentvalid_rounds` for a comparison of rounds), holding the
#'   elements named under "summary()" above.
#' * `as.data.frame()` returns a data frame.
#' * `plot()` of a judge-heterogeneity fit, a coverage analysis, or a
#'   comparison of rounds returns nothing: it stops with an error whose
#'   message says where to look instead.
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
#' print(fit, digits = 3)
#' s <- summary(fit)
#' s$reviewed_items$item
#' head(as.data.frame(fit, include_interpretation = FALSE))
#'
#' @name contentvalid-methods
#' @aliases print.contentvalid_sort
#' @aliases print.contentvalid_rating
#' @aliases print.contentvalid_expert
#' @aliases print.contentvalid_delphi
#' @aliases print.contentvalid_judge
#' @aliases print.contentvalid_domain
#' @aliases print.summary.contentvalid_sort
#' @aliases print.summary.contentvalid_rating
#' @aliases print.summary.contentvalid_expert
#' @aliases print.summary.contentvalid_delphi
#' @aliases print.summary.contentvalid_judge
#' @aliases print.summary.contentvalid_domain
#' @aliases print.summary.contentvalid_rounds
#' @aliases summary.contentvalid_sort
#' @aliases summary.contentvalid_rating
#' @aliases summary.contentvalid_expert
#' @aliases summary.contentvalid_delphi
#' @aliases summary.contentvalid_judge
#' @aliases summary.contentvalid_domain
#' @aliases summary.contentvalid_rounds
#' @aliases print.contentvalid_psa
#' @aliases print.contentvalid_csv
#' @aliases print.contentvalid_htc
#' @aliases print.contentvalid_htd
#' @aliases print.contentvalid_anova
#' @aliases print.contentvalid_aiken
#' @aliases print.contentvalid_cvr
#' @aliases print.contentvalid_ioc
#' @aliases print.contentvalid_cvi
#' @aliases print.contentvalid_agreement
#' @aliases print.contentvalid_binom
#' @aliases print.contentvalid_colquitt
#' @aliases print.contentvalid_colquitt_norms
#' @aliases print.contentvalid_similarity
#' @aliases print.contentvalid_sort_power
#' @aliases print.contentvalid_expert_power
#' @aliases print.contentvalid_gtheory
#' @aliases print.contentvalid_structure
#' @aliases print.contentvalid_signal
#' @aliases print.contentvalid_reproducibility
#' @aliases print.contentvalid_report
#' @aliases print.contentvalid_markdown
#' @aliases print.contentvalid_evidence
#' @aliases print.contentvalid_handoff
#' @aliases print.contentvalid_rounds
#' @aliases print.contentvalid_glossary
#' @aliases plot.contentvalid_judge
#' @aliases plot.contentvalid_domain
#' @aliases plot.contentvalid_rounds
#' @aliases as.data.frame.contentvalid_component
#' @aliases as.data.frame.contentvalid_report
#' @aliases as.data.frame.contentvalid_evidence
NULL

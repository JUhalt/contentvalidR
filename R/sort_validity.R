#' Analyze an item-sort content-validity pretest
#'
#' @description
#' Provides the recommended user-facing workflow for item-sort studies. For
#' each item, `sort_validity()` combines Anderson and Gerbing's (1991) Psa and
#' Csv statistics with the exact target-count significance test recommended by
#' Howard and Melloy (2016).
#'
#' The output deliberately separates statistical evidence from an editorial
#' decision. Items meeting the exact criterion are labeled `"Retain"`; items
#' that do not meet it are labeled `"Review"`, not automatically `"Delete"`.
#' A review decision should incorporate item wording, construct overlap,
#' theoretical coverage, and qualitative feedback from the pretest.
#'
#' @param assignments A data.frame containing item-sort responses.
#' @param item_col,rater_col,assigned_col,target_col Column names for the item,
#'   rater, assigned construct, and intended target construct.
#' @param p0 Null target-assignment probability for the exact binomial test.
#'   Default `0.5`, following Howard and Melloy (2016).
#' @param alpha Significance level. Default `0.05`.
#'
#' @return An object of class `contentvalid_sort`. Its `results` component is a
#'   data.frame with item-level statistics, inferential evidence, and a
#'   plain-language recommendation. `print()` and `summary()` provide
#'   user-facing interpretation.
#'
#' @references
#' Anderson, J. C., & Gerbing, D. W. (1991). Predicting the performance of
#' measures in a confirmatory factor analysis with a pretest assessment of
#' their substantive validities. *Journal of Applied Psychology, 76*(5),
#' 732-740. \doi{10.1037/0021-9010.76.5.732}
#'
#' Howard, M. C., & Melloy, R. C. (2016). Evaluating item-sort task methods:
#' The presentation of a new statistical significance formula and
#' methodological best practices. *Journal of Business and Psychology, 31*(1),
#' 173-186. \doi{10.1007/s10869-015-9404-y}
#'
#' @examples
#' sort_dat <- data.frame(
#'   item = rep(c("Clear", "Review"), each = 20),
#'   rater = rep(1:20, 2),
#'   target_construct = rep("A", 40),
#'   assigned_construct = c(rep("A", 16), rep("B", 4),
#'                          rep("A", 11), rep("B", 9))
#' )
#' fit <- sort_validity(sort_dat)
#' fit
#' summary(fit)
#' @export
sort_validity <- function(assignments,
                          item_col = "item",
                          rater_col = "rater",
                          assigned_col = "assigned_construct",
                          target_col = "target_construct",
                          p0 = 0.5,
                          alpha = 0.05) {
  # Reuse the exact-test helper to validate p0 and alpha even when all
  # assignment responses are missing.
  invisible(.critical_target_count(1L, p0 = p0, alpha = alpha))

  psa <- compute_psa(
    assignments,
    item_col = item_col,
    rater_col = rater_col,
    assigned_col = assigned_col,
    target_col = target_col
  )
  csv <- compute_csv(
    assignments,
    item_col = item_col,
    rater_col = rater_col,
    assigned_col = assigned_col,
    target_col = target_col
  )

  idx <- match(csv$item, psa$item)
  results <- csv
  results$psa <- psa$psa[idx]
  results <- results[c(
    "item", "target", "n_total", "n", "n_missing", "n_target",
    "n_other_max", "psa", "csv"
  )]

  tests <- lapply(seq_len(nrow(results)), function(i) {
    if (results$n[i] < 1L) return(NULL)
    csv_binom_test(
      n_c = results$n_target[i],
      N = results$n[i],
      p0 = p0,
      alpha = alpha
    )
  })

  results$p_value <- vapply(tests, function(z) if (is.null(z)) NA_real_ else z$p.value, numeric(1))
  results$critical_n_target <- vapply(tests, function(z) if (is.null(z)) NA_integer_ else z$critical_n_target, integer(1))
  results$passes_chance <- vapply(tests, function(z) if (is.null(z)) FALSE else z$passes_chance, logical(1))
  results$recommendation <- ifelse(
    results$n < 1L,
    "Insufficient data",
    ifelse(results$passes_chance, "Retain", "Review")
  )
  results$interpretation <- ifelse(
    results$n < 1L,
    "No non-missing assignments are available for this item.",
    ifelse(
      results$passes_chance,
      "Target assignment exceeds the exact chance criterion; the item shows statistical support for intended-construct correspondence in this sort pretest.",
      "Target assignment does not exceed the exact chance criterion; review wording, construct overlap, and qualitative feedback before deciding whether to revise or remove the item."
    )
  )

  d <- .prepare_sort_assignments(
    assignments, item_col, rater_col, assigned_col, target_col
  )
  out <- list(
    results = results,
    settings = list(
      method = "Howard-Melloy exact target-count test",
      p0 = p0,
      alpha = alpha
    ),
    design = list(
      n_items = nrow(results),
      n_raters = length(unique(d$rater)),
      n_constructs_observed = length(unique(c(as.character(d$target), as.character(d$assigned[!is.na(d$assigned)]))))
    )
  )
  class(out) <- "contentvalid_sort"
  out
}

#' @export
print.contentvalid_sort <- function(x, digits = 3, ...) {
  r <- x$results
  n_retain <- sum(r$recommendation == "Retain")
  n_review <- sum(r$recommendation == "Review")
  n_insufficient <- sum(r$recommendation == "Insufficient data")

  cat("contentvalidR item-sort analysis\n")
  cat(strrep("-", 32), "\n", sep = "")
  cat("Items:", x$design$n_items,
      "| Raters:", x$design$n_raters,
      "| Observed constructs:", x$design$n_constructs_observed, "\n")
  cat("Inference:", x$settings$method,
      sprintf("(p0 = %.2f, alpha = %.3f)", x$settings$p0, x$settings$alpha), "\n\n")

  cat(n_retain, "item(s) meet the exact target-assignment criterion;",
      n_review, "item(s) are flagged for review")
  if (n_insufficient > 0L) cat(";", n_insufficient, "item(s) have insufficient data")
  cat(".\n")

  if (n_review > 0L) {
    cat("Review:", paste(r$item[r$recommendation == "Review"], collapse = ", "), "\n")
  }
  if (n_insufficient > 0L) {
    cat("Insufficient data:", paste(r$item[r$recommendation == "Insufficient data"], collapse = ", "), "\n")
  }

  if (any(r$n_missing > 0L)) {
    cat("Missing assignments:", sum(r$n_missing), "across", sum(r$n_missing > 0L),
        "item(s); effective N is used itemwise.\n")
  }

  cat("\n")
  tab <- r[c("item", "target", "n", "n_target", "psa", "csv", "p_value", "recommendation")]
  tab[c("psa", "csv", "p_value")] <- lapply(
    tab[c("psa", "csv", "p_value")],
    function(z) round(z, digits = digits)
  )
  print(tab, row.names = FALSE)
  cat("\n'Review' is not an automatic deletion decision. Use theory, construct-domain coverage,\n")
  cat("item wording, and qualitative judge feedback alongside these statistics.\n")
  invisible(x)
}

#' @export
summary.contentvalid_sort <- function(object, ...) {
  r <- object$results
  out <- list(
    n_items = nrow(r),
    n_retain = sum(r$recommendation == "Retain"),
    n_review = sum(r$recommendation == "Review"),
    n_insufficient = sum(r$recommendation == "Insufficient data"),
    mean_psa = if (all(is.na(r$psa))) NA_real_ else mean(r$psa, na.rm = TRUE),
    mean_csv = if (all(is.na(r$csv))) NA_real_ else mean(r$csv, na.rm = TRUE),
    reviewed_items = r[r$recommendation != "Retain", , drop = FALSE],
    settings = object$settings
  )
  class(out) <- "summary.contentvalid_sort"
  out
}

#' @export
print.summary.contentvalid_sort <- function(x, digits = 3, ...) {
  cat("Summary of item-sort content-validity evidence\n")
  cat(strrep("-", 43), "\n", sep = "")
  cat("Retain:", x$n_retain, "of", x$n_items, "item(s)\n")
  cat("Review:", x$n_review, "of", x$n_items, "item(s)\n")
  if (x$n_insufficient > 0L) cat("Insufficient data:", x$n_insufficient, "item(s)\n")
  cat("Mean Psa:", ifelse(is.na(x$mean_psa), "NA", round(x$mean_psa, digits)), "\n")
  cat("Mean Csv:", ifelse(is.na(x$mean_csv), "NA", round(x$mean_csv, digits)), "\n\n")

  if (nrow(x$reviewed_items) == 0L) {
    cat("All analyzed items met the exact target-assignment criterion. This supports\n")
    cat("intended-construct correspondence in this pretest, but does not by itself\n")
    cat("establish comprehensiveness or the full content-validity argument.\n")
  } else {
    cat("Items needing attention:\n")
    show <- x$reviewed_items[c("item", "target", "n", "n_target", "psa", "csv", "p_value", "recommendation")]
    show[c("psa", "csv", "p_value")] <- lapply(
      show[c("psa", "csv", "p_value")],
      function(z) round(z, digits = digits)
    )
    print(show, row.names = FALSE)
    if (x$n_review > 0L) {
      cat("\nFor items flagged Review, examine weak target correspondence, overlap with an\n")
      cat("orbiting construct, ambiguous wording, and qualitative judge feedback.\n")
    }
    if (x$n_insufficient > 0L) {
      cat("Items with insufficient data need additional usable judge responses before\n")
      cat("the exact retention rule can be evaluated.\n")
    }
  }
  invisible(x)
}

#' Hinkin-Tracey ANOVA content test
#'
#' @description
#' For each item, evaluates whether definitional-correspondence ratings differ
#' across construct definitions and whether the intended construct is rated
#' higher than every orbiting construct.
#'
#' The Hinkin and Tracey (1999) rating task is ordinarily a **within-judge**
#' design: the same judge rates an item against multiple construct definitions.
#' For that design, `anova_content()` uses a one-way repeated-measures ANOVA on
#' judges with complete ratings for the item's construct set, followed by
#' one-sided paired planned contrasts of the target against each orbiting
#' construct. A between-judge path is retained for genuinely independent rating
#' designs, but it is not the recommended Hinkin-Tracey protocol.
#'
#' The repeated-measures output includes the conventional omnibus F/p and a
#' Greenhouse-Geisser epsilon/corrected p-value. With more than two construct
#' definitions, the corrected p-value is the safer default for omnibus screening
#' when sphericity may not hold. Planned target-versus-orbiting contrasts provide
#' the more direct item-level evidence.
#'
#' @param ratings A long-format data.frame with item, rater, construct, and
#'   numeric rating columns.
#' @param item_col,rater_col,construct_col,rating_col Column names.
#' @param target_map Optional named character vector/list mapping item to target.
#'   If neither a map nor `target_col` is available, omnibus tests are still
#'   returned but target-versus-orbiting contrasts are `NA`.
#' @param target_col Target column used when `target_map` is `NULL`.
#' @param design One of `"auto"`, `"within"`, or `"between"`. `"auto"`
#'   identifies the design itemwise from whether judges provide ratings for
#'   multiple construct definitions.
#' @param alpha Significance level for the omnibus test and planned contrasts.
#' @param adjust Multiplicity adjustment for the target-versus-orbiting planned
#'   contrast p values. Default `"none"` reproduces the planned-comparison
#'   logic commonly used with the Hinkin-Tracey procedure; `"holm"` is a
#'   conservative option.
#' @param posthoc Deprecated compatibility argument. Tukey/Duncan post-hoc
#'   testing is no longer used because the Hinkin-Tracey question is directly
#'   represented by planned target-versus-orbiting contrasts.
#'
#' @return A data.frame with one row per item, including the omnibus F, raw p,
#'   Greenhouse-Geisser epsilon/corrected degrees of freedom and p-value for
#'   within-judge designs, partial eta-squared, and planned-contrast diagnostics.
#'   The full planned-contrast table is stored in `attr(result, "contrasts")`.
#'   `posthoc_pass` is retained as an alias of `contrast_pass` for backward
#'   compatibility.
#'
#' @references
#' Hinkin, T. R., & Tracey, J. B. (1999). An analysis of variance approach to
#' content validation. *Organizational Research Methods, 2*(2), 175-186.
#' \doi{10.1177/109442819922004}
#'
#' Colquitt, J. A., Baer, M. D., Long, D. M., & Halvorsen-Ganepola, M. D. K.
#' (2014). Scale indicators of social exchange relationships: A comparison of
#' relative content validity. *Journal of Applied Psychology, 99*(4), 599-618.
#' \doi{10.1037/a0036374}
#'
#' @examples
#' set.seed(1)
#' d <- expand.grid(item = c("I1", "I2"), rater = 1:12,
#'                  construct = c("A", "B", "C"))
#' d$target_construct <- ifelse(d$item == "I1", "A", "B")
#' d$rating <- ifelse(d$construct == d$target_construct,
#'                    rnorm(nrow(d), 4.5, .4), rnorm(nrow(d), 2.3, .5))
#' anova_content(d)
#' @export
anova_content <- function(ratings,
                          item_col = "item",
                          rater_col = "rater",
                          construct_col = "construct",
                          rating_col = "rating",
                          target_map = NULL,
                          posthoc = NULL,
                          alpha = 0.05,
                          target_col = "target_construct",
                          design = c("auto", "within", "between"),
                          adjust = c("none", "holm")) {
  design <- match.arg(design)
  adjust <- match.arg(adjust)
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be one number strictly between 0 and 1.", call. = FALSE)
  }
  if (!is.null(posthoc)) {
    warning("`posthoc` is deprecated; `anova_content()` now uses planned target-versus-orbiting contrasts.",
            call. = FALSE)
  }

  d <- .prepare_rating_data(ratings, item_col, rater_col, construct_col,
                            rating_col, target_map, target_col, require_target = FALSE)
  by_item <- split(d, d$item, drop = TRUE)
  rows <- vector("list", length(by_item))
  contrast_rows <- list()
  ci <- 1L

  for (i in seq_along(by_item)) {
    df <- by_item[[i]]
    item <- df$item[1]
    target <- unique(df$target)[1]
    detected_design <- .detect_item_rating_design(df)
    if (design == "within" && detected_design == "between") {
      stop("`design = \"within\"` was requested, but item '", item,
           "' has no judge rating more than one construct definition.", call. = FALSE)
    }
    if (design == "between" && detected_design == "within") {
      stop("`design = \"between\"` was requested, but item '", item,
           "' contains judges who rated multiple construct definitions.", call. = FALSE)
    }
    item_design <- if (design == "auto") detected_design else design
    constructs <- unique(df$construct)
    means <- tapply(df$rating, df$construct, mean, na.rm = TRUE)
    means[is.nan(means)] <- NA_real_
    has_target <- !is.na(target) && target %in% names(means)
    others <- if (has_target) setdiff(names(means), target) else character(0)
    target_mean <- if (has_target) unname(means[target]) else NA_real_
    other_means <- if (has_target) means[others] else numeric(0)
    strongest <- if (length(other_means) && any(!is.na(other_means))) {
      best <- max(other_means, na.rm = TRUE)
      paste(names(other_means)[!is.na(other_means) & other_means == best], collapse = " / ")
    } else NA_character_
    competitor_mean <- if (length(other_means) && any(!is.na(other_means))) max(other_means, na.rm = TRUE) else NA_real_

    if (item_design == "within") {
      mat <- .item_rating_matrix(df)
      av <- .rm_anova_oneway(mat)
      con <- if (has_target) .within_target_contrasts(mat, target, alpha = alpha, adjust = adjust) else data.frame()
      n_raters <- nrow(mat)
      n_complete <- av$n_complete
    } else if (item_design == "between") {
      usable <- df[!is.na(df$rating), , drop = FALSE]
      n_raters <- length(unique(usable$rater))
      n_complete <- n_raters
      if (length(unique(usable$construct)) >= 2L && nrow(usable) >= 3L) {
        fit <- stats::aov(rating ~ factor(construct), data = usable)
        sm <- summary(fit)[[1]]
        ss_between <- sm$`Sum Sq`[1]
        ss_error <- sm$`Sum Sq`[2]
        av <- list(n_complete = n_complete, F = sm$`F value`[1],
                   df1 = sm$Df[1], df2 = sm$Df[2], p = sm$`Pr(>F)`[1],
                   epsilon_gg = NA_real_, df1_gg = NA_real_, df2_gg = NA_real_, p_gg = NA_real_,
                   partial_eta2 = if ((ss_between + ss_error) == 0) NA_real_ else ss_between / (ss_between + ss_error))
      } else {
        av <- list(n_complete = n_complete, F = NA_real_, df1 = NA_real_,
                   df2 = NA_real_, p = NA_real_, epsilon_gg = NA_real_,
                   df1_gg = NA_real_, df2_gg = NA_real_, p_gg = NA_real_,
                   partial_eta2 = NA_real_)
      }
      con <- if (has_target) .between_target_contrasts(df, target, alpha = alpha, adjust = adjust) else data.frame()
    } else {
      av <- list(n_complete = 0L, F = NA_real_, df1 = NA_real_, df2 = NA_real_, p = NA_real_,
                 epsilon_gg = NA_real_, df1_gg = NA_real_, df2_gg = NA_real_, p_gg = NA_real_,
                 partial_eta2 = NA_real_)
      con <- data.frame()
      n_raters <- length(unique(df$rater))
      n_complete <- 0L
    }

    if (nrow(con)) {
      con$item <- item
      con$design <- item_design
      contrast_rows[[ci]] <- con[c("item", "design", "target", "competitor", "n",
                                    "mean_target", "mean_competitor", "mean_diff",
                                    "t", "df", "p", "p_adj", "dz", "pass")]
      ci <- ci + 1L
    }

    contrast_pass <- if (!nrow(con) || any(is.na(con$pass))) NA else all(con$pass)
    min_diff <- if (nrow(con) && any(!is.na(con$mean_diff))) min(con$mean_diff, na.rm = TRUE) else NA_real_
    max_p <- if (nrow(con) && any(!is.na(con$p_adj))) max(con$p_adj, na.rm = TRUE) else NA_real_

    rows[[i]] <- data.frame(
      item = item,
      target = target,
      design = item_design,
      n_raters = n_raters,
      n_complete = n_complete,
      n_constructs = length(constructs),
      target_mean = target_mean,
      strongest_competitor = strongest,
      competitor_mean = competitor_mean,
      F = av$F,
      df1 = av$df1,
      df2 = av$df2,
      p = av$p,
      epsilon_gg = av$epsilon_gg,
      df1_gg = av$df1_gg,
      df2_gg = av$df2_gg,
      p_gg = av$p_gg,
      p_screen = if (item_design == "within" && !is.na(av$p_gg)) av$p_gg else av$p,
      partial_eta2 = av$partial_eta2,
      min_mean_diff = min_diff,
      max_contrast_p = max_p,
      contrast_pass = contrast_pass,
      posthoc_pass = contrast_pass,
      stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  contrasts <- if (length(contrast_rows)) do.call(rbind, contrast_rows) else data.frame()
  rownames(contrasts) <- NULL
  attr(out, "contrasts") <- contrasts
  attr(out, "settings") <- list(alpha = alpha, adjust = adjust,
                                 within_method = "one-way repeated-measures ANOVA with Greenhouse-Geisser correction plus planned paired contrasts")
  out
}

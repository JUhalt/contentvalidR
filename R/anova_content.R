#' ANOVA content test: is an item's mean on its target construct > all others?
#'
#' @description
#' For each item, runs a one-way ANOVA of ratings across constructs and (optionally)
#' a Tukey HSD post-hoc to confirm that the item's mean rating on its target construct
#' is significantly greater than its means on all non-target constructs.
#'
#' @param ratings A data.frame with columns for item, rater, construct, rating (Likert).
#' @param item_col Name of the item column in `ratings`. Default "item".
#' @param rater_col Name of the rater column in `ratings`. Default "rater".
#' @param construct_col Name of the construct column in `ratings`. Default "construct".
#' @param rating_col Name of the rating column in `ratings`. Default "rating".
#' @param target_map A named character vector or list mapping item -> target construct
#'   (e.g., `c(I1="A", I2="A", I3="B")`). If `NULL`, `posthoc_pass` is returned as `NA`.
#' @param posthoc Post-hoc method. `"tukey"` (default). If `"duncan"` is requested,
#'   a message is shown and Tukey is used (no extra dependency).
#' @param alpha Significance level for ANOVA and post-hoc tests. Default 0.05.
#'
#' @return A data.frame with one row per item:
#'   item, target, F, df1, df2, p, posthoc_pass (TRUE/FALSE/NA).
#'
#' @examples
#' set.seed(1)
#' df <- data.frame(
#'   item = rep(paste0("I",1:4), each = 30),
#'   rater = rep(1:30, times = 4),
#'   construct = rep(rep(LETTERS[1:3], each = 10), times = 4),
#'   rating = rnorm(120)
#' )
#' # say I1,I2 target A; I3 target B; I4 target C
#' tmap <- c(I1="A", I2="A", I3="B", I4="C")
#' anova_content(df, target_map = tmap)
#' @export
anova_content <- function(ratings,
                          item_col = "item",
                          rater_col = "rater",
                          construct_col = "construct",
                          rating_col = "rating",
                          target_map = NULL,
                          posthoc = "tukey",
                          alpha = 0.05) {
  needed <- c(item_col, rater_col, construct_col, rating_col)
  if (!all(needed %in% names(ratings))) {
    stop("`ratings` must contain columns: ", paste(needed, collapse = ", "))
  }
  if (!is.null(target_map) && is.list(target_map)) {
    # allow list mapping too
    target_map <- unlist(target_map, use.names = TRUE)
  }
  if (!tolower(posthoc) %in% c("tukey", "duncan")) {
    stop('`posthoc` must be "tukey" or "duncan".')
  }
  if (tolower(posthoc) == "duncan") {
    message('`posthoc="duncan"` not implemented; using Tukey HSD instead.')
    posthoc <- "tukey"
  }

  r <- ratings[, needed]
  names(r) <- c("item","rater","construct","rating")
  r$construct <- as.factor(r$construct)

  items <- unique(r$item)
  rows <- vector("list", length(items))

  for (i in seq_along(items)) {
    it <- items[i]
    df <- r[r$item == it, , drop = FALSE]
    a <- stats::aov(rating ~ construct, data = df)
    sm <- summary(a)[[1]]
    Fv <- sm$`F value`[1]
    p  <- sm$`Pr(>F)`[1]
    target <- if (!is.null(target_map)) unname(target_map[[as.character(it)]]) else NA_character_
    posthoc_pass <- NA
    if (!is.na(target) && !is.null(p) && is.finite(p) && p <= alpha) {
      # Tukey HSD post-hoc
      tk <- TukeyHSD(a)$construct
      means <- tapply(df$rating, df$construct, mean, na.rm = TRUE)
      others <- setdiff(names(means), target)
      pass_vec <- logical(length(others))
      for (j in seq_along(others)) {
        # Tukey returns diffs in alphabetical order of factor levels
        levs <- levels(df$construct)
        a_name <- target
        b_name <- others[j]
        pair <- sort(c(a_name, b_name))
        rowname <- paste0(pair[2], "-", pair[1])
        if (!rowname %in% rownames(tk)) {
          # try the inverse (depends on factor level order)
          rowname <- paste0(pair[1], "-", pair[2])
        }
        # require sig diff *and* target mean > other mean
        pass_vec[j] <- (!is.na(tk[rowname, "p adj"])) &&
          (tk[rowname, "p adj"] <= alpha) &&
          (means[target] > means[others[j]])
      }
      posthoc_pass <- all(pass_vec)
    }
    rows[[i]] <- data.frame(
      item = it,
      target = target,
      F = ifelse(is.null(Fv), NA_real_, Fv),
      df1 = sm$Df[1],
      df2 = sm$Df[2],
      p = ifelse(is.null(p), NA_real_, p),
      posthoc_pass = posthoc_pass,
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, rows)
}

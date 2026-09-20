# Delphi consensus and stability (#20). The evidence behind every choice here
# is recorded on the issue: stability as weighted kappa between rounds (Holey
# et al., 2007), quadratic weights by default (Fleiss & Cohen, 1973), the
# published alternatives selectable with their critiques, and no verbal kappa
# labels.

.delphi_stability_methods <- c("kappa", "lambda", "chisq_individual",
                               "chisq_group", "percent_change")

# Scheibe, Skutsch & Schofer (1975): change below 15% is read as stable.
.delphi_scheibe_cut <- 0.15

.delphi_disagreement_weights <- function(k, weights) {
  d <- abs(outer(seq_len(k), seq_len(k), "-"))
  if (identical(weights, "quadratic")) d^2 else d
}

# Rows are the earlier round, columns the later one; x1 and x2 are category
# indices 1..k.
.delphi_cross_tab <- function(x1, x2, k) {
  matrix(tabulate((x1 - 1L) * k + x2, k * k), k, k, byrow = TRUE)
}

# Cohen (1968), eq. 8, in disagreement weights. Undefined (NA) when chance
# disagreement is zero, which happens only when every rating in both rounds
# falls in one category.
.delphi_weighted_kappa <- function(x1, x2, V) {
  O <- .delphi_cross_tab(x1, x2, nrow(V))
  n <- sum(O)
  if (n == 0) return(NA_real_)
  E <- outer(rowSums(O), colSums(O)) / n
  chance <- sum(V * E)
  if (chance <= 0) return(NA_real_)
  1 - sum(V * O) / chance
}

# Chaffin & Talley (1980), eq. 4: predicting the later round from the earlier.
.delphi_lambda <- function(O) {
  n <- sum(O)
  top <- max(colSums(O))
  if (n - top <= 0) return(NA_real_)
  (sum(apply(O, 1L, max)) - top) / (n - top)
}

# Chi-square test of independence on the occupied rows and columns, computed
# directly so there is no continuity correction and no warning to suppress.
.delphi_chisq <- function(O) {
  O <- O[rowSums(O) > 0, colSums(O) > 0, drop = FALSE]
  if (nrow(O) < 2L || ncol(O) < 2L) {
    return(list(statistic = NA_real_, df = NA_integer_, p_value = NA_real_,
                min_expected = NA_real_, n_low = NA_integer_,
                n_rows = nrow(O), n_cols = ncol(O)))
  }
  E <- outer(rowSums(O), colSums(O)) / sum(O)
  statistic <- sum((O - E)^2 / E)
  df <- (nrow(O) - 1L) * (ncol(O) - 1L)
  list(statistic = statistic, df = as.integer(df),
       p_value = stats::pchisq(statistic, df, lower.tail = FALSE),
       min_expected = min(E), n_low = sum(E < 5),
       n_rows = nrow(O), n_cols = ncol(O))
}

# Scheibe et al. (1975): net person-changes between the two rounds' histograms
# as a share of the experts compared.
.delphi_percent_change <- function(x1, x2, k) {
  sum(abs(tabulate(x2, k) - tabulate(x1, k))) / 2 / length(x1)
}

.delphi_pair_row <- function(item, from, to, x1, x2, k, method, V, B, alpha,
                             seed) {
  n <- length(x1)
  row <- data.frame(
    item = item, from_round = from, to_round = to, n_paired = n,
    prop_unchanged = if (n) mean(x1 == x2) else NA_real_,
    method = method, value = NA_real_, lower = NA_real_, upper = NA_real_,
    df = NA_integer_, p_value = NA_real_, stable = NA,
    min_expected = NA_real_, n_low_expected = NA_integer_,
    n_boot_usable = NA_integer_, note = "",
    stringsAsFactors = FALSE
  )
  if (!n) {
    row$note <- "No expert rated the item in both rounds."
    return(row)
  }

  if (method == "kappa") {
    row$value <- .delphi_weighted_kappa(x1, x2, V)
    if (is.na(row$value)) {
      row$note <- paste("Kappa is undefined: every rating fell in the same",
                        "category in both rounds.")
      return(row)
    }
    if (length(unique(x1)) == 1L || length(unique(x2)) == 1L) {
      # A unanimous round leaves no room above chance, so kappa is 0 however
      # many experts kept their rating (the restricted-range case). It is 0 in
      # every resample too, so an interval would only restate that.
      row$note <- paste("Every expert gave the same rating in one of the two",
                        "rounds, so kappa is 0 however many kept their",
                        "rating. Read prop_unchanged instead.")
      return(row)
    }
    if (B > 0L && n >= 2L) {
      boot <- .unit_bootstrap(
        rbind(x1, x2),
        function(X) .delphi_weighted_kappa(X[1L, ], X[2L, ], V),
        B = B, alpha = alpha, seed = seed
      )
      row$lower <- boot$low
      row$upper <- boot$high
      row$n_boot_usable <- boot$n_usable
    }
    return(row)
  }

  if (method == "lambda") {
    row$value <- .delphi_lambda(.delphi_cross_tab(x1, x2, k))
    if (is.na(row$value)) {
      row$note <- paste("Lambda is undefined: every expert gave the same",
                        "rating in the later round.")
    }
    return(row)
  }

  if (method == "percent_change") {
    row$value <- .delphi_percent_change(x1, x2, k)
    row$stable <- row$value < .delphi_scheibe_cut
    return(row)
  }

  O <- if (method == "chisq_individual") {
    .delphi_cross_tab(x1, x2, k)
  } else {
    rbind(tabulate(x1, k), tabulate(x2, k))
  }
  test <- .delphi_chisq(O)
  row$value <- test$statistic
  row$df <- test$df
  row$p_value <- test$p_value
  row$min_expected <- test$min_expected
  row$n_low_expected <- test$n_low

  if (method == "chisq_individual") {
    # Chaffin & Talley: rejecting independence is the evidence of stability.
    row$stable <- if (is.na(test$p_value)) NA else test$p_value < alpha
    if (is.na(test$p_value)) {
      row$note <- paste("The test cannot be computed: every expert gave the",
                        "same rating in at least one of the two rounds.")
    }
  } else {
    # Dajani et al.: failing to reject is read as stability.
    if (is.na(test$p_value)) {
      row$stable <- TRUE
      row$note <- paste("Every rating fell in one category in both rounds,",
                        "so the two distributions are identical.")
    } else {
      row$stable <- test$p_value >= alpha
    }
  }
  if (!is.na(test$min_expected) && test$min_expected < 5) {
    row$note <- paste("Some expected counts are below 5, so the chi-square",
                      "approximation is unreliable.")
  }
  row
}

.delphi_prepare <- function(ratings, expert_col, item_col, round_col,
                            rating_col, lo, hi) {
  if (!is.data.frame(ratings)) {
    stop("`ratings` must be a data frame with one row per expert, item, and ",
         "round.", call. = FALSE)
  }
  cols <- c(expert_col, item_col, round_col, rating_col)
  if (!is.character(cols) || length(cols) != 4L || anyNA(cols)) {
    stop("Column arguments must each be one column name.", call. = FALSE)
  }
  missing_cols <- setdiff(cols, names(ratings))
  if (length(missing_cols)) {
    stop("Column(s) not found in `ratings`: ",
         paste(missing_cols, collapse = ", "), ".", call. = FALSE)
  }
  if (!is.numeric(lo) || length(lo) != 1L || !is.finite(lo) || lo != floor(lo) ||
      !is.numeric(hi) || length(hi) != 1L || !is.finite(hi) || hi != floor(hi) ||
      hi <= lo) {
    stop("`lo` and `hi` must be whole numbers with `hi > lo`.", call. = FALSE)
  }

  rating <- ratings[[rating_col]]
  if (!is.numeric(rating)) {
    stop("The rating column must be numeric.", call. = FALSE)
  }
  ok <- !is.na(rating)
  if (any(!is.finite(rating[ok]) | rating[ok] != floor(rating[ok]) |
          rating[ok] < lo | rating[ok] > hi)) {
    stop("Ratings must be whole numbers from `lo` to `hi` (", lo, " to ", hi,
         ").", call. = FALSE)
  }
  if (anyNA(ratings[[expert_col]][ok]) || anyNA(ratings[[item_col]][ok]) ||
      anyNA(ratings[[round_col]][ok])) {
    stop("Expert, item, and round must not be missing for a rated row.",
         call. = FALSE)
  }

  rounds_raw <- ratings[[round_col]][ok]
  round_levels <- if (is.factor(rounds_raw)) {
    levels(droplevels(rounds_raw))
  } else if (is.numeric(rounds_raw)) {
    as.character(sort(unique(rounds_raw)))
  } else {
    unique(as.character(rounds_raw))
  }

  d <- data.frame(
    expert = as.character(ratings[[expert_col]][ok]),
    item = as.character(ratings[[item_col]][ok]),
    round = as.character(rounds_raw),
    rating = as.integer(rating[ok]),
    stringsAsFactors = FALSE
  )
  d$round_index <- match(d$round, round_levels)
  if (anyDuplicated(d[c("expert", "item", "round")])) {
    stop("Each expert may rate each item at most once per round; duplicate ",
         "expert-item-round rows were found.", call. = FALSE)
  }
  if (length(round_levels) < 2L) {
    stop("A Delphi analysis needs ratings from at least two rounds.",
         call. = FALSE)
  }
  list(data = d, rounds = round_levels)
}

.delphi_method_note <- function(method, weights) {
  switch(
    method,
    kappa = paste(
      "Stability is weighted kappa between each expert's ratings in",
      "consecutive rounds (Holey et al., 2007), with", weights, "weights.",
      if (weights == "quadratic") {
        paste("A change of two scale points counts four times a change of one.",
              "With these weights kappa equals the intraclass correlation of",
              "the two rounds' ratings, so a shift of the whole panel counts",
              "as instability (Fleiss & Cohen, 1973).")
      } else {
        paste("A change of two scale points counts twice a change of one",
              "(Cohen, 1968).")
      },
      "Read kappa as a trend across rounds, not against a cut-off. No verbal",
      "labels such as 'substantial' are shown: kappa falls when ratings",
      "converge on one category, which is what a Delphi aims for, so a panel",
      "whose experts nearly all kept their answer can still show a low kappa.",
      "Holey et al. saw this for their most-agreed statement. Read kappa next",
      "to prop_unchanged. The intervals are percentile bootstraps that",
      "resample experts. That is this package's extension: Zapf et al. (2016)",
      "evaluated resampling items for panel coefficients, not experts for a",
      "two-round kappa. With few experts the intervals are wide."
    ),
    lambda = paste(
      "Stability is lambda, the index of predictive association that Chaffin",
      "and Talley (1980) take from Goodman and Kruskal: how much knowing an",
      "expert's earlier rating improves a guess at the later one. It measures",
      "predictability, not agreement: if every expert moved up one category,",
      "lambda would be 1 although no one kept an answer. It is undefined when",
      "the later round is unanimous, and it ignores the order of the scale.",
      "Weighted kappa is the default for these reasons."
    ),
    chisq_individual = paste(
      "Stability is Chaffin and Talley's (1980) chi-square test of whether",
      "experts' later ratings depend on their earlier ones. Here a",
      "significant result (p < alpha) is read as stability. Dependence is",
      "association, not agreement: a panel that moved together one category",
      "up would also pass. The test needs expected counts of at least 5,",
      "which a small panel's table rarely has; min_expected shows how far",
      "short each table falls."
    ),
    chisq_group = paste(
      "Stability is Dajani, Sincoff and Talley's (1979) chi-square test",
      "comparing the two rounds' rating distributions. Here a non-significant",
      "result (p >= alpha) is read as stability, so a small panel will often",
      "look stable simply because the test has little power. The test treats",
      "the rounds as independent samples although the same experts answered",
      "both, and it cannot see experts swapping answers: Chaffin and Talley",
      "(1980) show distributions that look stable while most experts changed",
      "category. Expected counts below 5 are flagged."
    ),
    percent_change = paste(
      "Stability is Scheibe, Skutsch and Schofer's (1975) net change: half the",
      "summed differences between the two rounds' rating distributions, as a",
      "share of the experts compared, with change below 15% read as stable.",
      "The authors say the measure has no statistical theory behind it; the",
      "15% cut-off came from the movement they observed in one classroom",
      "Delphi. Experts swapping answers cancel out, and in a small panel one",
      "expert is a large share: with 10 experts one net change is already 10%."
    )
  )
}

.delphi_value_label <- function(method) {
  switch(method, kappa = "kappa", lambda = "lambda",
         chisq_individual = "chi_sq", chisq_group = "chi_sq",
         percent_change = "change")
}

#' Delphi consensus and stability across rounds
#'
#' @description
#' Analyzes an expert panel rated over successive Delphi rounds. For each item
#' it reports consensus in every round and the stability of experts' ratings
#' between consecutive rounds, and it fits [expert_validity()] to each round
#' so the usual relevance evidence is available round by round.
#'
#' Consensus and stability are different questions. Consensus asks whether
#' enough experts agree now. Stability asks whether experts are still changing
#' their answers. A Delphi can reach one without the other, so both are shown.
#'
#' @details
#' **Consensus.** An expert agrees with an item when their rating is at least
#' `agree_cut`. `prop_agree` is the share of responding experts who agree,
#' which on a relevance scale is the I-CVI. An item reaches consensus when
#' `prop_agree` meets `consensus_threshold`. There is deliberately no default
#' threshold: Diamond et al. (2014) recommend fixing it before the study,
#' and the 75% median they report describes common practice rather than a
#' validated cut-off. Without a threshold, items are reported as
#' `Descriptive only`.
#'
#' **Stability** is computed for each item and each pair of consecutive
#' rounds, on the experts who rated the item in both. `prop_unchanged`, the
#' share who kept their rating, is always reported. The `stability` argument
#' chooses the statistic reported beside it:
#'
#' * `"kappa"` (default): weighted kappa between each expert's ratings in the
#'   two rounds (Holey et al., 2007), read as a trend with no cut-off.
#'   Quadratic weights (the default) make kappa the intraclass correlation of
#'   the two rounds' ratings (Fleiss & Cohen, 1973); linear weights count a
#'   two-point change twice a one-point change (Cohen, 1968). The interval
#'   resamples experts, which is this package's extension.
#' * `"lambda"`: Chaffin and Talley's (1980) index of predictive association.
#' * `"chisq_individual"`: Chaffin and Talley's (1980) chi-square test on
#'   each expert's pair of ratings; a significant result is read as stable.
#' * `"chisq_group"`: Dajani, Sincoff and Talley's (1979) chi-square test on
#'   the two rounds' distributions; a non-significant result is read as
#'   stable.
#' * `"percent_change"`: Scheibe, Skutsch and Schofer's (1975) net change,
#'   stable below 15%.
#'
#' The alternatives are published but contested, so the printed output
#' explains each one's limits. Stability never changes an item's status: the
#' status rests on consensus in the item's last round, and stability is read
#' beside it.
#'
#' Items may enter or leave between rounds. An item's last round is the last
#' one in which anyone rated it, and stability is computed only between
#' consecutive rounds in which it was rated.
#'
#' @section Why kappa has no verbal labels:
#' Landis and Koch (1977) introduced the familiar labels (slight, fair,
#' moderate, substantial, almost perfect) and called their divisions clearly
#' arbitrary. Kappa also falls when ratings converge on one category, which is
#' what a Delphi aims for: in Holey et al. (2007), the statement experts agreed
#' on most had the lowest kappa. A label would therefore tend to worsen as a
#' panel succeeds. Read kappa as a trend, next to `prop_unchanged`.
#'
#' @param ratings A data frame with one row per expert, item, and round.
#'   Rows with a missing rating are ignored.
#' @param expert_col,item_col,round_col,rating_col Column names in `ratings`.
#' @param lo,hi Lowest and highest points of the rating scale, as whole
#'   numbers.
#' @param agree_cut Rating at or above which an expert counts as agreeing.
#'   Defaults to `hi - 1`, the usual relevance cut on a 4-point scale.
#' @param consensus_threshold Share of experts that must agree for consensus,
#'   between 0 and 1, fixed before the study. `NULL` (default) reports
#'   agreement descriptively.
#' @param stability Stability statistic; see Details.
#' @param kappa_weights `"quadratic"` (default) or `"linear"`, used when
#'   `stability = "kappa"`.
#' @param alpha Significance level for the chi-square methods, and
#'   `1 - alpha` is the interval level.
#' @param B Bootstrap resamples for the kappa interval. Use `0` to skip it.
#' @param seed Optional seed for the bootstrap.
#'
#' @return An object of class `contentvalid_delphi` and
#'   `contentvalid_workflow`. `results` has one row per item: its last round,
#'   `n_experts` there, `prop_agree`, `consensus`, and, for the last pair of
#'   consecutive rounds, `prop_unchanged`, `stability` with `stability_low`
#'   and `stability_high` where an interval exists, `stability_p` for the
#'   chi-square methods, and `stable` for the methods that make a decision.
#'   `details` holds `consensus` (every item and round), `stability` (every
#'   item and pair of rounds, including `n_paired`, `min_expected` for the
#'   chi-square methods, `n_boot_usable` for the kappa interval, and a
#'   `note` where a statistic is undefined or unreliable), `panel` (experts
#'   per round), and `round_fits`, the [expert_validity()] fit for each round.
#'
#' @references
#' Chaffin, W. W., & Talley, W. K. (1980). Individual stability in Delphi
#' studies. *Technological Forecasting and Social Change, 16*(1), 67-73.
#' \doi{10.1016/0040-1625(80)90074-8}
#'
#' Cohen, J. (1968). Weighted kappa: Nominal scale agreement provision for
#' scaled disagreement or partial credit. *Psychological Bulletin, 70*(4),
#' 213-220. \doi{10.1037/h0026256}
#'
#' Dajani, J. S., Sincoff, M. Z., & Talley, W. K. (1979). Stability and
#' agreement criteria for the termination of Delphi studies. *Technological
#' Forecasting and Social Change, 13*(1), 83-90.
#' \doi{10.1016/0040-1625(79)90007-6}
#'
#' Diamond, I. R., Grant, R. C., Feldman, B. M., Pencharz, P. B., Ling, S. C.,
#' Moore, A. M., & Wales, P. W. (2014). Defining consensus: A systematic
#' review recommends methodologic criteria for reporting of Delphi studies.
#' *Journal of Clinical Epidemiology, 67*(4), 401-409.
#' \doi{10.1016/j.jclinepi.2013.12.002}
#'
#' Fleiss, J. L., & Cohen, J. (1973). The equivalence of weighted kappa and
#' the intraclass correlation coefficient as measures of reliability.
#' *Educational and Psychological Measurement, 33*(3), 613-619.
#' \doi{10.1177/001316447303300309}
#'
#' Holey, E. A., Feeley, J. L., Dixon, J., & Whittaker, V. J. (2007). An
#' exploration of the use of simple statistics to measure consensus and
#' stability in Delphi studies. *BMC Medical Research Methodology, 7*, 52.
#' \doi{10.1186/1471-2288-7-52}
#'
#' Landis, J. R., & Koch, G. G. (1977). The measurement of observer agreement
#' for categorical data. *Biometrics, 33*(1), 159-174. \doi{10.2307/2529310}
#'
#' Scheibe, M., Skutsch, M., & Schofer, J. (1975). Experiments in Delphi
#' methodology. In H. A. Linstone & M. Turoff (Eds.), *The Delphi method:
#' Techniques and applications*. Addison-Wesley.
#'
#' Zapf, A., Castell, S., Morawietz, L., & Karch, A. (2016). Measuring
#' inter-rater reliability for nominal data: Which coefficients and
#' confidence intervals are appropriate? *BMC Medical Research Methodology,
#' 16*, 93. \doi{10.1186/s12874-016-0200-9}
#'
#' @seealso [expert_validity()] for a single round, and [compare_rounds()],
#'   which accepts the fits in `details$round_fits`.
#'
#' @examples
#' # Eight experts rate four statements for relevance (1-4) over three rounds.
#' r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4, 3, 4), S2 = c(2, 3, 2, 1, 3, 2, 2, 3),
#'             S3 = c(3, 4, 2, 3, 4, 1, 3, 2), S4 = c(4, 3, 4, 2, 3, 3, 4, 2))
#' r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2, 2, 2),
#'             S3 = c(3, 3, 3, 3, 4, 2, 3, 3), S4 = c(4, 3, 4, 3, 3, 3, 4, 3))
#' r3 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 4, 4), S2 = c(2, 2, 2, 1, 2, 2, 2, 2),
#'             S3 = c(3, 3, 3, 3, 4, 3, 3, 3), S4 = c(4, 3, 4, 3, 4, 3, 4, 3))
#' long <- function(m, round) {
#'   data.frame(expert = paste0("E", seq_len(nrow(m))),
#'              item = rep(colnames(m), each = nrow(m)),
#'              round = round, rating = as.vector(m))
#' }
#' ratings <- rbind(long(r1, 1), long(r2, 2), long(r3, 3))
#'
#' fit <- delphi_validity(ratings, lo = 1, hi = 4, consensus_threshold = 0.75,
#'                        B = 200, seed = 1)
#' fit
#' fit$details$stability
#'
#' # A published alternative, with its critique printed.
#' delphi_validity(ratings, lo = 1, hi = 4, consensus_threshold = 0.75,
#'                 stability = "percent_change")
#' @export
delphi_validity <- function(ratings,
                            expert_col = "expert",
                            item_col = "item",
                            round_col = "round",
                            rating_col = "rating",
                            lo, hi,
                            agree_cut = NULL,
                            consensus_threshold = NULL,
                            stability = c("kappa", "lambda", "chisq_individual",
                                          "chisq_group", "percent_change"),
                            kappa_weights = c("quadratic", "linear"),
                            alpha = 0.05,
                            B = 1000,
                            seed = NULL) {
  stability <- match.arg(stability)
  kappa_weights <- match.arg(kappa_weights)
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) ||
      alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be one number strictly between 0 and 1.", call. = FALSE)
  }
  .validate_bootstrap_args(B, seed)

  prep <- .delphi_prepare(ratings, expert_col, item_col, round_col,
                          rating_col, lo, hi)
  d <- prep$data
  rounds <- prep$rounds
  k <- as.integer(hi - lo + 1)

  if (is.null(agree_cut)) agree_cut <- hi - 1
  if (!is.numeric(agree_cut) || length(agree_cut) != 1L || !is.finite(agree_cut) ||
      agree_cut < lo || agree_cut > hi) {
    stop("`agree_cut` must lie within the rating scale.", call. = FALSE)
  }
  if (!is.null(consensus_threshold) &&
      (!is.numeric(consensus_threshold) || length(consensus_threshold) != 1L ||
       !is.finite(consensus_threshold) || consensus_threshold <= 0 ||
       consensus_threshold > 1)) {
    stop("`consensus_threshold` must be NULL or a proportion in (0, 1], ",
         "such as 0.75.", call. = FALSE)
  }

  items <- unique(d$item)
  V <- .delphi_disagreement_weights(k, kappa_weights)

  # Consensus in every round an item was rated.
  consensus <- do.call(rbind, lapply(items, function(it) {
    di <- d[d$item == it, , drop = FALSE]
    idx <- sort(unique(di$round_index))
    do.call(rbind, lapply(idx, function(r) {
      x <- di$rating[di$round_index == r]
      data.frame(item = it, round = rounds[r], n_experts = length(x),
                 n_agree = sum(x >= agree_cut),
                 prop_agree = mean(x >= agree_cut),
                 stringsAsFactors = FALSE)
    }))
  }))
  consensus$consensus <- if (is.null(consensus_threshold)) {
    NA
  } else {
    consensus$prop_agree >= consensus_threshold
  }
  rownames(consensus) <- NULL

  # Stability between consecutive rounds in which the item was rated.
  pairs <- list()
  for (it in items) {
    di <- d[d$item == it, , drop = FALSE]
    for (r in seq_len(length(rounds) - 1L)) {
      a <- di[di$round_index == r, , drop = FALSE]
      b <- di[di$round_index == r + 1L, , drop = FALSE]
      if (!nrow(a) || !nrow(b)) next
      shared <- intersect(a$expert, b$expert)
      x1 <- a$rating[match(shared, a$expert)] - as.integer(lo) + 1L
      x2 <- b$rating[match(shared, b$expert)] - as.integer(lo) + 1L
      pairs[[length(pairs) + 1L]] <- .delphi_pair_row(
        it, rounds[r], rounds[r + 1L], x1, x2, k, stability, V,
        as.integer(B), alpha, seed
      )
    }
  }
  stab <- if (length(pairs)) do.call(rbind, pairs) else {
    .delphi_pair_row("", "", "", integer(0), integer(0), k, stability, V,
                     0L, alpha, NULL)[0, ]
  }
  rownames(stab) <- NULL

  # One row per item: its last round, with the last pair of rounds beside it.
  results <- do.call(rbind, lapply(items, function(it) {
    ci <- consensus[consensus$item == it, , drop = FALSE]
    last <- ci[nrow(ci), ]
    si <- stab[stab$item == it, , drop = FALSE]
    sl <- if (nrow(si)) si[nrow(si), ] else NULL
    data.frame(
      item = it,
      n_rounds = nrow(ci),
      last_round = last$round,
      n_experts = last$n_experts,
      prop_agree = last$prop_agree,
      consensus = last$consensus,
      prop_unchanged = if (is.null(sl)) NA_real_ else sl$prop_unchanged,
      stability = if (is.null(sl)) NA_real_ else sl$value,
      stability_low = if (is.null(sl)) NA_real_ else sl$lower,
      stability_high = if (is.null(sl)) NA_real_ else sl$upper,
      stability_p = if (is.null(sl)) NA_real_ else sl$p_value,
      stable = if (is.null(sl)) NA else sl$stable,
      stringsAsFactors = FALSE
    )
  }))
  rownames(results) <- NULL

  results$recommendation <- ifelse(
    results$n_experts < 3L, "Insufficient panel",
    ifelse(is.na(results$consensus), "Descriptive only",
           ifelse(results$consensus, "Consensus", "No consensus"))
  )
  pct <- function(p) paste0(format(round(100 * p)), "%")
  threshold_txt <- if (is.null(consensus_threshold)) "" else pct(consensus_threshold)
  results$interpretation <- vapply(seq_len(nrow(results)), function(i) {
    r <- results[i, ]
    switch(
      r$recommendation,
      "Insufficient panel" = paste(
        "Fewer than three experts rated this item in its last round, so no",
        "consensus judgment is made."),
      "Descriptive only" = paste0(
        pct(r$prop_agree), " of experts agreed in the last round. No consensus ",
        "threshold was set, so no decision is made."),
      "Consensus" = paste0(
        "Consensus in the last round: ", pct(r$prop_agree), " agreed, against ",
        "a threshold of ", threshold_txt, ". Check the stability trend before ",
        "closing the item."),
      paste0(
        "No consensus in the last round: ", pct(r$prop_agree), " agreed, ",
        "against a threshold of ", threshold_txt, ". ",
        if (1 - r$prop_agree >= consensus_threshold) {
          paste0("The panel did agree in the other direction: ",
                 pct(1 - r$prop_agree), " rated it below the agreement cut. ",
                 "Whether that is consensus to exclude is for your protocol ",
                 "to say.")
        } else {
          paste("Consider another round, rewording, or reporting the item as",
                "without consensus.")
        })
    )
  }, character(1))
  results$status <- .workflow_status_from_recommendation(results$recommendation)

  panel <- data.frame(
    round = rounds,
    n_experts = vapply(seq_along(rounds), function(r) {
      length(unique(d$expert[d$round_index == r]))
    }, integer(1)),
    n_items = vapply(seq_along(rounds), function(r) {
      length(unique(d$item[d$round_index == r]))
    }, integer(1)),
    stringsAsFactors = FALSE
  )

  # Each round's relevance evidence, so compare_rounds() can read the process.
  round_fits <- lapply(seq_along(rounds), function(r) {
    dr <- d[d$round_index == r, , drop = FALSE]
    experts <- unique(dr$expert)
    its <- unique(dr$item)
    m <- matrix(NA_real_, length(experts), length(its),
                dimnames = list(experts, its))
    m[cbind(match(dr$expert, experts), match(dr$item, its))] <- dr$rating
    expert_validity(m, mode = "relevance", lo = lo, hi = hi,
                    relevance_cut = agree_cut, alpha = alpha,
                    agreement = "none", na.rm = TRUE)
  })
  names(round_fits) <- rounds

  scale_summary <- data.frame(
    n_items = nrow(results),
    n_rounds = length(rounds),
    n_consensus = sum(results$recommendation == "Consensus"),
    n_no_consensus = sum(results$recommendation == "No consensus"),
    n_insufficient = sum(results$recommendation == "Insufficient panel"),
    median_prop_unchanged = if (all(is.na(results$prop_unchanged))) NA_real_ else
      stats::median(results$prop_unchanged, na.rm = TRUE),
    stringsAsFactors = FALSE
  )

  settings <- list(
    method = "Delphi consensus and stability",
    lo = lo, hi = hi, agree_cut = agree_cut,
    consensus_threshold = consensus_threshold,
    stability = stability,
    kappa_weights = if (stability == "kappa") kappa_weights else NA_character_,
    alpha = alpha, B = as.integer(B), seed = seed,
    judge_type = "expert"
  )
  design <- list(
    type = "Delphi rounds",
    n_items = length(items),
    n_rounds = length(rounds),
    rounds = rounds,
    n_judges = length(unique(d$expert)),
    n_judges_per_round = panel$n_experts
  )

  .new_contentvalid_workflow(
    subclass = "contentvalid_delphi",
    workflow = "delphi",
    results = results,
    scale_summary = scale_summary,
    settings = settings,
    design = design,
    details = list(consensus = consensus, stability = stab, panel = panel,
                   round_fits = round_fits)
  )
}

.delphi_pair_label <- function(from, to) paste0(from, "->", to)

.delphi_wide <- function(stab, column, digits) {
  if (!nrow(stab)) return(NULL)
  lab <- .delphi_pair_label(stab$from_round, stab$to_round)
  pairs <- unique(lab)
  items <- unique(stab$item)
  out <- data.frame(item = items, stringsAsFactors = FALSE)
  for (p in pairs) {
    v <- rep(NA_real_, length(items))
    sel <- lab == p
    v[match(stab$item[sel], items)] <- stab[[column]][sel]
    out[[p]] <- round(v, digits)
  }
  out
}

#' @export
print.contentvalid_delphi <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  s <- x$settings
  r <- x$results
  panel <- x$details$panel
  stab <- x$details$stability

  cat("contentvalidR Delphi analysis\n")
  cat(strrep("-", 29), "\n", sep = "")
  cat("Items:", x$design$n_items, "| Experts:", x$design$n_judges,
      "| Rounds:", x$design$n_rounds,
      paste0("(", paste(x$design$rounds, collapse = ", "), ")"), "\n")
  cat("Experts per round:", paste(panel$n_experts, collapse = ", "), "\n")
  cat(strwrap(paste0(
    "Agreement: a rating of ", format(s$agree_cut), " or higher on the ",
    format(s$lo), "-", format(s$hi), " scale. Consensus threshold: ",
    if (is.null(s$consensus_threshold)) "none set, so agreement is descriptive." else
      paste0(format(100 * s$consensus_threshold), "%, fixed before the study.")
  ), width = 76), sep = "\n")
  method_label <- switch(
    s$stability,
    kappa = paste0("weighted kappa (", s$kappa_weights, " weights)"),
    lambda = "lambda (Chaffin & Talley, 1980)",
    chisq_individual = "individual chi-square (Chaffin & Talley, 1980)",
    chisq_group = "group chi-square (Dajani et al., 1979)",
    percent_change = "net percent change (Scheibe et al., 1975)"
  )
  cat("Stability:", method_label, "between consecutive rounds\n\n")

  n_c <- sum(r$recommendation == "Consensus")
  n_n <- sum(r$recommendation == "No consensus")
  n_i <- sum(r$recommendation == "Insufficient panel")
  if (is.null(s$consensus_threshold)) {
    cat("No consensus threshold was set; agreement is reported descriptively.\n")
  } else {
    cat(n_c, "item(s) reached consensus in their last round;", n_n,
        "did not")
    if (n_i) cat(";", n_i, "had too few experts")
    cat(".\n")
    if (n_n) cat("No consensus:", paste(r$item[r$recommendation == "No consensus"],
                                        collapse = ", "), "\n")
  }

  cat("\nItem-level evidence (last round, and the last pair of rounds):\n")
  val <- .delphi_value_label(s$stability)
  tab <- data.frame(item = r$item, last_round = r$last_round,
                    n = r$n_experts, prop_agree = round(r$prop_agree, digits),
                    prop_unchanged = round(r$prop_unchanged, digits),
                    stringsAsFactors = FALSE)
  tab[[val]] <- round(r$stability, digits)
  if (s$stability == "kappa") {
    tab$low <- round(r$stability_low, digits)
    tab$high <- round(r$stability_high, digits)
  }
  if (s$stability %in% c("chisq_individual", "chisq_group")) {
    tab$p_value <- round(r$stability_p, 3)
  }
  if (s$stability %in% c("chisq_individual", "chisq_group", "percent_change")) {
    tab$stable <- r$stable
  }
  tab$recommendation <- r$recommendation
  print(tab, row.names = FALSE)

  if (nrow(stab) && length(unique(paste(stab$from_round, stab$to_round))) > 1L) {
    cat("\nStability trend (", val, ") by pair of rounds:\n", sep = "")
    print(.delphi_wide(stab, "value", digits), row.names = FALSE)
    cat("\nShare of experts who kept their rating, by pair of rounds:\n")
    print(.delphi_wide(stab, "prop_unchanged", digits), row.names = FALSE)
  }

  flagged <- stab[nzchar(stab$note), , drop = FALSE]
  if (nrow(flagged)) {
    cat("\nNotes:\n")
    for (i in seq_len(nrow(flagged))) {
      cat(strwrap(paste0(flagged$item[i], " (",
                         .delphi_pair_label(flagged$from_round[i],
                                            flagged$to_round[i]), "): ",
                         flagged$note[i]),
                  width = 76, initial = "  ", prefix = "    "), sep = "\n")
    }
  }

  if (identical(s$stability, "kappa") &&
      any(!is.na(stab$n_boot_usable) & stab$n_boot_usable < s$B)) {
    cat("\n")
    cat(strwrap(paste(
      "In some resamples kappa was undefined because every resampled rating",
      "fell in one category. Those intervals use the remaining resamples",
      "(n_boot_usable in details$stability), so treat them as rough."
    ), width = 76), sep = "\n")
  }

  cat("\n")
  cat(strwrap(.delphi_method_note(s$stability, s$kappa_weights), width = 76),
      sep = "\n")
  if (is.null(s$consensus_threshold)) {
    cat("\n")
    cat(strwrap(paste(
      "Diamond et al. (2014) recommend defining consensus before the study.",
      "Their review found a median threshold of 75%, which describes common",
      "practice rather than a validated cut-off."
    ), width = 76), sep = "\n")
  }
  if (length(unique(panel$n_experts)) > 1L) {
    cat("\n")
    cat(strwrap(paste0(
      "The panel changed size across rounds (", paste(panel$n_experts,
                                                        collapse = ", "),
      " experts). Stability uses only the experts who rated an item in both ",
      "rounds, and a result from fewer experts is weaker evidence."
    ), width = 76), sep = "\n")
  }

  if (.show_key()) {
    key <- c("prop_agree", "prop_unchanged",
             switch(s$stability, kappa = "kappa_w", lambda = "lambda",
                    chisq_individual = "chi_sq_individual",
                    chisq_group = "chi_sq_group",
                    percent_change = "percent_change"))
    .print_key(key)
    .print_status_legend()
    cat("\nSee `contentvalid_glossary()` for all terms, or set",
        "\n`options(contentvalidR.show_key = FALSE)` to hide this key.\n")
  }

  cat("\nConsensus is not correctness, and 'No consensus' is not an instruction to\n")
  cat("drop an item. Read these results with the experts' comments.\n")
  invisible(x)
}

.delphi_item_colours <- function(n) {
  if (n == 1L) return("black")
  grDevices::hcl.colors(n, palette = "Dark 3")
}

# Nudge labels apart so items that end at the same height stay readable.
.delphi_dodge <- function(y, gap) {
  o <- order(y)
  spread <- y[o]
  for (i in seq_along(spread)[-1]) {
    if (spread[i] - spread[i - 1] < gap) spread[i] <- spread[i - 1] + gap
  }
  out <- numeric(length(y))
  out[o] <- spread
  out
}

# Label each item's line at its last point, which also shows where an item
# left the study: a line that stops in round 2 settled in round 2.
.delphi_end_labels <- function(xs, ys, labels, colours, ylim) {
  last <- vapply(seq_along(labels), function(i) {
    keep <- is.finite(xs[[i]]) & is.finite(ys[[i]])
    if (any(keep)) max(which(keep)) else NA_integer_
  }, integer(1))
  ok <- !is.na(last)
  if (!any(ok)) return(invisible(NULL))

  at_x <- vapply(which(ok), function(i) xs[[i]][last[i]], numeric(1))
  at_y <- vapply(which(ok), function(i) ys[[i]][last[i]], numeric(1))
  gap <- 0.05 * diff(ylim)
  for (xx in unique(at_x)) {
    same <- at_x == xx
    if (sum(same) > 1L) at_y[same] <- .delphi_dodge(at_y[same], gap)
  }
  graphics::text(at_x, at_y, labels = labels[ok], pos = 4, cex = 0.7,
                 col = colours[ok], xpd = NA)
  invisible(NULL)
}

# The axis label says which statistic is plotted, in full.
.delphi_axis_label <- function(settings) {
  switch(settings$stability,
         kappa = paste0("Weighted kappa (", settings$kappa_weights, ")"),
         lambda = "Goodman-Kruskal lambda",
         chisq_individual = "Individual chi-square",
         chisq_group = "Group chi-square",
         percent_change = "Net change in the distribution")
}

#' Plot a Delphi analysis
#'
#' @description
#' Draws the two questions a Delphi asks, one at a time: whether the panel
#' agrees, and whether it has stopped moving. Both are trends across rounds,
#' which a plot shows better than a table of round pairs.
#'
#' @details
#' `which = "consensus"` draws each item's share of experts agreeing, round by
#' round. A line that stops early belongs to an item that settled and was set
#' aside. The consensus threshold is drawn only when one was set, because the
#' analysis applies no threshold without it.
#'
#' `which = "stability"` draws the stability statistic for each pair of
#' consecutive rounds, with the share of experts who kept their rating as open
#' circles. No bands or shaded regions are drawn behind kappa: its verbal
#' benchmarks are arbitrary, and kappa falls as a panel converges, so a shaded
#' "good" region would mislead exactly when a Delphi is succeeding. See
#' [delphi_validity()].
#'
#' @param x A fitted `contentvalid_delphi` object.
#' @param which `"consensus"` (default) or `"stability"`.
#' @param show_legend Draw the legend. Defaults to `TRUE`.
#' @param ... Passed to [graphics::plot()].
#'
#' @return `x`, invisibly. Called for the plot it draws.
#'
#' @seealso [delphi_validity()].
#'
#' @examples
#' r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4), S2 = c(2, 3, 2, 1, 3, 2))
#' r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2))
#' long <- function(m, round) {
#'   data.frame(expert = paste0("E", seq_len(nrow(m))),
#'              item = rep(colnames(m), each = nrow(m)),
#'              round = round, rating = as.vector(m))
#' }
#' fit <- delphi_validity(rbind(long(r1, 1), long(r2, 2)), lo = 1, hi = 4,
#'                        consensus_threshold = 0.75, B = 0)
#' plot(fit)
#' plot(fit, which = "stability")
#' @export
plot.contentvalid_delphi <- function(x, which = c("consensus", "stability"),
                                     show_legend = TRUE, ...) {
  which <- match.arg(which)
  .validate_flag(show_legend, "show_legend")
  rounds <- x$design$rounds
  items <- unique(x$results$item)
  colours <- .delphi_item_colours(length(items))
  # Room on the right for the item labels.
  right_pad <- 1 + 0.35 * max(nchar(items))

  if (which == "consensus") {
    cons <- x$details$consensus
    xs <- lapply(items, function(it) match(cons$round[cons$item == it], rounds))
    ys <- lapply(items, function(it) cons$prop_agree[cons$item == it])

    # Headroom at the top keeps the legend clear of the lines.
    ylim <- c(0, 1.16)
    graphics::plot(NA, xlim = c(1, length(rounds) + right_pad * 0.12),
                   ylim = ylim, yaxt = "n", xaxt = "n",
                   xlab = "Round", ylab = "Share of experts agreeing", ...)
    graphics::axis(2, at = seq(0, 1, by = 0.25))
    graphics::axis(1, at = seq_along(rounds), labels = rounds)
    threshold <- x$settings$consensus_threshold
    if (!is.null(threshold)) graphics::abline(h = threshold, lty = 3)
    for (i in seq_along(items)) {
      graphics::lines(xs[[i]], ys[[i]], col = colours[i], lwd = 1.5)
      graphics::points(xs[[i]], ys[[i]], col = colours[i], pch = 19, cex = 0.8)
    }
    .delphi_end_labels(xs, ys, items, colours, ylim)
    if (isTRUE(show_legend) && !is.null(threshold)) {
      graphics::legend("top",
                       legend = paste0("Consensus threshold (",
                                       format(100 * threshold), "%)"),
                       lty = 3, bty = "n", cex = 0.7, horiz = TRUE)
    }
    return(invisible(x))
  }

  stab <- x$details$stability
  if (!nrow(stab)) {
    stop("This analysis has no pair of consecutive rounds to plot.",
         call. = FALSE)
  }
  pair_at <- match(stab$from_round, rounds)
  xs <- lapply(items, function(it) pair_at[stab$item == it])
  ys <- lapply(items, function(it) stab$value[stab$item == it])
  unchanged <- lapply(items, function(it) stab$prop_unchanged[stab$item == it])

  finite <- unlist(c(ys, unchanged))
  finite <- finite[is.finite(finite)]
  ylim <- if (!length(finite)) c(0, 1) else range(c(0, 1, finite))
  ylim[2] <- ylim[2] + 0.16 * diff(ylim)
  labels <- paste0(stab$from_round[!duplicated(pair_at)], "-",
                   stab$to_round[!duplicated(pair_at)])

  graphics::plot(NA, xlim = c(1, max(pair_at) + right_pad * 0.12), ylim = ylim,
                 xaxt = "n", xlab = "Pair of rounds",
                 ylab = .delphi_axis_label(x$settings), ...)
  graphics::axis(1, at = sort(unique(pair_at)), labels = labels)
  for (i in seq_along(items)) {
    graphics::lines(xs[[i]], ys[[i]], col = colours[i], lwd = 1.5)
    graphics::points(xs[[i]], ys[[i]], col = colours[i], pch = 19, cex = 0.8)
    graphics::points(xs[[i]], unchanged[[i]], col = colours[i], pch = 1, cex = 0.8)
  }
  .delphi_end_labels(xs, ys, items, colours, ylim)
  if (isTRUE(show_legend)) {
    graphics::legend("top",
                     legend = c(.delphi_axis_label(x$settings),
                                "Kept their rating"),
                     pch = c(19, 1), bty = "n", cex = 0.7, horiz = TRUE)
  }
  invisible(x)
}

#' @export
summary.contentvalid_delphi <- function(object, ...) {
  out <- .workflow_summary_core(object)
  out$panel <- object$details$panel
  out$stability_method <- object$settings$stability
  class(out) <- c("summary.contentvalid_delphi", "summary.contentvalid_workflow")
  out
}

#' @export
print.summary.contentvalid_delphi <- function(x, digits = 3, ...) {
  .validate_digits(digits)
  cat("Summary of Delphi consensus and stability\n")
  cat(strrep("-", 41), "\n", sep = "")
  cat("Rounds:", nrow(x$panel), "| Experts per round:",
      paste(x$panel$n_experts, collapse = ", "), "\n")
  if (x$n_descriptive > 0L) {
    cat("Descriptive only:", x$n_descriptive, "of", x$n_items,
        "item(s); no consensus threshold was set.\n")
  } else {
    cat("Consensus:", x$n_supported, "of", x$n_items, "item(s)\n")
    cat("No consensus:", x$n_review, "of", x$n_items, "item(s)\n")
  }
  if (x$n_insufficient > 0L) {
    cat("Too few experts:", x$n_insufficient, "item(s)\n")
  }
  cat("Stability statistic:", x$stability_method, "\n")
  med <- x$scale_summary$median_prop_unchanged
  if (length(med) && !is.na(med)) {
    cat("Median share of experts keeping their rating (last pair):",
        format(round(med, digits)), "\n")
  }
  invisible(x)
}

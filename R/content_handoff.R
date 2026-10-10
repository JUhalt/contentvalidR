# Schema version 1 of the handoff object, agreed with the nomologR maintainers
# on 2026-09-16. The consumer matches on the "cv_handoff" class and reads the
# documented fields, so neither package depends on the other. Add fields in a
# minor release if needed; only `schema_version` gates a reader.
.handoff_schema_version <- 1L

# The frozen contract for version 1, as data rather than prose, so the
# documentation and the tests read from one source. Adding an optional field
# means adding it here; changing or removing anything here means version 2.
.handoff_schema <- function() {
  statistics <- c(item = "character", statistic = "character",
                  value = "numeric", criterion = "numeric", round = "integer",
                  lower = "numeric", upper = "numeric",
                  interval_method = "character", interval_level = "numeric",
                  note = "character")
  list(
    version = .handoff_schema_version,
    top_level = c("items", "scales", "item_evidence", "item_statistics",
                  "provenance", "panel_statistics"),
    item_evidence = c(item = "character", scale = "character",
                      carried = "logical", status = "character",
                      recommendation = "character", n_judges = "integer",
                      rule = "character", round = "integer",
                      keying = "integer", response_min = "integer",
                      response_max = "integer"),
    item_statistics = statistics,
    panel_statistics = statistics[names(statistics) != "item"],
    provenance = c(schema_version = "integer", package = "character",
                   package_version = "character", workflow = "character",
                   mode = "character", keep = "character",
                   method = "character", citation = "character",
                   settings = "list", design = "list", created = "Date")
  )
}

.handoff_stat <- function(items, statistic, value, criterion = NA_real_,
                          lower = NA_real_, upper = NA_real_,
                          interval_method = NA_character_,
                          interval_level = NA_real_, note = "") {
  out <- data.frame(
    item = as.character(items),
    statistic = statistic,
    value = as.numeric(value),
    criterion = as.numeric(criterion),
    lower = as.numeric(lower),
    upper = as.numeric(upper),
    interval_method = as.character(interval_method),
    interval_level = as.numeric(interval_level),
    # rep_len keeps a zero-row block zero-row: the default is length 1.
    note = .handoff_note(rep_len(note, length(items))),
    stringsAsFactors = FALSE
  )
  .handoff_no_interval(out)
}

# `note` is display text, so it is always a character vector with no NA: empty
# means there is nothing to say, never that something is missing.
.handoff_note <- function(note) {
  note <- as.character(note)
  note[is.na(note)] <- ""
  trimws(note)
}

# Agreed with nomologR (#46): NA in the four interval columns means "this
# statistic has no interval", never missing data. A row whose bounds could not
# be computed therefore carries no method or level either, so the four columns
# are NA together or not at all.
.handoff_no_interval <- function(stats) {
  none <- !is.finite(stats$lower) | !is.finite(stats$upper) |
    is.na(stats$interval_method)
  stats$lower[none] <- NA_real_
  stats$upper[none] <- NA_real_
  stats$interval_method[none] <- NA_character_
  stats$interval_level[none] <- NA_real_
  stats
}

# An interval whose bounds coincide, so every resample gave the same value.
# Its bounds are real, computed values, but they say nothing about precision,
# so a row carrying one says so in its note.
.handoff_zero_width <- function(lower, upper) {
  is.finite(lower) & is.finite(upper) &
    abs(upper - lower) < sqrt(.Machine$double.eps)
}

.handoff_interval_label <- function(method) {
  if (!is.character(method) || length(method) != 1L) return(NA_character_)
  switch(method,
         wilson = "Wilson score",
         agresti_coull = "Agresti-Coull",
         exact = "Clopper-Pearson exact",
         NA_character_)
}

# Item keying and the response scale describe the instrument as respondents
# will see it. No content-validity fit knows either: a panel's `lo` and `hi`
# are the scale the *experts* rated relevance on, usually 1 to 4, and have
# nothing to do with the 1-to-5 or 1-to-7 scale respondents answer. Filling
# these columns from `fit$settings` would therefore be wrong, not merely
# unrequested -- a reader screening for out-of-range answers would reject every
# legitimate top-category response. They come from the analyst or not at all.
.handoff_instrument <- function(items, reverse_keyed, response_scale) {
  n <- length(items)

  keying <- rep(NA_integer_, n)
  if (!is.null(reverse_keyed)) {
    if (!is.character(reverse_keyed) || anyNA(reverse_keyed)) {
      stop("`reverse_keyed` must be a character vector of item names, or ",
           "`character(0)` to state that no item is reverse-keyed.",
           call. = FALSE)
    }
    unknown <- setdiff(reverse_keyed, items)
    if (length(unknown)) {
      stop("`reverse_keyed` names ", .n_noun(length(unknown), "item"),
           " not in this analysis: ", paste(unknown, collapse = ", "), ".",
           call. = FALSE)
    }
    # Supplying the argument at all is a statement about every item: the ones
    # named are reversed and the rest are not.
    keying <- ifelse(items %in% reverse_keyed, -1L, 1L)
  }

  response_min <- rep(NA_integer_, n)
  response_max <- rep(NA_integer_, n)
  if (!is.null(response_scale)) {
    ok <- is.numeric(response_scale) && length(response_scale) == 2L &&
      all(is.finite(response_scale)) &&
      all(response_scale == floor(response_scale)) &&
      response_scale[2] > response_scale[1]
    if (!ok) {
      stop("`response_scale` must be two whole numbers, the lowest and ",
           "highest answer a respondent can give, such as `c(1, 5)`.",
           call. = FALSE)
    }
    response_min <- rep(as.integer(response_scale[1]), n)
    response_max <- rep(as.integer(response_scale[2]), n)
  }

  # Recoding a reverse-keyed item needs the scale's limits, so keying without
  # them is almost always an oversight. Say so here, where it can still be
  # fixed, rather than let a reader refuse later. `character(0)` reverses
  # nothing, so it needs no scale and draws no warning.
  n_reversed <- sum(keying == -1L, na.rm = TRUE)
  if (n_reversed > 0L && is.null(response_scale)) {
    warning(.n_noun(n_reversed, "item is", "items are"),
            " marked reverse-keyed, but ",
            "`response_scale` was not given. A reverse-keyed item cannot be ",
            "recoded without the lowest and highest answer a respondent can ",
            "give, so add, for example, `response_scale = c(1, 5)`.",
            call. = FALSE)
  }

  list(keying = as.integer(keying), response_min = response_min,
       response_max = response_max)
}

.handoff_column <- function(results, name) {
  if (name %in% names(results)) results[[name]] else NA_real_
}

# The panel-level agreement interval is not per item, so it travels in its own
# table with the same columns as `item_statistics`, less `item`.
.handoff_panel_statistics <- function(fit, round) {
  out <- data.frame(statistic = character(0), value = numeric(0),
                    criterion = numeric(0), round = integer(0),
                    lower = numeric(0), upper = numeric(0),
                    interval_method = character(0), interval_level = numeric(0),
                    note = character(0), stringsAsFactors = FALSE)
  ag <- if (is.list(fit$details)) fit$details$agreement else NULL
  if (!inherits(ag, "contentvalid_agreement")) return(out)

  has_interval <- is.finite(ag$ci_low) && is.finite(ag$ci_high)
  note <- c(
    if (!is.finite(ag$estimate)) {
      "The coefficient is undefined for these ratings, so it has no interval."
    } else if (!has_interval) {
      paste("The bootstrap interval could not be computed: too few resamples",
            "produced a usable coefficient.")
    } else if (.handoff_zero_width(ag$ci_low, ag$ci_high)) {
      # The bounds are kept, as computed; the note says what they mean, as
      # panel_agreement() does in its printout.
      paste("Every resample of the items gave the same value, so the interval",
            "has no width: that reflects items rated alike, not precision.")
    },
    # The console warns that the interval for AC1 is unvalidated. The caveat
    # belongs with the number wherever it is shown, not only where it was
    # computed (#56).
    if (identical(ag$method, "ac1") && has_interval) {
      paste("Zapf et al. (2016) evaluated this bootstrap for Fleiss' kappa",
            "and Krippendorff's alpha, not for AC1. Applying it here is this",
            "package's extension, and its coverage is unknown.")
    }
  )

  row <- .handoff_no_interval(data.frame(
    statistic = .agreement_label(ag$method, ag$level),
    value = as.numeric(ag$estimate),
    criterion = NA_real_,
    round = as.integer(round),
    lower = as.numeric(ag$ci_low),
    upper = as.numeric(ag$ci_high),
    interval_method = "item-resampling percentile bootstrap",
    interval_level = 1 - ag$alpha,
    note = paste(note, collapse = " "),
    stringsAsFactors = FALSE
  ))
  rbind(out, row)
}

# delphi_validity() records why a statistic is undefined; the handoff carries
# that sentence so a reader need not re-derive method-specific semantics. An
# item rated in a single round has no pair at all, and therefore no row in the
# fit to take a note from, so that sentence is written here.
#
# Returns three notes for each item. `pair` goes on every row taken from the
# item's last pair of rounds. It says when that pair is earlier than the
# item's last round (rated in rounds 1, 2 and 4: the pair is 1 and 2, and the
# rows are dated round 4), and how many experts the pair compared when that
# is fewer than rated the item in its last round, the n a reader sees beside
# it. `stability` is the note for the stability statistic itself: the pair's
# note, why the statistic is undefined when it is, and what an interval of
# zero width means. `reading` says which way the method's criterion reads and
# whether the fit read the item as stable, for the methods that decide that.
.handoff_delphi_notes <- function(fit, results) {
  stab <- fit$details$stability
  rounds <- fit$design$rounds
  rated <- .delphi_rated_rounds(fit)
  n <- nrow(results)
  gap <- character(n)
  paired <- character(n)
  own <- character(n)
  for (i in seq_len(n)) {
    rows <- which(stab$item == results$item[i])
    idx <- sort(rated[[results$item[i]]])
    if (!length(rows)) {
      own[i] <- if (length(idx) >= 2L) {
        # Rated more than once, but never in two rounds that follow each other.
        paste0("This item was rated in rounds ", .and_list(rounds[idx]),
               ", which are not consecutive, so no pair of rounds was ",
               "compared.")
      } else {
        paste("This item was rated in only one round, so there was no pair",
              "of rounds to compare.")
      }
      next
    }
    last <- rows[length(rows)]
    own[i] <- stab$note[last]
    if (length(idx) &&
        !identical(as.character(stab$to_round[last]),
                   as.character(rounds[max(idx)]))) {
      gap[i] <- paste0("From rounds ", stab$from_round[last], " and ",
                       stab$to_round[last], ", the item's last consecutive ",
                       "pair; it was last rated in round ", rounds[max(idx)],
                       ".")
    }
    # Stability compares only the experts who rated the item in both rounds,
    # which can be fewer than the last round's n when the panel changed.
    np <- if (is.null(stab$n_paired)) NA_integer_ else stab$n_paired[last]
    if (!is.na(np) && np > 0L && isTRUE(np < results$n_experts[i])) {
      paired[i] <- sprintf(paste("From the %d experts who rated the item in",
                                 "both rounds; %d rated it in its last round."),
                           as.integer(np), as.integer(results$n_experts[i]))
    }
  }
  own[is.na(own)] <- ""
  # The bounds are kept as computed; the note says what they mean.
  width <- ifelse(
    .handoff_zero_width(.handoff_column(results, "stability_low"),
                        .handoff_column(results, "stability_high")),
    paste("Every resample of the experts gave the same value, so the interval",
          "has no width: that reflects how alike the paired ratings were, not",
          "precision."),
    ""
  )
  pair <- .handoff_join(gap, paired)
  list(pair = pair, stability = .handoff_join(pair, own, width),
       reading = .handoff_delphi_reading(fit$settings$stability, results))
}

# Which way a stability criterion reads, and what the fit read. The two
# chi-square methods put the same alpha in `criterion` but read it in
# opposite directions, so the row says which, and carries the fit's own
# reading (`stable` in the results) rather than leave a reader to compare
# `value` with `criterion`. Kappa and lambda have no criterion and make no
# such call.
.handoff_delphi_reading <- function(method, results) {
  n <- nrow(results)
  rule <- switch(
    if (is.character(method) && length(method) == 1L) method else "",
    chisq_individual = paste("Stable when p is below alpha: Chaffin and",
                             "Talley (1980) read dependence between the two",
                             "rounds' ratings as stability."),
    chisq_group = paste("Stable when p is at or above alpha: Dajani et al.",
                        "(1979) read no detectable difference between the",
                        "two rounds' distributions as stability."),
    percent_change = paste("Stable when the change is below .15, the rule of",
                           "Scheibe et al. (1975/2002)."),
    NULL
  )
  if (is.null(rule)) return(character(n))
  stable <- rep_len(as.logical(.handoff_column(results, "stable")), n)
  verdict <- ifelse(is.na(stable), "",
                    ifelse(stable, "Read as stable.", "Not read as stable."))
  .handoff_join(rep_len(rule, n), verdict)
}

# Joins sentences row by row, skipping the empty ones, so a missing part
# never leaves a doubled space.
.handoff_join <- function(...) {
  parts <- lapply(list(...), function(p) {
    p <- as.character(p)
    p[is.na(p)] <- ""
    trimws(p)
  })
  n <- max(0L, lengths(parts))
  parts <- lapply(parts, rep_len, n)
  vapply(seq_len(n), function(i) {
    bits <- vapply(parts, `[[`, character(1), i)
    paste(bits[nzchar(bits)], collapse = " ")
  }, character(1))
}

# A Delphi study ends one item at a time: an item's evidence is dated by the
# round where it was last rated, which is earlier than the final round when
# it was set aside.
# Its evidence therefore comes from its own last round, and `round` carries that
# round's index rather than a constant.
.handoff_delphi_spec <- function(fit, results) {
  s <- fit$settings
  level <- 1 - s$alpha
  rounds <- fit$design$rounds
  round_index <- match(results$last_round, rounds)
  threshold <- s$consensus_threshold

  # The round is given by its position, with its label beside it when the
  # label is not that number, so "round 3 of 3" never reads "round 4 of 3".
  # A label that already says its position ("2", "R2", "Round 2") is not
  # repeated beside it.
  says_position <- vapply(seq_along(round_index), function(i) {
    lab <- as.character(results$last_round[i])
    num <- regmatches(lab, regexpr("[0-9]+(\\.[0-9]+)?", lab))
    length(num) == 1L && isTRUE(as.numeric(num) == round_index[i])
  }, logical(1))
  where <- sprintf(
    "last rated in round %d of %d%s", round_index, length(rounds),
    ifelse(says_position, "", paste0(" (\"", results$last_round, "\")"))
  )
  # The rule states what was supplied. Whether the threshold was fixed before
  # the study is for the analyst to report; the software cannot know it.
  rule <- if (is.null(threshold)) {
    paste0("no consensus threshold was supplied, so agreement is descriptive ",
           "(Diamond et al., 2014, recommend fixing one before the study); ",
           where)
  } else {
    sprintf(paste0("consensus when at least %s of experts rated the item %s",
                   "%s on the %s to %s scale (threshold as supplied; Diamond ",
                   "et al., 2014, recommend fixing it before the study); %s"),
            .delphi_percent(threshold), format(s$agree_cut),
            if (s$agree_cut < s$hi) " or higher" else "",
            format(s$lo), format(s$hi), where)
  }
  # Too few experts is its own reason, with or without a threshold: the rule
  # beside an "Insufficient data" status must explain that status.
  thin <- results$recommendation %in% "Insufficient panel"
  rule[thin] <- paste0("fewer than three experts rated the item in its last ",
                       "round, so no consensus judgment was made; ",
                       where[thin])

  stability_label <- switch(
    s$stability,
    kappa = paste0("weighted kappa (", s$kappa_weights, ")"),
    lambda = "Goodman-Kruskal lambda",
    chisq_individual = "individual chi-square",
    chisq_group = "group chi-square",
    percent_change = "net percent change"
  )
  stability_citation <- switch(
    s$stability,
    kappa = c("Holey et al. (2007)", "Cohen (1968)", "Fleiss & Cohen (1973)"),
    lambda = "Chaffin & Talley (1980)",
    chisq_individual = "Chaffin & Talley (1980)",
    chisq_group = "Dajani et al. (1979)",
    percent_change = "Scheibe et al. (1975/2002)"
  )

  # Relevance evidence comes from each item's own last round, so the interval
  # columns are the ones that round's expert_validity() fit already computed.
  last_fit_stat <- function(column) {
    out <- rep(NA_real_, nrow(results))
    for (r in unique(round_index)) {
      rf <- fit$details$round_fits[[r]]
      rows <- which(round_index == r)
      idx <- match(results$item[rows], rf$results$item)
      if (column %in% names(rf$results)) out[rows] <- rf$results[[column]][idx]
    }
    out
  }
  proportion_label <- .handoff_interval_label(
    fit$details$round_fits[[1]]$settings$proportion_ci
  )

  notes <- .handoff_delphi_notes(fit, results)
  statistics <- rbind(
    .handoff_stat(results$item, "I-CVI", results$prop_agree,
                  if (is.null(threshold)) NA_real_ else threshold,
                  lower = last_fit_stat("I_CVI_low"),
                  upper = last_fit_stat("I_CVI_high"),
                  interval_method = proportion_label,
                  interval_level = level),
    .handoff_stat(results$item, "Aiken's V", last_fit_stat("V"),
                  lower = last_fit_stat("ci_low"),
                  upper = last_fit_stat("ci_high"),
                  interval_method = "Penfield-Giacobbi score",
                  interval_level = level),
    # No criterion: a Delphi decides on the consensus threshold, not on the
    # 0.74 kappa rule that expert_validity() applies.
    .handoff_stat(results$item, "modified kappa", last_fit_stat("kappa_mod")),
    .handoff_stat(results$item, "proportion unchanged", results$prop_unchanged,
                  note = notes$pair),
    # The row that carries a stability criterion also says which way it
    # reads and what the fit read: net percent change here, the p value of
    # the chi-square methods below.
    .handoff_stat(results$item, stability_label, results$stability,
                  criterion = if (s$stability == "percent_change") {
                    .delphi_scheibe_cut
                  } else {
                    NA_real_
                  },
                  lower = results$stability_low,
                  upper = results$stability_high,
                  interval_method = if (s$stability == "kappa") {
                    "expert-resampling percentile bootstrap"
                  } else {
                    NA_character_
                  },
                  interval_level = level,
                  note = if (s$stability == "percent_change") {
                    .handoff_join(notes$stability, notes$reading)
                  } else {
                    notes$stability
                  })
  )
  if (s$stability %in% c("chisq_individual", "chisq_group")) {
    statistics <- rbind(
      statistics,
      .handoff_stat(results$item, "stability p_value", results$stability_p,
                    s$alpha, note = .handoff_join(notes$pair, notes$reading))
    )
  }

  list(
    scale = rep(NA_character_, nrow(results)),
    n_judges = as.integer(results$n_experts),
    rule = rule,
    round = as.integer(round_index),
    citation = c("Holey et al. (2007)", "Diamond et al. (2014)",
                 setdiff(stability_citation, "Holey et al. (2007)"),
                 "Aiken (1980)", "Polit et al. (2007)"),
    statistics = statistics
  )
}

# The construct-rating `p_value` is the omnibus p. An item can meet it and
# still be held back by a planned contrast, so that row says so: a reader who
# sees a statistic meeting its criterion beside a "Review" decision is told
# which test decided.
#
# The note names what held the item back. A contrast with no p (every judge
# rated the intended construct and another the same) is said in words: quoting
# the largest p among the other contrasts would give a p that meets alpha
# beside a decision that says a contrast did not. A missing omnibus p is
# explained too, as the note column promises.
.handoff_rating_notes <- function(fit, results, alpha) {
  pass <- .handoff_column(results, "contrast_pass")
  largest <- .handoff_column(results, "max_contrast_p")
  holm <- identical(fit$settings$adjust, "holm")
  contrasts <- if (is.list(fit$details)) fit$details$contrasts else NULL
  no_p <- is.na(results$p_value)
  held <- !no_p & results$p_value <= alpha & !(pass %in% TRUE) &
    results$recommendation %in% "Review"

  out <- character(nrow(results))
  for (i in which(held)) {
    tied <- character(0)
    if (is.data.frame(contrasts) && nrow(contrasts)) {
      own <- contrasts[contrasts$item == results$item[i], , drop = FALSE]
      tied <- as.character(own$competitor[is.na(own$p_adj)])
    }
    reason <- if (length(tied)) {
      paste0("; every judge rated the intended construct and ",
             paste(tied, collapse = ", "),
             " the same, so that contrast has no p.")
    } else if (is.na(largest[i])) {
      ", and not every one did."
    } else {
      paste0("; the largest ", if (holm) "Holm-adjusted " else "", "contrast ",
             .p_phrase(largest[i]), ".")
    }
    out[i] <- paste0("This omnibus p meets alpha, but the rule also needs ",
                     "every planned contrast to pass", reason)
  }
  insufficient <- results$recommendation %in% "Insufficient data"
  out[no_p & insufficient] <- paste(
    "No test: fewer than two judges rated the item against every construct."
  )
  out[no_p & !insufficient] <- "No test: the ratings left no variance to test."
  out
}

# Per-workflow evidence: the construct each item belongs to, the effective judge
# count, the decision rule in words, the citations for the method that ran, and
# the statistics that rule was applied to.
.handoff_spec <- function(fit, results) {
  alpha <- if (is.null(fit$settings$alpha)) NA_real_ else fit$settings$alpha
  level <- 1 - alpha
  proportion_label <- .handoff_interval_label(fit$settings$proportion_ci)
  n <- nrow(results)
  blank <- .handoff_stat(character(0), character(0), numeric(0), numeric(0),
                         numeric(0), numeric(0), character(0), numeric(0))

  if (inherits(fit, "contentvalid_sort")) {
    return(list(
      scale = as.character(results$target),
      n_judges = as.integer(results$n),
      # A rule is quoted downstream as the reason for a decision, so it never
      # carries a missing count: it says why no count applies.
      rule = ifelse(
        results$n < 1L,
        sprintf(paste("no judge sorted the item, so the exact binomial",
                      "target-count test (Howard & Melloy, 2016) was not",
                      "applied, alpha = %s"), .fmt_alpha(alpha)),
        ifelse(
          is.na(results$critical_n_target),
          sprintf(paste("no count of target assignments out of %d can meet",
                        "the exact binomial target-count test (Howard &",
                        "Melloy, 2016), alpha = %s"),
                  as.integer(results$n), .fmt_alpha(alpha)),
          sprintf(paste("target assignments >= %d of %d (exact binomial",
                        "target-count test; Howard & Melloy, 2016), alpha = %s"),
                  as.integer(results$critical_n_target), as.integer(results$n),
                  .fmt_alpha(alpha))
        )
      ),
      citation = c("Anderson & Gerbing (1991)", "Howard & Melloy (2016)",
                   "Colquitt et al. (2019)"),
      statistics = rbind(
        .handoff_stat(results$item, "Psa", results$psa,
                      results$critical_n_target / results$n,
                      lower = .handoff_column(results, "psa_low"),
                      upper = .handoff_column(results, "psa_high"),
                      interval_method = proportion_label,
                      interval_level = level),
        .handoff_stat(results$item, "Csv", results$csv),
        .handoff_stat(results$item, "p_value", results$p_value, alpha)
      )
    ))
  }

  if (inherits(fit, "contentvalid_delphi")) return(.handoff_delphi_spec(fit, results))

  if (inherits(fit, "contentvalid_rating")) {
    return(list(
      scale = as.character(results$target),
      n_judges = as.integer(results$n_complete),
      # The statistics carry the omnibus p only, so the rule says in words
      # that every contrast must pass as well, and the p row's note names the
      # contrast that held an item back. Schema 1 freezes the columns, not
      # the set of rows or the statistic labels, so a contrast-p row could be
      # added without a new schema version.
      rule = rep(sprintf(
        paste("Greenhouse-Geisser corrected omnibus test and every planned",
              "target-versus-orbiting contrast significant%s",
              "(repeated-measures ANOVA adapted from Hinkin & Tracey, 1999,",
              "following MacKenzie et al., 2011), alpha = %s"),
        if (identical(fit$settings$adjust, "holm")) {
          " after Holm adjustment"
        } else {
          ""
        },
        .fmt_alpha(alpha)), n),
      citation = c("Hinkin & Tracey (1999)", "MacKenzie et al. (2011)",
                   "Colquitt et al. (2019)"),
      statistics = rbind(
        .handoff_stat(results$item, "HTC", results$htc),
        .handoff_stat(results$item, "HTD", results$htd),
        .handoff_stat(results$item, "p_value", results$p_value, alpha,
                      note = .handoff_rating_notes(fit, results, alpha))
      )
    ))
  }

  mode <- if (is.null(fit$mode)) NA_character_ else fit$mode

  if (identical(mode, "relevance")) {
    # Stated as counts, because the decision compares counts (Lynn, 1986).
    # Past ten experts the count is the package's extension of Lynn's table,
    # and the rule says so.
    required <- .cvi_required_count(results$N)
    source <- ifelse(
      !is.na(results$N) & results$N > 10L,
      paste("contentvalidR extension of Lynn, 1986, holding her 7 of 9",
            "beyond her ten-expert table"),
      "Lynn, 1986"
    )
    rule <- ifelse(
      is.na(results$cvi_criterion),
      "fewer than three usable expert ratings; treated as insufficient",
      sprintf(paste("at least %d of %d experts rate the item relevant (I-CVI",
                    ">= %s; %s), which also puts modified kappa above .74",
                    "(Polit et al., 2007)"),
              required, as.integer(results$N), .fmt(results$cvi_criterion),
              source)
    )
    extended <- any(!is.na(results$N) & results$N > 10L)
    return(list(
      scale = rep(NA_character_, n),
      n_judges = as.integer(results$N),
      rule = rule,
      citation = c("Aiken (1980)", "Penfield & Giacobbi (2004)", "Lynn (1986)",
                   if (extended) "Polit & Beck (2006)",
                   "Polit et al. (2007)"),
      statistics = rbind(
        .handoff_stat(results$item, "Aiken's V", results$V,
                      lower = .handoff_column(results, "ci_low"),
                      upper = .handoff_column(results, "ci_high"),
                      interval_method = if (is.null(fit$settings$aiken_ci)) {
                        NA_character_
                      } else {
                        fit$settings$aiken_ci
                      },
                      interval_level = level),
        .handoff_stat(results$item, "I-CVI", results$I_CVI, results$cvi_criterion,
                      lower = .handoff_column(results, "I_CVI_low"),
                      upper = .handoff_column(results, "I_CVI_high"),
                      interval_method = proportion_label,
                      interval_level = level),
        .handoff_stat(results$item, "modified kappa", results$kappa_mod, 0.74)
      )
    ))
  }

  if (identical(mode, "essentiality")) {
    return(list(
      scale = rep(NA_character_, n),
      n_judges = as.integer(results$N),
      # As for the sort, a rule never carries a missing count.
      rule = ifelse(
        results$N < 1L,
        sprintf(paste("no expert rated the item, so the exact binomial test",
                      "(Ayre & Scally, 2014) was not applied, alpha = %s"),
                .fmt_alpha(alpha)),
        ifelse(
          is.na(results$critical_ne),
          sprintf(paste("no count of essential ratings out of %d can meet the",
                        "exact binomial test (Ayre & Scally, 2014), alpha = %s"),
                  as.integer(results$N), .fmt_alpha(alpha)),
          sprintf(paste("CVR >= %s, i.e. at least %d of %d judges rating the",
                        "item essential (exact binomial; Ayre & Scally, 2014),",
                        "alpha = %s"),
                  .fmt(results$critical_cvr), as.integer(results$critical_ne),
                  as.integer(results$N), .fmt_alpha(alpha))
        )
      ),
      citation = c("Lawshe (1975)", "Ayre & Scally (2014)"),
      statistics = rbind(
        .handoff_stat(results$item, "CVR", results$cvr, results$critical_cvr),
        .handoff_stat(results$item, "essential count", results$ne, results$critical_ne),
        .handoff_stat(results$item, "p_value", results$p_value, alpha)
      )
    ))
  }

  if (.congruence_pre10(fit)) stop(.congruence_pre10_message(), call. = FALSE)
  cells <- if (is.list(fit$details)) fit$details$cells else NULL
  # Tied objectives are listed together: "Objectives B, C."
  .objective_word <- function(obj) {
    ifelse(grepl(", ", obj, fixed = TRUE), "Objectives", "Objective")
  }
  cut <- fit$settings$ioc_cut
  if (!is.numeric(cut)) cut <- 0.70

  # Congruence, with a target mapping: the target objective is the construct,
  # and the decision is the index against Rovinelli and Hambleton's criterion.
  if ("target_ioc" %in% names(results)) {
    n_judges <- if ("n_judges" %in% names(results)) {
      as.integer(results$n_judges)
    } else if (is.data.frame(cells) &&
               all(c("item", "objective", "n_judges") %in% names(cells))) {
      as.integer(cells$n_judges[match(paste(results$item, results$target),
                                       paste(cells$item, cells$objective))])
    } else {
      rep(NA_integer_, n)
    }
    target_mean <- .handoff_column(results, "target_mean")
    return(list(
      scale = as.character(results$target),
      n_judges = n_judges,
      # A rule explains the decision beside it, so the two cases without one
      # say why.
      rule = ifelse(
        is.na(target_mean),
        "no usable expert ratings on the target objective; no decision",
        ifelse(
          is.na(results$target_ioc),
          paste("rated against its target objective only, so the index,",
                "which compares objectives, could not be computed; described,",
                "no decision"),
          sprintf(paste("index of item-objective congruence (Rovinelli &",
                        "Hambleton, 1977) for the target objective >= %s%s"),
                  .fmt(cut),
                  if (isTRUE(all.equal(cut, 0.70))) {
                    ", the criterion they applied"
                  } else {
                    ", set for this analysis (they applied .70)"
                  })
        )
      ),
      citation = "Rovinelli & Hambleton (1977)",
      statistics = rbind(
        .handoff_stat(results$item, "target IOC", results$target_ioc, cut),
        .handoff_stat(results$item, "target mean rating",
                      .handoff_column(results, "target_mean")),
        .handoff_stat(results$item, "competitor mean rating",
                      .handoff_column(results, "competitor_mean"),
                      note = ifelse(
                        is.na(.handoff_column(results, "strongest_competitor")),
                        "",
                        paste0(.objective_word(results$strongest_competitor),
                               " ", results$strongest_competitor, ".")
                      ))
      )
    ))
  }

  # Congruence without a target mapping: one row per item, no decision rule.
  # The index is given for the objective each item matched best.
  list(
    scale = rep(NA_character_, n),
    n_judges = if (is.data.frame(cells) && "n_judges" %in% names(cells)) {
      as.integer(vapply(results$item, function(it) {
        max(c(0L, cells$n_judges[cells$item == it]))
      }, numeric(1)))
    } else {
      rep(NA_integer_, n)
    },
    rule = rep(paste("no target-objective mapping was supplied; the index of",
                     "item-objective congruence is described, with no",
                     "decision"), n),
    citation = "Rovinelli & Hambleton (1977)",
    statistics = if ("best_ioc" %in% names(results)) {
      .handoff_stat(results$item, "highest IOC", results$best_ioc,
                    note = ifelse(is.na(results$best_objective), "",
                                  paste0(.objective_word(results$best_objective),
                                         " ", results$best_objective,
                                         ".")))
    } else {
      blank
    }
  )
}

#' Carry content-validity decisions into empirical validation
#'
#' @description
#' Packages the item decisions from a finished content-validity workflow so they
#' can be carried into an empirical scale-development workflow without retyping
#' item names or losing the record of why each item was kept.
#'
#' The result holds the item names that survived content review, the construct
#' each belongs to where the design defines one, a per-item evidence table, the
#' statistics behind each decision, and the provenance of the analysis. It is
#' plain data, so a downstream package can read it without contentvalidR being
#' installed.
#'
#' @details
#' Item-level workflows are accepted: [sort_validity()], [rating_validity()],
#' [expert_validity()], and [delphi_validity()]. [judge_validity()] and
#' [domain_validity()] are refused, because their rows are judges and blueprint
#' cells rather than items, so there is no item set to carry forward.
#'
#' Items that do not meet `keep` are not dropped from the record. They stay in
#' `item_evidence` with `carried = FALSE`, so a reader can see what was held
#' back and why. Review is not deletion.
#'
#' @section Object shape (schema version 1):
#' The object has class `c("contentvalid_handoff", "cv_handoff", "list")`. A
#' consumer matches on `"cv_handoff"` and reads these fields:
#'
#' \describe{
#'   \item{`items`}{character vector of the carried item names, that is
#'     `item_evidence$item[item_evidence$carried]`, unique and in results order.}
#'   \item{`scales`}{named list mapping each construct to its carried items, or
#'     `NULL` when the design has no construct mapping. Expert relevance and
#'     essentiality rate a single item set with no construct column, so they
#'     produce `NULL`, as does a Delphi study. An item belongs to at most one
#'     scale, the one its `item_evidence$scale` names: every workflow that maps
#'     items to constructs requires exactly one target per item, and stops
#'     otherwise.}
#'   \item{`item_evidence`}{data frame with one row per reviewed item: `item`,
#'     `scale` (`NA` without a construct mapping), `carried`, `status`,
#'     `recommendation`, `n_judges`, `rule`, and `round`. For a Delphi handoff
#'     `round` differs between items; see "A Delphi handoff". From
#'     contentvalidR 0.7.0 it also carries `keying`, `response_min`, and
#'     `response_max`, described under "Instrument metadata".}
#'   \item{`item_statistics`}{data frame, one row per item per statistic:
#'     `item`, `statistic`, `value`, `criterion` (`NA` when the method sets
#'     no explicit criterion), and `round`. Which statistics carry a criterion
#'     depends on the workflow rather than on the statistic alone: modified
#'     kappa carries 0.74 from [expert_validity()], and none from a Delphi
#'     handoff, which decides on the consensus threshold. From contentvalidR
#'     0.7.0 it also carries `note`, described under "The note column". From
#'     contentvalidR 0.5.0 it also
#'     carries `lower`, `upper`, `interval_method`, and `interval_level`,
#'     described under "Intervals".}
#'   \item{`provenance`}{list with `schema_version`, `package`,
#'     `package_version`, `workflow`, `mode`, `keep`, `method`, `citation`,
#'     `settings`, `design`, and `created`.}
#'   \item{`panel_statistics`}{added in contentvalidR 0.5.0. Data frame of
#'     panel-level statistics, with the same columns as `item_statistics` less
#'     `item`, including `note` from 0.7.0. It holds the panel agreement
#'     coefficient when [expert_validity()] computed one, and has zero rows
#'     otherwise.}
#' }
#'
#' This shape is agreed with the `nomologR` package, which consumes it in
#' `nomo_screen()` and `nomo_run()`. Neither package depends on the other.
#' Fields and columns added within schema version 1 are optional for a reader,
#' which should check that they are present rather than assume it.
#'
#' @section Reading the decisions:
#' Take each item's decision from the handoff, not from its statistics.
#' `carried` says whether the item travels forward, and `status` says why: it
#' is one of the four values `keep` accepts. `recommendation` words the same
#' decision for a person, and like `rule` it is prose.
#'
#' Don't re-derive a decision by comparing `value` with `criterion`, and don't
#' branch on `provenance$package_version`. A corrected rule can change a
#' decision between releases while the statistics stay the same, and the
#' handoff records the decision its producer made. contentvalidR 0.8.0 is the
#' example. For an item that 7 of 9 experts rated relevant, the I-CVI is .778
#' in both releases. 0.7.0 compared it with a rounded .78 and held the item
#' back. 0.8.0 applies Lynn's (1986) 7 of 9, stores 7/9 as the criterion, and
#' carries the item. There the value equals the criterion, so a recomputed
#' `value >= criterion` would hang on floating-point rounding, where the
#' package itself compares counts of experts. Read `carried`, which holds what
#' each release decided.
#'
#' Keying is read the same way, from the field and not from a default:
#' `keying` is `1` for a forward-keyed item, `-1` for a reverse-keyed one,
#' and `NA` when nobody said, as described under "Instrument metadata". Treat
#' `NA` as unknown, never as forward-keyed.
#'
#' @section What version 1 freezes:
#' Schema version 1 is frozen as of contentvalidR 0.7.0. Code that reads a
#' handoff can rely on all of the following, in every release that reports
#' `schema_version = 1`:
#'
#' * The six top-level fields above, under those names.
#' * In `item_evidence`: `item`, `scale`, `carried`, `status`,
#'   `recommendation`, `n_judges`, `rule`, `round`, `keying`, `response_min`,
#'   `response_max`.
#' * In `item_statistics`: `item`, `statistic`, `value`, `criterion`, `round`,
#'   `lower`, `upper`, `interval_method`, `interval_level`, `note`.
#' * In `panel_statistics`: the same columns less `item`.
#' * In `provenance`: `schema_version`, `package`, `package_version`,
#'   `workflow`, `mode`, `keep`, `method`, `citation`, `settings`, `design`,
#'   `created`.
#'
#' Each of those columns keeps its name, its position, and its type. Every
#' handoff carries every column, including when a workflow has nothing to put
#' in one: a statistic with no interval carries `NA` in the four interval
#' columns rather than dropping them, and a workflow with no panel coefficient
#' returns a zero-row `panel_statistics` with the full set of columns. A reader
#' can therefore bind handoffs from different workflows without reconciling
#' their columns.
#'
#' The values of two `provenance` fields are frozen as well, because they are
#' how a reader tells which workflow a handoff came from:
#'
#' * `workflow` is `"item-sort"` from [sort_validity()], `"construct-rating"`
#'   from [rating_validity()], `"expert-panel"` from [expert_validity()], or
#'   `"delphi"` from [delphi_validity()].
#' * `mode` is `"relevance"`, `"essentiality"`, or `"congruence"`, the `mode`
#'   an expert panel was analyzed in, and `NA` from the other three workflows.
#'
#' A new workflow or mode would add a value to these. None of the values
#' listed is renamed within version 1.
#'
#' These are deliberately **not** frozen, and a reader should not depend on
#' them:
#'
#' * The set of rows. Which items, which statistics, and how many of each
#'   depend on the workflow and on the data.
#' * The values in the `statistic` column. They are labels for display, and may
#'   be reworded in a minor release; match on `workflow` and `mode` in
#'   `provenance` instead, whose values are listed above.
#' * The text in `note`, `rule`, `recommendation`, and `citation`, which is
#'   prose for a human reader.
#' * The contents of `settings` and `design`, which mirror the fitted object
#'   and grow with it.
#'
#' Neither is the printed output part of the schema. `print()` on a handoff is
#' written for a person, and its layout and wording may change in any release.
#' Read the fields.
#'
#' New optional fields and columns may still be added within version 1, at the
#' end of a data frame or list. A reader written against this section keeps
#' working when that happens, provided it addresses columns by name.
#'
#' @section If the schema ever changes:
#' Renaming a field, removing one, changing a type, or changing what a field
#' means is a version 2 change, not a minor release. It would raise
#' `provenance$schema_version` to `2L`, and version 1 would keep being
#' produced for at least one full release cycle so that readers have a
#' version to fall back on. The release notes would say what moved.
#'
#' A reader should gate on the version rather than on the contentvalidR
#' version:
#'
#' ```r
#' if (!inherits(h, "cv_handoff") || h$provenance$schema_version != 1L) {
#'   stop("this reader understands handoff schema version 1 only")
#' }
#' ```
#'
#' No version 2 is planned.
#'
#' @section The note column:
#' Added in contentvalidR 0.7.0 to `item_statistics` and `panel_statistics`.
#' It says why a value or interval is absent or degenerate, in the producing
#' function's own words, so a reader need not re-derive method-specific
#' semantics. For example, a Delphi stability row may carry "Kappa is
#' undefined: every rating fell in the same category in both rounds." It also
#' says when a statistic that meets its criterion is not what decided: the
#' construct-rating `p_value` is the omnibus *p*, and for an item held back by
#' a planned contrast its note says so, with the largest contrast *p* or, when
#' a contrast has none, the constructs that tied. On a Delphi stability
#' criterion it says which way the criterion reads and whether the fit read
#' the item as stable, as described under "A Delphi handoff".
#'
#' Its contract, agreed with the `nomologR` maintainers:
#'
#' * It is **display text only**. Never match on it, branch on it, or parse
#'   it. Its wording may change in any minor release without a schema change.
#' * It is always a character vector with **no `NA`**. `""` means there is
#'   nothing to say, not that something is missing, so a row can carry a value
#'   and an empty note.
#' * It **never replaces the values**. Whether a statistic is undefined, and
#'   which of the two cases applies, stays readable from `value` and
#'   `proportion unchanged` as described under "When a stability statistic is
#'   NA". That inference is the supported way to decide anything.
#' * Objects from contentvalidR 0.6.0 and earlier have no such column, and a
#'   reader should treat its absence as every note being empty.
#'
#' @section Intervals:
#' Each statistic's interval travels with it, so a reader can tell a unanimous
#' four-judge panel from a unanimous twenty-judge one. `lower` and `upper` are
#' the bounds, `interval_method` names the method, and `interval_level` is the
#' confidence level, for example `0.95`.
#'
#' * Aiken's V: the Penfield-Giacobbi score interval.
#' * I-CVI and Psa: the method chosen with `proportion_ci`, the Wilson score
#'   interval by default. A Delphi handoff takes it from each item's last
#'   round.
#' * Panel agreement: the item-resampling percentile bootstrap of
#'   [panel_agreement()].
#' * Delphi weighted kappa: the expert-resampling percentile bootstrap of
#'   [delphi_validity()], at `1 - alpha`, when it was run with `B` above 0.
#'
#' The four columns are `NA` together when a statistic has no interval. That
#' happens when the method defines none (Csv, HTC, HTD, CVR, the essential
#' count, modified kappa, IOC and the mean ratings beside it, proportion
#' unchanged, lambda, the chi-squares, net percent change, and p values), when
#' intervals were switched off with `proportion_ci = "none"` or `B = 0`, or
#' when the statistic itself could not be computed. `NA` there never stands
#' for missing data.
#'
#' A bootstrap interval can have zero width (`lower` equal to `upper`), when
#' every resample gave the same value: a panel whose experts all kept their
#' ratings, say. The bounds are kept as computed, and the row's `note` says
#' that the width reflects how alike the ratings were, not precision.
#'
#' The handoff reports intervals only. It does not turn them into priors or
#' weights for a later analysis; that is a question for the consuming package.
#'
#' @section A Delphi handoff:
#' A Delphi study settles one item at a time: an item that reached consensus
#' early was set aside, and its last round came before the study's final round.
#' A Delphi handoff therefore carries each item's evidence **from its own last
#' round**, and `round` holds that round's index rather than one constant. It is
#' the only workflow where `round` varies within a handoff.
#'
#' Each item carries the relevance evidence of its last round, taken from that
#' round's [expert_validity()] fit, with intervals: `I-CVI` against the
#' consensus threshold, `Aiken's V`, and `modified kappa`. Modified kappa
#' carries no criterion here, because a Delphi decides on the consensus
#' threshold rather than on the 0.74 rule that [expert_validity()] applies.
#'
#' Two more statistics record whether the panel had stopped moving:
#' `proportion unchanged`, and the stability statistic that ran, named for its
#' method, such as `weighted kappa (quadratic)` or `Goodman-Kruskal lambda`.
#' The chi-square methods add `stability p_value` against `alpha`, and net
#' percent change carries its own criterion, .15. Stability travels as
#' evidence beside the decision; it never decides what is carried, exactly as
#' it never sets an item's status in [delphi_validity()].
#'
#' **The stability criteria do not all read the same way.** The individual
#' chi-square reads *p* below `alpha` as stable, because Chaffin and Talley
#' (1980) take dependence between the rounds' ratings as stability; the group
#' chi-square reads *p* at or above `alpha` as stable, because Dajani et al.
#' (1979) take no detectable difference between the rounds' distributions as
#' stability; and net percent change reads a value below .15 as stable
#' (Scheibe et al., 1975/2002). The same `criterion` therefore cannot be read
#' without the method. The row that carries the criterion (`stability
#' p_value`, or `net percent change`) says in its `note` which way it reads
#' and whether the fit read the item as stable ("Read as stable." or "Not
#' read as stable."), the call [delphi_validity()] records in `stable`. Kappa
#' and lambda have no criterion and make no such call.
#'
#' The stability rows come from the item's last pair of consecutive rounds.
#' For an item rated again after a gap (rounds 1, 2 and 4) that pair is
#' earlier than the round the rows are dated by, and their `note` says which
#' rounds they compare. Stability uses only the experts who rated the item in
#' both rounds of the pair; when they are fewer than `n_judges`, the experts
#' in the item's last round, the `note` gives their number.
#'
#' @section When a stability statistic is NA:
#' A stability row is always present for a carried item, so an `NA` there is a
#' statement about the data rather than a missing record. There are two kinds
#' of case, and they can be told apart from the object alone:
#'
#' \describe{
#'   \item{`proportion unchanged` is also `NA`}{No pair of ratings was
#'     compared, for one of three reasons: the item was rated in one round
#'     only; it was rated in rounds that are not consecutive (1 and 3), and
#'     only consecutive rounds are compared; or it was rated in two
#'     consecutive rounds, but no expert rated it in both, as when the panel
#'     was replaced between them. The `note` says which.}
#'   \item{`proportion unchanged` has a value}{A pair exists, but the
#'     statistic is undefined for that data.}
#' }
#'
#' In the second case, **read `proportion unchanged`**, which is often the more
#' informative number. An undefined kappa beside `proportion unchanged` of 1 is
#' perfect stability that kappa cannot express: kappa is chance-corrected, and
#' when every paired rating in both rounds falls in one category, the
#' disagreement expected by chance is zero, so kappa is 0/0. Reporting only
#' "not estimable" there would describe a defect that does not exist. Goodman-
#' Kruskal lambda is undefined when the later round is unanimous, and the
#' chi-square methods are undefined for a table with fewer than two occupied
#' rows or columns.
#'
#' `delphi_validity()` states the reason in `details$stability$note`, and from
#' contentvalidR 0.7.0 the handoff carries that sentence in the `note` column
#' of `item_statistics`, described under "The note column".
#'
#' @section Instrument metadata:
#' Added in contentvalidR 0.7.0, at the request of the `nomologR` maintainers,
#' because two empirical computations cannot be done correctly without them.
#'
#' * `keying` is `1` for a forward-keyed item, `-1` for a reverse-keyed one,
#'   and `NA` when nobody said. An even-odd consistency index must recode
#'   reverse-keyed items before splitting the scale, or a perfectly consistent
#'   respondent looks careless. And a negative corrected item-total correlation
#'   means opposite things in the two cases: on an item that was never recoded
#'   it is a coding error, and on a correctly coded item it is evidence against
#'   the item.
#' * `response_min` and `response_max` are the lowest and highest answers a
#'   respondent can give. Screening for out-of-range answers needs the scale's
#'   limits rather than the observed ones, because a category nobody used is
#'   still a legal answer, and long-string and within-person variability
#'   indices mean different things on a two-point and a seven-point scale.
#'
#' **Both come from the analyst, never from the fit.** A content-validity panel
#' rates relevance or correspondence on its own scale, usually 1 to 4, which is
#' not the scale respondents will answer the items on. Copying a fit's `lo` and
#' `hi` into `response_min` and `response_max` would give a downstream reader
#' the wrong limits, and it would then reject every legitimate top-category
#' answer. So both default to `NA`, which means *unknown*, and a reader should
#' treat `NA` that way rather than assume a forward-keyed item or an observed
#' range.
#'
#' Supplying `reverse_keyed` is a statement about every item: the ones named
#' are reverse-keyed and the rest are not. Pass `character(0)` to record that
#' you checked and none is. So `keying` is either `NA` for every item or for
#' none of them, and the same holds for the response scale.
#'
#' Naming a reverse-keyed item without `response_scale` gives a warning,
#' because such an item cannot be recoded without the scale's limits. A reader
#' that recodes would otherwise have to refuse later, where the problem is
#' harder to fix.
#'
#' @section What a handoff does and does not establish:
#' Surviving content review is evidence about relevance, representation, and
#' expert judgment. It does not establish that an item will behave well
#' empirically. An item can be clearly relevant and still correlate poorly with
#' its construct or load on an unintended factor. That is what the downstream
#' empirical analysis tests, which is why the item set travels with its
#' evidence rather than as a bare list of names.
#'
#' @references
#' Chaffin, W. W., & Talley, W. K. (1980). Individual stability in Delphi
#' studies. *Technological Forecasting and Social Change, 16*(1), 67–73.
#' \doi{10.1016/0040-1625(80)90074-8}
#'
#' Dajani, J. S., Sincoff, M. Z., & Talley, W. K. (1979). Stability and
#' agreement criteria for the termination of Delphi studies. *Technological
#' Forecasting and Social Change, 13*(1), 83–90.
#' \doi{10.1016/0040-1625(79)90007-6}
#'
#' Lynn, M. R. (1986). Determination and quantification of content validity.
#' *Nursing Research, 35*(6), 382–385.
#' \doi{10.1097/00006199-198611000-00017}
#'
#' Scheibe, M., Skutsch, M., & Schofer, J. (2002). Experiments in Delphi
#' methodology. In H. A. Linstone & M. Turoff (Eds.), *The Delphi method:
#' Techniques and applications* (pp. 257–281).
#' \url{https://www.foresight.pl/assets/downloads/publications/Turoff_Linstone.pdf}
#' (Original work published 1975)
#'
#' @param fit A fitted `contentvalid_sort`, `contentvalid_rating`,
#'   `contentvalid_expert`, or `contentvalid_delphi` object.
#' @param keep Statuses that travel forward, defaulting to `"Supported"`. Any of
#'   `"Supported"`, `"Review"`, `"Insufficient data"`, or `"Descriptive only"`.
#' @param round Pretest round this analysis represents. One fit is one round, so
#'   this defaults to `1` and matters only when stacking rounds by hand. It
#'   cannot be set for a Delphi fit, which dates each item by the round it
#'   was last rated in.
#' @param reverse_keyed Names of the reverse-keyed items, `character(0)` if
#'   none is, or `NULL` (the default) to leave keying unrecorded. See
#'   "Instrument metadata".
#' @param response_scale The lowest and highest answer respondents can give,
#'   such as `c(1, 5)`, or `NULL` (the default) to leave it unrecorded. This is
#'   the scale of the instrument, not the scale the panel rated on.
#'
#' @return An object of class `contentvalid_handoff`, `cv_handoff`, and `list`,
#'   as described under "Object shape".
#'
#' @seealso [as.data.frame.contentvalid_workflow()] for the full results table,
#'   and [content_report()] for manuscript tables.
#'
#' @examples
#' relevance <- matrix(
#'   c(4,4,4,3, 4,4,3,4, 3,4,4,4, 2,2,1,2),
#'   nrow = 4,
#'   dimnames = list(NULL, paste0("Item", 1:4))
#' )
#' fit <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
#'                        agreement = "none")
#' handoff <- content_handoff(fit)
#' handoff
#' handoff$items
#' handoff$item_evidence[, c("item", "status", "recommendation", "n_judges")]
#' writeLines(strwrap(handoff$item_evidence$rule[1]))
#' handoff$item_statistics[, c("item", "statistic", "value", "criterion")]
#'
#' # Carry items flagged for review as well, when the study protocol says so.
#' content_handoff(fit, keep = c("Supported", "Review"))$items
#' @export
content_handoff <- function(fit, keep = "Supported", round = 1,
                            reverse_keyed = NULL, response_scale = NULL) {
  item_classes <- c("contentvalid_sort", "contentvalid_rating",
                    "contentvalid_expert", "contentvalid_delphi")
  if (!inherits(fit, item_classes, which = FALSE)) {
    stop("`fit` must be a sort, rating, expert-panel, or Delphi workflow ",
         "object. judge_validity() and domain_validity() results describe ",
         "judges and blueprint cells rather than items, so they carry no item ",
         "set.", call. = FALSE)
  }

  # A Delphi fit dates each item by the round it was last rated in, so `round`
  # is read from the fit rather than supplied.
  if (inherits(fit, "contentvalid_delphi") && !missing(round)) {
    stop("For a Delphi fit, `round` comes from the round each item was last ",
         "rated in, so it cannot be set here.", call. = FALSE)
  }

  valid <- .status_definitions()$status
  if (!is.character(keep) || !length(keep) || anyNA(keep) || !all(keep %in% valid)) {
    bad <- if (is.character(keep)) setdiff(keep, valid) else character(0)
    stop("`keep` must be one or more of ", paste0('"', valid, '"', collapse = ", "),
         if (length(bad)) paste0(", not ", paste0('"', bad, '"', collapse = ", ")),
         ".", call. = FALSE)
  }
  if (!is.numeric(round) || length(round) != 1L || !is.finite(round) ||
      round < 1 || round != floor(round)) {
    stop("`round` must be one positive integer.", call. = FALSE)
  }

  results <- .with_workflow_status(fit$results)
  if (!"item" %in% names(results)) {
    stop("This workflow's results have no `item` column, so there is no item ",
         "set to carry forward.", call. = FALSE)
  }

  spec <- .handoff_spec(fit, results)
  # One round per item: a constant everywhere except a Delphi handoff, where
  # each item carries the round it was last rated in.
  item_round <- if (is.null(spec$round)) {
    rep(as.integer(round), nrow(results))
  } else {
    as.integer(spec$round)
  }
  names(item_round) <- as.character(results$item)

  evidence <- data.frame(
    item = as.character(results$item),
    scale = spec$scale,
    carried = as.character(results$status) %in% keep,
    status = as.character(results$status),
    recommendation = if ("recommendation" %in% names(results)) {
      as.character(results$recommendation)
    } else {
      NA_character_
    },
    n_judges = spec$n_judges,
    rule = spec$rule,
    round = unname(item_round),
    stringsAsFactors = FALSE
  )
  instrument <- .handoff_instrument(evidence$item, reverse_keyed,
                                    response_scale)
  evidence$keying <- instrument$keying
  evidence$response_min <- instrument$response_min
  evidence$response_max <- instrument$response_max
  rownames(evidence) <- NULL

  # Statistics cover every reviewed item, carried or not, so a held-back item
  # can be reported with the numbers behind its status.
  # The interval columns follow `round`, so the schema version 1 columns keep
  # their positions as well as their names.
  statistics <- spec$statistics
  statistics$round <- unname(item_round[as.character(statistics$item)])
  statistics <- statistics[c("item", "statistic", "value", "criterion", "round",
                             "lower", "upper", "interval_method",
                             "interval_level", "note")]
  rownames(statistics) <- NULL

  items <- unique(evidence$item[evidence$carried])
  scales <- NULL
  if (!all(is.na(evidence$scale))) {
    carried <- evidence[evidence$carried & !is.na(evidence$scale), , drop = FALSE]
    scales <- lapply(split(carried$item, carried$scale, drop = TRUE), unique)
  }

  out <- list(
    items = items,
    scales = scales,
    item_evidence = evidence,
    item_statistics = statistics,
    provenance = list(
      schema_version = .handoff_schema_version,
      package = "contentvalidR",
      package_version = as.character(getNamespaceVersion("contentvalidR")),
      workflow = .workflow_name(fit),
      mode = if (is.null(fit$mode)) NA_character_ else fit$mode,
      keep = keep,
      method = if (is.null(fit$settings$method)) NA_character_ else fit$settings$method,
      citation = spec$citation,
      settings = fit$settings,
      design = .workflow_design(fit),
      created = Sys.Date()
    ),
    panel_statistics = .handoff_panel_statistics(fit, round)
  )
  class(out) <- c("contentvalid_handoff", "cv_handoff", "list")
  out
}

# The keying and response scale the handoff carries, as one header line:
# "Keying: reverse-keyed A2, B3; response scale 1 to 5". A handoff from
# before 0.7.0 has neither column, which reads as not stated.
.handoff_keying_line <- function(evidence) {
  keying <- evidence$keying
  keyed <- if (is.null(keying) || all(is.na(keying))) {
    "not stated"
  } else {
    reversed <- unique(evidence$item[keying %in% -1L])
    if (length(reversed)) {
      paste("reverse-keyed", paste(reversed, collapse = ", "))
    } else {
      "no item reverse-keyed"
    }
  }
  lo <- evidence$response_min
  hi <- evidence$response_max
  known <- !is.null(lo) && !is.null(hi) && any(!is.na(lo) & !is.na(hi))
  scale <- if (known) {
    i <- which(!is.na(lo) & !is.na(hi))[1]
    paste("response scale", lo[i], "to", hi[i])
  } else {
    "response scale not stated"
  }
  paste0("Keying: ", keyed, "; ", scale)
}

# `keep` as it would be typed: "Supported" or c("Supported", "Review").
.handoff_keep_text <- function(keep) {
  quoted <- paste0("\"", keep, "\"")
  if (length(keep) == 1L) return(quoted)
  paste0("c(", paste(quoted, collapse = ", "), ")")
}

#' @export
print.contentvalid_handoff <- function(x, ...) {
  p <- x$provenance
  title <- paste0("Handoff to empirical validation (schema version ",
                  p$schema_version, ")")
  .print_header(x, title)
  cat("Workflow: ", p$workflow, sep = "")
  if (!is.na(p$mode)) cat(" (", p$mode, ")", sep = "")
  cat(" | contentvalidR ", p$package_version, " | ", format(p$created), "\n",
      sep = "")
  cat("Items carried forward: ", length(x$items), " of ",
      length(unique(x$item_evidence$item)), "\n", sep = "")
  cat("Carried when status is: ", paste(p$keep, collapse = ", "), "\n", sep = "")

  if (is.null(x$scales)) {
    cat("Constructs: none in this design; the panel rated one item set.\n")
  } else if (!length(x$scales)) {
    cat("Constructs: none carried\n")
  } else {
    .say(paste0("Constructs: ", paste(sprintf("%s (%d)", names(x$scales),
                                              lengths(x$scales)),
                                      collapse = ", ")),
         exdent = 2L)
  }
  .say(.handoff_keying_line(x$item_evidence), exdent = 2L)

  st <- x$item_statistics
  if (!is.null(st$interval_method) && any(!is.na(st$interval_method))) {
    carried <- unique(st[!is.na(st$interval_method),
                         c("statistic", "interval_method", "interval_level")])
    .say(paste0("Intervals carried: ", paste(sprintf(
      "%s (%s, %s%%)", carried$statistic, carried$interval_method,
      format(100 * carried$interval_level)
    ), collapse = "; ")), exdent = 2L)
  }

  ps <- x$panel_statistics
  if (is.data.frame(ps) && nrow(ps)) {
    for (i in seq_len(nrow(ps))) {
      line <- sprintf("Panel: %s = %s", ps$statistic[i], .fmt(ps$value[i]))
      if (!is.na(ps$interval_method[i])) {
        ci <- paste0(format(100 * ps$interval_level[i]), "% CI")
        # An interval with no width says nothing about precision, so it is
        # said in words, as panel_agreement() prints it.
        line <- if (.handoff_zero_width(ps$lower[i], ps$upper[i])) {
          paste0(line, "; no ", ci, ", because every resample of the items ",
                 "gave the same value")
        } else {
          sprintf("%s, %s %s (%s)", line, ci,
                  .fmt_ci(ps$lower[i], ps$upper[i]), ps$interval_method[i])
        }
      }
      .say(line, exdent = 2L)
    }
  }

  # The status words, in this workflow's own terms, after the facts.
  cat("\n")
  .say(.status_meaning(x$item_evidence$recommendation, x$item_evidence$status))

  held <- x$item_evidence[!x$item_evidence$carried, , drop = FALSE]
  if (nrow(held)) {
    .section("Held back")
    show <- data.frame(item = held$item, decision = held$recommendation,
                       stringsAsFactors = FALSE)
    # The shared status adds nothing when it repeats the workflow's own word.
    if (any(held$recommendation != held$status)) show$status <- held$status
    .print_table(show, more = "x$item_evidence")
    .end_section()
  }

  # An item no decision rule was applied to is held back by `keep`, not by
  # its evidence, so the print says so and how to carry it.
  descriptive <- held$item[held$status %in% "Descriptive only"]
  every_item <- length(descriptive) == nrow(x$item_evidence)
  if (length(descriptive)) {
    cat("\n")
    .say(if (every_item) {
      paste("No decision rule was applied in this analysis, so every item is",
            "Descriptive only and none is carried. keep = \"Descriptive",
            "only\" carries such items, as in content_handoff(fit, keep =",
            "\"Descriptive only\").")
    } else {
      paste0("No decision rule was applied to ",
             paste(descriptive, collapse = ", "), ", so ",
             if (length(descriptive) == 1L) "it is" else "they are",
             " Descriptive only and not carried. Adding \"Descriptive only\" ",
             "to keep carries such items, as in content_handoff(fit, keep = ",
             .handoff_keep_text(unique(c(p$keep, "Descriptive only"))), ").")
    })
  }

  if (length(x$items)) {
    cat("\n")
    .say("Carry these items into the empirical workflow once response data",
         "are collected. In nomologR that is")
    cat("    nomo_screen(data, items = handoff)\n")
    .say("which screens the items carried here. Passing the whole handoff,",
         "rather than handoff$items, keeps the keying and the reasons for",
         "anything held back.")
  } else if (!every_item) {
    cat("\n")
    .say("No item met `keep`, so nothing is carried into the empirical",
         "workflow yet.")
  }

  .closing(c("Surviving content review is evidence about relevance,",
             "representation, and expert judgment. It does not establish that",
             "an item will behave well empirically: an item can be clearly",
             "relevant and still correlate poorly with its construct or load on",
             "an unintended factor.",
             if (nrow(held)) {
               paste("Items held back are listed above rather than deleted, so",
                     "the record stays complete.")
             }),
           paste("See as.data.frame(x) for the item evidence and",
                 "x$item_statistics for the statistics."))
  invisible(x)
}

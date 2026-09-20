# Printed claims are checked against what the functions compute, from real
# fitted objects, rather than against strings copied out of the print methods
# (#41). A test that asserts what the documentation claims can pass while being
# false; these assert what the object holds.

printed <- function(x, ...) {
  paste(utils::capture.output(print(x, ...)), collapse = "\n")
}
squashed <- function(x, ...) gsub("[[:space:]]+", " ", printed(x, ...))

# The line(s) of printed output that mention a unit, joined.
line_for <- function(out, unit) {
  lines <- utils::capture.output(cat(out))
  hits <- grep(paste0("(^|[[:space:]])", unit, "([[:space:]]|$)"), lines,
               value = TRUE)
  paste(hits, collapse = " ")
}

# print.data.frame rounds, then pads a column to a common width, so the
# expected strings are built the same way the print methods build them.
expect_column_printed <- function(out, units, values, digits = 3,
                                  label = "column") {
  shown <- format(round(values, digits))
  for (i in seq_along(units)) {
    if (is.na(values[i])) next
    line <- line_for(out, units[i])
    expect_true(
      grepl(trimws(shown[i]), line, fixed = TRUE),
      info = paste0(label, ": ", units[i], " should print ", trimws(shown[i]),
                    " but its line reads: ", line)
    )
  }
}

fit_sort <- function(...) {
  d <- data.frame(
    item = rep(c("A1", "A2", "B1"), each = 12), rater = rep(1:12, 3),
    target_construct = c(rep("A", 24), rep("B", 12)),
    assigned_construct = c(rep("A", 11), "B", rep("A", 9), rep("B", 3),
                           rep("B", 10), rep("A", 2)),
    stringsAsFactors = FALSE)
  sort_validity(d, ...)
}

fit_expert <- function(...) {
  relevance <- matrix(c(4, 4, 4, 3, 4, 4, 3, 4, 3, 4, 4, 4, 2, 2, 1, 2),
                      nrow = 4, dimnames = list(NULL, paste0("Item", 1:4)))
  expert_validity(relevance, mode = "relevance", lo = 1, hi = 4, ...)
}

fit_delphi <- function(...) {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4), S2 = c(2, 3, 2, 1, 3, 2))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2))
  long <- function(m, round) {
    data.frame(expert = paste0("E", seq_len(nrow(m))),
               item = rep(colnames(m), each = nrow(m)),
               round = round, rating = as.vector(m), stringsAsFactors = FALSE)
  }
  delphi_validity(rbind(long(r1, 1), long(r2, 2)), lo = 1, hi = 4, ...)
}

test_that("every number printed for an item is the number the object holds", {
  s <- fit_sort()
  out <- printed(s)
  r <- s$results
  for (col in c("psa", "psa_low", "psa_high", "csv", "p_value")) {
    expect_column_printed(out, r$item, r[[col]], label = paste("sort", col))
  }

  e <- fit_expert(agreement = "none")
  out <- printed(e)
  r <- e$results
  for (col in c("V", "ci_low", "ci_high", "I_CVI", "I_CVI_low", "I_CVI_high",
                "kappa_mod")) {
    expect_column_printed(out, r$item, r[[col]], label = paste("expert", col))
  }

  d <- fit_delphi(consensus_threshold = 0.75, B = 0)
  out <- printed(d)
  r <- d$results
  for (col in c("prop_agree", "prop_unchanged", "stability")) {
    expect_column_printed(out, r$item, r[[col]], digits = 2,
                          label = paste("delphi", col))
  }
})

test_that("the printed settings are the settings that ran", {
  s <- fit_sort(p0 = 0.6, alpha = 0.01)
  out <- squashed(s)
  expect_match(out, "p0 = 0.60", fixed = TRUE)
  expect_match(out, "alpha = 0.010", fixed = TRUE)
  expect_match(out, paste("Items:", s$design$n_items), fixed = TRUE)
  expect_match(out, paste("Raters:", s$design$n_raters), fixed = TRUE)

  d <- fit_delphi(consensus_threshold = 0.8, agree_cut = 4, B = 0)
  out <- squashed(d)
  expect_match(out, "a rating of 4 or higher on the 1-4 scale", fixed = TRUE)
  expect_match(out, "Consensus threshold: 80%", fixed = TRUE)
  expect_match(out, paste("Experts:", d$design$n_judges), fixed = TRUE)

  h <- content_handoff(fit_expert(agreement = "none"))
  out <- squashed(h)
  expect_match(out, paste0("Items carried forward: ", length(h$items), " of ",
                           length(unique(h$item_evidence$item))), fixed = TRUE)
})

test_that("an interval printed for a panel statistic is the computed interval", {
  ag <- panel_agreement(
    rbind(c(4, 4, 3, 2, 4), c(4, 3, 3, 2, 4), c(3, 4, 4, 1, 4), c(4, 4, 3, 2, 3)),
    B = 200, seed = 5
  )
  out <- squashed(ag)
  expect_match(out, format(round(ag$estimate, 3)), fixed = TRUE)
  expect_match(out, format(round(ag$ci_low, 3)), fixed = TRUE)
  expect_match(out, format(round(ag$ci_high, 3)), fixed = TRUE)
  expect_match(out, paste0(format(100 * (1 - ag$alpha)), "%"), fixed = TRUE)
})

test_that("a method's critique is printed when that method ran, and not otherwise", {
  X <- rbind(c(4, 4, 3, 2, 4), c(4, 3, 3, 2, 4), c(3, 4, 4, 1, 4))
  expect_match(squashed(panel_agreement(X >= 3, method = "ac1", B = 0)),
               "Vach and Gerke")
  expect_false(grepl("Vach and Gerke",
                     squashed(panel_agreement(X, method = "krippendorff", B = 0))))

  # The proportion-interval note names the method that ran.
  expect_match(squashed(fit_sort(proportion_ci = "exact")), "Clopper-Pearson")
  expect_match(squashed(fit_sort(proportion_ci = "wilson")), "Wilson score")
  expect_false(grepl("Clopper-Pearson", squashed(fit_sort(proportion_ci = "wilson"))))

  # Colquitt's labels are withheld for expert judges, and the printout says so.
  expert_judges <- squashed(fit_sort(judge_type = "expert"))
  expect_match(expert_judges, "not applied because the analysis was marked as using expert judges")

  # Each Delphi stability method prints its own critique and no other's.
  notes <- c(kappa = "No verbal labels",
             lambda = "predictability, not agreement",
             chisq_individual = "whether experts' later ratings depend",
             chisq_group = "comparing the two rounds' rating distributions",
             percent_change = "no statistical theory behind it")
  for (m in names(notes)) {
    out <- squashed(fit_delphi(stability = m, B = 0))
    expect_match(out, notes[[m]], info = m)
    for (other in setdiff(names(notes), m)) {
      expect_false(grepl(notes[[other]], out, fixed = TRUE),
                   info = paste(m, "printed", other, "'s critique"))
    }
  }
})

test_that("the status legend's example words are real recommendation values", {
  # Every workflow, because the legend's examples are drawn from all of them:
  # "Typical" is judge_validity's and "Covered" is domain_validity's.
  judge_ratings <- rbind(
    c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
    c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(4, 3, 4, 3, 1, 2),
    c(4, 4, 3, 4, 2, 2), c(2, 2, 2, 2, 1, 1)
  )
  dimnames(judge_ratings) <- list(paste0("Judge", 1:8), paste0("Item", 1:6))
  blueprint <- data.frame(
    item = paste0("I", 1:8), cell = c("A", "A", "A", "B", "B", "C", "C", "C"),
    stringsAsFactors = FALSE
  )
  fits <- list(
    fit_sort(), fit_expert(agreement = "none"),
    expert_validity(c(10, 8, 6), mode = "essentiality", N = 12),
    fit_delphi(consensus_threshold = 0.75, B = 0),
    judge_validity(judge_ratings, lo = 1, hi = 4),
    domain_validity(blueprint, targets = c(A = 0.4, B = 0.3, C = 0.3))
  )
  observed <- unique(unlist(lapply(fits, function(f) {
    as.character(f$results$recommendation)
  })))

  legend <- paste(utils::capture.output(contentvalidR:::.print_status_legend()),
                  collapse = " ")
  quoted <- regmatches(legend, regexpr("\\(([^)]*and so on)\\)", legend))
  words <- trimws(strsplit(gsub("[()]|and so on", "", quoted), ",")[[1]])
  words <- words[nzchar(words)]

  expect_gt(length(words), 0L)
  for (w in words) {
    expect_true(w %in% observed,
                info = paste0("the status legend names '", w,
                              "' as a recommendation word, but no workflow ",
                              "produces it; observed: ",
                              paste(observed, collapse = ", ")))
  }
})

test_that("a printed key defines every term, and unknown terms are refused", {
  # A typo in a print method's term list must fail loudly rather than drop the
  # definition silently.
  expect_error(contentvalidR:::.print_key("not_a_term"), "Unknown")

  defined <- contentvalidR:::.term_defs()$term
  for (f in list(fit_sort(), fit_expert(agreement = "none"),
                 fit_delphi(consensus_threshold = 0.75, B = 0))) {
    out <- printed(f)
    key <- sub(".*What these columns mean", "", out)
    key <- sub("What the status labels mean.*", "", key)
    shown <- regmatches(key, gregexpr("(?m)^  ([^ ].*?) --", key, perl = TRUE))[[1]]
    shown <- trimws(sub(" --$", "", sub("^  ", "", shown)))
    expect_gt(length(shown), 0L)
    expect_true(all(shown %in% defined),
                info = paste("undefined term printed:",
                             paste(setdiff(shown, defined), collapse = ", ")))
  }
})

test_that("statistics stay inside the ranges the glossary claims", {
  unanimous <- matrix(4, nrow = 5, ncol = 3,
                      dimnames = list(NULL, paste0("I", 1:3)))
  rejected <- matrix(1, nrow = 5, ncol = 3,
                     dimnames = list(NULL, paste0("I", 1:3)))
  split <- rbind(c(4, 1, 4), c(1, 4, 1), c(4, 1, 4), c(1, 4, 1), c(4, 1, 4))
  colnames(split) <- paste0("I", 1:3)

  for (m in list(unanimous, rejected, split)) {
    r <- expert_validity(m, mode = "relevance", lo = 1, hi = 4,
                         agreement = "none")$results
    expect_true(all(r$V >= 0 & r$V <= 1))                    # "0 to 1"
    expect_true(all(r$I_CVI >= 0 & r$I_CVI <= 1))            # "0 to 1"
    expect_true(all(r$kappa_mod <= 1, na.rm = TRUE))         # "0 to 1; higher is stronger"
    expect_true(all(r$I_CVI_low >= 0 & r$I_CVI_high <= 1))   # "between 0 and 1"
  }

  # CVR: "-1 to 1", and above 0 means more than half the panel called it
  # essential.
  cvr_fit <- expert_validity(c(12, 6, 0), mode = "essentiality", N = 12)$results
  expect_true(all(cvr_fit$cvr >= -1 & cvr_fit$cvr <= 1))
  expect_true(all((cvr_fit$cvr > 0) == (cvr_fit$ne > 12 / 2)))

  # Psa "0 to 1" and Csv "-1 to 1", including a construct never chosen.
  s <- fit_sort()$results
  expect_true(all(s$psa >= 0 & s$psa <= 1))
  expect_true(all(s$csv >= -1 & s$csv <= 1))

  # Delphi: shares are proportions; kappa and lambda have their stated ranges.
  d <- fit_delphi(consensus_threshold = 0.75, B = 0)
  expect_true(all(d$results$prop_agree >= 0 & d$results$prop_agree <= 1))
  st <- d$details$stability
  expect_true(all(st$prop_unchanged >= 0 & st$prop_unchanged <= 1))
  expect_true(all(st$value >= -1 & st$value <= 1, na.rm = TRUE))
  lam <- fit_delphi(stability = "lambda", B = 0)$details$stability
  expect_true(all(lam$value >= 0 & lam$value <= 1, na.rm = TRUE))
  pc <- fit_delphi(stability = "percent_change", B = 0)$details$stability
  expect_true(all(pc$value >= 0 & pc$value <= 1, na.rm = TRUE))
})

test_that("percentages written into prose match the computed proportions", {
  d <- fit_delphi(consensus_threshold = 0.75, B = 0)
  r <- d$results
  for (i in seq_len(nrow(r))) {
    stated <- regmatches(r$interpretation[i],
                         regexpr("[0-9]+(?=% agreed)", r$interpretation[i],
                                 perl = TRUE))
    expect_identical(stated, format(round(100 * r$prop_agree[i])),
                     info = paste("interpretation for", r$item[i]))
  }
  # And the threshold quoted in the prose is the threshold that ran.
  expect_true(all(grepl("threshold of 75%", r$interpretation, fixed = TRUE)))
})

test_that("a claim about how a statistic was computed holds of the numbers", {
  # The printed kappa note claims that quadratic weights make kappa the
  # intraclass correlation of the two rounds. Check the claim, not the string.
  d <- fit_delphi(B = 0)
  out <- squashed(d)
  expect_match(out, "kappa equals the intraclass correlation")

  st <- d$details$stability
  # Rebuild the two rounds' ratings for one item and compare with the ANOVA
  # form of Fleiss & Cohen (1973), which is what the note asserts.
  r1 <- c(4, 4, 3, 4, 2, 4)
  r2 <- c(4, 4, 4, 4, 3, 4)
  y <- c(r1, r2)
  subj <- factor(rep(seq_along(r1), 2))
  rater <- factor(rep(1:2, each = length(r1)))
  ss <- stats::anova(stats::lm(y ~ subj + rater))[["Sum Sq"]]
  icc <- (ss[1] - ss[3]) / (ss[1] + 2 * ss[2] + ss[3])
  expect_equal(st$value[st$item == "S1"], icc)

  # With linear weights the claim is not made, because it would be false.
  linear <- squashed(fit_delphi(B = 0, kappa_weights = "linear"))
  expect_false(grepl("kappa equals the intraclass correlation", linear,
                     fixed = TRUE))
  expect_match(linear, "counts twice a change of one")
})

test_that("the handoff prints the interval methods it actually carries", {
  h <- content_handoff(fit_expert(agreement = "none"))
  out <- squashed(h)
  st <- h$item_statistics
  carried <- unique(st[!is.na(st$interval_method),
                       c("statistic", "interval_method", "interval_level")])
  for (i in seq_len(nrow(carried))) {
    expect_match(out, sprintf("%s (%s, %s%%)", carried$statistic[i],
                              carried$interval_method[i],
                              format(100 * carried$interval_level[i])),
                 fixed = TRUE)
  }
  # A statistic with no interval is not announced as having one.
  expect_false(grepl("modified kappa (", out, fixed = TRUE))
})

test_that("compare_rounds only claims comparability when settings match", {
  same <- compare_rounds(fit_sort(), fit_sort())
  expect_true(same$comparable)
  expect_match(squashed(same), "Settings were identical across rounds")

  changed <- compare_rounds(fit_sort(p0 = 0.5), fit_sort(p0 = 0.7))
  expect_false(changed$comparable)
  out <- squashed(changed)
  expect_false(grepl("Settings were identical across rounds", out, fixed = TRUE))
  expect_match(out, "p0")
})

test_that("summary() counts match the fitted object's statuses", {
  d <- fit_delphi(consensus_threshold = 0.75, B = 0)
  s <- summary(d)
  out <- squashed(s)
  expect_match(out, paste("Consensus:", sum(d$results$status == "Supported"),
                          "of", nrow(d$results)), fixed = TRUE)
  expect_match(out, paste("No consensus:", sum(d$results$status == "Review"),
                          "of", nrow(d$results)), fixed = TRUE)

  e <- summary(fit_expert(agreement = "none"))
  expect_identical(e$n_supported, sum(fit_expert(agreement = "none")$results$status == "Supported"))
})

test_that("nothing printed claims a statistic the analysis did not compute", {
  # Panel agreement is named only when it was computed.
  with_agreement <- squashed(fit_expert(agreement = "krippendorff", seed = 2))
  without <- squashed(fit_expert(agreement = "none"))
  expect_match(with_agreement, "Panel agreement")
  expect_false(grepl("Panel agreement", without, fixed = TRUE))

  # A Delphi without a threshold must not print a consensus count or rule.
  no_threshold <- squashed(fit_delphi(B = 0))
  expect_match(no_threshold, "No consensus threshold was set")
  expect_false(grepl("reached consensus in their last round", no_threshold,
                     fixed = TRUE))

  # The kappa interval note appears only when an interval was computed.
  expect_false(grepl("percentile bootstraps that resample experts",
                     squashed(fit_delphi(B = 0, stability = "lambda")),
                     fixed = TRUE))
})

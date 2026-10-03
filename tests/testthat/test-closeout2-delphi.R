# Fixes from the review of the audit close-out: the Delphi printout, its
# report table, compare_rounds() settings and the stability figure. Each test
# names what the earlier code printed.

co2_long <- function(m, round, experts = paste0("E", seq_len(nrow(m)))) {
  data.frame(expert = experts, item = rep(colnames(m), each = nrow(m)),
             round = round, rating = as.vector(m), stringsAsFactors = FALSE)
}

# The ratings of the Delphi vignette: ten experts, six statements, three
# rounds, with E10 gone and S1 set aside in round 3.
co2_rounds <- function() {
  list(
    cbind(S1 = c(4, 4, 3, 4, 3, 4, 2, 4, 3, 4),
          S2 = c(3, 4, 3, 2, 4, 3, 4, 3, 2, 4),
          S3 = c(2, 1, 2, 2, 1, 3, 2, 1, 2, 2),
          S4 = c(4, 2, 3, 1, 4, 2, 3, 1, 4, 2),
          S5 = c(2, 3, 2, 3, 2, 4, 3, 2, 3, 2),
          S6 = c(3, 2, 4, 1, 3, 2, 4, 1, 3, 2)),
    cbind(S1 = c(4, 4, 4, 4, 3, 4, 3, 4, 3, 4),
          S2 = c(4, 4, 4, 4, 4, 4, 4, 3, 4, 4),
          S3 = c(2, 1, 2, 2, 1, 2, 2, 1, 2, 2),
          S4 = c(4, 2, 3, 1, 4, 1, 3, 2, 4, 2),
          S5 = c(3, 3, 2, 3, 3, 4, 3, 2, 3, 3),
          S6 = c(2, 3, 1, 4, 2, 3, 1, 4, 2, 3)),
    cbind(S2 = c(4, 4, 4, 4, 4, 4, 4, 4, 4),
          S3 = c(2, 1, 2, 2, 1, 2, 2, 1, 2),
          S4 = c(4, 1, 3, 1, 4, 1, 3, 2, 4),
          S5 = c(3, 3, 3, 3, 3, 4, 3, 3, 3),
          S6 = c(3, 2, 4, 1, 3, 2, 4, 1, 3))
  )
}

co2_ratings <- function() {
  r <- co2_rounds()
  rbind(co2_long(r[[1]], 1), co2_long(r[[2]], 2), co2_long(r[[3]], 3))
}

# Round 2 of the vignette with E8 to E10 replaced: ten experts each round,
# seven of them paired.
co2_replaced <- function() {
  r <- co2_rounds()
  rbind(co2_long(r[[1]], 1),
        co2_long(r[[2]], 2, c(paste0("E", 1:7), "N8", "N9", "N10")))
}

co2_lines <- function(x, width = 80) {
  old <- options(width = width)
  on.exit(options(old), add = TRUE)
  utils::capture.output(print(x))
}

co2_squash <- function(lines) gsub("\\s+", " ", paste(lines, collapse = " "))

# The words of a table's heading line, the first line that starts with Item.
co2_heading <- function(lines) {
  hit <- grep("^\\s+Item\\s", lines, value = TRUE)[1]
  strsplit(trimws(hit), "\\s{1,}")[[1]]
}

test_that("the stored interpretation keeps one decimal, as the handoff does", {
  m1 <- cbind(S1 = c(4, 4, 4, 4, 4, 4, 2, 2, 1), S2 = c(4, 4, 4, 4, 4, 4, 4, 4, 3))
  m2 <- cbind(S1 = c(4, 4, 4, 4, 4, 4, 2, 2, 1), S2 = c(4, 4, 4, 4, 4, 4, 4, 4, 4))
  fit <- delphi_validity(rbind(co2_long(m1, 1), co2_long(m2, 2)), lo = 1,
                         hi = 4, consensus_threshold = .667, B = 0)
  r <- fit$results
  # Every item's interpretation read "against a threshold of 66.70%" once
  # one share sat just under it, while the handoff rule said 66.7%.
  expect_identical(
    r$interpretation,
    c(paste("No consensus in the last round: 66.7% agreed, against a",
            "threshold of 66.7%. Consider another round, rewording, or",
            "reporting the item as without consensus."),
      paste("Consensus in the last round: 100% agreed, against a threshold",
            "of 66.7%. Check the stability trend before closing the item."))
  )
  expect_identical(summary(fit)$reviewed_items$interpretation,
                   r$interpretation[1])
  rule <- content_handoff(fit)$item_evidence$rule
  expect_true(all(grepl("at least 66.7% of experts", rule, fixed = TRUE)))

  # The printouts tell the share and the threshold apart.
  out <- co2_squash(co2_lines(fit))
  expect_match(out, "Consensus threshold: 66.70%, as supplied.", fixed = TRUE)
  expect_match(co2_squash(co2_lines(summary(fit))),
               "S1 (No consensus): No consensus in the last round: 66.67% agreed, against a threshold of 66.70%.",
               fixed = TRUE)
  # A threshold no share sits just under keeps the stored text.
  plain <- delphi_validity(rbind(co2_long(m1, 1), co2_long(m2, 2)), lo = 1,
                           hi = 4, consensus_threshold = .75, B = 0)
  expect_match(co2_squash(co2_lines(summary(plain))),
               "66.7% agreed, against a threshold of 75%.", fixed = TRUE)
})

test_that("the report never prints a share below the threshold as meeting it", {
  rr <- co2_ratings()
  rr$rating[rr$round == 3 & rr$item == "S4"] <- c(4, 4, 3, 3, 4, 3, 1, 1, 1)
  fit <- delphi_validity(rr, lo = 1, hi = 4, consensus_threshold = .667, B = 0)
  rep <- content_report(fit)
  # It printed "S4 ... .67 ... No consensus" beside "at least 66.7%".
  expect_identical(rep$agree[rep$item == "S4"], ".6667")
  expect_identical(rep$agree[rep$item == "S1"], "1.00")
  expect_match(attr(rep, "note"),
               "Consensus = at least 66.70% of experts agreeing in the last round.",
               fixed = TRUE)
  flagged <- content_report(fit, include = "flagged")
  expect_identical(flagged$agree[flagged$item == "S4"], ".6667")
  expect_match(attr(flagged, "note"), "at least 66.70%", fixed = TRUE)
  md <- content_report(fit, format = "markdown")
  expect_true(any(grepl("^\\| S4 \\|.*\\| \\.6667 \\|", md)))
  expect_match(paste(md, collapse = " "), "at least 66.70% of experts",
               fixed = TRUE)
  # The printout and the report agree.
  row <- grep("^\\s+S4\\s", co2_lines(fit), value = TRUE)[1]
  expect_match(row, " .6667 ", fixed = TRUE)

  # A share that is not that close keeps two decimals, and the note one.
  plain <- content_report(delphi_validity(rr, lo = 1, hi = 4,
                                          consensus_threshold = .75, B = 0))
  expect_identical(plain$agree[plain$item == "S4"], ".67")
  expect_match(attr(plain, "note"), "at least 75% of experts", fixed = TRUE)
})

test_that("the chi-square and net-change tables keep the statistic beside Stable", {
  d <- co2_ratings()
  for (method in c("chisq_individual", "chisq_group", "percent_change")) {
    fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75,
                           stability = method)
    stat <- if (method == "percent_change") "Net change" else "Chi-square"
    for (w in c(80, 60)) {
      info <- paste(method, "at width", w)
      # The print dropped Stable at 80, and the report dropped Chi-square
      # while keeping Stable, df and p.
      for (lines in list(co2_lines(fit, w), co2_lines(content_report(fit), w))) {
        head <- paste(co2_heading(lines), collapse = " ")
        expect_match(head, stat, fixed = TRUE, info = info)
        expect_match(head, "Stable", fixed = TRUE, info = info)
        # Agree, which consensus rests on, stays too.
        expect_match(head, "Agree", fixed = TRUE, info = info)
        if (method != "percent_change") {
          # APA reports a chi-square with its df and p.
          expect_match(head, " df Chi-square ", fixed = TRUE, info = info)
          expect_match(head, " p Stable", fixed = TRUE, info = info)
        }
      }
    }
  }
  # Unchanged gives way first, and its definition goes with it.
  grp <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75,
                         stability = "chisq_group")
  lines <- co2_lines(grp, 80)
  expect_false("Unchanged" %in% co2_heading(lines))
  expect_match(co2_squash(lines), "Not shown for width: Unchanged.", fixed = TRUE)
  expect_false(grepl("Unchanged: share who kept", co2_squash(lines), fixed = TRUE))
  expect_match(co2_squash(lines), "Agree: share of experts agreeing", fixed = TRUE)
})

test_that("kappa and lambda keep their statistic and the decision at 60 columns", {
  d <- co2_ratings()
  kap <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75,
                         seed = 2026)
  for (w in c(80, 60)) {
    head <- co2_heading(co2_lines(kap, w))
    expect_true(all(c("Decision", "Agree", "Unchanged", "Kappa") %in% head),
                info = w)
  }
  expect_true(all(c("95%", "CI") %in% co2_heading(co2_lines(kap, 80))))
  lam <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75,
                         stability = "lambda")
  narrow <- co2_lines(lam, 60)
  # Lambda was left out at 60 columns.
  expect_true(all(c("Decision", "Agree", "Lambda") %in% co2_heading(narrow)))
  expect_match(co2_squash(narrow), "Not shown for width: Unchanged.", fixed = TRUE)
  expect_false(grepl("Unchanged: share who kept", co2_squash(narrow), fixed = TRUE))
  rep <- co2_lines(content_report(lam), 60)
  expect_true(all(c("Agree", "Lambda", "Decision") %in% co2_heading(rep)))
})

test_that("the Paired column comes last, gives way first, and the report notes it", {
  fit <- delphi_validity(co2_replaced(), lo = 1, hi = 4,
                         consensus_threshold = .75, seed = 1)
  expect_true(all(fit$details$stability$n_paired == 7L))
  wide <- co2_lines(fit, 80)
  head <- co2_heading(wide)
  expect_identical(utils::tail(head, 1), "Paired")
  expect_true(all(c("Unchanged", "Kappa", "CI") %in% head))
  out <- co2_squash(wide)
  expect_match(out, "Paired: experts who rated the item in both rounds of that pair, on whom Unchanged and kappa rest.",
               fixed = TRUE)
  expect_match(out, "(Paired against Experts).", fixed = TRUE)

  # At 60 columns Paired displaced Unchanged and Kappa, and the notes still
  # defined both.
  narrow <- co2_lines(fit, 60)
  head <- co2_heading(narrow)
  expect_false("Paired" %in% head)
  expect_true(all(c("Unchanged", "Kappa") %in% head))
  out <- co2_squash(narrow)
  expect_match(out, "Not shown for width: 95% CI, Paired.", fixed = TRUE)
  expect_false(grepl("Paired: experts", out, fixed = TRUE))
  expect_false(grepl("Paired against Experts", out, fixed = TRUE))
  expect_match(out, "in its last round (n_paired in details$stability).",
               fixed = TRUE)

  # The report showed Experts 10 beside statistics from 7, with no word.
  note <- attr(content_report(fit), "note")
  expect_match(note, paste("Unchanged and kappa rest on the experts who rated",
                           "the item in both of those rounds, fewer than the",
                           "Experts column shows: 7 for every item."),
               fixed = TRUE)
  grp <- delphi_validity(co2_replaced(), lo = 1, hi = 4,
                         consensus_threshold = .75, stability = "chisq_group")
  expect_match(attr(content_report(grp), "note"),
               "Unchanged and chi-square rest on the experts", fixed = TRUE)

  # Items paired on different counts are grouped by count.
  d <- co2_replaced()
  d <- d[!(d$item == "S2" & d$round == 2 & d$expert == "E1"), ]
  mixed <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  expect_match(attr(content_report(mixed), "note"),
               "Experts column shows: 7 for S1, S3, S4, S5 and S6; 6 for S2.",
               fixed = TRUE)

  # A panel paired in full has no such sentence.
  full <- delphi_validity(co2_ratings(), lo = 1, hi = 4,
                          consensus_threshold = .75, B = 0)
  expect_false(grepl("rest on the experts", attr(content_report(full), "note"),
                     fixed = TRUE))
})

test_that("compare_rounds() writes every proportion setting as APA does", {
  d <- co2_ratings()
  fit <- function(...) delphi_validity(d, lo = 1, hi = 4, B = 0, ...)
  cr <- compare_rounds(fit(consensus_threshold = .75),
                       fit(consensus_threshold = .8, alpha = .1))
  ch <- cr$settings_changes
  # It wrote "0.75" and "0.8" beside ".05" and ".10".
  expect_identical(ch$previous[ch$setting == "consensus_threshold"], ".75")
  expect_identical(ch$current[ch$setting == "consensus_threshold"], ".80")
  expect_identical(ch$previous[ch$setting == "alpha"], ".05")
  expect_match(co2_squash(co2_lines(cr)), "consensus_threshold .75 .80",
               fixed = TRUE)

  added <- compare_rounds(fit(), fit(consensus_threshold = .75))$settings_changes
  expect_identical(c(added$previous, added$current), c("(not set)", ".75"))
  # Two values that would read alike get the digits that tell them apart.
  near <- compare_rounds(fit(consensus_threshold = 2 / 3),
                         fit(consensus_threshold = .667))$settings_changes
  expect_identical(c(near$previous, near$current), c(".6667", ".667"))
  # A cut on the rating scale is a scale point, not a proportion.
  cut <- compare_rounds(fit(agree_cut = 3), fit(agree_cut = 4))$settings_changes
  expect_identical(c(cut$previous, cut$current), c("3", "4"))

  con <- utils::read.csv(system.file("extdata", "expert_congruence_example.csv",
                                     package = "contentvalidR"),
                         stringsAsFactors = FALSE)
  ioc <- compare_rounds(expert_validity(con, mode = "congruence"),
                        expert_validity(con, mode = "congruence",
                                        ioc_cut = .5))$settings_changes
  expect_identical(c(ioc$previous, ioc$current), c(".70", ".50"))
})

test_that("the stability view with no pair of rounds stops before a device opens", {
  nr <- rbind(
    data.frame(expert = paste0("E", 1:6), item = "S1", round = 1,
               rating = c(4, 4, 3, 4, 3, 4)),
    data.frame(expert = paste0("E", 1:6), item = "S1", round = 3,
               rating = c(4, 4, 4, 4, 3, 4)),
    data.frame(expert = paste0("E", 1:6), item = "S2", round = 2,
               rating = c(2, 3, 2, 1, 3, 2))
  )
  fit <- delphi_validity(nr, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  expect_identical(nrow(fit$details$stability), 0L)
  before <- grDevices::dev.list()
  # It opened a device, and wrote Rplots.pdf in a script, before stopping.
  expect_error(plot(fit, type = "stability"),
               "no pair of consecutive rounds to plot")
  expect_identical(grDevices::dev.list(), before)
})

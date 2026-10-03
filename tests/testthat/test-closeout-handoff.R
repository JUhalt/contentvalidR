# The handoff and the evidence across stages before 1.0: what each stability
# criterion means, what an interval with no width means, what is said when
# nothing is carried, and what the evidence table, its key and its profile
# show.

extdata <- function(f) system.file("extdata", f, package = "contentvalidR")

# The rounds of the Delphi vignette: S1 is set aside after round 2, and E10
# leaves before round 3.
delphi_rounds <- function() {
  round1 <- cbind(
    S1 = c(4, 4, 3, 4, 3, 4, 2, 4, 3, 4),
    S2 = c(3, 4, 3, 2, 4, 3, 4, 3, 2, 4),
    S3 = c(2, 1, 2, 2, 1, 3, 2, 1, 2, 2),
    S4 = c(4, 2, 3, 1, 4, 2, 3, 1, 4, 2),
    S5 = c(2, 3, 2, 3, 2, 4, 3, 2, 3, 2),
    S6 = c(3, 2, 4, 1, 3, 2, 4, 1, 3, 2)
  )
  round2 <- cbind(
    S1 = c(4, 4, 4, 4, 3, 4, 3, 4, 3, 4),
    S2 = c(4, 4, 4, 4, 4, 4, 4, 3, 4, 4),
    S3 = c(2, 1, 2, 2, 1, 2, 2, 1, 2, 2),
    S4 = c(4, 2, 3, 1, 4, 1, 3, 2, 4, 2),
    S5 = c(3, 3, 2, 3, 3, 4, 3, 2, 3, 3),
    S6 = c(2, 3, 1, 4, 2, 3, 1, 4, 2, 3)
  )
  round3 <- cbind(
    S2 = c(4, 4, 4, 4, 4, 4, 4, 4, 4),
    S3 = c(2, 1, 2, 2, 1, 2, 2, 1, 2),
    S4 = c(4, 1, 3, 1, 4, 1, 3, 2, 4),
    S5 = c(3, 3, 3, 3, 3, 4, 3, 3, 3),
    S6 = c(3, 2, 4, 1, 3, 2, 4, 1, 3)
  )
  list(round1, round2, round3)
}
to_long <- function(m, round, ids = paste0("E", seq_len(nrow(m)))) {
  data.frame(expert = ids, item = rep(colnames(m), each = nrow(m)),
             round = round, rating = as.vector(m))
}
delphi_ratings <- function() {
  r <- delphi_rounds()
  rbind(to_long(r[[1]], 1), to_long(r[[2]], 2), to_long(r[[3]], 3))
}
stability_rows <- function(h, statistic) {
  st <- h$item_statistics
  st[st$statistic == statistic, , drop = FALSE]
}
printed <- function(x) capture.output(print(x))
joined <- function(x) {
  gsub("[[:space:]]+", " ", paste(printed(x), collapse = " "))
}

relevance_fit <- function(...) {
  relevance <- matrix(c(4,4,4,3, 4,4,3,4, 3,4,4,4, 2,2,1,2), nrow = 4,
                      dimnames = list(NULL, paste0("Item", 1:4)))
  expert_validity(relevance, mode = "relevance", lo = 1, hi = 4, ...)
}
essentiality_fit <- function() {
  expert_validity(c(Item1 = 10, Item2 = 9, Item3 = 8, Item4 = 3),
                  mode = "essentiality", N = 12)
}
congruence_data <- function() {
  read.csv(extdata("expert_congruence_example.csv"), stringsAsFactors = FALSE)
}

# 1. Which way each stability criterion reads, and what the fit read.

test_that("each stability criterion says which way it reads, and the reading", {
  ratings <- delphi_ratings()
  rules <- c(chisq_individual = "Stable when p is below alpha",
             chisq_group = "Stable when p is at or above alpha",
             percent_change = "Stable when the change is below .15")
  rows <- c(chisq_individual = "stability p_value",
            chisq_group = "stability p_value",
            percent_change = "net percent change")
  for (m in names(rules)) {
    fit <- delphi_validity(ratings, lo = 1, hi = 4, consensus_threshold = .75,
                           stability = m)
    h <- content_handoff(fit)
    # The schema's columns do not change.
    expect_identical(names(h$item_statistics),
                     names(contentvalidR:::.handoff_schema()$item_statistics))
    st <- stability_rows(h, rows[[m]])
    expect_identical(st$item, fit$results$item)
    expect_true(all(grepl(rules[[m]], st$note, fixed = TRUE)), info = m)
    stable <- fit$results$stable
    expect_true(all(grepl("Read as stable.", st$note[stable %in% TRUE],
                          fixed = TRUE)), info = m)
    expect_true(all(grepl("Not read as stable.", st$note[stable %in% FALSE],
                          fixed = TRUE)), info = m)
    # An item the fit could not read either way gets no reading.
    expect_false(any(grepl("read as stable", st$note[is.na(stable)],
                           ignore.case = TRUE)), info = m)
  }
  # The two chi-squares put the same alpha in `criterion`, read in opposite
  # directions, and each is stable for S1 here.
  ind <- content_handoff(delphi_validity(ratings, lo = 1, hi = 4,
                                         consensus_threshold = .75,
                                         stability = "chisq_individual"))
  grp <- content_handoff(delphi_validity(ratings, lo = 1, hi = 4,
                                         consensus_threshold = .75,
                                         stability = "chisq_group"))
  s1 <- function(h) stability_rows(h, "stability p_value")[1, ]
  expect_lt(s1(ind)$value, s1(ind)$criterion)
  expect_gte(s1(grp)$value, s1(grp)$criterion)
  expect_match(s1(ind)$note, "Read as stable.", fixed = TRUE)
  expect_match(s1(grp)$note, "Read as stable.", fixed = TRUE)
  # Percent change: S5 moved .22, above .15.
  pc <- content_handoff(delphi_validity(ratings, lo = 1, hi = 4,
                                        consensus_threshold = .75,
                                        stability = "percent_change"))
  s5 <- stability_rows(pc, "net percent change")
  expect_match(s5$note[s5$item == "S5"], "Not read as stable.", fixed = TRUE)
  # Kappa has no criterion and makes no such call.
  kp <- content_handoff(delphi_validity(ratings, lo = 1, hi = 4,
                                        consensus_threshold = .75, B = 0))
  expect_false(any(grepl("read as stable",
                         stability_rows(kp, "weighted kappa (quadratic)")$note,
                         ignore.case = TRUE)))
})

# 2. An interval with no width, and the experts a pair compared.

test_that("a zero-width stability interval says what it means", {
  fit <- delphi_validity(delphi_ratings(), lo = 1, hi = 4,
                         consensus_threshold = 0.75, seed = 2026)
  k <- stability_rows(content_handoff(fit), "weighted kappa (quadratic)")
  zero <- is.finite(k$lower) & k$lower == k$upper
  expect_true(any(zero))
  # The bounds are kept as computed.
  expect_identical(k$lower, fit$results$stability_low)
  expect_true(all(grepl("Every resample of the experts gave the same value",
                        k$note[zero], fixed = TRUE)))
  expect_false(any(grepl("Every resample", k$note[!zero], fixed = TRUE)))
})

test_that("stability rows give the paired n when below the last round's", {
  r <- delphi_rounds()
  # E8 to E10 are replaced in round 2: ten rate each round, seven both.
  ids <- c(paste0("E", 1:7), paste0("N", 8:10))
  fit <- delphi_validity(rbind(to_long(r[[1]], 1), to_long(r[[2]], 2, ids)),
                         lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  h <- content_handoff(fit)
  for (stat in c("proportion unchanged", "weighted kappa (quadratic)")) {
    st <- stability_rows(h, stat)
    expect_true(all(grepl(paste("From the 7 experts who rated the item in",
                                "both rounds; 10 rated it in its last round."),
                          st$note, fixed = TRUE)), info = stat)
  }
  # With the same experts in both rounds nothing is added.
  same <- content_handoff(delphi_validity(
    rbind(to_long(r[[1]], 1), to_long(r[[2]], 2)), lo = 1, hi = 4,
    consensus_threshold = .75, B = 0))
  expect_false(any(grepl("both rounds;", same$item_statistics$note,
                         fixed = TRUE)))
})

# 3. Nothing carried, and stages that decided nothing.

test_that("a handoff where nothing is carried does not say to carry it", {
  ratings <- delphi_ratings()
  loose <- delphi_validity(ratings[ratings$item %in% paste0("S", 1:4), ],
                           lo = 1, hi = 4, B = 0)
  out <- joined(content_handoff(loose))
  expect_match(out, "No decision rule was applied in this analysis",
               fixed = TRUE)
  expect_match(out, "keep = \"Descriptive only\" carries such items",
               fixed = TRUE)
  expect_false(grepl("Carry these items", out, fixed = TRUE))
  expect_false(grepl("nomo_screen", out, fixed = TRUE))

  # Nothing met `keep`, with a rule applied.
  sorts <- read.csv(extdata("sort_example.csv"), stringsAsFactors = FALSE)
  sorts$assigned_construct <- "Z"
  none <- joined(content_handoff(sort_validity(sorts)))
  expect_match(none, "No item met `keep`, so nothing is carried", fixed = TRUE)
  expect_false(grepl("Carry these items", none, fixed = TRUE))
  expect_false(grepl("No decision rule", none, fixed = TRUE))

  # Some items described only: they are named, with the call that carries
  # them.
  d <- congruence_data()
  d <- rbind(d, data.frame(item = "I4", judge = 1:6, objective = "A",
                           target_objective = "A", score = 1))
  fit <- expert_validity(d, mode = "congruence")
  expect_identical(fit$results$recommendation[fit$results$item == "I4"],
                   "Target described")
  part <- joined(content_handoff(fit))
  expect_match(part, "No decision rule was applied to I4, so it is",
               fixed = TRUE)
  expect_match(part, "keep = c(\"Supported\", \"Descriptive only\")",
               fixed = TRUE)
  expect_match(part, "Carry these items", fixed = TRUE)
})

test_that("a stage that decided nothing holds nothing back", {
  ratings <- delphi_ratings()
  loose <- delphi_validity(ratings[ratings$item %in% paste0("S", 1:4), ],
                           lo = 1, hi = 4, B = 0)
  ev <- content_evidence(loose)
  # Nothing is held back, and nothing is carried either: no stage decided.
  expect_length(ev$carried, 0L)
  expect_false(ev$flow[[1]]$decided)
  expect_length(ev$flow[[1]]$held, 0L)
  out <- printed(ev)
  txt <- gsub("[[:space:]]+", " ", paste(out, collapse = " "))
  expect_match(txt, "No stage applied a decision rule", fixed = TRUE)
  expect_false(grepl("Held back: S1", txt, fixed = TRUE))
  expect_false(any(grepl("Held back", out[grepl("^  S[1-4] ", out)])))
  expect_true(all(grepl("No decision$", out[grepl("^  S[1-4] ", out)])))

  # Beside a stage that did decide, only that stage holds items back.
  d <- congruence_data()
  untargeted <- d[setdiff(names(d), "target_objective")]
  both <- content_evidence(First = expert_validity(d, mode = "congruence"),
                           Second = expert_validity(untargeted,
                                                    mode = "congruence"))
  expect_identical(both$carried, c("I1", "I2"))
  expect_true(both$flow$First$decided)
  expect_false(both$flow$Second$decided)
  txt <- joined(both)
  expect_match(txt, "Held back: I3 (First).", fixed = TRUE)
  expect_match(txt, "Second applied no decision rule", fixed = TRUE)
  expect_match(txt, paste("A stage that applied no decision rule to an item",
                          "does not hold it back"), fixed = TRUE)
  # The handoff records what the stage did, unchanged.
  expect_false(any(both$stages$Second$item_evidence$carried))
})

# 4. The handoff's header lines.

test_that("the constructs line wraps and says when none is carried", {
  sorts <- read.csv(extdata("sort_example.csv"), stringsAsFactors = FALSE)
  long <- c(A = "Affective organizational commitment",
            B = "Continuance organizational commitment",
            C = "Normative organizational commitment")
  for (col in c("target_construct", "assigned_construct")) {
    sorts[[col]] <- unname(long[as.character(sorts[[col]])])
  }
  old <- options(width = 80)
  on.exit(options(old))
  out <- printed(content_handoff(sort_validity(sorts)))
  expect_lte(max(nchar(out)), 79L)
  expect_match(paste(out, collapse = " "), "Constructs: Affective",
               fixed = TRUE)

  sorts$assigned_construct <- "Z"
  out <- printed(content_handoff(sort_validity(sorts)))
  expect_true("Constructs: none carried" %in% out)
})

test_that("the print shows the keying it carries", {
  sorts <- read.csv(extdata("sort_example.csv"), stringsAsFactors = FALSE)
  fit <- sort_validity(sorts)
  expect_true("Keying: not stated; response scale not stated" %in%
                printed(content_handoff(fit)))
  expect_true("Keying: reverse-keyed A2; response scale 1 to 5" %in%
                printed(content_handoff(fit, reverse_keyed = "A2",
                                        response_scale = c(1, 5))))
  expect_true("Keying: no item reverse-keyed; response scale 1 to 7" %in%
                printed(content_handoff(fit, reverse_keyed = character(0),
                                        response_scale = c(1, 7))))
  # A handoff from before 0.7.0 has no keying columns.
  h <- content_handoff(fit)
  h$item_evidence$keying <- NULL
  h$item_evidence$response_min <- NULL
  h$item_evidence$response_max <- NULL
  expect_true("Keying: not stated; response scale not stated" %in% printed(h))
})

test_that("the panel interval prints as a CI, or in words with no width", {
  h <- content_handoff(relevance_fit(seed = 1))
  ps <- h$panel_statistics
  expect_gt(ps$upper, ps$lower)
  out <- joined(h)
  expect_match(out, paste0("Krippendorff's alpha (ordinal) = .62, 95% CI ",
                           contentvalidR:::.fmt_ci(ps$lower, ps$upper),
                           " (item-resampling percentile bootstrap)"),
               fixed = TRUE)
  expect_false(grepl("% interval", out, fixed = TRUE))
  expect_identical(ps$note, "")

  # The help example of expert_validity(): every resample gave -.25.
  same <- matrix(c(4,4,4,3, 4,4,3,4, 3,4,4,4, 4,3,4,4), nrow = 4,
                 dimnames = list(NULL, paste0("Item", 1:4)))
  hz <- content_handoff(expert_validity(same, lo = 1, hi = 4, seed = 1))
  ps <- hz$panel_statistics
  expect_equal(ps$lower, ps$upper)
  expect_match(ps$note, "Every resample of the items gave the same value",
               fixed = TRUE)
  out <- joined(hz)
  expect_match(out, paste("= -.25; no 95% CI, because every resample of the",
                          "items gave the same value"), fixed = TRUE)
  expect_false(grepl("[-.25, -.25]", out, fixed = TRUE))
})

# 5. The help page.

test_that("?content_handoff documents the Delphi intervals and every NA case", {
  path <- testthat::test_path("..", "..", "man", "content_handoff.Rd")
  rd <- if (file.exists(path)) {
    paste(readLines(path, warn = FALSE), collapse = " ")
  } else {
    doc <- tryCatch(tools::Rd_db("contentvalidR")[["content_handoff.Rd"]],
                    error = function(e) NULL)
    if (is.null(doc)) skip("handoff documentation is not available")
    paste(as.character(doc), collapse = " ")
  }
  rd <- gsub("[[:space:]]+", " ", rd)
  expect_match(rd, "Delphi weighted kappa: the expert-resampling percentile",
               fixed = TRUE)
  for (s in c("proportion unchanged, lambda, the chi-squares, net percent",
              "rated in one round only", "not consecutive",
              "no expert rated it in both", "do not all read the same way",
              "zero width")) {
    expect_match(rd, s, fixed = TRUE)
  }
})

# 6. A congruence handoff from before 1.0.

test_that("content_evidence() refuses a congruence handoff made before 1.0", {
  d <- congruence_data()
  h <- content_handoff(expert_validity(d, mode = "congruence"))
  # Before 1.0 the "target IOC" held the mean rating, beside "competitor IOC"
  # and "IOC margin".
  old <- h
  s <- old$item_statistics[old$item_statistics$statistic == "target IOC", ]
  s$value <- c(1, 1, 0.83)
  comp <- s
  comp$statistic <- "competitor IOC"
  marg <- s
  marg$statistic <- "IOC margin"
  old$item_statistics <- rbind(s, comp, marg)
  expect_error(content_evidence(Old = old),
               "Stage 1 is a congruence handoff made before contentvalidR 1.0")
  expect_error(content_evidence(Old = old), "holds a mean rating",
               fixed = TRUE)
  # Without a target mapping it carried the mean as "IOC".
  untargeted <- old
  untargeted$item_statistics <- transform(s, statistic = "IOC")
  expect_error(content_evidence(untargeted), "\"IOC\" holds a mean rating",
               fixed = TRUE)
  # A handoff made now is read.
  expect_s3_class(content_evidence(h), "contentvalid_evidence")
})

# 7. Two headings that share one term.

test_that("the key explains each statistic once, under its own heading", {
  d <- congruence_data()
  untargeted <- d[setdiff(names(d), "target_objective")]
  out <- printed(content_evidence(
    First = expert_validity(d, mode = "congruence"),
    Second = expert_validity(untargeted, mode = "congruence")
  ))
  expect_identical(sum(grepl("^  Target IOC -- ", out)), 1L)
  expect_identical(sum(grepl("^  Highest IOC -- ", out)), 1L)
  # A heading repeated for the same term is still explained once.
  key <- capture.output(contentvalidR:::.print_key(c("psa", "psa"),
                                                   headings = c("Psa", "Psa")))
  expect_identical(sum(grepl("^  Psa -- ", key)), 1L)
})

# 8. Stage labels that are column names.

test_that("a stage cannot take the name of a table column", {
  expect_error(content_evidence(item = relevance_fit(agreement = "none"),
                                result = essentiality_fit()),
               "A stage cannot be labeled \"item\" or \"result\"",
               fixed = TRUE)
  expect_error(content_evidence(Result = relevance_fit(agreement = "none")),
               "cannot be labeled \"Result\"", fixed = TRUE)
})

# 9. The evidence table and its key.

test_that("the result column numbers the stages; the key matches the table", {
  old <- options(width = 80)
  on.exit(options(old))
  ev <- content_evidence(relevance_fit(agreement = "none"), essentiality_fit())
  out <- printed(ev)
  expect_lte(max(nchar(out)), 80L)
  expect_false(any(grepl("Not shown for width", out, fixed = TRUE)))
  expect_true(any(grepl("^  Item4 .* Held back: 1, 2$", out)))
  expect_true(any(grepl("^  Item2 .* Held back: 2$", out)))
  expect_true(any(grepl("^  CVR -- ", out)))
  # No line of the key starts with the missing marker.
  expect_false(any(grepl("^ *-- ", out)))

  # Long stage names: the stage columns are headed by their numbers, so both
  # stay on screen, and the key explains both.
  wt <- read.csv(extdata("walkthrough_relevance.csv"), stringsAsFactors = FALSE)
  panel <- expert_validity(as.matrix(wt[setdiff(names(wt), "expert")]),
                           mode = "relevance", lo = 1, hi = 4,
                           agreement = "none")
  sorts <- read.csv(extdata("walkthrough_sort.csv"), stringsAsFactors = FALSE)
  wide <- printed(content_evidence(
    `Expert relevance panel (round 1)` = panel,
    `Item sort with naive judges (study 2)` = sort_validity(sorts)
  ))
  expect_false(any(grepl("Not shown for width", wide, fixed = TRUE)))
  expect_true(any(grepl("^  Item +1 +2 +Result$", wide)))
  expect_true(any(grepl("^  Psa -- ", wide)))
  expect_true(any(grepl("^  I-CVI -- ", wide)))
  expect_true(any(grepl("^  1, 2 -- The stages, numbered as listed above",
                        wide)))
  expect_true(any(grepl("^  EF5 .* Held back: 1, 2$", wide)))

  # A stage that did not review an item: the marker is explained in a
  # sentence that does not open with it.
  first <- content_handoff(relevance_fit(agreement = "none"))
  later <- content_handoff(expert_validity(
    c(Item1 = 10, Item2 = 9, Item3 = 8), mode = "essentiality", N = 12))
  seq_out <- printed(content_evidence(Panel = first, Essential = later))
  seq_txt <- gsub("[[:space:]]+", " ", paste(seq_out, collapse = " "))
  expect_match(seq_txt, "A \"--\" marks a stage that did not review the item.",
               fixed = TRUE)
  expect_false(any(grepl("^ *-- ", seq_out)))
})

# 10. The evidence profile.

test_that("the profile draws at full size and fits its verdicts", {
  wt <- read.csv(extdata("walkthrough_relevance.csv"), stringsAsFactors = FALSE)
  panel <- expert_validity(as.matrix(wt[setdiff(names(wt), "expert")]),
                           mode = "relevance", lo = 1, hi = 4,
                           agreement = "none")
  sorts <- read.csv(extdata("walkthrough_sort.csv"), stringsAsFactors = FALSE)
  ev <- content_evidence(`Relevance panel` = panel,
                         `Item sort` = sort_validity(sorts),
                         `Second relevance panel` = panel)
  cex <- numeric(0)
  setHook("plot.new", function() cex <<- c(cex, graphics::par("cex")))
  on.exit(setHook("plot.new", NULL, "replace"), add = TRUE)
  grDevices::pdf(NULL, width = 7.5, height = 5.5)
  plot(ev)
  grDevices::dev.off()
  # layout() would have drawn three stages at 0.66.
  expect_true(length(cex) >= 4L)
  expect_true(all(cex == 1))

  # Each verdict fits between its start and the room given, at 8 points or
  # more, wrapping where shrinking is not enough.
  grDevices::pdf(NULL, width = 7.5, height = 5.5)
  graphics::plot.new()
  smallest <- 8 / graphics::par("ps")
  verdict <- c("carried", paste("held back: Relevance panel; Item sort;",
                                "Second relevance panel"))
  fit <- contentvalidR:::.evidence_fit_text(verdict, c(1, 2), room = 0.25,
                                            cex = 0.78, smallest = smallest)
  widths <- lapply(seq_along(verdict), function(i) {
    graphics::strwidth(fit$lines[[i]], cex = fit$cex, font = c(1, 2)[i])
  })
  # Short verdicts keep their size.
  short <- contentvalidR:::.evidence_fit_text("carried", 1, room = 0.5,
                                              cex = 0.78, smallest = smallest)
  grDevices::dev.off()
  expect_gte(fit$cex, smallest)
  expect_gt(length(fit$lines[[2]]), 1L)
  expect_true(all(unlist(widths) <= 0.25))
  expect_identical(paste(fit$lines[[2]], collapse = " "), verdict[2])
  expect_identical(short$cex, 0.78)

  # Verdicts that would spill into the next row even wrapped give the
  # stages' numbers, and the titles are numbered to match.
  long <- content_evidence(
    `Expert relevance panel (round 1)` = panel,
    `Item sort with naive judges (study 2)` = sort_validity(sorts),
    `Second relevance panel` = panel
  )
  plan_on <- function(ev, width, height) {
    grDevices::pdf(NULL, width = width, height = height)
    on.exit(grDevices::dev.off())
    graphics::par(oma = c(0, 4, 1.6, 0.5), mar = c(4.1, 0.6, 1.9, 0.6))
    contentvalidR:::.evidence_profile_plan(ev, length(ev$items), 8 / 12)
  }
  narrow <- plan_on(long, 5, 4)
  expect_true(narrow$numbered)
  expect_identical(narrow$verdict[long$items == "EF5"], "held back: 1, 2, 3")
  expect_match(narrow$titles$lines[[1]][1], "^1\\. ")
  expect_gt(narrow$mar_top, 1.9)
  expect_false(plan_on(ev, 7.5, 5.5)$numbered)
  grDevices::pdf(NULL, width = 5, height = 4)
  drawn <- plot(long)
  grDevices::dev.off()
  expect_identical(drawn, long)
})

test_that("the profile's key lists only what was drawn", {
  key <- function(ev) {
    grDevices::pdf(NULL, width = 7.5, height = 4)
    on.exit(grDevices::dev.off())
    graphics::plot.new()
    paste(contentvalidR:::.evidence_profile_key(ev, 0.72, 8 / 12)$lines,
          collapse = " ")
  }
  # An item no judge sorted has no value, so no symbol, so no cross.
  sorts <- read.csv(extdata("sort_example.csv"), stringsAsFactors = FALSE)
  sorts$assigned_construct[sorts$item == "A1"] <- NA
  fs <- sort_validity(sorts)
  expect_identical(fs$results$recommendation[1], "Insufficient data")
  ev <- content_evidence(Sort = fs)
  expect_false(grepl("Cross", key(ev$evidence), fixed = TRUE))
  expect_match(key(ev$evidence), "Filled: met the criterion.", fixed = TRUE)
  grDevices::pdf(NULL)
  drawn <- plot(ev)
  grDevices::dev.off()
  expect_identical(drawn, ev)

  # Construct ratings have no criterion line, so a filled symbol met the
  # stage's rule, not a criterion.
  rd <- read.csv(extdata("rating_example.csv"), stringsAsFactors = FALSE)
  er <- content_evidence(Ratings = rating_validity(rd))
  expect_true(all(is.na(er$evidence$criterion)))
  k <- key(er$evidence)
  expect_false(grepl("met the criterion", k, fixed = TRUE))
  expect_match(k, "Filled: met the stage's decision rule.", fixed = TRUE)
  expect_false(grepl("Dashed line", k, fixed = TRUE))

  # A stage that described only draws crosses, and says so.
  d <- congruence_data()
  untargeted <- d[setdiff(names(d), "target_objective")]
  ed <- content_evidence(Second = expert_validity(untargeted,
                                                  mode = "congruence"))
  expect_match(key(ed$evidence), "Cross: no decision.", fixed = TRUE)
})

test_that("?content_evidence no longer says every panel shows a criterion", {
  path <- testthat::test_path("..", "..", "man",
                              "plot.contentvalid_evidence.Rd")
  skip_if_not(file.exists(path), "package documentation is not available")
  rd <- gsub("[[:space:]]+", " ", paste(readLines(path, warn = FALSE),
                                        collapse = " "))
  expect_match(rd, "where the stage's rule has one", fixed = TRUE)
  expect_false(grepl("A filled symbol met the criterion", rd, fixed = TRUE))
})

# 11. The construct-rating decision legend.

test_that("the construct-rating legend names the competitor for what it is", {
  review <- contentvalidR:::.decision_meanings("construct-rating")[["Review"]]
  expect_match(review, "the other construct with the highest mean rating",
               fixed = TRUE)
  expect_false(grepl("closest", review, fixed = TRUE))
})

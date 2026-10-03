# The output style shared with nomologR (JUhalt/nomologR#144): headers,
# numbers, tables, sections, flags, closings, errors, plots and APA notes.

shown <- function(x, width = 80, ...) {
  old <- options(width = width)
  on.exit(options(old), add = TRUE)
  utils::capture.output(print(x, ...))
}

sort_fit <- function() {
  sort_validity(utils::read.csv(
    system.file("extdata", "sort_example.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE))
}

relevance <- function() {
  matrix(c(4, 3, 4, 4, 3, 4, 2, 3, 4, 4, 3, 2, 4, 4, 4, 3, 4, 4), 6,
         dimnames = list(NULL, c("I1", "I2", "I3")))
}

test_that("every printout opens with a tag-first header and no rule", {
  fit <- sort_fit()
  out <- shown(fit)
  expect_identical(out[1], "<contentvalid_sort> Item-sort analysis")
  expect_false(grepl("^-+$", out[2]))
  expect_identical(shown(summary(fit))[1],
                   "<contentvalid_sort summary> Item-sort analysis")
  expect_match(shown(compute_psa(utils::read.csv(
    system.file("extdata", "sort_example.csv", package = "contentvalidR"))))[1],
    "^<contentvalid_psa> ")
  expect_match(shown(cvi(relevance() >= 3))[1], "^<contentvalid_cvi> ")
  expect_identical(shown(csv_binom_test(n_c = 15, N = 20))[1],
                   "<contentvalid_binom> Howard-Melloy exact test (one-tailed)")
  sim <- shown(similarity_from_sort(utils::read.csv(
    system.file("extdata", "sort_example.csv", package = "contentvalidR"))))
  expect_identical(sim[1], "<contentvalid_similarity> Item similarity")
  # The diagonal is blank, never a lone dash, and the matrix is indented.
  expect_false(any(grepl(" - ", sim, fixed = TRUE)))
  expect_true(any(grepl("^  Item +A1 +A2", sim)))
  expect_identical(shown(content_report(sort_fit()))[1],
                   "<contentvalid_report> Results table in APA style")
})

test_that("numbers round half up, missing values print --, and p never reads 1.000", {
  fmt <- contentvalidR:::.fmt
  expect_identical(fmt(c(5 / 8, 1 / 8, 3 / 8)), c(".63", ".13", ".38"))
  expect_identical(fmt(c(-0.004, NA)), c(".00", "--"))
  expect_identical(fmt(2.675, bounded = FALSE), "2.68")
  expect_identical(contentvalidR:::.fmt_p(c(0.9996, 0.0004)), c("> .999", "< .001"))
  expect_identical(contentvalidR:::.p_phrase(0.9999), "p > .999")
  expect_identical(contentvalidR:::.fmt_pct(c(1 / 3, NA), base = 9), c("33%", "--"))
  expect_identical(contentvalidR:::.fmt_pct(1 / 3, base = 150), "33.3%")
})

test_that("prose wraps at 79 columns without breaking a statistic", {
  say <- contentvalidR:::.say
  old <- options(width = 30)
  on.exit(options(old), add = TRUE)
  phrases <- c("[.65, .99]", "p < .001", "N = 473", "F(2, 14) = 3.21",
               "alpha = .05", "Phi >= .80", "p <= alpha",
               "chi-square(1, N = 40) = 0.11")
  for (ph in phrases) {
    # Padded so that the phrase straddles the wrap column.
    out <- utils::capture.output(say(paste(strrep("x", max(1, 30 - nchar(ph))),
                                           ph, "end")))
    expect_true(any(grepl(ph, out, fixed = TRUE)), info = ph)
    expect_false(any(grepl(intToUtf8(160), out)), info = ph)
  }
  # A wide console still wraps prose at 79 columns.
  options(width = 120)
  out <- utils::capture.output(say(strrep("word ", 60)))
  expect_lte(max(nchar(out)), 79L)
  expect_gte(max(nchar(out)), 74L)
})

test_that("tables indent, align, use sentence case, and drop empty columns", {
  tab <- data.frame(item = c("A1", "B22"), decision = c("Retain", "Review"),
                    Psa = c(".90", ".65"), p = c("< .001", ".132"),
                    empty = c("--", "--"), stringsAsFactors = FALSE)
  out <- utils::capture.output(contentvalidR:::.print_table(tab))
  expect_identical(out[1], "  Item  Decision  Psa       p")
  expect_identical(out[3], "  B22   Review    .65    .132")
  # A status column stays even when empty; a decisive test column too.
  tab$decision <- "--"
  out <- utils::capture.output(contentvalidR:::.print_table(tab))
  expect_match(out[1], "Decision", fixed = TRUE)
  # Protection does not depend on the case of a heading.
  cased <- data.frame(Item = c("A1", "B2"), Decision = c("--", "--"),
                      `Contrast p` = c("--", "--"), check.names = FALSE)
  out <- utils::capture.output(contentvalidR:::.print_table(cased))
  expect_identical(strsplit(trimws(out[1]), "  +")[[1]],
                   c("Item", "Decision", "Contrast p"))
  # The headings printed are returned, so a key can leave out the rest.
  shown_heads <- NULL
  utils::capture.output(shown_heads <- contentvalidR:::.print_table(tab))
  expect_identical(shown_heads, c("item", "decision", "Psa", "p"))
})

test_that("a table too wide for the console drops trailing columns and says so", {
  old <- options(width = 40)
  on.exit(options(old), add = TRUE)
  tab <- data.frame(item = "A1", decision = "Retain", first = strrep("x", 12),
                    second = strrep("y", 12), third = strrep("z", 12),
                    stringsAsFactors = FALSE)
  out <- utils::capture.output(contentvalidR:::.print_table(tab))
  expect_match(out[1], "Decision", fixed = TRUE)
  expect_match(paste(out, collapse = " "), "Not shown for width:", fixed = TRUE)
  expect_match(paste(out, collapse = " "), "as.data.frame(x)", fixed = TRUE)
})

test_that("sections indent their prose, and the closing returns to the margin", {
  out <- shown(sort_fit())
  i <- which(out == "Item-level evidence")
  expect_match(out[i + 1L], "^  Item ")
  expect_true(any(grepl("^  Judges: assignments", out)))
  last <- out[length(out)]
  expect_match(last, "^See summary\\(x\\)")
  expect_true(any(grepl("^'Review' is not an automatic deletion decision", out)))
})

test_that("summaries list flagged units as bullets with complete sentences", {
  out <- shown(summary(sort_fit()))
  expect_true(any(out == "Flagged"))
  bullets <- out[startsWith(trimws(out), "- ")]
  expect_gte(length(bullets), 1L)
  expect_match(bullets[1], "^  - [A-Z0-9, ]+ \\(Review\\): [A-Z]")
})

test_that("a wrong choice names the argument and the choices", {
  expect_error(content_report(sort_fit(), format = "latex"),
               '`format` must be one of "apa", "data.frame", or "markdown", not "latex".',
               fixed = TRUE)
  expect_error(expert_power(criterion = "x"),
               '`criterion` must be one of "cvi" or "cvr", not "x".', fixed = TRUE)
  # A unique partial match still works, as with match.arg(), and NULL gives
  # the default.
  expect_s3_class(content_report(sort_fit(), format = "mark"), "contentvalid_markdown")
  expect_s3_class(content_report(sort_fit(), format = NULL), "contentvalid_report")
  expect_identical(names(as.data.frame(sort_fit(), component = NULL)),
                   names(as.data.frame(sort_fit())))
  expect_error(contentvalid_glossary("bogus"),
               '`workflow` must be one of "item-sort", ', fixed = TRUE)
  expect_error(contentvalid_glossary("bogus"), 'not "bogus".', fixed = TRUE)
  expect_error(content_handoff(sort_fit(), keep = "Kept"),
               'must be one or more of "Supported", ', fixed = TRUE)
  expect_error(content_handoff(sort_fit(), keep = "Kept"), 'not "Kept".',
               fixed = TRUE)
})

test_that("every plot method takes type", {
  methods <- c("plot.contentvalid_sort", "plot.contentvalid_rating",
               "plot.contentvalid_expert", "plot.contentvalid_delphi",
               "plot.contentvalid_evidence", "plot.contentvalid_sort_power",
               "plot.contentvalid_expert_power", "plot.contentvalid_structure")
  for (m in methods) {
    expect_true("type" %in% names(formals(utils::getFromNamespace(m, "contentvalidR"))),
                info = m)
  }
})

test_that("a manuscript table carries an APA note", {
  tab <- content_report(sort_fit())
  note <- attr(tab, "note")
  expect_match(note, "^Psa = proportion of substantive agreement; CI = confidence interval; Csv = ")
  expect_match(note, "95% CI = Wilson score confidence interval.", fixed = TRUE)
  expect_match(note, "Retain = at least the number of target assignments", fixed = TRUE)
  expect_match(paste(shown(tab), collapse = " "), "Note. Psa =", fixed = TRUE)
  md <- content_report(sort_fit(), format = "markdown")
  expect_match(md[length(md)], "^[*]Note[.][*] Psa = ")
  rel <- content_report(expert_validity(relevance(), lo = 1, hi = 4, agreement = "none"))
  expect_match(attr(rel, "note"),
               "Penfield-Giacobbi score confidence interval for V and Wilson score",
               fixed = TRUE)
})

test_that("flagged bullets group a shared explanation and list Review first", {
  out <- utils::capture.output(contentvalidR:::.say_flagged(
    c("A1", "B2", "C2"), c("Insufficient data", "Review", "Review"),
    c("No judge sorted it", "Too close to call.", "Too close to call.")))
  expect_identical(out, c("- B2, C2 (Review): Too close to call.",
                          "- A1 (Insufficient data): No judge sorted it."))
})

test_that("a value not computed is -- in the console and an em dash in Markdown", {
  s2 <- data.frame(
    item = rep(c("A1", "A2", "A3", "A4"), each = 8), rater = rep(1:8, 4),
    target_construct = "A",
    assigned_construct = c(rep("A", 5), rep("B", 3), rep("A", 5), rep("B", 3),
                           rep("A", 8), rep("A", 4), rep("B", 4)),
    stringsAsFactors = FALSE)
  fit <- sort_validity(s2)
  tab <- content_report(fit)
  expect_identical(tab$competitor[tab$item == "A3"], "--")
  expect_match(attr(tab, "note"), "-- = not computed.", fixed = TRUE)
  expect_false(grepl("printout", attr(tab, "note"), fixed = TRUE))
  md <- content_report(fit, format = "markdown")
  expect_match(md[grepl("^[|] A3 ", md)], "| \u2014 |", fixed = TRUE)
  expect_match(md[length(md)], "\u2014 = not computed.", fixed = TRUE)
  # 5 of 8 is an exact tie: both formats round it half up.
  expect_identical(tab$Psa[tab$item == "A1"], ".63")
  expect_equal(content_report(fit, format = "data.frame")$psa[1], 0.63)
})

test_that("a share prints the same in the table and in the sentence", {
  d <- data.frame(item = paste0("I", 1:8),
                  cell = c(rep("A", 3), rep("B", 4), "C"))
  fit <- domain_validity(d, cell_col = "cell", min_items = 1,
                         targets = c(A = 3, B = 2, C = 3))
  expect_true(any(grepl("^  C +Under-represented +1 +13% +38%$", shown(fit))))
  sm <- paste(shown(summary(fit)), collapse = " ")
  expect_match(sm, "This cell holds 13% of the items", fixed = TRUE)
  pa <- panel_agreement(rbind(c(4, 4, 3, 2, 4), c(4, 3, 3, 2, 4),
                              c(3, 4, 4, 1, 4), c(4, 4, 3, 2, 3)), B = 0)
  # 15 of 30 pairs: a whole number on a base under 100.
  expect_identical(pa$n_pairs, 30)
  expect_true(any(shown(pa) == "Identical rating pairs: 50%"))
})

test_that("the Delphi summary lists its flagged items as bullets", {
  long <- function(m, round) {
    data.frame(expert = paste0("E", seq_len(nrow(m))),
               item = rep(colnames(m), each = nrow(m)), round = round,
               rating = as.vector(m), stringsAsFactors = FALSE)
  }
  r1 <- cbind(S1 = c(4, 4, 3, 4, 3, 4, 4, 4), S2 = c(3, 4, 3, 2, 4, 3, 1, 2))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 4, 4), S2 = c(4, 4, 2, 1, 4, 3, 1, 2))
  fit <- delphi_validity(rbind(long(r1, 1), long(r2, 2)), lo = 1, hi = 4,
                         consensus_threshold = .75, B = 0,
                         stability = "chisq_group")
  out <- shown(summary(fit))
  expect_true(any(out == "Flagged"))
  expect_true(any(grepl("^  - S2 \\(No consensus\\): [A-Z]", out)))
})

test_that("the handoff closes at the margin, one blank line before the pointer", {
  h <- content_handoff(sort_fit(), reverse_keyed = character(0),
                       response_scale = c(1, 5))
  out <- shown(h)
  expect_true(any(out == "Held back"))
  expect_true(any(out == "    nomo_screen(data, items = handoff)"))
  expect_true(any(grepl("^Carry these items", out)))
  i <- grep("^Surviving content review", out)
  expect_length(i, 1L)
  expect_identical(out[i - 1L], "")
  p <- grep("^See as.data.frame\\(x\\)", out)
  expect_identical(out[p - 1L], "")
  expect_false(identical(out[p - 2L], ""))
})

test_that("the APA note names the interval and adjustment used, and each source once", {
  rel <- content_report(expert_validity(relevance(), lo = 1, hi = 4,
                                        agreement = "none",
                                        proportion_ci = "none"))
  expect_match(attr(rel, "note"),
               "95% CI = Penfield-Giacobbi score confidence interval for V.",
               fixed = TRUE)
  rat <- utils::read.csv(system.file("extdata", "rating_example.csv",
                                     package = "contentvalidR"))
  holm <- content_report(rating_validity(rat, scale_min = 1, scale_max = 5,
                                         adjust = "holm"))
  expect_match(attr(holm, "note"), "every one-sided Holm-adjusted contrast p",
               fixed = TRUE)
  d <- expand.grid(item = c("I1", "I2"), judge = 1:4, objective = c("A", "B"))
  d$target_objective <- ifelse(d$item == "I1", "A", "B")
  d$score <- ifelse(d$objective == d$target_objective, 1, -1)
  con <- attr(content_report(expert_validity(d, mode = "congruence")), "note")
  expect_match(con, "the criterion Rovinelli and Hambleton (1977) applied.",
               fixed = TRUE)
  expect_false(grepl("Rovinelli & Hambleton", con, fixed = TRUE))
})

test_that("a narrow console keeps each table's decision and points to the right place", {
  fit <- sort_fit()
  out <- shown(fit, width = 60)
  expect_true(any(grepl("^  Item +Target +Decision", out)))
  # A key entry is left out for a column the table did not show.
  if (any(grepl("Not shown for width: .*Competitor", out))) {
    expect_false(any(grepl("^  Competitor -- ", out)))
  }
  sm <- shown(summary(fit), width = 60)
  expect_false(any(grepl("as.data.frame(x)", sm, fixed = TRUE)))
  expect_true(any(grepl("x$scale_summary", sm, fixed = TRUE)))
  # A component never drops the statistic it exists to show.
  htd_out <- shown(htd(data.frame(
    item = rep("I1", 9), rater = rep(1:3, each = 3),
    construct = rep(c("A", "B", "C"), 3), rating = c(5, 2, 1, 4, 2, 2, 5, 1, 1)),
    target_map = c(I1 = "A"), scale_min = 1, scale_max = 5), width = 60)
  expect_true(any(grepl("HTD$", htd_out)))
})

test_that("keys and glossary entries wrap with the console", {
  out <- shown(contentvalid_glossary("item-sort"), width = 60)
  expect_lte(max(nchar(out)), 60L)
  expect_true(any(out == "Status labels"))
  expect_false(any(grepl(":$", out)))
  key <- shown(sort_fit(), width = 60)
  expect_lte(max(nchar(key)), 60L)
})

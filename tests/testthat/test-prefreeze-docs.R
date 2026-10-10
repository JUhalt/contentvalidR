# Three statements in the help pages that the 1.0 release candidate freezes:
# when a deprecated function may be removed (?contentvalidR), which values a
# handoff records for its workflow and mode (?content_handoff), and which
# columns hold an interval's bounds (?"contentvalid-data-frames"). Each is a
# claim about the package, so each is checked against the package: the help
# pages are parsed, and what they name is looked up in real results.

# One parsed help page: from the source tree when there is one, and from the
# installed package otherwise, as under R CMD check.
pf_page <- function(topic) {
  file <- paste0(topic, ".Rd")
  path <- testthat::test_path("..", "..", "man", file)
  if (file.exists(path)) return(tools::parse_Rd(path, encoding = "UTF-8"))
  db <- tryCatch(tools::Rd_db("contentvalidR"), error = function(e) NULL)
  at <- match(file, basename(names(db)))
  if (is.na(at)) skip("package documentation is not available")
  db[[at]]
}

pf_tag <- function(x) {
  tag <- attr(x, "Rd_tag")
  if (is.null(tag)) "" else tag
}

# An Rd element as text. A \code span is set in backticks, so that a name
# the page gives as code can be told from the same word in a sentence, and
# the cells and rows of a table are marked.
pf_text <- function(x) {
  tag <- pf_tag(x)
  if (tag == "\\tab") return("<tab>")
  if (tag == "\\cr") return("<cr>")
  if (is.character(x)) return(paste(x, collapse = ""))
  inner <- paste(vapply(x, pf_text, ""), collapse = "")
  if (tag == "\\code") paste0("`", inner, "`") else inner
}

pf_squish <- function(x) trimws(gsub("[[:space:]]+", " ", x))

# The body of the section with this title.
pf_section <- function(rd, title) {
  for (s in rd[vapply(rd, pf_tag, "") == "\\section"]) {
    if (identical(pf_squish(pf_text(s[[1]])), title)) return(s[[2]])
  }
  stop("No section titled '", title, "'.")
}

# Every item of every bulleted or numbered list inside an Rd element.
pf_items <- function(x) {
  out <- character(0)
  walk <- function(e) {
    if (!is.list(e)) return(invisible())
    if (pf_tag(e) %in% c("\\itemize", "\\enumerate")) {
      starts <- vapply(e, pf_tag, "") == "\\item"
      item <- cumsum(starts)
      for (i in seq_len(max(c(0L, item)))) {
        out <<- c(out, pf_squish(pf_text(e[item == i & !starts])))
      }
    }
    for (k in e) walk(k)
  }
  walk(x)
  out
}

# The first table inside an Rd element, one row per row and one column per
# column, header included.
pf_table <- function(x) {
  found <- NULL
  walk <- function(e) {
    if (!is.null(found) || !is.list(e)) return(invisible())
    if (pf_tag(e) == "\\tabular") {
      found <<- e
      return(invisible())
    }
    for (k in e) walk(k)
  }
  walk(x)
  if (is.null(found)) stop("No table found.")
  rows <- strsplit(pf_text(found[[2]]), "<cr>", fixed = TRUE)[[1]]
  rows <- rows[nzchar(pf_squish(rows))]
  cells <- lapply(strsplit(rows, "<tab>", fixed = TRUE), pf_squish)
  do.call(rbind, cells)
}

# What a piece of flattened text gives as code: `psa_low`, `"delphi"`.
pf_code <- function(text) {
  spans <- regmatches(text, gregexpr("`[^`]+`", text))[[1]]
  gsub("`", "", spans, fixed = TRUE)
}

pf_ext <- function(file) {
  utils::read.csv(system.file("extdata", file, package = "contentvalidR"),
                  stringsAsFactors = FALSE)
}

# A fit from every workflow, on the package's own example data. The Delphi
# data are the first two rounds of the example in ?delphi_validity; the
# judge and coverage data are the ones test-closeout-docs.R uses.
pf_fits <- local({
  cache <- NULL
  function() {
    if (!is.null(cache)) return(cache)
    panel <- as.matrix(pf_ext("expert_relevance_example.csv")[-1])
    essential <- as.matrix(pf_ext("expert_essentiality_example.csv")[-1])
    congruence <- pf_ext("expert_congruence_example.csv")
    long <- function(m, round) {
      data.frame(expert = paste0("E", seq_len(nrow(m))),
                 item = rep(colnames(m), each = nrow(m)),
                 round = round, rating = as.vector(m))
    }
    r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4, 3, 4), S2 = c(2, 3, 2, 1, 3, 2, 2, 3),
                S3 = c(3, 4, 2, 3, 4, 1, 3, 2), S4 = c(4, 3, 4, 2, 3, 3, 4, 2))
    r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2, 2, 2),
                S3 = c(3, 3, 3, 3, 4, 2, 3, 3), S4 = c(4, 3, 4, 3, 3, 3, 4, 3))
    judges <- rbind(c(4, 4, 3, 2), c(4, 3, 4, 1), c(3, 4, 4, 2), c(2, 2, 2, 1))
    cells <- data.frame(item = paste0("I", 1:4), cell = c("A", "A", "B", "C"))
    cache <<- list(
      sort = sort_validity(pf_ext("sort_example.csv")),
      rating = rating_validity(pf_ext("rating_example.csv")),
      relevance = expert_validity(panel, mode = "relevance", lo = 1, hi = 4,
                                  agreement_B = 200, seed = 1),
      essentiality = expert_validity(essential, mode = "essentiality"),
      congruence = expert_validity(congruence, mode = "congruence"),
      untargeted = expert_validity(
        congruence[setdiff(names(congruence), "target_objective")],
        mode = "congruence"
      ),
      delphi = delphi_validity(rbind(long(r1, 1), long(r2, 2)), lo = 1,
                               hi = 4, consensus_threshold = 0.75, B = 200,
                               seed = 1),
      judge = judge_validity(judges, lo = 1, hi = 4),
      domain = domain_validity(cells, cell_col = "cell")
    )
    cache
  }
})

# The workflows whose rows are items, which are the ones that hand off.
pf_hands_off <- c("sort", "rating", "relevance", "essentiality", "congruence",
                  "untargeted", "delphi")

test_that("the policy states when a function is removed, once", {
  rd <- pf_page("contentvalidR-package")
  steps <- pf_items(pf_section(rd, "How something is deprecated"))
  removal <- steps[startsWith(steps, "Removal follows")]
  expect_length(removal, 1L)

  # From 1.0 the wait for a major release covers Tiers 1 and 2, and the same
  # step says that Tier 3 is the exception.
  expect_match(removal, paste("From 1.0 onward a Tier 1 or Tier 2 function,",
                              "argument, or returned field is removed only",
                              "in a major release."), fixed = TRUE)
  expect_match(removal, paste("A Tier 3 helper is the exception: it may be",
                              "removed in a minor release, after its one",
                              "minor release of warning."), fixed = TRUE)

  # Nowhere else does the page give a rule for removal, so nothing can
  # contradict that step. It once had two: the Tier 3 paragraph allowed a
  # minor release while the step, unqualified, required a major one.
  policy <- pf_squish(pf_text(rd))
  count <- function(phrase) {
    lengths(regmatches(policy, gregexpr(phrase, policy, fixed = TRUE)))
  }
  expect_identical(count("only in a major release"), 1L)
  expect_identical(count("only in a major release from 1.0 onward"), 0L)
  expect_identical(count("removed in a minor release"), 2L)

  # The Tier 3 paragraph points to the step and gives no rule of its own.
  tiers <- pf_squish(pf_text(pf_section(rd, "What you can rely on")))
  expect_match(tiers, paste("they are the one exception in the deprecation",
                            "cycle below: after its warning, a Tier 3 helper",
                            "may be removed in a minor release (step 3)."),
               fixed = TRUE)
  expect_false(grepl("removed with one minor release of warning", tiers,
                     fixed = TRUE))

  # The exception is about something: the page files functions in Tier 3,
  # and each of them is exported.
  at <- regexpr("Tier 3, auxiliary and compatibility helpers[.][^.]*[.]", tiers)
  tier3 <- sub("[(][)]$", "", pf_code(regmatches(tiers, at)))
  expect_gt(length(tier3), 0L)
  expect_true(all(tier3 %in% getNamespaceExports("contentvalidR")))
})

test_that("the handoff page lists the workflow and mode values, and no other", {
  fits <- pf_fits()

  # Every workflow that can hand off is here, in every mode it has.
  accepted <- c("contentvalid_sort", "contentvalid_rating",
                "contentvalid_expert", "contentvalid_delphi")
  expect_setequal(vapply(fits[pf_hands_off], function(f) class(f)[1], ""),
                  accepted)
  expect_setequal(
    unlist(lapply(fits[pf_hands_off], `[[`, "mode"), use.names = FALSE),
    eval(formals(expert_validity)$mode)
  )
  for (other in setdiff(names(fits), pf_hands_off)) {
    expect_error(content_handoff(fits[[other]]), "carry no item set",
                 info = other)
  }

  provenance <- lapply(fits[pf_hands_off],
                       function(f) content_handoff(f)$provenance)
  workflow <- unname(vapply(provenance, `[[`, "", "workflow"))
  mode <- unname(vapply(provenance, `[[`, "", "mode"))
  expect_identical(
    workflow,
    c("item-sort", "construct-rating", "expert-panel", "expert-panel",
      "expert-panel", "expert-panel", "delphi")
  )
  expect_identical(
    mode,
    c(NA, NA, "relevance", "essentiality", "congruence", "congruence", NA)
  )

  # The page gives each value quoted, in one list item for each field.
  frozen <- pf_section(pf_page("content_handoff"), "What version 1 freezes")
  items <- pf_items(frozen)
  quoted <- function(field) {
    item <- items[startsWith(items, paste0("`", field, "` is "))]
    expect_length(item, 1L)
    code <- pf_code(item)
    gsub("\"", "", code[grepl("^\".*\"$", code)], fixed = TRUE)
  }
  expect_setequal(quoted("workflow"), workflow)
  expect_setequal(quoted("mode"), mode[!is.na(mode)])
  mode_item <- items[startsWith(items, "`mode` is ")]
  expect_identical("NA" %in% pf_code(mode_item), anyNA(mode))

  # Frozen for schema version 1: a value may be added, and none is renamed.
  text <- pf_squish(pf_text(frozen))
  expect_match(text, paste("The values of two `provenance` fields are frozen",
                           "as well"), fixed = TRUE)
  expect_match(text, "A new workflow or mode would add a value to these.",
               fixed = TRUE)
  expect_match(text, "None of the values listed is renamed within version 1.",
               fixed = TRUE)
  # The reader told not to match on `statistic` is told what to match on.
  expect_match(text, paste("match on `workflow` and `mode` in `provenance`",
                           "instead, whose values are listed above"),
               fixed = TRUE)
})

test_that("every interval column the data-frame page names is in its result", {
  fits <- pf_fits()
  sorts <- pf_ext("sort_example.csv")
  panel <- as.matrix(pf_ext("expert_relevance_example.csv")[-1])
  handoff <- content_handoff(fits$relevance)
  evidence <- content_evidence(Sort = fits$sort)
  agreement <- panel_agreement(panel, B = 200, seed = 1)
  binom <- csv_binom_test(16, 20)
  index <- cvi(panel >= 3)
  psa <- compute_psa(sorts)
  aiken <- aikens_v(panel, lo = 1, hi = 4)

  # The result each row of the table is about, by its first two cells.
  results <- list(
    "`sort_validity()` | `results`" = fits$sort$results,
    "`compute_psa()` | its data frame" = psa,
    "`expert_validity()` | `results` (Aiken's V)" = fits$relevance$results,
    "`aikens_v()` | its data frame" = aiken,
    "`panel_agreement()` | `as.data.frame(x)`" = as.data.frame(agreement),
    "`csv_binom_test()` | `as.data.frame(x)`" = as.data.frame(binom),
    "`expert_validity()` | `results` (I-CVI)" = fits$relevance$results,
    "`cvi()` | `item_level`" = index$item_level,
    "`expert_validity()` | `scale_summary`" = fits$relevance$scale_summary,
    "`delphi_validity()` | `results`" = fits$delphi$results,
    "`delphi_validity()` | `details$stability`" = fits$delphi$details$stability,
    "`content_handoff()` | `item_statistics`" = handoff$item_statistics,
    "`content_handoff()` | `panel_statistics`" = handoff$panel_statistics,
    "`content_evidence()` | `evidence`" = evidence$evidence
  )

  section <- pf_section(pf_page("contentvalid-data-frames"),
                        "Interval columns")
  rows <- pf_table(section)
  expect_identical(rows[1, ], c("Result", "Where", "Lower, upper"))
  rows <- rows[-1, , drop = FALSE]
  about <- paste(rows[, 1], rows[, 2], sep = " | ")
  expect_setequal(about, names(results))

  # Each row names two numeric columns of its result, the lower bound first.
  bounds <- lapply(rows[, 3], pf_code)
  for (i in seq_along(about)) {
    d <- results[[about[i]]]
    expect_length(bounds[[i]], 2L)
    expect_true(all(bounds[[i]] %in% names(d)),
                info = paste(about[i], "lacks",
                             paste(setdiff(bounds[[i]], names(d)),
                                   collapse = ", ")))
    numeric <- vapply(d[intersect(bounds[[i]], names(d))], is.numeric, NA)
    expect_true(all(numeric), info = about[i])
    low <- d[[bounds[[i]][1]]]
    high <- d[[bounds[[i]][2]]]
    both <- is.finite(low) & is.finite(high)
    expect_true(all(low[both] <= high[both]), info = about[i])
  }
  # Every family of names holds an interval that was computed somewhere.
  computed <- vapply(seq_along(about), function(i) {
    any(is.finite(results[[about[i]]][[bounds[[i]][1]]]))
  }, NA)
  expect_true(all(tapply(computed, rows[, 3], any)))

  # No bound goes unnamed: a column that looks like one is in the table, in
  # a row for the function that returned it.
  bound_like <- "(_low|_high)$|^(lower|upper)$"
  for (i in seq_along(about)) {
    have <- grep(bound_like, names(results[[about[i]]]), value = TRUE)
    named <- unlist(bounds[rows[, 1] == rows[i, 1]])
    expect_identical(setdiff(have, named), character(0), info = about[i])
  }
  # The results the table leaves out carry no interval.
  left_out <- c(
    lapply(fits[c("rating", "essentiality", "congruence", "untargeted",
                  "judge", "domain")], `[[`, "results"),
    lapply(fits[c("sort", "rating", "essentiality", "congruence", "delphi",
                  "judge", "domain")], `[[`, "scale_summary")
  )
  for (d in left_out) expect_length(grep(bound_like, names(d)), 0L)
  # The two lists the page mentions beside the table.
  expect_true(all(c("ci_low", "ci_high") %in% names(agreement)))
  expect_length(binom$conf.int, 2L)

  # Where the page says the level and the method are recorded, they are.
  alpha_of <- function(fit) fit$settings$alpha
  recorded <- c(
    "1 - settings$alpha" = all(vapply(fits[c("sort", "relevance", "delphi")],
                                      function(f) is.numeric(alpha_of(f)), NA)),
    "settings$proportion_ci" = is.character(fits$sort$settings$proportion_ci) &&
      is.character(fits$relevance$settings$proportion_ci),
    "ci_method" = "ci_method" %in% names(fits$relevance$results) &&
      "ci_method" %in% names(aiken),
    "settings$agreement_B" = is.numeric(fits$relevance$settings$agreement_B),
    "settings$B" = is.numeric(fits$delphi$settings$B),
    "alpha" = is.numeric(index$alpha) && is.numeric(agreement$alpha) &&
      all(c("alpha", "ci") %in% names(formals(compute_psa))) &&
      all(c("alpha", "ci") %in% names(formals(aikens_v))),
    "ci" = is.character(index$ci),
    "ci_alpha" = "ci_alpha" %in% names(as.data.frame(agreement)),
    "ci_level" = "ci_level" %in% names(as.data.frame(binom)),
    "ci_sides" = "ci_sides" %in% names(as.data.frame(binom)),
    "interval_level" = "interval_level" %in% names(handoff$item_statistics) &&
      "interval_level" %in% names(handoff$panel_statistics),
    "interval_method" = "interval_method" %in% names(handoff$item_statistics) &&
      "interval_method" %in% names(handoff$panel_statistics),
    "level" = "level" %in% names(evidence$evidence),
    "stages" = "stages" %in% names(evidence),
    "conf.int" = "conf.int" %in% names(binom)
  )
  expect_identical(names(recorded)[!recorded], character(0))
  said <- pf_code(pf_squish(pf_text(section)))
  expect_identical(setdiff(names(recorded), said), character(0))

  # And they say what the page says they say. A workflow's level is
  # 1 - settings$alpha: at alpha = .10 the Psa bounds are the 90% Wilson
  # score interval, which prop.test() gives without its continuity correction.
  wide <- sort_validity(sorts, alpha = 0.10)
  expect_identical(wide$settings$proportion_ci, "wilson")
  first <- wide$results[1, ]
  wilson <- stats::prop.test(first$n_target, first$n, correct = FALSE,
                             conf.level = 1 - wide$settings$alpha)$conf.int
  expect_equal(c(first$psa_low, first$psa_high), as.numeric(wilson),
               tolerance = 1e-8)
  # The handoff and the evidence table carry that level, and the data frame
  # of a test carries its own.
  level <- 1 - fits$relevance$settings$alpha
  stats <- handoff$item_statistics
  expect_equal(unique(stats$interval_level[!is.na(stats$lower)]), level)
  expect_equal(handoff$panel_statistics$interval_level, level)
  expect_identical(as.data.frame(agreement)$ci_alpha, agreement$alpha)
  expect_equal(as.data.frame(binom)$ci_level, 1 - binom$alpha)
  expect_identical(as.data.frame(binom)$ci_sides, "one-sided")
  shown <- evidence$evidence
  expect_equal(unique(shown$level[!is.na(shown$lower)]),
               1 - fits$sort$settings$alpha)
  methods <- evidence$stages$Sort$item_statistics$interval_method
  expect_true("Wilson score" %in% methods)
})

test_that("the reading-output vignette carries the same interval table", {
  path <- testthat::test_path("..", "..", "vignettes", "reading-output.Rmd")
  if (!file.exists(path)) skip("package sources are not available")
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  start <- grep("^## Finding the interval bounds$", lines)
  expect_length(start, 1L)
  after <- lines[seq.int(start + 1L, length(lines))]
  part <- after[seq_len(grep("^## ", after)[1] - 1L)]
  table <- part[grepl("^[|]", part) & !grepl("^[|]-", part)]
  cells <- lapply(strsplit(sub("^[|]", "", table), "|", fixed = TRUE),
                  pf_squish)
  expect_true(all(lengths(cells) == 3L))

  help <- pf_table(pf_section(pf_page("contentvalid-data-frames"),
                              "Interval columns"))
  expect_identical(do.call(rbind, cells), help)
})

# Help pages corrected in the review before 1.0.1. Each page is checked
# against the package: what a \value section names is looked up in a real
# result, so the page cannot drift from the object again.

# One parsed help page: from the source tree when there is one, and from the
# installed package otherwise, as under R CMD check.
rv1_page <- function(topic) {
  file <- paste0(topic, ".Rd")
  path <- testthat::test_path("..", "..", "man", file)
  if (file.exists(path)) return(tools::parse_Rd(path, encoding = "UTF-8"))
  db <- tryCatch(tools::Rd_db("contentvalidR"), error = function(e) NULL)
  if (!length(db)) skip("package documentation is not available")
  at <- match(file, basename(names(db)))
  if (is.na(at)) skip("package documentation is not available")
  db[[at]]
}

rv1_tag <- function(x) {
  tag <- attr(x, "Rd_tag")
  if (is.null(tag)) "" else tag
}

# An Rd element as text, with each \code span set in backticks so that a
# name the page gives as code can be told from the same word in a sentence.
rv1_text <- function(x) {
  tag <- rv1_tag(x)
  if (is.character(x)) return(paste(x, collapse = ""))
  inner <- paste(vapply(x, rv1_text, ""), collapse = "")
  if (tag == "\\code") paste0("`", inner, "`") else inner
}

rv1_squish <- function(x) trimws(gsub("[[:space:]]+", " ", x))

# The text of the page's \value section, or of a section with this title.
rv1_value <- function(rd) {
  val <- rd[vapply(rd, rv1_tag, "") == "\\value"]
  if (!length(val)) stop("The page has no \\value section.")
  rv1_squish(rv1_text(val[[1]]))
}

rv1_section <- function(rd, title) {
  for (s in rd[vapply(rd, rv1_tag, "") == "\\section"]) {
    if (identical(rv1_squish(rv1_text(s[[1]])), title)) {
      return(rv1_squish(rv1_text(s[[2]])))
    }
  }
  stop("No section titled '", title, "'.")
}

# The labels of every \describe item in the \value section, split where one
# item names several fields, as in "`n_retain`, `n_review`".
rv1_value_labels <- function(rd) {
  val <- rd[vapply(rd, rv1_tag, "") == "\\value"][[1]]
  out <- character(0)
  walk <- function(e) {
    if (!is.list(e)) return(invisible())
    if (rv1_tag(e) == "\\describe") {
      for (it in e[vapply(e, rv1_tag, "") == "\\item"]) {
        label <- gsub("`", "", rv1_squish(rv1_text(it[[1]])))
        out <<- c(out, trimws(strsplit(label, ",")[[1]]))
      }
    }
    for (k in e) walk(k)
  }
  walk(val)
  out
}

# The description of one \describe item in the \value section.
rv1_value_item <- function(rd, label) {
  val <- rd[vapply(rd, rv1_tag, "") == "\\value"][[1]]
  found <- NULL
  walk <- function(e) {
    if (!is.list(e) || !is.null(found)) return(invisible())
    if (rv1_tag(e) == "\\describe") {
      for (it in e[vapply(e, rv1_tag, "") == "\\item"]) {
        here <- gsub("`", "", rv1_squish(rv1_text(it[[1]])))
        if (identical(here, label)) found <<- rv1_squish(rv1_text(it[[2]]))
      }
    }
    for (k in e) walk(k)
  }
  walk(val)
  if (is.null(found)) stop("No \\value item labeled '", label, "'.")
  found
}

rv1_sorts <- function(flip = 0L) {
  assigned <- c(rep("A", 11), "B", rep("A", 10), "B", "B",
                rep("B", 5), rep("A", 7))
  if (flip) assigned[seq_len(flip)] <- "B"
  data.frame(
    item = rep(paste0("Item", 1:3), each = 12),
    rater = rep(1:12, 3),
    target_construct = rep(c("A", "A", "B"), each = 12),
    assigned_construct = assigned,
    stringsAsFactors = FALSE
  )
}

rv1_ratings <- function() {
  set.seed(12)
  d <- expand.grid(item = c("A1", "A2", "B1"), rater = 1:20,
                   construct = c("A", "B", "C"))
  d$target_construct <- ifelse(d$item == "B1", "B", "A")
  d$rating <- ifelse(d$construct == d$target_construct,
                     pmin(5, pmax(1, round(stats::rnorm(nrow(d), 4.5, .6)))),
                     pmin(5, pmax(1, round(stats::rnorm(nrow(d), 2.0, .7)))))
  d
}

# HELP-3 --------------------------------------------------------------------

test_that("the methods page points down to the summary() section", {
  rd <- rv1_page("contentvalid-methods")
  value <- rv1_value(rd)
  # R renders \value before the custom sections, so summary() is below.
  expect_match(value, 'named under "summary()" below', fixed = TRUE)
  expect_false(grepl('named under "summary()" above', value, fixed = TRUE))
})

# HELP-4 --------------------------------------------------------------------

test_that("the glossary gives share on the scale results store it on", {
  g <- contentvalid_glossary("domain-coverage")
  row <- g[g$term == "share", ]
  expect_identical(nrow(row), 1L)
  expect_identical(row$definition,
                   "Proportion of all items that fall in this blueprint cell.")
  expect_identical(row$range, "0 to 1; printed as 0% to 100%")

  # The printout wraps each range in parentheses, so the range must not carry
  # its own: the printed line reads as one definition and one range.
  # Whitespace is collapsed so the check does not depend on where it wraps.
  printed <- gsub("\\s+", " ",
                  paste(utils::capture.output(print(g)), collapse = " "))
  expect_match(printed,
               paste("share -- Share of items. Proportion of all items that",
                     "fall in this blueprint cell. (0 to 1; printed as 0% to",
                     "100%)"),
               fixed = TRUE)
  expect_false(grepl("((", printed, fixed = TRUE))

  # The stored column is the proportion the glossary now describes.
  fit <- domain_validity(
    data.frame(item = paste0("I", 1:7),
               construct = c(rep("Autonomy", 4), "Competence", "Competence",
                             "Relatedness")),
    cell_col = "construct",
    domain = c("Autonomy", "Competence", "Relatedness", "Belonging")
  )
  expect_true(all(fit$results$share >= 0 & fit$results$share <= 1))
  expect_equal(sum(fit$results$share), 1)

  # The key printed under results still reads as a percentage, as printed.
  expect_identical(contentvalidR:::.term_short()[["share"]],
                   "Percentage of all items in this cell.")
})

# HELP-5 --------------------------------------------------------------------

test_that("compare_rounds() documents every component it returns", {
  x <- compare_rounds(sort_validity(rv1_sorts()), sort_validity(rv1_sorts(2L)))
  labels <- rv1_value_labels(rv1_page("compare_rounds"))
  expect_setequal(labels, names(x))
  expect_true(all(c("labels", "id_col", "workflow", "n_rounds") %in% labels))

  # What the page says the new components hold is what they hold.
  expect_identical(x$labels, c("Round 1", "Round 2"))
  expect_identical(x$id_col, "item")
  expect_identical(x$workflow, "item-sort")
  expect_identical(x$n_rounds, 2L)
  expect_true(all(x$labels %in% names(x$transitions)))
})

# HELP-6 --------------------------------------------------------------------

test_that("content_evidence() names every element of each stage's flow", {
  relevance <- matrix(c(4, 4, 4, 3, 4, 4, 3, 4, 3, 4, 4, 4, 2, 2, 1, 2),
                      nrow = 4,
                      dimnames = list(NULL, paste0("Item", 1:4)))
  panel <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
                           agreement = "none")
  ev <- content_evidence(`Relevance panel` = panel,
                         `Item sort` = sort_validity(rv1_sorts()))
  flow <- rv1_value_item(rv1_page("content_evidence"), "flow")
  for (name in names(ev$flow[[1]])) {
    expect_match(flow, paste0("`", name, "`"), fixed = TRUE, info = name)
  }
  # Every stage holds the same elements, and the first adds nothing.
  expect_identical(names(ev$flow[[1]]), names(ev$flow[[2]]))
  expect_length(ev$flow[[1]]$added, 0L)
  expect_identical(ev$flow[[1]]$workflow, "expert-panel")
})

# HELP-7 --------------------------------------------------------------------

test_that("sort_power() names its table, the table's columns and its settings", {
  sp <- sort_power(N = c(10, 20), true_p = c(.6, .8))
  rd <- rv1_page("sort_power")
  expect_setequal(rv1_value_labels(rd), names(sp))
  table <- rv1_value_item(rd, "table")
  for (col in names(sp$table)) {
    expect_match(table, paste0("`", col, "`"), fixed = TRUE, info = col)
  }
  expect_identical(nrow(sp$table), 4L)
  settings <- rv1_value_item(rd, "settings")
  for (name in names(sp$settings)) {
    expect_match(settings, paste0("`", name, "`"), fixed = TRUE, info = name)
  }
})

test_that("content_structure() documents hclust with its other components", {
  items <- paste0("I", 1:9)
  blueprint <- rep(c("Autonomy", "Competence", "Relatedness"), each = 3)
  sim <- matrix(c(
    5, 4, 3, 2, 2, 1, 1, 2, 1,
    4, 5, 4, 3, 1, 2, 2, 1, 1,
    3, 4, 5, 1, 2, 2, 1, 1, 3,
    2, 3, 1, 5, 4, 3, 2, 2, 1,
    2, 1, 2, 4, 5, 4, 1, 3, 2,
    1, 2, 2, 3, 4, 5, 2, 1, 2,
    1, 2, 1, 2, 1, 2, 5, 3, 4,
    2, 1, 1, 2, 3, 1, 3, 5, 4,
    1, 1, 3, 1, 2, 2, 4, 4, 5
  ), 9, 9, dimnames = list(items, items))
  fit <- content_structure(sim, membership = blueprint)
  value <- rv1_value(rv1_page("content_structure"))
  for (name in names(fit)) {
    expect_match(value, paste0("`", name, "`"), fixed = TRUE, info = name)
  }
  expect_s3_class(fit$hclust, "hclust")
  expect_match(value, "`hclust`, the `stats::hclust()` fit behind `clusters`",
               fixed = TRUE)
})

# F3 ------------------------------------------------------------------------

test_that("both workflow pages list every scale_summary column", {
  sort_fit <- sort_validity(rv1_sorts())
  rating_fit <- rating_validity(rv1_ratings(), scale_min = 1, scale_max = 5)
  expect_setequal(
    intersect(rv1_value_labels(rv1_page("sort_validity")),
              names(sort_fit$scale_summary)),
    names(sort_fit$scale_summary)
  )
  expect_setequal(
    intersect(rv1_value_labels(rv1_page("rating_validity")),
              names(rating_fit$scale_summary)),
    names(rating_fit$scale_summary)
  )
})

test_that("each page says which form of benchmark_set its workflow stores", {
  sort_doc <- rv1_value_item(rv1_page("sort_validity"), "benchmark_set")
  rating_doc <- rv1_value_item(rv1_page("rating_validity"), "benchmark_set")
  norms <- c(overall = NA, weaker = .20, moderate = .40, stronger = .60)

  for (code in names(norms)) {
    r <- if (is.na(norms[[code]])) NULL else norms[[code]]
    # Both data sets have targets A and B, so a correlation is keyed by them.
    keyed <- if (is.null(r)) NULL else c(A = r, B = r)
    sort_fit <- sort_validity(rv1_sorts(), orbiting_r = keyed)
    rating_fit <- rating_validity(rv1_ratings(), scale_min = 1,
                                  scale_max = 5, orbiting_r = keyed)
    label <- colquitt_benchmarks("psa", orbiting_r = r)$benchmark_label[1]
    # The values are documented as they are stored, not as they might be:
    # the sort stores the label and the rating workflow the code.
    expect_identical(unique(sort_fit$scale_summary$benchmark_set), label)
    expect_identical(unique(rating_fit$scale_summary$benchmark_set), code)
    expect_match(sort_doc, paste0('`"', label, '"`'), fixed = TRUE,
                 info = code)
    expect_match(rating_doc, paste0('`"', code, '"`'), fixed = TRUE,
                 info = code)
    # Each page names the other workflow's form as well, so a reader of
    # either page alone can match every code to its label.
    expect_match(sort_doc, paste0('`"', code, '"`'), fixed = TRUE,
                 info = code)
    expect_match(rating_doc, paste0('`"', label, '"`'), fixed = TRUE,
                 info = code)
    # The rating printout shows the label the page pairs with the code.
    expect_match(
      rv1_squish(paste(utils::capture.output(print(rating_fit)),
                       collapse = " ")),
      paste("Benchmark set:", label), fixed = TRUE, info = code
    )
  }
  for (doc in list(sort_doc, rating_doc)) {
    expect_match(doc, "`colquitt_benchmarks()`", fixed = TRUE)
    expect_match(doc, "`interpret_colquitt()`", fixed = TRUE)
    expect_match(doc, "`benchmark_label`", fixed = TRUE)
  }
  # The helpers the pages point to do return both forms.
  ic <- interpret_colquitt(.80, "psa", orbiting_r = .40)
  expect_identical(ic$benchmark_set, "moderate")
  expect_identical(ic$benchmark_label,
                   "More moderate focal-orbiting correlation (.35-.50)")
})

# RU-14 ---------------------------------------------------------------------

test_that("?contentvalidR points to the vignettes and every example file", {
  section <- rv1_section(rv1_page("contentvalidR-package"), "Getting started")
  expect_match(section, 'vignette("getting-started"', fixed = TRUE)
  for (v in c("item-sort-validity", "construct-rating-validity",
              "expert-panel-validity", "delphi-rounds")) {
    expect_match(section, paste0('"', v, '"'), fixed = TRUE, info = v)
  }
  expect_match(section,
               'system.file("extdata", "sort_example.csv", package = "contentvalidR")',
               fixed = TRUE)

  # Every CSV the package ships is named, and every one named is shipped.
  shipped <- list.files(system.file("extdata", package = "contentvalidR"),
                        pattern = "[.]csv$")
  skip_if(!length(shipped), "the example data are not available")
  # A file name has an underscore, which read.csv() in the example lacks.
  named <- regmatches(section,
                      gregexpr("[A-Za-z0-9]+_[A-Za-z0-9_]+[.]csv",
                               section))[[1]]
  expect_setequal(unique(named), shipped)

  # The relevance ratings have a bullet of their own, naming the vignette
  # that reads them; the walkthrough vignette never does.
  expect_match(section,
               paste0("`walkthrough_relevance.csv`, eight experts' relevance ",
                      "ratings of the same twelve items, for ",
                      "`content_evidence()` in ",
                      "`vignette(\"reporting-examples\")`"),
               fixed = TRUE)
  expect_match(section,
               paste0("`walkthrough_responses.csv`, one item set carried ",
                      "through both stages of pretesting, for ",
                      "`vignette(\"one-item-set-both-stages\")`"),
               fixed = TRUE)

  # The vignettes it names exist, and each reads the files it is named for.
  vignettes <- testthat::test_path("..", "..", "vignettes")
  if (dir.exists(vignettes)) {
    for (v in c("getting-started", "item-sort-validity",
                "construct-rating-validity", "expert-panel-validity",
                "delphi-rounds", "one-item-set-both-stages",
                "reporting-examples")) {
      expect_true(file.exists(file.path(vignettes, paste0(v, ".Rmd"))),
                  info = v)
    }
    rmd <- function(v) {
      paste(readLines(file.path(vignettes, paste0(v, ".Rmd")),
                      warn = FALSE), collapse = "\n")
    }
    both_stages <- rmd("one-item-set-both-stages")
    for (f in c("walkthrough_items.csv", "walkthrough_sort.csv",
                "walkthrough_responses.csv")) {
      expect_match(both_stages, f, fixed = TRUE, info = f)
    }
    expect_false(grepl("walkthrough_relevance.csv", both_stages, fixed = TRUE))
    expect_match(rmd("reporting-examples"), "walkthrough_relevance.csv",
                 fixed = TRUE)
  }
})

# APA inventory: no leading zero on a value that cannot exceed 1 ------------

test_that("bounded values in the help prose drop the leading zero", {
  prob <- rv1_squish(rv1_text(rv1_page("expert_power")))
  expect_match(prob, "Values well below .50 describe", fixed = TRUE)
  expect_false(grepl("below 0.5 describe", prob, fixed = TRUE))

  handoff <- rv1_squish(rv1_text(rv1_page("content_handoff")))
  expect_match(handoff, "kappa carries .74 from", fixed = TRUE)
  expect_match(handoff, "the .74 rule", fixed = TRUE)
  expect_false(grepl("0.74", handoff, fixed = TRUE))

  report <- rv1_squish(rv1_text(rv1_page("content_report")))
  expect_match(report, "(.625) is .63 in both, where R's own rounding gave .62",
               fixed = TRUE)
})

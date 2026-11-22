# The pre-CRAN review of 1.0.1, for the vignettes and the installed extdata
# README: what the text says must match the output printed beside it, and the
# code a reader copies from a page must run on its own. The tests read the
# sources through src_lines() and vignette_sources() (helper-sources.R), so
# under R CMD check they read the copies an installed package carries.

# The code of one labeled chunk.
r101_chunk <- function(lines, label) {
  start <- grep(paste0("^```[{]r ", label, "[,}]"), lines)
  if (length(start) != 1L) stop("No single chunk labeled '", label, "'.")
  ends <- grep("^```[[:space:]]*$", lines)
  lines[seq.int(start + 1L, min(ends[ends > start]) - 1L)]
}

# Runs chunks in order in `env` and returns the value of the last one. What
# the chunks print is captured, so the test log stays quiet.
r101_run <- function(lines, labels, env) {
  value <- NULL
  utils::capture.output(for (label in labels) {
    value <- eval(parse(text = r101_chunk(lines, label)), envir = env)
  })
  value
}

# The lines outside code chunks.
r101_prose_lines <- function(lines) {
  fence <- grepl("^```", lines)
  lines[!(cumsum(fence) %% 2 == 1 | fence)]
}

# The prose as one line, block-quote marks removed, so that a phrase is found
# wherever the source wraps it.
r101_prose <- function(lines) {
  gsub("[[:space:]]+", " ",
       paste(sub("^> ?", "", r101_prose_lines(lines)), collapse = " "))
}

# The paragraphs of a file, each as one line.
r101_paragraphs <- function(lines) {
  paras <- strsplit(paste(lines, collapse = "\n"), "\n[[:space:]]*\n")[[1]]
  paras <- trimws(gsub("[[:space:]]+", " ", paras))
  paras[nzchar(paras)]
}

r101_repo_link <- paste0(
  "[source repository]",
  "(https://github.com/JUhalt/contentvalidR/tree/master/data-raw)"
)

test_that("reading-output explains fragile items with the page's own example", {
  rmd <- src_lines("vignettes", "reading-output.Rmd")
  text <- r101_prose(rmd)
  expect_match(text, paste("at the criterion, or one short of it, depending",
                           "on the panel size"), fixed = TRUE)
  expect_match(text, paste("`Item1` to `Item4` sit exactly at the criterion,",
                           "with 7 of 8 judges rating them relevant, but they",
                           "are not fragile"), fixed = TRUE)
  expect_match(text, paste("still have at least 6 of 7, which meets the",
                           "criterion of 6 for a panel of 7"), fixed = TRUE)
  expect_match(text, paste("An item at 5 of 6 would be fragile, because",
                           "without one of those five judges it has 4 of 5,",
                           "which misses the criterion of 5 for a panel of 5."),
               fixed = TRUE)

  # The page's panel, from the page's own (unlabeled) chunk.
  start <- grep("^judge_ratings <- rbind[(]", rmd)
  expect_length(start, 1L)
  ends <- grep("^```[[:space:]]*$", rmd)
  env <- new.env()
  utils::capture.output(eval(parse(
    text = rmd[seq.int(start, min(ends[ends > start]) - 1L)]
  ), envir = env))
  items <- env$fit_judge$details$influence_items
  first4 <- items[items$item %in% paste0("Item", 1:4), ]
  expect_identical(nrow(first4), 4L)
  expect_true(all(first4$n_raters == 8 & first4$n_relevant == 7))
  expect_false(any(first4$fragile))

  # The criteria the sentences quote, for panels of 5 to 8.
  expect_equal(as.numeric(.cvi_required_count(5:8)), c(5, 5, 6, 7))
  # An item at 5 of 6 is fragile, as the page says.
  X <- cbind(Five = c(4, 4, 4, 4, 4, 1), All = 4, Most = c(4, 3, 4, 3, 4, 4))
  dimnames(X) <- list(paste0("J", 1:6), colnames(X))
  six <- judge_validity(X, lo = 1, hi = 4)$details$influence_items
  expect_true(six$fragile[six$item == "Five"])
})

test_that("reading-output counts delphi_validity() among the item-row workflows", {
  text <- r101_prose(src_lines("vignettes", "reading-output.Rmd"))
  expect_match(text, paste("`expert_validity()`, and `delphi_validity()`",
                           "return **one row per item**"), fixed = TRUE)
  env <- new.env()
  r101_run(src_lines("vignettes", "delphi-rounds.Rmd"), "data", env)
  fit <- delphi_validity(env$ratings, lo = 1, hi = 4, B = 0)
  expect_identical(nrow(fit$results), length(unique(env$ratings$item)))
  expect_identical(anyDuplicated(fit$results$item), 0L)
})

test_that("reading-output says where APA's table forms apply", {
  text <- r101_prose(src_lines("vignettes", "reading-output.Rmd"))
  expect_match(text, paste("its cells write `<.001` and `>.999` without the",
                           "space, and a negative number, in the cells and in",
                           "the note beneath them, takes a true minus sign"),
               fixed = TRUE)
  expect_match(text, paste("The printouts of the fits keep `< .001` and the",
                           "hyphen."), fixed = TRUE)
  # The note under the table is made of sentences and still takes the minus,
  # so the page must not say that sentences keep the hyphen.
  expect_false(grepl("Sentences and the printouts", text, fixed = TRUE))
  # Both halves of the claim, on the page's own example.
  fit <- sort_validity(utils::read.csv(
    system.file("extdata", "sort_example.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE
  ))
  expect_true("<.001" %in% unlist(content_report(fit)))
  expect_true(any(grepl("< .001", utils::capture.output(print(fit)),
                        fixed = TRUE)))
  # The note's negative numbers take the minus, and the fit's printout keeps
  # the hyphen, on the congruence example, whose scale runs from -1 to 1.
  minus <- intToUtf8(0x2212L)
  cong <- expert_validity(utils::read.csv(
    system.file("extdata", "expert_congruence_example.csv",
                package = "contentvalidR"),
    stringsAsFactors = FALSE
  ), mode = "congruence")
  note <- attr(content_report(cong), "note")
  expect_match(note, paste0("(", minus, "1 to 1)"), fixed = TRUE)
  expect_false(grepl("(-1 to 1)", note, fixed = TRUE))
  expect_false(any(grepl(minus, utils::capture.output(print(cong)),
                         fixed = TRUE)))
})

test_that("no vignette holds the minus character, which PDF builds reject", {
  for (v in vignette_sources()) {
    lines <- src_lines("vignettes", v)
    expect_false(any(grepl(intToUtf8(0x2212L), lines, fixed = TRUE)), info = v)
  }
})

test_that("the read_example() helper is shown before the code that calls it", {
  for (v in c("design-and-reporting.Rmd", "reporting-examples.Rmd")) {
    rmd <- src_lines("vignettes", v)
    def <- grep("^read_example <- function", rmd)
    expect_length(def, 1L)
    headers <- grep("^```[{]r", rmd)
    header <- rmd[max(headers[headers < def])]
    expect_false(grepl("include *= *FALSE|echo *= *FALSE", header), info = v)
    calls <- grep("read_example[(]\"", rmd)
    expect_true(length(calls) > 0L && all(calls > def), info = v)
    # The shown chunk is all a reader needs to copy.
    env <- new.env()
    r101_run(rmd, sub("^```[{]r ([^,}]+).*$", "\\1", header), env)
    expect_s3_class(env$read_example("sort_example.csv"), "data.frame")
  }
})

test_that("the construct-rating vignette shows the seed behind its data", {
  withr::local_preserve_seed()
  rmd <- src_lines("vignettes", "construct-rating-validity.Rmd")
  expect_identical(r101_chunk(rmd, "data")[1], "set.seed(12)")
  ends <- grep("^```[[:space:]]*$", rmd)
  for (h in grep("^```[{]r[^}]*include *= *FALSE", rmd)) {
    code <- rmd[seq.int(h + 1L, min(ends[ends > h]) - 1L)]
    expect_false(any(grepl("set.seed", code, fixed = TRUE)))
  }
  # Run twice, the shown code draws the same ratings.
  a <- new.env()
  b <- new.env()
  r101_run(rmd, "data", a)
  r101_run(rmd, "data", b)
  expect_identical(a$rating_dat, b$rating_dat)
})

test_that("the vignettes' own tables write p as an APA table does", {
  rmd <- src_lines("vignettes", "reporting-examples.Rmd")
  env <- new.env()
  for (e in parse(text = r101_chunk(rmd, "sort-fit"))) {
    if (is.call(e) && identical(e[[1]], as.name("<-")) &&
        identical(e[[2]], as.name("rounded"))) eval(e, env)
  }
  d <- data.frame(item = letters[1:5],
                  p_value = c(0.0004, 0.0421, 0.9996, 1, NA),
                  mean_psa = c(0.12345, 1, 2, 3, 4))
  out <- env$rounded(d)
  expect_identical(out$p_value, c("<.001", ".042", ">.999", ">.999", NA))
  expect_identical(out$mean_psa, round(d$mean_psa, 3))
  expect_identical(out$item, d$item)

  rating <- src_lines("vignettes", "construct-rating-validity.Rmd")
  env <- new.env()
  env$aov_out <- structure(list(), contrasts = data.frame(
    item = "A1", target = "A", competitor = c("B", "C", "D", "E"),
    mean_diff = 1, t = 2, df = 23, p = c(0.0002, 0.0123, 0.9996, 1),
    dz = 0.5, pass = TRUE
  ))
  r101_run(rating, "contrasts", env)
  expect_identical(env$shown$p, c("<.001", ".012", ">.999", ">.999"))
})

test_that("reporting-examples lists Polit et al. (2007), which its scaffold cites", {
  rmd <- src_lines("vignettes", "reporting-examples.Rmd")
  start <- grep("^## References$", rmd)
  expect_length(start, 1L)
  expect_match(r101_prose(rmd[seq_len(start - 1L)]), "Polit et al. (2007)",
               fixed = TRUE)
  refs <- r101_paragraphs(rmd[seq.int(start + 1L, length(rmd))])
  polit <- refs[startsWith(refs, "Polit, D. F., Beck, C. T., & Owen, S. V. (2007).")]
  expect_length(polit, 1L)
  # The entry is word for word the one expert-panel-validity gives.
  expert <- r101_paragraphs(src_lines("vignettes", "expert-panel-validity.Rmd"))
  expect_true(polit %in% expert)
  # APA orders the list by the first author's surname.
  first <- tolower(iconv(sub(",.*$", "", refs), "UTF-8", "ASCII//TRANSLIT"))
  expect_identical(order(first, method = "radix"), seq_along(refs))
})

test_that("no sentence in a vignette opens with a number", {
  # APA 7 (Section 6.33) spells out a number that begins a sentence; a
  # scaffold's inline R would print a numeral there.
  for (v in vignette_sources()) {
    text <- r101_prose(src_lines("vignettes", v))
    expect_false(grepl("(^|[.!?] )`r ", text), info = v)
  }
  handoff <- src_lines("vignettes", "handoff-to-empirical-validation.Rmd")
  sentence <- r101_run(handoff, c("panel", "handoff", "reporting"), new.env())
  expect_identical(sentence,
                   "Of 5 items, 3 were carried forward (Supported); 2 were held back.")
})

test_that("no vignette splits a hyphenated word across source lines", {
  for (v in vignette_sources()) {
    lines <- r101_prose_lines(src_lines("vignettes", v))
    expect_false(any(grepl("[[:alpha:]]-$", lines)), info = v)
  }
  expect_false(any(grepl("[[:alpha:]]-$", src_lines("inst", "extdata",
                                                     "README.md"))))
})

test_that("the example-data documents name the workflows and count the test items", {
  readme <- src_lines("inst", "extdata", "README.md")
  reporting <- src_lines("vignettes", "reporting-examples.Rmd")
  for (doc in list(readme, reporting)) {
    text <- r101_prose(doc)
    expect_false(grepl("three flagship workflows", text, fixed = TRUE))
    expect_match(text, "the item-sort, construct-rating, and expert-panel workflows",
                 fixed = TRUE)
  }

  # The README's counts follow the roles the items file records.
  items <- utils::read.csv(
    system.file("extdata", "walkthrough_items.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE
  )
  expect_identical(sum(items$reverse_worded), 2L)
  tests <- items$role[!startsWith(items$role, "ordinary") & !items$reverse_worded]
  expect_length(tests, 7L)
  text <- r101_prose(readme)
  expect_match(text, "Two items are reverse-worded", fixed = TRUE)
  expect_match(text, "Seven more each set a deliberate test", fixed = TRUE)
  expect_false(grepl("Five more", text, fixed = TRUE))
  # EF6 and TF6, the two the old count left out.
  expect_match(items$role[items$item == "EF6"], "content criterion by one judge",
               fixed = TRUE)
  expect_match(text, "one meets the content criterion by a single judge",
               fixed = TRUE)
  expect_match(items$role[items$item == "TF6"], "two cohorts", fixed = TRUE)
  expect_match(text, "one is answered differently in the two cohorts",
               fixed = TRUE)
})

test_that("the walkthrough names the three items that do not behave as expected", {
  rmd <- src_lines("vignettes", "one-item-set-both-stages.Rmd")
  expect_match(r101_prose(rmd), "Three do not: `EF4`, `TF4`, and `EF3`.",
               fixed = TRUE)
  env <- new.env()
  r101_run(rmd, c("items", "sort", "handoff", "responses", "unrecoded",
                  "recode", "factors"), env)
  L <- abs(unclass(env$fa$loadings))
  ef <- startsWith(rownames(L), "EF")
  ef_factor <- which.max(colMeans(L[ef, , drop = FALSE]))
  own <- ifelse(ef, L[, ef_factor], L[, -ef_factor])
  other <- ifelse(ef, L[, -ef_factor], L[, ef_factor])
  # Below .40 on its own facet, or .30 or more on the other: the three named.
  expect_setequal(rownames(L)[own < .40 | other >= .30], c("EF4", "TF4", "EF3"))
  expect_identical(nrow(L), 10L)
})

test_that("reading-output gives Newcombe (1998) its full DOI", {
  rmd <- src_lines("vignettes", "reading-output.Rmd")
  for (v in vignette_sources()) {
    expect_false(any(grepl("doi.org/10/", src_lines("vignettes", v),
                           fixed = TRUE)), info = v)
  }
  # In angle brackets, because a bare URL's link would stop at the "::".
  line <- grep("^<https://doi[.]org/10[.]1002/[(]SICI[)]", rmd, value = TRUE)
  expect_length(line, 1L)
  doi <- sub("^<https://doi[.]org/(.*)>$", "\\1", line)
  expect_identical(utils::URLdecode(doi),
                   "10.1002/(SICI)1097-0258(19980430)17:8<857::AID-SIM777>3.0.CO;2-E")
})

test_that("every pointer to a data-raw script says it is in the source repository", {
  docs <- c(lapply(vignette_sources(), function(v) src_lines("vignettes", v)),
            list(src_lines("inst", "extdata", "README.md")))
  n <- 0L
  for (doc in docs) {
    for (p in r101_paragraphs(doc)) {
      if (!grepl("data-raw/build", p, fixed = TRUE)) next
      n <- n + 1L
      expect_match(p, r101_repo_link, fixed = TRUE)
    }
    expect_false(any(grepl("package sources", doc, fixed = TRUE)))
  }
  expect_identical(n, 8L)
})

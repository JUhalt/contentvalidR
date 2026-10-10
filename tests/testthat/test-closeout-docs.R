# The vignettes and help pages state facts about the package's own output:
# which items a toy sort retains, the numbers a model write-up reports, how
# many items a scale keeps, which judge panels reach a target. A vignette
# cannot assert any of that, so these tests do, by running the vignette's own
# chunks where they can. They read the source tree when it is there, and
# otherwise (as under R CMD check) the vignette sources and help pages an
# installed package carries: src_lines() and vignette_sources() are in
# helper-sources.R. Only the checks of README.Rmd and of the R/ sources, which
# are not installed, skip without the source tree.

# The code of one labeled chunk of an R Markdown file.
chunk_code <- function(lines, label) {
  start <- grep(paste0("^```[{]r ", label, "[,}]"), lines)
  if (length(start) != 1L) stop("No single chunk labeled '", label, "'.")
  ends <- grep("^```[[:space:]]*$", lines)
  end <- min(ends[ends > start])
  lines[seq.int(start + 1L, end - 1L)]
}

run_chunks <- function(lines, labels, env) {
  for (label in labels) {
    eval(parse(text = chunk_code(lines, label)), envir = env)
  }
  env
}

# A vignette's prose as one line, with block-quote marks removed, so a phrase
# can be found wherever the source wraps it.
prose <- function(lines) {
  gsub("[[:space:]]+", " ", paste(sub("^> ?", "", lines), collapse = " "))
}

# Parsed help pages, from the source tree when there is one, and from the
# installed package otherwise.
help_pages <- function() {
  man <- testthat::test_path("..", "..", "man")
  if (dir.exists(man)) {
    files <- list.files(man, pattern = "[.]Rd$", full.names = TRUE)
    out <- lapply(files, tools::parse_Rd, encoding = "UTF-8")
    names(out) <- basename(files)
    return(out)
  }
  db <- tryCatch(tools::Rd_db("contentvalidR"), error = function(e) NULL)
  if (!length(db)) skip("package documentation is not available")
  db
}

rd_tags <- function(rd) vapply(rd, function(x) attr(x, "Rd_tag"), "")

# The text of every \code and \verb inside an Rd element.
rd_code <- function(x) {
  out <- character(0)
  walk <- function(e) {
    tag <- attr(e, "Rd_tag")
    if (!is.null(tag) && tag %in% c("\\code", "\\verb")) {
      out <<- c(out, paste(unlist(e), collapse = ""))
    } else if (is.list(e)) {
      for (k in e) walk(k)
    }
  }
  walk(x)
  out
}

test_that("every registered S3 method has exactly one help page", {
  pages <- help_pages()
  aliases <- unlist(lapply(pages, function(rd) {
    vapply(rd[rd_tags(rd) == "\\alias"],
           function(x) paste(unlist(x), collapse = ""), "")
  }), use.names = FALSE)
  expect_false(anyDuplicated(aliases) > 0L,
               info = paste(aliases[duplicated(aliases)], collapse = ", "))

  info <- getNamespaceInfo(asNamespace("contentvalidR"), "S3methods")
  methods <- paste(info[, 1], info[, 2], sep = ".")
  expect_gt(length(methods), 60L)
  missing <- setdiff(methods, aliases)
  expect_identical(missing, character(0),
                   info = paste("no help page:", paste(missing, collapse = ", ")))

  # The print, summary and plot methods without a page of their own share
  # one, which says what each does.
  page <- pages[["contentvalid-methods.Rd"]]
  expect_false(is.null(page))
  shared <- vapply(page[rd_tags(page) == "\\alias"],
                   function(x) paste(unlist(x), collapse = ""), "")
  expect_true(all(c("print.contentvalid_sort", "summary.contentvalid_sort",
                    "print.summary.contentvalid_rounds",
                    "plot.contentvalid_judge", "plot.contentvalid_domain",
                    "plot.contentvalid_rounds") %in% shared))
})

test_that("every help page says what is returned", {
  # CRAN asks for a \value section on every page that documents a function or
  # a method. Only the package's own page documents neither.
  pages <- help_pages()
  expect_gt(length(pages), 40L)
  has_value <- vapply(pages, function(rd) "\\value" %in% rd_tags(rd), NA)
  without <- sub("[.]Rd$", "", names(pages)[!has_value])
  expect_identical(without, "contentvalidR-package")
})

test_that("each workflow's help lists every column of its results", {
  pages <- help_pages()
  documented <- function(topic) {
    rd <- pages[[paste0(topic, ".Rd")]]
    if (is.null(rd)) skip("package documentation is not available")
    rd_code(rd[rd_tags(rd) == "\\value"])
  }
  ext <- function(f) {
    utils::read.csv(system.file("extdata", f, package = "contentvalidR"),
                    stringsAsFactors = FALSE)
  }

  sort_cols <- names(sort_validity(ext("sort_example.csv"))$results)
  expect_true(all(sort_cols %in% documented("sort_validity")),
              info = paste(setdiff(sort_cols, documented("sort_validity")),
                           collapse = ", "))

  rating_cols <- names(rating_validity(ext("rating_example.csv"))$results)
  expect_true(all(rating_cols %in% documented("rating_validity")),
              info = paste(setdiff(rating_cols, documented("rating_validity")),
                           collapse = ", "))

  rel <- ext("expert_relevance_example.csv")
  ess <- ext("expert_essentiality_example.csv")
  con <- ext("expert_congruence_example.csv")
  expert_cols <- unique(c(
    names(expert_validity(as.matrix(rel[-1]), mode = "relevance", lo = 1,
                          hi = 4, agreement = "none")$results),
    names(expert_validity(as.matrix(ess[-1]), mode = "essentiality")$results),
    names(expert_validity(con, mode = "congruence")$results),
    names(expert_validity(con[setdiff(names(con), "target_objective")],
                          mode = "congruence")$results)
  ))
  expect_true(all(expert_cols %in% documented("expert_validity")),
              info = paste(setdiff(expert_cols, documented("expert_validity")),
                           collapse = ", "))

  judges <- rbind(c(4, 4, 3, 2), c(4, 3, 4, 1), c(3, 4, 4, 2), c(2, 2, 2, 1))
  judge_cols <- names(judge_validity(judges, lo = 1, hi = 4)$results)
  expect_true(all(judge_cols %in% documented("judge_validity")),
              info = paste(setdiff(judge_cols, documented("judge_validity")),
                           collapse = ", "))

  cells <- data.frame(item = paste0("I", 1:4), cell = c("A", "A", "B", "C"))
  domain_cols <- names(domain_validity(cells, cell_col = "cell")$results)
  expect_true(all(domain_cols %in% documented("domain_validity")),
              info = paste(setdiff(domain_cols, documented("domain_validity")),
                           collapse = ", "))

  # Delphi fits with and without a threshold, and with an item too few
  # experts rated, so every recommendation occurs and is named.
  long <- function(m, round) {
    data.frame(expert = paste0("E", seq_len(nrow(m))),
               item = rep(colnames(m), each = nrow(m)), round = round,
               rating = as.vector(m))
  }
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4), S2 = c(2, 3, 2, 1, 3, 2))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2))
  thin <- data.frame(expert = c("E1", "E2", "E1", "E2"), item = "S3",
                     round = c(1, 1, 2, 2), rating = 4)
  d <- rbind(long(r1, 1), long(r2, 2), thin)
  set <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75, B = 0)
  none <- delphi_validity(d, lo = 1, hi = 4, B = 0)
  delphi_cols <- unique(c(names(set$results), names(none$results)))
  expect_true(all(delphi_cols %in% documented("delphi_validity")),
              info = paste(setdiff(delphi_cols, documented("delphi_validity")),
                           collapse = ", "))
  recs <- unique(c(set$results$recommendation, none$results$recommendation))
  expect_setequal(recs, c("Consensus", "No consensus", "Descriptive only",
                          "Insufficient panel"))
  expect_true(all(paste0('"', recs, '"') %in% documented("delphi_validity")),
              info = paste(recs, collapse = ", "))
})

test_that("getting started covers every workflow and its toy sort retains items", {
  rmd <- src_lines("vignettes", "getting-started.Rmd")
  text <- prose(rmd)

  # Headings, not bold lines, and the Csv formula in math the page renders.
  expect_gte(length(grep("^## ", rmd)), 8L)
  expect_false(any(grepl("^[*][*][A-Z][^*]*[*][*]$", rmd)))
  expect_match(text, "\\(\\text{Csv} = (n_{target} - n_{competitor}) / N\\)",
               fixed = TRUE)

  for (f in c("sort_validity", "rating_validity", "expert_validity",
              "delphi_validity", "judge_validity", "domain_validity",
              "content_evidence", "content_handoff")) {
    expect_match(text, paste0("`", f, "()`"), fixed = TRUE)
  }
  for (v in c("item-sort-validity", "construct-rating-validity",
              "expert-panel-validity", "delphi-rounds", "reading-output",
              "reporting-examples", "handoff-to-empirical-validation",
              "one-item-set-both-stages")) {
    expect_match(text, paste0('vignette("', v, '")'), fixed = TRUE)
  }

  env <- run_chunks(rmd, c("sort", "diagnostics"), new.env())
  status <- env$sort_fit$results$status
  expect_identical(env$sort_fit$results$item[status == "Supported"],
                   c("I1", "I2"))
  expect_identical(env$sort_fit$results$item[status == "Review"],
                   c("I3", "I4"))
  expect_lt(env$sort_fit$results$csv[env$sort_fit$results$item == "I4"], 0)
  expect_identical(env$sort_fit$results$critical_n_target[1], 10L)

  # The diagnostics compare decisions that vary, so phi is defined.
  sd <- signal_detection(env$pretest_supported, env$later_retained)
  rp <- reproducibility_phi(env$pretest_supported, env$replication_supported)
  expect_true(is.finite(sd$phi))
  expect_true(is.finite(rp$phi))
  expect_identical(sd$p_method, "Fisher's exact test")
  expect_identical(rp$p_method, "Fisher's exact test")
})

test_that("the reading-output write-up reports the fit's own numbers", {
  rmd <- src_lines("vignettes", "reading-output.Rmd")
  text <- prose(rmd)
  r <- sort_validity(utils::read.csv(
    system.file("extdata", "sort_example.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE
  ))$results

  expect_identical(r$item[r$recommendation == "Retain"],
                   c("A1", "A2", "B1", "C1"))
  expect_identical(r$item[r$recommendation == "Review"], c("B2", "C2"))
  expect_true(all(r$critical_n_target == 15L))
  expect_match(text, "an item needs 15 of 20 target assignments", fixed = TRUE)
  for (i in seq_len(nrow(r))) {
    phrase <- paste0("*Psa* = ", .fmt(r$psa[i]), ", 95% CI ",
                     .fmt_ci(r$psa_low[i], r$psa_high[i]), ", *p* ",
                     sub("^p ", "", .p_phrase(r$p_value[i])))
    expect_match(text, phrase, fixed = TRUE, info = r$item[i])
  }
  expect_match(text, "Howard, M. C., & Melloy, R. C. (2016).", fixed = TRUE)
  # The bands describe a scale's mean, not an item.
  expect_false(grepl("not that the item", text, fixed = TRUE))
})

test_that("the walkthrough's scale count follows from the handoff", {
  rmd <- src_lines("vignettes", "one-item-set-both-stages.Rmd")
  text <- prose(rmd)
  expect_false(any(grepl("^## Stage one: the expert panel", rmd)))
  h <- content_handoff(sort_validity(utils::read.csv(
    system.file("extdata", "walkthrough_sort.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE
  )))
  # The text drops EF4 and then EF3 from the effort-regulation scale.
  left <- setdiff(h$scales$EF, c("EF3", "EF4"))
  expect_identical(left, c("EF1", "EF2", "EF6"))
  expect_match(text, "still has three items, `EF1`, `EF2`, and `EF6`",
               fixed = TRUE)
})

test_that("the Delphi vignette's kappa claim holds for its own data", {
  rmd <- src_lines("vignettes", "delphi-rounds.Rmd")
  text <- prose(rmd)
  expect_false(grepl("dotted line", text, fixed = TRUE))
  expect_match(text, "computed from sums of squares (Fleiss & Cohen, 1973)",
               fixed = TRUE)

  env <- run_chunks(rmd, "data", new.env())
  fit <- delphi_validity(env$ratings, lo = 1, hi = 4, B = 0)
  st <- fit$details$stability
  rounds <- list(env$round1, env$round2, env$round3)
  # Kappa with quadratic weights against the intraclass correlation computed
  # from sums of squares, and from mean squares, for one pair of rounds.
  iccs <- function(x, y) {
    X <- cbind(x, y)
    n <- nrow(X)
    gm <- mean(X)
    ss_s <- 2 * sum((rowMeans(X) - gm)^2)
    ss_r <- n * sum((colMeans(X) - gm)^2)
    ss_e <- sum((X - gm)^2) - ss_s - ss_r
    ms_s <- ss_s / (n - 1)
    ms_e <- ss_e / (n - 1)
    c(ss = (ss_s - ss_e) / (ss_s + ss_e + 2 * ss_r),
      ms = (ms_s - ms_e) / (ms_s + ms_e + 2 * (ss_r - ms_e) / n))
  }
  for (k in seq_len(nrow(st))) {
    a <- rounds[[st$from_round[k]]]
    b <- rounds[[st$to_round[k]]]
    it <- st$item[k]
    if (!it %in% colnames(a) || !it %in% colnames(b) || is.na(st$value[k])) next
    m <- min(nrow(a), nrow(b))
    expect_equal(unname(iccs(a[seq_len(m), it], b[seq_len(m), it])["ss"]),
                 st$value[k], tolerance = 1e-10, info = it)
  }
  # "With ten experts the two can differ in the second decimal."
  s5 <- iccs(env$round1[, "S5"], env$round2[, "S5"])
  expect_false(identical(.fmt(s5[["ss"]]), .fmt(s5[["ms"]])))
})

test_that("the design guide's claim about reachable targets holds", {
  rmd <- src_lines("vignettes", "design-and-reporting.Rmd")
  env <- run_chunks(rmd, "gtheory", new.env())
  needed <- gtheory_content(env$judge_ratings)$judges_needed
  expect_false(anyNA(needed[c("n_judges_relative", "n_judges_absolute")]))
  expect_lte(max(needed$n_judges_relative, needed$n_judges_absolute), 5)
  expect_match(prose(rmd), "every target is reached with five judges or fewer",
               fixed = TRUE)
})

test_that("vignette tables print rounded, and the p0 caveat is stated", {
  rating <- src_lines("vignettes", "construct-rating-validity.Rmd")
  env <- new.env()
  env$aov_out <- anova_content(utils::read.csv(
    system.file("extdata", "rating_example.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE
  ), design = "within")
  run_chunks(rating, "contrasts", env)
  expect_true(all(grepl("^(< [.]001|[.][0-9]{3}|1[.]000)$", env$shown$p)))
  for (col in c("mean_diff", "t", "dz")) {
    v <- env$shown[[col]]
    expect_true(all(abs(v * 100 - round(v * 100)) < 1e-8), info = col)
  }

  sort_text <- prose(src_lines("vignettes", "item-sort-validity.Rmd"))
  expect_match(sort_text, "arbitrary and lenient", fixed = TRUE)
  expect_match(sort_text,
               "With a null rate of .60, 15 of 20 judges no longer meets",
               fixed = TRUE)
  expect_false(csv_binom_test(15, 20, p0 = .60)$passes_chance)
  expect_true(csv_binom_test(15, 20)$passes_chance)
})

test_that("the Markdown report is shown rendered, and the README says how", {
  rmd <- src_lines("vignettes", "reporting-examples.Rmd")
  asis <- grep('^```[{]r [^}]*results = "asis"', rmd)
  expect_length(asis, 1L)
  label <- sub("^```[{]r ([^,}]+).*$", "\\1", rmd[asis])
  expect_match(paste(chunk_code(rmd, label), collapse = " "),
               'format = "markdown"', fixed = TRUE)

  readme <- prose(src_lines("README.Rmd"))
  expect_match(readme, 'results = "asis"', fixed = TRUE)
  expect_false(grepl("prints its verdict first", readme, fixed = TRUE))
  expect_match(readme, "then the facts of the design, then its verdict",
               fixed = TRUE)
})

test_that("the Scheibe et al. chapter names no publisher that repeats its editors", {
  # APA 7 omits the publisher when it is the same as the author or editors,
  # as the 2002 web edition's issuers, its two editors, are.
  for (path in list(c("README.Rmd"), c("vignettes", "delphi-rounds.Rmd"),
                    c("R", "delphi_validity.R"))) {
    text <- prose(sub("^#' ?", "", do.call(src_lines, as.list(path))))
    # The URL follows the page range directly (in Rd it is wrapped in \url{}).
    expect_match(text, paste0("\\(pp\\. 257\u2013281\\)\\. ",
                              "(\\\\url\\{)?https://"),
                 info = paste(path, collapse = "/"))
  }
  bib <- src_lines("inst", "REFERENCES.bib")
  entry <- bib[seq(grep("^@incollection[{]scheibe2002", bib), length(bib))]
  entry <- entry[seq_len(grep("^[}]", entry)[1])]
  expect_false(any(grepl("publisher", entry, fixed = TRUE)))
})

test_that("Markdown lists in the vignettes and README start a new block", {
  files <- c(file.path("vignettes", vignette_sources()), "README.Rmd")
  if (length(files) < 2L) skip("package sources are not available")
  for (f in files) {
    lines <- do.call(src_lines, as.list(strsplit(f, "/", fixed = TRUE)[[1]]))
    fence <- cumsum(grepl("^```", lines)) %% 2L == 1L | grepl("^```", lines)
    item <- grepl("^([-*]|[0-9]+[.]) ", lines)
    prev <- c("", lines[-length(lines)])
    prev_item <- c(FALSE, item[-length(item)])
    # A list item straight after a paragraph line runs into that paragraph.
    bad <- which(item & !fence & nzchar(trimws(prev)) & !prev_item &
                   !grepl("^[[:space:]]", prev))
    expect_identical(bad, integer(0), info = f)
  }
})

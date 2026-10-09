test_that("bundled example datasets are installed with stable schemas", {
  files <- c(
    sort = "sort_example.csv",
    rating = "rating_example.csv",
    relevance = "expert_relevance_example.csv",
    essentiality = "expert_essentiality_example.csv",
    congruence = "expert_congruence_example.csv"
  )
  paths <- vapply(files, function(x) {
    system.file("extdata", x, package = "contentvalidR")
  }, character(1))

  expect_true(all(nzchar(paths)))
  expect_true(all(file.exists(paths)))

  sort_dat <- utils::read.csv(paths[["sort"]], stringsAsFactors = FALSE)
  expect_identical(
    names(sort_dat),
    c("item", "rater", "target_construct", "assigned_construct")
  )
  expect_equal(nrow(sort_dat), 120L)

  rating_dat <- utils::read.csv(paths[["rating"]], stringsAsFactors = FALSE)
  expect_identical(
    names(rating_dat),
    c("item", "rater", "construct", "target_construct", "rating")
  )
  expect_equal(nrow(rating_dat), 432L)

  relevance <- utils::read.csv(paths[["relevance"]], stringsAsFactors = FALSE)
  expect_identical(names(relevance), c("expert", paste0("Item", 1:5)))
  expect_equal(nrow(relevance), 8L)

  essentiality <- utils::read.csv(paths[["essentiality"]], stringsAsFactors = FALSE)
  expect_identical(names(essentiality), c("expert", paste0("Item", 1:4)))
  expect_equal(nrow(essentiality), 12L)

  congruence <- utils::read.csv(paths[["congruence"]], stringsAsFactors = FALSE)
  expect_identical(
    names(congruence),
    c("item", "judge", "objective", "target_objective", "score")
  )
  expect_equal(nrow(congruence), 54L)
})

test_that("bundled examples execute all flagship workflow families", {
  read_ext <- function(name) {
    utils::read.csv(
      system.file("extdata", name, package = "contentvalidR"),
      stringsAsFactors = FALSE
    )
  }

  s <- sort_validity(read_ext("sort_example.csv"))
  expect_s3_class(s, "contentvalid_sort")
  expect_true(any(s$results$status == "Supported"))
  expect_true(any(s$results$status == "Review"))

  r <- rating_validity(read_ext("rating_example.csv"), scale_min = 1, scale_max = 5)
  expect_s3_class(r, "contentvalid_rating")
  expect_true(any(r$results$status == "Supported"))
  expect_true(any(r$results$status == "Review"))

  rel <- read_ext("expert_relevance_example.csv")
  rel_fit <- expert_validity(
    as.matrix(rel[setdiff(names(rel), "expert")]),
    mode = "relevance", lo = 1, hi = 4
  )
  expect_s3_class(rel_fit, "contentvalid_expert")

  ess <- read_ext("expert_essentiality_example.csv")
  ess_fit <- expert_validity(
    as.matrix(ess[setdiff(names(ess), "expert")]),
    mode = "essentiality"
  )
  expect_s3_class(ess_fit, "contentvalid_expert")
  expect_true(any(ess_fit$results$status == "Supported"))
  expect_true(any(ess_fit$results$status == "Review"))

  con <- read_ext("expert_congruence_example.csv")
  con_fit <- expert_validity(con, mode = "congruence")
  expect_s3_class(con_fit, "contentvalid_expert")
})

test_that("the README reference list and REFERENCES.bib list the same works", {
  readme <- testthat::test_path("..", "..", "README.Rmd")
  bib <- testthat::test_path("..", "..", "inst", "REFERENCES.bib")
  skip_if_not(file.exists(readme) && file.exists(bib), "package sources are not available")

  lines <- readLines(readme, warn = FALSE, encoding = "UTF-8")
  start <- which(lines == "## References")
  expect_length(start, 1L)
  stop_at <- which(startsWith(lines, "## ") & seq_along(lines) > start)[1]
  entries <- grep("^- ", lines[(start + 1L):(stop_at - 1L)], value = TRUE)
  bib_text <- readLines(bib, warn = FALSE, encoding = "UTF-8")
  expect_identical(length(entries), length(grep("^@", bib_text)))

  # Newcombe's (1998) DOI holds "<", ">" and "::", which break Markdown links,
  # so the README gives its shortDOI (APA 7 allows either); the file keeps
  # the full DOI.
  short_dois <- c(
    "10/cpchjg" = "10.1002/(sici)1097-0258(19980430)17:8<857::aid-sim777>3.0.co;2-e"
  )
  norm_doi <- function(x) {
    x <- tolower(x)
    ifelse(x %in% names(short_dois), short_dois[x], x)
  }
  readme_dois <- norm_doi(sub("^.*https://doi\\.org/(\\S+)$", "\\1",
                              grep("https://doi\\.org/", entries, value = TRUE)))
  bib_dois <- norm_doi(sub("^\\s*doi = \\{(.*)\\},?$", "\\1",
                           grep("^\\s*doi = ", bib_text, value = TRUE)))
  expect_setequal(readme_dois, bib_dois)

  # APA 7 orders the reference list alphabetically by author, and an
  # author's undated work before the dated ones (Section 9.47).
  authors <- sub("\\s\\((\\d{4}|n\\.d\\.)\\).*$", "", sub("^- ", "", entries))
  plain <- tolower(iconv(authors, "UTF-8", "ASCII//TRANSLIT"))
  plain <- gsub("[^a-z ]", " ", gsub("(eds.)", "", plain, fixed = TRUE))
  plain <- trimws(gsub("\\s+", " ", plain))
  years <- sub("^.*\\((\\d{4}|n\\.d\\.)\\).*$", "\\1", entries)
  years[years == "n.d."] <- "0000"
  expect_identical(order(plain, years, method = "radix"), seq_along(entries))
})

test_that("citation and the BibTeX reference list are installed", {
  bib <- system.file("REFERENCES.bib", package = "contentvalidR")
  expect_true(nzchar(bib))
  expect_true(file.exists(bib))

  bib_text <- paste(readLines(bib, warn = FALSE), collapse = "\n")
  for (doi in c(
    "10.1037/0021-9010.76.5.732",
    "10.1007/s10869-015-9404-y",
    "10.1177/109442819922004",
    "10.1037/apl0000406",
    "10.1207/s15327841mpee0804_3",
    "10.1111/j.1744-6570.1975.tb01393.x",
    "10.1177/0748175613513808",
    "10.1002/nur.20199",
    "10.1097/00006199-198611000-00017",
    "10.2307/23044045",
    "10.1007/bf02289823"
  )) {
    # DOIs are case-insensitive; the file keeps each publisher's capitals.
    expect_true(grepl(doi, tolower(bib_text), fixed = TRUE), info = doi)
  }

  cit <- system.file("CITATION", package = "contentvalidR")
  expect_true(nzchar(cit))
  expect_true(file.exists(cit))
  cit_text <- paste(readLines(cit, warn = FALSE), collapse = "\n")
  expect_match(cit_text, "contentvalidR")
  expect_match(cit_text, "meta\\$Version")
})

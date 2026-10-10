# Schema version 1 is frozen: a downstream package reads these objects, so the
# field names, their order, and their types are a promise rather than an
# implementation detail. `.handoff_schema()` is that promise as data, and these
# tests check real objects against it, from every workflow that can hand off.

schema <- contentvalidR:::.handoff_schema()

types_of <- function(x) vapply(x, function(v) class(v)[1], character(1))

handoffs <- function() {
  relevance <- matrix(c(4, 4, 4, 3, 4, 4, 3, 4, 3, 4, 4, 4, 2, 2, 1, 2),
                      nrow = 4, dimnames = list(NULL, paste0("Item", 1:4)))
  sort_dat <- data.frame(
    item = rep(c("A1", "A2", "B1"), each = 12), rater = rep(1:12, 3),
    target_construct = c(rep("A", 24), rep("B", 12)),
    assigned_construct = c(rep("A", 11), "B", rep("A", 9), rep("B", 3),
                           rep("B", 10), rep("A", 2)),
    stringsAsFactors = FALSE)
  long <- function(m, round) {
    data.frame(expert = paste0("E", seq_len(nrow(m))),
               item = rep(colnames(m), each = nrow(m)),
               round = round, rating = as.vector(m), stringsAsFactors = FALSE)
  }
  r1 <- cbind(S1 = c(4, 4, 3, 4, 3, 4), S2 = c(3, 4, 3, 2, 4, 3))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(4, 4, 4, 4, 4, 3))
  # The package's own example data, for the construct-rating and the
  # item-objective congruence designs.
  ext <- function(f) {
    utils::read.csv(system.file("extdata", f, package = "contentvalidR"),
                    stringsAsFactors = FALSE)
  }
  congruence <- ext("expert_congruence_example.csv")
  # Without a target objective no decision rule is applied, so every item is
  # "Descriptive only".
  untargeted <- expert_validity(
    congruence[setdiff(names(congruence), "target_objective")],
    mode = "congruence")

  keep_all <- c("Supported", "Review", "Insufficient data", "Descriptive only")
  list(
    `expert relevance` = content_handoff(
      expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
                      agreement = "none"), keep = keep_all),
    `expert relevance with panel agreement` = content_handoff(
      expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
                      agreement = "krippendorff", agreement_B = 100, seed = 3),
      keep = keep_all),
    essentiality = content_handoff(
      expert_validity(c(10, 8, 6), mode = "essentiality", N = 12), keep = keep_all),
    `item sort` = content_handoff(sort_validity(sort_dat), keep = keep_all),
    delphi = content_handoff(
      delphi_validity(rbind(long(r1, 1), long(r2, 2)), lo = 1, hi = 4,
                      consensus_threshold = 0.75, B = 0), keep = keep_all),
    `construct rating` = content_handoff(
      rating_validity(ext("rating_example.csv"), scale_min = 1, scale_max = 5),
      keep = keep_all),
    `expert congruence` = content_handoff(
      expert_validity(congruence, mode = "congruence"), keep = keep_all),
    `expert congruence without targets` = content_handoff(
      untargeted, keep = c("Supported", "Descriptive only")),
    # The default `keep` carries no "Descriptive only" item, so this handoff
    # carries no item at all.
    `expert congruence carrying no item` = content_handoff(untargeted)
  )
}

test_that("every handoff matches the frozen version 1 contract", {
  for (nm in names(handoffs())) {
    h <- handoffs()[[nm]]
    expect_identical(names(h), schema$top_level, info = nm)
    expect_identical(h$provenance$schema_version, schema$version, info = nm)

    expect_type(h$items, "character")
    expect_true(is.null(h$scales) || is.list(h$scales), info = nm)

    for (part in c("item_evidence", "item_statistics", "panel_statistics")) {
      expect_true(is.data.frame(h[[part]]), info = paste(nm, part))
      expect_identical(names(h[[part]]), names(schema[[part]]),
                       info = paste(nm, part))
      expect_identical(types_of(h[[part]]), schema[[part]],
                       info = paste(nm, part))
    }
    expect_identical(names(h$provenance), names(schema$provenance), info = nm)
    expect_identical(types_of(h$provenance), schema$provenance, info = nm)
  }
})

test_that("the handoffs checked include one that carries no item", {
  hs <- handoffs()
  described <- hs[["expert congruence without targets"]]
  expect_true(all(described$item_evidence$status == "Descriptive only"))
  expect_identical(described$items, described$item_evidence$item)

  none <- hs[["expert congruence carrying no item"]]
  expect_identical(none$items, character(0))
  expect_false(any(none$item_evidence$carried))
  # The item set is empty, and the evidence on every reviewed item still
  # travels.
  expect_identical(none$item_evidence$item, described$item_evidence$item)
  expect_gt(nrow(none$item_statistics), 0L)
})

test_that("every handoff carries every column, whatever the workflow held", {
  hs <- handoffs()
  for (nm in names(hs)) {
    for (part in c("item_statistics", "panel_statistics")) {
      d <- hs[[nm]][[part]]
      # A statistic with no interval carries NA in all four columns, not a
      # dropped column and not a partial interval.
      none <- is.na(d$lower)
      expect_identical(is.na(d$upper), none, info = paste(nm, part))
      expect_identical(is.na(d$interval_method), none, info = paste(nm, part))
      expect_identical(is.na(d$interval_level), none, info = paste(nm, part))
      # `note` is display text, so it is never NA.
      expect_false(anyNA(d$note), info = paste(nm, part))
    }
    # Zero rows is a real answer, not a missing field.
    expect_identical(names(hs[[nm]]$panel_statistics),
                     names(schema$panel_statistics), info = nm)
  }

  # The point of a frozen column set: handoffs from different workflows bind
  # without reconciling them first.
  bound <- do.call(rbind, lapply(hs, `[[`, "item_statistics"))
  expect_identical(names(bound), names(schema$item_statistics))
  expect_gt(nrow(bound), 0L)
})

test_that("the documentation lists every frozen field", {
  rd <- tryCatch({
    doc <- tools::Rd_db("contentvalidR")[["content_handoff.Rd"]]
    if (is.null(doc)) NULL else paste(as.character(doc), collapse = " ")
  }, error = function(e) NULL)
  if (is.null(rd)) {
    path <- testthat::test_path("..", "..", "man", "content_handoff.Rd")
    if (!file.exists(path)) skip("handoff documentation is not available")
    rd <- paste(readLines(path, warn = FALSE), collapse = " ")
  }

  fields <- c(schema$top_level, names(schema$item_evidence),
              names(schema$item_statistics), names(schema$provenance))
  missing <- fields[!vapply(fields, grepl, logical(1), x = rd, fixed = TRUE)]
  expect_identical(missing, character(0),
                   info = paste("not documented:", paste(missing, collapse = ", ")))
})

test_that("a reader can tell an unfamiliar schema version from a familiar one", {
  h <- handoffs()[["expert relevance"]]
  # The one field a reader is told to gate on.
  expect_true("schema_version" %in% names(h$provenance))
  expect_type(h$provenance$schema_version, "integer")
  expect_length(h$provenance$schema_version, 1L)
})

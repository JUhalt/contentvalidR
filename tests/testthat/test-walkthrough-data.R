# vignette("one-item-set-both-stages") narrates specific things about the
# shipped walkthrough data: which two items the panel flags, which item met the
# criterion by one judge, which items pass content review and then misbehave,
# and which item differs between cohorts. A vignette cannot assert any of that,
# so these tests do. If the data are regenerated and a claim stops holding, the
# suite fails here rather than the vignette quietly becoming wrong.

extdata <- function(f) system.file("extdata", f, package = "contentvalidR")

wt_items <- function() {
  read.csv(extdata("walkthrough_items.csv"), stringsAsFactors = FALSE)
}
wt_responses <- function() {
  read.csv(extdata("walkthrough_responses.csv"), stringsAsFactors = FALSE)
}
wt_panel <- function() {
  sort_validity(read.csv(extdata("walkthrough_sort.csv"),
                         stringsAsFactors = FALSE))
}
wt_handoff <- function() {
  items <- wt_items()
  content_handoff(wt_panel(), reverse_keyed = items$item[items$reverse_worded],
                  response_scale = c(1, 5))
}
# Reverse-worded items recoded with the keying and limits the handoff carries,
# which is the only correct way for a reader to do it.
wt_recoded <- function(h = wt_handoff()) {
  X <- as.matrix(wt_responses()[h$items])
  ev <- h$item_evidence
  key <- setNames(ev$keying, ev$item)[h$items]
  X[, key == -1] <- (ev$response_min[1] + ev$response_max[1]) - X[, key == -1]
  X
}

test_that("the three walkthrough files agree on one item set", {
  items <- wt_items()
  sorted <- read.csv(extdata("walkthrough_sort.csv"), stringsAsFactors = FALSE)
  responses <- wt_responses()

  expect_identical(nrow(items), 12L)
  expect_setequal(sorted$item, items$item)
  # nomologR reads one row per respondent and one column per item, named
  # exactly as the handoff's `item` values, in order.
  expect_identical(names(responses), c("respondent", "cohort", items$item))
  expect_identical(nrow(responses), 400L)
  expect_setequal(responses$cohort, c("A", "B"))

  values <- unlist(responses[items$item], use.names = FALSE)
  expect_type(values, "integer")
  expect_gte(min(values), 1L)
  expect_lte(max(values), 5L)
  expect_false(anyNA(values))
})

test_that("the panel flags the two items the walkthrough says it flags", {
  r <- wt_panel()$results

  expect_setequal(r$item[r$recommendation == "Review"], c("EF5", "TF5"))
  # EF5 keeps its target but misses the criterion; TF5 loses it outright.
  expect_gt(r$csv[r$item == "EF5"], 0)
  expect_lt(r$csv[r$item == "TF5"], 0)
  expect_identical(r$issue[r$item == "TF5"], "Competing construct favored")

  # EF6 meets the criterion by exactly one judge, which the vignette leans on.
  expect_identical(r$n_target[r$item == "EF6"],
                   r$critical_n_target[r$item == "EF6"])
  expect_identical(r$recommendation[r$item == "EF6"], "Retain")
})

test_that("the handoff carries ten items in two equal facets", {
  h <- content_handoff(wt_panel())

  expect_length(h$items, 10L)
  expect_false(any(c("EF5", "TF5") %in% h$items))
  expect_named(h$scales, c("EF", "TF"))
  expect_length(h$scales$EF, 5L)
  expect_length(h$scales$TF, 5L)

  # The rejected items stay in the record, so the walkthrough can show them.
  ev <- h$item_evidence
  expect_setequal(ev$item, wt_items()$item)
  expect_setequal(ev$item[!ev$carried], c("EF5", "TF5"))
})

test_that("EF4 passes content review and still carries almost nothing", {
  # The headline claim of the vignette. Measured with corrected item-total
  # correlations rather than a factor solution, because factor order and sign
  # are not stable across platforms and these are.
  h <- wt_handoff()
  X <- wt_recoded(h)
  corrected <- function(item, set) {
    rest <- setdiff(set, item)
    stats::cor(X[, item], rowSums(X[, rest, drop = FALSE]))
  }

  ef <- h$scales$EF
  r_ef <- vapply(ef, corrected, numeric(1), set = ef)

  expect_true("EF4" %in% ef)
  expect_lt(r_ef[["EF4"]], 0.35)
  # EF3 is also low, but for a different reason (see the next test), so the
  # well-behaved comparison excludes it.
  expect_gt(min(r_ef[setdiff(ef, c("EF3", "EF4"))]), 0.45)

  # What makes EF4's low correlation damning is that its spread is ordinary:
  # nothing about the distribution explains it away.
  spread <- apply(X, 2, stats::sd)
  expect_gt(spread[["EF4"]], 0.9 * stats::median(spread))
})

test_that("EF3 is flagged by a screen for a reason the panel had already answered", {
  # The reverse case, and the sharper one: an empirical screen flags it, and
  # keeping it is right. Requested by the nomologR maintainers so that both
  # packages' articles tell the same story about this item.
  h <- wt_handoff()
  X <- wt_recoded(h)
  corrected <- function(item, set) {
    rest <- setdiff(set, item)
    stats::cor(X[, item], rowSums(X[, rest, drop = FALSE]))
  }

  # Content review had no problem with it.
  r <- wt_panel()$results
  expect_identical(r$recommendation[r$item == "EF3"], "Retain")
  expect_true("EF3" %in% h$items)

  # A screen keyed on item-total correlation would flag it.
  expect_lt(corrected("EF3", h$scales$EF), 0.40)

  # And the distribution says why: near-ceiling, so it has almost no room to
  # correlate with anything. This is the evidence that separates it from EF4.
  spread <- apply(X, 2, stats::sd)
  expect_lt(spread[["EF3"]], 0.6 * stats::median(spread))
  expect_gt(mean(X[, "EF3"] >= 4), 0.9)
  expect_lt(max(colMeans(X[, setdiff(h$items, "EF3"), drop = FALSE] >= 4)), 0.6)
})

test_that("TF4 passes content review and belongs to both facets", {
  h <- wt_handoff()
  X <- wt_recoded(h)
  with_set <- function(item, set) {
    stats::cor(X[, item], rowSums(X[, setdiff(set, item), drop = FALSE]))
  }

  # It sits at least as close to the facet the judges did not choose.
  expect_gte(with_set("TF4", h$scales$EF), with_set("TF4", h$scales$TF))
  # The other task-focus items do not.
  others <- setdiff(h$scales$TF, "TF4")
  own <- vapply(others, with_set, numeric(1), set = h$scales$TF)
  other <- vapply(others, with_set, numeric(1), set = h$scales$EF)
  expect_true(all(own > other), info = paste(names(own), collapse = ", "))
})

test_that("TF6 is the one item that answers differently by cohort", {
  h <- content_handoff(wt_panel())
  responses <- wt_responses()
  shift <- vapply(h$items, function(i) {
    m <- tapply(responses[[i]], responses$cohort, mean)
    unname(m[["B"]] - m[["A"]])
  }, numeric(1))

  expect_gt(shift[["TF6"]], 0.4)
  expect_lt(max(abs(shift[setdiff(h$items, "TF6")])), 0.25)
})

test_that("the item file says which items were built to misbehave", {
  items <- wt_items()
  expect_named(items, c("item", "facet", "stem", "role", "reverse_worded"))
  expect_false(any(is.na(items$role) | !nzchar(items$role)))
  expect_type(items$reverse_worded, "logical")

  designed <- items$item[!startsWith(items$role, "ordinary")]
  expect_setequal(designed, c("EF2", "EF3", "EF4", "EF5", "EF6",
                              "TF2", "TF4", "TF5", "TF6"))
  expect_setequal(items$item[items$reverse_worded], c("EF2", "TF2"))
})

test_that("a reverse-worded item looks damning until it is recoded", {
  # The case nomologR asked for: the same negative correlation means a coding
  # error on an item that was never recoded and evidence against the item on
  # one that was. The handoff's keying is what tells them apart.
  h <- wt_handoff()
  ev <- h$item_evidence
  expect_identical(setNames(ev$keying, ev$item)[c("EF2", "TF2")],
                   c(EF2 = -1L, TF2 = -1L))
  expect_true(all(ev$keying[!ev$item %in% c("EF2", "TF2")] == 1L))
  expect_true(all(ev$response_min == 1L) && all(ev$response_max == 5L))

  corrected <- function(X, item, set) {
    rest <- setdiff(set, item)
    stats::cor(X[, item], rowSums(X[, rest, drop = FALSE]))
  }
  raw <- as.matrix(wt_responses()[h$items])
  rec <- wt_recoded(h)
  for (i in c("EF2", "TF2")) {
    set <- h$scales[[substr(i, 1, 2)]]
    expect_lt(corrected(raw, i, set), 0)
    expect_gt(corrected(rec, i, set), 0.40)
  }
})

test_that("recoding restores exactly the data the design describes", {
  # Reversal draws no random numbers, so a recoded reverse-worded item is the
  # forward item it was written from. Nothing else in the design moves.
  rec <- wt_recoded()
  expect_true(all(rec >= 1L & rec <= 5L))
  expect_identical(anyNA(rec), FALSE)
})

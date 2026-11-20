# Tests for the branches of content_handoff(), content_evidence() and the
# rating-distribution view that covr 4.0.0 still found unrun after the first
# round, and for three corrections: the refusal of a handoff with nothing to
# show, the flow box of a stage whose judge counts were not recorded, and the
# panel note when the agreement bootstrap was skipped. Most of the branches
# are reached only by an object edited by hand or by a direct call to the
# helper, and the tests build that input.

extdata <- function(f) system.file("extdata", f, package = "contentvalidR")

# Four experts rate four items, as in the content_evidence() examples.
relevance_panel <- function() {
  m <- matrix(c(4, 4, 4, 3, 4, 4, 3, 4, 3, 4, 4, 4, 2, 2, 1, 2), nrow = 4,
              dimnames = list(NULL, paste0("Item", 1:4)))
  expert_validity(m, mode = "relevance", lo = 1, hi = 4, agreement = "none")
}

# Twelve judges sort three items, as in the content_evidence() examples.
item_sort <- function() {
  sort_validity(data.frame(
    item = rep(paste0("Item", 1:3), each = 12),
    rater = rep(1:12, 3),
    target_construct = rep(c("A", "A", "B"), each = 12),
    assigned_construct = c(rep("A", 11), "B", rep("A", 10), "B", "B",
                           rep("B", 5), rep("A", 7))
  ))
}

# ---- content_evidence() ----------------------------------------------------

test_that("a handoff with nothing to show is refused in plain English", {
  panel <- content_handoff(relevance_panel())
  panel$provenance$mode <- "coverage"
  expect_error(content_evidence(panel),
               paste("^This expert-panel handoff carries no statistic",
                     "content_evidence\\(\\) can show\\.$"))
  sorts <- content_handoff(item_sort())
  sorts$item_statistics <-
    sorts$item_statistics[sorts$item_statistics$statistic != "Psa", ]
  expect_error(content_evidence(Sort = sorts),
               paste("^This item-sort handoff carries no statistic",
                     "content_evidence\\(\\) can show\\.$"))
})

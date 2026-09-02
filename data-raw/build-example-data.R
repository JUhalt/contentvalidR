# Build the human-readable example datasets shipped in inst/extdata.
#
# This script uses only base R and is deterministic. Re-run it from the package
# root whenever the example data need to be regenerated.

out_dir <- file.path("inst", "extdata")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# Item-sort example: 6 items, 20 judges, three construct choices.
# -----------------------------------------------------------------------------
make_sort_item <- function(item, target, assignments) {
  data.frame(
    item = item,
    rater = seq_along(assignments),
    target_construct = target,
    assigned_construct = assignments,
    stringsAsFactors = FALSE
  )
}

sort_example <- do.call(rbind, list(
  make_sort_item("A1", "A", c(rep("A", 18), "B", "C")),
  make_sort_item("A2", "A", c(rep("A", 15), rep("B", 3), rep("C", 2))),
  make_sort_item("B1", "B", c(rep("B", 17), rep("A", 2), "C")),
  make_sort_item("B2", "B", c(rep("B", 13), rep("A", 5), rep("C", 2))),
  make_sort_item("C1", "C", c(rep("C", 18), "A", "B")),
  make_sort_item("C2", "C", c(rep("C", 14), rep("B", 4), rep("A", 2)))
))
write.csv(sort_example, file.path(out_dir, "sort_example.csv"), row.names = FALSE, quote = FALSE)

# -----------------------------------------------------------------------------
# Construct-rating example: 6 items, 24 judges, three construct definitions.
# Ratings are deterministic 1-5 patterns so examples never depend on RNG state.
# -----------------------------------------------------------------------------
patterns <- list(
  strong = c(5, 4, 5, 4, 5, 5),
  moderate = c(4, 4, 3, 4, 4, 3),
  low = c(2, 2, 1, 2, 2, 1),
  mid = c(2, 3, 2, 2, 3, 2),
  overlap = c(3, 3, 4, 3, 3, 4)
)

target <- c(A1 = "A", A2 = "A", B1 = "B", B2 = "B", C1 = "C", C2 = "C")
profile <- c(
  "A1:A" = "strong",   "A1:B" = "low",     "A1:C" = "mid",
  "A2:A" = "moderate", "A2:B" = "overlap", "A2:C" = "mid",
  "B1:A" = "low",      "B1:B" = "strong",  "B1:C" = "mid",
  "B2:A" = "overlap",  "B2:B" = "moderate","B2:C" = "mid",
  "C1:A" = "low",      "C1:B" = "mid",     "C1:C" = "strong",
  "C2:A" = "mid",      "C2:B" = "overlap", "C2:C" = "moderate"
)

rating_example <- expand.grid(
  item = names(target),
  rater = 1:24,
  construct = c("A", "B", "C"),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
rating_example$target_construct <- unname(target[rating_example$item])
rating_example$rating <- mapply(function(item, rater, construct) {
  key <- paste(item, construct, sep = ":")
  pat <- patterns[[profile[[key]]]]
  pat[(rater - 1L) %% length(pat) + 1L]
}, rating_example$item, rating_example$rater, rating_example$construct)
write.csv(rating_example, file.path(out_dir, "rating_example.csv"), row.names = FALSE, quote = FALSE)

# -----------------------------------------------------------------------------
# Expert relevance example: 8 experts x 5 items on a 1-4 relevance scale.
# -----------------------------------------------------------------------------
expert_relevance_example <- data.frame(
  expert = 1:8,
  Item1 = c(4,4,4,4,4,4,4,4),
  Item2 = c(4,4,4,4,3,4,4,3),
  Item3 = c(4,3,4,3,3,4,3,4),
  Item4 = c(3,3,3,2,3,2,3,3),
  Item5 = c(2,2,3,2,2,3,2,2)
)
write.csv(expert_relevance_example,
          file.path(out_dir, "expert_relevance_example.csv"), row.names = FALSE, quote = FALSE)

# -----------------------------------------------------------------------------
# Expert essentiality example: 12 experts x 4 binary items.
# -----------------------------------------------------------------------------
expert_essentiality_example <- data.frame(
  expert = 1:12,
  Item1 = c(rep(1, 11), 0),
  Item2 = c(rep(1, 10), rep(0, 2)),
  Item3 = c(rep(1, 8), rep(0, 4)),
  Item4 = c(rep(1, 6), rep(0, 6))
)
write.csv(expert_essentiality_example,
          file.path(out_dir, "expert_essentiality_example.csv"), row.names = FALSE, quote = FALSE)

# -----------------------------------------------------------------------------
# Expert congruence example: 3 items x 6 experts x 3 objectives.
# -----------------------------------------------------------------------------
congruence_patterns <- list(
  "I1:A" = c(1,1,1,1,1,1),   "I1:B" = c(-1,-1,0,-1,0,-1), "I1:C" = rep(-1, 6),
  "I2:A" = c(-1,-1,-1,0,-1,0), "I2:B" = c(1,1,1,1,1,1),   "I2:C" = c(-1,-1,-1,-1,0,-1),
  "I3:A" = c(-1,0,-1,-1,0,-1), "I3:B" = c(1,0,1,0,1,0),    "I3:C" = c(1,1,1,1,0,1)
)
congruence_target <- c(I1 = "A", I2 = "B", I3 = "C")
expert_congruence_example <- expand.grid(
  item = names(congruence_target),
  judge = 1:6,
  objective = c("A", "B", "C"),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
expert_congruence_example$target_objective <- unname(congruence_target[expert_congruence_example$item])
expert_congruence_example$score <- mapply(function(item, judge, objective) {
  congruence_patterns[[paste(item, objective, sep = ":")]][judge]
}, expert_congruence_example$item, expert_congruence_example$judge,
   expert_congruence_example$objective)
write.csv(expert_congruence_example,
          file.path(out_dir, "expert_congruence_example.csv"), row.names = FALSE, quote = FALSE)

message("Rebuilt example datasets in ", normalizePath(out_dir, winslash = "/"))

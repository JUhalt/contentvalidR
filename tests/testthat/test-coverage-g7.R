# Tests for branches of content_structure(), similarity_from_sort(),
# domain_validity(), the content map and gtheory_content() that covr 4.0.0
# found no test running. They are grouped by the function they exercise.

# The nine-item similarity ratings from the content_structure() examples:
# three items written for each of three blueprint cells.
g7_similarity <- function() {
  items <- paste0("I", 1:9)
  matrix(c(
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
}

g7_blueprint <- function() {
  rep(c("Autonomy", "Competence", "Relatedness"), each = 3)
}

# Printed text with its line breaks and indents collapsed to single spaces,
# so a check does not depend on where a sentence wraps.
g7_printed <- function(x) {
  gsub("[[:space:]]+", " ", paste(utils::capture.output(print(x)),
                                  collapse = " "))
}

# Draws `expr` on a null PDF device and records what reaches base graphics:
# the colors and symbols of each set of points (plot.xy draws both the
# map's points and the key's symbols) and the title, labels and colors of
# each key (legend). Returns those with the value of `expr` and whether it
# was visible.
g7_map_drawing <- function(expr) {
  sink <- new.env()
  sink$points <- list()
  sink$keys <- list()
  add_points <- function(col, pch) {
    sink$points[[length(sink$points) + 1L]] <- list(col = col, pch = pch)
  }
  add_key <- function(title, labels, col) {
    sink$keys[[length(sink$keys) + 1L]] <-
      list(title = title, labels = labels, col = col)
  }
  ns <- asNamespace("graphics")
  suppressMessages({
    trace("plot.xy", bquote(.(add_points)(col, pch)), print = FALSE,
          where = ns)
    trace("legend", bquote(.(add_key)(title, legend, col)), print = FALSE,
          where = ns)
  })
  on.exit(suppressMessages({
    untrace("plot.xy", where = ns)
    untrace("legend", where = ns)
  }), add = TRUE)
  grDevices::pdf(NULL, width = 7, height = 5)
  on.exit(grDevices::dev.off(), add = TRUE)
  shown <- withVisible(force(expr))
  list(points = sink$points, keys = sink$keys, value = shown$value,
       visible = shown$visible)
}

# content_structure() ----------------------------------------------------

test_that("a similarity matrix held as text is refused as not numeric", {
  sim <- g7_similarity()
  as_text <- sim
  storage.mode(as_text) <- "character"
  expect_error(content_structure(as_text, membership = g7_blueprint()),
               "`similarity` must be numeric", fixed = TRUE)
})

test_that("distances given directly give the map their similarities give", {
  sim <- g7_similarity()
  # The documented conversion: distance = max(similarity) - similarity.
  dist_mat <- max(sim) - sim
  diag(dist_mat) <- 0

  from_sim <- content_structure(sim, membership = g7_blueprint())
  from_dist <- content_structure(dist_mat, membership = g7_blueprint(),
                                 similarity_is_distance = TRUE)
  expect_true(from_dist$settings$similarity_is_distance)
  expect_equal(from_dist$coordinates, from_sim$coordinates)
  expect_identical(from_dist$clusters$cluster, from_sim$clusters$cluster)
  expect_equal(from_dist$fit, from_sim$fit)
  expect_identical(from_dist$adjusted_rand, from_sim$adjusted_rand)
})

test_that("a negative distance is refused, naming the distance setting", {
  dist_mat <- max(g7_similarity()) - g7_similarity()
  diag(dist_mat) <- 0
  dist_mat[1, 2] <- dist_mat[2, 1] <- -1
  expect_error(content_structure(dist_mat, similarity_is_distance = TRUE),
               paste("Converted distances are negative;",
                     "check `similarity_is_distance`"),
               fixed = TRUE)
})

test_that("one item per cell and per cluster leaves the index undefined", {
  # Three items, each its own blueprint cell, so k defaults to three
  # clusters of one. No pair of items shares a group on either side, so the
  # adjusted Rand index is 0 / 0 (Hubert & Arabie, 1985): undefined, not 0.
  sim <- g7_similarity()[1:3, 1:3]
  fit <- content_structure(sim, membership = c("A", "B", "C"))
  expect_identical(fit$settings$k, 3L)
  expect_identical(sort(fit$clusters$cluster), 1:3)
  expect_true(is.na(fit$adjusted_rand))
  expect_identical(fit$status, "Insufficient data")
  expect_output(print(fit), "Adjusted Rand index: not defined", fixed = TRUE)

  # The same holds for the index itself on any two all-singleton partitions.
  expect_true(is.na(contentvalidR:::.adjusted_rand(c("A", "B", "C", "D"),
                                                   1:4)))
})

# print.contentvalid_structure() -------------------------------------------

test_that("a structure saved before ari_cut existed prints with the .60 rule", {
  # Objects from releases up to 0.10.1 have no settings$ari_cut. They print
  # with the default criterion, .60, exactly as a current default fit does.
  fit <- content_structure(g7_similarity(), membership = g7_blueprint())
  old <- fit
  old$settings$ari_cut <- NULL
  expect_null(old$settings$ari_cut)
  expect_identical(utils::capture.output(print(old)),
                   utils::capture.output(print(fit)))
  expect_match(g7_printed(old),
               "adjusted Rand index >= .60, a contentvalidR convention",
               fixed = TRUE)
})

# similarity_from_sort() ---------------------------------------------------

test_that("a judge who sorted only one item adds nothing to any pair", {
  sorts <- data.frame(
    item = c("I1", "I2", "I3", "I1", "I2", "I3", "I1"),
    rater = c("R1", "R1", "R1", "R2", "R2", "R2", "R3"),
    assigned_construct = c("A", "A", "B", "A", "B", "B", "A")
  )
  with_r3 <- similarity_from_sort(sorts)
  without_r3 <- similarity_from_sort(sorts[sorts$rater != "R3", ])
  expect_identical(with_r3, without_r3)

  # By hand from R1 and R2: I1-I2 together once in two, I1-I3 never,
  # I2-I3 once in two.
  expect_equal(with_r3["I1", "I2"], 0.5)
  expect_equal(with_r3["I1", "I3"], 0)
  expect_equal(with_r3["I2", "I3"], 0.5)
  n_pairs <- attr(with_r3, "n_pairs")
  expect_identical(n_pairs[upper.tri(n_pairs)], rep(2L, 3))
})

test_that("items never sorted by a common judge stop the similarity build", {
  # R1 sorted I1 and I2, R2 sorted I3 and I4, so no judge saw I1 with I3.
  sorts <- data.frame(
    item = c("I1", "I2", "I3", "I4"),
    rater = c("R1", "R1", "R2", "R2"),
    assigned_construct = c("A", "A", "B", "B")
  )
  expect_error(similarity_from_sort(sorts),
               paste("never sorted by a common judge, so their similarity",
                     "is undefined"),
               fixed = TRUE)
})

# domain_validity() and its summary ----------------------------------------

test_that("an unnamed similarity matrix is paired with the items by position", {
  assignments <- data.frame(item = paste0("I", 1:9), cell = g7_blueprint())
  fit <- domain_validity(assignments, similarity = unname(g7_similarity()))
  cs <- fit$details$structure
  expect_s3_class(cs, "contentvalid_structure")
  expect_identical(cs$clusters$blueprint_cell, assignments$cell)
  # Positional pairing gives the same structure as naming the blueprint.
  ref <- content_structure(g7_similarity(), membership = g7_blueprint())
  expect_identical(cs$adjusted_rand, ref$adjusted_rand)
  expect_identical(fit$scale_summary$adjusted_rand, ref$adjusted_rand)
})

test_that("the coverage summary explains the content structure beneath it", {
  assignments <- data.frame(item = paste0("I", 1:9), cell = g7_blueprint())
  fit <- domain_validity(assignments, similarity = g7_similarity())
  out <- utils::capture.output(print(summary(fit)))
  heading <- which(out == "Content structure")
  expect_length(heading, 1L)
  # The structure's own interpretation follows the heading, indented.
  expect_match(out[heading + 1L], "^  Expert-perceived item groupings")
  expect_match(g7_printed(summary(fit)),
               "Expert-perceived item groupings correspond to the blueprint",
               fixed = TRUE)
})

# plot.contentvalid_structure() and plot.contentvalid_domain() -------------

test_that("a map without a blueprint keys its symbols by recovered cluster", {
  fit <- content_structure(g7_similarity())
  drawn <- g7_map_drawing(plot(fit))
  expect_false(drawn$visible)
  expect_identical(drawn$value, fit)
  expect_length(drawn$keys, 1L)
  expect_identical(drawn$keys[[1]]$title, "Cluster")
  expect_setequal(setdiff(drawn$keys[[1]]$labels, ""), c("1", "2"))
  # Cluster j is drawn with symbol j, the first of the default symbols.
  expect_identical(as.integer(drawn$points[[1]]$pch), fit$clusters$cluster)
})

test_that("one color per cell colors both the points and the key", {
  fit <- content_structure(g7_similarity(), membership = g7_blueprint())
  cell_cols <- c("red", "blue", "darkgreen")
  cells <- sort(unique(g7_blueprint()))
  drawn <- g7_map_drawing(plot(fit, col = cell_cols))
  expect_identical(drawn$value, fit)

  # Each item takes its cell's color, cells in alphabetical order.
  expect_identical(drawn$points[[1]]$col,
                   cell_cols[match(g7_blueprint(), cells)])
  key <- drawn$keys[[1]]
  expect_identical(key$title, "Blueprint cell")
  expect_identical(key$col[match(cells, key$labels)], cell_cols)
})

test_that("plotting a coverage analysis with a map points to the map", {
  assignments <- data.frame(item = paste0("I", 1:9), cell = g7_blueprint())
  fit <- domain_validity(assignments, similarity = g7_similarity())
  devices <- grDevices::dev.list()
  expect_error(plot(fit),
               "Its content map is drawn with plot(x$details$structure)",
               fixed = TRUE)
  # The error comes before any device is opened.
  expect_identical(grDevices::dev.list(), devices)
})

# gtheory_content() --------------------------------------------------------

g7_ratings <- function() {
  r <- rbind(
    c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
    c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(4, 3, 4, 3, 1, 2),
    c(4, 4, 3, 4, 2, 2), c(3, 3, 3, 2, 1, 1)
  )
  dimnames(r) <- list(paste0("Judge", 1:8), paste0("Item", 1:6))
  r
}

test_that("the printout counts the judges dropped for incomplete ratings", {
  complete <- g7_ratings()
  ratings <- rbind(complete, Judge9 = c(4, NA, 3, 4, 2, 2))
  fit <- gtheory_content(ratings, na.rm = TRUE)
  expect_identical(fit$design$n_judges_dropped, 1L)
  expect_identical(fit$design$n_judges_input, 9L)
  # The analysis is that of the eight complete judges.
  expect_equal(fit$coefficients, gtheory_content(complete)$coefficients)
  expect_output(print(fit), "Judges dropped for incomplete ratings: 1 of 9",
                fixed = TRUE)
})

test_that("an analysis saved before phi_cut existed prints with the .80 rule", {
  # Objects from releases up to 0.10.1 have no settings$phi_cut. They print
  # with the default criterion, .80, exactly as a current default fit does.
  fit <- gtheory_content(g7_ratings())
  old <- fit
  old$settings$phi_cut <- NULL
  expect_null(old$settings$phi_cut)
  expect_identical(utils::capture.output(print(old)),
                   utils::capture.output(print(fit)))
  expect_match(g7_printed(old),
               "criterion: Phi >= .80, a contentvalidR convention",
               fixed = TRUE)
})

test_that("barely distinguished items make high targets unreachable", {
  # Six judges rate four items. The items differ a little, so the item
  # component is positive, but far less than the residual.
  ratings <- matrix(c(2, 2, 2, 3, 1, 1,
                      1, 1, 4, 4, 4, 2,
                      2, 4, 3, 3, 2, 4,
                      3, 1, 4, 2, 4, 1), 6, 4,
                    dimnames = list(paste0("Judge", 1:6), paste0("Item", 1:4)))
  fit <- gtheory_content(ratings)

  # Independent variance components from a two-way ANOVA (Brennan, 2001):
  # item = (MS_item - MS_res) / n_judges, judge = (MS_judge - MS_res) /
  # n_items, each truncated at 0.
  long <- data.frame(rating = as.vector(ratings),
                     judge = factor(rep(rownames(ratings), times = 4)),
                     item = factor(rep(colnames(ratings), each = 6)))
  tab <- stats::anova(stats::lm(rating ~ item + judge, data = long))
  ms <- tab[["Mean Sq"]]
  names(ms) <- trimws(rownames(tab))
  var_item <- (ms[["item"]] - ms[["Residuals"]]) / 6
  var_judge <- max(0, (ms[["judge"]] - ms[["Residuals"]]) / 4)
  var_res <- ms[["Residuals"]]
  expect_gt(var_item, 0)

  # Judges needed: target * error / (item * (1 - target)), rounded up, and
  # unreachable beyond a panel of 1000.
  needed <- function(target, error) {
    n <- target * error / (var_item * (1 - target))
    ifelse(n > 1000, NA_integer_, as.integer(ceiling(n)))
  }
  targets <- c(0.70, 0.80, 0.90)
  expect_identical(fit$judges_needed$n_judges_relative,
                   needed(targets, var_res))
  expect_identical(fit$judges_needed$n_judges_absolute,
                   needed(targets, var_judge + var_res))
  expect_identical(fit$judges_needed$n_judges_relative, c(593L, NA, NA))

  printed <- g7_printed(fit)
  expect_match(printed, ".80 unreachable unreachable", fixed = TRUE)
  expect_match(printed, paste("Unreachable: no panel of 1000 or fewer judges",
                              "reaches this target, because the judges",
                              "barely distinguish the items"), fixed = TRUE)
  expect_false(grepl("with no item variance", printed, fixed = TRUE))
})

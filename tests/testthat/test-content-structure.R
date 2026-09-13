# Independent adjusted Rand index by explicit pair counting, used as an external
# check on the contingency-table implementation:
#   ARI = 2(ad - bc) / ((a+b)(b+d) + (a+c)(c+d))
ari_by_pairs <- function(x, y) {
  n <- length(x)
  a <- b <- cc <- dd <- 0
  for (i in seq_len(n - 1L)) {
    for (j in seq(i + 1L, n)) {
      same_x <- x[i] == x[j]
      same_y <- y[i] == y[j]
      if (same_x && same_y) a <- a + 1
      if (same_x && !same_y) b <- b + 1
      if (!same_x && same_y) cc <- cc + 1
      if (!same_x && !same_y) dd <- dd + 1
    }
  }
  (2 * (a * dd - b * cc)) / ((a + b) * (b + dd) + (a + cc) * (cc + dd))
}

block_similarity <- function() {
  items <- paste0("I", 1:6)
  sim <- matrix(1, 6, 6, dimnames = list(items, items))
  sim[1:3, 1:3] <- 5
  sim[4:6, 4:6] <- 5
  diag(sim) <- 5
  sim
}

test_that("adjusted Rand index matches an independent pair-counting formula", {
  set.seed(404)
  for (i in 1:10) {
    n <- sample(8:20, 1)
    x <- sample(letters[1:sample(2:4, 1)], n, replace = TRUE)
    y <- sample(seq_len(sample(2:4, 1)), n, replace = TRUE)
    expect_equal(contentvalidR:::.adjusted_rand(x, y), ari_by_pairs(x, y),
                 tolerance = 1e-10)
  }
})

test_that("adjusted Rand index has its defining properties", {
  p <- rep(c("A", "B", "C"), each = 5)
  expect_equal(contentvalidR:::.adjusted_rand(p, p), 1)
  # Invariant to cluster relabelling.
  expect_equal(contentvalidR:::.adjusted_rand(p, rep(c(3, 1, 2), each = 5)), 1)
  # Chance agreement scores 0, not something positive.
  expect_equal(contentvalidR:::.adjusted_rand(p, rep(1, 15)), 0)

  set.seed(7)
  random_ari <- replicate(500, contentvalidR:::.adjusted_rand(p, sample(p)))
  expect_lt(abs(mean(random_ari)), 0.05)

  # Undefined when neither partition separates anything.
  expect_true(is.na(contentvalidR:::.adjusted_rand(rep(1, 6), rep(1, 6))))
  expect_true(is.na(contentvalidR:::.adjusted_rand(1, 1)))
})

test_that("clean block structure is recovered exactly", {
  blueprint <- c(rep("Autonomy", 3), rep("Competence", 3))
  cs <- content_structure(block_similarity(), membership = blueprint)

  expect_s3_class(cs, "contentvalid_structure")
  expect_equal(cs$adjusted_rand, 1)
  expect_equal(cs$status, "Supported")
  expect_equal(length(unique(cs$clusters$cluster)), 2L)
  # Items in the same blueprint cell land in the same cluster.
  expect_equal(length(unique(cs$clusters$cluster[1:3])), 1L)
  expect_equal(length(unique(cs$clusters$cluster[4:6])), 1L)
  expect_false(cs$clusters$cluster[1] == cs$clusters$cluster[4])
})

test_that("a noisy three-facet blueprint is still recovered", {
  set.seed(21)
  cells <- rep(c("Know", "Skill", "Attitude"), each = 4)
  items <- paste0("Q", seq_along(cells))
  S <- outer(cells, cells, function(a, b) ifelse(a == b, 4, 1))
  S <- S + matrix(stats::rnorm(length(S), 0, 0.35), nrow = nrow(S))
  S <- (S + t(S)) / 2
  diag(S) <- 5
  dimnames(S) <- list(items, items)

  cs <- content_structure(S, membership = cells)
  expect_gt(cs$adjusted_rand, 0.6)
  expect_equal(cs$status, "Supported")
  expect_equal(dim(cs$cross_tab), c(3L, 3L))
})

test_that("structure unrelated to the blueprint is flagged, not endorsed", {
  set.seed(5)
  items <- paste0("I", 1:9)
  S <- matrix(stats::runif(81, 1, 5), 9, 9)
  S <- (S + t(S)) / 2
  diag(S) <- 5
  dimnames(S) <- list(items, items)
  membership <- rep(c("A", "B", "C"), each = 3)

  cs <- content_structure(S, membership = membership)
  expect_lt(cs$adjusted_rand, 0.6)
  expect_equal(cs$status, "Review")
  # Weak correspondence must not be presented as grounds for deleting items.
  expect_match(cs$interpretation, "not by\\s+itself a reason to delete items")
})

test_that("no blueprint yields descriptive output rather than a verdict", {
  cs <- content_structure(block_similarity())
  expect_equal(cs$status, "Descriptive only")
  expect_true(is.na(cs$adjusted_rand))
  expect_null(cs$cross_tab)
  expect_match(cs$interpretation, "No blueprint was supplied")
})

test_that("fit is reported across dimensionalities with descriptive labels", {
  cs <- content_structure(block_similarity(), membership = rep(c("A", "B"), each = 3))
  expect_true(all(c("dims", "stress", "gof", "fit_label") %in% names(cs$fit)))
  expect_true(all(cs$fit$stress >= 0 | is.na(cs$fit$stress)))
  # Stress cannot increase as dimensions are added.
  s <- cs$fit$stress[!is.na(cs$fit$stress)]
  expect_true(all(diff(s) <= 1e-8))

  printed <- paste(capture.output(print(cs)), collapse = " ")
  expect_match(printed, "descriptive conventions, not rules")
})

test_that("requested dimensionality is capped at what the data supports and reported", {
  sim <- block_similarity()
  cs <- content_structure(sim, dims = 4)
  expect_lte(cs$settings$dims, cs$design$n_dimensions_available)
  expect_equal(cs$settings$dims_requested, 4L)
  expect_equal(ncol(cs$coordinates), cs$settings$dims)
})

test_that("content_structure rejects malformed similarity input", {
  sim <- block_similarity()
  expect_error(content_structure(matrix(1:6, nrow = 2)), "square")
  expect_error(content_structure(matrix(1, 2, 2)), "at least three items")

  asym <- sim
  asym[1, 2] <- 99
  expect_error(content_structure(asym), "symmetric")

  na_sim <- sim
  na_sim[1, 2] <- na_sim[2, 1] <- NA
  expect_error(content_structure(na_sim), "missing values")

  inf_sim <- sim
  inf_sim[1, 2] <- inf_sim[2, 1] <- Inf
  expect_error(content_structure(inf_sim), "infinite")

  expect_error(content_structure(sim, dims = 0), "between 1 and")
  expect_error(content_structure(sim, k = 99), "between 1 and")
  expect_error(content_structure(sim, membership = c("A", "B")), "one entry per item")
  expect_error(content_structure(sim, max_dims = 0), "positive integer")
})

test_that("similarity_from_sort computes co-assignment proportions", {
  sorts <- data.frame(
    item = rep(paste0("I", 1:4), each = 5),
    rater = rep(1:5, times = 4),
    assigned_construct = c(rep("A", 5), c("A", "A", "A", "B", "A"),
                           rep("B", 5), rep("B", 5)),
    stringsAsFactors = FALSE
  )
  sim <- similarity_from_sort(sorts)

  expect_equal(dim(sim), c(4L, 4L))
  expect_equal(sim, t(sim), ignore_attr = TRUE)
  expect_equal(diag(sim), c(I1 = 1, I2 = 1, I3 = 1, I4 = 1))
  # Four of five judges put I1 and I2 together.
  expect_equal(sim["I1", "I2"], 0.8)
  # I1 and I3 never shared a construct.
  expect_equal(sim["I1", "I3"], 0)
  expect_equal(sim["I3", "I4"], 1)
  expect_equal(attr(sim, "n_pairs")["I1", "I2"], 5L, ignore_attr = TRUE)
})

test_that("similarity_from_sort rejects malformed sort data", {
  ok <- data.frame(
    item = rep(paste0("I", 1:3), each = 2),
    rater = rep(1:2, times = 3),
    assigned_construct = rep("A", 6),
    stringsAsFactors = FALSE
  )
  expect_error(similarity_from_sort(ok[0, ]), "at least one row")
  expect_error(similarity_from_sort(ok, item_col = "nope"), "missing required column")

  dup <- rbind(ok, ok[1, ])
  expect_error(similarity_from_sort(dup), "only once")

  two_items <- ok[ok$item %in% c("I1", "I2"), ]
  expect_error(similarity_from_sort(two_items), "[Aa]t least three items")
})

test_that("sort-derived similarity feeds the structure analysis", {
  raters <- 1:6
  items <- paste0("I", 1:6)
  truth <- rep(c("A", "B"), each = 3)
  rows <- do.call(rbind, lapply(raters, function(r) {
    data.frame(item = items, rater = r, assigned_construct = truth,
               stringsAsFactors = FALSE)
  }))
  sim <- similarity_from_sort(rows)
  cs <- content_structure(sim, membership = truth)
  expect_equal(cs$adjusted_rand, 1)
})

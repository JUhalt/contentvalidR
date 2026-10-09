# Fixes from the audit before 1.0: judges, generalizability, content
# structure, domain coverage, and the two-by-two comparators.

shown <- function(x, ...) {
  old <- options(width = 80)
  on.exit(options(old), add = TRUE)
  utils::capture.output(print(x, ...))
}

flat <- function(x, ...) gsub("[[:space:]]+", " ", paste(shown(x, ...), collapse = "\n"))

varied_panel <- function() {
  r <- rbind(
    c(4, 4, 3, 4, 3, 2, 3, 2, 4, 3), c(4, 3, 4, 3, 2, 3, 2, 3, 4, 2),
    c(3, 4, 4, 3, 3, 2, 2, 2, 3, 3), c(4, 4, 3, 2, 3, 3, 3, 1, 4, 2),
    c(4, 3, 3, 4, 2, 2, 3, 2, 3, 3), c(3, 4, 4, 3, 3, 3, 2, 3, 4, 1),
    c(4, 4, 4, 4, 3, 2, 3, 2, 4, 3), c(3, 2, 3, 2, 2, 1, 2, 1, 2, 2)
  )
  dimnames(r) <- list(paste0("Judge", 1:8), paste0("Item", 1:10))
  r
}

three_cells <- function() {
  items <- paste0("I", 1:9)
  matrix(c(
    5, 4, 4, 2, 2, 1, 1, 2, 1,
    4, 5, 4, 2, 1, 2, 2, 1, 1,
    4, 4, 5, 1, 2, 2, 1, 1, 2,
    2, 2, 1, 5, 4, 4, 2, 2, 1,
    2, 1, 2, 4, 5, 4, 1, 2, 2,
    1, 2, 2, 4, 4, 5, 2, 1, 2,
    1, 2, 1, 2, 1, 2, 5, 4, 4,
    2, 1, 1, 2, 2, 1, 4, 5, 4,
    1, 1, 2, 1, 2, 2, 4, 4, 5
  ), 9, 9, dimnames = list(items, items))
}

# ---- judge_validity: fragile items ------------------------------------------

test_that("a three-judge panel flags nobody and checks no item", {
  # Removing one of three judges leaves two, where Lynn's table has no
  # criterion. That is "cannot be checked", never "changes status".
  fit <- judge_validity(rbind(c(4, 4, 3, 2), c(4, 3, 4, 2), c(3, 4, 4, 1)))
  expect_true(all(fit$results$status == "Supported"))
  expect_true(all(is.na(fit$results$n_items_flipped)))
  items <- fit$details$influence_items
  expect_true(all(is.na(items$fragile)))
  expect_identical(fit$scale_summary$n_fragile_items, 0L)
  expect_identical(fit$scale_summary$n_items_unchecked, 4L)
  out <- flat(fit)
  expect_match(out, "3 of 3 judges are consistent with the panel.", fixed = TRUE)
  expect_match(out, "Not checked: 4 items rated by three or fewer judges",
               fixed = TRUE)
  expect_false(grepl("change review status", out, fixed = TRUE))
})

test_that("an item at the criterion is reported once, with its judges", {
  X <- rbind(c(4, 4, 4), c(4, 4, 4), c(4, 4, 4),
             c(4, 4, 4), c(4, 4, 4), c(2, 4, 4))
  dimnames(X) <- list(paste0("J", 1:6), c("Fragile", "Solid1", "Solid2"))
  fit <- judge_validity(X)
  out <- flat(fit)
  expect_match(out, "6 of 6 judges are consistent with the panel.", fixed = TRUE)
  expect_match(out, "Items whose status changes if one judge is removed", fixed = TRUE)
  expect_match(out, "Fragile 5 of 6 Support J1, J2, J3, J4, J5", fixed = TRUE)
  expect_match(out, "This describes the item, not the judges named",
               fixed = TRUE)
  expect_false(grepl("Influential", out, fixed = TRUE))
  expect_match(flat(summary(fit)), "Fragile 5 of 6 Support J1, J2, J3, J4, J5",
               fixed = TRUE)

  items <- fit$details$influence_items
  expect_identical(names(items), c("item", "n_raters", "n_relevant",
                                   "status_full_panel", "fragile",
                                   "changes_without"))
  expect_identical(items$fragile, c(TRUE, FALSE, FALSE))
})

test_that("a Review item one dissenter short of the criterion names the dissenters", {
  # Five of seven relevant is below Lynn's six of seven; without either
  # dissenter it is five of six, which meets the criterion for six.
  X <- cbind(Item1 = c(4, 4, 4, 4, 4, 2, 2), Item2 = rep(4, 7))
  rownames(X) <- paste0("J", 1:7)
  items <- judge_validity(X)$details$influence_items
  expect_identical(items$status_full_panel, c("Review", "Support"))
  expect_identical(items$fragile, c(TRUE, FALSE))
  expect_identical(items$changes_without[1], "J6, J7")
})

test_that("with missing ratings, an item with three raters is not checked", {
  X <- matrix(4, 6, 3, dimnames = list(paste0("J", 1:6), paste0("I", 1:3)))
  X[4:6, 3] <- NA
  X[1, 1] <- 2
  fit <- judge_validity(X, na.rm = TRUE)
  items <- fit$details$influence_items
  expect_true(is.na(items$fragile[3]))
  expect_identical(items$fragile[1:2], c(TRUE, FALSE))
  # The judges are still counted on the items that could be checked.
  expect_false(anyNA(fit$results$n_items_flipped))
})

# ---- judge_validity: fit flags ----------------------------------------------

test_that("fit statistics are shown and not flagged on a small design", {
  fit <- judge_validity(varied_panel())
  r <- fit$results
  expect_true(fit$scale_summary$severity_estimable)
  # Judge2 and Judge4 sit above 1.5, and nobody is flagged for fit.
  expect_true(any(pmax(r$infit, r$outfit, na.rm = TRUE) > 1.5))
  expect_false(any(r$recommendation %in% c("Erratic", "Too predictable")))
  expect_true(all(r$n_scored < 30))
  out <- flat(fit)
  expect_match(out, "Here the model scored at most 6 of any judge's decisions",
               fixed = TRUE)
  expect_match(out, "so the fit statistics are shown and not flagged", fixed = TRUE)
  expect_match(out, "Linacre (2002)", fixed = TRUE)
  expect_match(r$interpretation[r$judge == "Judge2"],
               "too few for a fit flag", fixed = TRUE)
})

test_that("an erratic judge is flagged once the model scored enough decisions", {
  set.seed(31)
  n_j <- 8; n_i <- 60
  easy <- seq(-2, 2, length.out = n_i)
  p <- stats::plogis(outer(rep(0, n_j), easy, "+"))
  B <- matrix(stats::rbinom(n_j * n_i, 1, as.vector(p)), n_j)
  # The last judge endorses the hard items and rejects the easy ones.
  B[n_j, ] <- as.integer(easy < 0)
  X <- ifelse(B == 1, 4, 2)
  dimnames(X) <- list(paste0("J", 1:n_j), paste0("I", 1:n_i))
  fit <- judge_validity(X)
  r <- fit$results
  expect_true(fit$scale_summary$severity_estimable)
  expect_gte(r$n_scored[n_j], 30L)
  expect_identical(r$recommendation[n_j], "Erratic")
  expect_identical(r$status[n_j], "Review")
  expect_match(r$interpretation[n_j], "Linacre, 2002", fixed = TRUE)
  expect_false(grepl("random variation", r$interpretation[n_j], fixed = TRUE))

  # The same judge is described, not flagged, when the bar is out of reach.
  strict <- judge_validity(X, fit_min_ratings = 1000)
  expect_false(strict$results$recommendation[n_j] == "Erratic")
})

test_that("a judge more predictable than the model expects is never flagged", {
  set.seed(32)
  n_j <- 8; n_i <- 60
  easy <- seq(-2, 2, length.out = n_i)
  p <- stats::plogis(outer(rep(0, n_j), easy, "+"))
  B <- matrix(stats::rbinom(n_j * n_i, 1, as.vector(p)), n_j)
  # A perfect Guttman pattern: every easy item endorsed, every hard one not.
  B[1, ] <- as.integer(easy > 0)
  X <- ifelse(B == 1, 4, 2)
  dimnames(X) <- list(paste0("J", 1:n_j), paste0("I", 1:n_i))
  # A wide upper limit, so the only way out of the range is below it.
  fit <- judge_validity(X, fit_range = c(0.9, 10))
  r <- fit$results
  expect_true(fit$scale_summary$severity_estimable)
  below <- !is.na(r$infit) & pmin(r$infit, r$outfit) < 0.9
  expect_true(below[1])
  expect_true(all(r$n_scored[below] >= 30L))
  expect_false(any(r$recommendation %in% c("Erratic", "Too predictable")))
  expect_match(r$interpretation[1], "which is not a flag", fixed = TRUE)
  # A range the analyst set is not Linacre's, so he is not quoted for it.
  expect_false(grepl("Linacre", r$interpretation[1], fixed = TRUE))
  expect_false(grepl("fixed rule", r$interpretation[1], fixed = TRUE))
})

test_that("the judge decision words have meanings, and the retired ones are gone", {
  words <- names(contentvalidR:::.decision_meanings("judge"))
  expect_false(any(c("Influential", "Too predictable") %in% words))
  fit <- judge_validity(varied_panel())
  expect_true(all(fit$results$recommendation %in% words))
})

# ---- judge_validity: severity -----------------------------------------------

test_that("the bias correction counts judges, not items", {
  set.seed(12)
  X <- ifelse(matrix(stats::rbinom(4 * 40, 1, 0.6), nrow = 4), 4, 2)
  dimnames(X) <- list(paste0("J", 1:4), paste0("I", 1:40))
  fit <- judge_validity(X)
  expect_true(fit$scale_summary$severity_estimable)
  placed <- sum(fit$results$severity_estimable)
  expect_equal(fit$settings$bias_correction, (placed - 1) / placed)
  raw <- judge_validity(X, bias_correct = FALSE)
  expect_equal(fit$results$severity,
               raw$results$severity * fit$settings$bias_correction)
})

test_that("corrected severities recover their true spread on a small panel", {
  skip_on_cran()
  set.seed(1)
  sev <- seq(-1, 1, length.out = 4)
  slope <- function(correct) {
    mean(replicate(25, {
      easy <- stats::rnorm(150, 0.5, 1)
      p <- stats::plogis(outer(rep(1, 4), easy) - outer(sev, rep(1, 150)))
      B <- matrix(stats::rbinom(length(p), 1, p), 4)
      dimnames(B) <- list(paste0("J", 1:4), paste0("I", 1:150))
      est <- contentvalidR:::.facets_severity(B, bias_correct = correct)
      if (!est$estimable) return(NA_real_)
      unname(stats::coef(stats::lm(est$table$severity ~ sev))[2])
    }), na.rm = TRUE)
  }
  # Joint maximum likelihood stretches four judges' severities by about 4/3.
  expect_gt(slope(FALSE), 1.25)
  corrected <- slope(TRUE)
  expect_gt(corrected, 0.9)
  expect_lt(corrected, 1.15)
})

test_that("with missing ratings a judge is compared on the items they rated", {
  RN <- rbind(matrix(rep(c(4, 4, 4, 4, 2, 2), 5), 5, byrow = TRUE),
              c(NA, NA, NA, NA, 2, 2))
  dimnames(RN) <- list(paste0("J", 1:6), paste0("I", 1:6))
  fit <- judge_validity(RN, na.rm = TRUE)
  r <- fit$results
  # J6 rated only the two low items, exactly as everyone else did.
  expect_equal(r$severity_raw[6], 0)
  expect_identical(r$recommendation[6], "Typical")
  out <- flat(fit)
  expect_match(out, "Missing ratings: 4.", fixed = TRUE)
  expect_match(out, "Phi uses the 5 judges who rated every item", fixed = TRUE)

  # A judge who rated only the two high items as 4 and 4 is not penalized for
  # a spread the others also lack on those items.
  RH <- RN
  RH[6, ] <- c(4, 4, NA, NA, NA, NA)
  rh <- judge_validity(RH, na.rm = TRUE)$results
  expect_equal(rh$severity_raw[6], 0)
  expect_false(rh$recommendation[6] == "Low differentiation")
})

test_that("complete ratings give the severity and scale use they always did", {
  X <- varied_panel()
  r <- judge_validity(X)$results
  expect_equal(r$severity_raw, unname(mean(X) - rowMeans(X)))
  sds <- apply(X, 1, stats::sd)
  expect_equal(r$differentiation, unname(sds / stats::median(sds)))
})

# ---- judge_validity: inputs and print ---------------------------------------

test_that("one judge is not a panel", {
  fit <- judge_validity(matrix(c(4, 3, 2, 4), 1))
  expect_identical(fit$results$recommendation, "Insufficient data")
  expect_identical(fit$results$status, "Insufficient data")
  out <- flat(fit)
  expect_match(out, "One judge is not a panel", fixed = TRUE)
  expect_match(out, "Dependability (Phi): not estimable", fixed = TRUE)
  expect_false(grepl("NA%", out, fixed = TRUE))
  expect_false(grepl("1 of 1 judges", out, fixed = TRUE))
})

test_that("repeated judge or item names are refused with the name", {
  X <- matrix(4, 3, 3, dimnames = list(c("a", "a", "b"), paste0("I", 1:3)))
  expect_error(judge_validity(X), "this row name is used more than once: a",
               fixed = TRUE)
  Y <- matrix(4, 3, 3, dimnames = list(paste0("J", 1:3), c("I1", "I1", "I2")))
  expect_error(judge_validity(Y), "this column name is used more than once: I1",
               fixed = TRUE)
  expect_error(judge_validity(matrix(numeric(0), 0, 3)),
               "at least one judge (row) and one item (column)", fixed = TRUE)
})

test_that("the new cuts are arguments, validated and printed", {
  X <- varied_panel()
  expect_error(judge_validity(X, fit_min_ratings = 0), "positive integer")
  expect_error(judge_validity(X, differentiation_cut = -1), "positive number")
  loose <- judge_validity(X, differentiation_cut = 0.95)
  expect_true(any(loose$results$recommendation == "Low differentiation"))
  expect_false(any(judge_validity(X)$results$recommendation == "Low differentiation"))
  expect_match(flat(loose), "scale use is below 0.95", fixed = TRUE)
  out <- flat(judge_validity(X))
  expect_match(out, "These cuts are contentvalidR conventions, not published standards.",
               fixed = TRUE)
  expect_match(out, "Scale: 1 to 4 | Relevant: a rating of 3 or higher",
               fixed = TRUE)
  expect_identical(judge_validity(X)$settings$fit_min_ratings, 30L)
})

test_that("the judges table stays within 80 columns with long names", {
  X <- varied_panel()
  rownames(X) <- paste0("Dr. Kowalski-", 1:8)
  lines <- shown(judge_validity(X))
  expect_lte(max(nchar(lines)), 80L)
  expect_lte(max(nchar(shown(summary(judge_validity(X))))), 80L)
})

test_that("content_report() for judges has no flipped column", {
  rep <- content_report(judge_validity(varied_panel()))
  expect_false("flipped" %in% names(rep))
  expect_true(all(c("logit", "infit", "outfit", "scale use", "decision") %in%
                    names(rep)))
})

# ---- gtheory_content ---------------------------------------------------------

test_that("max_judges = 1 no longer stops the decision study", {
  X <- varied_panel()
  g <- gtheory_content(X, max_judges = 1)
  expect_identical(g$dstudy$n_judges, c(1L, 8L))
})

test_that("phi_cut is an argument, printed beside the status", {
  X <- varied_panel()
  g <- gtheory_content(X)
  expect_identical(g$settings$phi_cut, 0.80)
  out <- flat(g)
  expect_match(out, "(criterion: Phi >= .80, a contentvalidR convention)",
               fixed = TRUE)
  phi <- g$coefficients$phi_coefficient
  expect_identical(gtheory_content(X, phi_cut = phi + 0.01)$status, "Review")
  expect_identical(gtheory_content(X, phi_cut = phi - 0.01)$status, "Supported")
  expect_error(gtheory_content(X, phi_cut = 1), "strictly between 0 and 1")
  # No value is called "moderate": the number is stated against the criterion.
  low <- gtheory_content(X, phi_cut = 0.99)
  expect_false(grepl("moderately", low$interpretation, fixed = TRUE))
  expect_match(low$interpretation, "below the .99 set for this analysis",
               fixed = TRUE)
})

test_that("the zero-item-variance text says where the variance is", {
  # Each judge rates every item alike, and the judges differ: all the
  # variance is between judges and the residual is zero.
  g <- gtheory_content(matrix(rep(c(4, 3, 2, 4, 3), 6), 5, 6))
  expect_identical(g$status, "Descriptive only")
  expect_true(is.na(g$coefficients$g_coefficient))
  expect_equal(g$coefficients$phi_coefficient, 0)
  expect_match(g$interpretation, "all of the variation is between judges",
               fixed = TRUE)
  expect_match(g$interpretation, "the generalizability coefficient is undefined",
               fixed = TRUE)
  expect_false(grepl("Both coefficients are therefore 0", g$interpretation,
                     fixed = TRUE))
  out <- flat(g)
  expect_match(out, "relative, rank ordering): not defined", fixed = TRUE)
  expect_match(out, "with no item variance, no number of judges reaches any target",
               fixed = TRUE)
})

test_that("an insufficient design prints its reason and no empty tables", {
  g <- gtheory_content(matrix(c(4, 3, 2, 4, 3, 1), 1))
  out <- flat(g)
  expect_match(out, "Status: Insufficient data", fixed = TRUE)
  expect_false(grepl("Variance components", out, fixed = TRUE))
  expect_false(grepl("unreachable", out, fixed = TRUE))
  expect_false(grepl("Brennan", out, fixed = TRUE))
  expect_error(gtheory_content(matrix(numeric(0), 0, 4)),
               "at least one judge (row) and one item (column)", fixed = TRUE)
})

# ---- content_structure -------------------------------------------------------

test_that("the clusters come from the map coordinates, so dims matters", {
  sim <- three_cells()
  cs <- content_structure(sim, membership = rep(c("A", "B", "C"), each = 3))
  ref <- stats::cutree(
    stats::hclust(stats::dist(cs$coordinates), method = "average"), k = 3
  )
  expect_identical(cs$clusters$cluster, unname(as.integer(ref)))
  expect_match(cs$settings$method, "adapted from Sireci & Geisinger",
               fixed = TRUE)

  # Random dissimilarities: the partition from the 1-D coordinates differs
  # from the one from the 4-D coordinates in at least one of these.
  set.seed(9)
  differs <- vapply(1:20, function(i) {
    S <- matrix(stats::runif(100, 1, 5), 10, 10)
    S <- (S + t(S)) / 2
    diag(S) <- 5
    a <- content_structure(S, k = 3, dims = 1)$clusters$cluster
    b <- content_structure(S, k = 3, dims = 4)$clusters$cluster
    !isTRUE(all.equal(contentvalidR:::.adjusted_rand(a, b), 1))
  }, logical(1))
  expect_true(any(differs))
})

test_that("a one-cell blueprint leaves nothing to compare", {
  sim <- three_cells()
  cs <- content_structure(sim, membership = rep("Unidimensional", 9))
  expect_true(is.na(cs$adjusted_rand))
  expect_identical(cs$status, "Insufficient data")
  expect_match(flat(cs), "Adjusted Rand index: not defined", fixed = TRUE)
  expect_false(grepl("correspond only weakly", cs$interpretation, fixed = TRUE))

  one_cluster <- content_structure(sim, membership = rep(c("A", "B", "C"), each = 3),
                                   k = 1)
  expect_identical(one_cluster$status, "Insufficient data")

  d <- domain_validity(data.frame(item = rownames(sim), cell = "Unidimensional"),
                       similarity = sim, min_items = 1)
  expect_match(flat(d), "Content structure: adjusted Rand index not defined (Insufficient data)",
               fixed = TRUE)
})

test_that("ari_cut is an argument, printed beside the status", {
  sim <- three_cells()
  bp <- rep(c("A", "B", "C"), each = 3)
  cs <- content_structure(sim, membership = bp)
  expect_identical(cs$settings$ari_cut, 0.60)
  expect_match(flat(cs), "(criterion: adjusted Rand index >= .60, a contentvalidR convention)",
               fixed = TRUE)
  expect_lte(max(nchar(shown(cs))), 80L)
  expect_error(content_structure(sim, membership = bp, ari_cut = 0),
               "above 0 and at most 1")

  # A blueprint that puts one item in the wrong cell: the same index is
  # Supported or Review according to the cut the analyst sets.
  moved <- c("A", "A", "B", "B", "B", "B", "C", "C", "C")
  part <- content_structure(sim, membership = moved)
  expect_gt(part$adjusted_rand, 0)
  expect_lt(part$adjusted_rand, 1)
  expect_identical(content_structure(sim, membership = moved,
                                     ari_cut = part$adjusted_rand)$status,
                   "Supported")
  strict <- content_structure(sim, membership = moved, ari_cut = 1)
  expect_identical(strict$status, "Review")
  expect_match(strict$interpretation, "below the 1.00 set for this analysis",
               fixed = TRUE)
})

test_that("membership names must be the item names", {
  sim <- three_cells()
  bp <- rep(c("A", "B", "C"), each = 3)
  named <- stats::setNames(bp, rownames(sim))
  expect_equal(content_structure(sim, membership = rev(named))$adjusted_rand, 1)
  typo <- stats::setNames(rev(bp), c(rownames(sim)[1:8], "typo"))
  expect_error(content_structure(sim, membership = typo),
               "its names do not include item(s): I9", fixed = TRUE)
  expect_equal(content_structure(sim, membership = factor(bp))$adjusted_rand, 1)
})

test_that("equal similarities stop with a reason", {
  expect_error(content_structure(matrix(5, 4, 4)),
               "Every pair of items is equally similar", fixed = TRUE)
})

test_that("plot arguments replace the method's own, and one dimension keeps its key", {
  sim <- three_cells()
  bp <- rep(c("A", "B", "C"), each = 3)
  cs <- content_structure(sim, membership = bp)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_silent(plot(cs, xlab = "Dimension one", pch = 19, main = "Map",
                     xlim = c(-5, 5)))
  expect_silent(plot(content_structure(sim, membership = bp, dims = 1)))
  expect_silent(plot(content_structure(sim, membership = bp, dims = 1),
                     show_legend = FALSE, ylab = "none"))
})

test_that("similarity_from_sort keeps data order and trims labels", {
  sorts <- data.frame(
    item = rep(c("Q10", "Q2", "Q1"), each = 4),
    rater = rep(1:4, times = 3),
    assigned_construct = c("A", "A", " A", "B", "B", "B", "B", "A",
                           "A", "A", "A", "A"),
    stringsAsFactors = FALSE
  )
  sim <- similarity_from_sort(sorts)
  expect_identical(rownames(sim), c("Q10", "Q2", "Q1"))
  # " A" and "A" are one construct: rater 3 put Q10 and Q1 together.
  expect_equal(sim["Q10", "Q1"], 0.75)
})

# ---- domain_validity ---------------------------------------------------------

test_that("with targets, a cell far below its intended share is flagged", {
  a <- data.frame(item = paste0("I", 1:14),
                  cell = rep(c("A", "B", "C"), c(2, 6, 6)))
  fit <- domain_validity(a, targets = c(A = 10, B = 2, C = 2))
  r <- fit$results
  expect_identical(r$recommendation,
                   c("Under-represented", "Over-represented", "Over-represented"))
  expect_identical(r$status, rep("Review", 3))
  expect_identical(fit$scale_summary$n_under, 1L)
  expect_identical(fit$scale_summary$n_covered, 0L)
  expect_match(r$interpretation[1], "less than 1/2 of its intended share of 71%",
               fixed = TRUE)
  out <- flat(fit)
  expect_match(out, "or below 1/2 of it (expected shares from `targets`)",
               fixed = TRUE)
  expect_true("Under-represented" %in%
                names(contentvalidR:::.decision_meanings("domain")))

  # Without targets an equal share is an assumption, so nothing is called
  # under-represented.
  plain <- domain_validity(a)
  expect_false(any(plain$results$recommendation == "Under-represented"))
  expect_identical(plain$scale_summary$n_under, 0L)
})

test_that("a cell that meets a target of one is not thin", {
  a <- data.frame(item = paste0("I", 1:5),
                  cell = rep(c("A", "B", "C"), c(1, 2, 2)))
  fit <- domain_validity(a, targets = c(A = 1, B = 2, C = 2))
  expect_identical(fit$results$recommendation, rep("Covered", 3))
  # Without the target the same cell is below the minimum of two.
  expect_identical(domain_validity(a)$results$recommendation[1],
                   "Thinly covered")
  # A target above min_items does not raise the floor.
  b <- data.frame(item = paste0("I", 1:8),
                  cell = rep(c("A", "B"), c(2, 6)))
  expect_false(domain_validity(b, targets = c(A = 3, B = 5))$results$recommendation[1] ==
                 "Thinly covered")
})

test_that("the printout says when no cell can be over-represented", {
  two <- data.frame(item = paste0("I", 1:12), cell = rep(c("A", "B"), c(10, 2)))
  fit <- domain_validity(two)
  expect_false(fit$settings$over_possible)
  expect_match(flat(fit), "no cell can be flagged as over-represented",
               fixed = TRUE)
  three <- data.frame(item = paste0("I", 1:6), cell = rep(c("A", "B", "C"), 2))
  expect_true(domain_validity(three)$settings$over_possible)
  expect_false(grepl("can be flagged", flat(domain_validity(three)), fixed = TRUE))
})

test_that("the domain key defines only what the printout shows", {
  sim <- three_cells()
  d <- data.frame(item = rownames(sim), cell = rep(c("A", "B", "C"), each = 3))
  out <- flat(domain_validity(d, similarity = sim))
  expect_match(out, "Adjusted Rand -- Adjusted Rand index", fixed = TRUE)
  expect_false(grepl("stress", out, fixed = TRUE))
})

test_that("cell labels and target names are compared as trimmed text", {
  a <- data.frame(item = paste0("I", 1:4), cell = c("A", " A", "B", "B "))
  fit <- domain_validity(a, targets = c("A " = 2, B = 2))
  expect_identical(fit$results$cell, c("A", "B"))
  expect_identical(fit$results$n_items, c(2L, 2L))
  expect_error(domain_validity(a, targets = c(A = 2, "A " = 1, B = 2)),
               "names a cell more than once: A", fixed = TRUE)
})

# ---- two-by-two comparators --------------------------------------------------

test_that("small tables report Fisher's exact p, large ones the chi-square", {
  s1 <- c(TRUE, TRUE, FALSE, FALSE, TRUE, FALSE)
  s2 <- c(TRUE, FALSE, FALSE, FALSE, TRUE, FALSE)
  small <- reproducibility_phi(s1, s2)
  expect_identical(small$p_method, "Fisher's exact test")
  expect_equal(small$p, stats::fisher.test(small$table)$p.value)
  expect_equal(small$p_chisq,
               suppressWarnings(stats::chisq.test(small$table, correct = FALSE))$p.value)
  expect_identical(small$n, 6L)
  out <- flat(small)
  expect_match(out, "phi = .71, Fisher's exact p = .400.", fixed = TRUE)
  expect_match(out, "chi-square(1, N = 6) = 3.00, p = .083", fixed = TRUE)

  b1 <- rep(c(TRUE, FALSE), each = 30)
  b2 <- b1
  b2[c(3, 9, 40, 44, 51)] <- !b2[c(3, 9, 40, 44, 51)]
  big <- reproducibility_phi(b1, b2)
  expect_identical(big$p_method, "chi-square")
  expect_equal(big$p, big$p_chisq)
  expect_match(flat(big), "chi-square(1, N = 60) = 41.71, p < .001.",
               fixed = TRUE)
  expect_false(grepl("Fisher", flat(big), fixed = TRUE))

  sd <- signal_detection(c(TRUE, TRUE, FALSE, FALSE), c(TRUE, FALSE, TRUE, FALSE))
  expect_identical(sd$p_method, "Fisher's exact test")
  expect_identical(sd$n, 4L)
  # An empty row or column leaves nothing to test either way.
  none <- signal_detection(c(TRUE, TRUE, TRUE), c(TRUE, TRUE, TRUE))
  expect_true(is.na(none$chisq))
  expect_true(is.na(none$p))
  expect_true(is.na(none$p_method))
})

# ---- wording -----------------------------------------------------------------

test_that("qfactor_content says what it does not do, and wraps its message", {
  set.seed(1)
  df <- data.frame(
    item = rep(paste0("I", 1:6), each = 30),
    rater = rep(1:10, times = 18),
    construct = rep(rep(LETTERS[1:3], each = 10), times = 6),
    rating = stats::rnorm(180)
  )
  msg <- tryCatch(qfactor_content(df, retention = "kaiser"),
                  message = function(m) conditionMessage(m))
  expect_lte(max(nchar(strsplit(msg, "\n", fixed = TRUE)[[1]])), 80L)
  expect_match(gsub("[[:space:]]+", " ", msg),
               "Zwick and Velicer (1986) found that it severely overestimates",
               fixed = TRUE)
})

test_that("the key no longer calls the map's fit Kruskal's stress", {
  g <- contentvalid_glossary()
  row <- g[g$term == "stress", ]
  expect_false(grepl("^Kruskal", row$label))
  expect_match(row$definition, "not Kruskal's", fixed = TRUE)
  expect_false(grepl("fair", row$range, fixed = TRUE))
  expect_lte(max(nchar(contentvalidR:::.term_short())), 120L)
})

# ---- Review of the audit fixes ----------------------------------------------

test_that("a fragile item can be one judge short of the criterion", {
  # Eight judges: the criterion is 7, and 6 of 8 becomes 6 of 7 without a
  # dissenter, which meets it.
  X <- rbind(c(4, 4), c(4, 4), c(4, 4), c(4, 4), c(4, 4), c(4, 4),
             c(2, 4), c(2, 4))
  dimnames(X) <- list(paste0("J", 1:8), c("Short", "Solid"))
  fit <- judge_validity(X)
  items <- fit$details$influence_items
  expect_true(items$fragile[items$item == "Short"])
  expect_identical(items$status_full_panel[items$item == "Short"], "Review")
  out <- flat(fit)
  expect_match(out, "at the criterion, or one short of it", fixed = TRUE)
  expect_false(grepl("sits at the CVI criterion", out, fixed = TRUE))
})

test_that("complete ratings give raw severity as before, and a judge at a cut is not flagged", {
  X <- matrix(c(2, 4, 2, 3, 3, 4, 4, 3, 3, 3, 2, 4, 4, 1, 4, 1, 3, 4, 3, 3), 5, 4)
  fit <- judge_validity(X, lo = 1, hi = 4)
  r <- fit$results
  expect_identical(r$severity_raw, unname(mean(X) - rowMeans(X)))
  at_cut <- abs(abs(r$severity_raw) - fit$settings$severity_raw_cut) < 1e-8
  expect_true(any(at_cut))
  expect_false(any(r$recommendation[at_cut] %in% c("Severe", "Lenient")))
})

test_that("with missing ratings the correction counts the judges behind each item", {
  set.seed(4)
  n_j <- 6; n_i <- 40
  X <- ifelse(matrix(stats::rbinom(n_j * n_i, 1, 0.6), n_j), 4, 2)
  # Each item is rated by four of the six judges.
  for (i in seq_len(n_i)) X[sample(n_j, 2), i] <- NA
  dimnames(X) <- list(paste0("J", 1:n_j), paste0("I", 1:n_i))
  fit <- judge_validity(X, na.rm = TRUE)
  expect_true(fit$scale_summary$severity_estimable)
  expect_equal(fit$settings$bias_correction, 3 / 4)
  raw <- judge_validity(X, na.rm = TRUE, bias_correct = FALSE)
  expect_equal(fit$results$severity, raw$results$severity * 3 / 4)
  expect_equal(fit$results$se, raw$results$se * sqrt(3 / 4))
})

test_that("the fit rule cites Linacre only for his bound and names judges too thin to flag", {
  r <- data.frame(judge = c("A", "B", "C"), infit = c(1, 2.4, 1.1),
                  outfit = c(1, 3.5, 0.9), n_scored = c(36L, 20L, 36L),
                  stringsAsFactors = FALSE)
  lines <- contentvalidR:::.judge_fit_lines(
    r, list(fit_range = c(0.5, 1.5), fit_min_ratings = 30L))
  expect_match(lines[1], "Linacre (2002)", fixed = TRUE)
  expect_match(lines[1], "at least 30", fixed = TRUE)
  expect_match(lines[1], "contentvalidR conventions", fixed = TRUE)
  expect_identical(lines[2], "Above 1.5 on too few scored decisions to flag: B (20).")

  custom <- contentvalidR:::.judge_fit_lines(
    r, list(fit_range = c(0.5, 1.2), fit_min_ratings = 30L))
  expect_false(grepl("Linacre", custom[1], fixed = TRUE))
  expect_match(custom[1], "the upper bound set for this analysis", fixed = TRUE)

  r$n_scored <- c(6L, 6L, 5L)
  few <- contentvalidR:::.judge_fit_lines(
    r, list(fit_range = c(0.5, 1.5), fit_min_ratings = 30L))
  expect_match(few[2], "Here the model scored at most 6", fixed = TRUE)
})

test_that("a judge below a custom fit range is not described in Linacre's words", {
  set.seed(32)
  n_j <- 8; n_i <- 60
  easy <- seq(-2, 2, length.out = n_i)
  p <- stats::plogis(outer(rep(0, n_j), easy, "+"))
  B <- matrix(stats::rbinom(n_j * n_i, 1, as.vector(p)), n_j)
  B[1, ] <- as.integer(easy > 0)
  X <- ifelse(B == 1, 4, 2)
  dimnames(X) <- list(paste0("J", 1:n_j), paste0("I", 1:n_i))
  default <- judge_validity(X)
  expect_true(default$scale_summary$severity_estimable)
  expect_lt(min(default$results$infit[1], default$results$outfit[1]), 0.5)
  expect_match(default$results$interpretation[1], "Linacre (2002)", fixed = TRUE)
  custom <- judge_validity(X, fit_range = c(0.9, 10))
  expect_false(grepl("Linacre", custom$results$interpretation[1], fixed = TRUE))
})

test_that("one judge prints the verdict and nothing that needs a panel", {
  out <- flat(judge_validity(matrix(c(4, 3, 2, 4), 1)))
  expect_match(out, "One judge is not a panel", fixed = TRUE)
  expect_false(grepl("A judge is flagged", out, fixed = TRUE))
  expect_false(grepl("Logit severity not estimated", out, fixed = TRUE))
})

test_that("Phi is not said to rest on fewer than two judges", {
  X <- varied_panel()
  X[, 10] <- NA
  out <- flat(judge_validity(X, na.rm = TRUE))
  expect_match(out, "fewer than two judges rated every item, so Phi is not estimable",
               fixed = TRUE)
  expect_false(grepl("Phi uses the 0 judges", out, fixed = TRUE))
  X <- varied_panel()
  X[1, 1] <- NA
  sm <- flat(summary(judge_validity(X, na.rm = TRUE)))
  expect_match(sm, "Phi uses the 7 judges who rated every item", fixed = TRUE)
})

test_that("an empty data frame gets the empty-input message", {
  expect_error(judge_validity(data.frame(I1 = numeric(0), I2 = numeric(0))),
               "at least one judge")
})

test_that("judge objects saved before 1.0 still print and summarize", {
  fit <- judge_validity(varied_panel())
  fit$settings$differentiation_cut <- NULL
  fit$settings$fit_min_ratings <- NULL
  fit$results$n_scored <- NULL
  keep <- c("item", "fragile")
  fit$details$influence_items <- fit$details$influence_items[, keep]
  expect_no_warning(out <- flat(fit))
  expect_match(out, "scale use is below 0.50", fixed = TRUE)
  expect_no_error(flat(summary(fit)))
})

test_that("the summary heading for judges sharing a reason wraps", {
  set.seed(31)
  n_j <- 8; n_i <- 60
  easy <- seq(-2, 2, length.out = n_i)
  p <- stats::plogis(outer(rep(0, n_j), easy, "+"))
  B <- matrix(stats::rbinom(n_j * n_i, 1, as.vector(p)), n_j)
  B[n_j, ] <- as.integer(easy < 0)
  X <- ifelse(B == 1, 4, 2)
  dimnames(X) <- list(sprintf("Judge_Number%02d", 1:n_j), paste0("I", 1:n_i))
  out <- shown(summary(judge_validity(X)))
  expect_true(all(nchar(out) <= 80))
})

test_that("a value just below its cut gets a third decimal", {
  expect_identical(contentvalidR:::.fmt_beside_cut(0.796703, 0.80), ".797")
  expect_identical(contentvalidR:::.fmt_beside_cut(0.81, 0.80), ".81")
  expect_identical(contentvalidR:::.fmt_beside_cut(0.80, 0.80), ".80")
  X <- structure(c(1, 1, 1, 2, 1, 2, 2, 2, 2, 3, 1, 1, 1, 1, 1, 1, 2, 3, 2, 1),
                 dim = 5:4)
  g <- gtheory_content(X)
  expect_match(g$interpretation, "Phi = .797, below the .80", fixed = TRUE)
})

test_that("a cut the analyst sets is not called a package convention", {
  X <- varied_panel()
  out <- flat(gtheory_content(X, phi_cut = 0.9))
  expect_match(out, "(criterion: Phi >= .90, set for this analysis)", fixed = TRUE)
  expect_false(grepl("a contentvalidR convention)", out, fixed = TRUE))
})

test_that("gtheory names residual variation as residual", {
  g <- gtheory_content(rbind(c(4, 3, 4, 3), c(3, 4, 3, 4), c(4, 3, 3, 4),
                             c(3, 4, 4, 3)))
  expect_match(g$interpretation, "residual", fixed = TRUE)
  expect_false(grepl("within judge-item cells", g$interpretation, fixed = TRUE))
})

test_that("the content map's symbols and key follow a pch or col given per cell", {
  group <- factor(c("A", "A", "B", "C"))
  s <- contentvalidR:::.structure_symbols(group, list())
  expect_identical(s$pch, c(1L, 1L, 2L, 3L))
  expect_identical(s$key_pch, 1:3)
  expect_null(s$key_col)

  per_cell <- contentvalidR:::.structure_symbols(group, list(pch = c(15, 16, 17),
                                                          col = c("red", "blue", "grey")))
  expect_identical(per_cell$pch, c(15, 15, 16, 17))
  expect_identical(per_cell$key_pch, c(15, 16, 17))
  expect_identical(per_cell$col, c("red", "red", "blue", "grey"))
  expect_identical(per_cell$key_col, c("red", "blue", "grey"))

  one <- contentvalidR:::.structure_symbols(group, list(pch = 19, col = "red"))
  expect_null(one$key_pch)
  expect_identical(one$key_col, "red")
})

test_that("the structure example spreads its nine items over the map", {
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
  cs <- content_structure(sim, membership = blueprint)
  expect_identical(nrow(unique(round(cs$coordinates, 6))), 9L)
  out <- flat(content_structure(sim, membership = blueprint, ari_cut = 1))
  expect_match(out, "set for this analysis)", fixed = TRUE)
  expect_match(out, "Distortion", fixed = TRUE)
  expect_match(out, "absolute eigenvalues", fixed = TRUE)
})

test_that("structure errors say what to do and end with one period", {
  expect_error(content_structure(matrix(5, 4, 4)), "Check `similarity`.", fixed = TRUE)
  sim <- matrix(1, 9, 9, dimnames = list(paste0("I", 1:9), paste0("I", 1:9)))
  diag(sim) <- 5
  sim[1:3, 1:3] <- 4
  diag(sim) <- 5
  bp <- stats::setNames(rep(c("A", "B", "C"), each = 3), paste0("Q", 1:9))
  err <- tryCatch(content_structure(sim, membership = bp), error = conditionMessage)
  expect_match(err, "I5 and 4 more. Name it", fixed = TRUE)
})

test_that("domain criteria state the target floor, rounded up, and name the convention", {
  d <- data.frame(item = paste0("I", 1:7),
                  cell = c(rep("Autonomy", 4), "Competence", "Competence", "Relatedness"))
  fit <- domain_validity(d, targets = c(Autonomy = 4, Competence = 2, Relatedness = 1))
  out <- flat(fit)
  expect_match(out, "at least 2 items per cell (or the cell's target, if smaller)",
               fixed = TRUE)
  expect_match(out, "contentvalidR conventions, not published standards", fixed = TRUE)
  expect_identical(fit$results$recommendation[fit$results$cell == "Relatedness"],
                   "Covered")

  frac <- domain_validity(d, targets = c(Autonomy = 4, Competence = 2,
                                         Relatedness = 1.5))
  rel <- frac$results$cell == "Relatedness"
  expect_identical(frac$results$recommendation[rel], "Thinly covered")
  expect_match(frac$results$interpretation[rel], "below the minimum of 2",
               fixed = TRUE)
})

test_that("a target cell with no items is reported, and a stray target stops", {
  d <- data.frame(item = paste0("I", 1:4), cell = c("A", "A", "B", "B"))
  fit <- domain_validity(d, targets = c(A = 2, B = 2, C = 2))
  expect_identical(fit$results$cell, c("A", "B", "C"))
  expect_identical(fit$results$recommendation[3], "Not covered")
  expect_equal(fit$results$expected_share, rep(1 / 3, 3))
  expect_error(domain_validity(d, domain = c("A", "B"),
                               targets = c(A = 2, B = 2, C = 2)),
               "not in `domain`: C")
})

test_that("domain_validity trims the item names in similarity", {
  items <- paste0("I", 1:6, " ")
  sim <- matrix(1, 6, 6, dimnames = list(items, items))
  sim[1:3, 1:3] <- 4
  sim[4:6, 4:6] <- 4
  sim[1, 2] <- sim[2, 1] <- 5
  sim[4, 6] <- sim[6, 4] <- 3
  diag(sim) <- 5
  d <- data.frame(item = items, cell = rep(c("A", "B"), each = 3))
  fit <- domain_validity(d, similarity = sim, dims = 1)
  expect_s3_class(fit$details$structure, "contentvalid_structure")
})

test_that("rounds analyzed alike stay comparable when the data change a derived setting", {
  a <- domain_validity(data.frame(item = paste0("I", 1:6),
                                  cell = rep(c("A", "B"), each = 3)))
  b <- domain_validity(data.frame(item = paste0("I", 1:9),
                                  cell = rep(c("A", "B", "C"), each = 3)))
  expect_false(identical(a$settings$over_possible, b$settings$over_possible))
  expect_true(compare_rounds(a, b)$comparable)
})

test_that("the two-by-two comparators handle large tables", {
  expect_no_error(signal_detection(rep(c(TRUE, FALSE), c(400, 300)),
                                   rep(c(TRUE, FALSE, TRUE, FALSE),
                                       c(350, 50, 40, 260))))
})

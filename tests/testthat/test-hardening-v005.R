.make_v005_sort <- function() {
  data.frame(
    item = rep(c("A1", "B1"), each = 10),
    rater = rep(seq_len(10), 2),
    assigned_construct = c(rep("A", 9), "B", rep("B", 8), rep("A", 2)),
    target_construct = rep(c("A", "B"), each = 10),
    stringsAsFactors = FALSE
  )
}

.make_v005_rating <- function() {
  d <- expand.grid(
    item = c("A1", "B1"),
    rater = seq_len(8),
    construct = c("A", "B"),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  d$target_construct <- ifelse(d$item == "A1", "A", "B")
  base <- ifelse(d$construct == d$target_construct, 4.5, 2.0)
  d$rating <- base + rep(c(-.2, .1, .2, -.1), length.out = nrow(d))
  d
}

.make_v005_expert <- function() {
  matrix(
    c(4,4,4,4,4,4,
      4,4,4,3,4,4,
      4,3,4,4,3,4),
    nrow = 6,
    dimnames = list(NULL, paste0("Item", 1:3))
  )
}

test_that("logical missing-data flags are validated explicitly", {
  x <- matrix(c(4, 4, 3, 4), nrow = 2)
  expect_error(aikens_v(x, na.rm = 1), "TRUE or FALSE")
  expect_error(cvi(matrix(c(1, 0), nrow = 1), na.rm = NA), "TRUE or FALSE")
  expect_error(cvr(c(3, 4), N = 5, na.rm = "yes"), "TRUE or FALSE")
  expect_error(ioc(data.frame(item="I1", judge=1, objective="A", score=1), na.rm = 0), "TRUE or FALSE")
  expect_error(expert_validity(x, mode = "relevance", na.rm = NULL), "TRUE or FALSE")
})

test_that("Aiken and CVR reject malformed numerical controls", {
  x <- matrix(c(4, 4, 3, 4), nrow = 2)
  expect_error(aikens_v(x, lo = 1, hi = 4, alpha = NA_real_), "alpha")
  expect_error(aikens_v(x, lo = 1, hi = 4, ci = "bootstrap", B = 2.5), "integer")
  expect_error(aikens_v(x, lo = 1, hi = 4, ci = "bootstrap", B = 5, seed = 1.2), "seed")
  expect_error(cvr(c(3, 4), N = 5, alpha = NaN), "alpha")
})

test_that("sort identifiers and column arguments cannot be blank or ambiguous", {
  d <- .make_v005_sort()
  d$item[1] <- ""
  expect_error(compute_psa(d), "item.*empty")

  d <- .make_v005_sort()
  d$assigned_construct[1] <- "   "
  expect_error(compute_csv(d), "assigned_construct.*empty")

  expect_error(
    compute_psa(.make_v005_sort(), item_col = c("item", "rater")),
    "character scalars"
  )
  expect_error(
    compute_psa(.make_v005_sort(), item_col = "item", rater_col = "item"),
    "distinct columns"
  )
})

test_that("rating data reject non-finite values and malformed target maps", {
  d <- .make_v005_rating()
  d$rating[1] <- Inf
  expect_error(htc(d), "finite numeric")
  expect_error(anova_content(d), "finite numeric")

  d <- .make_v005_rating()
  bad_dup <- c(A1 = "A", A1 = "B", B1 = "B")
  expect_error(htc(d, target_map = bad_dup), "uniquely map")
  expect_error(htc(d, target_map = c(A1 = NA_character_, B1 = "B")), "non-missing")
  expect_error(htc(d, target_map = c(A1 = "", B1 = "B")), "non-missing")
})

test_that("rating distinctiveness requires at least two construct definitions", {
  d <- data.frame(
    item = rep("I1", 4), rater = 1:4, construct = "A",
    rating = c(4, 5, 4, 5), target_construct = "A"
  )
  expect_error(htd(d), "at least two construct definitions")
  expect_error(rating_validity(d), "at least two construct definitions")
})

test_that("rating orbiting correlations obey documented multi-scale mapping", {
  d <- .make_v005_rating()
  expect_error(rating_validity(d, orbiting_r = .40), "uniquely named")
  expect_error(rating_validity(d, orbiting_r = c(A = .4, A = .5, B = .6)), "uniquely named")
  expect_error(rating_validity(d, orbiting_r = c(A = .4, B = 1.2)), "between -1 and 1")
})

test_that("sort orbiting correlations reject duplicate target names", {
  d <- .make_v005_sort()
  expect_error(
    sort_validity(d, orbiting_r = c(A = .4, A = .5, B = .6)),
    "uniquely named"
  )
})

test_that("Colquitt benchmark helper rejects vector orbiting correlations cleanly", {
  expect_error(colquitt_benchmarks("psa", orbiting_r = c(.2, .4)), "one finite correlation")
  expect_equal(colquitt_benchmarks("psa", orbiting_r = NA_real_)$benchmark_set[1], "overall")
})

test_that("forced ANOVA design cannot contradict observed judge structure", {
  within <- .make_v005_rating()
  expect_error(anova_content(within, design = "between"), "rated multiple construct")

  between <- data.frame(
    item = "I1", rater = 1:8,
    construct = rep(c("A", "B"), each = 4),
    rating = c(4,5,4,5,2,2,3,2),
    target_construct = "A"
  )
  expect_error(anova_content(between, design = "within"), "no judge rating more than one")
})

test_that("IOC rejects malformed identifiers", {
  d <- data.frame(item = "I1", judge = 1:2, objective = "A", score = c(1, 0))
  d$judge[1] <- NA
  expect_error(ioc(d), "judge.*missing")

  d <- data.frame(item = "I1", judge = 1:2, objective = c("A", ""), score = c(1, 0))
  expect_error(ioc(d), "objective.*empty")
})

test_that("expert congruence target mappings must refer to rated objectives", {
  d <- expand.grid(item = "I1", judge = 1:3, objective = c("A", "B"),
                   KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  d$score <- c(1,1,1,0,-1,0)
  d$target_objective <- "C"
  expect_error(expert_validity(d, mode = "congruence"), "absent from the rated objectives")

  d$target_objective <- NA_character_
  expect_error(expert_validity(d, mode = "congruence"), "cannot be missing")
})

test_that("expert relevance validates scale bounds before deriving CVI cut", {
  x <- .make_v005_expert()
  expect_error(expert_validity(x, mode = "relevance", lo = 4, hi = 1), "hi > lo")
})

test_that("legacy simulation helpers fail early on impossible inputs", {
  expect_error(simulate_csv_power(N = 0), "positive integer")
  expect_error(simulate_csv_power(reps = 2.5), "positive integer")
  expect_error(simulate_csv_power(alpha = NA_real_), "alpha")
  expect_error(simulate_anova_power(n_raters = 1), "at least 2")
  expect_error(simulate_anova_power(sd = 0), "positive finite")
  expect_error(simulate_anova_power(k_constructs = 1), "at least 2")
})

test_that("Q-factor helper validates structure before extraction", {
  one <- data.frame(item="I1", rater=1:4, construct="A", rating=1:4)
  expect_error(qfactor_content(one), "at least two items")

  dup <- rbind(
    data.frame(item="I1", rater=1, construct="A", rating=1),
    data.frame(item="I1", rater=1, construct="A", rating=2),
    data.frame(item="I2", rater=1, construct="A", rating=3)
  )
  expect_error(qfactor_content(dup), "at most once")

  flat <- expand.grid(item=c("I1","I2"), rater=1:4, construct="A",
                      KEEP.OUT.ATTRS=FALSE, stringsAsFactors=FALSE)
  flat$rating <- 1
  expect_error(qfactor_content(flat), "Q correlations are undefined")
})

test_that("Q-factor PCA retains a stable auxiliary return contract", {
  d <- expand.grid(item = paste0("I", 1:3), rater = 1:8, construct = c("A","B"),
                   KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  item_shift <- c(I1 = 0, I2 = .7, I3 = -.4)
  d$rating <- as.numeric(d$rater) * c(.2, -.1)[match(d$construct, c("A","B"))] +
    item_shift[d$item] +
    as.numeric(factor(interaction(d$rater, d$construct))) * c(.03, -.02, .01)[match(d$item, paste0("I",1:3))]
  out <- qfactor_content(d, k_factors = 1, method = "pca")
  expect_named(out, c("cor_Q", "eigen", "k", "loadings", "method"))
  expect_equal(dim(out$cor_Q), c(3L, 3L))
  expect_equal(dim(out$loadings), c(3L, 1L))
  expect_equal(out$k, 1L)
  expect_equal(out$method, "pca")
})

test_that("agreement helper validates shape before optional dependency lookup", {
  expect_error(agreement_summary(data.frame(rater1 = c("A", "B"))), "two raters")
})

test_that("v0.0.6 workflow contracts preserve v0.0.5 compatibility aliases", {
  core <- c("workflow", "results", "scale_summary", "settings", "design", "details")
  summary_core <- c("workflow", "n_items", "n_results", "n_supported", "n_review",
                    "n_insufficient", "n_descriptive", "scale_summary",
                    "reviewed_items", "settings", "design")

  sfit <- sort_validity(.make_v005_sort())
  expect_s3_class(sfit, "contentvalid_sort")
  expect_true(all(core %in% names(sfit)))
  ss <- summary(sfit)
  expect_true(all(summary_core %in% names(ss)))
  expect_equal(ss$n_retain, ss$n_supported)
  expect_false(withVisible(print(sfit))$visible)

  rfit <- rating_validity(.make_v005_rating())
  expect_s3_class(rfit, "contentvalid_rating")
  expect_true(all(core %in% names(rfit)))
  expect_identical(rfit$contrasts, rfit$details$contrasts)
  rs <- summary(rfit)
  expect_true(all(summary_core %in% names(rs)))
  expect_equal(rs$n_retain, rs$n_supported)
  expect_false(withVisible(print(rfit))$visible)

  efit <- expert_validity(.make_v005_expert(), mode = "relevance", lo = 1, hi = 4)
  expect_s3_class(efit, "contentvalid_expert")
  expect_true(all(core %in% names(efit)))
  expect_identical(efit$scale, efit$scale_summary)
  es <- summary(efit)
  expect_true(all(summary_core %in% names(es)))
  expect_identical(es$scale, es$scale_summary)
  expect_identical(es$flagged, es$reviewed_items)
  expect_false(withVisible(print(efit))$visible)
})

test_that("expert item names are unique and non-empty", {
  x <- matrix(c(4,4,3,4, 4,3,4,4), nrow = 4,
              dimnames = list(NULL, c("Item1", "Item1")))
  expect_error(aikens_v(x, lo = 1, hi = 4), "unique")
  expect_error(cvi(x >= 3), "unique")
  expect_error(cvr(x >= 3), "unique")
})

test_that("anova_content reports one-construct designs descriptively instead of crashing", {
  d <- data.frame(
    item = rep("I1", 4), rater = 1:4, construct = "A",
    rating = c(4, 5, 4, 5), target_construct = "A"
  )
  out <- anova_content(d)
  expect_equal(out$n_constructs, 1L)
  expect_true(is.na(out$F))
  expect_true(is.na(out$contrast_pass))
  expect_equal(nrow(attr(out, "contrasts")), 0L)
})

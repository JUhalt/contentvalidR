# Fixes from the audit before 1.0: the published index of item-objective
# congruence, the congruence decision, and the expert-panel labels for what
# is published and what is this package's extension.

flat <- function(x) {
  old <- options(width = 80)
  on.exit(options(old), add = TRUE)
  gsub("[[:space:]]+", " ", paste(utils::capture.output(print(x)), collapse = "\n"))
}

long_ratings <- function(item, judge, objective, score) {
  data.frame(item = item, judge = judge, objective = objective, score = score,
             stringsAsFactors = FALSE)
}

# ---- ioc(): the published index ----------------------------------------------

test_that("the index is half the gap between the objective and the others", {
  # +1 on the objective and 0 on the other: .50, the published value.
  d <- long_ratings("I1", rep(1:3, 2), rep(c("A", "B"), each = 3),
                    c(1, 1, 1, 0, 0, 0))
  out <- ioc(d)
  expect_equal(out$ioc[out$objective == "A"], 0.5)
  expect_equal(out$mean_rating[out$objective == "A"], 1)
  # +1 on the objective and -1 on the other: 1.
  d$score <- c(1, 1, 1, -1, -1, -1)
  expect_equal(ioc(d)$ioc[1], 1)
})

test_that("the index matches Rovinelli and Hambleton's formula", {
  set.seed(7)
  n <- 5; objectives <- c("A", "B", "C", "D")
  d <- expand.grid(item = c("I1", "I2"), judge = seq_len(n),
                   objective = objectives, stringsAsFactors = FALSE)
  d$score <- sample(c(-1, 0, 1), nrow(d), replace = TRUE)
  out <- ioc(d)
  N <- length(objectives)
  for (k in c("I1", "I2")) for (i in objectives) {
    on_i <- sum(d$score[d$item == k & d$objective == i])
    others <- sum(d$score[d$item == k & d$objective != i])
    expected <- ((N - 1) * on_i - others) / (2 * (N - 1) * n)
    expect_equal(out$ioc[out$item == k & out$objective == i], expected)
  }
})

test_that("one objective gives no index, and items keep the order of the data", {
  d <- long_ratings(rep(c("I2", "I1"), each = 3), rep(1:3, 2), "A", 1)
  out <- ioc(d)
  expect_identical(out$item, c("I2", "I1"))
  expect_true(all(is.na(out$ioc)))
  expect_identical(out$n_objectives, c(1L, 1L))
})

# ---- expert_validity(mode = "congruence") ------------------------------------

congruence_data <- function() {
  d <- expand.grid(item = c("I1", "I2", "I3"), judge = 1:4,
                   objective = c("A", "B"), stringsAsFactors = FALSE)
  d$target_objective <- c(I1 = "A", I2 = "B", I3 = "A")[d$item]
  d$score <- with(d, ifelse(
    item == "I1", ifelse(objective == "A", 1, -1),
    ifelse(item == "I2", ifelse(objective == "B", 1, 0),
           ifelse(objective == "A", 0, 1))))
  d
}

test_that("the decision is the index against the criterion", {
  fit <- expert_validity(congruence_data(), mode = "congruence")
  r <- fit$results
  expect_identical(r$item, c("I1", "I2", "I3"))
  expect_equal(r$target_ioc, c(1, 0.5, -0.5))
  expect_identical(r$recommendation, c("Congruent", "Review", "Review"))
  expect_equal(fit$settings$ioc_cut, 0.70)
  expect_equal(r$target_mean, c(1, 1, 0))
  expect_equal(r$margin, c(2, 1, -1))
  expect_identical(r$strongest_competitor, c("B", "A", "B"))

  lenient <- expert_validity(congruence_data(), mode = "congruence", ioc_cut = 0.5)
  expect_identical(lenient$results$recommendation, c("Congruent", "Congruent", "Review"))
  expect_error(expert_validity(congruence_data(), mode = "congruence", ioc_cut = 1.2),
               "`ioc_cut` must be one number above 0 and at most 1.", fixed = TRUE)
  expect_error(expert_validity(congruence_data(), mode = "congruence", ioc_cut = 0),
               "`ioc_cut`", fixed = TRUE)
})

test_that("an item rated on its target only is described, not decided", {
  d <- long_ratings("I1", 1:3, "A", 1)
  d$target_objective <- "A"
  fit <- expert_validity(d, mode = "congruence")
  expect_identical(fit$results$recommendation, "Target described")
  expect_true(is.na(fit$results$target_ioc))
  expect_identical(fit$results$status, "Descriptive only")
})

test_that("the congruence printout states the criterion and its source", {
  out <- flat(expert_validity(congruence_data(), mode = "congruence"))
  expect_match(out, "1 of 3 items meets the congruence criterion", fixed = TRUE)
  expect_match(out, "Rovinelli", fixed = TRUE)
  expect_match(out, ".70", fixed = TRUE)
  expect_match(out, "Flagged for review: I2, I3", fixed = TRUE)
})

test_that("without targets there is one row per item and the cells are kept", {
  d <- congruence_data()
  d$target_objective <- NULL
  fit <- expert_validity(d, mode = "congruence")
  r <- fit$results
  expect_identical(r$item, c("I1", "I2", "I3"))
  expect_identical(r$recommendation, rep("Descriptive only", 3))
  expect_identical(r$best_objective, c("A", "B", "B"))
  expect_equal(r$best_ioc, c(1, 0.5, 0.5))
  expect_identical(nrow(fit$details$cells), 6L)
  out <- flat(fit)
  expect_match(out, "without a decision", fixed = TRUE)
})

test_that("the congruence handoff carries the index, both means and the criterion", {
  h <- content_handoff(expert_validity(congruence_data(), mode = "congruence"),
                       keep = c("Supported", "Review"))
  st <- h$item_statistics
  expect_setequal(unique(st$statistic),
                  c("target IOC", "target mean rating", "competitor mean rating"))
  tioc <- st[st$statistic == "target IOC", ]
  expect_equal(tioc$value, c(1, 0.5, -0.5))
  expect_equal(tioc$criterion, rep(0.70, 3))
  comp <- st[st$statistic == "competitor mean rating", ]
  expect_identical(comp$note[comp$item == "I1"], "Objective B.")
  expect_match(h$item_evidence$rule[1], ">= .70 (Rovinelli & Hambleton, 1977)",
               fixed = TRUE)
  expect_false(any(c("competitor IOC", "IOC margin") %in% st$statistic))

  d <- congruence_data()
  d$target_objective <- NULL
  desc <- content_handoff(expert_validity(d, mode = "congruence"),
                          keep = "Descriptive only")
  expect_identical(unique(desc$item_statistics$statistic), "highest IOC")
  expect_identical(nrow(desc$item_statistics), 3L)
})

test_that("the congruence report shows the index, the means and the decision", {
  tab <- content_report(expert_validity(congruence_data(), mode = "congruence"))
  expect_identical(names(tab), c("item", "target", "experts", "IOC", "mean",
                                 "competitor", "competitor mean", "margin",
                                 "decision"))
  expect_identical(tab$IOC, c("1.00", ".50", "-.50"))
  expect_identical(tab$margin, c("2.00", "1.00", "-1.00"))
  d <- congruence_data()
  d$target_objective <- NULL
  desc <- content_report(expert_validity(d, mode = "congruence"))
  expect_true(all(c("best objective", "best IOC") %in% names(desc)))
})

# ---- Relevance: Lynn's criterion and the package's extension of it ----------

relevance_panel <- function(n_experts) {
  set.seed(n_experts)
  m <- matrix(sample(3:4, n_experts * 3, replace = TRUE), n_experts,
              dimnames = list(NULL, paste0("Item", 1:3)))
  m[seq_len(min(3, n_experts)), 3] <- 1
  m
}

test_that("an item that meets the criterion always has modified kappa above .74", {
  N <- 3:400
  req <- contentvalidR:::.cvi_required_count(N)
  k <- vapply(seq_along(N), function(i) {
    a <- req[i]:N[i]
    pc <- stats::dbinom(a, N[i], 0.5)
    min((a / N[i] - pc) / (1 - pc))
  }, numeric(1))
  expect_gt(min(k), 0.74)
  fit <- expert_validity(relevance_panel(8), lo = 1, hi = 4, agreement = "none")
  expect_false("Support" %in% fit$results$recommendation)
  expect_false("n_support" %in% names(fit$scale_summary))
})

test_that("beyond ten experts the criterion is labeled the package's extension", {
  big <- expert_validity(relevance_panel(12), lo = 1, hi = 4, agreement = "none")
  out <- flat(big)
  expect_match(out, "I-CVI criterion for 12 experts: 10 agreeing", fixed = TRUE)
  expect_match(out, "(a contentvalidR extension)", fixed = TRUE)
  h <- content_handoff(big, keep = c("Supported", "Review"))
  expect_match(h$item_evidence$rule[1], "contentvalidR extension of Lynn, 1986",
               fixed = TRUE)

  small <- expert_validity(relevance_panel(8), lo = 1, hi = 4, agreement = "none")
  out <- flat(small)
  expect_match(out, "following Lynn (1986)", fixed = TRUE)
  expect_false(grepl("extension", out, fixed = TRUE))
  hs <- content_handoff(small, keep = c("Supported", "Review"))
  expect_false(grepl("extension", hs$item_evidence$rule[1], fixed = TRUE))
  expect_match(hs$item_evidence$rule[1], "which also puts modified kappa above .74",
               fixed = TRUE)
})

test_that("mixed panel sizes name the extension when one exceeds ten", {
  m <- relevance_panel(12)
  m[1:4, 1] <- NA
  fit <- expert_validity(m, lo = 1, hi = 4, na.rm = TRUE, agreement = "none")
  out <- flat(fit)
  expect_match(out, "I-CVI needed: the criterion of Lynn (1986)", fixed = TRUE)
  expect_match(out, "(a contentvalidR extension)", fixed = TRUE)
})

test_that("the verdict verb agrees with its number", {
  out <- flat(expert_validity(c(10, 8, 6), mode = "essentiality", N = 12))
  expect_match(out, "1 of 3 items meets the exact essentiality criterion.",
               fixed = TRUE)
  one <- expert_validity(matrix(c(4, 4, 4), 3, dimnames = list(NULL, "I1")),
                         lo = 1, hi = 4, agreement = "none")
  expect_match(flat(one), "1 of 1 item meets the I-CVI criterion", fixed = TRUE)
})

# ---- Colquitt et al. (2019) norms: no overall band, and their design --------

sort_two <- function() {
  d <- expand.grid(item = c("A1", "A2", "B1", "B2"), rater = 1:12,
                   stringsAsFactors = FALSE)
  d$target_construct <- substr(d$item, 1, 1)
  d$assigned_construct <- d$target_construct
  d$assigned_construct[d$rater == 12] <- "A"
  d
}

test_that("the sort summary reads each index against its own band", {
  fit <- sort_validity(sort_two())
  s <- fit$scale_summary
  expect_false("overall_strength" %in% names(s))
  expect_false(any(grepl("weaker of", s$evidence, fixed = TRUE)))
  expect_match(s$evidence[1], "mean Csv", fixed = TRUE)
  expect_false(grepl("overall", paste(capture.output(print(summary(fit))),
                                      collapse = " "), fixed = TRUE))
})

test_that("the norms carry a caution when judges did not see three definitions", {
  two <- sort_validity(sort_two())
  expect_match(two$scale_summary$evidence[1],
               "three definitions (one focal, two orbiting); this study offered 2",
               fixed = TRUE)
  three <- sort_validity(sort_two(), n_constructs = 3)
  expect_false(any(grepl("three definitions", three$scale_summary$evidence,
                         fixed = TRUE)))

  set.seed(2)
  rd <- expand.grid(item = c("A1", "B1"), rater = 1:12,
                    construct = c("A", "B", "C", "D"), stringsAsFactors = FALSE)
  rd$target_construct <- ifelse(rd$item == "B1", "B", "A")
  rd$rating <- ifelse(rd$construct == rd$target_construct,
                      sample(4:5, nrow(rd), TRUE), sample(1:3, nrow(rd), TRUE))
  four <- rating_validity(rd)
  expect_false("overall_strength" %in% names(four$scale_summary))
  expect_match(four$scale_summary$evidence[1], "this study offered 4",
               fixed = TRUE)
  three <- rating_validity(rd[rd$construct != "D", ])
  expect_false(any(grepl("three definitions", three$scale_summary$evidence,
                         fixed = TRUE)))
})

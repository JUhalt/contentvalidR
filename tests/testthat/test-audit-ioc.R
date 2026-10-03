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
  expect_match(out, "1 of 3 items meets the congruence criterion for the target objective.",
               fixed = TRUE)
  expect_match(out, "Criterion: IOC at or above .70, the criterion Rovinelli and Hambleton applied.",
               fixed = TRUE)
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
  expect_match(h$item_evidence$rule[1], "(Rovinelli & Hambleton, 1977) for the target objective >= .70, the criterion they applied",
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
  # Documents the claim; "Support" was unreachable before this change too.
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
               "three definitions (one focal, two orbiting); judges here used 2",
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
  expect_match(four$scale_summary$evidence[1], "items here were rated against 4",
               fixed = TRUE)
  three <- rating_validity(rd[rd$construct != "D", ])
  expect_false(any(grepl("three definitions", three$scale_summary$evidence,
                         fixed = TRUE)))
})

# ---- Review of the IOC fixes -------------------------------------------------

ioc_long <- function(item, objective, score, target = NULL) {
  d <- data.frame(item = item, judge = seq_along(score), objective = objective,
                  score = score, stringsAsFactors = FALSE)
  if (!is.null(target)) d$target_objective <- target
  d
}

test_that("with a missing rating the index uses each objective's mean", {
  d <- rbind(ioc_long("I1", "A", c(1, 1, 1, 1)),
             ioc_long("I1", "B", c(-1, -1, -1, -1)),
             ioc_long("I1", "C", c(1, NA, NA, NA)))
  out <- ioc(d, na.rm = TRUE)
  # A: (1 - mean(c(-1, 1))) / 2 = .50, not the pooled (1 - (-.6)) / 2 = .80.
  expect_equal(out$ioc[out$objective == "A"], 0.5)
  expect_equal(out$n_judges, c(4L, 4L, 1L))
  d$target_objective <- "A"
  printed <- flat(expert_validity(d, mode = "congruence", na.rm = TRUE))
  expect_match(printed, "this package's handling of an incomplete design",
               fixed = TRUE)
})

test_that("a criterion the analyst sets is not credited to Rovinelli and Hambleton", {
  fit <- expert_validity(congruence_data(), mode = "congruence", ioc_cut = 0.5)
  out <- flat(fit)
  expect_match(out, "Criterion: IOC at or above .50, set for this analysis (Rovinelli and Hambleton applied .70).",
               fixed = TRUE)
  expect_false(grepl("criterion .70", out, fixed = TRUE))
  h <- content_handoff(fit, keep = c("Supported", "Review"))
  expect_match(h$item_evidence$rule[1],
               ">= .50, set for this analysis (they applied .70)", fixed = TRUE)
  default <- content_handoff(expert_validity(congruence_data(), mode = "congruence"),
                             keep = c("Supported", "Review"))
  expect_match(default$item_evidence$rule[1], ">= .70, the criterion they applied",
               fixed = TRUE)
})

test_that("a congruent item whose rival is rated as high is not called unrivaled", {
  d <- rbind(ioc_long("T1", "A", rep(1, 4)), ioc_long("T1", "B", rep(1, 4)),
             ioc_long("T1", "C", rep(-1, 4)), ioc_long("T1", "D", rep(-1, 4)),
             ioc_long("T1", "E", rep(-1, 4)))
  d$target_objective <- "A"
  fit <- expert_validity(d, mode = "congruence")
  expect_identical(fit$results$recommendation, "Congruent")
  expect_equal(fit$results$margin, 0)
  expect_match(fit$results$interpretation, "the experts rated B as high as",
               fixed = TRUE)
  expect_false(grepl("not to the other objectives", fit$results$interpretation,
                     fixed = TRUE))
})

test_that("items rated on their target only are not said to lack a target", {
  d <- rbind(ioc_long("J1", "A", rep(1, 3), "A"), ioc_long("J2", "B", rep(1, 3), "B"))
  out <- flat(expert_validity(d, mode = "congruence"))
  expect_match(out, "Every item was rated against its target objective only",
               fixed = TRUE)
  expect_false(grepl("No target objective was supplied", out, fixed = TRUE))
})

test_that("the ioc() note about one objective fires only for one objective", {
  d <- rbind(ioc_long("I1", "A", c(1, 1, 1, 1)), ioc_long("I1", "B", c(0, 0, 0, 0)),
             ioc_long("I1", "C", rep(NA_real_, 4)))
  out <- flat(ioc(d, na.rm = TRUE))
  expect_false(grepl("rated against one objective", out, fixed = TRUE))
})

test_that("tied competitors are named as objectives in the handoff note", {
  d <- rbind(ioc_long("I1", "A", rep(1, 4)), ioc_long("I1", "B", rep(0, 4)),
             ioc_long("I1", "C", rep(0, 4)))
  d$target_objective <- "A"
  h <- content_handoff(expert_validity(d, mode = "congruence"))
  note <- h$item_statistics$note[h$item_statistics$statistic == "competitor mean rating"]
  expect_identical(note, "Objectives B, C.")
})

test_that("a congruence fit saved before 1.0 asks to be fitted again", {
  old <- expert_validity(congruence_data(), mode = "congruence")
  old$results <- data.frame(item = c("I1", "I2"), target = c("A", "B"),
                            target_ioc = c(1, 0.75), strongest_competitor = c("B", "A"),
                            competitor_ioc = c(-1, 0.5), margin = c(2, 0.25),
                            recommendation = "Target favored", status = "Supported",
                            stringsAsFactors = FALSE)
  old$settings$ioc_cut <- NULL
  expect_match(flat(old), "made before contentvalidR 1.0", fixed = TRUE)
  expect_error(content_handoff(old), "Fit it again with expert_validity()",
               fixed = TRUE)
  expect_error(content_report(old), "made before contentvalidR 1.0", fixed = TRUE)
  expect_error(plot(old), "made before contentvalidR 1.0", fixed = TRUE)
})

test_that("the congruence plot marks items with no index and labels the criterion", {
  legend <- NULL
  local_mocked_bindings(.legend_top = function(labels, ...) {
    legend <<- labels
    invisible(NULL)
  })
  pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  d <- rbind(ioc_long("I1", "A", rep(1, 4), "A"), ioc_long("I1", "B", rep(-1, 4), "A"),
             ioc_long("I2", "B", rep(1, 4), "B"))
  plot(expert_validity(d, mode = "congruence"))
  expect_identical(legend, c("IOC", "Mean: target", "Mean: competitor",
                             "No index", "Criterion (.70)"))
})

test_that("the bands are stated apart when they differ", {
  r <- data.frame(target = "A", psa = c(.95, .90), csv = c(.20, .25),
                  recommendation = "Retain", stringsAsFactors = FALSE)
  s <- contentvalidR:::.sort_scale_summary(r, orbiting_r = NULL,
                                           judge_type = "naive", n_definitions = 3L)
  expect_match(s$evidence, "^Mean Psa falls in the .+ band and mean Csv in the .+ band")
  expect_false(grepl("three definitions", s$evidence, fixed = TRUE))
})

test_that("the Colquitt caution is labeled, counts what was used, and prints", {
  used <- sort_validity(sort_two())
  expect_match(used$scale_summary$evidence[1],
               "judges here used 2 (set `n_constructs` if more were offered)",
               fixed = TRUE)
  expect_match(used$scale_summary$evidence[1], "This is a contentvalidR caution",
               fixed = TRUE)
  expect_match(flat(used), "judges here used 2", fixed = TRUE)
  offered <- sort_validity(sort_two(), n_constructs = 4)
  expect_match(offered$scale_summary$evidence[1], "this study offered 4",
               fixed = TRUE)

  # Two focal sets, each item rated against its own and two orbiting
  # definitions: the Colquitt design, so no caution.
  set.seed(5)
  mk <- function(items, cons, target) {
    d <- expand.grid(item = items, rater = 1:15, construct = cons,
                     stringsAsFactors = FALSE)
    d$target_construct <- target
    d$rating <- ifelse(d$construct == target, sample(5:7, nrow(d), TRUE),
                       sample(1:4, nrow(d), TRUE))
    d
  }
  d <- rbind(mk(c("A1", "A2"), c("A", "C", "D"), "A"),
             mk(c("B1", "B2"), c("B", "E", "F"), "B"))
  fit <- rating_validity(d, scale_min = 1, scale_max = 7)
  expect_identical(fit$scale_summary$n_definitions, c(3L, 3L))
  expect_false(any(grepl("three definitions", fit$scale_summary$evidence,
                         fixed = TRUE)))
})

test_that("the extension beyond ten experts is labeled where it is applied", {
  out <- flat(expert_power(n_experts = c(8, 12), prob = 0.9))
  expect_match(out, "a contentvalidR extension", fixed = TRUE)
  expect_false(grepl("extension", flat(expert_power(n_experts = c(6, 8), prob = 0.9)),
                     fixed = TRUE))
  big <- flat(expert_validity(relevance_panel(12), lo = 1, hi = 4,
                              agreement = "none"))
  expect_match(big, "extended past ten experts by this package", fixed = TRUE)
  expect_false(grepl("published panel-size guidelines", big, fixed = TRUE))
  X <- matrix(4, 12, 2, dimnames = list(paste0("J", 1:12), c("I1", "I2")))
  X[1:3, 1] <- 2
  note <- paste(contentvalidR:::.fragile_items_notes(
    judge_validity(X, lo = 1, hi = 4)$details$influence_items), collapse = " ")
  expect_match(note, "beyond ten judges, this package's extension", fixed = TRUE)
})

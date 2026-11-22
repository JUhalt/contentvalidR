# Input checks and error messages from the review before the CRAN release of
# 1.0.1: each test names the finding it answers.

r101_csv <- function(file) {
  utils::read.csv(system.file("extdata", file, package = "contentvalidR"))
}

r101_error <- function(expr) {
  tryCatch({
    expr
    NA_character_
  }, error = function(e) conditionMessage(e))
}

# ---- CVR-CODE-1: ioc_cut is checked in every mode ---------------------------

test_that("ioc_cut is checked in relevance and essentiality modes too", {
  rel <- r101_csv("expert_relevance_example.csv")[, -1]
  msg <- "`ioc_cut` must be one number above 0 and at most 1."
  expect_error(expert_validity(rel, mode = "relevance", ioc_cut = 2), msg,
               fixed = TRUE)
  ess <- r101_csv("expert_essentiality_example.csv")[, -1]
  expect_error(expert_validity(ess, mode = "essentiality", ioc_cut = NA), msg,
               fixed = TRUE)
  # The default passes in every mode.
  expect_s3_class(expert_validity(rel, mode = "relevance", agreement = "none"),
                  "contentvalid_expert")
})

test_that("a positional call written for 0.4.0 stops instead of using Wilson", {
  rel <- r101_csv("expert_relevance_example.csv")[, -1]
  # In 0.4.0 the 10th argument was `proportion_ci`; it is now `ioc_cut`.
  err <- r101_error(expert_validity(rel, "relevance", 1, 4, NULL, NULL, 0.05,
                                    FALSE, "target_objective", "exact"))
  expect_match(err, "`ioc_cut` must be one number above 0 and at most 1.",
               fixed = TRUE)
  expect_match(err, "It is the 10th argument, after `target_col`, so pass ",
               fixed = TRUE)
  expect_match(err, "`proportion_ci` and the arguments after it by name.",
               fixed = TRUE)
  # Named, the same interval is used as before.
  fit <- expert_validity(rel, "relevance", proportion_ci = "exact",
                         agreement = "none")
  expect_identical(fit$settings$proportion_ci, "exact")
  # A number out of range gets no positional hint.
  num <- r101_error(expert_validity(rel, ioc_cut = 1.5))
  expect_false(grepl("10th argument", num, fixed = TRUE))
})

# ---- RU-01: target and assigned labels coded differently -------------------

test_that("assigned labels that differ from the targets only in case stop", {
  s <- r101_csv("sort_example.csv")
  s$assigned_construct <- tolower(s$assigned_construct)
  msg <- paste("Target construct(s) A, B, C never appear in",
               "`assigned_construct`, which uses a, b, c. Code both columns",
               "the same way.")
  expect_error(sort_validity(s), msg, fixed = TRUE)
  expect_error(compute_psa(s), msg, fixed = TRUE)
  expect_error(compute_csv(s), msg, fixed = TRUE)
})

test_that("a number written two ways (1 and \"1.0\") stops", {
  s <- r101_csv("sort_example.csv")
  s$target_construct <- match(s$target_construct, LETTERS)
  s$assigned_construct <- sprintf("%.1f", match(s$assigned_construct, LETTERS))
  expect_error(sort_validity(s),
               paste("Target construct(s) 1, 2, 3 never appear in",
                     "`assigned_construct`, which uses 1.0, 2.0, 3.0."),
               fixed = TRUE)
})

test_that("the stop names the user's column name", {
  s <- r101_csv("sort_example.csv")
  names(s)[names(s) == "assigned_construct"] <- "choice"
  s$choice <- tolower(s$choice)
  expect_error(sort_validity(s, assigned_col = "choice"),
               "never appear in `choice`, which uses", fixed = TRUE)
})

test_that("only the target that is coded differently is named", {
  s <- r101_csv("sort_example.csv")
  s$assigned_construct[s$assigned_construct == "B"] <- "b"
  err <- r101_error(sort_validity(s))
  expect_match(err, "Target construct(s) B never appear", fixed = TRUE)
  expect_match(err, "which uses A, b, C.", fixed = TRUE)
})

test_that("a target no judge chose, with no near match, is not an error", {
  s <- r101_csv("sort_example.csv")
  # Every C item reassigned to A: C never appears, and nothing resembles it.
  s$assigned_construct[s$assigned_construct == "C"] <- "A"
  expect_no_error(fit <- sort_validity(s))
  expect_true(all(fit$results$n_target[fit$results$target == "C"] == 0L))
})

test_that("not one assignment matching its target warns once", {
  s <- r101_csv("sort_example.csv")
  # Numbers against letters: nothing to match ignoring case or as a number.
  s$assigned_construct <- c(A = "1", B = "2", C = "3")[s$assigned_construct]
  msg <- paste("Not one assignment in `assigned_construct` equals its item's",
               "`target_construct`, so every item's target count is 0. Check",
               "that both columns code the constructs the same way.")
  w <- character(0)
  fit <- withCallingHandlers(
    sort_validity(s),
    warning = function(cnd) {
      w <<- c(w, conditionMessage(cnd))
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(w, msg)
  expect_true(all(fit$results$n_target == 0L))
  expect_warning(compute_psa(s), msg, fixed = TRUE)
  expect_warning(compute_csv(s), msg, fixed = TRUE)
})

test_that("the bundled sort data raise no condition", {
  for (f in c("sort_example.csv", "walkthrough_sort.csv")) {
    s <- r101_csv(f)
    expect_no_warning(sort_validity(s))
    expect_no_warning(compute_psa(s))
    expect_no_warning(compute_csv(s))
    expect_no_warning(similarity_from_sort(s))
  }
})

test_that("all-missing assignments are left to the existing handling", {
  d <- data.frame(item = rep(c("I1", "I2"), each = 3), rater = rep(1:3, 2),
                  assigned_construct = NA_character_,
                  target_construct = rep(c("A", "B"), each = 3))
  expect_no_warning(fit <- compute_psa(d))
  expect_true(all(is.na(fit$psa)))
})

# ---- RU-02: a target_col the data lack -------------------------------------

test_that("an explicit target_col that is not a column stops", {
  cg <- r101_csv("expert_congruence_example.csv")
  err <- r101_error(expert_validity(cg, mode = "congruence",
                                    target_col = "target"))
  expect_match(err, paste0("`target_col` = \"target\" is not a column of ",
                           "`data` (columns: item, judge, objective, ",
                           "target_objective, score)."), fixed = TRUE)
  expect_match(err, "leave `target_col` out", fixed = TRUE)
  # Naming the default explicitly, on data without it, is also a mistake.
  no_target <- cg[names(cg) != "target_objective"]
  expect_error(expert_validity(no_target, mode = "congruence",
                               target_col = "target_objective"),
               "is not a column of `data`", fixed = TRUE)
})

test_that("without the default column the items are still described", {
  cg <- r101_csv("expert_congruence_example.csv")
  no_target <- cg[names(cg) != "target_objective"]
  fit <- expert_validity(no_target, mode = "congruence")
  expect_true(all(fit$results$recommendation == "Descriptive only"))
  expect_null(fit$settings$target_col)
})

# ---- RU-03 and RU-10: the argument and the column named --------------------

test_that("relevance mode names `data`, the text column and the shape", {
  rel <- r101_csv("expert_relevance_example.csv")[, -1]
  rel$Item3 <- as.character(rel$Item3)
  rel$Item3[2] <- "N/A"
  err <- r101_error(expert_validity(rel))
  expect_match(err, paste0("`data` must hold numeric ratings, but column ",
                           "\"Item3\" holds text (such as \"N/A\")."),
               fixed = TRUE)
  expect_match(err, paste("`data` needs one row per expert and one column per",
                          "item, so data with one row per rating must be",
                          "reshaped first."), fixed = TRUE)
  expect_match(err, "convert that column to numbers, coding a missing rating as NA.",
               fixed = TRUE)
  expect_false(grepl("`ratings`", err, fixed = TRUE))
})

test_that("long data in relevance mode, judge_validity() and panel_agreement() get the shape", {
  rel <- r101_csv("expert_relevance_example.csv")[, -1]
  long <- data.frame(item = rep(names(rel)[1:3], each = nrow(rel)),
                     rating = unlist(rel[1:3], use.names = FALSE))
  shape <- "needs one row per %s and one column per item"
  expect_match(r101_error(expert_validity(long)),
               sprintf(shape, "expert"), fixed = TRUE)
  expect_match(r101_error(judge_validity(long)),
               sprintf(shape, "judge"), fixed = TRUE)
  expect_match(r101_error(panel_agreement(long)),
               sprintf(shape, "rater"), fixed = TRUE)
  expect_match(r101_error(judge_validity(long)),
               "`ratings` must hold numeric ratings, but column \"item\"",
               fixed = TRUE)
})

test_that("direct calls to aikens_v() still name `ratings` and judges", {
  rel <- r101_csv("expert_relevance_example.csv")[, -1]
  m <- as.matrix(rel)
  storage.mode(m) <- "character"
  err <- r101_error(aikens_v(m, lo = 1, hi = 4))
  expect_match(err, "`ratings` must hold numeric ratings, but columns",
               fixed = TRUE)
  expect_match(err, "hold numbers stored as text", fixed = TRUE)
  expect_match(err, "one row per judge", fixed = TRUE)
  expect_error(aikens_v(rel[0, ], lo = 1, hi = 4),
               "`ratings` must contain at least one judge and one item.",
               fixed = TRUE)
  expect_error(expert_validity(rel[0, ]),
               "`data` must contain at least one expert and one item.",
               fixed = TRUE)
})

test_that("congruence mode names `data` and the missing column", {
  cg <- r101_csv("expert_congruence_example.csv")
  names(cg)[names(cg) == "judge"] <- "expert"
  err <- r101_error(expert_validity(cg, mode = "congruence"))
  expect_match(err, paste("`data` must be a data.frame with item, judge,",
                          "objective, and score columns. It has no column",
                          "named judge"), fixed = TRUE)
  expect_match(err, "Rename the columns to match.", fixed = TRUE)
  # Called directly, ioc() names its own argument.
  expect_match(r101_error(ioc(cg)), "`ratings` must be a data.frame",
               fixed = TRUE)
  empty <- cg[0, ]
  names(empty)[names(empty) == "expert"] <- "judge"
  expect_error(expert_validity(empty, mode = "congruence"),
               "`data` contains no rows.", fixed = TRUE)
})

test_that("essentiality coded other than 0/1 says how to code it", {
  ess <- r101_csv("expert_essentiality_example.csv")[, -1]
  ess[] <- lapply(ess, function(z) ifelse(z == 1, 1, 2))
  err <- r101_error(expert_validity(ess, mode = "essentiality"))
  expect_match(err, "`data` must contain only 0/1 values, but columns",
               fixed = TRUE)
  expect_match(err, "hold other values (2).", fixed = TRUE)
  expect_match(err, "Code essential as 1 and every other answer as 0.",
               fixed = TRUE)
  expect_match(r101_error(cvr(ess)), "`essential` must contain only 0/1 values",
               fixed = TRUE)
  text <- r101_csv("expert_essentiality_example.csv")[, -1]
  text[[2]] <- ifelse(text[[2]] == 1, "yes", "no")
  err <- r101_error(expert_validity(text, mode = "essentiality"))
  expect_match(err, paste0("`data` must contain numeric or logical 0/1 ",
                           "values, but column \"", names(text)[2],
                           "\" holds text (such as \""), fixed = TRUE)
  # Counts given to expert_validity() are `data` too.
  expect_error(expert_validity(c(1, Inf), mode = "essentiality", N = 5),
               "`data` must contain finite counts.", fixed = TRUE)
})

# ---- RU-04: a blank assignment ---------------------------------------------

test_that("a blank assignment says to code a skipped item as NA", {
  s <- r101_csv("sort_example.csv")
  s$assigned_construct[1] <- ""
  expect_error(sort_validity(s),
               paste0("`assigned_construct` identifiers cannot be empty. Code ",
                      "an item a judge did not sort as NA, for example ",
                      "read.csv(file, na.strings = c(\"\", \"NA\"))."),
               fixed = TRUE)
  # NA is a missing assignment, as before.
  s$assigned_construct[1] <- NA
  expect_s3_class(sort_validity(s), "contentvalid_sort")
})

# ---- RU-05: a content_evidence() result ------------------------------------

test_that("content_handoff() and content_report() explain an evidence object", {
  wr <- expert_validity(r101_csv("walkthrough_relevance.csv")[, -1], seed = 1,
                        agreement = "none")
  ws <- sort_validity(r101_csv("walkthrough_sort.csv"))
  ce <- content_evidence(relevance = wr, sort = ws)
  expect_error(content_handoff(ce),
               paste("`fit` is a content_evidence() result, which combines",
                     "stages and is not a fitted workflow. Hand off or report",
                     "each stage's fit, use fit$carried for the items every",
                     "deciding stage carried, and as.data.frame(fit) for the",
                     "evidence table."), fixed = TRUE)
  expect_error(content_report(ce),
               "use x$carried for the items every deciding stage carried",
               fixed = TRUE)
  # Other objects get the messages they had.
  expect_error(content_report(list()),
               "`x` must be a fitted contentvalidR workflow object.",
               fixed = TRUE)
})

# ---- RU-06: ratings outside the scale --------------------------------------

test_that("rating_validity() gives the bounds, the defaults and the range", {
  r <- r101_csv("rating_example.csv")
  r$rating <- r$rating + 2
  expect_error(rating_validity(r),
               paste0("Ratings run from 3 to 7, outside `scale_min` = 1 to ",
                      "`scale_max` = 5 (the defaults). Set `scale_min` and ",
                      "`scale_max` to the lowest and highest points of the ",
                      "scale the judges used, or correct the ratings."),
               fixed = TRUE)
  expect_error(rating_validity(r, scale_max = 6),
               "`scale_max` = 6 (`scale_min` is the default).", fixed = TRUE)
  expect_error(htc(r, scale_min = 1, scale_max = 6),
               "`scale_max` = 6. Set", fixed = TRUE)
  expect_s3_class(rating_validity(r, scale_max = 7), "contentvalid_rating")
})

test_that("judge_validity() gives the bounds, the defaults and the range", {
  rel <- r101_csv("expert_relevance_example.csv")[, -1]
  rel[1, 1] <- 5
  lo_obs <- format(min(as.matrix(rel)))
  expect_error(judge_validity(rel),
               paste0("Ratings run from ", lo_obs, " to 5, outside `lo` = 1 ",
                      "to `hi` = 4 (the defaults). Set `lo` and `hi`"),
               fixed = TRUE)
  expect_error(judge_validity(rel, lo = 1, hi = 4),
               "`hi` = 4. Set `lo` and `hi`", fixed = TRUE)
})

# ---- RU-16: a list of fits -------------------------------------------------

test_that("compare_rounds() says how to pass a list of fits", {
  s <- r101_csv("sort_example.csv")
  f1 <- sort_validity(s)
  f2 <- sort_validity(s[s$rater <= 12, ])
  expect_error(compare_rounds(list(f1, f2)),
               paste("`compare_rounds()` was given one list of 2 fitted",
                     "workflows. Pass the fits as separate arguments, or use",
                     "do.call(compare_rounds, fits)."), fixed = TRUE)
  expect_s3_class(do.call(compare_rounds, list(f1, f2)),
                  "contentvalid_rounds")
  # One fit on its own keeps its message.
  expect_error(compare_rounds(f1),
               "`compare_rounds()` needs at least two fitted workflow objects.",
               fixed = TRUE)
})

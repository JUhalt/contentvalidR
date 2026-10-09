# Fixes from the pre-1.0 audit of the expert-panel functions. Each test names
# the wrong result the old code gave.

test_that("on a two-point scale the default cut is the top point, not the bottom", {
  # The default was hi - 1, the lowest point of a 0/1 scale, so every rating
  # counted as relevant and an item no expert endorsed got I-CVI 1.00.
  b <- cbind(Q1 = c(1, 1, 1, 1, 1, 1), Q2 = c(1, 1, 1, 0, 1, 1),
             Q3 = c(0, 0, 1, 0, 0, 0), Q4 = c(0, 0, 0, 0, 0, 0))
  fit <- expert_validity(b, lo = 0, hi = 1, agreement = "none")
  expect_identical(fit$settings$relevance_cut, 1)
  expect_equal(fit$results$I_CVI, c(1, 5 / 6, 1 / 6, 0))
  expect_equal(fit$results$I_CVI, as.data.frame(cvi(b)$item_level)$I_CVI)
  expect_identical(fit$results$recommendation,
                   c("Strong support", "Strong support", "Review", "Review"))

  # The same on a 1/2 coding, and in the judge and Delphi workflows.
  expect_identical(expert_validity(b + 1, lo = 1, hi = 2,
                                   agreement = "none")$settings$relevance_cut, 2)
  expect_identical(judge_validity(b, lo = 0, hi = 1)$settings$relevance_cut, 1)
  long <- data.frame(expert = rep(paste0("E", 1:6), times = 8),
                     item = rep(rep(colnames(b), each = 6), 2),
                     round = rep(1:2, each = 24), rating = rep(as.vector(b), 2))
  delphi <- delphi_validity(long, lo = 0, hi = 1, consensus_threshold = .75,
                            B = 0)
  expect_identical(delphi$settings$agree_cut, 1)
  expect_identical(delphi$results$recommendation,
                   c("Consensus", "Consensus", "No consensus", "No consensus"))
  # Longer scales keep the usual cut.
  expect_identical(contentvalidR:::.default_cut(1, 4), 3)
  expect_identical(contentvalidR:::.default_cut(1, 5), 4)
  expect_identical(contentvalidR:::.default_cut(1, 3), 2)
})

test_that("a cut at the bottom of the scale is refused, with the reason", {
  R <- cbind(A = c(4, 3, 4), B = c(2, 3, 4))
  expect_error(expert_validity(R, relevance_cut = 1),
               "cannot be the lowest point of the scale")
  expect_error(judge_validity(R, relevance_cut = 1),
               "cannot be the lowest point of the scale")
  long <- data.frame(expert = rep(1:3, 4), item = rep(rep(c("A", "B"), each = 3), 2),
                     round = rep(1:2, each = 6), rating = rep(as.vector(R), 2))
  expect_error(delphi_validity(long, lo = 1, hi = 4, agree_cut = 1, B = 0),
               "cannot be the lowest point of the scale")
  expect_error(expert_validity(R, relevance_cut = 9), "within the rating scale")
})

test_that("the relevance print states the scale and the cut", {
  R <- cbind(A = c(4, 3, 4), B = c(2, 3, 4))
  out <- capture.output(print(expert_validity(R, agreement = "none")))
  expect_true(any(out == "Scale: 1 to 4 | Relevant: a rating of 3 or higher"))
  out5 <- capture.output(print(expert_validity(R, lo = 1, hi = 5,
                                               agreement = "none")))
  expect_true(any(out5 == "Scale: 1 to 5 | Relevant: a rating of 4 or higher"))
  out2 <- capture.output(print(expert_validity((R >= 3) + 0, lo = 0, hi = 1,
                                               agreement = "none")))
  expect_true(any(out2 == "Scale: 0 to 1 | Relevant: a rating of 1"))
})

test_that("a rater-ID column is not analyzed as an item", {
  rel <- read.csv(system.file("extdata", "expert_relevance_example.csv",
                              package = "contentvalidR"))
  expect_true("expert" %in% names(rel))
  # With four experts on a 1-4 scale the IDs 1 to 4 are valid ratings, so the
  # column used to become an item called "expert".
  expect_error(expert_validity(rel[1:4, ]), "looks like a rater ID")
  expect_error(expert_validity(rel[1:4, ]), "data[, -1]", fixed = TRUE)
  expect_error(judge_validity(rel[1:4, ]), "looks like a rater ID")
  expect_error(aikens_v(rel[1:4, ], lo = 1, hi = 4), "looks like a rater ID")
  expect_error(cvr(data.frame(Judge = 1:3, A = c(1, 0, 1))),
               "looks like a rater ID")
  expect_error(expert_validity(data.frame(rater_id = 0:1, A = c(1, 0)),
                               mode = "essentiality"), "looks like a rater ID")
  fit <- expert_validity(rel[1:4, -1], agreement = "none")
  expect_false("expert" %in% fit$results$item)
  expect_identical(fit$design$n_items, 5L)
  # An ordinary item name is left alone.
  ok <- cbind(Expertise = c(4, 3, 4), Identity = c(3, 4, 4))
  expect_silent(expert_validity(ok, agreement = "none"))

  # Every function that takes a judge-by-item table checks.
  wide <- data.frame(ID = 1:3, A = c(1, 0, 1), B = c(1, 1, 0))
  expect_error(cvi(wide), "looks like a rater ID")
  expect_error(gtheory_content(wide), "looks like a rater ID")
  expect_error(panel_agreement(wide), "looks like a rater ID")
})

test_that("the row-number column of a CSV round trip is caught, and the message helps", {
  df <- data.frame(Q1 = c(4, 4, 3, 4), Q2 = c(3, 4, 4, 4), Q3 = c(2, 3, 4, 4))
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  utils::write.csv(df, path)
  back <- utils::read.csv(path)
  expect_identical(names(back)[1], "X")
  # With four experts on a 1-4 scale, X held 1 to 4 and became an item.
  expect_error(expert_validity(back, agreement = "none"),
               "has a column named \"X\", which looks like a rater ID")
  # A column called X that does not count the rows is an item.
  x_item <- data.frame(X = c(4, 4, 3, 4), Q2 = c(3, 4, 4, 4))
  expect_identical(expert_validity(x_item, agreement = "none")$results$item,
                   c("X", "Q2"))

  # Two ID columns: plural wording, and a fix that removes both.
  two <- data.frame(I1 = c(3, 4, 4), I2 = c(4, 4, 3), rater = 1:3,
                    I3 = c(4, 3, 4), coder_id = 1:3)
  msg <- tryCatch(expert_validity(two, agreement = "none"),
                  error = conditionMessage)
  expect_match(msg, "has columns named \"rater\", \"coder_id\", which look like rater IDs",
               fixed = TRUE)
  expect_match(msg, "data[, -c(3, 5)]", fixed = TRUE)
  expect_match(msg, "rename it", fixed = TRUE)
})

test_that("a Delphi item named like a rater ID is still an item", {
  # delphi_validity() builds its own judge-by-item table from long data, so
  # the columns are item labels and the check does not apply.
  long <- expand.grid(expert = paste0("e", 1:5), item = c("Subject", "ID", "I3"),
                      round = 1:2, stringsAsFactors = FALSE)
  long$rating <- rep(c(4, 3, 4, 2, 4, 3), length.out = nrow(long))
  fit <- delphi_validity(long, lo = 1, hi = 4, B = 0)
  expect_setequal(fit$results$item, c("Subject", "ID", "I3"))
  # The switch is off again afterwards.
  expect_error(expert_validity(data.frame(ID = 1:3, A = c(4, 3, 4))),
               "looks like a rater ID")
})

test_that("an out-of-range rating names its column and the scale", {
  R <- cbind(A = c(4, 3, 4), B = c(2, 5, 4))
  expect_error(aikens_v(R, lo = 1, hi = 4),
               "bounds (1 to 4) in column \"B\"", fixed = TRUE)
  expect_error(expert_validity(R), "in column \"B\"", fixed = TRUE)
  # It says what to do, counts the columns, and stops listing after five.
  expect_error(expert_validity(cbind(A = c(5, 4, 5), B = c(4, 5, 5))),
               "in columns \"A\", \"B\". Set `lo` and `hi`", fixed = TRUE)
  many <- matrix(7, 3, 30, dimnames = list(NULL, paste0("Item", 1:30)))
  expect_error(aikens_v(many, lo = 1, hi = 4),
               "\"Item5\" and 25 more.", fixed = TRUE)
  expect_error(aikens_v(matrix(c(4, 4, 9), 3, 1), lo = 1, hi = 4),
               "in column 1.", fixed = TRUE)
})

test_that("aikens_v() needs the scale, and reports it", {
  R <- cbind(A = c(4, 4, 4), B = c(3, 4, 4))
  expect_error(aikens_v(R), "`lo` and `hi` are required")
  expect_error(aikens_v(R, lo = 1), "`lo` and `hi` are required")
  v <- aikens_v(R, lo = 1, hi = 4)
  expect_equal(v$V, c(1, 8 / 9))
  expect_identical(attr(v, "scale"), c(1, 4))
  expect_true(any(capture.output(print(v)) == "Scale: 1 to 4."))
  # The same ratings on a longer scale give a lower V, which is why the scale
  # is never assumed.
  expect_equal(aikens_v(R, lo = 1, hi = 5)$V, c(.75, 2 / 3))
})

test_that("named essential counts keep their names, into the handoff", {
  fit <- expert_validity(c(Q1 = 12, Q2 = 10, Q3 = 6), mode = "essentiality",
                         N = 12)
  expect_identical(fit$results$item, c("Q1", "Q2", "Q3"))
  expect_identical(content_handoff(fit)$items, c("Q1", "Q2"))
  expect_identical(as.data.frame(cvr(c(A = 8, B = 5), N = 12))$item, c("A", "B"))
  # An explicit item_names still wins, and unnamed counts keep the default.
  expect_identical(
    as.data.frame(cvr(c(A = 8, B = 5), N = 12, item_names = c("x", "y")))$item,
    c("x", "y")
  )
  expect_identical(as.data.frame(cvr(c(8, 5), N = 12))$item, c("Item1", "Item2"))
  # Names that cannot serve (blank, missing or repeated) fall back to numbers.
  for (bad in list(c("a", ""), c("a", NA), c("a", "a"))) {
    expect_identical(
      as.data.frame(cvr(stats::setNames(c(8, 9), bad), N = 10))$item,
      c("Item1", "Item2")
    )
  }
})

test_that("a panel too small for the exact test gives no decision, and says why", {
  # Four of four essential gives p = .0625, so nothing can pass at .05. Such
  # items were labeled Review, as if experts had disagreed.
  fit <- expert_validity(c(4, 3, 2), mode = "essentiality", N = 4)
  expect_identical(fit$results$recommendation, rep("Insufficient panel", 3))
  expect_identical(fit$results$status, rep("Insufficient data", 3))
  expect_identical(fit$scale_summary$n_review, 0L)
  expect_identical(fit$scale_summary$n_insufficient, 3L)
  out <- paste(capture.output(print(fit)), collapse = " ")
  expect_match(out, "Too few experts for the exact test: Item1, Item2, Item3.",
               fixed = TRUE)
  expect_match(out, "With 4 or fewer experts, no count of essential ratings",
               fixed = TRUE)
  expect_match(out, "Insufficient panel -- too few experts rated it",
               fixed = TRUE)
  expect_false(grepl("Flagged for review", out, fixed = TRUE))

  rule <- content_handoff(
    fit, keep = c("Supported", "Review", "Insufficient data")
  )$item_evidence$rule
  expect_false(any(grepl("NA", rule, fixed = TRUE)))
  expect_match(rule[1], "no count of essential ratings out of 4 can meet",
               fixed = TRUE)

  # Five experts can decide: all five must agree.
  five <- expert_validity(c(5, 4), mode = "essentiality", N = 5)
  expect_identical(five$results$recommendation, c("Supported", "Review"))

  # The component says the same.
  comp <- gsub("\\s+", " ",
               paste(capture.output(print(cvr(c(4, 3), N = 4))), collapse = " "))
  # .0625 is an exact tie at three decimals and rounds half up. No count can
  # pass, so the component's decision column reads -- and is still shown.
  expect_match(comp, "4/4 1\\.00 \\.063 none --")
  expect_equal(cvr(4, N = 4)$p_value, 1 / 16)
  expect_match(comp, "With 4 or fewer experts, no count of essential ratings",
               fixed = TRUE)
  expect_false(grepl("NA", comp, fixed = TRUE))
})

test_that("a mixed panel shows every kind of decision without a raw NA count", {
  # Twelve experts rated A to C, four rated D and E, none rated F.
  M <- matrix(c(rep(1, 12), c(rep(1, 10), 0, 0), c(rep(1, 6), rep(0, 6)),
                c(1, 1, 1, 1, rep(NA, 8)), c(1, 1, 0, 1, rep(NA, 8)),
                rep(NA, 12)),
              nrow = 12, dimnames = list(NULL, c("A", "B", "C", "D", "E", "F")))
  fit <- expert_validity(M, mode = "essentiality", na.rm = TRUE)
  expect_identical(fit$results$recommendation,
                   c("Supported", "Supported", "Review", "Insufficient panel",
                     "Insufficient panel", "Insufficient data"))

  lines <- capture.output(print(fit))
  row <- function(item) {
    strsplit(trimws(grep(paste0("^ +", item, " "), lines, value = TRUE)[1]),
             " +")[[1]]
  }
  # The needed column printed NA beside "Insufficient panel".
  expect_identical(utils::tail(row("A"), 1), "10")
  expect_identical(utils::tail(row("D"), 1), "none")
  expect_identical(utils::tail(row("F"), 1), "--")
  out <- gsub("\\s+", " ", paste(lines, collapse = " "))
  expect_match(out, "Too few experts for the exact test: D, E.", fixed = TRUE)
  expect_match(out, "Insufficient data: F", fixed = TRUE)

  # The summary counts the two reasons for no decision apart.
  sm <- gsub("\\s+", " ",
             paste(capture.output(print(summary(fit))), collapse = " "))
  expect_match(sm, "Supported: 2 of 6 | Review: 1 of 6 | Too few experts: 2 | Insufficient data: 1",
               fixed = TRUE)

  # Each kind of item has its own handoff rule, none with a missing count.
  rule <- content_handoff(
    fit, keep = c("Supported", "Review", "Insufficient data")
  )$item_evidence$rule
  expect_false(any(grepl("NA", rule, fixed = TRUE)))
  expect_match(rule[1], "at least 10 of 12 judges", fixed = TRUE)
  expect_match(rule[4], "no count of essential ratings out of 4 can meet",
               fixed = TRUE)
  expect_match(rule[6], "no expert rated the item", fixed = TRUE)

  # The component marks both no-decision rows the same way.
  comp <- capture.output(print(cvr(M, na.rm = TRUE)))
  expect_true(any(grepl("^ +D +4/4 .* none +--$", comp)))
  expect_true(any(grepl("^ +F +0/0 .* -- +--$", comp)))
})

test_that("a seeded call leaves the session's random stream as it found it", {
  R <- rbind(c(4, 4, 3, 2, 4), c(4, 3, 3, 2, 4), c(3, 4, 4, 1, 4),
             c(4, 4, 3, 2, 3))
  colnames(R) <- paste0("I", 1:5)
  after <- function(seed, call) {
    set.seed(seed)
    force(call)
    stats::runif(1)
  }
  for (start in c(101, 202)) {
    set.seed(start); expected <- stats::runif(1)
    expect_identical(after(start, panel_agreement(R, B = 50, seed = 1)), expected)
    expect_identical(after(start, expert_validity(R, agreement_B = 50, seed = 1)),
                     expected)
    expect_identical(
      after(start, aikens_v(R, lo = 1, hi = 4, ci = "bootstrap", B = 20, seed = 1)),
      expected
    )
  }
  # The result itself is still reproducible.
  expect_identical(panel_agreement(R, B = 50, seed = 7)$ci_low,
                   panel_agreement(R, B = 50, seed = 7)$ci_low)
})

test_that("a seed gives the draws set.seed() gives", {
  # withr seeds and restores the stream; the draws under a seed are those of
  # a plain set.seed(), as they were before the package used withr.
  with_seed <- contentvalidR:::.with_seed
  set.seed(11); plain <- c(stats::runif(3), sample(20))
  # An integer seed and a whole double give the same draws.
  expect_identical(with_seed(11L, c(stats::runif(3), sample(20))), plain)
  expect_identical(with_seed(11, c(stats::runif(3), sample(20))), plain)

  # No seed: the code runs on the session's stream and moves it.
  set.seed(5); expected <- stats::runif(2)
  set.seed(5)
  expect_identical(c(with_seed(NULL, stats::runif(1)), stats::runif(1)), expected)
})

test_that("a seed gives the draws set.seed() gives under another generator", {
  # withr from 2.5.0 seeds within the caller's kind of generator; 2.4.2 and
  # 2.4.3 switched to the default kind, which changes seeded results. That is
  # why DESCRIPTION asks for 2.5.0.
  with_seed <- contentvalidR:::.with_seed
  before <- RNGkind()
  # The session's generator and stream are put back when the block ends.
  withr::with_preserve_seed(local({
    kinds <- RNGkind("Wichmann-Hill", "Box-Muller")
    on.exit(RNGkind(kinds[1], kinds[2]), add = TRUE)
    set.seed(11); plain <- c(stats::runif(3), stats::rnorm(2))
    expect_identical(with_seed(11L, c(stats::runif(3), stats::rnorm(2))), plain)
    expect_identical(RNGkind()[1:2], c("Wichmann-Hill", "Box-Muller"))
  }))
  expect_identical(RNGkind(), before)
})

test_that("a seed too large for an integer is refused by name", {
  R <- rbind(c(4, 4, 3, 2, 4), c(4, 3, 3, 2, 4), c(3, 4, 4, 1, 4),
             c(4, 4, 3, 2, 3))
  colnames(R) <- paste0("I", 1:5)
  for (big in c(2^31, -2^31)) {
    expect_error(panel_agreement(R, B = 20, seed = big), "`seed` must be")
    expect_error(expert_validity(R, lo = 1, hi = 4, agreement_B = 20, seed = big),
                 "`seed` must be")
    expect_error(aikens_v(R, lo = 1, hi = 4, ci = "bootstrap", B = 20, seed = big),
                 "`seed` must be")
  }
  long <- data.frame(item = rep(paste0("I", 1:6), each = 30),
                     rater = rep(1:10, times = 18),
                     construct = rep(rep(LETTERS[1:3], each = 10), times = 6),
                     rating = rep(c(1, 3, 2, 5, 4, 2, 3, 1, 5, 4), times = 18))
  expect_error(qfactor_content(long, seed = 2^31), "`seed` must be")
  # The largest integer is a seed like any other.
  top <- .Machine$integer.max
  expect_identical(panel_agreement(R, B = 20, seed = top)$ci_low,
                   panel_agreement(R, B = 20, seed = top)$ci_low)
})

test_that("no function of the package reaches for the global environment", {
  # CRAN: a package may not write to the user's workspace. Restoring the
  # random stream by hand needs assign() or rm() there, so that is left to
  # withr. Each function is read whole, as text: its arguments' defaults, any
  # function defined inside it, and names given as strings. `<<-`,
  # as.environment() and assign(pos = ) are refused outright, whether or not
  # a given use would reach the workspace, because the package needs none.
  ns <- asNamespace("contentvalidR")
  fns <- Filter(function(n) is.function(get(n, envir = ns)),
                ls(ns, all.names = TRUE))
  expect_gt(length(fns), 300L)
  pattern <- paste0("globalenv|\\.GlobalEnv|<<-|\\.Random\\.seed|set\\.seed|",
                    "as\\.environment|assign\\([^)]*pos *=")
  reaches <- vapply(fns, function(n) {
    grepl(pattern, paste(deparse(get(n, envir = ns)), collapse = "\n"))
  }, NA)
  expect_identical(fns[reaches], character(0))

  # The scan sees what it must: a default argument, a nested function, a
  # name given as a string, and a position.
  caught <- function(f) grepl(pattern, paste(deparse(f), collapse = "\n"))
  expect_true(caught(function(x, envir = globalenv()) x))
  expect_true(caught(function(x) lapply(x, function(i, e = .GlobalEnv) i)))
  expect_true(caught(function(x) get(".Random.seed", envir = baseenv())))
  expect_true(caught(function(x) assign("a", x, pos = 1)))
  expect_true(caught(function(x) do.call("set.seed", list(x))))
  expect_false(caught(function(x) withr::with_seed(1L, x)))
})

test_that("the AC1 bootstrap scores every resample on the same categories", {
  ac1 <- contentvalidR:::.gwet_ac1
  # Three categories overall; this resample contains only two of them.
  X <- rbind(c(1, 2, 3, 3), c(1, 2, 3, 2), c(1, 2, 2, 3))
  sub <- X[, c(1, 1, 2, 2), drop = FALSE]
  fixed <- ac1(sub, values = c(1, 2, 3))
  free <- ac1(sub)
  # Perfect agreement either way, but chance agreement differs with q.
  expect_equal(fixed$pe, sum(c(.5, .5, 0) * (1 - c(.5, .5, 0))) / 2)
  expect_equal(free$pe, sum(c(.5, .5) * (1 - c(.5, .5))) / 1)
  # The point estimate is unchanged: observed categories, as irrCAC does.
  expect_equal(panel_agreement(X, method = "ac1", B = 0)$estimate,
               ac1(X)$estimate)
  # The interval is the one the fixed categories give.
  set.seed(11)
  draws <- vapply(1:200, function(b) {
    ac1(X[, sample.int(4, 4, replace = TRUE), drop = FALSE], c(1, 2, 3))$estimate
  }, numeric(1))
  got <- panel_agreement(X, method = "ac1", B = 200, seed = 11)
  expect_equal(got$ci_low, stats::quantile(draws[is.finite(draws)], .025,
                                           names = FALSE))
})

test_that("an undefined agreement coefficient is not printed as NA", {
  same <- matrix(4, 3, 4)
  out <- capture.output(print(panel_agreement(same, B = 20, seed = 1)))
  expect_false(any(grepl("= NA", out, fixed = TRUE)))
  expect_true(any(grepl(": undefined$", out)))
  expect_false(any(grepl("resamples", out, fixed = TRUE)))
})

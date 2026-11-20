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

# Six judges rate three items against objectives A to C, with the target
# mapping of the example data or without it.
congruence_fit <- function(targeted = TRUE, ...) {
  d <- read.csv(extdata("expert_congruence_example.csv"),
                stringsAsFactors = FALSE)
  if (!targeted) d$target_objective <- NULL
  expert_validity(d, mode = "congruence", ...)
}

# Runs `expr` on a blank PDF device with the graphics function `fun` traced,
# and returns `what` for each call to `fun` in which `when` holds, as a list.
# The tracer runs in the traced function's frame, so `what` and `when` can
# name its arguments.
recorded <- function(fun, what, expr, when = TRUE) {
  rec <- new.env()
  rec$values <- list()
  tracer <- bquote(if (.(when)) {
    assign("values", c(get("values", envir = .(rec)), list(.(what))),
           envir = .(rec))
  })
  suppressMessages(trace(fun, tracer = tracer, print = FALSE,
                         where = asNamespace("graphics")))
  on.exit(suppressMessages(untrace(fun, where = asNamespace("graphics"))),
          add = TRUE)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  force(expr)
  rec$values
}

# Each line the flow diagram fits into a box, as given before it is wrapped.
flow_lines <- function(ev) {
  real <- contentvalidR:::.evidence_fit_text
  seen <- new.env()
  seen$text <- character(0)
  local_mocked_bindings(.evidence_fit_text = function(text, ...) {
    seen$text <- c(seen$text, text)
    real(text, ...)
  })
  grDevices::pdf(NULL, width = 7, height = 5)
  on.exit(grDevices::dev.off(), add = TRUE)
  plot(ev, type = "flow")
  unique(seen$text)
}

# ---- content_handoff(): the panel note ------------------------------------

test_that("a skipped agreement bootstrap is noted as skipped, not as failed", {
  rel <- read.csv(extdata("expert_relevance_example.csv"))
  rel$expert <- NULL
  fit <- expert_validity(rel, mode = "relevance", lo = 1, hi = 4,
                         agreement_B = 0)
  ag <- fit$details$agreement
  expect_identical(ag$B, 0L)
  expect_true(is.finite(ag$estimate))
  ps <- content_handoff(fit)$panel_statistics
  expect_identical(nrow(ps), 1L)
  expect_equal(ps$value, panel_agreement(rel, B = 0)$estimate)
  # agreement_B = 0 skips the bootstrap on purpose; no resample failed.
  expect_identical(ps$note, paste("The bootstrap was skipped",
                                  "(agreement_B = 0), so the coefficient",
                                  "has no interval."))
  # The four interval columns are missing together, as the schema says.
  expect_true(all(is.na(c(ps$lower, ps$upper, ps$interval_level))))
  expect_true(is.na(ps$interval_method))
})

# ---- content_handoff(): congruence fits edited by hand ---------------------

test_that("an untargeted congruence fit without its details has no counts", {
  fit <- congruence_fit(targeted = FALSE)
  h <- content_handoff(fit)
  expect_identical(h$item_evidence$n_judges, rep(6L, 3))
  # Without `details` there are no cells to count judges from, so the count
  # is not recorded, and the index is still carried.
  fit$details <- NULL
  h <- content_handoff(fit)
  expect_identical(h$item_evidence$n_judges, rep(NA_integer_, 3))
  expect_identical(h$item_statistics$statistic, rep("highest IOC", 3))
  expect_equal(h$item_statistics$value, fit$results$best_ioc)
})

test_that("an untargeted fit whose cells carry no counts has no counts", {
  fit <- congruence_fit(targeted = FALSE)
  fit$details$cells$n_judges <- NULL
  h <- content_handoff(fit)
  expect_identical(h$item_evidence$n_judges, rep(NA_integer_, 3))
})

test_that("a congruence fit that records no criterion is read against .70", {
  fit <- congruence_fit()
  fit$settings$ioc_cut <- NULL
  h <- content_handoff(fit)
  target <- h$item_statistics[h$item_statistics$statistic == "target IOC", ]
  expect_identical(target$criterion, rep(0.70, 3))
  expect_true(all(grepl(
    "for the target objective >= .70, the criterion they applied",
    h$item_evidence$rule, fixed = TRUE)))
})

test_that("a targeted fit without a count column counts judges by cell", {
  fit <- congruence_fit()
  fit$results$n_judges <- NULL
  # Distinct counts show which cell each item's count is taken from: the
  # item's own row against its target objective.
  cells <- fit$details$cells
  fit$details$cells$n_judges <- seq_len(nrow(cells))
  expected <- which(paste(cells$item, cells$objective) %in%
                      paste(fit$results$item, fit$results$target))
  expect_identical(expected, c(1L, 5L, 9L))
  h <- content_handoff(fit)
  expect_identical(h$item_evidence$item, c("I1", "I2", "I3"))
  expect_identical(h$item_evidence$n_judges, expected)
})

test_that("a targeted fit with no counts in results or cells has none", {
  fit <- congruence_fit()
  fit$results$n_judges <- NULL
  fit$details <- list()
  h <- content_handoff(fit)
  expect_identical(h$item_evidence$n_judges, rep(NA_integer_, 3))
  # The decisions are carried as the fit made them.
  expect_identical(h$items, fit$results$item[fit$results$status ==
                                               "Supported"])
})

test_that("a congruence fit stripped of both index columns has no statistics", {
  fit <- congruence_fit()
  # The mean rating on the target is left, so the fit is not taken for one
  # made before 1.0, but there is no index to carry.
  fit$results$target_ioc <- NULL
  h <- content_handoff(fit)
  expect_identical(nrow(h$item_statistics), 0L)
  expect_identical(names(h$item_statistics),
                   c("item", "statistic", "value", "criterion", "round",
                     "lower", "upper", "interval_method", "interval_level",
                     "note"))
  expect_identical(h$item_evidence$item, c("I1", "I2", "I3"))
})

# ---- content_handoff(): other input edited by hand -------------------------

test_that("a fit whose results lost the item column is refused", {
  fit <- relevance_panel()
  fit$results$item <- NULL
  expect_error(content_handoff(fit),
               paste("This workflow's results have no `item` column, so",
                     "there is no item set to carry forward."),
               fixed = TRUE)
})

test_that("a stability method that is not one name gives no reading", {
  res <- data.frame(item = c("S1", "S2"), stable = c(TRUE, FALSE))
  reading <- contentvalidR:::.handoff_delphi_reading
  expect_identical(reading(NULL, res), c("", ""))
  expect_identical(reading(c("percent_change", "kappa"), res), c("", ""))
  # One name it knows gives the rule and the fit's reading.
  rule <- "Stable when the change is below .15, the rule of Scheibe et al."
  expect_identical(reading("percent_change", res),
                   paste(rule, "(1975/2002).",
                         c("Read as stable.", "Not read as stable.")))
})

test_that("one status in keep is quoted as typed, without c()", {
  keep_text <- contentvalidR:::.handoff_keep_text
  expect_identical(keep_text("Supported"), "\"Supported\"")
  expect_identical(keep_text(c("Supported", "Descriptive only")),
                   "c(\"Supported\", \"Descriptive only\")")
})

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

test_that("the flow box of a stage without judge counts says so", {
  h <- content_handoff(relevance_panel())
  h$item_evidence$n_judges <- NA_integer_
  text <- flow_lines(content_evidence(Panel = h))
  expect_true("4 items reviewed; number of experts not recorded" %in% text)
  expect_false(any(grepl("reviewed by experts", text, fixed = TRUE)))
  # A stage that recorded its counts still names them.
  text <- flow_lines(content_evidence(Panel = relevance_panel()))
  expect_true("4 items reviewed by 4 experts" %in% text)
})

test_that("an empty text fits a box as one empty line", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::plot.new()
  fit <- contentvalidR:::.evidence_fit_text(c("", "Stage 1: Panel"), font = 2,
                                            room = 1, cex = 0.85,
                                            smallest = 0.5)
  expect_identical(fit$cex, 0.85)
  expect_identical(fit$lines, list("", "Stage 1: Panel"))
})

# ---- The rating-distribution view ------------------------------------------

test_that("a round given no status draws every symbol as no decision", {
  ratings <- matrix(c(4, 4, 3, 2, 4, 3, 4, 1), nrow = 4,
                    dimnames = list(NULL, c("I1", "I2")))
  draw <- quote(contentvalidR:::.plot_rating_distribution(
    rounds = list(ratings), items = c("I1", "I2"), lo = 1, hi = 4, cut = 3,
    criterion = 0.78, status = list(NULL), value_label = "I-CVI",
    axis_label = "Share of experts", labels = NULL, apa = TRUE,
    show_legend = TRUE
  ))
  # The symbol beside each bar is a cross, the symbol for no decision.
  pch <- recorded("points", quote(list(...)[["pch"]]), eval(draw),
                  when = quote(identical(x, 1.06)))
  expect_identical(pch, list(4L, 4L))
  # The key lists only what the figure draws: the criterion and the cross.
  keys <- recorded("legend", quote(legend), eval(draw),
                   when = quote(is.null(fill)))
  expect_identical(keys, list(c("Criterion", "No decision")))
})

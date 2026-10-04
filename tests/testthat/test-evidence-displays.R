# content_evidence(), its evidence profile and flow diagram, and the
# rating-distribution view of expert and Delphi fits. The figures only draw
# what the fits and handoffs already decided, so most of these tests check
# what is read, not how it looks.

extdata <- function(f) system.file("extdata", f, package = "contentvalidR")

wt_relevance_fit <- function() {
  r <- read.csv(extdata("walkthrough_relevance.csv"), stringsAsFactors = FALSE)
  R <- as.matrix(r[setdiff(names(r), "expert")])
  expert_validity(R, mode = "relevance", lo = 1, hi = 4, agreement = "none")
}
wt_sorted <- function() {
  read.csv(extdata("walkthrough_sort.csv"), stringsAsFactors = FALSE)
}
# The usual order: the sort reviews what the relevance panel carried.
wt_sequential <- function() {
  panel <- content_handoff(wt_relevance_fit())
  sort <- content_handoff(sort_validity(wt_sorted()[wt_sorted()$item %in%
                                                      panel$items, ]))
  content_evidence(`Relevance panel` = panel, `Item sort` = sort)
}

draws <- function(expr) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  force(expr)
}

test_that("stages in sequence carry what every reviewing stage carried", {
  ev <- wt_sequential()
  expect_s3_class(ev, "contentvalid_evidence")
  expect_named(ev$stages, c("Relevance panel", "Item sort"))
  expect_identical(ev$items[1:6], paste0("EF", 1:6))
  expect_setequal(ev$carried, setdiff(ev$items, c("EF5", "TF5")))

  expect_identical(ev$flow[[1]]$held, "EF5")
  expect_identical(ev$flow[[2]]$held, "TF5")
  expect_length(ev$flow[[2]]$reviewed, 11L)
  expect_length(ev$flow[[2]]$already_out, 0L)
  expect_length(ev$flow[[2]]$not_reviewed, 0L)

  d <- as.data.frame(ev)
  expect_identical(nrow(d), 12L + 11L)
  expect_named(d, c("item", "scale", "stage", "statistic", "value", "lower",
                    "upper", "level", "criterion", "recommendation", "status",
                    "carried"))
  expect_setequal(unique(d$statistic), c("I-CVI", "Psa"))
  # The relevance panel maps no constructs; the sort's mapping fills them in,
  # except for EF5, which never reached the sort.
  expect_identical(d$scale[d$item == "EF1" & d$stage == "Relevance panel"], "EF")
  expect_true(is.na(d$scale[d$item == "EF5"][1]))
})

test_that("stages side by side count only what each stage held back itself", {
  panel <- content_handoff(wt_relevance_fit())
  sort <- content_handoff(sort_validity(wt_sorted()))
  ev <- content_evidence(panel, sort)

  expect_named(ev$stages, c("Relevance panel", "Item sort"))
  expect_setequal(ev$carried, setdiff(ev$items, c("EF5", "TF5")))
  # EF5 was already held back when the sort, which also holds it back, saw it.
  expect_identical(ev$flow[[2]]$already_out, "EF5")
  expect_identical(ev$flow[[2]]$held, "TF5")
  verdict <- contentvalidR:::.evidence_verdicts(ev)
  expect_identical(verdict[ev$items == "EF5"],
                   "held back: Relevance panel; Item sort")
  expect_identical(verdict[ev$items == "TF5"], "held back: Item sort")
})

test_that("fits and handoffs give the same evidence", {
  fit <- wt_relevance_fit()
  a <- content_evidence(Panel = fit)
  b <- content_evidence(Panel = content_handoff(fit))
  expect_identical(a$evidence, b$evidence)
  expect_identical(a$carried, b$carried)
  # `keep` applies to fits only.
  wide <- content_evidence(Panel = fit, keep = c("Supported", "Review"))
  expect_true("EF5" %in% wide$carried)
})

test_that("decisions are read from each handoff, never recomputed", {
  # A handoff that says an item was held back is believed, whatever its number
  # says, which is the reader contract in ?content_handoff.
  h <- content_handoff(wt_relevance_fit())
  h$item_evidence$carried[h$item_evidence$item == "TF1"] <- FALSE
  h$item_evidence$recommendation[h$item_evidence$item == "TF1"] <- "Review"
  h$item_evidence$status[h$item_evidence$item == "TF1"] <- "Review"
  ev <- content_evidence(Panel = h)
  expect_false("TF1" %in% ev$carried)
  expect_identical(ev$flow[[1]]$held, c("EF5", "TF1"))
})

test_that("unnamed and repeated stages are labeled so they can be told apart", {
  fit <- wt_relevance_fit()
  ev <- content_evidence(fit, fit)
  expect_named(ev$stages, c("Relevance panel (stage 1)",
                            "Relevance panel (stage 2)"))
  ev <- content_evidence(First = fit, fit)
  expect_named(ev$stages, c("First", "Relevance panel"))
})

test_that("each workflow shows the statistic its decision rule reads", {
  ess <- expert_validity(c(10, 8, 6), mode = "essentiality", N = 12)
  con_d <- expand.grid(item = c("I1", "I2"), judge = 1:4, objective = c("A", "B"),
                       KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  con_d$score <- ifelse(con_d$objective == ifelse(con_d$item == "I1", "A", "B"),
                        1, -1)
  con_t <- con_d
  con_t$target_objective <- ifelse(con_t$item == "I1", "A", "B")
  set.seed(12)
  rd <- expand.grid(item = c("A1", "A2", "B1"), rater = 1:20,
                    construct = c("A", "B", "C"), stringsAsFactors = FALSE)
  rd$target_construct <- ifelse(rd$item == "B1", "B", "A")
  rd$rating <- ifelse(rd$construct == rd$target_construct,
                      pmin(5, pmax(1, round(stats::rnorm(nrow(rd), 4.5, .6)))),
                      pmin(5, pmax(1, round(stats::rnorm(nrow(rd), 2.0, .7)))))
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4), S2 = c(2, 3, 2, 1, 3, 2))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2))
  long <- function(m, round) {
    data.frame(expert = paste0("E", seq_len(nrow(m))),
               item = rep(colnames(m), each = nrow(m)),
               round = round, rating = as.vector(m))
  }
  delphi <- delphi_validity(rbind(long(r1, 1), long(r2, 2)), lo = 1, hi = 4,
                            consensus_threshold = 0.75, B = 0)

  stat_of <- function(x, keep = "Supported") {
    unique(as.data.frame(content_evidence(x, keep = keep))$statistic)
  }
  expect_identical(stat_of(ess), "CVR")
  expect_identical(stat_of(expert_validity(con_t, mode = "congruence")),
                   "target IOC")
  expect_identical(stat_of(expert_validity(con_d, mode = "congruence"),
                           keep = "Descriptive only"), "highest IOC")
  expect_identical(stat_of(rating_validity(rd, scale_min = 1, scale_max = 5)),
                   "HTC")
  expect_identical(stat_of(delphi), "Share agreeing")
  expect_identical(names(content_evidence(delphi)$stages), "Delphi")
})

test_that("content_evidence() refuses what it cannot read", {
  expect_error(content_evidence(), "at least one handoff")
  expect_error(content_evidence(list(a = 1)), "not a handoff or a fitted workflow")
  h <- content_handoff(wt_relevance_fit())
  h$provenance$schema_version <- 2L
  expect_error(content_evidence(h), "schema version 2")
})

test_that("the print opens with the verdict and names who held what back", {
  out <- capture.output(print(wt_sequential()))
  expect_match(out[2], "10 of 12 items carried by every stage that reviewed")
  # Wrapped lines are joined, so a phrase split across two still matches.
  txt <- gsub("\\s+", " ", paste(out, collapse = " "))
  expect_match(txt, "Held back: EF5 \\(Relevance panel\\), TF5 \\(Item sort\\)")
  expect_match(txt, "1\\. Relevance panel: 12 items, 8 experts\\. Shows I-CVI\\.")
  expect_match(txt, "2\\. Item sort: 11 items, 20 judges\\. Shows Psa\\.")
  expect_match(txt, "Held back: Item sort")
  expect_match(txt, "Carried")
  expect_match(txt, "Result -- Carried when every stage")
  expect_match(txt, "What these columns mean")

  old <- options(contentvalidR.show_key = FALSE)
  on.exit(options(old))
  hidden <- gsub("\\s+", " ", paste(capture.output(print(wt_sequential())),
                                    collapse = " "))
  expect_no_match(hidden, "What these columns mean")
  # The result stays readable with the key hidden.
  expect_match(hidden, "Held back: Item sort")
})

test_that("the profile and the flow draw in gray and in color", {
  ev <- wt_sequential()
  for (apa in c(TRUE, FALSE)) {
    expect_identical(draws(plot(ev, apa = apa)), ev)
    expect_identical(draws(plot(ev, type = "flow", apa = apa)), ev)
    expect_identical(draws(plot(ev, show_legend = FALSE)), ev)
  }
  # Side by side, with an item a later stage has already lost.
  side <- content_evidence(content_handoff(wt_relevance_fit()),
                           content_handoff(sort_validity(wt_sorted())))
  expect_identical(draws(plot(side, type = "flow")), side)
  expect_error(plot(ev, apa = NA), "`apa` must be TRUE or FALSE")
  expect_error(plot(ev, type = "bars"))
})

test_that("an expert fit keeps its ratings and draws their distribution", {
  fit <- wt_relevance_fit()
  r <- read.csv(extdata("walkthrough_relevance.csv"), stringsAsFactors = FALSE)
  expect_equal(unname(fit$details$ratings),
               unname(as.matrix(r[setdiff(names(r), "expert")])))

  for (apa in c(TRUE, FALSE)) {
    expect_identical(draws(plot(fit, type = "distribution", apa = apa)), fit)
  }
  labs <- c("Not relevant", "Somewhat", "Quite", "Highly relevant")
  expect_identical(draws(plot(fit, type = "distribution", labels = labs)), fit)
  expect_error(draws(plot(fit, type = "distribution", labels = labs[1:3])),
               "4 labels")
  # The existing evidence plot is unchanged, and still the default.
  expect_identical(draws(plot(fit)), fit)

  ess <- expert_validity(c(10, 8, 6), mode = "essentiality", N = 12)
  expect_error(plot(ess, type = "distribution"), "relevance-mode fit")
  old_fit <- fit
  old_fit$details$ratings <- NULL
  expect_error(plot(old_fit, type = "distribution"), "earlier version")
})

test_that("a Delphi fit draws each round's distribution", {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4), S2 = c(2, 3, 2, 1, 3, 2),
              S3 = c(4, 4, 4, 4, 4, 3))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2))
  long <- function(m, round) {
    data.frame(expert = paste0("E", seq_len(nrow(m))),
               item = rep(colnames(m), each = nrow(m)),
               round = round, rating = as.vector(m))
  }
  # S3 reached consensus in round 1 and was not rated again.
  fit <- delphi_validity(rbind(long(r1, 1), long(r2, 2)), lo = 1, hi = 4,
                         consensus_threshold = 0.75, B = 0)
  for (apa in c(TRUE, FALSE)) {
    expect_identical(draws(plot(fit, which = "distribution", apa = apa)), fit)
  }
  # Without a threshold there is no criterion line and no decision.
  loose <- delphi_validity(rbind(long(r1, 1), long(r2, 2)), lo = 1, hi = 4,
                           B = 0)
  expect_identical(draws(plot(loose, which = "distribution")), loose)
  # The existing views still draw.
  expect_identical(draws(plot(fit)), fit)

  old_fit <- fit
  old_fit$details$round_fits[[1]]$details$ratings <- NULL
  expect_error(plot(old_fit, which = "distribution"), "earlier version")
})

test_that("the rating fills darken in gray and diverge in color", {
  grey <- contentvalidR:::.rating_fills(4, 2, apa = TRUE)
  lum <- colSums(grDevices::col2rgb(grey))
  expect_true(all(diff(lum) < 0))
  colour <- contentvalidR:::.rating_fills(4, 2, apa = FALSE)
  expect_length(colour, 4L)
  expect_length(unique(colour), 4L)
  # A five-point scale cut at 4: three below, two above.
  expect_length(contentvalidR:::.rating_fills(5, 3, apa = FALSE), 5L)
  # One category on a side takes the shade nearest the cut.
  expect_length(contentvalidR:::.rating_fills(4, 3, apa = FALSE), 4L)
})

# Tests for branches that covr 4.0.0 found no test running: the refusals of
# aikens_v() and signal_detection(), the shared plot helpers, the
# rating-distribution view, and content_evidence() with its printout, evidence
# profile, and flow diagram. They are grouped by the function they exercise.

extdata <- function(f) system.file("extdata", f, package = "contentvalidR")
joined <- function(x) {
  gsub("[[:space:]]+", " ", paste(utils::capture.output(print(x)),
                                  collapse = " "))
}

# Runs `expr` on a blank PDF device with the graphics function `fun` traced,
# and returns `what` for each call to `fun` in which `when` holds, as a list.
# The tracer runs in the traced function's frame, so `what` and `when` can
# name its arguments.
recorded <- function(fun, what, expr, when = TRUE, width = 7, height = 4) {
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
  grDevices::pdf(NULL, width = width, height = height)
  on.exit(grDevices::dev.off(), add = TRUE)
  force(expr)
  rec$values
}

# Every string text() and mtext() were asked to draw. text() dispatches
# through the S3 table, which keeps the untraced text.default, so the generic
# is traced, and only its unnamed character arguments (the labels) are kept.
drawn_text <- function(expr, width = 7, height = 4) {
  sink <- new.env()
  sink$text <- character(0)
  grab <- function(...) {
    a <- list(...)
    nm <- names(a)
    if (is.null(nm)) nm <- rep("", length(a))
    for (i in which(!nzchar(nm))) {
      if (is.character(a[[i]])) sink$text <- c(sink$text, a[[i]])
    }
  }
  suppressMessages({
    trace("mtext", bquote(.(grab)(text)), print = FALSE,
          where = asNamespace("graphics"))
    trace("text", bquote(.(grab)(...)), print = FALSE,
          where = asNamespace("graphics"))
  })
  on.exit(suppressMessages({
    untrace("mtext", where = asNamespace("graphics"))
    untrace("text", where = asNamespace("graphics"))
  }), add = TRUE)
  grDevices::pdf(NULL, width = width, height = height)
  on.exit(grDevices::dev.off(), add = TRUE)
  force(expr)
  sink$text
}

# The relevance panel and item sort of the content_evidence() examples.
relevance4 <- function() {
  matrix(c(4, 4, 4, 3, 4, 4, 3, 4, 3, 4, 4, 4, 2, 2, 1, 2), nrow = 4,
         dimnames = list(NULL, paste0("Item", 1:4)))
}
example_panel <- function(alpha = 0.05) {
  expert_validity(relevance4(), mode = "relevance", lo = 1, hi = 4,
                  agreement = "none", alpha = alpha)
}
example_evidence <- function() {
  sorts <- data.frame(
    item = rep(paste0("Item", 1:3), each = 12),
    rater = rep(1:12, 3),
    target_construct = rep(c("A", "A", "B"), each = 12),
    assigned_construct = c(rep("A", 11), "B", rep("A", 10), "B", "B",
                           rep("B", 5), rep("A", 7))
  )
  content_evidence(`Relevance panel` = example_panel(),
                   `Item sort` = sort_validity(sorts))
}

# Six experts rate four items. Item2 lost one rating, so its panel is five and
# Lynn's (1986) criterion for it is all five, against five of six for Item1
# and Item4. Nobody rated Item3, so it has no I-CVI; Item4 is rated low. An
# item sort then reviews Item1 and an item the panel never saw, Item5.
staged_evidence <- function() {
  ratings <- matrix(c(4, 4, 4, 3, 4, 4,
                      4, 3, 4, 4, 3, NA,
                      NA, NA, NA, NA, NA, NA,
                      2, 2, 1, 2, 3, 2), nrow = 6,
                    dimnames = list(NULL, paste0("Item", 1:4)))
  panel <- expert_validity(ratings, mode = "relevance", lo = 1, hi = 4,
                           na.rm = TRUE, agreement = "none")
  sorts <- data.frame(
    item = rep(c("Item1", "Item5"), each = 12),
    rater = rep(1:12, 2),
    target_construct = rep(c("A", "B"), each = 12),
    assigned_construct = c(rep("A", 11), "B", rep("B", 11), "A")
  )
  content_evidence(Panel = panel, Sort = sort_validity(sorts))
}

congruence_data <- function() {
  read.csv(extdata("expert_congruence_example.csv"), stringsAsFactors = FALSE)
}
# Congruence ratings without a target mapping: every item is described, none
# decided on.
untargeted <- function(items = c("I1", "I2", "I3")) {
  d <- congruence_data()
  d <- d[d$item %in% items, setdiff(names(d), "target_objective")]
  expert_validity(d, mode = "congruence")
}
# A relevance panel that decides on the congruence items it is given.
panel_on <- function(items) {
  m <- matrix(c(4, 4, 3, 4), nrow = 4, ncol = length(items),
              dimnames = list(NULL, items))
  expert_validity(m, mode = "relevance", lo = 1, hi = 4, agreement = "none")
}

# aikens_v() ----------------------------------------------------------------

test_that("aikens_v() refuses ratings with no judges or no items", {
  no_judges <- matrix(numeric(0), nrow = 0, ncol = 3,
                      dimnames = list(NULL, paste0("Item", 1:3)))
  expect_error(aikens_v(no_judges, lo = 1, hi = 4),
               "must contain at least one judge and one item")
  expect_error(aikens_v(matrix(numeric(0), nrow = 4, ncol = 0), lo = 1,
                        hi = 4),
               "must contain at least one judge and one item")
})

# signal_detection() --------------------------------------------------------

test_that("signal_detection() refuses vectors of different or zero length", {
  expect_error(signal_detection(c(TRUE, FALSE, TRUE), c(TRUE, FALSE)),
               "must have the same non-zero length")
  expect_error(signal_detection(logical(0), logical(0)),
               "must have the same non-zero length")
})

# Item labels (.item_labels(), through the figures) ------------------------

test_that("long item names that shorten alike are numbered to tell apart", {
  stem <- "My manager gives me clear and timely feedback (version %s) on the"
  items <- paste(sprintf(stem, c("A", "B")), "work I do every single day")
  ratings <- matrix(4, nrow = 5, ncol = 2, dimnames = list(NULL, items))
  fit <- expert_validity(ratings, mode = "relevance", lo = 1, hi = 4,
                         agreement = "none")
  labels <- recorded("axis", quote(labels), plot(fit),
                     when = quote(side == 2 && is.character(labels)))
  expect_length(labels, 1L)
  labels <- labels[[1]]
  # Shortened in the middle, the two names would read the same, so each is
  # numbered by its position.
  expect_length(labels, 2L)
  expect_true(all(grepl("...", labels, fixed = TRUE)))
  expect_true(all(startsWith(labels, "My manager")))
  expect_match(labels[1], " (1)", fixed = TRUE)
  expect_match(labels[2], " (2)", fixed = TRUE)
  expect_identical(sub(" \\([12]\\)$", "", labels[1]),
                   sub(" \\([12]\\)$", "", labels[2]))
})

# Legend layout (.legend_fit()) ---------------------------------------------

test_that("a key too wide for one column shrinks until its width fits", {
  # The figures of expert_validity(), rating_validity(), sort_power() and
  # expert_power() lay out their keys with .legend_fit(); the width here is
  # set to the edge where the PDF device's whole-point type matters.
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  labels <- c("A rather long first entry in the key",
              "Second entry, also long", "Third")
  # One column by legend()'s arithmetic: the widest label, then the symbol
  # and its gap (1.7 characters), then half a character.
  char_in <- function(cex) {
    cex * graphics::par("cex") * graphics::par("cin")[1]
  }
  one_column <- function(cex) {
    max(graphics::strwidth(labels, units = "inches", cex = cex)) +
      2.2 * char_in(cex)
  }
  usual <- one_column(0.72)
  width_in <- 0.992 * usual + 0.1
  room <- width_in - 0.1
  first_guess <- 0.72 * room / usual
  # PDF sets text in whole points, so type scaled in proportion still rounds
  # up to 9 points and is too wide.
  expect_gt(one_column(first_guess), room)
  fit <- contentvalidR:::.legend_fit(labels, pch = 1:3, width_in = width_in)
  expect_equal(fit$ncol, 1)
  expect_lte(fit$width, room)
  expect_lt(fit$cex, first_guess)
  expect_gte(fit$cex, 8 / graphics::par("ps"))
})

# Count axes (.axis_counts()) -----------------------------------------------

test_that("a panel-size axis zoomed between whole numbers ticks no fraction", {
  pw <- expert_power(n_experts = 3:12, prob = c(0.7, 0.85))
  ticks <- function(...) {
    at <- recorded("axis", quote(at), plot(pw, ...), when = quote(side == 1))
    Filter(Negate(is.null), at)
  }
  # Unzoomed, whole numbers of experts are ticked.
  expect_identical(ticks(), list(c(4, 6, 8, 10, 12)))
  # Between 6 and 7 experts there is no whole number to tick, and no
  # fraction such as 6.5 experts is ticked instead.
  expect_identical(ticks(xlim = c(6.2, 6.8)), list(integer(0)))
})

test_that("a vertical axis of counts ticks whole numbers only", {
  # No figure draws a vertical count axis yet; the helper is called directly.
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 1), ylim = c(2.2, 2.8))
  expect_invisible(at <- contentvalidR:::.axis_counts(2))
  expect_identical(at, integer(0))
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 1), ylim = c(0, 3))
  expect_identical(contentvalidR:::.axis_counts(2), c(0, 1, 2, 3))
})

# Rating distribution view (plot(<expert fit>, type = "distribution")) -----

test_that("one rating below the cut is drawn in the brown nearest the cut", {
  fit <- expert_validity(relevance4(), mode = "relevance", lo = 1, hi = 4,
                         relevance_cut = 2, agreement = "none")
  fills <- recorded("legend", quote(fill),
                    plot(fit, type = "distribution", apa = FALSE),
                    when = quote(!is.null(fill)))
  expect_length(fills, 1L)
  # Rated 1 is the only category below the cut of 2. The brown ramp runs
  # from #A6611A, far from the cut, to #DFC27D beside it; the three ratings
  # at or above the cut run from light to deep teal.
  expect_identical(fills[[1]],
                   c("#DFC27D", grDevices::colorRampPalette(
                     c("#80CDC1", "#018571"))(3)))
})

test_that("a title on the distribution view sits above the key, or lower", {
  fit <- example_panel()
  title_line <- function(...) {
    recorded("title", quote(line),
             plot(fit, type = "distribution", main = "Relevance", ...),
             when = quote(identical(main, "Relevance")))
  }
  # The top margin holds the key's two rows (3.4 lines), or 1.1 lines
  # without it, and 1.6 more for the title, which sits 1.2 lines below the
  # margin's top.
  expect_equal(title_line(), list(3.4 + 1.6 - 1.2))
  expect_equal(title_line(show_legend = FALSE), list(1.1 + 1.6 - 1.2))
})

# content_evidence(): the stages it accepts --------------------------------

test_that("a handoff from an unknown workflow or expert mode is refused", {
  # The handoff's schema is a published contract, so a "cv_handoff" can come
  # from another producer, or a later release, with a workflow or an expert
  # mode this release does not know.
  h <- content_handoff(example_panel())
  other <- h
  other$provenance$workflow <- "domain-blueprint"
  expect_error(content_evidence(other),
               paste("domain-blueprint handoff carries no statistic",
                     "content_evidence\\(\\) can show"))
  # Unnamed, so the stage is labeled by its workflow before it is refused.
  new_mode <- h
  new_mode$provenance$mode <- "coverage"
  expect_error(content_evidence(new_mode),
               paste("expert-panel handoff carries no statistic",
                     "content_evidence\\(\\) can show"))
})

test_that("a handoff from before the interval columns shows no intervals", {
  # contentvalidR 0.4.0 wrote schema version 1 handoffs whose statistics had
  # no interval columns; 0.5.0 added them within the same version.
  fit <- example_panel()
  h <- content_handoff(fit)
  h$item_statistics <- h$item_statistics[c("item", "statistic", "value",
                                           "criterion", "round")]
  h$panel_statistics <- NULL
  ev <- content_evidence(Panel = h)
  expect_identical(ev$evidence$value, as.numeric(fit$results$I_CVI))
  expect_true(all(is.na(ev$evidence$lower)))
  expect_true(all(is.na(ev$evidence$upper)))
  expect_true(all(is.na(ev$evidence$level)))
  # With no interval drawn, the key does not explain one.
  key <- drawn_text(plot(ev))
  expect_true(any(grepl("Dashed line: criterion.", key, fixed = TRUE)))
  expect_false(any(grepl("Bar:", key, fixed = TRUE)))
})

test_that("a stage whose handoff records no judge counts says so", {
  h <- content_handoff(example_panel())
  h$item_evidence$n_judges <- NA_integer_
  out <- joined(content_evidence(Panel = h))
  expect_match(out, "1. Panel: 4 items, experts not recorded. Shows I-CVI.",
               fixed = TRUE)
  expect_false(grepl("NA expert", out, fixed = TRUE))
})

# content_evidence(): the printout ------------------------------------------

test_that("the summary sentence agrees in number with the items", {
  one <- joined(content_evidence(Panel = panel_on("I1")))
  expect_match(one, "1 of 1 item carried by every stage that reviewed it.",
               fixed = TRUE)
  several <- joined(staged_evidence())
  expect_match(several,
               "3 of 5 items carried by every stage that reviewed them.",
               fixed = TRUE)
  # A single item that no stage decided on.
  alone <- joined(content_evidence(Ratings = untargeted("I1")))
  expect_match(alone, paste("No stage applied a decision rule (every item is",
                            "Descriptive only), so the item is marked No",
                            "decision."), fixed = TRUE)
})

test_that("items no stage decided on are named, as it or them", {
  one <- joined(content_evidence(Ratings = untargeted(),
                                 Panel = panel_on(c("I1", "I2"))))
  expect_match(one, paste("No decision: I3 (no stage applied a decision rule",
                          "to it)."), fixed = TRUE)
  two <- joined(content_evidence(Ratings = untargeted(),
                                 Panel = panel_on("I1")))
  expect_match(two, paste("No decision: I2, I3 (no stage applied a decision",
                          "rule to them)."), fixed = TRUE)
})

test_that("stages that applied no decision rule are named, as it or they", {
  one <- joined(content_evidence(Ratings = untargeted(),
                                 Panel = panel_on(c("I1", "I2"))))
  expect_match(one, paste("Ratings applied no decision rule (every item is",
                          "Descriptive only), so it holds no item back."),
               fixed = TRUE)
  two <- joined(content_evidence(First = untargeted(), Second = untargeted(),
                                 Panel = panel_on("I1")))
  expect_match(two, paste("First and Second applied no decision rule (every",
                          "item is Descriptive only), so they hold no item",
                          "back."), fixed = TRUE)
})

test_that("handoffs that differ on carrying described items are explained", {
  fit <- untargeted()
  ev <- content_evidence(
    Kept = content_handoff(fit, keep = c("Supported", "Descriptive only")),
    Dropped = content_handoff(fit),
    Panel = panel_on("I1")
  )
  # I2 and I3: carried by the first handoff, not by the second.
  expect_identical(ev$evidence$carried[ev$evidence$item == "I2"],
                   c(TRUE, FALSE))
  expect_match(joined(ev),
               paste("A stage's own handoff carries the items it only",
                     "described only when keep includes \"Descriptive only\",",
                     "as it did for some here."), fixed = TRUE)
})

test_that("the key tells a stage that did not review an item from a gap", {
  out <- joined(staged_evidence())
  # Item3 has no I-CVI, and the sort did not review Item2 to Item4.
  expect_match(out, "Item3 -- Insufficient panel --", fixed = TRUE)
  expect_match(out, paste("A \"--\" alone marks a stage that did not review",
                          "the item. A \"--\" before a decision marks a",
                          "statistic that could not be computed."),
               fixed = TRUE)
  # Without a missing statistic, the mark needs no "alone".
  plain <- joined(example_evidence())
  expect_match(plain, "A \"--\" marks a stage that did not review the item.",
               fixed = TRUE)
  expect_false(grepl("before a decision", plain, fixed = TRUE))
})

test_that("as.data.frame() on the evidence takes the row names it is given", {
  ev <- example_evidence()
  names_given <- paste0("row", seq_len(nrow(ev$evidence)))
  out <- as.data.frame(ev, row.names = names_given)
  expect_identical(rownames(out), names_given)
  rownames(out) <- NULL
  expect_identical(out, ev$evidence)
})

# content_evidence(): the evidence profile ----------------------------------

test_that("the profile's panels run -1 to 1 for the CVR and the IOC", {
  essential <- read.csv(extdata("expert_essentiality_example.csv"))
  first <- content_evidence(
    Essentiality = expert_validity(essential[-1], mode = "essentiality"),
    Relevance = example_panel()
  )
  xlim <- recorded("plot.window", quote(xlim), plot(first))
  # One frame per stage, then the column of results across stages.
  expect_identical(xlim, list(c(-1, 1), c(0, 1), c(0, 1)))
  d <- congruence_data()
  second <- content_evidence(
    Targeted = expert_validity(d, mode = "congruence"),
    Untargeted = untargeted()
  )
  expect_identical(unique(second$evidence$statistic),
                   c("target IOC", "highest IOC"))
  xlim <- recorded("plot.window", quote(xlim), plot(second))
  expect_identical(xlim, list(c(-1, 1), c(-1, 1), c(0, 1)))
})

test_that("a criterion that differs by item is marked on each item's row", {
  ev <- staged_evidence()
  # Lynn (1986): five of six experts for Item1 and Item4, all five for
  # Item2; Item3 has no criterion.
  panel <- ev$evidence[ev$evidence$stage == "Panel", ]
  expect_equal(panel$criterion, c(5 / 6, 1, NA, 5 / 6))
  marks <- recorded("segments", quote(x0), plot(ev),
                    when = quote(identical(lty, 2)))
  expect_equal(marks, list(c(5 / 6, 1, 5 / 6)))
})

test_that("intervals at different levels are keyed without a level", {
  ev <- content_evidence(`95% panel` = example_panel(),
                         `90% panel` = example_panel(alpha = 0.10))
  expect_equal(unique(ev$evidence$level), c(0.95, 0.90))
  key <- drawn_text(plot(ev))
  expect_true(any(grepl("Bar: interval.", key, fixed = TRUE)))
  expect_false(any(grepl("% interval", key, fixed = TRUE)))
})

test_that("a profile with nothing to explain draws no key", {
  unrated <- matrix(NA_real_, nrow = 4, ncol = 2,
                    dimnames = list(NULL, c("I1", "I2")))
  fit <- expert_validity(unrated, mode = "relevance", lo = 1, hi = 4,
                         na.rm = TRUE, agreement = "none")
  ev <- content_evidence(Panel = fit)
  expect_true(all(is.na(ev$evidence$value)))
  outer <- recorded("mtext", quote(text), plot(ev),
                    when = quote(isTRUE(outer)))
  expect_length(outer, 0L)
  # Each row says it has no value instead.
  rows <- recorded("text", quote(list(...)[[1]]), plot(ev),
                   when = quote(any(vapply(list(...), identical, logical(1),
                                           "no value"))))
  expect_identical(rows, list(2:1))
})

test_that("the profile's key shrinks a line a little too wide", {
  # plot(<evidence>) fits its key to the panels' width through this helper;
  # the width is given here so the edge case is exact.
  ev <- example_evidence()$evidence
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  smallest <- 8 / graphics::par("ps")
  roomy <- contentvalidR:::.evidence_profile_key(ev, 0.72, smallest,
                                                 room = 100)
  expect_length(roomy$lines, 1L)
  need <- graphics::strwidth(roomy$lines, units = "inches", cex = 0.72)
  key <- contentvalidR:::.evidence_profile_key(ev, 0.72, smallest,
                                               room = need / 1.04)
  expect_identical(key$lines, roomy$lines)
  expect_equal(key$cex, 0.72 / 1.04)
  expect_gte(key$cex, smallest)
})

test_that("a key too wide even one part to a line is set at 8 points", {
  ev <- example_evidence()$evidence
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  smallest <- 8 / graphics::par("ps")
  key <- contentvalidR:::.evidence_profile_key(ev, 0.72, smallest,
                                               room = 0.5)
  expect_identical(key$lines, c("Filled: met the criterion.", "Open: review.",
                                "Dashed line: criterion.",
                                "Bar: 95% interval."))
  expect_equal(key$cex, smallest)
})

# content_evidence(): the flow diagram --------------------------------------

test_that("the flow diagram follows items added, carried, and held back", {
  text <- drawn_text(plot(staged_evidence(), type = "flow"))
  # The sort saw Item5 for the first time, and not Item2, which the panel
  # carried.
  expect_true("including 1 item not reviewed before" %in% text)
  expect_true("1 item carried so far, not reviewed here" %in% text)
  # A held-back item with a statistic gives it; one without gives none.
  expect_true("Item4 (Review): I-CVI .17, criterion .83" %in% text)
  expect_true("Item3 (Insufficient panel)" %in% text)
  # The sort mapped Item1 and Item5 to constructs; nothing mapped Item2.
  expect_true(all(c("Carried forward: 3 items", "A (1): Item1",
                    "Unmapped (1): Item2", "B (1): Item5") %in% text))
})

test_that("the flow diagram shrinks to a shorter device, to 8 points", {
  ev <- staged_evidence()
  size <- function(height) {
    cex <- recorded("text", quote(list(...)[["cex"]]),
                    plot(ev, type = "flow"), height = height)
    unique(unlist(cex))
  }
  # On a tall device only the boxes' width sets the size.
  tall <- size(8)
  expect_length(tall, 1L)
  shorter <- size(3.5)
  expect_length(shorter, 1L)
  expect_lt(shorter, tall)
  expect_gte(shorter, 8 / 12)
})

test_that("a device too short at 8 points sets the flow diagram smaller", {
  ev <- staged_evidence()
  cex <- recorded("text", quote(list(...)[["cex"]]),
                  plot(ev, type = "flow"), height = 2)
  cex <- unique(unlist(cex))
  expect_length(cex, 1L)
  expect_lt(cex, 8 / 12)
  expect_gt(cex, 0.2)
})

# The evidence across stages before 1.0, second close-out: a stage holds back
# only the items it decided on, an item no stage decided on is "No decision",
# long stage names head their columns by number, and the figures keep every
# label at a readable size on the device.

extdata <- function(f) system.file("extdata", f, package = "contentvalidR")
printed <- function(x) capture.output(print(x))
joined <- function(x) gsub("[[:space:]]+", " ", paste(printed(x), collapse = " "))

# Records one argument of a graphics function each time it is called, until
# stop_recording(). The tracer runs in the traced function's frame, so it
# writes to an environment written into the call.
record_arg <- function(fun, arg, when = TRUE) {
  rec <- new.env()
  rec$values <- NULL
  tracer <- bquote(if (.(when)) {
    assign("values", c(get("values", envir = .(rec)), .(as.name(arg))),
           envir = .(rec))
  })
  suppressMessages(trace(fun, tracer = tracer, print = FALSE,
                         where = asNamespace("graphics")))
  rec
}
stop_recording <- function(fun) {
  suppressMessages(untrace(fun, where = asNamespace("graphics")))
}
long_rounds <- function(m, round) {
  data.frame(expert = paste0("E", seq_len(nrow(m))),
             item = rep(colnames(m), each = nrow(m)), round = round,
             rating = as.vector(m))
}

# A Delphi study without a threshold in which S3 had two experts, and a
# panel that supports all three statements.
delphi_thin <- function() {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4, 3, 4), S2 = c(2, 3, 2, 1, 3, 2, 2, 3))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2, 2, 2))
  d <- rbind(long_rounds(r1, 1), long_rounds(r2, 2),
             data.frame(expert = c("E1", "E2", "E1", "E2"), item = "S3",
                        round = c(1, 1, 2, 2), rating = 4))
  delphi_validity(d, lo = 1, hi = 4, B = 0)
}
panel_s <- function(items = c("S1", "S2", "S3")) {
  ratings <- matrix(c(4, 4, 4, 3, 4, 4, 3, 4, 3, 4, 4, 4), 4,
                    dimnames = list(NULL, c("S1", "S2", "S3")))
  expert_validity(ratings[, items, drop = FALSE], mode = "relevance", lo = 1,
                  hi = 4, agreement = "none")
}
untargeted_fit <- function() {
  d <- read.csv(extdata("expert_congruence_example.csv"),
                stringsAsFactors = FALSE)
  expert_validity(d[setdiff(names(d), "target_objective")],
                  mode = "congruence")
}
walkthrough_panel <- function() {
  wt <- read.csv(extdata("walkthrough_relevance.csv"), stringsAsFactors = FALSE)
  expert_validity(as.matrix(wt[setdiff(names(wt), "expert")]),
                  mode = "relevance", lo = 1, hi = 4, agreement = "none")
}
walkthrough_sort <- function() {
  sort_validity(read.csv(extdata("walkthrough_sort.csv"),
                         stringsAsFactors = FALSE))
}

# 1. The rule applies item by item.

test_that("a stage never holds back an item it only described", {
  fit <- delphi_thin()
  expect_identical(fit$results$status,
                   c("Descriptive only", "Descriptive only",
                     "Insufficient data"))
  ev <- content_evidence(Delphi = fit, Panel = panel_s())
  # S3 had too few experts, a decision the Delphi stage did make; S1 and S2
  # were only described there, and the panel supported them.
  expect_identical(ev$carried, c("S1", "S2"))
  expect_true(ev$flow$Delphi$decided)
  expect_identical(ev$flow$Delphi$held, "S3")
  expect_identical(contentvalidR:::.evidence_verdicts(ev),
                   c("carried", "carried", "held back: Delphi"))
  # The handoff is unchanged: the Delphi stage carries none of them.
  expect_false(any(ev$stages$Delphi$item_evidence$carried))

  old <- options(width = 80)
  on.exit(options(old))
  out <- printed(ev)
  txt <- joined(ev)
  expect_match(txt, paste("2 of 3 items carried by every stage that applied",
                          "a decision rule to them. Held back: S3 (Delphi)."),
               fixed = TRUE)
  expect_match(txt, "Shows Share agreeing; no decision rule for 2 items.",
               fixed = TRUE)
  expect_true(any(grepl("^  S1 .* Carried$", out)))
  expect_true(any(grepl("^  S3 .* Held back: 1$", out)))
  expect_false(grepl("Held back: S1", txt, fixed = TRUE))
  expect_match(txt, paste("A stage that applied no decision rule to an item",
                          "does not hold it back."), fixed = TRUE)
  # One space between sentences, never two.
  expect_false(any(grepl("[.]  [A-Z]", out)))
})

# 2. An item no stage decided on is "No decision", never "Carried".

test_that("an item no stage decided on reads No decision", {
  cu <- untargeted_fit()
  ev <- content_evidence(Only = cu)
  # The handoff carries none of them, and the evidence calls none carried.
  expect_length(content_handoff(cu)$items, 0L)
  expect_length(ev$carried, 0L)
  expect_identical(contentvalidR:::.evidence_verdicts(ev),
                   rep("no decision", 3))
  old <- options(width = 80)
  on.exit(options(old))
  out <- printed(ev)
  txt <- joined(ev)
  expect_match(txt, paste("No stage applied a decision rule (every item is",
                          "Descriptive only), so all 3 items are marked No",
                          "decision."), fixed = TRUE)
  expect_match(txt, paste("A stage's own handoff carries none of the items it",
                          "only described; keep = \"Descriptive only\" in",
                          "content_handoff() carries them."), fixed = TRUE)
  expect_identical(sum(grepl("keep = \"Descriptive only\"", txt,
                             fixed = TRUE)), 1L)
  expect_true(all(grepl("No decision$", out[grepl("^  I[1-3] ", out)])))
  expect_false(any(grepl("Carried$", out)))
  expect_match(txt, paste("Result -- Carried when every stage that applied a",
                          "decision rule to the item carried it, and No",
                          "decision when no stage applied one; otherwise the",
                          "numbers of the stages that held it back"),
               fixed = TRUE)

  # Beside a stage that decided on some items, the rest are named.
  ratings <- do.call(rbind, lapply(1:2, function(k) {
    m <- cbind(S1 = c(4, 4, 3, 4, 2, 4), S2 = c(2, 3, 2, 1, 3, 2),
               S3 = c(4, 4, 4, 3, 4, 4))
    long_rounds(m, k)
  }))
  delphi <- delphi_validity(ratings, lo = 1, hi = 4, B = 0)
  mixed <- content_evidence(Delphi = delphi, Panel = panel_s(c("S1", "S2")))
  expect_identical(mixed$carried, c("S1", "S2"))
  expect_identical(contentvalidR:::.evidence_undecided(mixed), "S3")
  mtxt <- joined(mixed)
  expect_match(mtxt, paste("No decision: S3 (no stage applied a decision rule",
                           "to it)."), fixed = TRUE)
  expect_true(any(grepl("^  S3 .* No decision$", printed(mixed))))

  # Handoffs that carried such items because `keep` asked for them.
  kept <- content_evidence(Only = cu, keep = "Descriptive only")
  expect_true(all(kept$stages$Only$item_evidence$carried))
  expect_length(kept$carried, 0L)
  expect_match(joined(kept), paste("Their stages' handoffs carry them, because",
                                   "keep included \"Descriptive only\"."),
               fixed = TRUE)
})

test_that("the flow diagram lists the items no stage decided on apart", {
  ratings <- do.call(rbind, lapply(1:2, function(k) {
    long_rounds(cbind(S1 = c(4, 4, 3, 4, 2, 4), S2 = c(2, 3, 2, 1, 3, 2),
                      S3 = c(4, 4, 4, 3, 4, 4)), k)
  }))
  mixed <- content_evidence(Delphi = delphi_validity(ratings, lo = 1, hi = 4,
                                                     B = 0),
                            Panel = panel_s(c("S1", "S2")))
  rec <- record_arg("text.default", "labels")
  on.exit(stop_recording("text.default"), add = TRUE)
  grDevices::pdf(NULL, width = 7, height = 4)
  plot(mixed, type = "flow")
  plot(content_evidence(Delphi = delphi_thin(), Panel = panel_s()),
       type = "flow")
  grDevices::dev.off()
  drawn <- as.character(rec$values)
  expect_true("Carried forward: 2 items" %in% drawn)
  expect_true("No decision: 1" %in% drawn)
  expect_true("no stage applied a decision rule" %in% drawn)
  expect_true("1 item still in play, not reviewed here" %in% drawn)
  expect_true("2 items with no decision rule, not held back" %in% drawn)
  expect_true("S3 (Insufficient panel): Share agreeing 1.00" %in% drawn)
})

test_that("?content_evidence states the rule item by item", {
  rd <- gsub("[[:space:]]+", " ",
             paste(rd_lines("content_evidence"), collapse = " "))
  expect_match(rd, "A stage holds back only the items it decided on",
               fixed = TRUE)
  expect_match(rd, "its result is \"No decision\"", fixed = TRUE)
  expect_match(rd, "still holds back an item it found to have too few experts",
               fixed = TRUE)
})

# 3. Long stage names head their columns by number.

test_that("stage columns are numbered when their names would not fit", {
  panel <- walkthrough_panel()
  sorts <- walkthrough_sort()
  ess <- expert_validity(c(EF1 = 10, EF2 = 9, EF3 = 8, EF4 = 3, EF5 = 12,
                           EF6 = 11), mode = "essentiality", N = 12)
  two <- content_evidence(`Expert relevance panel (round 1)` = panel,
                          `Expert essentiality panel (round 2)` = ess)
  three <- content_evidence(`Expert relevance panel (round 1)` = panel,
                            `Item sort with naive judges (study 2)` = sorts,
                            `Second relevance panel of four experts` = panel)
  short <- content_evidence(`Relevance panel` = panel, `Item sort` = sorts)
  for (w in c(80L, 60L)) {
    old <- options(width = w)
    out2 <- printed(two)
    out3 <- printed(three)
    outs <- printed(short)
    options(old)
    # A table never runs past the console.
    expect_lte(max(nchar(c(out2, out3, outs))), w)
    expect_true(any(grepl("^  Item +1 +2 +Result$", out2)))
    expect_false(any(grepl("Not shown for width", out2, fixed = TRUE)))
    expect_true(any(grepl("^  1, 2 -- The stages, numbered as listed above",
                          out2)))
    # The names are still listed above the table.
    expect_true(any(grepl("^  2\\. Expert essentiality panel", out2)))
  }
  old <- options(width = 80)
  out3 <- printed(three)
  outs <- printed(short)
  options(old)
  # Three long names: every stage column at 80 columns, numbered.
  expect_true(any(grepl("^  Item +1 +2 +3 +Result$", out3)))
  expect_false(any(grepl("Not shown for width", out3, fixed = TRUE)))
  expect_true(any(grepl("^  1 to 3 -- The stages", out3)))
  # Names that fit stay as the headings.
  expect_true(any(grepl("^  Item +Relevance panel +Item sort +Result$", outs)))
  expect_false(any(grepl("The stages, numbered", outs, fixed = TRUE)))
})

# 4. The highest index has its own definition.

test_that("Highest IOC is defined apart from the target index", {
  d <- read.csv(extdata("expert_congruence_example.csv"),
                stringsAsFactors = FALSE)
  out <- printed(content_evidence(First = expert_validity(d, mode = "congruence"),
                                  Second = untargeted_fit()))
  key <- gsub("[[:space:]]+", " ", paste(out, collapse = " "))
  highest <- regmatches(key, regexpr("Highest IOC -- [^)]*\\)\\.", key))
  target <- regmatches(key, regexpr("Target IOC -- [^)]*\\)\\.", key))
  expect_identical(highest, paste("Highest IOC -- Index of item-objective",
                                  "congruence. The item's index on its best",
                                  "objective, the one with the highest index",
                                  "(-1 to 1)."))
  expect_false(grepl("Rovinelli", highest, fixed = TRUE))
  expect_match(target, "Rovinelli and Hambleton used .70", fixed = TRUE)
})

# 5. The profile's key is fitted to the width it is centered on.

long_item_evidence <- function() {
  stems <- c(EF1 = "When my coursework gets boring I keep at it",
             EF2 = "I stop studying once it stops being interesting",
             EF3 = "I finish the assignments that count toward my grade",
             EF4 = "I make myself study even when I would rather not",
             EF5 = "I like school",
             EF6 = "Even dull readings get my full attention to the end")
  wt <- read.csv(extdata("walkthrough_relevance.csv"), stringsAsFactors = FALSE,
                 check.names = FALSE)
  hit <- names(wt) %in% names(stems)
  names(wt)[hit] <- stems[names(wt)[hit]]
  panel <- expert_validity(as.matrix(wt[setdiff(names(wt), "expert")]),
                           mode = "relevance", lo = 1, hi = 4,
                           agreement = "none")
  sorts <- read.csv(extdata("walkthrough_sort.csv"), stringsAsFactors = FALSE)
  hit <- sorts$item %in% names(stems)
  sorts$item[hit] <- stems[sorts$item[hit]]
  content_evidence(`Expert relevance panel (round 1)` = panel,
                   `Item sort with naive judges (study 2)` =
                     sort_validity(sorts))
}

test_that("the profile key stays on the device with long item names", {
  ev <- long_item_evidence()
  real <- contentvalidR:::.evidence_profile_key
  seen <- new.env()
  local_mocked_bindings(.evidence_profile_key = function(...) {
    key <- real(...)
    din <- graphics::par("din")
    omi <- graphics::par("omi")
    # mtext(outer = TRUE) centers each line on the region inside the outer
    # margins, the left one holding the item names.
    centre <- omi[2] + (din[1] - omi[2] - omi[4]) / 2
    half <- graphics::strwidth(key$lines, units = "inches", cex = key$cex) / 2
    seen$left <- c(seen$left, centre - half)
    seen$right <- c(seen$right, centre + half - din[1])
    seen$cex <- c(seen$cex, key$cex)
    key
  })
  for (size in list(c(7, 4), c(7.5, 5.5), c(5, 3.5))) {
    grDevices::pdf(NULL, width = size[1], height = size[2])
    plot(ev)
    grDevices::dev.off()
  }
  expect_length(seen$cex, 3L)
  expect_true(all(seen$left > 0))
  expect_true(all(seen$right < 0))
  expect_true(all(seen$cex >= 8 / 12 - 1e-12))
})

# 6. Every item is named, and verdicts never run into the next row.

test_that("a three-stage profile at 5 by 3.5 names every item", {
  panel <- walkthrough_panel()
  four <- read.csv(extdata("walkthrough_relevance.csv"),
                   stringsAsFactors = FALSE)[1:4, ]
  panel4 <- expert_validity(as.matrix(four[setdiff(names(four), "expert")]),
                            mode = "relevance", lo = 1, hi = 4,
                            agreement = "none")
  ev <- content_evidence(`Expert relevance panel (round 1)` = panel,
                         `Item sort with naive judges (study 2)` =
                           walkthrough_sort(),
                         `Second relevance panel of four experts` = panel4)
  sizes <- numeric(0)
  rec <- record_arg("axis", "labels",
                    when = quote(side == 2 && is.character(labels)))
  on.exit(stop_recording("axis"), add = TRUE)
  real_axis <- contentvalidR:::.evidence_item_axis
  local_mocked_bindings(.evidence_item_axis = function(y, labels, smallest) {
    cex <- real_axis(y, labels, smallest)
    per_row <- graphics::par("pin")[2] / diff(graphics::par("usr")[3:4])
    sizes <<- c(sizes, cex, per_row,
                graphics::strheight("M", units = "inches", cex = cex))
    invisible(cex)
  })
  grDevices::pdf(NULL, width = 5, height = 3.5)
  plot(ev)
  grDevices::dev.off()
  # One label per call, so axis() can skip none of them.
  expect_identical(sort(rec$values), sort(ev$items))
  expect_gte(sizes[1], 8 / 12 - 1e-12)
  # The names fit their rows: capitals to descenders within the row.
  expect_lte(1.3 * sizes[3], sizes[2])
})

test_that("numbered verdicts that would still wrap are set on one line", {
  ev <- long_item_evidence()
  ev3 <- content_evidence(
    `Expert relevance panel (round 1)` = ev$stages[[1]],
    `Item sort with naive judges (study 2)` = ev$stages[[2]],
    `A third stage with a very long name indeed` = ev$stages[[1]]
  )
  real_draw <- contentvalidR:::.evidence_draw_verdicts
  seen <- new.env()
  local_mocked_bindings(.evidence_draw_verdicts = function(verdict, y, font,
                                                           col, smallest,
                                                           one_line = FALSE) {
    seen$one_line <- one_line
    seen$verdict <- verdict
    seen$row <- graphics::par("pin")[2] / diff(graphics::par("usr")[3:4])
    seen$tall <- graphics::strheight("Mg", units = "inches", cex = smallest)
    real_draw(verdict, y, font, col, smallest, one_line)
  })
  grDevices::pdf(NULL, width = 5, height = 3.5)
  plot(ev3)
  grDevices::dev.off()
  expect_true(seen$one_line)
  expect_true("held back: 1, 2, 3" %in% seen$verdict)
  # Titles were cut short rather than squeeze the rows below one line of
  # 8-point text.
  expect_gt(seen$row, 1.2 * seen$tall)
})

# 7. Keys and labels in the workflows' figures.

capture_fit <- function(env = parent.frame()) {
  real <- contentvalidR:::.legend_draw
  seen <- new.env()
  local_mocked_bindings(.legend_draw = function(fit) {
    seen$fit <- fit
    if (!is.null(fit)) {
      args <- list("top", legend = fit$legend, pch = fit$pch, col = fit$col,
                   bty = "n", ncol = fit$ncol, cex = fit$cex, x.intersp = 0.7,
                   seg.len = 1.6, title = fit$title, plot = FALSE)
      if (any(!is.na(fit$lty))) args$lty <- fit$lty
      seen$rect <- do.call(graphics::legend, args)$rect
    }
    seen$usr <- graphics::par("usr")
    real(fit)
  }, .env = env)
  seen
}

test_that("the rating profile lays out its key like the other views", {
  r <- read.csv(extdata("rating_example.csv"), stringsAsFactors = FALSE)
  a1 <- r$item == "A1" & r$construct != r$target_construct & r$rater > 1
  r$rating[a1] <- NA
  fit <- suppressWarnings(rating_validity(r))
  seen <- capture_fit()
  for (size in list(c(7, 4), c(7, 5), c(5, 3.5))) {
    grDevices::pdf(NULL, width = size[1], height = size[2])
    plot(fit, type = "profile")
    grDevices::dev.off()
    key <- seen$fit
    entries <- trimws(key$legend[nzchar(key$legend)])
    expect_setequal(entries, c("Target", "Top competitor", "Gap (retain)",
                               "Gap (review)", "No decision"))
    # A label left of another column is padded clear of that column's line.
    inner <- ceiling(seq_along(key$legend) / key$rows) < key$ncol &
      nzchar(key$legend)
    expect_true(all(grepl(" {5}$", key$legend[inner])))
    # The key sits above the first item's row and inside the plot.
    expect_gt(seen$rect$top - seen$rect$h, nrow(fit$results) + 0.25)
    expect_gte(seen$rect$left, seen$usr[1])
    expect_lte(seen$rect$left + seen$rect$w, seen$usr[2])
  }
})

test_that("item plots set their vertical tick labels horizontally", {
  s <- read.csv(extdata("sort_example.csv"), stringsAsFactors = FALSE)
  s$assigned_construct[s$item == "A1"] <- NA
  fit <- suppressWarnings(sort_validity(s))
  real <- contentvalidR:::.axis_bounded
  calls <- list()
  local_mocked_bindings(.axis_bounded = function(side, at, digits = 2, ...) {
    if (side == 2) {
      calls[[length(calls) + 1L]] <<- list(
        las = list(...)$las,
        gap = min(diff(at)) * graphics::par("pin")[2] /
          diff(graphics::par("usr")[3:4]),
        tall = graphics::strheight("1", units = "inches",
                                   cex = graphics::par("cex.axis"))
      )
    }
    real(side, at, digits, ...)
  })
  rating <- rating_validity(read.csv(extdata("rating_example.csv")))
  grDevices::pdf(NULL, width = 5, height = 3.5)
  plot(fit)
  plot(fit, metric = "csv")
  plot(fit, type = "map")
  plot(rating, metric = "htd")
  plot(rating, type = "map")
  grDevices::dev.off()
  expect_length(calls, 5L)
  for (cl in calls) {
    expect_identical(cl$las, 1)
    # Upright labels are only a line apart, so none is dropped.
    expect_gt(cl$gap, cl$tall)
  }
})

test_that("the relevance key clears the criterion line", {
  rel <- read.csv(extdata("expert_relevance_example.csv"))
  fit <- expert_validity(as.matrix(rel[, -1]), mode = "relevance", lo = 1,
                         hi = 4, seed = 1)
  set.seed(3)
  R12 <- matrix(sample(2:4, 72, TRUE, prob = c(.1, .3, .6)), 12, 6,
                dimnames = list(NULL, paste0("Item", 1:6)))
  fit12 <- expert_validity(R12, mode = "relevance", lo = 1, hi = 4,
                           agreement = "none")
  cong <- expert_validity(read.csv(extdata("expert_congruence_example.csv")),
                          mode = "congruence")
  seen <- capture_fit()
  for (f in list(fit, fit12, cong)) {
    for (size in list(c(7, 4), c(5, 3.5))) {
      grDevices::pdf(NULL, width = size[1], height = size[2])
      plot(f)
      grDevices::dev.off()
      # The reference lines reach half a row above the first item.
      expect_gt(seen$rect$top - seen$rect$h, nrow(f$results) + 0.5)
    }
  }
  # More than ten experts: one column at full size, at 5 by 3.5 inches.
  grDevices::pdf(NULL, width = 5, height = 3.5)
  plot(fit12)
  grDevices::dev.off()
  expect_identical(seen$fit$ncol, 1)
  expect_identical(seen$fit$cex, 0.72)
})

test_that("long item names get the margin they need", {
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::plot.new()
  op <- graphics::par(no.readonly = TRUE)
  items <- c("My supervisor trusts my judgment", "Item 2")
  labels <- contentvalidR:::.item_axis_left(items)
  need <- max(graphics::strwidth(labels, units = "inches")) +
    graphics::par("mgp")[2] * graphics::par("csi")
  expect_identical(labels, items)
  expect_gte(graphics::par("mai")[2], need)
  graphics::par(op)
  below <- contentvalidR:::.item_axis_below(paste("A long item stem", 1:3))
  # The axis title sits below the names, inside the margin.
  need <- max(graphics::strwidth(below$labels, units = "inches")) /
    graphics::par("csi") + graphics::par("mgp")[2]
  expect_gt(below$line, need)
  expect_lt(below$line + 1, graphics::par("mar")[1])
  graphics::par(op)
  # Short names leave the usual margins alone.
  expect_identical(contentvalidR:::.item_axis_left(c("I1", "I2")),
                   c("I1", "I2"))
  expect_identical(graphics::par("mar"), op$mar)
})

test_that("the flow diagram keeps its text at 8 points where it can", {
  rec <- record_arg("text.default", "cex")
  on.exit(stop_recording("text.default"), add = TRUE)
  one <- content_evidence(`Relevance panel` = walkthrough_panel())
  two <- content_evidence(`Relevance panel` = walkthrough_panel(),
                          `Item sort` = walkthrough_sort())
  for (ev in list(one, two)) {
    for (size in list(c(7, 4), c(5, 3.5))) {
      rec$values <- NULL
      grDevices::pdf(NULL, width = size[1], height = size[2])
      plot(ev, type = "flow")
      grDevices::dev.off()
      expect_gte(min(rec$values) * 12, 8 - 1e-9)
    }
  }
})

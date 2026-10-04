# The last round of the audit close-out: what a confirming review found.

long <- function(m, round) {
  data.frame(expert = paste0("E", seq_len(nrow(m))),
             item = rep(colnames(m), each = nrow(m)), round = round,
             rating = as.vector(m), stringsAsFactors = FALSE)
}

# Draws `expr` on a null device and returns every string that mtext() and
# text() were asked to draw.
drawn_text <- function(expr) {
  sink <- new.env()
  sink$text <- character(0)
  grab <- function(x) sink$text <- c(sink$text, as.character(x))
  # text() dispatches through the S3 table, which keeps the untraced
  # text.default, so the generic is traced and its character arguments kept.
  grab_chars <- function(...) {
    for (a in list(...)) if (is.character(a)) grab(a)
  }
  suppressMessages({
    trace("mtext", bquote(.(grab)(text)), print = FALSE, where = graphics::plot)
    trace("text", bquote(.(grab_chars)(...)), print = FALSE,
          where = graphics::plot)
  })
  on.exit(suppressMessages({
    untrace("mtext", where = graphics::plot)
    untrace("text", where = graphics::plot)
  }), add = TRUE)
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  force(expr)
  sink$text
}

delphi_rounds <- function() {
  r1 <- cbind(S1 = c(4, 4, 3, 4, 2, 4, 3, 4), S2 = c(2, 3, 2, 1, 3, 2, 2, 3),
              S3 = c(4, 3, 4, 4, 4, 2, 4, 3))
  r2 <- cbind(S1 = c(4, 4, 4, 4, 3, 4, 3, 4), S2 = c(2, 2, 2, 1, 3, 2, 2, 2),
              S3 = c(4, 4, 4, 4, 4, 3, 4, 4))
  rbind(long(r1, 1), long(r2, 2))
}

test_that("long item names are shortened rather than run past the console", {
  d <- delphi_rounds()
  nm <- c(S1 = "Time needed to deliver the session to every student",
          S2 = "Cost relative to the current approach to teaching it",
          S3 = "Fit with the curriculum taught in the first year")
  d$item <- nm[d$item]
  fit <- delphi_validity(d, lo = 1, hi = 4, consensus_threshold = .75,
                         stability = "chisq_group", seed = 1)
  old <- options(width = 80)
  on.exit(options(old), add = TRUE)
  out <- utils::capture.output(print(fit))
  expect_lte(max(nchar(out, type = "width")), 80L)
  expect_true(any(grepl("Long names are shortened in the middle", out,
                        fixed = TRUE)))
  # The decision and its statistic stay.
  head_line <- out[grep("^  Item", out)[1]]
  expect_match(head_line, "Stable", fixed = TRUE)
  rep_out <- utils::capture.output(print(content_report(fit)))
  expect_lte(max(nchar(rep_out, type = "width")), 80L)
  # The object keeps the names in full.
  expect_true(all(nm %in% fit$results$item))
})

test_that(".shorten_middle keeps the start and end of a name", {
  s <- contentvalidR:::.shorten_middle(c("Alpha beta gamma delta", "Short"), 12)
  expect_identical(s[2], "Short")
  expect_identical(nchar(s[1]), 12L)
  expect_identical(s[1], "Alpha...elta")
})

test_that("a flagged-only report of a domain fit with nothing flagged prints", {
  asg <- data.frame(item = paste0("I", 1:7),
                    construct = c(rep("Autonomy", 4), "Competence",
                                  "Competence", "Relatedness"))
  fit <- domain_validity(asg, cell_col = "construct",
                         targets = c(Autonomy = 4, Competence = 2,
                                     Relatedness = 1))
  rep <- content_report(fit, include = "flagged")
  expect_identical(nrow(rep), 0L)
  expect_true(any(grepl("No units matched", utils::capture.output(print(rep)),
                        fixed = TRUE)))
  md <- content_report(fit, include = "flagged", format = "markdown")
  expect_type(md, "character")
  expect_identical(contentvalidR:::.fmt_pct(numeric(0), base = 7),
                   character(0))
})

test_that("a narrow report says its note covers the columns not shown", {
  fit <- delphi_validity(delphi_rounds(), lo = 1, hi = 4,
                         consensus_threshold = .75, stability = "chisq_group",
                         seed = 1)
  old <- options(width = 50)
  on.exit(options(old), add = TRUE)
  out <- paste(utils::capture.output(print(content_report(fit))),
               collapse = " ")
  if (grepl("Not shown for width", out, fixed = TRUE)) {
    expect_match(gsub("[[:space:]]+", " ", out),
                 "The note describes the full table", fixed = TRUE)
  }
  options(width = 200)
  wide <- paste(utils::capture.output(print(content_report(fit))),
                collapse = " ")
  expect_false(grepl("The note describes the full table", wide, fixed = TRUE))
})

test_that("the evidence key names what a cross marks", {
  d <- rbind(delphi_rounds()[delphi_rounds()$item != "S3", ],
             data.frame(expert = c("E1", "E2", "E1", "E2"), item = "S3",
                        round = c(1, 1, 2, 2), rating = 4))
  fit <- delphi_validity(d, lo = 1, hi = 4, B = 0)
  ev <- content_evidence(Delphi = fit)
  all_text <- paste(drawn_text(plot(ev)), collapse = " ")
  # The collector saw the figure's text, so the check below means something.
  expect_match(all_text, "Delphi", fixed = TRUE)
  expect_false(grepl("Cross: no decision", all_text, fixed = TRUE))
  expect_match(all_text, "Cross: not judged against a criterion", fixed = TRUE)
})

test_that("short stage names are not numbered when numbering would not help", {
  d <- rbind(delphi_rounds()[delphi_rounds()$item != "S3", ],
             data.frame(expert = c("E1", "E2", "E1", "E2"), item = "S3",
                        round = c(1, 1, 2, 2), rating = 4))
  fit <- delphi_validity(d, lo = 1, hi = 4, B = 0)
  panel <- expert_validity(matrix(c(4, 4, 4, 3, 4, 4, 3, 4, 3, 4, 4, 4), 4,
                                  dimnames = list(NULL, c("S1", "S2", "S3"))),
                           mode = "relevance", lo = 1, hi = 4,
                           agreement = "none")
  old <- options(width = 60)
  on.exit(options(old), add = TRUE)
  out <- utils::capture.output(print(content_evidence(Delphi = fit,
                                                      Panel = panel)))
  head_line <- out[grep("^  Item", out)[1]]
  expect_match(head_line, "Delphi", fixed = TRUE)
})

test_that("the flow diagram says items still in play plainly", {
  fit <- delphi_validity(delphi_rounds(), lo = 1, hi = 4, B = 0)
  p2 <- expert_validity(matrix(c(4, 4, 4, 3, 4, 4, 3, 4), 4,
                               dimnames = list(NULL, c("S1", "S2"))),
                        mode = "relevance", lo = 1, hi = 4,
                        agreement = "none")
  ev <- content_evidence(Delphi = fit, Panel = p2)
  all_text <- paste(drawn_text(plot(ev, type = "flow")), collapse = " ")
  expect_match(all_text, "not reviewed here", fixed = TRUE)
  expect_false(grepl("not held back so far not reviewed", all_text,
                     fixed = TRUE))
})

test_that("the construct-rating profile widens its margin for long names", {
  rt <- utils::read.csv(system.file("extdata", "rating_example.csv",
                                    package = "contentvalidR"))
  rt$item <- paste0(rt$item, ": a rating item with a long stem")
  fit <- rating_validity(rt, scale_min = 1, scale_max = 5)
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  mar_seen <- NULL
  setHook("plot.new", function() mar_seen <<- graphics::par("mar"))
  old_hook <- getHook("plot.new")
  on.exit(setHook("plot.new", old_hook[-length(old_hook)], "replace"),
          add = TRUE)
  expect_no_error(plot(fit, type = "profile"))
  expect_gt(mar_seen[2], 5)
})

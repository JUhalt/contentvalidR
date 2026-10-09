#' Combine content evidence across review stages
#'
#' @description
#' Brings the handoffs from several content-review stages together, so the
#' evidence for each item can be read, reported, and drawn as a whole. Give the
#' stages in the order they ran, such as an expert relevance panel and then an
#' item sort. Each stage can be a handoff from [content_handoff()] or a fitted
#' workflow, which is handed off with `keep`.
#'
#' The result prints one row per item, with each stage's decision beside the
#' statistic its rule read, and it draws two figures for a paper or poster:
#'
#' * `plot(x)`, the **item evidence profile**. One panel per stage shows the
#'   statistic each decision read, its interval, and its criterion, and a last
#'   column names the stages that held an item back.
#' * `plot(x, type = "flow")`, the **item flow diagram**. Each stage's box says
#'   how many items it reviewed, a side box lists what it held back with the
#'   number behind each decision, and the last box lists what was carried
#'   forward.
#'
#' @details
#' **The statistic each stage shows** is the one its decision rule reads, taken
#' from the handoff:
#'
#' * an item sort: Psa, against the exact test's criterion;
#' * an expert relevance panel: the I-CVI, against Lynn's (1986) count
#'   (beyond ten experts, this package's extension holding her 7 of 9);
#' * a Delphi study: the share of experts agreeing, against the consensus
#'   threshold;
#' * an essentiality panel: the CVR, against the exact test's criterion;
#' * congruence ratings: the index of item-objective congruence for the
#'   target objective, against the criterion, or the highest index when there
#'   is no target mapping;
#' * construct ratings: HTC, with no criterion, because that workflow decides
#'   on its planned contrasts.
#'
#' Decisions are read from each handoff, never recomputed from the statistic.
#'
#' **Stages in sequence or side by side.** Usually a stage reviews only what
#' the stage before it carried forward, and the flow diagram reads that way.
#' When two methods reviewed the same items side by side, a stage's box says
#' how many of its items an earlier stage had already held back, and its side
#' box lists only the items it held back itself. Either way, an item is carried
#' forward when every stage that reviewed it carried it.
#'
#' @section Where the displays come from:
#' The flow diagram is modeled on the PRISMA 2020 flow diagram for systematic
#' reviews (Page et al., 2021), with items in place of studies. The evidence
#' profile is this package's own design. It sets out each stage's statistic as
#' a forest plot does, one panel per stage, so that agreement and disagreement
#' between methods can be seen item by item. Neither computes anything new:
#' both draw the statistics and decisions the stages already made.
#'
#' @param ... Handoffs from [content_handoff()], or fitted workflows that
#'   [content_handoff()] accepts, in the order the stages ran. Name them to
#'   label the stages, as in `content_evidence(Panel = h1, Sort = h2)`.
#'   Unnamed stages are labeled by their workflow.
#' @param keep Statuses carried forward when a stage is given as a fitted
#'   workflow rather than a handoff, as in [content_handoff()]. A handoff
#'   already records what it carried, so `keep` does not change it.
#'
#' @return An object of class `contentvalid_evidence`, a list with:
#'   \describe{
#'     \item{`stages`}{the handoffs, named by stage.}
#'     \item{`items`}{every item reviewed, in the order first reviewed.}
#'     \item{`evidence`}{one row per item per stage: `item`, `scale`, `stage`,
#'       `statistic`, `value`, `lower`, `upper`, `level`, `criterion`,
#'       `recommendation`, `status`, and `carried`. `as.data.frame()` returns
#'       it.}
#'     \item{`flow`}{for each stage, the items it reviewed, those an earlier
#'       stage had already held back, those it held back itself, and those
#'       carried so far that it did not review.}
#'     \item{`carried`}{the items carried by every stage that reviewed them.}
#'   }
#'
#' @references
#' Lynn, M. R. (1986). Determination and quantification of content validity.
#' *Nursing Research, 35*(6), 382–385.
#' \doi{10.1097/00006199-198611000-00017}
#'
#' Page, M. J., McKenzie, J. E., Bossuyt, P. M., Boutron, I., Hoffmann, T. C.,
#' Mulrow, C. D., Shamseer, L., Tetzlaff, J. M., Akl, E. A., Brennan, S. E.,
#' Chou, R., Glanville, J., Grimshaw, J. M., Hróbjartsson, A., Lalu, M. M.,
#' Li, T., Loder, E. W., Mayo-Wilson, E., McDonald, S., . . . Moher, D.
#' (2021). The PRISMA 2020 statement: An updated guideline for reporting
#' systematic reviews. *BMJ, 372*, Article n71. \doi{10.1136/bmj.n71}
#'
#' @seealso [content_handoff()] for a single stage, and
#'   [plot.contentvalid_evidence()] for the two figures.
#'
#' @examples
#' relevance <- matrix(
#'   c(4,4,4,3, 4,4,3,4, 3,4,4,4, 2,2,1,2),
#'   nrow = 4,
#'   dimnames = list(NULL, paste0("Item", 1:4))
#' )
#' panel <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
#'                          agreement = "none")
#' # The sort reviews the three items the panel carried forward.
#' sorts <- data.frame(
#'   item = rep(paste0("Item", 1:3), each = 12),
#'   rater = rep(1:12, 3),
#'   target_construct = rep(c("A", "A", "B"), each = 12),
#'   assigned_construct = c(rep("A", 11), "B", rep("A", 10), "B", "B",
#'                          rep("B", 5), rep("A", 7))
#' )
#' evidence <- content_evidence(`Relevance panel` = panel,
#'                              `Item sort` = sort_validity(sorts))
#' evidence
#' plot(evidence)
#' plot(evidence, type = "flow")
#' plot(evidence, apa = FALSE)
#' @export
content_evidence <- function(..., keep = "Supported") {
  stages <- list(...)
  if (!length(stages)) {
    stop("Give at least one handoff or fitted workflow, in the order the ",
         "stages ran.", call. = FALSE)
  }
  given <- names(stages)
  if (is.null(given)) given <- rep("", length(stages))
  given[is.na(given)] <- ""
  stages <- lapply(seq_along(stages), function(i) {
    .evidence_as_handoff(stages[[i]], keep, i)
  })
  labels <- ifelse(nzchar(given), given,
                   vapply(stages, .evidence_stage_label, character(1)))
  dup <- duplicated(labels) | duplicated(labels, fromLast = TRUE)
  labels[dup] <- sprintf("%s (stage %d)", labels[dup], which(dup))
  names(stages) <- labels

  evidence <- do.call(rbind, lapply(seq_along(stages), function(k) {
    .evidence_rows(stages[[k]], labels[k])
  }))
  rownames(evidence) <- NULL
  items <- unique(evidence$item)
  # One construct per item: the first stage that mapped it says which.
  mapped <- evidence[!is.na(evidence$scale), , drop = FALSE]
  scale <- mapped$scale[match(items, mapped$item)]
  evidence$scale <- scale[match(evidence$item, items)]

  flow <- .evidence_flow(stages)
  structure(
    list(stages = stages, items = items, evidence = evidence,
         flow = flow$stages, carried = items[items %in% flow$carried]),
    class = "contentvalid_evidence"
  )
}

.evidence_as_handoff <- function(x, keep, i) {
  if (inherits(x, "cv_handoff")) {
    v <- x$provenance$schema_version
    if (!identical(as.integer(v), 1L)) {
      stop(sprintf(paste("Stage %d is a handoff with schema version %s;",
                         "content_evidence() reads version 1."), i, format(v)),
           call. = FALSE)
    }
    return(x)
  }
  if (inherits(x, "contentvalid_workflow")) return(content_handoff(x, keep = keep))
  stop(sprintf(paste("Stage %d is not a handoff or a fitted workflow. Give the",
                     "result of content_handoff(), or a fit such as",
                     "sort_validity() returns."), i), call. = FALSE)
}

.evidence_stage_label <- function(h) {
  mode <- as.character(h$provenance$mode)
  switch(h$provenance$workflow,
         "item-sort" = "Item sort",
         "construct-rating" = "Construct rating",
         "delphi" = "Delphi",
         "expert-panel" = switch(mode,
                                 relevance = "Relevance panel",
                                 essentiality = "Essentiality panel",
                                 congruence = "Congruence panel",
                                 "Expert panel"),
         h$provenance$workflow)
}

# The statistic each workflow's decision rule reads, as the handoff names it.
.evidence_headline_stat <- function(h) {
  wf <- h$provenance$workflow
  mode <- as.character(h$provenance$mode)
  have <- unique(h$item_statistics$statistic)
  pick <- switch(wf,
    "item-sort" = "Psa",
    "construct-rating" = "HTC",
    "delphi" = "I-CVI",
    "expert-panel" = switch(mode,
                            relevance = "I-CVI",
                            essentiality = "CVR",
                            # The last two are the names before 1.0.
                            congruence = c("target IOC", "highest IOC",
                                           "IOC margin", "IOC")[
                              c("target IOC", "highest IOC", "IOC margin",
                                "IOC") %in% have][1],
                            NA_character_),
    NA_character_)
  if (is.na(pick) || !pick %in% have) {
    stop("A ", wf, " handoff carries no statistic content_evidence() can ",
         "show.", call. = FALSE)
  }
  pick
}

# The name a reader sees. A Delphi handoff stores the share agreeing under
# "I-CVI", which is what it is, but the Delphi literature calls it agreement.
.evidence_display_stat <- function(stat, workflow) {
  if (identical(workflow, "delphi")) "Share agreeing" else stat
}

.evidence_rows <- function(h, label) {
  stat <- .evidence_headline_stat(h)
  s <- h$item_statistics[h$item_statistics$statistic == stat, , drop = FALSE]
  ev <- h$item_evidence
  idx <- match(ev$item, s$item)
  col <- function(name) if (name %in% names(s)) s[[name]][idx] else rep(NA, nrow(ev))
  data.frame(
    item = as.character(ev$item),
    scale = as.character(ev$scale),
    stage = label,
    statistic = .evidence_display_stat(stat, h$provenance$workflow),
    value = as.numeric(s$value[idx]),
    lower = as.numeric(col("lower")),
    upper = as.numeric(col("upper")),
    level = as.numeric(col("interval_level")),
    criterion = as.numeric(s$criterion[idx]),
    recommendation = as.character(ev$recommendation),
    status = as.character(ev$status),
    carried = as.logical(ev$carried),
    stringsAsFactors = FALSE
  )
}

# What each stage reviewed and held back, reading the stages in order. An item
# stays in play until a stage that reviews it holds it back.
.evidence_flow <- function(stages) {
  in_play <- character(0)
  seen <- character(0)
  out <- vector("list", length(stages))
  for (k in seq_along(stages)) {
    ev <- stages[[k]]$item_evidence
    reviewed <- unique(as.character(ev$item))
    already_out <- intersect(reviewed, setdiff(seen, in_play))
    added <- if (k == 1L) character(0) else setdiff(reviewed, seen)
    not_reviewed <- setdiff(in_play, reviewed)
    in_play <- if (k == 1L) reviewed else union(in_play, added)
    held <- intersect(as.character(ev$item[!ev$carried]), in_play)
    in_play <- setdiff(in_play, held)
    seen <- union(seen, reviewed)
    out[[k]] <- list(reviewed = reviewed, already_out = already_out,
                     added = added, not_reviewed = not_reviewed, held = held,
                     n_judges = ev$n_judges, workflow = stages[[k]]$provenance$workflow)
  }
  names(out) <- names(stages)
  list(stages = out, carried = in_play)
}

# "8 experts", "12 to 20 judges", or "judges not recorded".
.evidence_judges <- function(f) {
  who <- if (f$workflow %in% c("expert-panel", "delphi")) "expert" else "judge"
  nj <- f$n_judges[!is.na(f$n_judges)]
  if (!length(nj)) return(paste0(who, "s not recorded"))
  if (min(nj) == max(nj)) return(.n_noun(nj[1], who))
  sprintf("%d to %d %ss", min(nj), max(nj), who)
}

# APA numbers: no leading zero, except for the IOC margin, which can exceed 1.
.evidence_value_text <- function(value, statistic) {
  statistic <- rep_len(statistic, length(value))
  out <- .fmt(value, bounded = TRUE)
  wide <- statistic %in% "IOC margin"
  out[wide] <- .fmt(value[wide], bounded = FALSE)
  out
}

.evidence_verdicts <- function(x) {
  ev <- x$evidence
  vapply(x$items, function(it) {
    rows <- ev[ev$item == it, , drop = FALSE]
    if (it %in% x$carried) return("carried")
    held_by <- rows$stage[!rows$carried]
    if (!length(held_by)) return("carried")
    paste("held back:", paste(held_by, collapse = "; "))
  }, character(1), USE.NAMES = FALSE)
}

#' @export
print.contentvalid_evidence <- function(x, ...) {
  ns <- length(x$stages)
  title <- sprintf("Content evidence across %s", .n_noun(ns, "stage"))
  .print_header(x, title)
  verdict <- .evidence_verdicts(x)
  held <- x$items[verdict != "carried"]
  holders <- vapply(held, function(it) {
    rows <- x$evidence[x$evidence$item == it & !x$evidence$carried, ]
    paste(rows$stage, collapse = "; ")
  }, character(1))
  .say(sprintf("%d of %s carried by every stage that reviewed %s.",
               length(x$carried), .n_noun(length(x$items), "item"),
               if (length(x$items) == 1L) "it" else "them"),
       if (length(held)) {
         paste0("Held back: ", paste(sprintf("%s (%s)", held, holders),
                                     collapse = ", "), ".")
       })

  .section("Stages, in order")
  for (k in seq_len(ns)) {
    f <- x$flow[[k]]
    stat <- x$evidence$statistic[x$evidence$stage == names(x$stages)[k]][1]
    .say(sprintf("%d. %s: %s, %s. Shows %s.", k, names(x$stages)[k],
                 .n_noun(length(f$reviewed), "item"), .evidence_judges(f),
                 stat),
         indent = 2L, exdent = 5L)
  }

  cat("\n")
  tab <- data.frame(item = x$items, stringsAsFactors = FALSE)
  for (lab in names(x$stages)) {
    rows <- x$evidence[x$evidence$stage == lab, , drop = FALSE]
    i <- match(x$items, rows$item)
    cell <- ifelse(is.na(i), "--",
                   paste(.evidence_value_text(rows$value[i], rows$statistic[i]),
                         rows$recommendation[i]))
    tab[[lab]] <- cell
  }
  # Status words start with a capital, as in every other table.
  tab$result <- .sentence_case(verdict)
  .print_table(tab)

  if (.show_key()) {
    stats <- unique(x$evidence$statistic)
    term <- c(Psa = "psa", `I-CVI` = "I_CVI", `Share agreeing` = "prop_agree",
              CVR = "cvr", `target IOC` = "ioc", `highest IOC` = "ioc",
              `IOC margin` = "ioc", IOC = "ioc", HTC = "htc")
    known <- stats[stats %in% names(term)]
    .print_key(unname(term[known]), headings = known)
    .say("Result -- Carried when every stage that reviewed the item carried",
         "it; otherwise the stages that held it back. -- marks a stage that",
         "did not review the item.", indent = 2L, exdent = 6L)
    .print_key_footer()
  }
  .closing(pointer = paste("See plot(x) for the evidence profile and",
                           "plot(x, type = \"flow\") for the flow diagram;",
                           "add apa = FALSE for color."))
  invisible(x)
}

#' @export
as.data.frame.contentvalid_evidence <- function(x, row.names = NULL,
                                                optional = FALSE, ...) {
  out <- x$evidence
  if (!is.null(row.names)) rownames(out) <- row.names
  out
}

#' Plot content evidence across review stages
#'
#' @description
#' Draws the two figures of [content_evidence()].
#'
#' `type = "profile"` (default), the item evidence profile, gives one panel
#' per stage with the items down the side. Each panel shows the statistic that
#' stage's decision read, its interval as a bar, and its criterion as a dashed
#' line. A filled symbol met the criterion, an open one was flagged for review,
#' and a cross marks no decision. "not reviewed" marks an item a stage did not
#' see. The last column says whether each item was carried, or names the
#' stages that held it back. Faint lines separate the constructs.
#'
#' `type = "flow"`, the item flow diagram, follows the items through the
#' stages, modeled on the PRISMA 2020 flow diagram (Page et al., 2021). Each
#' stage's box gives how many items it reviewed and by how many judges; its
#' side box lists each item it held back, with the decision and the number
#' behind it; and the last box lists the items carried forward, by construct.
#'
#' @param x A `contentvalid_evidence` object.
#' @param type `"profile"` or `"flow"`.
#' @param apa `TRUE` (default) draws in black, white, and gray, as an APA
#'   figure is printed. `FALSE` marks evidence that met its criterion in teal
#'   and evidence under review in brown, a colorblind-safe scheme for slides
#'   and posters. Symbols carry the decision either way, so neither reading
#'   depends on color.
#' @param show_legend Draw the key above the profile. Default `TRUE`.
#' @param ... Additional graphical arguments passed to [graphics::plot()] for
#'   each panel of the profile. The flow diagram does not use them.
#'
#' @return `x`, invisibly. Called for the plot it draws.
#'
#' @references
#' Page, M. J., McKenzie, J. E., Bossuyt, P. M., Boutron, I., Hoffmann, T. C.,
#' Mulrow, C. D., Shamseer, L., Tetzlaff, J. M., Akl, E. A., Brennan, S. E.,
#' Chou, R., Glanville, J., Grimshaw, J. M., Hróbjartsson, A., Lalu, M. M.,
#' Li, T., Loder, E. W., Mayo-Wilson, E., McDonald, S., . . . Moher, D.
#' (2021). The PRISMA 2020 statement: An updated guideline for reporting
#' systematic reviews. *BMJ, 372*, Article n71. \doi{10.1136/bmj.n71}
#'
#' @seealso [content_evidence()].
#'
#' @examples
#' relevance <- matrix(
#'   c(4,4,4,3, 4,4,3,4, 3,4,4,4, 2,2,1,2),
#'   nrow = 4,
#'   dimnames = list(NULL, paste0("Item", 1:4))
#' )
#' panel <- expert_validity(relevance, mode = "relevance", lo = 1, hi = 4,
#'                          agreement = "none")
#' sorts <- data.frame(
#'   item = rep(paste0("Item", 1:3), each = 12),
#'   rater = rep(1:12, 3),
#'   target_construct = rep(c("A", "A", "B"), each = 12),
#'   assigned_construct = c(rep("A", 11), "B", rep("A", 10), "B", "B",
#'                          rep("B", 5), rep("A", 7))
#' )
#' evidence <- content_evidence(`Relevance panel` = panel,
#'                              `Item sort` = sort_validity(sorts))
#' plot(evidence)
#' plot(evidence, type = "flow", apa = FALSE)
#' @export
plot.contentvalid_evidence <- function(x, type = c("profile", "flow"),
                                       apa = TRUE, show_legend = TRUE, ...) {
  type <- .choose(type)
  .validate_flag(apa, "apa")
  .validate_flag(show_legend, "show_legend")
  if (type == "flow") {
    .plot_evidence_flow(x, apa)
  } else {
    .plot_evidence_profile(x, apa, show_legend, ...)
  }
  invisible(x)
}

.plot_evidence_profile <- function(x, apa, show_legend, ...) {
  ev <- x$evidence
  items <- x$items
  n <- length(items)
  y <- rev(seq_len(n))
  stages <- names(x$stages)
  ns <- length(stages)
  pal <- .evidence_colours(apa)

  # Faint lines between constructs, drawn only when the items come grouped by
  # construct; items no stage mapped are passed over.
  scale <- ev$scale[match(items, ev$item)]
  known <- scale
  for (i in seq_along(known)[-1]) if (is.na(known[i])) known[i] <- known[i - 1]
  runs <- rle(known[!is.na(known)])$values
  breaks <- if (length(runs) == length(unique(runs)) && length(runs) > 1L) {
    which(!is.na(known[-1]) & !is.na(known[-n]) & known[-1] != known[-n])
  } else integer(0)

  op <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(op), add = TRUE)
  lab <- .item_labels(items, width_in = graphics::par("din")[1])
  # A title is drawn once, above every panel, not on each one.
  dots <- list(...)
  main <- dots$main
  graphics::par(oma = c(0, lab$lines,
                        (if (show_legend) 1.6 else 0.3) +
                          if (length(main)) 1.6 else 0, 0.5),
                mar = c(4.1, 0.6, 1.9, 0.6))
  graphics::layout(matrix(seq_len(ns + 1L), 1), widths = c(rep(1, ns), 0.75))

  any_ci <- FALSE
  any_crit <- FALSE
  shown <- character(0)
  for (k in seq_len(ns)) {
    s <- ev[ev$stage == stages[k], , drop = FALSE]
    stat <- s$statistic[1]
    xlim <- switch(stat, CVR = c(-1, 1), IOC = c(-1, 1), `target IOC` = c(-1, 1),
                   `highest IOC` = c(-1, 1), `IOC margin` = c(-2, 2), c(0, 1))
    .plot_with(list(x = NA, xlim = xlim, ylim = c(0.4, n + 0.6), xaxt = "n",
                    yaxt = "n", xlab = stat, ylab = ""), dots,
               protect = c("type", "xaxt", "yaxt", "axes", "main", "ylab"))
    if (stat == "IOC margin") {
      graphics::axis(1, at = seq(-2, 2))
    } else {
      .axis_bounded(1, at = seq(xlim[1], xlim[2], length.out = 5))
    }
    if (k == 1L) graphics::axis(2, at = y, labels = lab$labels, las = 1)
    if (length(breaks)) graphics::abline(h = y[breaks] - 0.5, col = "grey80")
    row <- match(s$item, items)
    crit <- unique(s$criterion[is.finite(s$criterion)])
    if (length(crit) == 1L) {
      graphics::abline(v = crit, lty = 2)
      any_crit <- TRUE
    } else if (length(crit) > 1L) {
      # A criterion that differs by item is marked on its own row.
      ok <- is.finite(s$criterion)
      graphics::segments(s$criterion[ok], y[row][ok] - 0.3, s$criterion[ok],
                         y[row][ok] + 0.3, lty = 2)
      any_crit <- TRUE
    }
    col <- .status_colour(s$status, apa)
    ok <- is.finite(s$lower) & is.finite(s$upper)
    if (any(ok)) {
      graphics::segments(s$lower[ok], y[row][ok], s$upper[ok], y[row][ok],
                         col = col[ok])
      any_ci <- TRUE
    }
    graphics::points(s$value, y[row], pch = .status_pch(s$status), col = col,
                     cex = 1.15)
    shown <- c(shown, s$status)
    missing <- setdiff(items, s$item)
    if (length(missing)) {
      graphics::text(mean(xlim), y[match(missing, items)], "not reviewed",
                     cex = 0.72, col = "grey40", font = 3)
    }
    graphics::mtext(stages[k], side = 3, line = 0.5, cex = 0.8, font = 2)
  }

  graphics::plot(NA, xlim = c(0, 1), ylim = c(0.4, n + 0.6), axes = FALSE,
                 xlab = "", ylab = "")
  graphics::mtext("Across stages", side = 3, line = 0.5, cex = 0.8, font = 2)
  if (length(breaks)) graphics::abline(h = y[breaks] - 0.5, col = "grey80")
  verdict <- .evidence_verdicts(x)
  held <- verdict != "carried"
  graphics::text(0.02, y, verdict, adj = 0, cex = 0.78,
                 font = ifelse(held, 2, 1),
                 col = ifelse(held, pal$review, pal$met), xpd = NA)

  if (isTRUE(show_legend)) {
    level <- unique(ev$level[is.finite(ev$level)])
    parts <- c(
      if (any(shown %in% "Supported")) "Filled: met the criterion.",
      if (any(shown %in% "Review")) "Open: review.",
      if (any(!shown %in% c("Supported", "Review"))) "Cross: no decision.",
      if (any_crit) "Dashed line: criterion.",
      if (any_ci) {
        if (length(level) == 1L) sprintf("Bar: %s%% interval.", format(100 * level))
        else "Bar: interval."
      }
    )
    graphics::mtext(paste(parts, collapse = "   "), side = 3, outer = TRUE,
                    line = 0.2, cex = 0.72)
  }
  if (length(main)) {
    graphics::title(main = main, outer = TRUE,
                    line = (if (show_legend) 1.6 else 0.3) + 0.2)
  }
  invisible(NULL)
}

.plot_evidence_flow <- function(x, apa) {
  pal <- .evidence_colours(apa)
  ev <- x$evidence
  op <- graphics::par(mar = c(0.3, 0.3, 0.3, 0.3))
  on.exit(graphics::par(op), add = TRUE)
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 1), ylim = c(0, 1), xaxs = "i", yaxs = "i")

  # Every box's text first, so the diagram can be sized to the page.
  rows <- lapply(seq_along(x$flow), function(k) {
    f <- x$flow[[k]]
    main <- c(sprintf("Stage %d: %s", k, names(x$flow)[k]),
              sprintf("%s reviewed by %s", .n_noun(length(f$reviewed), "item"),
                      .evidence_judges(f)))
    if (length(f$already_out)) {
      main <- c(main, sprintf("including %s already held back",
                              .n_noun(length(f$already_out), "item")))
    }
    if (length(f$added)) {
      main <- c(main, sprintf("including %s not reviewed before",
                              .n_noun(length(f$added), "item")))
    }
    if (length(f$not_reviewed)) {
      main <- c(main, sprintf("%s carried so far not reviewed here",
                              .n_noun(length(f$not_reviewed), "item")))
    }
    s <- ev[ev$stage == names(x$flow)[k], , drop = FALSE]
    side <- sprintf("Held back: %d", length(f$held))
    if (!length(f$held)) side <- c(side, "none")
    for (it in f$held) {
      r <- s[s$item == it, , drop = FALSE][1, ]
      number <- if (is.finite(r$value)) {
        txt <- paste(r$statistic, .evidence_value_text(r$value, r$statistic))
        if (is.finite(r$criterion)) {
          txt <- paste0(txt, ", criterion ",
                        .evidence_value_text(r$criterion, r$statistic))
        }
        txt
      } else ""
      side <- c(side, sprintf("%s (%s)%s", it, r$recommendation,
                              if (nzchar(number)) paste0(": ", number) else ""))
    }
    list(main = main, side = side)
  })
  final <- sprintf("Carried forward: %s", .n_noun(length(x$carried), "item"))
  scale <- ev$scale[match(x$carried, ev$item)]
  if (any(!is.na(scale))) {
    groups <- unique(scale)
    for (g in groups) {
      its <- x$carried[if (is.na(g)) is.na(scale) else scale %in% g]
      lab <- if (is.na(g)) "Unmapped" else g
      final <- c(final, strwrap(sprintf("%s (%d): %s", lab, length(its),
                                        paste(its, collapse = ", ")),
                                width = 52, exdent = 4))
    }
  } else if (length(x$carried)) {
    final <- c(final, strwrap(paste(x$carried, collapse = ", "), width = 52))
  }

  main_x <- c(0.02, 0.47)
  side_x <- c(0.54, 0.98)
  # Shrink the text until the widest line fits its box and the whole diagram
  # fits the page.
  cex <- 0.85
  widest <- function(lines, width) {
    max(graphics::strwidth(lines, cex = cex, font = 2)) / width
  }
  need <- max(unlist(lapply(rows, function(r) {
    c(widest(r$main, diff(main_x)), widest(r$side, diff(side_x)))
  })), widest(final, diff(main_x)))
  if (need > 0.94) cex <- cex * 0.94 / need
  line_h <- function() {
    graphics::par("cin")[2] * cex * 1.3 / graphics::par("pin")[2]
  }
  box_h <- function(nl) line_h() * (nl + 0.7)
  heights <- function() {
    row_h <- vapply(rows, function(r) max(box_h(length(r$main)),
                                          box_h(length(r$side))), numeric(1))
    list(row = row_h, gap = line_h() * 2.2,
         total = sum(row_h) + line_h() * 2.2 * length(rows) +
           box_h(length(final)))
  }
  hs <- heights()
  if (hs$total > 0.96) {
    cex <- cex * 0.96 / hs$total
    hs <- heights()
  }

  draw_box <- function(x0, x1, top, lines, fill) {
    lh <- line_h()
    h <- lh * (length(lines) + 0.7)
    graphics::rect(x0, top - h, x1, top, col = fill, border = pal$border)
    for (i in seq_along(lines)) {
      graphics::text((x0 + x1) / 2, top - lh * (i - 0.15), lines[i], cex = cex,
                     font = if (i == 1L) 2 else 1)
    }
    top - h
  }

  top <- 0.5 + hs$total / 2
  for (k in seq_along(rows)) {
    r <- rows[[k]]
    mid <- top - hs$row[k] / 2
    bottom <- draw_box(main_x[1], main_x[2], mid + box_h(length(r$main)) / 2,
                       r$main, pal$stage)
    draw_box(side_x[1], side_x[2], mid + box_h(length(r$side)) / 2, r$side,
             pal$held)
    graphics::arrows(main_x[2], mid, side_x[1], mid, length = 0.07)
    next_top <- top - hs$row[k] - hs$gap
    graphics::arrows(mean(main_x), bottom, mean(main_x), next_top,
                     length = 0.07)
    top <- next_top
  }
  draw_box(main_x[1], main_x[2], top, final, pal$final)
  invisible(NULL)
}

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
#' statistic behind it, and it draws two figures for a paper or poster:
#'
#' * `plot(x)`, the **item evidence profile**. One panel per stage shows the
#'   statistic behind each decision, its interval, and its criterion where the
#'   stage's rule has one, and a last column names the stages that held an
#'   item back.
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
#' A congruence handoff made before contentvalidR 1.0 is refused, because its
#' "target IOC" holds a mean rating rather than the index; fit the panel again
#' with [expert_validity()] and hand that fit off.
#'
#' **Stages in sequence or side by side.** Usually a stage reviews only what
#' the stage before it carried forward, and the flow diagram reads that way.
#' When two methods reviewed the same items side by side, a stage's box says
#' how many of its items an earlier stage had already held back, and its side
#' box lists only the items it held back itself. Either way, an item is carried
#' forward when every stage that reviewed it carried it.
#'
#' **A stage that applied no decision rule holds nothing back.** When every
#' item of a stage is "Descriptive only", as in a Delphi study run without a
#' consensus threshold or congruence ratings without a target mapping, the
#' stage described its items and decided nothing. Its handoff carries none of
#' them, but that is not a judgment against any, so here it does not count as
#' holding them back: an item is carried when every stage that reviewed it
#' and applied a decision rule carried it. The printout names such a stage,
#' and its statistic is still shown. To carry the items of a single such stage
#' on its own, use `keep = "Descriptive only"` in [content_handoff()].
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
#'   Unnamed stages are labeled by their workflow. A stage cannot be labeled
#'   `"item"` or `"result"`, which head the printed table's other columns.
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
#'       stage had already held back, those it held back itself, those
#'       carried so far that it did not review, and `decided`, whether it
#'       applied a decision rule.}
#'     \item{`carried`}{the items carried by every stage that reviewed them
#'       and applied a decision rule.}
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
  # Stage labels become column headings beside the item and the result.
  reserved <- given[tolower(trimws(given)) %in% c("item", "result")]
  if (length(reserved)) {
    stop("A stage cannot be labeled ",
         paste0("\"", reserved, "\"", collapse = " or "),
         ": the evidence table already has a column of that name.",
         call. = FALSE)
  }
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
    # The same refusal content_handoff() gives a congruence fit from before
    # 1.0, in a handoff's terms.
    if (.evidence_congruence_pre10(x)) {
      targeted <- "target IOC" %in% x$item_statistics$statistic
      stop(sprintf(paste(
        "Stage %d is a congruence handoff made before contentvalidR 1.0. Its",
        "\"%s\" holds a mean rating, not the index of item-objective",
        "congruence%s. Fit it again with expert_validity() and hand that fit",
        "off to get the index and its criterion."), i,
        if (targeted) "target IOC" else "IOC",
        if (targeted) ", and its decision used the highest mean" else ""),
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

# A congruence handoff made before 1.0 stored the mean rating where the index
# belongs: "target IOC" beside "competitor IOC" and "IOC margin" with a
# target mapping, "IOC" without one. Since 1.0 the means travel under their
# own names ("target mean rating"), and an untargeted handoff carries
# "highest IOC", so a handoff with the old names and neither new one is from
# before 1.0. Showing it would present a mean as the index.
.evidence_congruence_pre10 <- function(h) {
  have <- unique(as.character(h$item_statistics$statistic))
  identical(as.character(h$provenance$workflow), "expert-panel") &&
    identical(as.character(h$provenance$mode), "congruence") &&
    any(c("competitor IOC", "IOC margin", "IOC") %in% have) &&
    !any(c("target mean rating", "highest IOC") %in% have)
}

# Whether a stage applied a decision rule. A stage whose every item is
# "Descriptive only" (a Delphi study without a consensus threshold,
# congruence ratings without a target mapping) made no decision, so the items
# it did not carry were not held back by it: they were only described.
.evidence_decided <- function(h) {
  !all(as.character(h$item_evidence$status) %in% "Descriptive only")
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
                            congruence = c("target IOC", "highest IOC")[
                              c("target IOC", "highest IOC") %in% have][1],
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
# stays in play until a stage that reviews it holds it back. A stage that
# applied no decision rule holds nothing back.
.evidence_flow <- function(stages) {
  in_play <- character(0)
  seen <- character(0)
  out <- vector("list", length(stages))
  for (k in seq_along(stages)) {
    ev <- stages[[k]]$item_evidence
    decided <- .evidence_decided(stages[[k]])
    reviewed <- unique(as.character(ev$item))
    already_out <- intersect(reviewed, setdiff(seen, in_play))
    added <- if (k == 1L) character(0) else setdiff(reviewed, seen)
    not_reviewed <- setdiff(in_play, reviewed)
    in_play <- if (k == 1L) reviewed else union(in_play, added)
    held <- if (decided) {
      intersect(as.character(ev$item[!ev$carried]), in_play)
    } else {
      character(0)
    }
    in_play <- setdiff(in_play, held)
    seen <- union(seen, reviewed)
    out[[k]] <- list(reviewed = reviewed, already_out = already_out,
                     added = added, not_reviewed = not_reviewed, held = held,
                     decided = decided, n_judges = ev$n_judges,
                     workflow = stages[[k]]$provenance$workflow)
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

# APA numbers with no leading zero: every statistic a stage shows (Psa, the
# I-CVI, the share agreeing, the CVR, the IOC, HTC) lies within -1 to 1.
.evidence_value_text <- function(value, statistic) {
  .fmt(value, bounded = TRUE)
}

# The stages that applied a decision rule, by name.
.evidence_deciding <- function(x) {
  names(x$stages)[vapply(x$stages, .evidence_decided, logical(1))]
}

# The stages that held each item back, in order: only stages that applied a
# decision rule hold anything back.
.evidence_holders <- function(x) {
  ev <- x$evidence
  deciding <- .evidence_deciding(x)
  lapply(x$items, function(it) {
    if (it %in% x$carried) return(character(0))
    ev$stage[ev$item == it & !ev$carried & ev$stage %in% deciding]
  })
}

# Each item's result across the stages: "carried", or "held back:" and the
# stages, by name for the figure and by number for the table, where the
# numbered list of stages above it gives the names.
.evidence_verdicts <- function(x, numbered = FALSE) {
  holders <- .evidence_holders(x)
  vapply(holders, function(held_by) {
    if (!length(held_by)) return("carried")
    if (numbered) {
      paste("held back:", paste(match(held_by, names(x$stages)),
                                collapse = ", "))
    } else {
      paste("held back:", paste(held_by, collapse = "; "))
    }
  }, character(1), USE.NAMES = FALSE)
}

#' @export
print.contentvalid_evidence <- function(x, ...) {
  ns <- length(x$stages)
  title <- sprintf("Content evidence across %s", .n_noun(ns, "stage"))
  .print_header(x, title)
  stage_names <- names(x$stages)
  holders <- .evidence_holders(x)
  held <- lengths(holders) > 0L
  # A stage that applied no decision rule holds nothing back, so the headline
  # names it rather than count its items as held back.
  quiet <- setdiff(stage_names, .evidence_deciding(x))
  n_items <- length(x$items)
  .say(
    if (length(quiet) == ns) {
      sprintf(paste("No stage applied a decision rule (every item is",
                    "Descriptive only), so none held an item back: %s",
                    "carried."),
              if (n_items == 1L) "the item is" else
                sprintf("all %d items are", n_items))
    } else {
      sprintf("%d of %s carried by every stage that %s %s.",
              length(x$carried), .n_noun(n_items, "item"),
              if (length(quiet)) "applied a decision rule to" else "reviewed",
              if (n_items == 1L) "it" else "them")
    },
    if (any(held)) {
      paste0("Held back: ",
             paste(sprintf("%s (%s)", x$items[held],
                           vapply(holders[held], paste, character(1),
                                  collapse = "; ")),
                   collapse = ", "), ".")
    },
    if (length(quiet) && length(quiet) < ns) {
      sprintf(paste("%s applied no decision rule (every item is Descriptive",
                    "only), so %s no item back."),
              .and_list(quiet),
              if (length(quiet) == 1L) "it holds" else "they hold")
    }
  )

  .section("Stages, in order")
  for (k in seq_len(ns)) {
    f <- x$flow[[k]]
    stat <- x$evidence$statistic[x$evidence$stage == stage_names[k]][1]
    .say(sprintf("%d. %s: %s, %s. Shows %s%s.", k, stage_names[k],
                 .n_noun(length(f$reviewed), "item"), .evidence_judges(f),
                 stat,
                 if (stage_names[k] %in% quiet) "; no decision rule" else ""),
         indent = 2L, exdent = 5L)
  }

  cat("\n")
  tab <- data.frame(item = x$items, stringsAsFactors = FALSE)
  for (lab in stage_names) {
    rows <- x$evidence[x$evidence$stage == lab, , drop = FALSE]
    i <- match(x$items, rows$item)
    cell <- ifelse(is.na(i), .missing_mark,
                   paste(.evidence_value_text(rows$value[i], rows$statistic[i]),
                         rows$recommendation[i]))
    tab[[lab]] <- cell
  }
  # Status words start with a capital, as in every other table. The stages
  # that held an item back are given by number, as listed above, so that
  # long stage names do not crowd the stages' own columns off the table.
  tab$result <- .sentence_case(.evidence_verdicts(x, numbered = TRUE))
  shown <- .print_table(tab, as_is = stage_names)

  if (.show_key()) {
    # The key explains only the columns the table could show.
    on_screen <- stage_names[stage_names %in% shown]
    stats <- unique(x$evidence$statistic[x$evidence$stage %in% on_screen])
    term <- c(Psa = "psa", `I-CVI` = "I_CVI", `Share agreeing` = "prop_agree",
              CVR = "cvr", `target IOC` = "ioc", `highest IOC` = "ioc",
              HTC = "htc")
    known <- stats[stats %in% names(term)]
    if (length(known)) {
      .print_key(unname(term[known]), headings = known)
    } else {
      .section("What these columns mean")
    }
    cells <- as.character(unlist(tab[on_screen], use.names = FALSE))
    alone <- any(cells == .missing_mark)
    before <- any(startsWith(cells, paste0(.missing_mark, " ")))
    .say("Result -- Carried when every stage that reviewed the item carried",
         "it; otherwise the numbers of the stages that held it back, as",
         "listed above.",
         if (length(quiet)) {
           "A stage that applied no decision rule holds nothing back."
         },
         if (alone) {
           sprintf("A \"%s\"%s marks a stage that did not review the item.",
                   .missing_mark, if (before) " alone" else "")
         },
         if (before) {
           sprintf(paste("A \"%s\" before a decision marks a statistic that",
                         "could not be computed."), .missing_mark)
         },
         indent = 2L, exdent = 6L)
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
#' per stage with the items down the side. Each panel shows the statistic
#' behind that stage's decisions, its interval as a bar, and, where the
#' stage's rule has one, its criterion as a dashed line. Construct ratings
#' have none: that workflow decides on planned contrasts, not on the HTC
#' shown. A filled symbol met the stage's decision rule, an open one was
#' flagged for review, and a cross marks no decision. "no value" marks an item
#' the stage reviewed without a statistic, and "not reviewed" one it did not
#' see. The last column says whether each item was carried, or names the
#' stages that held it back; when the names would not fit beside their item,
#' it gives the stages' numbers instead, and the panel titles are numbered to
#' match. Faint lines separate the constructs. The legend lists only what was
#' drawn, and no text is smaller than 8 points: text that does not fit is
#' wrapped rather than run off the figure.
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
  # Everything is measured and drawn at full size. layout() shrinks text to
  # 0.66 with three or more columns, which put the smaller labels near 6
  # points, so the size is set again after it. No text is below 8 points.
  graphics::par(cex = 1)
  smallest <- 8 / graphics::par("ps")
  small <- max(0.72, smallest)
  lab <- .item_labels(items, width_in = graphics::par("din")[1])
  key <- if (isTRUE(show_legend)) {
    .evidence_profile_key(ev, small, smallest)
  } else {
    list(lines = character(0))
  }
  key_top <- if (length(key$lines)) 0.6 + length(key$lines) else 0.3
  # A title is drawn once, above every panel, not on each one.
  dots <- list(...)
  main <- dots$main
  graphics::par(oma = c(0, lab$lines, key_top + if (length(main)) 1.6 else 0,
                        0.5),
                mar = c(4.1, 0.6, 1.9, 0.6))
  plan <- .evidence_profile_plan(x, n, smallest)
  held <- plan$verdict != "carried"
  graphics::par(mar = c(4.1, 0.6, plan$mar_top, 0.6))
  graphics::layout(matrix(seq_len(ns + 1L), 1),
                   widths = c(rep(1, ns), plan$share))
  graphics::par(cex = 1, cex.axis = max(0.85, smallest),
                cex.lab = max(0.9, smallest))

  for (k in seq_len(ns)) {
    s <- ev[ev$stage == stages[k], , drop = FALSE]
    stat <- s$statistic[1]
    xlim <- switch(stat, CVR = c(-1, 1), `target IOC` = c(-1, 1),
                   `highest IOC` = c(-1, 1), c(0, 1))
    .plot_with(list(x = NA, xlim = xlim, ylim = c(0.4, n + 0.6), xaxt = "n",
                    yaxt = "n", xlab = stat, ylab = ""), dots,
               protect = c("type", "xaxt", "yaxt", "axes", "main", "ylab"))
    .axis_bounded(1, at = .evidence_ticks(xlim))
    if (k == 1L) graphics::axis(2, at = y, labels = lab$labels, las = 1)
    if (length(breaks)) graphics::abline(h = y[breaks] - 0.5, col = "grey80")
    row <- match(s$item, items)
    crit <- unique(s$criterion[is.finite(s$criterion)])
    if (length(crit) == 1L) {
      graphics::abline(v = crit, lty = 2)
    } else if (length(crit) > 1L) {
      # A criterion that differs by item is marked on its own row.
      ok <- is.finite(s$criterion)
      graphics::segments(s$criterion[ok], y[row][ok] - 0.3, s$criterion[ok],
                         y[row][ok] + 0.3, lty = 2)
    }
    col <- .status_colour(s$status, apa)
    ok <- is.finite(s$lower) & is.finite(s$upper)
    if (any(ok)) {
      graphics::segments(s$lower[ok], y[row][ok], s$upper[ok], y[row][ok],
                         col = col[ok])
    }
    has <- is.finite(s$value)
    graphics::points(s$value[has], y[row][has],
                     pch = .status_pch(s$status[has]), col = col[has],
                     cex = 1.15)
    # A row is never left blank: an item the stage reviewed without a value
    # (no judge sorted it, say) says so, as does one it did not review.
    if (any(!has)) {
      graphics::text(mean(xlim), y[row][!has], "no value", cex = small,
                     col = "grey40", font = 3)
    }
    missing <- setdiff(items, s$item)
    if (length(missing)) {
      graphics::text(mean(xlim), y[match(missing, items)], "not reviewed",
                     cex = small, col = "grey40", font = 3)
    }
    .evidence_panel_title(plan$titles$lines[[k]], plan$titles$cex,
                          plan$title_step)
  }

  graphics::plot(NA, xlim = c(0, 1), ylim = c(0.4, n + 0.6), axes = FALSE,
                 xlab = "", ylab = "")
  .evidence_panel_title(plan$across$lines[[1]], plan$across$cex,
                        plan$title_step)
  if (length(breaks)) graphics::abline(h = y[breaks] - 0.5, col = "grey80")
  .evidence_draw_verdicts(plan$verdict, y, font = plan$font,
                          col = ifelse(held, pal$review, pal$met),
                          smallest = smallest)

  for (j in seq_along(key$lines)) {
    graphics::mtext(key$lines[j], side = 3, outer = TRUE,
                    line = 0.2 + length(key$lines) - j, cex = key$cex)
  }
  if (length(main)) {
    graphics::title(main = main, outer = TRUE, line = key_top + 0.2)
  }
  invisible(NULL)
}

# The profile's key, listing only what the panels draw: a symbol for each
# item with a value, a dashed line for each criterion, a bar for each
# interval. A filled symbol "met the criterion" only where its panel has one;
# construct ratings decide on their contrasts, not on the HTC shown. Fitted
# to the figure's width as the verdicts are: shrunk, to no less than
# `smallest`, then split over two lines. Returns the lines and their size.
.evidence_profile_key <- function(ev, cex, smallest) {
  value <- is.finite(ev$value)
  drawn <- ev$status[value]
  no_criterion <- !ev$stage %in% ev$stage[is.finite(ev$criterion)]
  level <- unique(ev$level[is.finite(ev$level)])
  parts <- c(
    if (any(drawn %in% "Supported")) {
      if (any(value & no_criterion & ev$status %in% "Supported")) {
        "Filled: met the stage's decision rule."
      } else {
        "Filled: met the criterion."
      }
    },
    if (any(drawn %in% "Review")) "Open: review.",
    if (any(!drawn %in% c("Supported", "Review"))) "Cross: no decision.",
    if (any(is.finite(ev$criterion))) "Dashed line: criterion.",
    if (any(is.finite(ev$lower) & is.finite(ev$upper))) {
      if (length(level) == 1L) {
        sprintf("Bar: %s%% interval.", format(100 * level))
      } else {
        "Bar: interval."
      }
    }
  )
  if (!length(parts)) return(list(lines = character(0), cex = cex))
  room <- graphics::par("din")[1] - 0.2
  wide <- function(s) graphics::strwidth(s, units = "inches", cex = cex)
  one <- paste(parts, collapse = "   ")
  if (wide(one) > room) cex <- max(smallest, cex * room / wide(one))
  if (wide(one) <= room || length(parts) < 2L) {
    return(list(lines = one, cex = cex))
  }
  half <- seq_len(ceiling(length(parts) / 2))
  list(lines = c(paste(parts[half], collapse = "   "),
                 paste(parts[-half], collapse = "   ")),
       cex = cex)
}

# Five ticks across a panel, or three when five labels would crowd it, so no
# label is silently dropped for overlapping its neighbor.
.evidence_ticks <- function(xlim) {
  at <- seq(xlim[1], xlim[2], length.out = 5)
  w <- graphics::strwidth(.tick_labels(at), cex = graphics::par("cex.axis"))
  gap <- graphics::strwidth("m", cex = graphics::par("cex.axis"))
  if (any((w[-1] + w[-5]) / 2 + gap > diff(at)[1])) at <- at[c(1, 3, 5)]
  at
}

# Plans the profile's text before layout(), in inches, so that nothing runs
# off the figure or into its neighbor. Called with the outer and figure
# margins set, and the top margin at one line of titles.
#
# * The verdict column is 0.75 of a stage panel, widened up to 1.25 when the
#   longest verdict needs it.
# * Verdicts name the stages that held an item back. When even wrapped at
#   8 points they would spill into the next row, they give the stages'
#   numbers instead, as the printed table does, and the panel titles are
#   numbered to match.
# * Titles are fitted to their panels and wrapped when they must be, and the
#   top margin grows to hold them.
.evidence_profile_plan <- function(x, n, smallest) {
  stages <- names(x$stages)
  ns <- length(stages)
  din <- graphics::par("din")
  omi <- graphics::par("omi")
  mai <- graphics::par("mai")
  inner <- din[1] - omi[2] - omi[4]
  column_in <- function(share) inner * share / (ns + share)
  # The verdicts start near the left of their plot region (x = 0.02 on an
  # axis extended 4% each side) and may run to the figure's edge.
  edge <- mai[4] + omi[4] - 0.05
  room_in <- function(share) {
    (column_in(share) - mai[2] - mai[4]) * 1.02 / 1.08 + edge
  }
  row_in <- (din[2] - omi[1] - omi[3] - mai[1] - mai[3]) / ((n + 0.2) * 1.08)
  start <- max(0.78, smallest)

  verdicts <- function(numbered) {
    verdict <- .evidence_verdicts(x, numbered = numbered)
    font <- ifelse(verdict != "carried", 2, 1)
    need <- max(0, mapply(function(v, f) {
      graphics::strwidth(v, units = "inches", cex = start, font = f)
    }, verdict, font))
    column <- (need - edge) * 1.08 / 1.02 + mai[2] + mai[4]
    share <- if (column >= inner) {
      1.25
    } else {
      min(1.25, max(0.75, column * ns / (inner - column)))
    }
    fit <- .evidence_fit_text(verdict, font, room_in(share), start, smallest,
                              units = "inches")
    step <- graphics::strheight("Mg", units = "inches", cex = fit$cex) * 1.3
    list(verdict = verdict, font = font, share = share, numbered = numbered,
         fits = max(0L, lengths(fit$lines)) * step <= 0.9 * row_in)
  }
  plan <- verdicts(FALSE)
  if (!plan$fits) plan <- verdicts(TRUE)

  titles <- if (plan$numbered) paste0(seq_len(ns), ". ", stages) else stages
  panel <- .evidence_fit_text(titles, 2, inner / (ns + plan$share) - 0.05, 0.8,
                              smallest, units = "inches")
  across <- .evidence_fit_text("Across stages", 2,
                               column_in(plan$share) - 0.05, 0.8, smallest,
                               units = "inches")
  # Title lines are stacked upward from the usual line, a little more than
  # their own height apart.
  step <- 1.15 * max(panel$cex, across$cex)
  extra <- max(lengths(panel$lines), lengths(across$lines)) - 1L
  c(plan, list(titles = panel, across = across, title_step = step,
               mar_top = graphics::par("mar")[3] + extra * step))
}

# A title above a panel, line by line from the bottom up.
.evidence_panel_title <- function(lines, cex, step) {
  k <- length(lines)
  for (j in seq_len(k)) {
    graphics::mtext(lines[j], side = 3, line = 0.5 + (k - j) * step, cex = cex,
                    font = 2)
  }
}

# The verdicts of the last column, each fitted between its start and the
# right edge of the figure.
.evidence_draw_verdicts <- function(verdict, y, font, col, smallest) {
  usr <- graphics::par("usr")
  per_inch <- diff(usr[1:2]) / graphics::par("pin")[1]
  start <- 0.02
  # From the start to the device's edge, less a small pad.
  edge_in <- (usr[2] - start) / per_inch + graphics::par("mai")[4] +
    graphics::par("omi")[4] - 0.05
  fit <- .evidence_fit_text(verdict, font, edge_in * per_inch,
                            max(0.78, smallest), smallest)
  step <- graphics::strheight("Mg", cex = fit$cex) * 1.3
  for (i in seq_along(verdict)) {
    lines <- fit$lines[[i]]
    k <- length(lines)
    at <- y[i] + (rev(seq_len(k)) - (k + 1) / 2) * step
    graphics::text(start, at, lines, adj = 0, cex = fit$cex, font = font[i],
                   col = col[i], xpd = NA)
  }
  invisible(NULL)
}

# Fits text into `room` (in `units`): one size for all of it, shrunk from
# `cex` to no less than `smallest` (8 points), then wrapped at spaces where a
# line is still too wide. A single word wider than the room, such as a long
# stage name with no spaces, is cut short rather than run off the figure.
# Returns the size and the lines of each text.
.evidence_fit_text <- function(text, font, room, cex, smallest,
                               units = "user") {
  font <- rep_len(font, length(text))
  width <- function(s, f) {
    graphics::strwidth(s, units = units, cex = cex, font = f)
  }
  widest <- max(0, mapply(width, text, font))
  if (widest > room) cex <- max(smallest, cex * room / widest)

  wrap <- function(txt, f) {
    words <- strsplit(txt, " ", fixed = TRUE)[[1]]
    if (!length(words)) return(txt)
    lines <- character(0)
    current <- ""
    for (w in words) {
      joined <- if (nzchar(current)) paste(current, w) else w
      if (!nzchar(current) || width(joined, f) <= room) {
        current <- joined
      } else {
        lines <- c(lines, current)
        current <- w
      }
    }
    lines <- c(lines, current)
    vapply(lines, function(l) {
      if (width(l, f) <= room) return(l)
      while (nchar(l) > 1L && width(paste0(l, "..."), f) > room) {
        l <- substr(l, 1L, nchar(l) - 1L)
      }
      paste0(l, "...")
    }, character(1), USE.NAMES = FALSE)
  }
  list(cex = cex, lines = mapply(wrap, text, font, SIMPLIFY = FALSE,
                                 USE.NAMES = FALSE))
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
    if (!length(f$held)) {
      side <- c(side, if (isFALSE(f$decided)) {
        "none: no decision rule"
      } else {
        "none"
      })
    }
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

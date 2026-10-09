# Shared pieces of the plot methods, so every figure follows the same rules:
#
# * no empty title band: the top margin is small unless a `main` title is
#   passed through `...`;
# * axes for statistics that cannot exceed 1 are labeled as APA prints them
#   (.25, .50, not 0.25, 0.50);
# * a legend lists only what the figure draws, and sits in headroom reserved
#   above the data rather than on top of it, in as many rows as the plot's
#   width needs;
# * reference lines stop below that headroom;
# * a vertical axis title too long for the figure gives way to the index's
#   name, which the legend's heading defines;
# * an axis of counts, such as experts or judges, ticks whole numbers only;
# * item names get the margin they need, shortened in the middle when long;
# * the tick labels of a vertical statistic axis are set horizontally, so a
#   short figure drops none of them.

# Narrows the top margin unless the caller asked for a title. Returns the old
# settings for on.exit(graphics::par(op)).
.plot_margins <- function(dots) {
  mar <- graphics::par("mar")
  if (!"main" %in% names(dots)) mar[3] <- 1.1
  mar[4] <- min(mar[4], 1.1)
  graphics::par(mar = mar)
}

# Draws a figure's frame from the method's own arguments, with any named
# argument the caller passed in `...` taking the place of the method's, so
# `xlab`, `xlim` or `main` never collide with it. Arguments the figure's
# encoding depends on (`protect`: the frame type, the axes the method draws
# itself, and on a map the decision symbols its legend keys) are kept as the
# method set them, and a NULL from the caller leaves the method's value.
# Unnamed arguments cannot be matched to anything and are dropped with a
# warning.
.plot_with <- function(args, dots,
                       protect = c("type", "xaxt", "yaxt", "axes"),
                       draw = graphics::plot) {
  nm <- names(dots)
  if (is.null(nm)) nm <- rep("", length(dots))
  if (any(!nzchar(nm))) {
    warning("Unnamed arguments to plot() are ignored; name them, as in ",
            "xlab = \"...\".", call. = FALSE)
  }
  named <- dots[nzchar(nm)]
  named <- named[!names(named) %in% protect &
                   !vapply(named, is.null, logical(1))]
  args[names(named)] <- named
  do.call(draw, args)
}

# Item labels for the left margin of a horizontal figure, and the margin they
# need, in lines. The labels are measured on the open device. A label wider
# than 40% of the width left for labels (`width_in` less `reserve_in`, in
# inches) is shortened in the middle with "...", keeping its start and end so
# that names sharing an opening stay apart; if shortened labels would still
# coincide, a number is added.
.item_labels <- function(items, width_in = graphics::par("fin")[1],
                         reserve_in = 0, base = 1.2) {
  items <- as.character(items)
  csi <- graphics::par("csi")
  cap_in <- max(0.4 * (width_in - reserve_in), 4 * csi)
  wide <- function(x) graphics::strwidth(x, units = "inches")
  out <- items
  for (i in which(wide(items) > cap_in)) {
    full <- items[i]
    keep <- nchar(full)
    repeat {
      keep <- keep - 1L
      head <- ceiling(keep / 2)
      label <- paste0(substr(full, 1L, head), "...",
                      substr(full, nchar(full) - (keep - head) + 1L, nchar(full)))
      if (wide(label) <= cap_in || keep <= 4L) break
    }
    out[i] <- label
  }
  dup <- duplicated(out) | duplicated(out, fromLast = TRUE)
  if (any(dup)) out[dup] <- paste0(out[dup], " (", which(dup), ")")
  list(labels = out, lines = base + max(wide(out), 0) / csi)
}

# Item names down the left of a horizontal figure: shortened by
# .item_labels(), with the left margin widened to hold them. Called before the
# frame is drawn; returns the labels to draw.
.item_axis_left <- function(items) {
  lab <- .item_labels(items, width_in = graphics::par("din")[1])
  mar <- graphics::par("mar")
  graphics::par(mar = c(mar[1], max(mar[2], lab$lines + 0.2), mar[3:4]))
  lab$labels
}

# Item names set upright under a vertical figure (axis(1, las = 2)):
# shortened by .item_labels() to 40% of the figure's height less an inch kept
# for the data, with the bottom margin widened to hold them and the axis
# title moved below them. Called before the frame is drawn; returns the
# labels and the title's line.
.item_axis_below <- function(items) {
  lab <- .item_labels(items, width_in = graphics::par("din")[2],
                      reserve_in = 1)
  mar <- graphics::par("mar")
  line <- max(graphics::par("mgp")[1], lab$lines + 0.2)
  graphics::par(mar = c(max(mar[1], line + 1.2), mar[-1]))
  list(labels = lab$labels, line = line)
}

# Tick labels in APA style for a bounded statistic: 0, .25, .50, .75, 1.00.
.tick_labels <- function(at, digits = 2) {
  out <- formatC(at, format = "f", digits = digits)
  out <- sub("^(-?)0\\.", "\\1.", out)
  out[abs(at) < 1e-12] <- "0"
  out
}

# On a vertical axis the labels are set horizontally unless the caller says
# otherwise: set along the axis, each needs its width between ticks, and a
# short figure under a tall key would drop some of them.
.axis_bounded <- function(side, at, digits = 2, ...) {
  args <- list(side, at = at, labels = .tick_labels(at, digits), ...)
  if (side %in% c(2, 4) && is.null(args$las)) args$las <- 1
  do.call(graphics::axis, args)
}

# One plotting symbol per decision: met (filled), review (open), no decision
# (cross). Words are matched through the shared statuses.
.decision_pch <- function(recommendation) {
  status <- .workflow_status_from_recommendation(recommendation)
  ifelse(status %in% "Supported", 19L, ifelse(status %in% "Review", 1L, 4L))
}

# Legend entries for the decisions actually drawn, in a fixed order.
.decision_legend <- function(recommendation) {
  words <- unique(as.character(recommendation[!is.na(recommendation)]))
  pch <- .decision_pch(words)
  ord <- order(match(pch, c(19L, 1L, 4L)))
  list(legend = words[ord], pch = pch[ord])
}

# How a legend in the headroom at the top of the plot fits the plot's width:
# one row at the usual size when it fits, else two rows, else three, and so
# on up to a single column, and only then smaller type, never below 8 points,
# so the text keeps its size wherever rows can hold it. Rows read across in
# the order given. NA in `pch` or `lty` marks "no symbol" or "no line";
# `title` is a heading above the entries. Widths follow legend()'s own
# arithmetic in inches on the open device, so a figure can size its headroom
# (.legend_room()) before its frame is drawn.
.legend_fit <- function(legend, pch = NA, lty = NA, col = "black", title = NULL,
                        width_in = graphics::par("pin")[1], cex = 0.72) {
  n <- length(legend)
  # Nothing drawn, nothing to explain (for example, every value is missing).
  if (!n) return(NULL)
  pch <- rep_len(pch, n)
  lty <- rep_len(lty, n)
  col <- rep_len(col, n)
  lines <- any(!is.na(lty))
  layout <- function(rows, cex) {
    ncol <- ceiling(n / rows)
    rows <- ceiling(n / ncol)
    # legend() fills its columns first; this order makes the rows read
    # across. The slots after the last entry are left blank, so a short last
    # row moves no entry into another column.
    blank <- rows * ncol - n
    ord <- as.vector(matrix(seq_len(rows * ncol), rows, byrow = TRUE))
    labels <- c(legend, rep("", blank))[ord]
    # With lines in the key, legend() starts each line a little before its
    # column, which runs the widest label of the column before into it, so
    # every column but the last is padded.
    if (lines) {
      inner <- ceiling(seq_along(labels) / rows) < ncol
      labels[inner] <- paste0(labels[inner], "     ")
    }
    # Each column is as wide as the widest label, plus the symbol and its gap
    # (x.intersp = 0.7) and, with lines, the segment (seg.len = 1.6) less the
    # 0.7 character a merged symbol overlaps.
    xchar <- cex * graphics::par("cex") * graphics::par("cin")[1]
    ychar <- cex * graphics::par("cex") * graphics::par("cin")[2]
    text <- max(graphics::strwidth(labels, units = "inches", cex = cex))
    column <- text + 1.7 * xchar + if (lines) 0.9 * xchar else 0
    width <- ncol * column + 0.5 * xchar
    if (!is.null(title)) {
      heading <- graphics::strwidth(title, units = "inches", cex = cex)
      width <- max(width, heading + 0.5 * xchar)
    }
    pad <- function(v) c(v, rep(NA, blank))[ord]
    list(legend = labels, pch = pad(pch), lty = pad(lty), col = pad(col),
         title = title, ncol = ncol, rows = rows, cex = cex, width = width,
         height = (rows + 1 + !is.null(title)) * ychar)
  }
  # A tenth of an inch spare absorbs the difference between measured and
  # drawn text on bitmap devices.
  room <- width_in - 0.1
  for (rows in seq_len(n)) {
    fit <- layout(rows, cex)
    if (fit$width <= room) return(fit)
  }
  # Too wide even in one column: that column in type shrunk to fit, to no
  # less than 8 points. Some devices set text in whole points, so the width
  # is checked again.
  smallest <- min(cex, 8 / (graphics::par("ps") * graphics::par("cex")))
  fit <- layout(n, max(smallest, cex * room / fit$width))
  while (fit$width > room && fit$cex > smallest) {
    fit <- layout(n, max(smallest, 0.95 * fit$cex))
  }
  fit
}

# Draws a legend laid out by .legend_fit() at the top of the plot.
.legend_draw <- function(fit) {
  if (is.null(fit)) return(invisible(NULL))
  args <- list("top", legend = fit$legend, pch = fit$pch, col = fit$col,
               bty = "n", ncol = fit$ncol, cex = fit$cex, x.intersp = 0.7,
               seg.len = 1.6, title = fit$title)
  # legend() cannot draw a key whose line types are all missing.
  if (any(!is.na(fit$lty))) args$lty <- fit$lty
  do.call(graphics::legend, args)
}

# A legend in the headroom at the top of the plot, laid out to fit the plot's
# width. A figure that sizes its headroom for the key lays it out with
# .legend_fit() and draws it with .legend_draw() instead.
.legend_top <- function(legend, pch = NA, lty = NA, col = "black",
                        title = NULL) {
  invisible(.legend_draw(.legend_fit(legend, pch, lty, col, title)))
}

# The top of a frame's y range that keeps a legend laid out by .legend_fit()
# clear of data reaching `hi`, and never lower than `top`. The frame runs
# from `lo` with R's usual 4% padding at each end over `height_in` inches;
# `above_in` is what the data draw above `hi`, such as half a symbol or a
# label set above a point.
.legend_room <- function(lo, hi, top, fit, above_in = 0.05,
                         height_in = graphics::par("pin")[2]) {
  if (is.null(fit)) return(top)
  share <- 1.08 * (fit$height + above_in) / height_in
  # A key taller than most of the plot cannot be cleared on this device;
  # the data then keep at least a third of the height.
  max(top, lo + (hi - lo) / max(1.04 - share, 0.35))
}

# The title of the vertical axis: the full label where it fits the figure's
# height, centered on the plot, and the index's name alone where it does
# not, for the key to define.
.ylab_fit <- function(full, short) {
  room <- graphics::par("pin")[2] +
    2 * min(graphics::par("mai")[c(1L, 3L)]) - 0.1
  need <- graphics::strwidth(full, units = "inches",
                             cex = graphics::par("cex.lab"))
  if (need <= room) full else short
}

# Ticks for an axis of counts, such as experts or judges: whole numbers only,
# so a narrow range never shows 3.2 experts. Returns the ticks, invisibly.
.axis_counts <- function(side) {
  at <- graphics::axTicks(side)
  at <- at[abs(at - round(at)) < 1e-8]
  if (!length(at)) {
    usr <- graphics::par("usr")[if (side %in% c(1, 3)) 1:2 else 3:4]
    whole <- ceiling(min(usr)):floor(max(usr))
    at <- whole[whole >= min(usr) & whole <= max(usr)]
  }
  graphics::axis(side, at = at)
  invisible(at)
}

# A vertical reference line that stops at `top`, below the legend's headroom.
.vline_below <- function(x, bottom, top, lty = 3) {
  graphics::segments(x, bottom, x, top, lty = lty)
}

# A horizontal reference line across the plot width, at height `y`.
.hline <- function(y, lty = 3) {
  graphics::abline(h = y, lty = lty)
}

# Colors for the displays that take `apa`. With apa = TRUE everything is
# black, white, and gray, as an APA figure is printed. With apa = FALSE, teal
# marks evidence that met its criterion and brown evidence under review, from
# the colorblind-safe brown-teal diverging scheme. The plotting symbol still
# carries the decision in both, so no reading depends on color alone.
.evidence_colours <- function(apa) {
  if (isTRUE(apa)) {
    list(met = "black", review = "black", none = "grey40",
         stage = "white", held = "grey93", final = "grey85", border = "grey20")
  } else {
    list(met = "#01665E", review = "#8C510A", none = "grey40",
         stage = "white", held = "#F6E8C3", final = "#C7EAE5", border = "grey20")
  }
}

# The color of each decision, from its shared status.
.status_colour <- function(status, apa) {
  pal <- .evidence_colours(apa)
  ifelse(status %in% "Supported", pal$met,
         ifelse(status %in% "Review", pal$review, pal$none))
}

# One plotting symbol per shared status: met (filled), review (open), no
# decision (cross), as .decision_pch() draws from the workflow's own words.
.status_pch <- function(status) {
  ifelse(status %in% "Supported", 19L, ifelse(status %in% "Review", 1L, 4L))
}

# One fill per rating category, lowest first. In gray, darker means a higher
# rating. In color, ratings below the cut are brown and ratings at or above it
# teal, each deeper the further it lies from the cut.
.rating_fills <- function(k, n_below, apa) {
  if (isTRUE(apa)) return(grDevices::grey(seq(0.93, 0.22, length.out = k)))
  n_above <- k - n_below
  below <- if (n_below > 0L) {
    grDevices::colorRampPalette(c("#A6611A", "#DFC27D"))(max(n_below, 2L))
  }
  above <- if (n_above > 0L) {
    grDevices::colorRampPalette(c("#80CDC1", "#018571"))(max(n_above, 2L))
  }
  # With one category on a side, use the shade nearest the cut.
  if (n_below == 1L) below <- below[2L]
  if (n_above == 1L) above <- above[1L]
  c(below, above)
}

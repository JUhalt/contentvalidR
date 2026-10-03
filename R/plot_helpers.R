# Shared pieces of the plot methods, so every figure follows the same rules:
#
# * no empty title band: the top margin is small unless a `main` title is
#   passed through `...`;
# * axes for statistics that cannot exceed 1 are labeled as APA prints them
#   (.25, .50, not 0.25, 0.50);
# * a legend lists only what the figure draws, and sits in headroom reserved
#   above the data rather than on top of it;
# * reference lines stop below that headroom.

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
# `xlab`, `xlim` or `main` never collide with it.
.plot_with <- function(args, dots) {
  named <- if (is.null(names(dots))) list() else dots[nzchar(names(dots))]
  args[names(named)] <- named
  do.call(graphics::plot, args)
}

# Item labels for the left margin of a horizontal figure, and the margin they
# need, in lines. A label is shortened with "..." when the full one would take
# more than 40% of the width (`width_in`, in inches), so a long item name never
# leaves the plot region too small to draw.
.item_labels <- function(items, width_in = graphics::par("fin")[1],
                         base = 1.2, per_char = 0.62) {
  items <- as.character(items)
  cap <- 0.4 * width_in / graphics::par("csi")
  max_chars <- max(4L, as.integer(floor((cap - base) / per_char)))
  long <- nchar(items) > max_chars
  items[long] <- paste0(substr(items[long], 1L, max_chars - 3L), "...")
  list(labels = items, lines = base + per_char * max(nchar(items), 1L))
}

# Tick labels in APA style for a bounded statistic: 0, .25, .50, .75, 1.00.
.tick_labels <- function(at, digits = 2) {
  out <- formatC(at, format = "f", digits = digits)
  out <- sub("^(-?)0\\.", "\\1.", out)
  out[abs(at) < 1e-12] <- "0"
  out
}

.axis_bounded <- function(side, at, digits = 2, ...) {
  graphics::axis(side, at = at, labels = .tick_labels(at, digits), ...)
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

# A horizontal legend in the headroom at the top of the plot. `entries` is a
# list of legend(), pch, lty values; NA marks "no symbol" or "no line".
.legend_top <- function(legend, pch = NA, lty = NA, col = "black", ncol = NULL) {
  n <- length(legend)
  # Nothing drawn, nothing to explain (for example, every value is missing).
  if (!n) return(invisible(NULL))
  args <- list("top", legend = legend, pch = rep_len(pch, n),
               col = rep_len(col, n), bty = "n", horiz = is.null(ncol),
               ncol = if (is.null(ncol)) 1 else ncol, cex = 0.72,
               x.intersp = 0.7, seg.len = 1.6)
  # legend() cannot draw a key whose line types are all missing. When lines
  # and symbols are mixed, a horizontal key underestimates the room a line
  # needs and runs the label before it into the line, so that label is padded.
  lty <- rep_len(lty, n)
  if (any(!is.na(lty))) {
    args$lty <- lty
    if (is.null(ncol) && n > 1L) {
      before_line <- c(is.na(lty[-n]) & !is.na(lty[-1L]), FALSE)
      args$legend[before_line] <- paste0(legend[before_line], "     ")
    }
  }
  do.call(graphics::legend, args)
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

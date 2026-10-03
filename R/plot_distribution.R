# The full distribution of a panel's ratings, as diverging stacked bars
# (Heiberger & Robbins, 2014), shared by plot(<expert fit>, type =
# "distribution") and plot(<Delphi fit>, type = "distribution").
#
# Each bar splits at the cut the decision rule uses: ratings below it extend
# left of zero and ratings at or above it extend right, so the right-hand
# length is exactly the share the rule counts (the I-CVI, or the share
# agreeing). The number printed beside the bar is that share, and the symbol
# is the decision the fit made, taken from the fit rather than recomputed.

# The share of ratings in each scale category. A rating between two scale
# points is drawn with the point below it, and never across the cut from where
# the rule counts it, so the categories at or above the cut sum to exactly
# mean(x >= cut), the share the fit used.
.rating_shares <- function(x, cats, cut) {
  k <- length(cats)
  bin <- pmin(pmax(as.integer(floor(x - cats[1] + 1e-9)) + 1L, 1L), k)
  crossed <- x >= cut & cats[bin] < cut
  bin[crossed] <- min(which(cats >= cut))
  # And the mirror: a rating a hair under the cut stays on the lower side.
  under <- x < cut & cats[bin] >= cut
  bin[under] <- max(which(cats < cut))
  tabulate(bin, k) / length(x)
}

# `rounds`: a named list of rating matrices (raters in rows, items in
# columns), one per round, drawn as adjacent bars for each item.
# `status`: a list parallel to `rounds` of named character vectors, item to
# shared status, for the symbol beside each bar.
.plot_rating_distribution <- function(rounds, items, lo, hi, cut, criterion,
                                      status, value_label, axis_label, labels, apa,
                                      show_legend, ...) {
  k <- as.integer(hi - lo + 1)
  cats <- seq(lo, hi)
  if (is.null(labels)) labels <- paste("Rated", cats)
  if (!is.character(labels) || length(labels) != k || anyNA(labels)) {
    stop(sprintf("`labels` must be %d labels, one for each rating from %s to %s.",
                 k, format(lo), format(hi)), call. = FALSE)
  }
  n_below <- sum(cats < cut)
  fills <- .rating_fills(k, n_below, apa)
  border <- if (isTRUE(apa)) "grey35" else "white"
  pal <- .evidence_colours(apa)

  n <- length(items)
  nr <- length(rounds)
  step <- nr + 0.6
  ypos <- function(i, r) (n - i) * step + (nr - r) + 1
  top <- n * step + 0.2
  round_names <- names(rounds)

  lab <- .item_labels(items)
  mar <- graphics::par("mar")
  mar[2] <- lab$lines +
    if (nr > 1L) 0.55 * max(nchar(round_names)) + 0.6 else 0
  mar[3] <- if (isTRUE(show_legend)) 3.4 else 1.1
  mar[4] <- 4.2
  op <- graphics::par(mar = mar)
  on.exit(graphics::par(op), add = TRUE)

  .plot_with(list(x = NA, xlim = c(-1, 1), ylim = c(0.4, top + 0.6), xaxt = "n",
                  yaxt = "n", xlab = axis_label, ylab = "", bty = "n"), list(...))
  at <- seq(-1, 1, 0.25)
  graphics::axis(1, at = at, labels = .tick_labels(abs(at)))
  graphics::segments(0, 0.4, 0, top, col = "grey30")

  drawn <- character(0)
  for (i in seq_len(n)) {
    for (r in seq_len(nr)) {
      yc <- ypos(i, r)
      m <- rounds[[r]]
      x <- if (items[i] %in% colnames(m)) m[, items[i]] else numeric(0)
      x <- x[!is.na(x)]
      if (nr > 1L) {
        graphics::axis(2, at = yc, labels = round_names[r], las = 1,
                       tick = FALSE, line = -0.6, cex.axis = 0.7,
                       col.axis = "grey30")
      }
      if (!length(x)) {
        graphics::text(0.03, yc, "not rated", adj = 0, cex = 0.7,
                       col = "grey40", font = 3)
        next
      }
      p <- .rating_shares(x, cats, cut)
      # Nearest the cut first, so the extremes sit at the outer ends.
      left <- 0
      for (j in rev(which(cats < cut))) {
        graphics::rect(left - p[j], yc - 0.38, left, yc + 0.38,
                       col = fills[j], border = border, lwd = 0.5)
        left <- left - p[j]
      }
      right <- 0
      for (j in which(cats >= cut)) {
        graphics::rect(right, yc - 0.38, right + p[j], yc + 0.38,
                       col = fills[j], border = border, lwd = 0.5)
        right <- right + p[j]
      }
      st <- status[[r]][items[i]]
      if (is.null(st) || length(st) == 0L) st <- NA_character_
      drawn <- c(drawn, st)
      graphics::points(1.06, yc, pch = .status_pch(st), cex = 0.85,
                       col = .status_colour(st, apa), xpd = NA)
      graphics::text(1.11, yc, .fmt(right), adj = 0, cex = 0.75, xpd = NA)
    }
    mid <- mean(c(ypos(i, 1), ypos(i, nr)))
    graphics::axis(2, at = mid, labels = lab$labels[i], las = 1, tick = FALSE,
                   line = if (nr > 1L) 0.55 * max(nchar(round_names)) - 0.2 else -0.4)
  }
  # Drawn over the bars, so a bar that stops short of it can be seen to.
  if (length(criterion) == 1L && is.finite(criterion)) {
    graphics::segments(criterion, 0.4, criterion, top, lty = 2, lwd = 1.2)
  }
  graphics::text(1.06, top + 0.35, value_label, adj = 0, cex = 0.75, font = 2,
                 xpd = NA)

  if (isTRUE(show_legend)) {
    # Two rows in the top margin: the rating categories, then what the lines
    # and symbols mean. Only what the figure draws is listed.
    to_user <- function(inch) {
      graphics::grconvertY(inch, "inches", "user")
    }
    top_in <- graphics::grconvertY(graphics::par("usr")[4], "user", "inches")
    row <- graphics::par("csi") * 0.95
    graphics::legend(x = 0, y = to_user(top_in + 2.05 * row), xjust = 0.5,
                     yjust = 0.5, legend = labels, fill = fills,
                     border = border, horiz = TRUE, bty = "n", cex = 0.72,
                     x.intersp = 0.5, xpd = NA)
    has_crit <- length(criterion) == 1L && is.finite(criterion)
    # Anything other than met or review draws a cross: no decision was made.
    shown <- ifelse(drawn %in% c("Supported", "Review"), drawn, "None")
    sts <- intersect(c("Supported", "Review", "None"), unique(shown))
    words <- c(Supported = "Met the criterion", Review = "Review",
               None = "No decision")
    lab2 <- c(if (has_crit) "Criterion", unname(words[sts]))
    args <- list(x = 0, y = to_user(top_in + 0.95 * row), xjust = 0.5,
                 yjust = 0.5, legend = lab2,
                 pch = c(if (has_crit) NA, .status_pch(sts)),
                 col = c(if (has_crit) "black", .status_colour(sts, apa)),
                 horiz = TRUE, bty = "n", cex = 0.72, x.intersp = 0.6,
                 seg.len = 1.6, xpd = NA)
    # legend() cannot draw a key whose line types are all missing, so the line
    # type is passed only when the criterion line is drawn.
    if (has_crit) args$lty <- c(2, rep(NA, length(sts)))
    do.call(graphics::legend, args)
  }
  invisible(NULL)
}

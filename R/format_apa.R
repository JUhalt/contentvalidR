# Printed numbers follow the APA Publication Manual (7th ed., Section 6.36).
#
# * A statistic that cannot exceed 1 in absolute value is printed without a
#   leading zero: proportions, correlations, agreement coefficients, and p
#   values (.83, -.43). One that can exceed 1 keeps it: F, chi-square, mean
#   ratings, severities, logits (0.57).
# * Two decimals by default, which Section 6.36 recommends for proportions,
#   correlations, and test statistics.
# * p values are exact to three decimals, and below .001 are printed as < .001,
#   never as 0.000.
# * Intervals are printed as [LL, UL], with the level in the column heading
#   (Section 6.43).
#
# Only what is printed is formatted. Results objects keep full precision.

.fmt <- function(x, digits = 2, bounded = TRUE) {
  x <- as.numeric(x)
  out <- formatC(x, format = "f", digits = digits)
  if (bounded) out <- sub("^(-?)0\\.", "\\1.", out)
  # A value that rounds to zero keeps no sign: -.00 reads as a real negative.
  zero <- formatC(0, format = "f", digits = digits)
  if (bounded) zero <- sub("^0\\.", ".", zero)
  out[out == paste0("-", zero)] <- zero
  out[is.na(x)] <- "NA"
  out
}

.fmt_p <- function(p) {
  p <- as.numeric(p)
  out <- .fmt(p, digits = 3, bounded = TRUE)
  out[!is.na(p) & p < .001] <- "< .001"
  out
}

# An alpha level keeps the digits it was given, with at least two: .05, .10,
# .025, .001. Rounding to two decimals would print .001 as .00. A computed
# level such as .05 / 3 is shown to three significant digits (.0167). The
# text never depends on the session's `digits` or `OutDec` options, because
# it also goes into the handoff.
.fmt_alpha <- function(alpha) {
  alpha <- as.numeric(alpha)
  out <- vapply(alpha, function(a) {
    if (is.na(a)) return("NA")
    a <- signif(a, 3)
    given <- format(a, digits = 15, scientific = FALSE, drop0trailing = TRUE,
                    decimal.mark = ".")
    decimals <- if (grepl(".", given, fixed = TRUE)) {
      nchar(sub("^[^.]*\\.", "", given))
    } else {
      0L
    }
    formatC(a, format = "f", digits = max(2L, decimals), decimal.mark = ".")
  }, character(1))
  sub("^0\\.", ".", out)
}

# "p = .021", or "p < .001" when it is that small.
.p_phrase <- function(p) {
  txt <- .fmt_p(p)
  ifelse(startsWith(txt, "<"), paste("p", txt), paste("p =", txt))
}

.fmt_ci <- function(lo, hi, digits = 2, bounded = TRUE) {
  out <- sprintf("[%s, %s]", .fmt(lo, digits, bounded), .fmt(hi, digits, bounded))
  out[is.na(lo) | is.na(hi)] <- "NA"
  out
}

# The heading for an interval column, such as "95% CI".
.ci_label <- function(alpha) {
  paste0(format(100 * (1 - alpha)), "% CI")
}

# Prints a table of already-formatted text. Every heading is kept exactly as
# given, so two intervals can both be labeled "95% CI", each after its own
# estimate.
.print_table <- function(tab) {
  tab <- as.data.frame(tab, stringsAsFactors = FALSE, check.names = FALSE)
  print(tab, row.names = FALSE, right = TRUE)
  invisible(tab)
}

# Wraps a sentence or paragraph to the console, never wider than 80 columns.
.say <- function(..., indent = 0L, exdent = indent) {
  width <- min(getOption("width", 80L), 80L) - 2L
  cat(strwrap(paste(...), width = width, indent = indent, exdent = exdent),
      sep = "\n")
  invisible(NULL)
}

# A count with its noun in the right number: "1 item", "3 items".
.n_noun <- function(n, noun, plural = paste0(noun, "s")) {
  paste(n, ifelse(n == 1, noun, plural))
}

# The two degrees of freedom of an F test as APA writes them: whole numbers
# without decimals, "F(2, 15)", and corrected ones with them, "F(1.89,
# 20.84)". The pair is decided together, so a correction that happens to
# leave one of the two whole still prints both to the same precision:
# "F(1.39, 32.00)", never "F(1.39, 32)".
.fmt_df <- function(df1, df2, digits = 2) {
  is_whole <- function(v) is.na(v) | abs(v - round(v)) < 1e-8
  whole <- is_whole(df1) & is_whole(df2)
  one <- function(v) {
    out <- .fmt(v, digits, bounded = FALSE)
    w <- whole & !is.na(v)
    out[w] <- format(round(v[w]), trim = TRUE, scientific = FALSE)
    out
  }
  paste0(one(df1), ", ", one(df2))
}

# An F test as text: "F(2, 15) = 4.21". `Inf` is written without padding.
.fmt_f_test <- function(f, df1, df2, digits = 2) {
  value <- ifelse(is.infinite(f), "Inf", .fmt(f, digits, bounded = FALSE))
  sprintf("F(%s) = %s", .fmt_df(df1, df2, digits), value)
}

# Scale points as text, written alike: "1" and "4", or "0.333" and "1.333" on
# a scale with fractional points, never seven digits on one and six on another.
.fmt_scale <- function(x) {
  format(x, digits = 3, drop0trailing = TRUE, trim = TRUE)
}

# "4 or fewer experts": a panel too small for any count to reach alpha stays
# too small at every smaller size.
.or_fewer <- function(n, noun) {
  if (n <= 1L) paste("1", noun) else paste0(n, " or fewer ", noun, "s")
}

# Prints each distinct text once, led by every label it applies to, so an
# explanation shared by five items is read once rather than five times.
.say_grouped <- function(labels, texts, indent = 0L, exdent = indent + 2L) {
  keep <- !is.na(texts) & nzchar(texts)
  for (txt in unique(texts[keep])) {
    .say(paste0(paste(labels[keep & texts == txt], collapse = ", "), ": ", txt),
         indent = indent, exdent = exdent)
  }
  invisible(NULL)
}

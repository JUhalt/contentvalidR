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

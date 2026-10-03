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
#
# The style is shared with nomologR (JUhalt/nomologR#144): rounding half away
# from zero, so .625 prints .63; "--" for a missing value; "p > .999" rather
# than 1.000.

# The missing marker in printed numbers and tables.
.missing_mark <- "--"

# Rounds half away from zero for display, so exact ties do not round to even
# (R's own rule, under which 5 of 8 prints .62 and 3 of 8 prints .38). The
# 1e-9 absorbs the binary error that leaves .625 a hair below its tie.
.half_up <- function(x, digits) {
  s <- 10^digits
  out <- sign(x) * floor(abs(x) * s + 0.5 + 1e-9) / s
  out[!is.na(out) & out == 0] <- 0
  out
}

.fmt <- function(x, digits = 2, bounded = TRUE) {
  x <- as.numeric(x)
  finite <- is.finite(x)
  x[finite] <- .half_up(x[finite], digits)
  out <- formatC(x, format = "f", digits = digits)
  if (bounded) out <- sub("^(-?)0\\.", "\\1.", out)
  # A value that rounds to zero keeps no sign: -.00 reads as a real negative.
  zero <- formatC(0, format = "f", digits = digits)
  if (bounded) zero <- sub("^0\\.", ".", zero)
  out[out == paste0("-", zero)] <- zero
  out[is.na(x)] <- .missing_mark
  out
}

# A p value to three decimals, "< .001" below that, and "> .999" where three
# decimals would print 1.000 (APA 7, Section 6.36).
.fmt_p <- function(p) {
  p <- as.numeric(p)
  out <- .fmt(p, digits = 3, bounded = TRUE)
  out[!is.na(p) & p < .001] <- "< .001"
  out[!is.na(p) & out == "1.000"] <- "> .999"
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
    if (is.na(a)) return(.missing_mark)
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

# "p = .021", "p < .001" when it is that small, or "p > .999".
.p_phrase <- function(p) {
  txt <- .fmt_p(p)
  ifelse(startsWith(txt, "<") | startsWith(txt, ">"), paste("p", txt),
         paste("p =", txt))
}

.fmt_ci <- function(lo, hi, digits = 2, bounded = TRUE) {
  out <- sprintf("[%s, %s]", .fmt(lo, digits, bounded), .fmt(hi, digits, bounded))
  out[is.na(lo) | is.na(hi)] <- .missing_mark
  out
}

# A value printed beside its cut. Two decimals can make a value just below the
# cut print as the cut itself ("Phi = .80, below the .80"), so such a value
# gets a third decimal.
.fmt_beside_cut <- function(x, cut, digits = 2L) {
  if (!is.na(x) && x < cut && .fmt(x, digits) == .fmt(cut, digits)) {
    return(.fmt(x, digits + 1L))
  }
  .fmt(x, digits)
}

# The heading for an interval column, such as "95% CI".
.ci_label <- function(alpha) {
  paste0(format(100 * (1 - alpha)), "% CI")
}

# Prints a table of already-formatted text in the style shared with
# nomologR: indented two spaces, text left-aligned and numbers right-aligned,
# headings in sentence case (standard abbreviations kept). Two columns may
# share a heading, such as "95% CI" after each of two estimates. A column
# empty in every row is dropped, except the status and the tests a decision
# rests on, whose "--" the notes explain (`keep`). A table wider than the
# console tightens its columns, then drops trailing ones, never the stub or a
# `keep` column, and names them with the call that shows them (`more`).
.print_table <- function(tab, keep = c("decision", "status", "result", "p",
                                       "omnibus p", "contrast p", "F test"),
                         more = "as.data.frame(x)", indent = 2L, gap = 2L) {
  tab <- as.data.frame(tab, stringsAsFactors = FALSE, check.names = FALSE)
  if (!ncol(tab)) return(invisible(tab))
  heads <- names(tab)
  cells <- lapply(tab, function(v) {
    v <- as.character(v)
    v[is.na(v)] <- .missing_mark
    v
  })
  # Empty everywhere: nothing a reader can use. The stub and the status stay.
  empty <- vapply(cells, function(v) {
    length(v) > 0L && all(v %in% c("", .missing_mark))
  }, logical(1))
  empty[1L] <- FALSE
  empty[heads %in% keep] <- FALSE
  cells <- cells[!empty]
  heads <- heads[!empty]
  shown <- .sentence_case(heads)
  right <- vapply(cells, .looks_numeric, logical(1))
  width_of <- function(v) if (length(v)) max(nchar(v, type = "width")) else 0L
  widths <- pmax(nchar(shown, type = "width"), vapply(cells, width_of, 0L))
  room <- getOption("width", 80L)
  total <- function() indent + sum(widths) + gap * (length(widths) - 1L)
  # Tighter columns before fewer columns.
  if (total() > room && gap > 1L) gap <- 1L
  dropped <- character(0)
  while (total() > room) {
    can_go <- which(seq_along(heads) > 1L & !(heads %in% keep))
    if (!length(can_go)) break
    j <- max(can_go)
    dropped <- c(shown[j], dropped)
    cells <- cells[-j]
    heads <- heads[-j]
    shown <- shown[-j]
    right <- right[-j]
    widths <- widths[-j]
  }
  pad <- function(v, w, r) {
    sp <- strrep(" ", pmax(0L, w - nchar(v, type = "width")))
    if (r) paste0(sp, v) else paste0(v, sp)
  }
  line <- function(parts) {
    sub("[[:space:]]+$", "", paste0(strrep(" ", indent),
                                    paste(parts, collapse = strrep(" ", gap))))
  }
  out <- line(mapply(pad, shown, widths, right))
  n <- length(cells[[1L]])
  for (i in seq_len(n)) {
    out <- c(out, line(mapply(function(v, w, r) pad(v[i], w, r), cells, widths,
                              right)))
  }
  cat(out, sep = "\n")
  if (length(dropped)) {
    .say(paste0("Not shown for width: ", paste(dropped, collapse = ", "),
                ". See ", more, " for every column."), indent = indent,
         exdent = indent)
  }
  invisible(tab)
}

# A percentage: whole numbers when the base is under 100, one decimal
# otherwise, rounded half up, with the missing marker for NA.
.fmt_pct <- function(p, base) {
  digits <- if (isTRUE(base >= 100)) 1L else 0L
  out <- paste0(formatC(.half_up(100 * as.numeric(p), digits), format = "f",
                        digits = digits), "%")
  out[is.na(p)] <- .missing_mark
  out
}

# A contingency table as a printable frame: the row variable's categories in
# the stub, one column per category of the column variable, headed with its
# name ("Actual: Retain").
.table_frame <- function(tab) {
  tab <- as.table(tab)
  dn <- dimnames(tab)
  vars <- names(dn)
  if (is.null(vars)) vars <- c("", "")
  out <- data.frame(stub = dn[[1]], stringsAsFactors = FALSE)
  names(out) <- if (nzchar(vars[1])) vars[1] else " "
  for (j in seq_along(dn[[2]])) {
    head <- if (nzchar(vars[2])) paste0(vars[2], ": ", dn[[2]][j]) else dn[[2]][j]
    out[[head]] <- format(as.vector(tab[, j]), trim = TRUE)
  }
  out
}

# A heading in sentence case: "item" becomes "Item", "mean Psa" becomes
# "Mean Psa". Statistical symbols that are lowercase by convention stay so.
.sentence_case <- function(h) {
  keep_lower <- c("p", "n", "df", "r")
  fix <- grepl("^[a-z]", h) & !(h %in% keep_lower)
  h[fix] <- paste0(toupper(substr(h[fix], 1L, 1L)), substring(h[fix], 2L))
  h
}

# Whether a column of formatted text holds numbers, to be right-aligned:
# estimates, intervals, counts such as "18/20", percentages, "< .001". The
# missing marker and "none" do not decide it.
.looks_numeric <- function(v) {
  v <- v[!(v %in% c("", .missing_mark, "none", "NA"))]
  if (!length(v)) return(TRUE)
  num <- "^([<>] )?-?([0-9]+([.][0-9]+)?|[.][0-9]+)%?$"
  all(grepl(num, v) | grepl("^\\[.*\\]$", v) | grepl("^[0-9]+/[0-9]+$", v) |
        v %in% c("Inf", "-Inf"))
}

# Sections. A section is a blank line, a sentence-case title with no colon,
# and content indented two spaces. .section() starts one, so that the prose
# .say() prints under it is indented like its tables; .end_section() returns
# to the margin for a printout's closing paragraph, and every header starts
# at the margin.
.cv_print <- new.env(parent = emptyenv())
.cv_print$indent <- 0L

.section <- function(title) {
  cat("\n", title, "\n", sep = "")
  .cv_print$indent <- 2L
  invisible(NULL)
}

.end_section <- function() {
  .cv_print$indent <- 0L
  invisible(NULL)
}

# A printout's last lines, at the margin: a closing caveat and, after a blank
# line, the pointer to what else the object holds ("See summary(x) for ...").
.closing <- function(caveat = NULL, pointer = NULL) {
  .end_section()
  if (length(caveat)) {
    cat("\n")
    .say(paste(caveat, collapse = " "))
  }
  if (length(pointer)) {
    cat("\n")
    .say(pointer)
  }
  invisible(NULL)
}

# Wraps a sentence or paragraph to the console, never wider than 79 columns
# (min(width, 80) - 1). A test statistic, a sample size or an interval is
# never broken across lines: "p < .001", "N = 473", "[.65, .99]", "F(2, 14)".
# Inside a section the default indent is the section's.
.say <- function(..., indent = NULL, exdent = NULL) {
  if (is.null(indent)) indent <- .cv_print$indent
  if (is.null(exdent)) exdent <- indent
  width <- min(getOption("width", 80L), 80L) - 1L
  txt <- .bind_phrases(paste(...))
  out <- strwrap(txt, width = width, indent = indent, exdent = exdent)
  cat(gsub(.nbsp, " ", out, fixed = TRUE), sep = "\n")
  invisible(NULL)
}

.nbsp <- "\u00a0"

# Joins the parts of a phrase that must stay on one line with no-break
# spaces, which strwrap() does not split at; .say() turns them back.
.bind_phrases <- function(x) {
  # "p < .001", "N = 473", "alpha = .05", "Phi = .80": a name, a relation
  # and a number.
  x <- gsub("\\b([A-Za-z][A-Za-z0-9-]*) ([<>=]) (?=[-.0-9])",
            paste0("\\1", .nbsp, "\\2", .nbsp), x, perl = TRUE)
  # "[.65, .99]" and "F(2, 14)" or "chi-square(1, N = 40)"
  x <- gsub("\\[([^]\\[]*), ([^]\\[]*)\\]", paste0("[\\1,", .nbsp, "\\2]"),
            x, perl = TRUE)
  x <- gsub("\\(([0-9.]+), ", paste0("(\\1,", .nbsp), x, perl = TRUE)
  x
}

# The first line of every printout: the object's class in angle brackets,
# then a plain-language title, on one line with no rule beneath it. A
# summary's tag ends in "summary": "<contentvalid_sort summary> Item-sort
# analysis". The form is shared with nomologR.
.print_header <- function(x, title) {
  cls <- class(x)[1]
  tag <- if (startsWith(cls, "summary.")) {
    paste(sub("^summary\\.", "", cls), "summary")
  } else {
    cls
  }
  .end_section()
  cat("<", tag, "> ", title, "\n", sep = "")
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
.say_grouped <- function(labels, texts, indent = NULL, exdent = NULL) {
  if (is.null(indent)) indent <- .cv_print$indent
  if (is.null(exdent)) exdent <- indent + 2L
  keep <- !is.na(texts) & nzchar(texts)
  for (txt in unique(texts[keep])) {
    .say(paste0(paste(labels[keep & texts == txt], collapse = ", "), ": ", txt),
         indent = indent, exdent = exdent)
  }
  invisible(NULL)
}

# The bullets of a "Flagged" section, shared with nomologR: one per unit,
# "- B2 (Review): A complete sentence.", units with the same decision and
# the same explanation grouped ("- B2, C2 (Review): ..."), review before
# no decision.
.say_flagged <- function(labels, decisions, texts) {
  indent <- .cv_print$indent
  texts <- ifelse(is.na(texts) | !nzchar(texts), "", texts)
  texts <- ifelse(nzchar(texts) & !grepl("[.!?]$", texts), paste0(texts, "."),
                  texts)
  key <- paste(decisions, texts, sep = "\r")
  order <- unique(key[order(decisions != "Review")])
  for (k in order) {
    same <- key == k
    .say(paste0("- ", paste(labels[same], collapse = ", "), " (",
                decisions[same][1], ")",
                if (nzchar(texts[same][1])) paste0(": ", texts[same][1])),
         indent = indent, exdent = indent + 2L)
  }
  invisible(NULL)
}

# Internal validation helpers -----------------------------------------------

.validate_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop(sprintf("`%s` must be TRUE or FALSE.", name), call. = FALSE)
  }
  invisible(x)
}

.validate_column_names <- function(..., context = "column-name arguments") {
  cols <- list(...)
  ok <- vapply(
    cols,
    function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x),
    logical(1)
  )
  if (!all(ok)) {
    stop("All ", context, " must be non-empty character scalars.", call. = FALSE)
  }
  vals <- unlist(cols, use.names = FALSE)
  if (anyDuplicated(vals)) {
    stop("The ", context, " must refer to distinct columns.", call. = FALSE)
  }
  invisible(vals)
}

# The lowest rating counted as relevant when the analyst gives none: one point
# below the top of the scale, or the top itself on a two-point scale, where
# "one below" is the bottom and every rating would count. It assumes scale
# points one unit apart; the help says to set the cut on any other scale.
.default_cut <- function(lo, hi) {
  if (hi - lo <= 1) hi else hi - 1
}

# A cut at the bottom of the scale counts every rating as relevant, so every
# item would meet any criterion whatever the experts said.
.validate_cut <- function(cut, lo, hi, name) {
  if (!is.numeric(cut) || length(cut) != 1L || !is.finite(cut) ||
      cut < lo || cut > hi) {
    stop(sprintf("`%s` must lie within the rating scale.", name), call. = FALSE)
  }
  if (cut <= lo) {
    stop(sprintf(paste0("`%s` cannot be the lowest point of the scale (%s): ",
                        "every rating would then count, and every item would ",
                        "meet the criterion. Use a value above `lo`."),
                 name, format(lo)), call. = FALSE)
  }
  invisible(cut)
}

# State shared inside the package while one function calls another.
.cv_state <- new.env(parent = emptyenv())

# Runs `code` with the rater-ID check switched off. A workflow that builds its
# own judge-by-item table from long data, as delphi_validity() does, names the
# columns after the user's items, so an item called "Subject" is an item.
.without_id_check <- function(code) {
  old <- .cv_state$skip_id_check
  .cv_state$skip_id_check <- TRUE
  on.exit(.cv_state$skip_id_check <- old, add = TRUE)
  code
}

# Wide ratings have one column per item. A rater-ID column left in the data
# would be analyzed as an item when its values happen to fall on the scale, so
# a column that looks like an ID stops the analysis. Two kinds are caught: a
# name such as "expert" or "rater_id", and the unnamed row-number column that
# write.csv() and read.csv() add ("X", "...1"), when it counts 1, 2, 3, ...
# The check goes by name, so it cannot catch an ID column called "Q0".
.check_no_id_column <- function(data, arg) {
  if (isTRUE(.cv_state$skip_id_check)) return(invisible(NULL))
  nm <- colnames(data)
  if (is.null(nm)) return(invisible(NULL))
  clean <- trimws(nm)
  id_like <- grepl(
    paste0("^(expert|judge|rater|coder|evaluator|panelist|panellist|reviewer|",
           "participant|respondent|subject|sme|id|pid|name)s?",
           "([ ._]?(id|name|no|num|number|#))?$"),
    clean, ignore.case = TRUE
  )
  row_like <- grepl("^(X(\\.[0-9]+)?|\\.\\.\\.[0-9]+|row[ ._]?(id|names?|number)?)$",
                    clean, ignore.case = TRUE)
  if (any(row_like)) {
    counts_rows <- vapply(which(row_like), function(j) {
      v <- if (is.data.frame(data)) data[[j]] else data[, j]
      is.numeric(v) && !anyNA(v) && isTRUE(all(v == seq_along(v)))
    }, logical(1))
    row_like[which(row_like)] <- counts_rows
  }
  hit <- which(id_like | row_like)
  if (length(hit)) {
    many <- length(hit) > 1L
    stop(sprintf(
      paste0("`%s` has %s named %s, which %s, not %s. Every column is ",
             "analyzed as an item, so remove %s first, for example ",
             "`%s[, -%s]`. If %s, rename it."),
      arg, if (many) "columns" else "a column",
      paste0("\"", nm[hit], "\"", collapse = ", "),
      if (many) "look like rater IDs" else "looks like a rater ID",
      if (many) "items" else "an item",
      if (many) "them" else "it", arg,
      if (many) paste0("c(", paste(hit, collapse = ", "), ")") else hit,
      if (many) "one of them is an item" else "it is an item"
    ), call. = FALSE)
  }
  invisible(NULL)
}

# Runs `code` with the random-number generator seeded, then puts the caller's
# generator back as it was. A seeded call is then reproducible without
# resetting the session's random stream, which would make every later draw in
# a simulation loop repeat. withr does the saving and restoring, so the
# package itself never writes to the global environment.
.with_seed <- function(seed, code) {
  if (is.null(seed)) return(code)
  withr::with_seed(as.integer(seed), code)
}

# Judge and item names key every table built from a judges-by-items matrix,
# so a repeated name is reported here, before it fails somewhere obscure.
.check_unique_names <- function(nm, what, margin) {
  dup <- unique(nm[duplicated(nm)])
  if (length(dup)) {
    stop("Each ", what, " needs its own name, but ",
         if (length(dup) == 1L) "this " else "these ", margin, " name",
         if (length(dup) == 1L) " is" else "s are", " used more than once: ",
         paste(dup[seq_len(min(5L, length(dup)))], collapse = ", "),
         if (length(dup) > 5L) ", ..." else "", ".", call. = FALSE)
  }
  invisible(NULL)
}

.validate_labels <- function(x, name, allow_na = FALSE) {
  if (!allow_na && anyNA(x)) {
    stop(sprintf("`%s` identifiers cannot be missing.", name), call. = FALSE)
  }
  z <- as.character(x)
  # Whitespace of any kind, so a label that is only a non-breaking space is
  # empty too.
  bad <- !is.na(z) & !nzchar(trimws(z, whitespace = "[\\h\\v]"))
  if (any(bad)) {
    stop(sprintf("`%s` identifiers cannot be empty.", name), call. = FALSE)
  }
  invisible(x)
}

# One value from a fixed set of choices, as match.arg() picks it (a unique
# partial match is enough, and the default or NULL gives the first choice),
# with the error the style shared with nomologR uses: `format` must be one of
# "apa", "data.frame", or "markdown", not "latex". With no `choices`, they are
# the default of the calling function's argument, as in match.arg().
.choose <- function(arg, choices = NULL, name = deparse(substitute(arg))) {
  if (is.null(choices)) {
    fn <- sys.function(sys.parent())
    choices <- eval(formals(fn)[[name]], envir = parent.frame())
  }
  if (is.null(arg) || identical(arg, choices)) return(choices[1L])
  ok <- is.character(arg) && length(arg) == 1L && !is.na(arg)
  i <- if (ok) pmatch(arg, choices) else NA_integer_
  if (is.na(i)) {
    listed <- paste0('"', choices, '"')
    listed <- if (length(listed) > 2L) {
      paste0(paste(listed[-length(listed)], collapse = ", "), ", or ",
             listed[length(listed)])
    } else {
      paste(listed, collapse = " or ")
    }
    given <- if (ok) paste0('"', arg, '"') else paste(deparse(arg), collapse = " ")
    stop("`", name, "` must be one of ", listed, ", not ", given, ".",
         call. = FALSE)
  }
  choices[i]
}

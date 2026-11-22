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

# Runs `code` with its messages naming the caller's argument. expert_validity()
# hands its `data` to aikens_v(), cvr() and ioc(), whose own argument names
# (`ratings`, `essential`) the user never typed, so an error from them names
# `data` instead, and the experts as experts.
.as_argument <- function(code, arg, rater = NULL) {
  old <- list(.cv_state$argument, .cv_state$rater)
  .cv_state$argument <- arg
  .cv_state$rater <- rater
  on.exit({
    .cv_state$argument <- old[[1]]
    .cv_state$rater <- old[[2]]
  }, add = TRUE)
  code
}

# The argument name an input check should use: the caller's, inside
# .as_argument(), and the function's own otherwise.
.argument <- function(own) {
  arg <- .cv_state$argument
  if (is.null(arg)) own else arg
}

.rater_noun <- function(own = "judge") {
  rater <- .cv_state$rater
  if (is.null(rater)) own else rater
}

# Up to `max` values joined by commas, then a count of the rest, so a message
# about a wide table stays short.
.list_some <- function(x, max = 5L) {
  x <- as.character(x)
  out <- paste(utils::head(x, max), collapse = ", ")
  if (length(x) > max) out <- paste0(out, " and ", length(x) - max, " more")
  out
}

# Columns of a table as a message names them: quoted names, or numbers when
# the table has no column names.
.column_labels <- function(x, j) {
  nm <- colnames(x)
  if (is.null(nm)) as.character(j) else paste0("\"", nm[j], "\"")
}

# "column \"Item3\" holds text (such as \"N/A\")": the columns of a
# judge-by-item table that are not numbers, with a value that is not a
# number, which is usually what the user must recode. A column that holds
# only numbers stored as text is named as such, beside any text columns, so
# that one error names every column to convert rather than one fix at a time
# revealing the next. NULL when every column is numeric or logical; otherwise
# the phrase carries the number of columns named, as attribute "n_columns".
.text_columns_phrase <- function(x) {
  cols <- if (is.data.frame(x)) {
    as.list(x)
  } else {
    m <- as.matrix(x)
    lapply(seq_len(ncol(m)), function(j) m[, j])
  }
  bad <- which(!vapply(cols, function(v) is.numeric(v) || is.logical(v),
                       logical(1)))
  if (!length(bad)) return(NULL)
  examples <- lapply(cols[bad], function(v) {
    v <- as.character(v)
    v[!is.na(v) & is.na(suppressWarnings(as.numeric(v)))]
  })
  texty <- lengths(examples) > 0L
  columns_hold <- function(j) {
    paste0(if (length(j) > 1L) "columns " else "column ",
           .list_some(.column_labels(x, j)),
           if (length(j) > 1L) " hold" else " holds")
  }
  parts <- character(0)
  if (any(texty)) {
    shown <- bad[texty]
    ex <- examples[texty][[1L]][1L]
    if (nchar(ex) > 40L) ex <- paste0(substr(ex, 1L, 37L), "...")
    parts <- paste0(columns_hold(shown), " text (such as \"", ex, "\"",
                    if (length(shown) > 1L) {
                      paste0(" in column ", .column_labels(x, shown[1L]))
                    },
                    ")")
  }
  if (!all(texty)) {
    parts <- c(parts, paste0(columns_hold(bad[!texty]),
                             " numbers stored as text"))
  }
  structure(paste(parts, collapse = " and "), n_columns = length(bad))
}

# ", but column \"Item3\" holds text ...", or nothing when no column was
# named, to follow "must hold numeric ratings" in an error. The callers ask
# only about a table that is not numeric, which always names a column; the
# empty form keeps a message whole should one ever not.
.but_columns <- function(phrase) {
  if (is.null(phrase)) "" else paste0(", but ", phrase)
}

# What the user is told to convert: the column or columns named, or the
# ratings when none was.
.convert_what <- function(phrase) {
  if (is.null(phrase)) return("the ratings")
  if (attr(phrase, "n_columns") > 1L) "those columns" else "that column"
}

# The error for a judge-by-item table that is not numeric. Data with one row
# per rating, the shape delphi_validity() and congruence mode take, is the
# usual way to arrive here, so the message states the shape the table needs.
.stop_not_numeric <- function(x, arg, rater = "judge") {
  which_cols <- .text_columns_phrase(x)
  stop(sprintf(
    paste0("`%s` must hold numeric ratings%s. `%s` needs one row per %s and ",
           "one column per item, so data with one row per rating must be ",
           "reshaped first. Otherwise convert %s to numbers, coding a missing ",
           "rating as NA."),
    arg, .but_columns(which_cols), arg, rater, .convert_what(which_cols)
  ), call. = FALSE)
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
         if (length(dup) > 5L) paste0(" and ", length(dup) - 5L, " more"),
         ".", call. = FALSE)
  }
  invisible(NULL)
}

.validate_labels <- function(x, name, allow_na = FALSE, empty_hint = NULL) {
  if (!allow_na && anyNA(x)) {
    stop(sprintf("`%s` identifiers cannot be missing.", name), call. = FALSE)
  }
  z <- as.character(x)
  # Whitespace of any kind, so a label that is only a non-breaking space is
  # empty too.
  bad <- !is.na(z) & !nzchar(trimws(z, whitespace = "[\\h\\v]"))
  if (any(bad)) {
    stop(sprintf("`%s` identifiers cannot be empty.", name),
         if (!is.null(empty_hint)) paste0(" ", empty_hint), call. = FALSE)
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

# A content_evidence() result lists stages and the items they carried, but it
# is not a fitted workflow, so content_handoff() and content_report() cannot
# take it. The message says what to use instead.
.evidence_not_fit <- function(arg) {
  sprintf(paste0("`%s` is a content_evidence() result, which combines stages ",
                 "and is not a fitted workflow. Hand off or report each ",
                 "stage's fit, use %s$carried for the items every deciding ",
                 "stage carried, and as.data.frame(%s) for the evidence ",
                 "table."), arg, arg, arg)
}

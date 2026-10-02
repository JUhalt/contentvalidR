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
# "one below" is the bottom and every rating would count.
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

# Wide ratings have one column per item. A rater-ID column left in the data
# would be analyzed as an item when its values happen to fall on the scale, so
# a column whose name looks like an ID stops the analysis.
.check_no_id_column <- function(data, arg) {
  nm <- colnames(data)
  if (is.null(nm)) return(invisible(NULL))
  id_like <- grepl(
    paste0("^(expert|judge|rater|panelist|panellist|reviewer|participant|",
           "respondent|subject|sme|id)s?([ ._]?(id|name|no|number))?$"),
    trimws(nm), ignore.case = TRUE
  )
  if (any(id_like)) {
    stop(sprintf(
      paste0("`%s` has a column named %s, which looks like a rater ID, not an ",
             "item. Every column is analyzed as an item, so remove it first, ",
             "for example `%s[, -%d]`."),
      arg, paste0("\"", nm[id_like], "\"", collapse = ", "), arg,
      which(id_like)[1]
    ), call. = FALSE)
  }
  invisible(NULL)
}

# Runs `code` with the random-number generator seeded, then puts the caller's
# generator back as it was. A seeded call is then reproducible without
# resetting the session's random stream, which would make every later draw in
# a simulation loop repeat.
.with_seed <- function(seed, code) {
  if (is.null(seed)) return(code)
  env <- globalenv()
  had <- exists(".Random.seed", envir = env, inherits = FALSE)
  old <- if (had) get(".Random.seed", envir = env, inherits = FALSE)
  on.exit({
    if (had) {
      assign(".Random.seed", old, envir = env)
    } else if (exists(".Random.seed", envir = env, inherits = FALSE)) {
      rm(".Random.seed", envir = env)
    }
  }, add = TRUE)
  set.seed(as.integer(seed))
  code
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

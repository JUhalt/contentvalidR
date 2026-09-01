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

.validate_labels <- function(x, name, allow_na = FALSE) {
  if (!allow_na && anyNA(x)) {
    stop(sprintf("`%s` identifiers cannot be missing.", name), call. = FALSE)
  }
  z <- as.character(x)
  bad <- !is.na(z) & !nzchar(trimws(z))
  if (any(bad)) {
    stop(sprintf("`%s` identifiers cannot be empty.", name), call. = FALSE)
  }
  invisible(x)
}

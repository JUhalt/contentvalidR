#' Tables from contentvalidR results
#'
#' @description
#' `as.data.frame()` returns a result's table as an ordinary data frame, for
#' filtering, joining, or writing to a file. A result that holds several
#' tables returns the one named by `component`; a single test returns one row.
#' Fitted workflows have their own method,
#' [as.data.frame.contentvalid_workflow()].
#'
#' @param x A contentvalidR result.
#' @param row.names,optional Accepted for compatibility with
#'   [base::as.data.frame()] and ignored.
#' @param component The table to return, where a result holds more than one:
#'   * [cvi()]: `"item_level"` (default) or `"scale_level"`.
#'   * [gtheory_content()]: `"variance_components"` (default),
#'     `"coefficients"`, `"dstudy"`, or `"judges_needed"`.
#'   * [content_structure()]: `"items"` (default; each item's cluster,
#'     blueprint cell and coordinates), `"fit"`, or `"cross_tab"`.
#'   * [compare_rounds()]: `"transitions"` (default), `"summary"`, or
#'     `"settings_changes"`.
#'   * [content_handoff()]: `"item_evidence"` (default), `"item_statistics"`,
#'     or `"panel_statistics"`.
#' @param ... Not used.
#'
#' @return A data frame. [csv_binom_test()], [signal_detection()],
#'   [reproducibility_phi()] and [panel_agreement()] give one row: an
#'   interval becomes two columns, and a two-by-two table becomes its four
#'   counts.
#'
#' @examples
#' R <- matrix(c(4, 3, 4, 4, 3, 4, 2, 3, 4, 4, 3, 2), 6,
#'             dimnames = list(NULL, c("I1", "I2")))
#' as.data.frame(cvi(R >= 3))
#' as.data.frame(cvi(R >= 3), component = "scale_level")
#' as.data.frame(csv_binom_test(16, 20))
#' @name contentvalid-data-frames
NULL

# One table out of a result holding several.
.as_df_part <- function(x, component, choices) {
  component <- match.arg(component, choices)
  out <- x[[component]]
  if (is.null(out)) {
    stop("This result has no `", component, "` table.", call. = FALSE)
  }
  out <- as.data.frame(out, stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out
}

# One row from a single test: scalars as they are, an interval as two
# columns, and a two-by-two table as its four counts.
.as_df_row <- function(x) {
  x <- unclass(x)
  cols <- list()
  for (nm in names(x)) {
    v <- x[[nm]]
    if (is.table(v) || is.matrix(v)) {
      if (length(dim(v)) == 2L && all(dim(v) == 2L)) {
        # Each count is named by its row and column: "n_predicted_retain_
        # actual_not_retained" for a confusion table.
        dn <- dimnames(v)
        tidy <- function(z) gsub("[^a-z0-9]+", "_", tolower(z))
        cells <- if (length(dn) == 2L && !is.null(names(dn)) &&
                     all(nzchar(names(dn)))) {
          as.vector(outer(paste(names(dn)[1], dn[[1]]),
                          paste(names(dn)[2], dn[[2]]), paste))
        } else {
          paste(nm, c("11", "21", "12", "22"))
        }
        cols[paste0("n_", tidy(cells))] <- as.list(as.vector(v))
      }
    } else if (is.atomic(v) && length(v) == 1L) {
      cols[[nm]] <- v
    } else if (is.atomic(v) && length(v) == 2L) {
      stem <- if (identical(nm, "conf.int")) "ci" else nm
      cols[paste0(stem, c("_low", "_high"))] <- as.list(as.vector(v))
    }
  }
  as.data.frame(cols, stringsAsFactors = FALSE, check.names = FALSE)
}

#' @rdname contentvalid-data-frames
#' @export
as.data.frame.contentvalid_cvi <- function(x, row.names = NULL, optional = FALSE,
                                           component = c("item_level", "scale_level"),
                                           ...) {
  .as_df_part(x, component[1], c("item_level", "scale_level"))
}

#' @rdname contentvalid-data-frames
#' @export
as.data.frame.contentvalid_gtheory <- function(x, row.names = NULL, optional = FALSE,
                                               component = c("variance_components",
                                                             "coefficients", "dstudy",
                                                             "judges_needed"),
                                               ...) {
  .as_df_part(x, component[1], c("variance_components", "coefficients",
                                 "dstudy", "judges_needed"))
}

#' @rdname contentvalid-data-frames
#' @export
as.data.frame.contentvalid_structure <- function(x, row.names = NULL,
                                                 optional = FALSE,
                                                 component = c("items", "fit",
                                                               "cross_tab"),
                                                 ...) {
  component <- match.arg(component[1], c("items", "fit", "cross_tab"))
  if (component == "items") {
    # The clusters table already carries each item's coordinates.
    out <- x$clusters
    rownames(out) <- NULL
    return(out)
  }
  if (component == "cross_tab") {
    if (is.null(x$cross_tab)) {
      stop("This result has no `cross_tab` table: no blueprint was given.",
           call. = FALSE)
    }
    out <- as.data.frame(x$cross_tab, stringsAsFactors = FALSE)
    names(out)[ncol(out)] <- "n_items"
    return(out)
  }
  .as_df_part(x, component, "fit")
}

#' @rdname contentvalid-data-frames
#' @export
as.data.frame.contentvalid_rounds <- function(x, row.names = NULL, optional = FALSE,
                                              component = c("transitions", "summary",
                                                            "settings_changes"),
                                              ...) {
  .as_df_part(x, component[1], c("transitions", "summary", "settings_changes"))
}

#' @rdname contentvalid-data-frames
#' @export
as.data.frame.contentvalid_handoff <- function(x, row.names = NULL, optional = FALSE,
                                               component = c("item_evidence",
                                                             "item_statistics",
                                                             "panel_statistics"),
                                               ...) {
  .as_df_part(x, component[1], c("item_evidence", "item_statistics",
                                 "panel_statistics"))
}

#' @rdname contentvalid-data-frames
#' @export
as.data.frame.contentvalid_sort_power <- function(x, row.names = NULL,
                                                  optional = FALSE, ...) {
  .as_df_part(x, "table", "table")
}

#' @rdname contentvalid-data-frames
#' @export
as.data.frame.contentvalid_expert_power <- function(x, row.names = NULL,
                                                    optional = FALSE, ...) {
  .as_df_part(x, "results", "results")
}

#' @rdname contentvalid-data-frames
#' @export
as.data.frame.contentvalid_agreement <- function(x, row.names = NULL,
                                                 optional = FALSE, ...) {
  .as_df_row(x)
}

#' @rdname contentvalid-data-frames
#' @export
as.data.frame.contentvalid_binom <- function(x, row.names = NULL, optional = FALSE,
                                             ...) {
  .as_df_row(x)
}

#' @rdname contentvalid-data-frames
#' @export
as.data.frame.contentvalid_signal <- function(x, row.names = NULL, optional = FALSE,
                                              ...) {
  .as_df_row(x)
}

#' @rdname contentvalid-data-frames
#' @export
as.data.frame.contentvalid_reproducibility <- function(x, row.names = NULL,
                                                       optional = FALSE, ...) {
  .as_df_row(x)
}

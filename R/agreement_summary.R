#' Agreement summary (auxiliary)
#'
#' @description Computes Fleiss' kappa via 'irr' if available. This is an auxiliary compatibility helper, not part of the recommended contentvalidR workflows.
#' @param ratings matrix/data.frame: rows = items, cols = raters (nominal categories)
#' @return list with results, or a message if 'irr' is not installed
#' @export
agreement_summary <- function(ratings) {
  X <- as.data.frame(ratings)
  if (nrow(X) < 1L || ncol(X) < 2L) {
    stop("`ratings` must contain at least one item and two raters.", call. = FALSE)
  }
  if (!requireNamespace("irr", quietly = TRUE)) {
    message("Package 'irr' not installed; install.packages('irr') to compute Fleiss' kappa.")
    return(list(ok = FALSE, message = "irr not installed"))
  }
  fun <- getExportedValue("irr", "kappam.fleiss")
  fun(X)
}

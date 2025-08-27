#' Agreement summary (auxiliary)
#'
#' @description Computes Fleiss' kappa via 'irr' if available (auxiliary only).
#' @param ratings matrix/data.frame: rows = items, cols = raters (nominal categories)
#' @return list with results, or a message if 'irr' is not installed
#' @export
agreement_summary <- function(ratings) {
  if (!requireNamespace("irr", quietly = TRUE)) {
    message("Package 'irr' not installed; install.packages('irr') to compute Fleiss' kappa.")
    return(list(ok = FALSE, message = "irr not installed"))
  }
  fun <- getExportedValue("irr", "kappam.fleiss")
  fun(as.data.frame(ratings))
}

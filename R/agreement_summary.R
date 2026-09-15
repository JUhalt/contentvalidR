#' Agreement summary (auxiliary)
#'
#' @description Computes Fleiss' kappa via 'irr' if available. This is an auxiliary compatibility helper, not part of the recommended contentvalidR workflows.
#' @param ratings matrix/data.frame: rows = items, cols = raters (nominal categories)
#' @return When 'irr' is installed, the result of `irr::kappam.fleiss()`.
#'   Otherwise a list with `ok = FALSE` and a `message`, after a message
#'   explaining how to install 'irr'.
#' @seealso [panel_agreement()] for panel-level agreement with an evidence-based
#'   default coefficient and a bootstrap interval.
#' @examples
#' ratings <- data.frame(
#'   rater1 = c("A", "B", "A", "C"),
#'   rater2 = c("A", "B", "B", "C"),
#'   rater3 = c("A", "B", "A", "C")
#' )
#' if (requireNamespace("irr", quietly = TRUE)) {
#'   agreement_summary(ratings)
#' }
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

#' Agreement summary (auxiliary)
#'
#' @description
#' Convenience wrapper to compute Fleiss' kappa via the 'irr' package if available.
#' This is NOT a substitute for Csv/Psa and should be presented as auxiliary only.
#'
#' @param ratings matrix/data.frame where rows = subjects (items), columns = raters,
#'        and values are nominal category labels (e.g., construct names).
#'
#' @returns A list with either kappa results or a message asking to install 'irr'.
#' @examples
#' # Not run: requires 'irr'
#' # agreement_summary(matrix(sample(letters[1:3], 30, TRUE), nrow = 10))
agreement_summary <- function(ratings) {
  if (!requireNamespace("irr", quietly = TRUE)) {
    message("Package 'irr' not installed; install.packages('irr') to compute Fleiss' kappa.")
    return(list(ok = FALSE, message = "irr not installed"))
  }
  irr::kappam.fleiss(as.data.frame(ratings))
}

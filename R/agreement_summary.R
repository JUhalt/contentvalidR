#' Agreement summary (deprecated)
#'
#' @description
#' **Deprecated in 0.9.0, to be removed in 1.0.0.** Use [panel_agreement()]
#' instead. `agreement_summary()` is the only function in the package that
#' takes items in rows and raters in columns; every other ratings function,
#' `panel_agreement()` included, takes raters in rows. The same matrix passed
#' to both would therefore be read two different ways. `panel_agreement()`
#' also reports an interval and needs no other package. Calling
#' `agreement_summary()` still works in 0.9.0, with a warning.
#'
#' Computes Fleiss' (1971) kappa, the extension of Cohen's kappa to many
#' raters, by calling `irr::kappam.fleiss()` from the irr package (Gamer,
#' Lemon, Fellows, & Singh, 2026) when it is installed.
#' @param ratings matrix/data.frame: rows = items, cols = raters (nominal
#'   categories). Note the orientation, the reverse of [panel_agreement()].
#' @return When 'irr' is installed, the result of `irr::kappam.fleiss()`.
#'   Otherwise a list with `ok = FALSE` and a `message`, after a message
#'   explaining how to install 'irr'.
#' @seealso [panel_agreement()] for panel-level agreement with an evidence-based
#'   default coefficient and a bootstrap interval.
#' @references
#' Fleiss, J. L. (1971). Measuring nominal scale agreement among many raters.
#' *Psychological Bulletin, 76*(5), 378–382. \doi{10.1037/h0031619}
#'
#' Gamer, M., Lemon, J., Fellows, I., & Singh, P. (2026). *irr: Various
#' coefficients of interrater reliability and agreement* (R package version
#' 0.85). \doi{10.32614/CRAN.package.irr}
#' @examples
#' ratings <- data.frame(
#'   rater1 = c("A", "B", "A", "C"),
#'   rater2 = c("A", "B", "B", "C"),
#'   rater3 = c("A", "B", "A", "C")
#' )
#' # Deprecated: it warns, and points to panel_agreement().
#' if (requireNamespace("irr", quietly = TRUE)) {
#'   suppressWarnings(agreement_summary(ratings))
#' }
#' @export
agreement_summary <- function(ratings) {
  warning(structure(
    class = c("contentvalidR_deprecated", "deprecatedWarning", "warning",
              "condition"),
    list(message = paste(
      "`agreement_summary()` is deprecated and will be removed in",
      "contentvalidR 1.0.0. Use `panel_agreement()`, which takes raters in",
      "rows, where `agreement_summary()` takes items in rows."
    ), call = NULL)
  ))
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

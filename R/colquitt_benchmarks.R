.colquitt_cutpoints <- function(statistic, norm) {
  tables <- list(
    overall = list(
      psa = c(`Very Strong` = .91, Strong = .82, Moderate = .72, Weak = .39),
      csv = c(`Very Strong` = .81, Strong = .61, Moderate = .51, Weak = .05),
      htc = c(`Very Strong` = .91, Strong = .87, Moderate = .84, Weak = .60),
      htd = c(`Very Strong` = .35, Strong = .27, Moderate = .18, Weak = .04)
    ),
    stronger = list(
      psa = c(`Very Strong` = .80, Strong = .75, Moderate = .60, Weak = .24),
      csv = c(`Very Strong` = .61, Strong = .50, Moderate = .21, Weak = .01),
      htc = c(`Very Strong` = .90, Strong = .86, Moderate = .82, Weak = .63),
      htd = c(`Very Strong` = .23, Strong = .15, Moderate = .11, Weak = .01)
    ),
    moderate = list(
      psa = c(`Very Strong` = .91, Strong = .81, Moderate = .76, Weak = .46),
      csv = c(`Very Strong` = .83, Strong = .61, Moderate = .52, Weak = .01),
      htc = c(`Very Strong` = .92, Strong = .89, Moderate = .85, Weak = .60),
      htd = c(`Very Strong` = .34, Strong = .27, Moderate = .20, Weak = .09)
    ),
    weaker = list(
      psa = c(`Very Strong` = .94, Strong = .90, Moderate = .84, Weak = .52),
      csv = c(`Very Strong` = .89, Strong = .80, Moderate = .67, Weak = .04),
      htc = c(`Very Strong` = .91, Strong = .88, Moderate = .86, Weak = .67),
      htd = c(`Very Strong` = .48, Strong = .35, Moderate = .26, Weak = .12)
    )
  )
  tables[[norm]][[statistic]]
}

.colquitt_norm <- function(orbiting_r = NULL) {
  if (is.null(orbiting_r) || is.na(orbiting_r)) return("overall")
  if (!is.numeric(orbiting_r) || length(orbiting_r) != 1L || !is.finite(orbiting_r) || orbiting_r < -1 || orbiting_r > 1) {
    stop("`orbiting_r` must be NULL or one finite correlation between -1 and 1.", call. = FALSE)
  }
  if (orbiting_r <= .34) "weaker" else if (orbiting_r <= .50) "moderate" else "stronger"
}

.colquitt_norm_label <- function(norm) {
  switch(
    norm,
    overall = "Overall (not correlation-normed)",
    weaker = "Weaker focal-orbiting correlation (r <= .34)",
    moderate = "More moderate focal-orbiting correlation (.35-.50)",
    stronger = "Stronger focal-orbiting correlation (r >= .51)"
  )
}

#' Colquitt et al. (2019) empirical content-validation benchmarks
#'
#' @description
#' Returns the empirical interpretation bands proposed by Colquitt et al.
#' (2019) for Psa, Csv, HTC, or HTD. The benchmarks were created from
#' scale-level averages for 112 scales and are percentile-based norms, not
#' universal psychometric cutoffs.
#'
#' If `orbiting_r` is supplied, the correlation-conditional benchmark set is
#' selected. Otherwise the overall, non-correlation-normed criteria are used.
#'
#' The published table contains a few rounded boundary overlaps/gaps. This
#' implementation treats each printed lower bound as the start of its category
#' and assigns categories from strongest to weakest, yielding deterministic
#' interpretation at rounded boundaries.
#'
#' @param statistic One of `"psa"`, `"csv"`, `"htc"`, or `"htd"`.
#' @param orbiting_r Optional average correlation between the focal scale and
#'   its orbiting scales.
#'
#' @return A data.frame describing the selected benchmark set and its lower
#'   cutpoints.
#'
#' @references
#' Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
#' Content validation guidelines: Evaluation criteria for definitional
#' correspondence and definitional distinctiveness. *Journal of Applied
#' Psychology, 104*(10), 1243-1265. \doi{10.1037/apl0000406}
#'
#' @examples
#' colquitt_benchmarks("psa")
#' colquitt_benchmarks("csv", orbiting_r = .40)
#' @export
colquitt_benchmarks <- function(statistic = c("psa", "csv", "htc", "htd"),
                                orbiting_r = NULL) {
  statistic <- match.arg(statistic)
  norm <- .colquitt_norm(orbiting_r)
  cp <- .colquitt_cutpoints(statistic, norm)
  data.frame(
    statistic = statistic,
    benchmark_set = norm,
    benchmark_label = .colquitt_norm_label(norm),
    interpretation = c(names(cp), "Lack of"),
    percentile = c("80th-99th", "60th-79th", "40th-59th", "20th-39th", "0th-19th"),
    minimum = c(unname(cp), -Inf),
    stringsAsFactors = FALSE
  )
}

#' Interpret a statistic using Colquitt et al. (2019) norms
#'
#' @description
#' Classifies one or more Psa, Csv, HTC, or HTD values using the empirical
#' percentile bands from Colquitt et al. (2019). These norms were derived from
#' scale-level averages and from naive judges representative of substantive
#' study populations. They should therefore be treated as contextual norms,
#' not pass/fail rules.
#'
#' When `judge_type = "expert"`, the Colquitt classification is deliberately
#' not applied because the authors caution against using their norms for expert
#' judges.
#'
#' @param value Numeric value(s) to interpret.
#' @param statistic One of `"psa"`, `"csv"`, `"htc"`, or `"htd"`.
#' @param orbiting_r Optional scalar, or a vector matching `value`, containing
#'   the average focal-orbiting correlation. `NULL` uses the overall norms.
#' @param judge_type Either `"naive"` or `"expert"`.
#'
#' @return A data.frame with the value, benchmark set, interpretation, and an
#'   applicability flag.
#'
#' @references
#' Colquitt, J. A., Sabey, T. B., Rodell, J. B., & Hill, E. T. (2019).
#' *Journal of Applied Psychology, 104*(10), 1243-1265.
#' \doi{10.1037/apl0000406}
#'
#' @examples
#' interpret_colquitt(.84, "psa")
#' interpret_colquitt(.70, "csv", orbiting_r = .40)
#' @export
interpret_colquitt <- function(value,
                               statistic = c("psa", "csv", "htc", "htd"),
                               orbiting_r = NULL,
                               judge_type = c("naive", "expert")) {
  statistic <- match.arg(statistic)
  judge_type <- match.arg(judge_type)
  if (!is.numeric(value) || length(value) < 1L) {
    stop("`value` must be a non-empty numeric vector.", call. = FALSE)
  }
  valid_range <- if (statistic %in% c("psa", "htc")) c(0, 1) else c(-1, 1)
  if (any(!is.na(value) & (!is.finite(value) | value < valid_range[1] | value > valid_range[2]))) {
    stop(sprintf("`%s` values must lie between %g and %g.", statistic, valid_range[1], valid_range[2]), call. = FALSE)
  }
  if (!is.null(orbiting_r)) {
    if (!is.numeric(orbiting_r) || !(length(orbiting_r) %in% c(1L, length(value)))) {
      stop("`orbiting_r` must be NULL, length 1, or the same length as `value`.", call. = FALSE)
    }
    orbiting_r <- rep(orbiting_r, length.out = length(value))
  }

  rows <- lapply(seq_along(value), function(i) {
    v <- value[i]
    r <- if (is.null(orbiting_r)) NULL else orbiting_r[i]
    norm <- .colquitt_norm(r)

    if (judge_type == "expert") {
      return(data.frame(
        statistic = statistic, value = v, benchmark_set = norm,
        benchmark_label = .colquitt_norm_label(norm),
        interpretation = NA_character_, applicable = FALSE,
        note = "Colquitt et al. (2019) norms were developed for naive judges, not expert panels.",
        stringsAsFactors = FALSE
      ))
    }

    label <- NA_character_
    if (!is.na(v)) {
      cp <- .colquitt_cutpoints(statistic, norm)
      hit <- which(v >= cp)
      label <- if (length(hit)) names(cp)[min(hit)] else "Lack of"
    }
    data.frame(
      statistic = statistic, value = v, benchmark_set = norm,
      benchmark_label = .colquitt_norm_label(norm),
      interpretation = label, applicable = TRUE,
      note = "Empirical percentile norm from scale-level averages; not a universal cutoff.",
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

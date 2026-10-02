# The component functions (compute_psa(), aikens_v(), cvr(), and the rest)
# return ordinary data frames, lists, or a matrix, tagged with a small class so
# they print as formatted tables in APA style (see format_apa.R). Only the
# display is rounded: every value keeps full precision, and as.data.frame()
# returns the plain data frame. The workflows call these functions and strip
# the tag at once, so it never reaches a workflow's results.

.tag_component <- function(x, cls, ...) {
  extra <- list(...)
  for (nm in names(extra)) attr(x, nm) <- extra[[nm]]
  oldClass(x) <- c(cls, "contentvalid_component",
                   setdiff(oldClass(x), c(cls, "contentvalid_component")))
  x
}

.untag_component <- function(x) {
  keep <- oldClass(x)
  if (is.null(keep)) return(x)
  keep <- keep[!(startsWith(keep, "contentvalid_") & keep != "contentvalid_workflow")]
  oldClass(x) <- if (length(keep)) keep else NULL
  x
}

#' @export
as.data.frame.contentvalid_component <- function(x, ...) {
  as.data.frame(.untag_component(x), ...)
}

# Prints a titled table with notes beneath it. When a user has dropped the
# columns a display needs (by subsetting), the plain data frame prints instead.
.print_component <- function(x, needed, build, title, notes = NULL) {
  if (!all(needed %in% names(x))) {
    print(.untag_component(x))
    return(invisible(x))
  }
  .say(title)
  cat("\n")
  .print_table(build())
  notes <- notes[!is.na(notes) & nzchar(notes)]
  if (length(notes)) {
    cat("\n")
    for (n in notes) .say(n)
  }
  invisible(x)
}

.yes_no <- function(x) ifelse(is.na(x), "NA", ifelse(x, "yes", "no"))

.alpha_attr <- function(x) {
  a <- attr(x, "alpha")
  if (is.numeric(a) && length(a) == 1L && is.finite(a)) a else 0.05
}

#' @export
print.contentvalid_psa <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  alpha <- .alpha_attr(x)
  method <- attr(x, "ci_method")
  has_ci <- all(c("psa_low", "psa_high") %in% names(x)) && any(!is.na(x$psa_low))
  .print_component(
    x, c("item", "target", "n", "n_target", "psa"),
    title = "Proportion of substantive agreement (Psa; Anderson & Gerbing, 1991)",
    build = function() {
      tab <- data.frame(item = x$item, target = x$target,
                        judges = paste0(x$n_target, "/", x$n),
                        Psa = .fmt(x$psa, digits), stringsAsFactors = FALSE)
      if (has_ci) tab[[.ci_label(alpha)]] <- .fmt_ci(x$psa_low, x$psa_high, digits)
      tab
    },
    notes = c(
      "judges: assignments to the target construct, out of the judges who sorted the item.",
      if (has_ci && is.character(method)) .proportion_ci_note(method, alpha),
      if ("n_missing" %in% names(x) && any(x$n_missing > 0, na.rm = TRUE)) {
        paste("Missing assignments:", sum(x$n_missing, na.rm = TRUE),
              "in all; each item uses the judges who sorted it.")
      }
    )
  )
}

#' @export
print.contentvalid_csv <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  .print_component(
    x, c("item", "target", "n", "n_target", "competitor", "n_other_max", "csv"),
    title = "Coefficient of substantive validity (Csv; Anderson & Gerbing, 1991)",
    build = function() {
      data.frame(item = x$item, target = x$target,
                 judges = paste0(x$n_target, "/", x$n),
                 competitor = x$competitor,
                 `competitor judges` = paste0(x$n_other_max, "/", x$n),
                 Csv = .fmt(x$csv, digits),
                 stringsAsFactors = FALSE, check.names = FALSE)
    },
    notes = paste("Csv is the target count minus the count for the most-chosen",
                  "other construct, divided by the number of judges.")
  )
}

#' @export
print.contentvalid_htc <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  .print_component(
    x, c("item", "target", "n_target", "target_mean", "htc"),
    title = "Hinkin-Tracey correspondence (HTC; Colquitt et al., 2019)",
    build = function() {
      data.frame(item = x$item, target = x$target, judges = x$n_target,
                 `target mean` = .fmt(x$target_mean, digits, bounded = FALSE),
                 HTC = .fmt(x$htc, digits),
                 stringsAsFactors = FALSE, check.names = FALSE)
    },
    notes = if ("anchors" %in% names(x) && length(unique(x$anchors)) == 1L) {
      sprintf("HTC expresses the mean target rating as a share of the %d-point scale.",
              as.integer(x$anchors[1]))
    }
  )
}

#' @export
print.contentvalid_htd <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  .print_component(
    x, c("item", "target", "n_complete", "target_mean_complete",
         "strongest_competitor", "competitor_mean", "htd"),
    title = "Hinkin-Tracey distinctiveness (HTD; Colquitt et al., 2019)",
    build = function() {
      data.frame(item = x$item, target = x$target, judges = x$n_complete,
                 `target mean` = .fmt(x$target_mean_complete, digits, bounded = FALSE),
                 competitor = x$strongest_competitor,
                 `competitor mean` = .fmt(x$competitor_mean, digits, bounded = FALSE),
                 HTD = .fmt(x$htd, digits),
                 stringsAsFactors = FALSE, check.names = FALSE)
    },
    notes = paste("competitor: the other construct with the highest mean rating.",
                  "HTD itself averages the gap over every other construct.")
  )
}

#' @export
print.contentvalid_anova <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  needed <- c("item", "target", "n_complete", "F", "df1", "df2", "p_screen",
              "partial_eta2", "strongest_competitor", "max_contrast_p",
              "contrast_pass")
  .print_component(
    x, needed,
    title = "Content-validity ANOVA (Hinkin & Tracey, 1999)",
    build = function() {
      gg <- !is.na(x$df1_gg)
      d1 <- ifelse(gg, x$df1_gg, x$df1)
      d2 <- ifelse(gg, x$df2_gg, x$df2)
      test <- ifelse(is.na(x$F), "NA",
                     sprintf("F(%s, %s) = %s", .fmt(d1, digits, bounded = FALSE),
                             .fmt(d2, digits, bounded = FALSE),
                             .fmt(x$F, digits, bounded = FALSE)))
      # Narrow enough for an 80-column console; the strongest competitor
      # stays in the `strongest_competitor` column.
      data.frame(item = x$item, target = x$target, judges = x$n_complete,
                 `F test` = test, p = .fmt_p(x$p_screen),
                 `partial eta^2` = .fmt(x$partial_eta2, digits),
                 `contrast p` = .fmt_p(x$max_contrast_p),
                 met = .yes_no(x$contrast_pass),
                 stringsAsFactors = FALSE, check.names = FALSE)
    },
    notes = c(
      if (any(!is.na(x$df1_gg))) {
        "Within-judge omnibus tests are Greenhouse-Geisser corrected, so their degrees of freedom are fractional."
      },
      paste("contrast p: the largest p among the planned target-versus-other",
            "contrasts; met: whether every one of them met the screening",
            "criterion. attr(x, \"contrasts\") holds each contrast, and",
            "`strongest_competitor` the construct rated closest to the target.")
    )
  )
}

#' @export
print.contentvalid_aiken <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  alpha <- .alpha_attr(x)
  has_ci <- all(c("ci_low", "ci_high") %in% names(x)) && any(!is.na(x$ci_low))
  methods <- if ("ci_method" %in% names(x)) unique(stats::na.omit(x$ci_method)) else character(0)
  scale <- attr(x, "scale")
  .print_component(
    x, c("item", "N", "V"),
    title = "Aiken's V (Aiken, 1980)",
    build = function() {
      tab <- data.frame(item = x$item, experts = x$N, V = .fmt(x$V, digits),
                        stringsAsFactors = FALSE)
      if (has_ci) tab[[.ci_label(alpha)]] <- .fmt_ci(x$ci_low, x$ci_high, digits)
      tab
    },
    notes = c(
      # V depends on the scale, so the scale it was computed on is stated.
      if (is.numeric(scale) && length(scale) == 2L) {
        sprintf("Scale: %s to %s.", format(scale[1]), format(scale[2]))
      },
      if (has_ci && length(methods) == 1L) {
        paste0("Interval: ", methods,
               if (identical(methods, "Penfield-Giacobbi score")) " (Penfield & Giacobbi, 2004)", ".")
      }
    )
  )
}

#' @export
print.contentvalid_cvr <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  alpha <- .alpha_attr(x)
  .print_component(
    x, c("item", "ne", "N", "cvr", "p_value", "critical_ne", "pass"),
    title = "Content validity ratio (CVR; Lawshe, 1975)",
    build = function() {
      unreachable <- is.na(x$critical_ne) & x$N >= 1L
      data.frame(item = x$item, essential = paste0(x$ne, "/", x$N),
                 CVR = .fmt(x$cvr, digits), p = .fmt_p(x$p_value),
                 needed = ifelse(unreachable, "none",
                                 ifelse(is.na(x$critical_ne), "--",
                                        as.character(x$critical_ne))),
                 meets = ifelse(unreachable, "--", .yes_no(x$pass)),
                 stringsAsFactors = FALSE)
    },
    notes = c(
      sprintf(paste("needed: essential ratings the exact one-tailed binomial",
                    "test requires at alpha = %s (Ayre & Scally, 2014)."),
              .fmt_alpha(alpha)),
      if (any(is.na(x$critical_ne) & x$N >= 1L)) {
        sprintf(paste("With %s, no count of essential ratings reaches alpha =",
                      "%s, so the test cannot be met at that panel size."),
                .or_fewer(max(x$N[is.na(x$critical_ne) & x$N >= 1L]), "expert"),
                .fmt_alpha(alpha))
      }
    )
  )
}

#' @export
print.contentvalid_ioc <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  .print_component(
    x, c("item", "objective", "n_judges", "ioc"),
    title = "Item-objective congruence (IOC; Rovinelli & Hambleton, 1977)",
    build = function() {
      data.frame(item = x$item, objective = x$objective, judges = x$n_judges,
                 IOC = .fmt(x$ioc, digits), stringsAsFactors = FALSE)
    }
  )
}

.stat_heading <- function(s) {
  map <- c(psa = "Psa", csv = "Csv", htc = "HTC", htd = "HTD")
  ifelse(s %in% names(map), map[s], s)
}

#' @export
print.contentvalid_colquitt <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  .print_component(
    x, c("statistic", "value", "interpretation", "benchmark_label"),
    title = "Benchmark bands (Colquitt et al., 2019)",
    build = function() {
      data.frame(statistic = .stat_heading(x$statistic),
                 value = .fmt(x$value, digits),
                 band = ifelse(is.na(x$interpretation), "not applied", x$interpretation),
                 benchmarks = x$benchmark_label,
                 stringsAsFactors = FALSE)
    },
    notes = if ("note" %in% names(x)) unique(x$note)
  )
}

#' @export
print.contentvalid_colquitt_norms <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  .print_component(
    x, c("statistic", "benchmark_label", "interpretation", "percentile", "minimum"),
    title = sprintf("Benchmarks for %s (Colquitt et al., 2019): %s",
                    .stat_heading(x$statistic[1]), x$benchmark_label[1]),
    build = function() {
      data.frame(band = x$interpretation, percentile = x$percentile,
                 minimum = ifelse(is.finite(x$minimum), .fmt(x$minimum, digits), "none"),
                 stringsAsFactors = FALSE)
    },
    notes = paste("A scale-level mean at or above a band's minimum falls in that",
                  "band. The bands are percentiles of published scales, not",
                  "validity cutoffs.")
  )
}

#' @export
print.contentvalid_binom <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  .say("Howard-Melloy exact test (one-tailed)")
  cat("\n")
  p_txt <- .p_phrase(x$p.value)
  has_counts <- all(c("n_target", "N", "p0", "alpha") %in% names(x))
  # The verdict comes first, in the words the item-sort workflow uses.
  .say(if (isTRUE(x$passes_chance)) {
    "The item meets the exact target-assignment criterion."
  } else {
    "The item does not meet the exact target-assignment criterion."
  })
  if (has_counts) {
    .say(sprintf(paste("%d of %s assigned the item to its target construct",
                       "(Psa = %s). If each judge chose the target with",
                       "probability p0 = %s, a count this high has probability %s."),
                 as.integer(x$n_target), .n_noun(as.integer(x$N), "judge"),
                 .fmt(x$estimate, digits), .fmt(x$p0, digits), p_txt))
    if (is.na(x$critical_n_target)) {
      .say(sprintf(paste("With %s, no count can reach alpha = %s, so no item",
                         "can meet the criterion at this panel size."),
                   .n_noun(as.integer(x$N), "judge"), .fmt_alpha(x$alpha)))
    } else {
      .say(sprintf("At alpha = %s an item needs at least %d of %d.",
                   .fmt_alpha(x$alpha), as.integer(x$critical_n_target),
                   as.integer(x$N)))
    }
  } else {
    .say(sprintf("Psa = %s, %s.", .fmt(x$estimate, digits), p_txt))
  }
  if (length(x$conf.int) == 2L) {
    .say(sprintf("One-sided %s%% CI for the target rate: %s.",
                 format(100 * attr(x$conf.int, "conf.level")),
                 .fmt_ci(x$conf.int[1], x$conf.int[2], digits)))
  }
  invisible(x)
}

.print_two_by_two <- function(tab, title, x, digits, extra = NULL) {
  .say(title)
  cat("\n")
  print(tab)
  cat("\n")
  stats <- c(extra,
             paste0("phi = ", .fmt(x$phi, digits)),
             if (!is.na(x$chisq)) {
               sprintf("chi-square(1) = %s, %s",
                       .fmt(x$chisq, digits, bounded = FALSE), .p_phrase(x$p))
             })
  .say(paste0(paste(stats, collapse = ", "), "."))
  invisible(x)
}

#' @export
print.contentvalid_signal <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  .print_two_by_two(
    x$confusion, "Retention decisions compared with the actual outcome",
    x, digits,
    extra = c(paste0("accuracy = ", .fmt(x$accuracy, digits)),
              paste0("sensitivity = ", .fmt(x$sensitivity, digits)),
              paste0("specificity = ", .fmt(x$specificity, digits)))
  )
}

#' @export
print.contentvalid_reproducibility <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  .print_two_by_two(x$table, "Retention decisions in two pretests", x, digits)
}

#' @export
print.contentvalid_similarity <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  m <- unclass(x)
  pairs <- attr(m, "n_pairs")
  attr(m, "n_pairs") <- NULL
  shown <- matrix(.fmt(m, digits), nrow(m), dimnames = dimnames(m))
  diag(shown) <- "-"
  .say("Item similarity: the share of judges who sorted both items and put",
       "them in the same construct")
  cat("\n")
  print(noquote(shown), right = TRUE)
  if (is.matrix(pairs)) {
    off <- pairs[upper.tri(pairs)]
    cat("\n")
    .say(if (length(unique(off)) == 1L) {
      sprintf("Every pair was sorted by the same %d judges.", as.integer(off[1]))
    } else {
      sprintf("Pairs were sorted by %d to %d judges; attr(x, \"n_pairs\") has each count.",
              as.integer(min(off)), as.integer(max(off)))
    })
  }
  invisible(x)
}

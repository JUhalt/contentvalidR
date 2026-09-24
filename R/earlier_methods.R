# Earlier published methods, computed beside the current ones for teaching,
# the way a methods text reports eta-squared next to omega-squared. None of
# them decides anything: each workflow's own rule does. Every rule here is
# taken from its source as published, without extension, and is checked
# against the source's own worked values in test-earlier-methods.R.

# Lawshe (1975, Table 1): minimum CVR by panel size, labeled a one-tailed test
# at .05 and computed by Schipper. A unanimous panel's CVR of 1 is listed as
# .99. Panel sizes the table does not list have no minimum.
.lawshe_minimum_cvr <- c(`5` = .99, `6` = .99, `7` = .99, `8` = .75, `9` = .78,
                         `10` = .62, `11` = .59, `12` = .56, `13` = .54,
                         `14` = .51, `15` = .49, `20` = .42, `25` = .37,
                         `30` = .33, `35` = .31, `40` = .29)

.lawshe_minimum <- function(N) unname(.lawshe_minimum_cvr[as.character(N)])

# Wilson, Pan and Schumsky (2012, Table 2): the normal approximation to the
# binomial, z(1 - alpha) / sqrt(N) for a one-tailed test, with a value of 1 or
# more listed as .99.
.wilson_critical_cvr <- function(N, alpha) {
  v <- stats::qnorm(1 - alpha) / sqrt(N)
  ifelse(v >= 1, .99, v)
}

# Anderson and Gerbing (1991, Equations 5 and 6): the fewest target
# assignments m with P(n_c >= m) < alpha when each judge picks the target with
# probability .5. Then critical csv = (m - (N - m)) / N, which assumes the N - m
# judges who miss the target all pick one rival. NA when no count of N judges
# can reach significance.
.ag_critical_count <- function(N, alpha) {
  vapply(N, function(n) {
    if (is.na(n) || n < 1L) return(NA_integer_)
    m <- 0:n
    ok <- m[stats::pbinom(m - 1L, n, .5, lower.tail = FALSE) < alpha]
    if (length(ok)) as.integer(min(ok)) else NA_integer_
  }, integer(1))
}

# Yao, Wu and Yang (2008, p. 486): Psa and Csv both at least .30, chosen for a
# four-domain sort, where an item assigned at random reaches its domain with
# probability .25.
.yao_cut <- .30

# A contentvalidR extension, not a published rule, approved by the maintainer
# and always labeled as one: Yao et al.'s reasoning carried to k constructs as
# chance plus .05, which is their .30 when k = 4. Undefined below two
# constructs, where chance is 1.
.yao_extension_cut <- function(k) {
  if (is.null(k) || is.na(k) || k < 2L) return(NA_real_)
  1 / k + .05
}

# Fleiss (1971): kappa for many raters assigning subjects to nominal
# categories. `ratings` has raters in rows and subjects in columns. Fleiss's
# formula needs the same raters on every subject, so a missing rating gives NA.
.fleiss_kappa <- function(ratings) {
  M <- as.matrix(ratings)
  if (anyNA(M) || nrow(M) < 2L || ncol(M) < 2L) return(NA_real_)
  n <- nrow(M)
  cats <- sort(unique(as.vector(M)))
  # Subjects in rows, categories in columns: how many raters chose each.
  counts <- vapply(cats, function(k) colSums(M == k), numeric(ncol(M)))
  counts <- matrix(counts, nrow = ncol(M))
  p_bar <- mean((rowSums(counts^2) - n) / (n * (n - 1)))
  p_e <- sum((colSums(counts) / (ncol(M) * n))^2)
  if (p_e >= 1) return(NA_real_)
  (p_bar - p_e) / (1 - p_e)
}

# Whether an estimate meets a published cutoff. The tolerance keeps a value
# that equals the cutoff in exact arithmetic, such as 7 of 8 for Lawshe's .75,
# from missing it through floating point.
.meets <- function(value, cut) {
  ifelse(is.na(value) | is.na(cut), NA, value >= cut - 1e-9)
}

.sort_earlier_methods <- function(results, alpha, n_constructs, show,
                                  constructs_given = FALSE) {
  m <- .ag_critical_count(results$n, alpha)
  # Compared as counts, n_c - n_o against 2m - N, so no rounding decides.
  ag <- ifelse(is.na(m) | results$n < 1L, NA,
               results$n_target - results$n_other_max >= 2L * m - results$n)
  ext_cut <- .yao_extension_cut(n_constructs)
  list(
    show = isTRUE(show),
    alpha = alpha,
    n_constructs = n_constructs,
    # Whether the analyst stated the number offered, or it was counted from
    # the constructs judges actually used, which can undercount.
    constructs_given = isTRUE(constructs_given),
    extension_cut = ext_cut,
    items = data.frame(
      item = results$item,
      target = results$target,
      n = results$n,
      psa = results$psa,
      csv = results$csv,
      decision = results$recommendation,
      ag_critical_n = m,
      ag_critical_csv = ifelse(is.na(m), NA_real_,
                               (2 * m - results$n) / results$n),
      ag_meets = ag,
      yao_meets = .meets(results$psa, .yao_cut) & .meets(results$csv, .yao_cut),
      extension_meets = .meets(results$psa, ext_cut) &
        .meets(results$csv, ext_cut),
      stringsAsFactors = FALSE
    )
  )
}

.essentiality_earlier_methods <- function(res, alpha, show) {
  lawshe_min <- .lawshe_minimum(res$N)
  wilson <- ifelse(res$N < 1L, NA_real_, .wilson_critical_cvr(res$N, alpha))
  lawshe_meets <- .meets(res$cvr, lawshe_min)
  retained <- which(lawshe_meets %in% TRUE)
  list(
    show = isTRUE(show),
    alpha = alpha,
    items = data.frame(
      item = res$item,
      N = res$N,
      ne = res$ne,
      cvr = res$cvr,
      decision = res$recommendation,
      lawshe_minimum = lawshe_min,
      lawshe_meets = lawshe_meets,
      wilson_critical = wilson,
      wilson_meets = .meets(res$cvr, wilson),
      stringsAsFactors = FALSE
    ),
    # Lawshe's CVI is the mean CVR of the items his table retains. It needs
    # his table to cover every item's panel size.
    lawshe_cvi = if (anyNA(lawshe_min) || !length(retained)) NA_real_ else
      mean(res$cvr[retained]),
    lawshe_n_retained = length(retained)
  )
}

.relevance_earlier_methods <- function(B, scale, show) {
  list(
    show = isTRUE(show),
    fleiss_kappa = .fleiss_kappa(B),
    complete = !anyNA(B),
    S_CVI_Ave = scale$S_CVI_Ave,
    S_CVI_UA = scale$S_CVI_UA
  )
}

# Whether to print the block: an explicit print() argument wins, then the
# choice made when the analysis ran. Objects saved before this existed print
# without it.
.show_earlier <- function(x, legacy) {
  if (!is.null(legacy)) {
    .validate_flag(legacy, "legacy")
    return(legacy)
  }
  em <- if (is.list(x$details)) x$details$earlier_methods else NULL
  isTRUE(em$show)
}

.verdict <- function(meets) {
  ifelse(is.na(meets), "n/a", ifelse(meets, "meets", "below"))
}

.earlier_heading <- function() {
  cat("\nEarlier methods, for comparison (not used for the decision)\n")
}

# An estimate can print as equal to its cutoff and still miss it, such as 8 of
# 9 experts (a CVR of .778) against Lawshe's .78. Say so with three decimals,
# so the table does not appear to contradict itself.
.rounding_note <- function(items, value, cut, meets, rule, digits) {
  hit <- which(meets %in% FALSE & .fmt(value, digits) == .fmt(cut, digits))
  if (!length(hit)) return(invisible(NULL))
  # One sentence per cutoff, since panel sizes can differ between items. A
  # published cutoff such as .78 is exact at two decimals; a computed one such
  # as Wilson's z/sqrt(N) gets three.
  for (c1 in unique(cut[hit])) {
    h <- hit[cut[hit] == c1]
    exact <- abs(round(c1, digits) - c1) < 1e-12
    shown_cut <- .fmt(c1, if (exact) digits else 3)
    .say(paste0(
      paste0(items[h], " (", .fmt(value[h], 3), ")", collapse = ", "),
      if (length(h) == 1L) " prints" else " print",
      " at the ", rule, " cutoff of ", shown_cut,
      " but ", if (length(h) == 1L) "falls" else "fall",
      " short of it before rounding."
    ))
  }
  invisible(NULL)
}

# How often an earlier rule agrees with the decision the workflow made.
.agreement_count <- function(meets, supported) {
  ok <- !is.na(meets) & !is.na(supported)
  c(agree = sum(meets[ok] == supported[ok]), of = sum(ok))
}

.print_sort_earlier <- function(em, digits) {
  it <- em$items
  if (is.null(it) || !nrow(it)) return(invisible(NULL))
  .earlier_heading()
  tab <- data.frame(item = it$item, decision = it$decision,
                    Psa = .fmt(it$psa, digits), Csv = .fmt(it$csv, digits),
                    stringsAsFactors = FALSE, check.names = FALSE)
  sizes <- unique(it$n[it$n >= 1L])
  if (length(sizes) > 1L) tab$`A&G critical` <- .fmt(it$ag_critical_csv, digits)
  tab$`A&G (1991)` <- .verdict(it$ag_meets)
  tab$`Yao et al. (2008)` <- .verdict(it$yao_meets)
  # The extension gets its own column only where it differs from Yao's .30.
  ext_cut <- em$extension_cut
  show_ext <- !is.null(ext_cut) && !is.na(ext_cut) &&
    abs(ext_cut - .yao_cut) > 1e-9
  if (show_ext) tab$`extension*` <- .verdict(it$extension_meets)
  .print_table(tab)
  cat("\n")

  alpha <- .fmt(em$alpha)
  worst_case <- paste(
    "Their critical value assumes every judge who misses the target picks the",
    "same rival. When those judges spread across several constructs, Csv can",
    "reach it with fewer target assignments than the exact test needs."
  )
  if (length(sizes) == 1L) {
    crit <- it$ag_critical_csv[it$n == sizes][1]
    .say(if (is.na(crit)) {
      paste0("Anderson and Gerbing (1991): with ", sizes, " judges no count ",
             "reaches significance at alpha = ", alpha, ", so their test ",
             "cannot be applied.")
    } else {
      paste0("Anderson and Gerbing (1991): Csv of at least ",
             .fmt(crit, digits), ", their critical value for ", sizes,
             " judges at alpha = ", alpha, " (Equations 5 and 6).")
    }, worst_case)
  } else {
    .say("Anderson and Gerbing (1991): Csv of at least the critical value for",
         "each item's number of judges at alpha =", paste0(alpha, "."),
         worst_case)
  }
  k <- em$n_constructs
  counted <- !isTRUE(em$constructs_given)
  .say("Yao, Wu and Yang (2008): Psa and Csv both at least .30, set for a",
       "four-domain sort where chance assignment is .25.")
  if (show_ext) {
    .say(paste0(
      "* extension: a contentvalidR extension, not a published rule. It ",
      "carries Yao et al.'s reasoning to this sort's ", k, " constructs as ",
      "chance plus .05, so Psa and Csv both at least ", .fmt(ext_cut, digits),
      " (1/", k, " + .05)."
    ), exdent = 2L)
  } else if (!is.null(ext_cut) && !is.na(ext_cut)) {
    .say("With 4 constructs, the contentvalidR extension of this rule to",
         "other numbers of constructs (chance plus .05) gives the same .30.")
  }
  if (counted && !is.null(ext_cut) && !is.na(ext_cut)) {
    .say(paste0(
      "The ", k, " constructs are the ones judges used. If more were offered, ",
      "set `n_constructs`, since chance depends on the number offered."
    ))
  }
  supported <- ifelse(it$decision %in% c("Retain", "Review"),
                      it$decision == "Retain", NA)
  ag <- .agreement_count(it$ag_meets, supported)
  yao <- .agreement_count(it$yao_meets, supported)
  ext <- .agreement_count(it$extension_meets, supported)
  .say(paste0("Agreement with the decision above: Anderson and Gerbing on ",
              ag[["agree"]], " of ", ag[["of"]], " items, Yao et al. on ",
              yao[["agree"]], " of ", yao[["of"]],
              if (show_ext) paste0(", the extension on ", ext[["agree"]],
                                   " of ", ext[["of"]]),
              "."))
  # Each cut applies to both indices; name whichever one rounding hides.
  .rounding_note(it$item, it$psa, rep(.yao_cut, nrow(it)),
                 .meets(it$psa, .yao_cut), "Yao et al. Psa", digits)
  .rounding_note(it$item, it$csv, rep(.yao_cut, nrow(it)),
                 .meets(it$csv, .yao_cut), "Yao et al. Csv", digits)
  if (show_ext) {
    .rounding_note(it$item, it$psa, rep(ext_cut, nrow(it)),
                   .meets(it$psa, ext_cut), "extension Psa", digits)
    .rounding_note(it$item, it$csv, rep(ext_cut, nrow(it)),
                   .meets(it$csv, ext_cut), "extension Csv", digits)
  }
  .say("Csv counts only the single most-chosen rival construct (Anderson &",
       "Gerbing, 1991, p. 734). Pooling every other construct into it instead",
       "gives twice Psa minus one, a different index.")
  invisible(NULL)
}

.print_essentiality_earlier <- function(em, digits) {
  it <- em$items
  if (is.null(it) || !nrow(it)) return(invisible(NULL))
  .earlier_heading()
  tab <- data.frame(item = it$item, decision = it$decision,
                    essential = paste0(it$ne, "/", it$N),
                    CVR = .fmt(it$cvr, digits),
                    stringsAsFactors = FALSE, check.names = FALSE)
  sizes <- unique(it$N[it$N >= 1L])
  if (length(sizes) > 1L) {
    tab$`Lawshe min` <- .fmt(it$lawshe_minimum, digits)
    tab$`Wilson min` <- .fmt(it$wilson_critical, digits)
  }
  tab$`Lawshe (1975)` <- .verdict(it$lawshe_meets)
  tab$`Wilson et al. (2012)` <- .verdict(it$wilson_meets)
  .print_table(tab)
  cat("\n")

  alpha <- .fmt(em$alpha)
  if (length(sizes) == 1L) {
    lmin <- it$lawshe_minimum[1]
    .say(if (is.na(lmin)) {
      paste0("Lawshe (1975, Table 1) lists no minimum for ", sizes,
             " panelists; the table covers 5 to 15, then every fifth size to ",
             "40.")
    } else {
      paste0("Lawshe (1975, Table 1): minimum CVR ", .fmt(lmin, digits),
             " for ", sizes, " panelists, labeled a one-tailed test at .05. ",
             "Wilson, Pan and Schumsky (2012) found the table closer to a ",
             "two-tailed test.")
    })
    .say(paste0("Wilson et al. (2012, Table 2): minimum CVR ",
                .fmt(it$wilson_critical[1], digits), ", the normal ",
                "approximation z/sqrt(N) at one-tailed alpha = ", alpha, "."))
  } else {
    .say("Lawshe (1975, Table 1) and Wilson et al. (2012, Table 2) set the",
         "minimum CVR by panel size, so each item's minimum is shown. Lawshe",
         "labeled his a one-tailed test at .05; Wilson, Pan and Schumsky",
         "(2012) found it closer to a two-tailed test. Wilson's is z/sqrt(N)",
         "at one-tailed alpha =", paste0(alpha, "."))
  }
  .rounding_note(it$item, it$cvr, it$lawshe_minimum, it$lawshe_meets,
                 "Lawshe", digits)
  .rounding_note(it$item, it$cvr, it$wilson_critical, it$wilson_meets,
                 "Wilson et al.", digits)
  .say("The decision above uses the exact binomial test (Ayre & Scally,",
       "2014).")
  .say(if (!is.na(em$lawshe_cvi)) {
    paste0("Lawshe's content validity index, the mean CVR of the items his ",
           "table retains: ", .fmt(em$lawshe_cvi, digits), " (",
           em$lawshe_n_retained, " item", if (em$lawshe_n_retained != 1L) "s",
           ").")
  } else if (anyNA(it$lawshe_minimum)) {
    paste("Lawshe's content validity index needs his table to cover every",
          "panel size here, so it is not shown.")
  } else {
    paste("Lawshe's content validity index is not defined here: no item met",
          "his minimum.")
  })
  invisible(NULL)
}

.print_relevance_earlier <- function(em, digits) {
  .earlier_heading()
  .say(paste0(
    "Fleiss' (1971) kappa on the relevant/not-relevant decision: ",
    if (!isTRUE(em$complete)) {
      "not computed, because it needs every expert to rate every item."
    } else if (is.na(em$fleiss_kappa)) {
      "undefined, because every decision was the same."
    } else {
      paste0(.fmt(em$fleiss_kappa, digits), ".")
    }
  ))
  .say(paste0(
    "S-CVI/Ave (", .fmt(em$S_CVI_Ave, digits), ") is the same index as the ",
    "average congruency percentage. Polit and Beck (2006) recommend .90 or ",
    "higher for it, and call .80 a reasonable, even strict, criterion for ",
    "S-CVI/UA (", .fmt(em$S_CVI_UA, digits), ")."
  ))
  invisible(NULL)
}

# Krippendorff's alpha, computed from the coincidence matrix as set out in
# Krippendorff (2011), "Computing Krippendorff's Alpha-Reliability".
# `X` has raters in rows and units (items) in columns, matching expert_validity().

.alpha_levels <- c("ordinal", "nominal", "interval")

.coincidence_matrix <- function(X) {
  values <- sort(unique(as.vector(X[!is.na(X)])))
  k <- length(values)
  o <- matrix(0, nrow = k, ncol = k, dimnames = list(values, values))
  n_units <- 0L
  n_pairs <- 0

  for (u in seq_len(ncol(X))) {
    x <- X[!is.na(X[, u]), u]
    m <- length(x)
    # A lone value in a unit cannot be paired, so it contributes nothing.
    if (m < 2L) next
    counts <- tabulate(match(x, values), nbins = k)
    pairs <- outer(counts, counts)
    diag(pairs) <- counts * (counts - 1)
    o <- o + pairs / (m - 1)
    n_units <- n_units + 1L
    n_pairs <- n_pairs + m * (m - 1) / 2
  }

  list(o = o, values = values, n_units = n_units, n_pairs = n_pairs)
}

.alpha_delta <- function(values, n_c, level) {
  k <- length(values)
  if (level == "nominal") return(1 - diag(k))
  if (level == "interval") return(outer(values, values, function(a, b) (a - b)^2))

  # Ordinal: squared rank distance measured in pairable-value frequencies,
  # summing every category from c through k inclusive.
  d <- matrix(0, nrow = k, ncol = k)
  for (i in seq_len(k)) {
    for (j in seq_len(k)) {
      if (i == j) next
      span <- min(i, j):max(i, j)
      d[i, j] <- (sum(n_c[span]) - (n_c[i] + n_c[j]) / 2)^2
    }
  }
  d
}

.alpha_from_coincidence <- function(o, values, level) {
  n_c <- rowSums(o)
  n <- sum(n_c)
  if (length(values) < 1L || n < 2) return(NA_real_)
  delta <- .alpha_delta(values, n_c, level)
  d_observed <- sum(o * delta) / n
  d_expected <- sum(outer(n_c, n_c) * delta) / (n * (n - 1))
  # With no variation among pairable values there is no disagreement to
  # expect, and alpha is undefined rather than zero.
  if (!is.finite(d_expected) || d_expected <= 0) return(NA_real_)
  1 - d_observed / d_expected
}

.krippendorff_alpha <- function(X, level) {
  cm <- .coincidence_matrix(X)
  list(
    estimate = .alpha_from_coincidence(cm$o, cm$values, level),
    coincidence = cm$o,
    n_units = cm$n_units,
    n_pairs = cm$n_pairs,
    n_values = sum(cm$o)
  )
}

# Shared by panel_agreement() and expert_validity(), which name the resample
# count differently.
.validate_bootstrap_args <- function(B, seed, B_name = "B") {
  if (!is.numeric(B) || length(B) != 1L || !is.finite(B) || B < 0 || B != floor(B)) {
    stop("`", B_name, "` must be one non-negative integer; use 0 to skip the interval.",
         call. = FALSE)
  }
  if (!is.null(seed) && (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed))) {
    stop("`seed` must be NULL or one number.", call. = FALSE)
  }
  invisible(TRUE)
}

.agreement_label <- function(method, level) {
  if (method == "krippendorff") paste0("Krippendorff's alpha (", level, ")") else "Gwet's AC1"
}

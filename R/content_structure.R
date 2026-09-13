.choose2 <- function(x) x * (x - 1) / 2

# Adjusted Rand index between two partitions of the same items. Chance-corrected
# so that agreement no better than random assignment scores about 0.
.adjusted_rand <- function(a, b) {
  ok <- !is.na(a) & !is.na(b)
  a <- a[ok]
  b <- b[ok]
  n <- length(a)
  if (n < 2L) return(NA_real_)

  tab <- table(a, b)
  sum_ij <- sum(.choose2(as.vector(tab)))
  sum_a <- sum(.choose2(rowSums(tab)))
  sum_b <- sum(.choose2(colSums(tab)))
  total <- .choose2(n)
  if (total <= 0) return(NA_real_)

  expected <- sum_a * sum_b / total
  maximum <- 0.5 * (sum_a + sum_b)
  if (abs(maximum - expected) < .Machine$double.eps^0.5) return(NA_real_)
  (sum_ij - expected) / (maximum - expected)
}

.stress1 <- function(d_orig, d_fit) {
  num <- sum((d_orig - d_fit)^2)
  den <- sum(d_orig^2)
  if (!is.finite(den) || den <= 0) return(NA_real_)
  sqrt(num / den)
}

.stress_label <- function(s) {
  # Kruskal's conventional descriptors. These are long-standing conventions for
  # describing fit, not decision rules.
  ifelse(is.na(s), NA_character_,
         ifelse(s < 0.025, "excellent",
                ifelse(s < 0.05, "good",
                       ifelse(s < 0.10, "fair",
                              ifelse(s < 0.20, "poor", "very poor")))))
}

.as_item_distance <- function(similarity, is_distance) {
  M <- as.matrix(similarity)
  if (!is.numeric(M)) stop("`similarity` must be numeric.", call. = FALSE)
  if (nrow(M) != ncol(M)) {
    stop("`similarity` must be a square item-by-item matrix.", call. = FALSE)
  }
  if (nrow(M) < 3L) {
    stop("`similarity` must cover at least three items.", call. = FALSE)
  }
  if (any(is.na(M))) {
    stop("`similarity` cannot contain missing values.", call. = FALSE)
  }
  if (any(is.infinite(M))) {
    stop("`similarity` cannot contain infinite values.", call. = FALSE)
  }
  if (max(abs(M - t(M))) > 1e-8) {
    stop("`similarity` must be symmetric.", call. = FALSE)
  }
  if (is.null(rownames(M))) rownames(M) <- paste0("Item", seq_len(nrow(M)))
  colnames(M) <- rownames(M)

  D <- if (isTRUE(is_distance)) M else max(M) - M
  diag(D) <- 0
  if (any(D < 0)) {
    stop("Converted distances are negative; check `similarity_is_distance`.",
         call. = FALSE)
  }
  D
}

#' Item-similarity structure of a content domain
#'
#' @description
#' Analyzes whether subject-matter experts perceive items as grouping the way a
#' test blueprint says they should, using the multidimensional scaling and
#' cluster analysis procedure of Sireci and Geisinger (1992, 1995).
#'
#' Experts rate how similar each pair of items is. Those similarities are scaled
#' into a low-dimensional content map and clustered. If the blueprint describes
#' the domain as experts actually see it, the recovered clusters should
#' correspond to the blueprint's cells. Agreement is quantified with the
#' adjusted Rand index, which is corrected for chance so that a value near 0
#' means no better than random correspondence.
#'
#' This is evidence about perceived content *structure*. It is not evidence that
#' the items cover the domain: see [domain_validity()] for coverage.
#'
#' @param similarity A square, symmetric item-by-item matrix of expert
#'   similarity ratings, or a distance matrix when `similarity_is_distance` is
#'   `TRUE`. Similarities are converted to distances as `max(similarity) -
#'   similarity`.
#' @param membership Optional blueprint cell for each item, as a vector in the
#'   same order as the rows of `similarity`, or named by item. When supplied,
#'   the recovered clustering is compared against it.
#' @param k Number of clusters to extract. Defaults to the number of distinct
#'   blueprint cells, or 2 when no blueprint is supplied.
#' @param dims Number of multidimensional scaling dimensions to retain.
#' @param max_dims Largest dimensionality reported in the fit table.
#' @param similarity_is_distance Set `TRUE` when `similarity` already holds
#'   distances rather than similarities.
#'
#' @return An object of class `contentvalid_structure`, a list containing the
#'   MDS `coordinates`, `clusters`, the `fit` table across dimensionalities, the
#'   `stress` and `gof` of the retained solution, the `adjusted_rand` index and
#'   `cross_tab` against the blueprint, `settings`, `design`, `status`, and an
#'   `interpretation`.
#'
#' @section Dimensionality:
#' The retained dimensionality is reported rather than chosen silently. The
#' `fit` table gives Kruskal stress-1 for every dimensionality up to `max_dims`,
#' with the conventional descriptive labels. Those labels are long-standing
#' conventions for describing fit, not thresholds that decide how many
#' dimensions a content domain has. Substantive interpretability of the
#' dimensions should drive that choice.
#'
#' @references
#' Sireci, S. G., & Geisinger, K. F. (1992). Analyzing test content using
#' cluster analysis and multidimensional scaling. *Applied Psychological
#' Measurement, 16*(1), 17-31. \doi{10.1177/014662169201600102}
#'
#' Sireci, S. G., & Geisinger, K. F. (1995). Using subject-matter experts to
#' assess content representation: An MDS analysis. *Applied Psychological
#' Measurement, 19*(3), 241-255. \doi{10.1177/014662169501900303}
#'
#' Sireci, S. G. (1998). The construct of content validity. *Social Indicators
#' Research, 45*(1-3), 83-117. \doi{10.1023/A:1006985528729}
#'
#' Hubert, L., & Arabie, P. (1985). Comparing partitions. *Journal of
#' Classification, 2*(1), 193-218. \doi{10.1007/BF01908075}
#'
#' @seealso [similarity_from_sort()] to derive similarities from an item-sort
#'   task, and [domain_validity()] for the combined coverage-and-structure
#'   workflow.
#'
#' @examples
#' items <- paste0("I", 1:6)
#' blueprint <- c(rep("Autonomy", 3), rep("Competence", 3))
#' sim <- matrix(1, 6, 6, dimnames = list(items, items))
#' sim[1:3, 1:3] <- 5
#' sim[4:6, 4:6] <- 5
#' diag(sim) <- 5
#' content_structure(sim, membership = blueprint)
#' @export
content_structure <- function(similarity,
                              membership = NULL,
                              k = NULL,
                              dims = 2,
                              max_dims = 5,
                              similarity_is_distance = FALSE) {
  .validate_flag(similarity_is_distance, "similarity_is_distance")

  D <- .as_item_distance(similarity, similarity_is_distance)
  items <- rownames(D)
  n_items <- length(items)

  if (!is.numeric(dims) || length(dims) != 1L || !is.finite(dims) ||
      dims < 1 || dims != floor(dims) || dims >= n_items) {
    stop("`dims` must be one integer between 1 and the number of items minus one.",
         call. = FALSE)
  }
  if (!is.numeric(max_dims) || length(max_dims) != 1L || !is.finite(max_dims) ||
      max_dims < 1 || max_dims != floor(max_dims)) {
    stop("`max_dims` must be one positive integer.", call. = FALSE)
  }
  max_dims <- min(as.integer(max_dims), n_items - 1L)

  # A similarity matrix supports only as many dimensions as it has positive
  # eigenvalues. Requesting more makes cmdscale warn and return padding columns,
  # so the usable rank is determined once and reported rather than suppressed.
  eig_all <- suppressWarnings(
    stats::cmdscale(stats::as.dist(D), k = n_items - 1L, eig = TRUE)$eig
  )
  n_available <- max(1L, sum(eig_all > max(eig_all[1], 0) * 1e-8))
  max_dims <- min(max_dims, n_available)
  dims_requested <- as.integer(dims)
  dims <- min(dims_requested, n_available)

  if (!is.null(membership)) {
    if (!is.null(names(membership)) && all(items %in% names(membership))) {
      membership <- membership[items]
    }
    if (length(membership) != n_items) {
      stop("`membership` must have one entry per item.", call. = FALSE)
    }
    membership <- as.character(membership)
    .validate_labels(membership, "membership", allow_na = TRUE)
  }

  n_cells <- if (is.null(membership)) NA_integer_ else length(unique(membership[!is.na(membership)]))
  if (is.null(k)) k <- if (is.na(n_cells) || n_cells < 2L) 2L else n_cells
  if (!is.numeric(k) || length(k) != 1L || !is.finite(k) || k < 1 ||
      k != floor(k) || k > n_items) {
    stop("`k` must be one integer between 1 and the number of items.", call. = FALSE)
  }
  k <- as.integer(k)

  dobj <- stats::as.dist(D)

  fit_rows <- lapply(seq_len(max_dims), function(kd) {
    sol <- try(suppressWarnings(stats::cmdscale(dobj, k = kd, eig = TRUE)),
               silent = TRUE)
    if (inherits(sol, "try-error")) {
      return(data.frame(dims = kd, stress = NA_real_, gof = NA_real_,
                        stringsAsFactors = FALSE))
    }
    pts <- sol$points
    if (is.null(dim(pts))) pts <- matrix(pts, ncol = 1L)
    s <- .stress1(as.vector(dobj), as.vector(stats::dist(pts)))
    data.frame(dims = kd, stress = s,
               gof = if (length(sol$GOF)) sol$GOF[1] else NA_real_,
               stringsAsFactors = FALSE)
  })
  fit <- do.call(rbind, fit_rows)
  fit$fit_label <- .stress_label(fit$stress)
  rownames(fit) <- NULL

  sol <- suppressWarnings(stats::cmdscale(dobj, k = dims, eig = TRUE))
  pts <- sol$points
  if (is.null(dim(pts))) pts <- matrix(pts, ncol = 1L)
  rownames(pts) <- items
  colnames(pts) <- paste0("Dim", seq_len(ncol(pts)))

  retained_stress <- fit$stress[fit$dims == dims]
  retained_gof <- fit$gof[fit$dims == dims]

  hc <- stats::hclust(dobj, method = "average")
  cluster <- stats::cutree(hc, k = k)

  clusters <- data.frame(
    item = items,
    cluster = as.integer(cluster),
    stringsAsFactors = FALSE
  )
  if (!is.null(membership)) clusters$blueprint_cell <- membership
  clusters <- cbind(clusters, as.data.frame(pts))
  rownames(clusters) <- NULL

  ari <- NA_real_
  cross_tab <- NULL
  if (!is.null(membership)) {
    ari <- .adjusted_rand(membership, cluster)
    cross_tab <- table(blueprint = membership, cluster = cluster)
  }

  status <- if (is.null(membership)) {
    "Descriptive only"
  } else if (is.na(ari)) {
    "Insufficient data"
  } else if (ari >= 0.60) {
    "Supported"
  } else {
    "Review"
  }

  interpretation <- if (is.null(membership)) {
    paste(
      "No blueprint was supplied, so the recovered structure is reported",
      "descriptively. Supply `membership` to test whether experts group the",
      "items the way the blueprint says they should."
    )
  } else if (is.na(ari)) {
    paste(
      "Correspondence with the blueprint could not be quantified. This happens",
      "when every item falls in one blueprint cell or one cluster, leaving",
      "nothing to compare."
    )
  } else if (ari >= 0.60) {
    sprintf(paste(
      "Expert-perceived item groupings correspond closely to the blueprint",
      "(adjusted Rand index %.2f, where 0 is chance agreement and 1 is exact).",
      "This supports the claim that the blueprint describes the domain as",
      "subject-matter experts see it."
    ), ari)
  } else {
    sprintf(paste(
      "Expert-perceived item groupings correspond only weakly to the blueprint",
      "(adjusted Rand index %.2f, where 0 is chance agreement and 1 is exact).",
      "Inspect the cross-tabulation to see which cells experts merged or split.",
      "This is a reason to re-examine the blueprint or the item wording, not by",
      "itself a reason to delete items: experts may be responding to surface",
      "features such as shared vocabulary rather than the intended facets."
    ), ari)
  }

  out <- list(
    coordinates = pts,
    clusters = clusters,
    fit = fit,
    stress = if (length(retained_stress)) retained_stress else NA_real_,
    gof = if (length(retained_gof)) retained_gof else NA_real_,
    adjusted_rand = ari,
    cross_tab = cross_tab,
    hclust = hc,
    settings = list(
      method = "Sireci-Geisinger MDS with hierarchical cluster analysis",
      dims = as.integer(dims),
      dims_requested = dims_requested,
      k = k,
      max_dims = max_dims,
      cluster_method = "average linkage",
      similarity_is_distance = isTRUE(similarity_is_distance)
    ),
    design = list(
      type = "expert item-similarity structure",
      n_items = n_items,
      n_blueprint_cells = n_cells,
      n_dimensions_available = n_available
    ),
    status = status,
    interpretation = interpretation
  )
  class(out) <- "contentvalid_structure"
  out
}

#' @export
print.contentvalid_structure <- function(x, digits = 3, ...) {
  .validate_digits(digits)
  cat("Expert item-similarity content structure\n")
  cat(sprintf("Items: %d   Dimensions retained: %d   Clusters: %d\n",
              x$design$n_items, x$settings$dims, x$settings$k))
  if (x$settings$dims < x$settings$dims_requested) {
    cat(sprintf(paste0(
      "Requested %d dimensions, but these similarities support only %d.\n",
      "The solution uses %d.\n"),
      x$settings$dims_requested, x$design$n_dimensions_available, x$settings$dims))
  }
  cat(sprintf("Stress (Kruskal-1): %s (%s)\n",
              format(round(x$stress, digits)), x$fit$fit_label[x$fit$dims == x$settings$dims]))

  cat("\nFit by dimensionality\n")
  f <- x$fit
  f$stress <- round(f$stress, digits)
  f$gof <- round(f$gof, digits)
  print(f, row.names = FALSE)

  if (!is.null(x$cross_tab)) {
    cat("\nBlueprint cell by recovered cluster\n")
    print(x$cross_tab)
    cat(sprintf("\nAdjusted Rand index: %s\n", format(round(x$adjusted_rand, digits))))
  }

  cat("\nStatus: ", x$status, "\n", sep = "")
  cat(strwrap(x$interpretation, width = 76), sep = "\n")
  cat("\nStress labels are descriptive conventions, not rules for deciding",
      "\nhow many dimensions a content domain has.\n")
  invisible(x)
}

#' Derive item similarities from an item-sort task
#'
#' @description
#' Builds an item-by-item similarity matrix from item-sort data, where the
#' similarity of two items is the proportion of judges who assigned them to the
#' same construct.
#'
#' This lets [content_structure()] be used when a study collected a sorting task
#' rather than the pairwise similarity ratings of Sireci and Geisinger (1992).
#'
#' @param assignments A long-format data frame of sort assignments.
#' @param item_col,rater_col,assigned_col Column names.
#'
#' @return A square, symmetric item-by-item matrix of co-assignment proportions,
#'   with attribute `"n_pairs"` giving the number of judges contributing to each
#'   cell.
#'
#' @section Weaker evidence than a similarity task:
#' Co-assignment similarity is coarser than a direct similarity rating. A sort
#' forces every item into exactly one construct, so two items placed in
#' different constructs record zero similarity no matter how closely related a
#' judge considers them, and the recovered structure is constrained toward the
#' construct set the sorting task offered. Structure recovered this way is
#' evidence about how judges sorted, which is a weaker basis for claims about
#' perceived content structure than pairwise similarity ratings collected for
#' that purpose.
#'
#' @references
#' Sireci, S. G., & Geisinger, K. F. (1992). Analyzing test content using
#' cluster analysis and multidimensional scaling. *Applied Psychological
#' Measurement, 16*(1), 17-31. \doi{10.1177/014662169201600102}
#'
#' @examples
#' sorts <- data.frame(
#'   item = rep(paste0("I", 1:4), each = 5),
#'   rater = rep(1:5, times = 4),
#'   assigned_construct = c(rep("A", 5), rep("A", 5), rep("B", 5), rep("B", 5))
#' )
#' similarity_from_sort(sorts)
#' @export
similarity_from_sort <- function(assignments,
                                 item_col = "item",
                                 rater_col = "rater",
                                 assigned_col = "assigned_construct") {
  .validate_column_names(item_col, rater_col, assigned_col)
  if (!is.data.frame(assignments) || !nrow(assignments)) {
    stop("`assignments` must be a data.frame with at least one row.", call. = FALSE)
  }
  missing_cols <- setdiff(c(item_col, rater_col, assigned_col), names(assignments))
  if (length(missing_cols)) {
    stop("`assignments` is missing required column(s): ",
         paste(missing_cols, collapse = ", "), ".", call. = FALSE)
  }

  d <- assignments[, c(item_col, rater_col, assigned_col), drop = FALSE]
  names(d) <- c("item", "rater", "assigned")
  .validate_labels(d$item, "item")
  .validate_labels(d$rater, "rater")
  d$item <- as.character(d$item)
  d$rater <- as.character(d$rater)
  d$assigned <- as.character(d$assigned)

  if (anyDuplicated(d[c("item", "rater")])) {
    stop("Each item-rater pair must appear only once.", call. = FALSE)
  }

  items <- sort(unique(d$item))
  raters <- unique(d$rater)
  n_items <- length(items)
  if (n_items < 3L) {
    stop("At least three items are required to build a similarity matrix.",
         call. = FALSE)
  }

  wide <- matrix(NA_character_, nrow = length(raters), ncol = n_items,
                 dimnames = list(raters, items))
  wide[cbind(match(d$rater, raters), match(d$item, items))] <- d$assigned

  same <- matrix(0, n_items, n_items, dimnames = list(items, items))
  pairs <- matrix(0L, n_items, n_items, dimnames = list(items, items))
  for (r in seq_len(nrow(wide))) {
    row <- wide[r, ]
    obs <- !is.na(row)
    if (sum(obs) < 2L) next
    idx <- which(obs)
    agree <- outer(row[idx], row[idx], "==")
    same[idx, idx] <- same[idx, idx] + agree
    pairs[idx, idx] <- pairs[idx, idx] + 1L
  }

  sim <- ifelse(pairs > 0L, same / pairs, NA_real_)
  diag(sim) <- 1
  if (any(is.na(sim))) {
    stop("Some item pairs were never sorted by a common judge, so their ",
         "similarity is undefined.", call. = FALSE)
  }
  attr(sim, "n_pairs") <- pairs
  sim
}

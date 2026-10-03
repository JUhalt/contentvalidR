.choose2 <- function(x) x * (x - 1) / 2

# Adjusted Rand index between two partitions of the same items. Chance-corrected
# so that agreement no better than random assignment scores about 0.
.adjusted_rand <- function(a, b) {
  ok <- !is.na(a) & !is.na(b)
  a <- a[ok]
  b <- b[ok]
  n <- length(a)
  if (n < 2L) return(NA_real_)

  # One group on either side leaves nothing to compare: the index would be 0
  # whatever the other partition is, which reads as "no better than chance".
  if (length(unique(a)) < 2L || length(unique(b)) < 2L) return(NA_real_)

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

# How far the map's distances depart from the dissimilarities, as a share of
# the dissimilarities. This is not Kruskal's (1964) stress-1: his compares the
# map distances with disparities from a monotone regression, over the squared
# map distances, for a configuration fitted to minimize it. Classical scaling
# does none of that, so his verbal benchmarks do not apply here and no label
# is attached.
.raw_stress <- function(d_orig, d_fit) {
  num <- sum((d_orig - d_fit)^2)
  den <- sum(d_orig^2)
  if (!is.finite(den) || den <= 0) return(NA_real_)
  sqrt(num / den)
}

.as_item_distance <- function(similarity, is_distance) {
  M <- as.matrix(.untag_component(similarity))
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
  if (all(D == 0)) {
    stop("Every pair of items is equally similar, so there is no structure ",
         "to scale or cluster. Check `similarity`.", call. = FALSE)
  }
  D
}

#' Item-similarity structure of a content domain
#'
#' @description
#' Analyzes whether subject-matter experts perceive items as grouping the way a
#' test blueprint says they should, with multidimensional scaling followed by
#' a cluster analysis of the item coordinates, adapted from Sireci and
#' Geisinger (1992, 1995).
#'
#' Experts rate how similar each pair of items is. Those similarities are scaled
#' into a low-dimensional content map, and the items' coordinates on that map
#' are clustered. If the blueprint describes the domain as experts actually see
#' it, the recovered clusters should correspond to the blueprint's cells.
#' Agreement is quantified with the adjusted Rand index (Hubert & Arabie,
#' 1985), which is corrected for chance so that a value near 0 means no better
#' than random correspondence.
#'
#' This is evidence about perceived content *structure*. It is not evidence that
#' the items cover the domain: see [domain_validity()] for coverage.
#'
#' @section What is published and what is this package's choice:
#' Sireci and Geisinger scaled the experts' similarity ratings and then ran a
#' hierarchical cluster analysis on the items' scaling coordinates.
#' `content_structure()` does the same, so the clusters depend on the number
#' of dimensions retained. Four things differ from their procedure or are not
#' stated in it, and are this package's choices:
#'
#' * In their 1995 study they scaled each expert's matrix with an
#'   individual-differences model (INDSCAL). This function applies classical
#'   scaling to one similarity matrix, usually the experts' mean ratings.
#' * The clusters are formed with average linkage.
#' * They read the correspondence with the blueprint from the cluster table
#'   and from regressions of relevance ratings on the coordinates. The
#'   adjusted Rand index is added here to put a number on that
#'   correspondence.
#' * The status rests on `ari_cut`. No published standard says how large an
#'   adjusted Rand index must be, so the default, .60, is a contentvalidR
#'   convention. It is printed beside the status so a reader can apply
#'   another.
#'
#' Versions before 1.0 clustered the original dissimilarities, not the
#' coordinates, so the number of dimensions had no effect on the clusters.
#'
#' @param similarity A square, symmetric item-by-item matrix of expert
#'   similarity ratings, or a distance matrix when `similarity_is_distance` is
#'   `TRUE`. Similarities are converted to distances as `max(similarity) -
#'   similarity`.
#' @param membership Optional blueprint cell for each item, as a vector in the
#'   same order as the rows of `similarity`, or named by item. When it has
#'   names, they must be the item names: a vector whose names do not match
#'   the items is an error, never read by position. When supplied, the
#'   recovered clustering is compared against it.
#' @param k Number of clusters to extract. Defaults to the number of distinct
#'   blueprint cells, or 2 when no blueprint is supplied.
#' @param dims Number of multidimensional scaling dimensions to retain. The
#'   clusters are formed from the coordinates on these dimensions.
#' @param max_dims Largest dimensionality reported in the fit table.
#' @param similarity_is_distance Set `TRUE` when `similarity` already holds
#'   distances rather than similarities.
#' @param ari_cut Adjusted Rand index at or above which the status is
#'   `"Supported"`. Default .60, a contentvalidR convention.
#'
#' @return An object of class `contentvalid_structure`, a list containing the
#'   MDS `coordinates`, `clusters`, the `fit` table across dimensionalities, the
#'   `stress` and `gof` of the retained solution, the `adjusted_rand` index and
#'   `cross_tab` against the blueprint, `settings`, `design`, `status`, and an
#'   `interpretation`. `status` is `"Supported"` or `"Review"` by `ari_cut`,
#'   `"Descriptive only"` without a blueprint, and `"Insufficient data"` when
#'   the blueprint or the clustering has a single group, which leaves nothing
#'   to compare.
#'
#' @section Dimensionality:
#' The retained dimensionality is reported rather than chosen silently. For
#' every dimensionality up to `max_dims`, the `fit` table gives two measures
#' of how well the map reproduces the similarities. `gof` is the goodness of
#' fit of classical scaling: the share of the sum of the absolute eigenvalues
#' that the retained dimensions account for. `stress`, printed as
#' "distortion", is the root of the squared differences between the
#' dissimilarities and the map distances, over the squared dissimilarities;
#' 0 is an exact map. It need not fall as dimensions are added, because
#' classical scaling does not minimize it.
#'
#' That `stress` is not Kruskal's (1964) stress-1, which compares the map
#' distances with monotonically transformed dissimilarities in a nonmetric
#' solution fitted to minimize it. His verbal benchmarks ("good", "fair",
#' "poor") were given for that quantity and are not applied here. Versions
#' before 1.0 printed this statistic as "Kruskal stress-1" with those labels.
#' Substantive interpretability of the dimensions should drive the choice of
#' dimensionality.
#'
#' @references
#' Hubert, L., & Arabie, P. (1985). Comparing partitions. *Journal of
#' Classification, 2*(1), 193–218. \doi{10.1007/BF01908075}
#'
#' Kruskal, J. B. (1964). Multidimensional scaling by optimizing goodness of
#' fit to a nonmetric hypothesis. *Psychometrika, 29*(1), 1–27.
#' \doi{10.1007/BF02289565}
#'
#' Sireci, S. G., & Geisinger, K. F. (1992). Analyzing test content using
#' cluster analysis and multidimensional scaling. *Applied Psychological
#' Measurement, 16*(1), 17–31. \doi{10.1177/014662169201600102}
#'
#' Sireci, S. G., & Geisinger, K. F. (1995). Using subject-matter experts to
#' assess content representation: An MDS analysis. *Applied Psychological
#' Measurement, 19*(3), 241–255. \doi{10.1177/014662169501900303}
#'
#' @seealso [similarity_from_sort()] to derive similarities from an item-sort
#'   task, and [domain_validity()] for the combined coverage-and-structure
#'   workflow.
#'
#' @examples
#' # Mean similarity ratings (1 = unlike, 5 = alike) for nine items written
#' # for three blueprint cells.
#' items <- paste0("I", 1:9)
#' blueprint <- rep(c("Autonomy", "Competence", "Relatedness"), each = 3)
#' sim <- matrix(c(
#'   5, 4, 3, 2, 2, 1, 1, 2, 1,
#'   4, 5, 4, 3, 1, 2, 2, 1, 1,
#'   3, 4, 5, 1, 2, 2, 1, 1, 3,
#'   2, 3, 1, 5, 4, 3, 2, 2, 1,
#'   2, 1, 2, 4, 5, 4, 1, 3, 2,
#'   1, 2, 2, 3, 4, 5, 2, 1, 2,
#'   1, 2, 1, 2, 1, 2, 5, 3, 4,
#'   2, 1, 1, 2, 3, 1, 3, 5, 4,
#'   1, 1, 3, 1, 2, 2, 4, 4, 5
#' ), 9, 9, dimnames = list(items, items))
#' content_structure(sim, membership = blueprint)
#' @export
content_structure <- function(similarity,
                              membership = NULL,
                              k = NULL,
                              dims = 2,
                              max_dims = 5,
                              similarity_is_distance = FALSE,
                              ari_cut = 0.60) {
  .validate_flag(similarity_is_distance, "similarity_is_distance")
  if (!is.numeric(ari_cut) || length(ari_cut) != 1L || !is.finite(ari_cut) ||
      ari_cut <= 0 || ari_cut > 1) {
    stop("`ari_cut` must be one number above 0 and at most 1.", call. = FALSE)
  }

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
    if (is.factor(membership)) {
      membership <- stats::setNames(as.character(membership), names(membership))
    }
    if (!is.null(names(membership))) {
      # Names are a claim about which item each entry belongs to. If they do
      # not cover the items, reading the vector by position would silently
      # reorder the blueprint.
      missing_items <- setdiff(items, names(membership))
      if (length(missing_items)) {
        stop("`membership` is named, but its names do not include item(s): ",
             paste(missing_items[seq_len(min(5L, length(missing_items)))],
                   collapse = ", "),
             if (length(missing_items) > 5L) {
               paste0(" and ", length(missing_items) - 5L, " more")
             },
             ". Name it by the items in `similarity`, or remove the names to ",
             "match by position.", call. = FALSE)
      }
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
    s <- .raw_stress(as.vector(dobj), as.vector(stats::dist(pts)))
    data.frame(dims = kd, stress = s,
               gof = if (length(sol$GOF)) sol$GOF[1] else NA_real_,
               stringsAsFactors = FALSE)
  })
  fit <- do.call(rbind, fit_rows)
  rownames(fit) <- NULL

  sol <- suppressWarnings(stats::cmdscale(dobj, k = dims, eig = TRUE))
  pts <- sol$points
  if (is.null(dim(pts))) pts <- matrix(pts, ncol = 1L)
  rownames(pts) <- items
  colnames(pts) <- paste0("Dim", seq_len(ncol(pts)))

  retained_stress <- fit$stress[fit$dims == dims]
  retained_gof <- fit$gof[fit$dims == dims]

  # The items' coordinates on the retained dimensions are what is clustered,
  # as in Sireci and Geisinger (1992, 1995); average linkage is this
  # package's choice. So the clusters belong to the map that is reported and
  # plotted.
  hc <- stats::hclust(stats::dist(pts), method = "average")
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
  } else if (ari >= ari_cut) {
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
  } else if (ari >= ari_cut) {
    sprintf(paste(
      "Expert-perceived item groupings correspond to the blueprint (adjusted",
      "Rand index %s, where 0 is chance agreement and 1 is exact; at or above",
      "the %s set for this analysis). This supports the claim that the",
      "blueprint describes the domain as subject-matter experts see it."
    ), .fmt_beside_cut(ari, ari_cut), .fmt(ari_cut))
  } else {
    sprintf(paste(
      "Expert-perceived item groupings fall short of the blueprint (adjusted",
      "Rand index %s, where 0 is chance agreement and 1 is exact; below the",
      "%s set for this analysis).",
      "Inspect the cross-tabulation to see which cells experts merged or split.",
      "This is a reason to re-examine the blueprint or the item wording, not by",
      "itself a reason to delete items: experts may be responding to surface",
      "features such as shared vocabulary rather than the intended facets."
    ), .fmt_beside_cut(ari, ari_cut), .fmt(ari_cut))
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
      method = paste("Classical MDS with average-linkage clustering of the",
                     "item coordinates (adapted from Sireci & Geisinger, 1992,",
                     "1995)"),
      dims = as.integer(dims),
      dims_requested = dims_requested,
      k = k,
      max_dims = max_dims,
      cluster_method = "average linkage on the MDS coordinates",
      ari_cut = ari_cut,
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
print.contentvalid_structure <- function(x, digits = 2, ...) {
  .validate_digits(digits)
  .print_header(x, "Content structure from expert similarity")
  cat("Items: ", x$design$n_items, " | Dimensions retained: ", x$settings$dims,
      " | Clusters: ", x$settings$k, "\n", sep = "")
  if (x$settings$dims < x$settings$dims_requested) {
    .say(paste0(
      "Requested ", x$settings$dims_requested, " dimensions, but these ",
      "similarities support only ", x$design$n_dimensions_available,
      ". The solution uses ", x$settings$dims, "."))
  }
  ari_cut <- x$settings$ari_cut
  if (is.null(ari_cut)) ari_cut <- 0.60
  .say(paste0(
    "Status: ", x$status,
    if (x$status %in% c("Supported", "Review")) {
      paste0(" (criterion: adjusted Rand index >= ", .fmt(ari_cut, digits),
             if (ari_cut == 0.60) ", a contentvalidR convention" else
               ", set for this analysis", ")")
    }), exdent = 2L)
  .say(x$interpretation)

  .section("Fit by dimensionality")
  f <- x$fit
  .print_table(data.frame(dimensions = f$dims,
                          GOF = .fmt(f$gof, digits),
                          distortion = .fmt(f$stress, digits),
                          stringsAsFactors = FALSE, check.names = FALSE),
               more = "x$fit")
  cat("\n")
  .say("GOF: goodness of fit from classical scaling, the share of the sum",
       "of the absolute eigenvalues that the retained dimensions account for.",
       "Distortion: how far the map's distances depart from the",
       "dissimilarities (0 is an exact map); it need not fall as dimensions",
       "are added. It is not Kruskal's stress-1, so his benchmarks do not",
       "apply.")

  if (!is.null(x$cross_tab)) {
    .section("Blueprint cell by recovered cluster (counts of items)")
    .print_table(.table_frame(x$cross_tab))
    cat("\n")
    .say("Adjusted Rand index:",
         if (is.na(x$adjusted_rand)) "not defined" else
           .fmt(x$adjusted_rand, digits))
  }

  .closing(c("The clusters come from the item coordinates on the",
             .n_noun(x$settings$dims, "retained dimension"),
             "(average linkage), so they change with the number of dimensions.",
             "Choose that number for how interpretable the dimensions are."),
           "See plot(x) for the content map.")
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
#'   It prints with two decimals; the values themselves are unrounded.
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
#' Measurement, 16*(1), 17–31. \doi{10.1177/014662169201600102}
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
  # Labels are compared as trimmed text, and items keep the order of the data,
  # as in the item-sort workflow.
  d$item <- .as_label(d$item)
  d$rater <- .as_label(d$rater)
  d$assigned <- .as_label(d$assigned)

  if (anyDuplicated(d[c("item", "rater")])) {
    stop("Each item-rater pair must appear only once.", call. = FALSE)
  }

  items <- unique(d$item)
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
  .tag_component(sim, "contentvalid_similarity")
}

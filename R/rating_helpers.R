.prepare_rating_data <- function(ratings,
                                 item_col = "item",
                                 rater_col = "rater",
                                 construct_col = "construct",
                                 rating_col = "rating",
                                 target_map = NULL,
                                 target_col = "target_construct",
                                 require_target = TRUE) {
  if (!is.data.frame(ratings) || nrow(ratings) == 0L) {
    stop("`ratings` must be a non-empty data.frame.", call. = FALSE)
  }
  needed <- c(item_col, rater_col, construct_col, rating_col)
  missing_cols <- setdiff(needed, names(ratings))
  if (length(missing_cols)) {
    stop("`ratings` is missing required column(s): ",
         paste(missing_cols, collapse = ", "), ".", call. = FALSE)
  }

  d <- ratings[, needed, drop = FALSE]
  names(d) <- c("item", "rater", "construct", "rating")
  if (anyNA(d$item) || anyNA(d$rater) || anyNA(d$construct)) {
    stop("`item`, `rater`, and `construct` cannot contain missing values.", call. = FALSE)
  }
  if (!is.numeric(d$rating)) {
    stop("`rating` must be numeric.", call. = FALSE)
  }

  key <- paste(d$item, d$rater, d$construct, sep = "\r")
  if (anyDuplicated(key)) {
    stop("Each item-rater-construct combination must appear at most once.", call. = FALSE)
  }

  if (!is.null(target_map)) {
    if (is.list(target_map)) target_map <- unlist(target_map, use.names = TRUE)
    if (!is.character(target_map) || is.null(names(target_map)) || any(names(target_map) == "")) {
      stop("`target_map` must be a named character vector or named list mapping item -> target construct.", call. = FALSE)
    }
    item_chr <- as.character(d$item)
    missing_targets <- setdiff(unique(item_chr), names(target_map))
    if (length(missing_targets)) {
      stop("`target_map` is missing item(s): ", paste(missing_targets, collapse = ", "), ".", call. = FALSE)
    }
    d$target <- unname(target_map[item_chr])
  } else if (!is.null(target_col) && target_col %in% names(ratings)) {
    d$target <- as.character(ratings[[target_col]])
    if (anyNA(d$target) || any(d$target == "")) {
      stop("`target_col` cannot contain missing or empty target labels.", call. = FALSE)
    }
  } else if (isTRUE(require_target)) {
    stop("Supply a named `target_map` or include a target column (default `target_construct`).", call. = FALSE)
  } else {
    d$target <- NA_character_
  }

  if (!all(is.na(d$target))) {
    by_item <- split(d$target, d$item, drop = TRUE)
    bad <- names(Filter(function(z) length(unique(z)) != 1L, by_item))
    if (length(bad)) {
      stop("Each item must map to exactly one target construct. Check: ",
           paste(bad, collapse = ", "), ".", call. = FALSE)
    }

    item_constructs <- split(d$construct, d$item, drop = TRUE)
    missing_target_levels <- vapply(names(item_constructs), function(it) {
      target <- unique(d$target[d$item == it])[1]
      !target %in% unique(as.character(item_constructs[[it]]))
    }, logical(1))
    if (any(missing_target_levels)) {
      stop("Target construct is absent from the rating options for item(s): ",
           paste(names(item_constructs)[missing_target_levels], collapse = ", "), ".", call. = FALSE)
    }
  }

  d$item <- as.character(d$item)
  d$rater <- as.character(d$rater)
  d$construct <- as.character(d$construct)
  d$target <- as.character(d$target)
  rownames(d) <- NULL
  d
}

.validate_rating_scale <- function(scale_min, scale_max, observed = NULL) {
  vals <- c(scale_min, scale_max)
  if (!is.numeric(vals) || any(!is.finite(vals)) || length(scale_min) != 1L || length(scale_max) != 1L) {
    stop("`scale_min` and `scale_max` must be finite numeric scalars.", call. = FALSE)
  }
  if (scale_max <= scale_min) {
    stop("`scale_max` must be greater than `scale_min`.", call. = FALSE)
  }
  if (abs(scale_min - round(scale_min)) > sqrt(.Machine$double.eps) ||
      abs(scale_max - round(scale_max)) > sqrt(.Machine$double.eps)) {
    stop("`scale_min` and `scale_max` must be integer anchor endpoints.", call. = FALSE)
  }
  anchors <- scale_max - scale_min + 1
  if (abs(anchors - round(anchors)) > sqrt(.Machine$double.eps)) {
    stop("The Hinkin-Tracey indices require equally spaced integer anchors (for example, 1 to 5 or 1 to 7).", call. = FALSE)
  }
  anchors <- as.integer(round(anchors))
  if (anchors < 2L) stop("At least two rating anchors are required.", call. = FALSE)
  if (!is.null(observed)) {
    bad <- !is.na(observed) & (observed < scale_min | observed > scale_max)
    if (any(bad)) {
      stop("Observed ratings must fall between `scale_min` and `scale_max`.", call. = FALSE)
    }
  }
  anchors
}

.item_rating_matrix <- function(df) {
  raters <- unique(df$rater)
  constructs <- unique(df$construct)
  mat <- matrix(NA_real_, nrow = length(raters), ncol = length(constructs),
                dimnames = list(raters, constructs))
  for (i in seq_len(nrow(df))) {
    mat[df$rater[i], df$construct[i]] <- df$rating[i]
  }
  mat
}

.detect_item_rating_design <- function(df) {
  counts <- tapply(df$construct[!is.na(df$rating)],
                   df$rater[!is.na(df$rating)],
                   function(z) length(unique(z)))
  if (length(counts) == 0L) return("unknown")
  if (all(counts <= 1L)) "between" else "within"
}

.gg_epsilon <- function(y) {
  y <- as.matrix(y)
  k <- ncol(y)
  if (k < 2L || nrow(y) < 2L) return(NA_real_)
  if (k == 2L) return(1)
  S <- stats::cov(y)
  if (any(!is.finite(S))) return(NA_real_)
  C <- diag(k) - matrix(1 / k, nrow = k, ncol = k)
  Sc <- C %*% S %*% C
  numerator <- sum(diag(Sc))^2
  denominator <- (k - 1) * sum(Sc * Sc)
  if (!is.finite(denominator) || denominator <= 0) return(NA_real_)
  eps <- numerator / denominator
  max(1 / (k - 1), min(1, eps))
}

.rm_anova_oneway <- function(mat) {
  complete <- stats::complete.cases(mat)
  y <- mat[complete, , drop = FALSE]
  n <- nrow(y)
  k <- ncol(y)
  if (n < 2L || k < 2L) {
    return(list(n_complete = n, F = NA_real_, df1 = if (k >= 1L) k - 1 else NA_real_,
                df2 = NA_real_, p = NA_real_, epsilon_gg = NA_real_,
                df1_gg = NA_real_, df2_gg = NA_real_, p_gg = NA_real_,
                partial_eta2 = NA_real_))
  }

  gm <- mean(y)
  ss_total <- sum((y - gm)^2)
  ss_subject <- k * sum((rowMeans(y) - gm)^2)
  ss_within <- ss_total - ss_subject
  ss_construct <- n * sum((colMeans(y) - gm)^2)
  ss_error <- max(0, ss_within - ss_construct)
  df1 <- k - 1
  df2 <- (n - 1) * (k - 1)
  ms_construct <- ss_construct / df1
  ms_error <- ss_error / df2
  Fv <- if (ms_error == 0) {
    if (ms_construct > 0) Inf else NA_real_
  } else {
    ms_construct / ms_error
  }
  p <- if (is.na(Fv)) NA_real_ else if (is.infinite(Fv)) 0 else stats::pf(Fv, df1, df2, lower.tail = FALSE)
  eps <- .gg_epsilon(y)
  df1_gg <- if (is.na(eps)) NA_real_ else eps * df1
  df2_gg <- if (is.na(eps)) NA_real_ else eps * df2
  p_gg <- if (is.na(Fv) || is.na(eps)) NA_real_ else if (is.infinite(Fv)) 0 else
    stats::pf(Fv, df1_gg, df2_gg, lower.tail = FALSE)
  eta_p2 <- if ((ss_construct + ss_error) == 0) NA_real_ else ss_construct / (ss_construct + ss_error)
  list(n_complete = n, F = Fv, df1 = df1, df2 = df2, p = p,
       epsilon_gg = eps, df1_gg = df1_gg, df2_gg = df2_gg, p_gg = p_gg,
       partial_eta2 = eta_p2)
}

.within_target_contrasts <- function(mat, target, alpha = .05, adjust = "none") {
  complete <- stats::complete.cases(mat)
  y <- mat[complete, , drop = FALSE]
  others <- setdiff(colnames(y), target)
  if (nrow(y) < 2L || length(others) == 0L || !target %in% colnames(y)) {
    return(data.frame())
  }

  rows <- lapply(others, function(other) {
    diff <- y[, target] - y[, other]
    n <- length(diff)
    md <- mean(diff)
    sd_d <- stats::sd(diff)
    if (is.na(sd_d) || sd_d == 0) {
      tval <- if (md > 0) Inf else if (md < 0) -Inf else NA_real_
      p <- if (md > 0) 0 else if (md < 0) 1 else NA_real_
      dz <- if (md == 0) NA_real_ else sign(md) * Inf
    } else {
      tval <- md / (sd_d / sqrt(n))
      p <- stats::pt(tval, df = n - 1, lower.tail = FALSE)
      dz <- md / sd_d
    }
    data.frame(
      target = target,
      competitor = other,
      n = n,
      mean_target = mean(y[, target]),
      mean_competitor = mean(y[, other]),
      mean_diff = md,
      t = tval,
      df = n - 1,
      p = p,
      dz = dz,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out$p_adj <- stats::p.adjust(out$p, method = adjust)
  out$pass <- !is.na(out$p_adj) & out$p_adj <= alpha & out$mean_diff > 0
  rownames(out) <- NULL
  out
}

.between_target_contrasts <- function(df, target, alpha = .05, adjust = "none") {
  constructs <- unique(df$construct)
  others <- setdiff(constructs, target)
  rows <- lapply(others, function(other) {
    x <- df$rating[df$construct == target & !is.na(df$rating)]
    y <- df$rating[df$construct == other & !is.na(df$rating)]
    if (length(x) < 2L || length(y) < 2L) {
      return(data.frame(target = target, competitor = other, n = min(length(x), length(y)),
                        mean_target = if (length(x)) mean(x) else NA_real_,
                        mean_competitor = if (length(y)) mean(y) else NA_real_,
                        mean_diff = if (length(x) && length(y)) mean(x) - mean(y) else NA_real_,
                        t = NA_real_, df = NA_real_, p = NA_real_, dz = NA_real_,
                        stringsAsFactors = FALSE))
    }
    mx <- mean(x); my <- mean(y)
    vx <- stats::var(x); vy <- stats::var(y)
    se2 <- vx / length(x) + vy / length(y)
    if (se2 == 0) {
      tval <- if (mx > my) Inf else if (mx < my) -Inf else NA_real_
      dfw <- Inf
      pval <- if (mx > my) 0 else if (mx < my) 1 else NA_real_
    } else {
      tval <- (mx - my) / sqrt(se2)
      dfw <- se2^2 / ((vx / length(x))^2 / (length(x) - 1) +
                      (vy / length(y))^2 / (length(y) - 1))
      pval <- stats::pt(tval, df = dfw, lower.tail = FALSE)
    }
    pooled <- sqrt(((length(x)-1)*vx + (length(y)-1)*vy) /
                     (length(x) + length(y) - 2))
    d <- if (pooled == 0) NA_real_ else (mx - my) / pooled
    data.frame(target = target, competitor = other, n = min(length(x), length(y)),
               mean_target = mx, mean_competitor = my,
               mean_diff = mx - my, t = tval,
               df = dfw, p = pval, dz = d,
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  out$p_adj <- stats::p.adjust(out$p, method = adjust)
  out$pass <- !is.na(out$p_adj) & out$p_adj <= alpha & out$mean_diff > 0
  rownames(out) <- NULL
  out
}

.resolve_rating_orbiting_r <- function(targets, orbiting_r) {
  if (is.null(orbiting_r)) {
    return(stats::setNames(rep(NA_real_, length(targets)), targets))
  }
  if (!is.numeric(orbiting_r)) {
    stop("`orbiting_r` must be numeric.", call. = FALSE)
  }
  if (length(orbiting_r) == 1L) {
    return(stats::setNames(rep(as.numeric(orbiting_r), length(targets)), targets))
  }
  if (is.null(names(orbiting_r)) || any(names(orbiting_r) == "")) {
    stop("For multiple target scales, `orbiting_r` must be a named numeric vector keyed by target.", call. = FALSE)
  }
  missing_targets <- setdiff(targets, names(orbiting_r))
  if (length(missing_targets)) {
    stop("`orbiting_r` is missing target(s): ", paste(missing_targets, collapse = ", "), ".", call. = FALSE)
  }
  stats::setNames(as.numeric(orbiting_r[targets]), targets)
}

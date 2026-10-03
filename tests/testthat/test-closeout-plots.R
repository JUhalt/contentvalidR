# Figures: keys that fit, headroom, axis titles, count axes, symbols, the
# one-dimensional content map, and argument checks before any device opens.

closeout_sort_fit <- function(drop_a1 = FALSE) {
  s <- utils::read.csv(system.file("extdata", "sort_example.csv",
                                   package = "contentvalidR"))
  if (drop_a1) s$assigned_construct[s$item == "A1"] <- NA
  suppressWarnings(sort_validity(s))
}

# The key a plot draws, captured on its way to legend() with where it lands,
# measured while the plot's own margins are still set.
capture_key <- function(env = parent.frame()) {
  real <- contentvalidR:::.legend_draw
  seen <- new.env()
  local_mocked_bindings(.legend_draw = function(fit) {
    seen$fit <- fit
    seen$rect <- if (!is.null(fit)) key_rect(fit)
    seen$usr <- graphics::par("usr")
    real(fit)
  }, .env = env)
  seen
}

# Where legend() puts a key laid out by .legend_fit(), on the current plot.
key_rect <- function(fit) {
  args <- list("top", legend = fit$legend, pch = fit$pch, col = fit$col,
               bty = "n", ncol = fit$ncol, cex = fit$cex, x.intersp = 0.7,
               seg.len = 1.6, title = fit$title, plot = FALSE)
  if (any(!is.na(fit$lty))) args$lty <- fit$lty
  do.call(graphics::legend, args)$rect
}

test_that("a key's measured size is the size legend() draws", {
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::plot.new()
  labels <- c("Retain", "Review", "Insufficient data", "95% CI",
              "Criterion (exact test)")
  for (w in c(9, 4, 2.5)) {
    fit <- contentvalidR:::.legend_fit(labels, c(19, 1, 4, NA, NA),
                                       c(NA, NA, NA, 1, 2), width_in = w)
    rect <- key_rect(fit)
    usr <- graphics::par("usr")
    pin <- graphics::par("pin")
    expect_equal(rect$w / diff(usr[1:2]) * pin[1], fit$width, tolerance = 1e-6)
    expect_equal(rect$h / diff(usr[3:4]) * pin[2], fit$height, tolerance = 1e-6)
  }
  titled <- contentvalidR:::.legend_fit(c("A", "B"), c(1, 2),
                                        title = "A heading wider than the key")
  rect <- key_rect(titled)
  expect_equal(rect$w / diff(graphics::par("usr")[1:2]) * graphics::par("pin")[1],
               titled$width, tolerance = 1e-6)
})

test_that("a key too wide for one row takes two, then three, then smaller type", {
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  labels <- c("Retain", "Review", "Insufficient data", "95% CI",
              "Criterion (exact test)")
  pch <- c(19, 1, 4, NA, NA)
  lty <- c(NA, NA, NA, 1, 2)
  wide <- contentvalidR:::.legend_fit(labels, pch, lty, width_in = 12)
  expect_identical(wide$rows, 1)
  expect_identical(wide$cex, 0.72)
  two <- contentvalidR:::.legend_fit(labels, pch, lty, width_in = 6)
  expect_identical(c(two$rows, two$ncol), c(2, 3))
  expect_lte(two$width, 6 - 0.1)
  # Rows read across: the decisions first, then the lines. legend() fills
  # columns first, so the vector runs down each column.
  expect_identical(trimws(two$legend),
                   c("Retain", "95% CI", "Review", "Criterion (exact test)",
                     "Insufficient data", ""))
  expect_identical(two$pch, c(19, NA, 1, NA, 4, NA))
  tiny <- contentvalidR:::.legend_fit(labels, pch, lty, width_in = 2.5)
  expect_identical(tiny$rows, 3)
  expect_lt(tiny$cex, 0.72)
  expect_lte(tiny$width, 2.5 - 0.1 + 1e-9)
  # A short last row leaves blank slots at its end, never mid-key.
  seven <- contentvalidR:::.legend_fit(as.character(1:7), 1, width_in = 0.9)
  expect_identical(seven$rows, 3)
  expect_identical(seven$legend, c("1", "4", "7", "2", "5", "", "3", "6", ""))
  expect_null(contentvalidR:::.legend_fit(character(0)))
})

test_that("the Psa key with five entries fits at the vignette's 7 by 4 inches", {
  # The finding's case: three decisions, the interval and the criterion.
  fit <- closeout_sort_fit(drop_a1 = TRUE)
  expect_setequal(unique(fit$results$recommendation),
                  c("Insufficient data", "Retain", "Review"))
  seen <- capture_key()
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  plot(fit)
  key <- seen$fit
  expect_identical(sort(trimws(key$legend[nzchar(key$legend)])),
                   sort(c("Retain", "Review", "Insufficient data", "95% CI",
                          "Criterion (exact test)")))
  expect_gt(key$rows, 1)
  rect <- seen$rect
  expect_gte(rect$left, seen$usr[1])
  expect_lte(rect$left + rect$w, seen$usr[2])
  # The key sits above the highest possible Psa.
  expect_gt(rect$top - rect$h, 1)
})

test_that("every key sits in headroom above the data", {
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  seen <- capture_key()
  check <- function(obj, hi, ...) {
    seen$fit <- NULL
    plot(obj, ...)
    expect_false(is.null(seen$fit))
    rect <- seen$rect
    expect_gt(rect$top - rect$h, hi)
    expect_gte(rect$left, seen$usr[1])
    expect_lte(rect$left + rect$w, seen$usr[2])
  }
  check(expert_power(n_experts = 3:12, prob = c(.5, .6, .7, .95)), 1)
  check(sort_power(N = c(10, 20, 30, 40), true_p = c(.8, .9, .95)), 1,
        reference_power = .8)
  check(closeout_sort_fit(), 1, metric = "csv")
  check(closeout_sort_fit(), 1, type = "map")
  rating <- rating_validity(utils::read.csv(system.file(
    "extdata", "rating_example.csv", package = "contentvalidR")))
  check(rating, 1, metric = "htd")
  check(rating, 1, type = "map")
  set.seed(3)
  big <- matrix(sample(1:4, 8 * 25, TRUE, prob = c(.05, .1, .35, .5)), 8,
                dimnames = list(NULL, paste0("Item", 1:25)))
  check(expert_validity(big, mode = "relevance", lo = 1, hi = 4,
                        agreement = "none"), 25.25)
})

test_that("the planning curves are solid and their keys say so", {
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  seen <- capture_key()
  entries <- function() nzchar(seen$fit$legend)
  plot(expert_power(n_experts = 3:12, prob = c(.5, .6, .7, .95)))
  expect_identical(unique(seen$fit$lty[entries()]), 1)
  expect_identical(anyDuplicated(seen$fit$pch[entries()]), 0L)
  plot(sort_power(N = c(10, 20), true_p = c(.6, .8)), reference_power = .8)
  ref <- grepl("Reference", seen$fit$legend)
  expect_identical(seen$fit$lty[entries() & !ref], c(1, 1))
  expect_identical(seen$fit$lty[ref], 2)
})

test_that("a panel-size axis ticks only whole numbers", {
  real <- contentvalidR:::.axis_counts
  ticks <- NULL
  local_mocked_bindings(.axis_counts = function(side) {
    ticks <<- real(side)
    invisible(ticks)
  })
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  plot(expert_power(n_experts = 3:4, prob = .8))
  expect_identical(ticks, c(3, 4))
  plot(sort_power(N = 20, true_p = .7))
  expect_identical(ticks, 20)
  plot(sort_power(N = 18:21, true_p = .7), type = "critical")
  expect_identical(ticks, c(18, 19, 20, 21))
  plot(expert_power(n_experts = 3:12, prob = .8))
  expect_true(all(ticks == round(ticks)))
})

test_that("a vertical axis title too long for the figure moves to the key", {
  rating <- rating_validity(utils::read.csv(system.file(
    "extdata", "rating_example.csv", package = "contentvalidR")))
  full <- "HTD: lead of the target over the other constructs"
  real <- contentvalidR:::.plot_with
  ylab <- NULL
  local_mocked_bindings(.plot_with = function(args, dots, ...) {
    ylab <<- args$ylab
    real(args, dots, ...)
  })
  seen <- capture_key()

  grDevices::pdf(NULL, width = 7, height = 4)
  plot(rating, metric = "htd")
  grDevices::dev.off()
  expect_identical(ylab, "HTD")
  expect_identical(seen$fit$title, full)

  grDevices::pdf(NULL, width = 7, height = 7)
  plot(rating, metric = "htd")
  grDevices::dev.off()
  expect_identical(ylab, full)
  expect_null(seen$fit$title)

  # Without a key the axis still shows the index's name.
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  plot(rating, metric = "htd", show_legend = FALSE)
  expect_identical(ylab, "HTD")
})

test_that("the congruence plot fills an index that met the criterion", {
  cong <- utils::read.csv(system.file("extdata", "expert_congruence_example.csv",
                                      package = "contentvalidR"))
  fit <- expert_validity(cong, mode = "congruence")
  expect_identical(fit$results$recommendation,
                   c("Congruent", "Congruent", "Review"))
  seen <- capture_key()
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  plot(fit)
  key <- seen$fit
  keep <- nzchar(key$legend)
  entries <- stats::setNames(key$pch[keep], trimws(key$legend[keep]))
  expect_identical(entries[["IOC: meets criterion"]], 19)
  expect_identical(entries[["IOC: below criterion"]], 1)
  # The competitor's mean is no longer an open circle, which now means an
  # index below the criterion.
  expect_identical(entries[["Mean: competitor"]], 6)
  expect_identical(entries[["Mean: target"]], 2)
})

test_that("coincident items on a one-dimensional map are stacked", {
  grDevices::pdf(NULL, width = 7, height = 4)
  on.exit(grDevices::dev.off(), add = TRUE)
  items <- paste0("I", 1:6)
  sim <- matrix(1, 6, 6, dimnames = list(items, items))
  sim[1:3, 1:3] <- 5
  sim[4:6, 4:6] <- 5
  diag(sim) <- 5
  cs <- content_structure(sim, membership = rep(c("Autonomy", "Competence"),
                                                each = 3))
  expect_identical(ncol(cs$coordinates), 1L)
  px <- cs$coordinates[, 1]
  lay <- contentvalidR:::.strip_layout(px, items, range(px), 0.6)
  # Three items share each position, so each stack has three rows, the first
  # item at the top.
  expect_identical(sort(lay$rows[1:3]), 0:2)
  expect_identical(sort(lay$rows[4:6]), 0:2)
  expect_identical(lay$rows[c(1, 4)], c(2L, 2L))
  # Items far apart share one row.
  apart <- contentvalidR:::.strip_layout(c(-2, 0, 2), c("A", "B", "C"),
                                         c(-2, 2), 0.6)
  expect_identical(apart$rows, c(0L, 0L, 0L))
  # The last names fit inside the frame.
  long <- paste("Item about", c("autonomy at work", "choosing tasks", "own pace"))
  wide <- contentvalidR:::.strip_layout(c(-2, 2, 2), long, c(-2, 2), 0.6)
  reach <- graphics::strwidth(long, units = "inches", cex = 0.7)
  per_in <- graphics::par("pin")[1] / (1.08 * diff(wide$xlim))
  right_edge <- wide$xlim[2] + 0.04 * diff(wide$xlim)
  expect_true(all(c(-2, 2, 2) + reach / per_in <= right_edge))
  expect_silent(plot(cs))
})

test_that("the help pages describe the figures as drawn", {
  man <- testthat::test_path("..", "..", "man")
  skip_if_not(dir.exists(man), "package documentation is not available")
  rd <- function(topic) {
    paste(readLines(file.path(man, paste0(topic, ".Rd")), warn = FALSE),
          collapse = " ")
  }
  structure_rd <- rd("plot.contentvalid_structure")
  expect_false(grepl("labeled by its blueprint cell", structure_rd, fixed = TRUE))
  expect_match(structure_rd, "are stacked one above another", fixed = TRUE)
  sort_power_rd <- rd("plot.contentvalid_sort_power")
  expect_false(grepl("by line type", sort_power_rd, fixed = TRUE))
  expect_match(rd("plot.contentvalid_expert"), "fell below it", fixed = TRUE)
})

test_that("bad plot arguments stop before any graphics device is touched", {
  touched <- FALSE
  local_mocked_bindings(.plot_margins = function(...) {
    touched <<- TRUE
    stop("the margins were set")
  })
  sort_fit <- closeout_sort_fit()
  rating <- rating_validity(utils::read.csv(system.file(
    "extdata", "rating_example.csv", package = "contentvalidR")))
  plan <- sort_power(N = c(10, 20), true_p = .8)
  expect_error(plot(sort_fit, metric = "nope"), "`metric` must be one of")
  expect_error(plot(rating, metric = "nope"), "`metric` must be one of")
  expect_error(plot(plan, reference_power = 2), "`reference_power` must be NULL")
  expect_error(plot(plan, reference_power = -1), "`reference_power` must be NULL")
  expect_false(touched)
})

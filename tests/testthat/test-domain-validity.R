sdt_assignments <- function() {
  data.frame(
    item = paste0("I", 1:7),
    construct = c("Autonomy", "Autonomy", "Autonomy", "Autonomy",
                  "Competence", "Competence", "Relatedness"),
    stringsAsFactors = FALSE
  )
}

full_domain <- c("Autonomy", "Competence", "Relatedness", "Belonging")

test_that("domain_validity returns a conforming workflow with one row per cell", {
  fit <- domain_validity(sdt_assignments(), cell_col = "construct", domain = full_domain)

  expect_s3_class(fit, "contentvalid_domain")
  expect_s3_class(fit, "contentvalid_workflow")
  expect_true(all(c("results", "scale_summary", "settings", "design", "details") %in% names(fit)))
  expect_equal(nrow(fit$results), 4L)
  expect_setequal(fit$results$cell, full_domain)
  expect_true(all(fit$results$status %in% contentvalidR:::.workflow_status_levels))
  expect_true(all(nzchar(fit$results$interpretation)))
})

test_that("an empty blueprint cell is detected and explained", {
  fit <- domain_validity(sdt_assignments(), cell_col = "construct", domain = full_domain)
  gap <- fit$results[fit$results$cell == "Belonging", ]

  expect_equal(gap$n_items, 0L)
  expect_equal(gap$recommendation, "Not covered")
  expect_equal(gap$status, "Review")
  expect_equal(fit$scale_summary$n_empty, 1L)
  # The output must explain why item-level evidence cannot surface this.
  expect_match(gap$interpretation, "no item here to rate")
})

test_that("empty cells are undetectable without a domain, and the output says so", {
  fit <- domain_validity(sdt_assignments(), cell_col = "construct")

  expect_equal(nrow(fit$results), 3L)
  expect_equal(fit$scale_summary$n_empty, 0L)
  expect_false(fit$scale_summary$domain_supplied)

  printed <- paste(capture.output(print(fit)), collapse = " ")
  expect_match(printed, "cannot be detected")
  summarised <- paste(capture.output(print(summary(fit))), collapse = " ")
  expect_match(summarised, "no `domain` was supplied")
})

test_that("thin and over-represented cells are flagged against explicit thresholds", {
  fit <- domain_validity(sdt_assignments(), cell_col = "construct",
                         domain = full_domain, min_items = 2, over_factor = 2)
  r <- fit$results

  expect_equal(r$recommendation[r$cell == "Relatedness"], "Thinly covered")
  expect_equal(r$recommendation[r$cell == "Autonomy"], "Over-represented")
  expect_equal(r$recommendation[r$cell == "Competence"], "Covered")

  # Thresholds are settings, not fixed rules: relaxing them changes the verdict.
  relaxed <- domain_validity(sdt_assignments(), cell_col = "construct",
                             domain = full_domain, min_items = 1, over_factor = 5)
  rr <- relaxed$results
  expect_equal(rr$recommendation[rr$cell == "Relatedness"], "Covered")
  expect_equal(rr$recommendation[rr$cell == "Autonomy"], "Covered")
})

test_that("shares and counts are internally consistent", {
  fit <- domain_validity(sdt_assignments(), cell_col = "construct", domain = full_domain)
  r <- fit$results
  expect_equal(sum(r$n_items), 7L)
  expect_equal(sum(r$share), 1, tolerance = 1e-12)
  expect_equal(r$share, r$n_items / 7, tolerance = 1e-12)
})

test_that("targets replace the equal-cells expectation", {
  targets <- c(Autonomy = 4, Competence = 2, Relatedness = 1, Belonging = 3)
  fit <- domain_validity(sdt_assignments(), cell_col = "construct",
                         domain = full_domain, targets = targets, min_items = 1)
  r <- fit$results

  expect_equal(r$expected_share, as.numeric(targets[r$cell]) / sum(targets),
               tolerance = 1e-12)
  # Autonomy now matches its intended weight, so it is no longer over-represented.
  expect_equal(r$recommendation[r$cell == "Autonomy"], "Covered")
  expect_true(fit$settings$targets_supplied)
})

test_that("construct-by-facet cells are crossed correctly", {
  faceted <- data.frame(
    item = paste0("Q", 1:6),
    construct = rep(c("Knowledge", "Skill"), each = 3),
    facet = c("Recall", "Apply", "Apply", "Recall", "Recall", "Apply"),
    stringsAsFactors = FALSE
  )
  fit <- domain_validity(faceted, cell_col = "construct", facet_col = "facet",
                         min_items = 1)

  expect_equal(nrow(fit$results), 4L)
  expect_true(all(grepl(" / ", fit$results$cell)))
  expect_true(fit$design$faceted)
  expect_equal(sum(fit$results$n_items), 6L)
})

test_that("structure analysis is attached when similarity is supplied", {
  a <- sdt_assignments()
  cells <- a$construct
  S <- outer(cells, cells, function(x, y) ifelse(x == y, 4, 1))
  diag(S) <- 5
  dimnames(S) <- list(a$item, a$item)

  fit <- domain_validity(a, cell_col = "construct", domain = full_domain, similarity = S)
  expect_s3_class(fit$details$structure, "contentvalid_structure")
  expect_equal(fit$scale_summary$adjusted_rand, 1)
  expect_true(fit$settings$structure_analyzed)

  printed <- paste(capture.output(print(fit)), collapse = " ")
  expect_match(printed, "adjusted Rand")
})

test_that("similarity that cannot be matched to items is an error, not a silent guess", {
  a <- sdt_assignments()
  S <- diag(7)
  dimnames(S) <- list(paste0("X", 1:7), paste0("X", 1:7))
  expect_error(
    domain_validity(a, cell_col = "construct", similarity = S),
    "no blueprint assignment"
  )

  unnamed <- diag(5)
  expect_error(
    domain_validity(a, cell_col = "construct", similarity = unnamed),
    "cannot be matched"
  )
})

test_that("malformed inputs are rejected", {
  a <- sdt_assignments()
  expect_error(domain_validity(a[0, ], cell_col = "construct"), "at least one row")
  expect_error(domain_validity(a, cell_col = "nope"), "missing required column")
  expect_error(domain_validity(a, cell_col = "construct", min_items = 0), "positive integer")
  expect_error(domain_validity(a, cell_col = "construct", over_factor = 1), "greater than 1")
  expect_error(
    domain_validity(a, cell_col = "construct", domain = "Autonomy"),
    "appear in `assignments` but not in `domain`"
  )
  expect_error(
    domain_validity(a, cell_col = "construct", domain = full_domain,
                    targets = c(Autonomy = 1)),
    "missing entries for"
  )
  expect_error(
    domain_validity(a, cell_col = "construct", domain = full_domain,
                    targets = c(1, 2, 3, 4)),
    "named, non-negative"
  )

  dup <- data.frame(item = c("A", "A"), cell = c("x", "y"), stringsAsFactors = FALSE)
  expect_error(domain_validity(dup), "only once")
})

test_that("output states the limits of coverage evidence", {
  fit <- domain_validity(sdt_assignments(), cell_col = "construct", domain = full_domain)
  printed <- paste(capture.output(print(fit)), collapse = " ")
  expect_match(printed, "does not show that")
  expect_match(printed, "blueprint is the right")
  expect_error(print(fit, digits = -1), "nonnegative integer")
})

test_that("a fully covered blueprint reports no gaps", {
  even <- data.frame(
    item = paste0("I", 1:6),
    cell = rep(c("A", "B", "C"), each = 2),
    stringsAsFactors = FALSE
  )
  fit <- domain_validity(even, domain = c("A", "B", "C"))

  expect_equal(fit$scale_summary$n_empty, 0L)
  expect_equal(fit$scale_summary$n_thin, 0L)
  expect_equal(fit$scale_summary$n_over, 0L)
  expect_equal(fit$scale_summary$n_covered, 3L)
  expect_true(all(fit$results$status == "Supported"))

  summarised <- paste(capture.output(print(summary(fit))), collapse = " ")
  expect_match(summarised, "met the coverage criteria")
})

test_that("the content map plot runs for one and two dimensions", {
  blueprint <- c(rep("A", 3), rep("B", 3))
  items <- paste0("I", 1:6)
  sim <- matrix(1, 6, 6, dimnames = list(items, items))
  sim[1:3, 1:3] <- 5
  sim[4:6, 4:6] <- 5
  diag(sim) <- 5

  cs <- content_structure(sim, membership = blueprint)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_silent(plot(cs))
  expect_silent(plot(cs, show_legend = FALSE))
  expect_error(plot(cs, show_legend = NA), "TRUE or FALSE")

  one_dim <- content_structure(sim, membership = blueprint, dims = 1)
  expect_silent(plot(one_dim))
})

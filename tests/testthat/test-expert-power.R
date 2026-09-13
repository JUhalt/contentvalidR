test_that("required endorsement counts clear the I-CVI criterion and are minimal", {
  for (n in 3:20) {
    crit <- contentvalidR:::.cvi_common_criterion(n)
    req <- contentvalidR:::.cvi_required_count(n)
    expect_false(is.na(req), info = paste("n =", n))
    expect_gte(req / n, crit - 1e-9)
    if (req > 1L) expect_lt((req - 1L) / n, crit)
  }
  # Panels too small for the guideline have no attainable requirement.
  expect_true(is.na(contentvalidR:::.cvi_required_count(2L)))
})

test_that("CVR critical counts agree with those reported by cvr()", {
  for (n in c(5, 8, 10, 15, 20, 25)) {
    from_cvr <- cvr(essential = n, N = n)$critical_ne
    from_power <- contentvalidR:::.cvr_required_count(n, 0.05)
    expect_equal(as.integer(from_power), as.integer(from_cvr), info = paste("n =", n))
  }
})

test_that("power equals the exact binomial tail probability", {
  p <- expert_power(n_experts = 3:12, prob = c(0.7, 0.85, 0.95))
  r <- p$results
  for (i in seq_len(nrow(r))) {
    n <- r$n_experts[i]
    req <- r$required_endorsements[i]
    direct <- sum(stats::dbinom(req:n, size = n, prob = r$prob[i]))
    expect_equal(r$power[i], direct, tolerance = 1e-12)
  }
})

test_that("the I-CVI criterion step at six experts is reported, not smoothed", {
  r <- expert_power(n_experts = 3:8, prob = 0.9, criterion = "cvi")$results

  # Under unanimity, adding a fourth or fifth expert makes clearing harder.
  expect_lt(r$power[r$n_experts == 5], r$power[r$n_experts == 3])
  # The sixth expert relaxes the criterion, so power jumps.
  expect_gt(r$power[r$n_experts == 6], r$power[r$n_experts == 5])
  expect_equal(r$required_endorsements[r$n_experts == 5], 5L)
  expect_equal(r$required_endorsements[r$n_experts == 6], 5L)

  out <- paste(capture.output(print(expert_power(n_experts = 3:8, prob = 0.9))),
               collapse = " ")
  expect_match(out, "step at six experts")
  expect_match(out, "property of the guideline, not of the items")
})

test_that("power increases with the assumed endorsement probability", {
  r <- expert_power(n_experts = 10, prob = c(0.5, 0.7, 0.9))$results
  r <- r[order(r$prob), ]
  expect_true(all(diff(r$power) > 0))
})

test_that("a below-full response rate lowers power and averages over realized panels", {
  full <- expert_power(n_experts = 10, prob = 0.9, response_rate = 1)$results$power
  partial <- expert_power(n_experts = 10, prob = 0.9, response_rate = 0.6)$results$power
  expect_lt(partial, full)
  expect_gt(partial, 0)

  # Averaging over realized panel sizes is not the same as simply shrinking the
  # panel, because the criterion itself moves with size.
  shrunk <- expert_power(n_experts = 6, prob = 0.9)$results$power
  expect_false(isTRUE(all.equal(partial, shrunk)))

  out <- paste(capture.output(
    print(expert_power(n_experts = 10, prob = 0.9, response_rate = 0.6))
  ), collapse = " ")
  expect_match(out, "experts invited")
})

test_that("the CVR criterion is available and behaves monotonically in probability", {
  p <- expert_power(n_experts = c(5, 10, 20), prob = c(0.6, 0.8), criterion = "cvr")
  expect_equal(p$settings$criterion, "cvr")
  expect_match(p$settings$method, "Lawshe")

  r <- p$results
  for (n in c(5, 10, 20)) {
    sub <- r[r$n_experts == n, ]
    sub <- sub[order(sub$prob), ]
    expect_true(all(diff(sub$power) > 0))
  }
})

test_that("alpha tightens the CVR requirement", {
  lenient <- expert_power(n_experts = 20, prob = 0.7, criterion = "cvr", alpha = 0.10)
  strict <- expert_power(n_experts = 20, prob = 0.7, criterion = "cvr", alpha = 0.01)
  expect_gte(strict$results$required_endorsements, lenient$results$required_endorsements)
  expect_lte(strict$results$power, lenient$results$power)
})

test_that("the grid covers every panel size and probability requested", {
  p <- expert_power(n_experts = c(4, 6, 8), prob = c(0.7, 0.9))
  expect_equal(nrow(p$results), 6L)
  expect_setequal(unique(p$results$n_experts), c(4L, 6L, 8L))
  expect_setequal(unique(p$results$prob), c(0.7, 0.9))
  expect_equal(p$design$n_panel_sizes, 3L)
  expect_equal(p$design$n_probabilities, 2L)
})

test_that("planning output refuses to recommend a panel size", {
  out <- paste(capture.output(print(expert_power(n_experts = 3:8, prob = 0.9))),
               collapse = " ")
  expect_match(out, "does not recommend one")
  expect_match(out, "an assumption you supply")
})

test_that("malformed planning inputs are rejected", {
  expect_error(expert_power(n_experts = 0), "positive integers")
  expect_error(expert_power(n_experts = 2.5), "positive integers")
  expect_error(expert_power(n_experts = NA), "positive integers")
  expect_error(expert_power(prob = 1.5), "probabilities between 0 and 1")
  expect_error(expert_power(prob = -0.1), "probabilities between 0 and 1")
  expect_error(expert_power(alpha = 0), "strictly between 0 and 1")
  expect_error(expert_power(alpha = 1), "strictly between 0 and 1")
  expect_error(expert_power(response_rate = 0), "greater than 0")
  expect_error(expert_power(response_rate = 1.2), "greater than 0")
  expect_error(expert_power(criterion = "nope"), "should be one of")
  expect_error(print(expert_power(n_experts = 5, prob = 0.9), digits = -1),
               "nonnegative integer")
})

test_that("the planning curve plots as a step function", {
  p <- expert_power(n_experts = 3:12, prob = c(0.7, 0.85))
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_silent(plot(p))
  expect_silent(plot(p, show_legend = FALSE))
  expect_error(plot(p, show_legend = NA), "TRUE or FALSE")
})

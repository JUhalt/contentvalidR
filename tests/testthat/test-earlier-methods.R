# The earlier methods are checked against the numbers their sources publish,
# not against the package's own output, and are shown never to move a decision.

ag_count <- contentvalidR:::.ag_critical_count

test_that("Anderson and Gerbing's critical Csv follows their Equations 5 and 6", {
  # Their two pretest samples of 20 respondents used the critical value .5.
  m <- ag_count(20, .05)
  expect_identical(m, 15L)
  expect_equal((2 * m - 20) / 20, .5)

  # Equation 5 by direct enumeration: the fewest m with P(n_c >= m) < alpha
  # under a binomial at .5.
  for (n in 5:40) {
    tail <- stats::pbinom((0:n) - 1L, n, .5, lower.tail = FALSE)
    expect_identical(ag_count(n, .05), as.integer(min((0:n)[tail < .05])),
                     info = paste("N =", n))
  }
  # Four judges can never reach significance at .05: .5^4 = .0625.
  expect_true(is.na(ag_count(4, .05)))
})

test_that("Lawshe's table is his Table 1, and sizes he did not list have no minimum", {
  published <- c(`5` = .99, `6` = .99, `7` = .99, `8` = .75, `9` = .78,
                 `10` = .62, `11` = .59, `12` = .56, `13` = .54, `14` = .51,
                 `15` = .49, `20` = .42, `25` = .37, `30` = .33, `35` = .31,
                 `40` = .29)
  expect_equal(contentvalidR:::.lawshe_minimum(as.integer(names(published))),
               unname(published))
  expect_true(all(is.na(contentvalidR:::.lawshe_minimum(c(4L, 16L, 41L)))))
})

test_that("Wilson et al.'s critical CVR reproduces their Table 2", {
  wilson <- contentvalidR:::.wilson_critical_cvr
  # N = 5 and 6 at one-tailed .05, .025, .01 and .005, as published.
  expect_equal(round(wilson(5, .05), 3), .736)
  expect_equal(round(wilson(5, .025), 3), .877)
  expect_equal(wilson(5, .01), .99)
  expect_equal(round(wilson(6, .05), 3), .672)
  expect_equal(round(wilson(6, .025), 3), .800)
  expect_equal(round(wilson(6, .01), 3), .950)
  expect_equal(wilson(6, .005), .99)
})

test_that("essentiality compares CVR with Lawshe and Wilson, and computes Lawshe's CVI", {
  fit <- expert_validity(c(12, 10, 8, 6), mode = "essentiality", N = 12)
  em <- fit$details$earlier_methods
  it <- em$items
  expect_equal(it$lawshe_minimum, rep(.56, 4))
  expect_identical(it$lawshe_meets, c(TRUE, TRUE, FALSE, FALSE))
  expect_equal(it$wilson_critical, rep(stats::qnorm(.95) / sqrt(12), 4))
  # Lawshe's CVI: the mean CVR of the items his table retains.
  expect_equal(em$lawshe_cvi, mean(fit$results$cvr[1:2]))
  expect_identical(em$lawshe_n_retained, 2L)

  # 7 of 8 is exactly Lawshe's .75, and meets it despite floating point.
  eight <- expert_validity(7, mode = "essentiality", N = 8)$details$earlier_methods
  expect_true(eight$items$lawshe_meets)
  # 8 of 9 is .778, short of his .78: the table needs all nine.
  nine <- expert_validity(c(9, 8), mode = "essentiality", N = 9)$details$earlier_methods
  expect_identical(nine$items$lawshe_meets, c(TRUE, FALSE))

  # A panel size Lawshe did not tabulate has no minimum and no CVI.
  sixteen <- expert_validity(c(16, 13), mode = "essentiality", N = 16)
  expect_true(all(is.na(sixteen$details$earlier_methods$items$lawshe_meets)))
  expect_true(is.na(sixteen$details$earlier_methods$lawshe_cvi))
})

test_that("Yao et al.'s rule needs Psa and Csv both at .30 or more", {
  d <- data.frame(
    item = rep(c("I1", "I2", "I3"), each = 10), rater = rep(1:10, 3),
    target_construct = "A",
    assigned_construct = c(
      rep("A", 3), rep("B", 7),                    # Psa .30, Csv -.40
      rep("A", 5), rep("B", 2), rep("C", 2), "D",  # Psa .50, Csv .30
      rep("A", 4), rep("B", 3), rep("C", 3)        # Psa .40, Csv .10
    ),
    stringsAsFactors = FALSE
  )
  it <- sort_validity(d)$details$earlier_methods$items
  expect_equal(it$psa, c(.3, .5, .4))
  expect_equal(it$csv, c(-.4, .3, .1))
  expect_identical(it$yao_meets, c(FALSE, TRUE, FALSE))
})

test_that("the chance-plus-.05 extension reproduces Yao et al. at four constructs", {
  ext <- contentvalidR:::.yao_extension_cut
  expect_equal(ext(4L), .30)
  expect_equal(ext(3L), 1 / 3 + .05)
  expect_equal(ext(10L), .15)
  expect_true(is.na(ext(1L)))
  expect_true(is.na(ext(NULL)))

  # Three constructs used: 12 A, 3 B, 5 C gives Psa .60 and Csv .35, which
  # pass Yao's .30 but not the extension's .383.
  d <- data.frame(
    item = rep("I1", 20), rater = 1:20, target_construct = "A",
    assigned_construct = c(rep("A", 12), rep("B", 3), rep("C", 5)),
    stringsAsFactors = FALSE
  )
  fit <- sort_validity(d)
  it <- fit$details$earlier_methods$items
  expect_equal(fit$details$earlier_methods$n_constructs, 3L)
  expect_equal(it$psa, .60)
  expect_equal(it$csv, .35)
  expect_true(it$yao_meets)
  expect_false(it$extension_meets)

  # Stating that five were offered lowers chance, and the cut, to .25.
  five <- sort_validity(d, n_constructs = 5)$details$earlier_methods
  expect_equal(five$extension_cut, .25)
  expect_true(five$items$extension_meets)
  expect_true(five$constructs_given)
  # The count never changes the decision.
  expect_identical(sort_validity(d, n_constructs = 5)$results, fit$results)
})

test_that("n_constructs must count every construct judges could choose", {
  d <- data.frame(
    item = rep("I1", 10), rater = 1:10, target_construct = "A",
    assigned_construct = c(rep("A", 6), rep("B", 2), rep("C", 2)),
    stringsAsFactors = FALSE
  )
  expect_error(sort_validity(d, n_constructs = 2), "data use 3 constructs")
  expect_error(sort_validity(d, n_constructs = 3.5), "whole number")
  expect_error(sort_validity(d, n_constructs = 1), "at least 2")
})

test_that("the extension is labeled as one wherever it is printed", {
  d <- data.frame(
    item = rep(c("I1", "I2"), each = 20), rater = rep(1:20, 2),
    target_construct = "A",
    assigned_construct = c(rep("A", 12), rep("B", 5), rep("C", 3),
                           rep("A", 15), rep("C", 5)),
    stringsAsFactors = FALSE
  )
  text <- function(...) {
    gsub("[[:space:]]+", " ", paste(utils::capture.output(
      print(sort_validity(d, legacy = TRUE, ...))), collapse = " "))
  }
  three <- text()
  expect_match(three, "extension*", fixed = TRUE)
  expect_match(three, "a contentvalidR extension, not a published rule",
               fixed = TRUE)
  expect_match(three, "(1/3 + .05)", fixed = TRUE)
  expect_match(three, "If more were offered, set `n_constructs`", fixed = TRUE)

  # With four constructs the extension is Yao's rule, so no second column.
  four <- text(n_constructs = 4)
  expect_false(grepl("extension*", four, fixed = TRUE))
  expect_match(four, "gives the same .30", fixed = TRUE)
  expect_false(grepl("If more were offered", four, fixed = TRUE))
})

test_that("Anderson and Gerbing's verdict compares counts, so the cutoff itself meets", {
  d <- data.frame(
    item = rep("I1", 20), rater = 1:20, target_construct = "A",
    assigned_construct = c(rep("A", 14), rep("B", 4), rep("C", 2)),
    stringsAsFactors = FALSE
  )
  fit <- sort_validity(d)
  it <- fit$details$earlier_methods$items
  # n_c - n_o = 14 - 4 = 10 = 2m - N = 30 - 20, so Csv .50 meets .50.
  expect_equal(it$csv, .5)
  expect_true(it$ag_meets)
  # Yet 14 of 20 is short of the 15 the exact test needs: the six judges who
  # missed the target split between two rivals, which Equation 6 assumes away.
  expect_identical(fit$results$critical_n_target, 15L)
  expect_identical(fit$results$recommendation, "Review")
})

test_that("Fleiss' kappa matches the irr package and fails safe", {
  fleiss <- contentvalidR:::.fleiss_kappa
  B <- rbind(c(1, 1, 1, 0, 1), c(1, 1, 0, 0, 1), c(1, 0, 1, 0, 1),
             c(1, 1, 1, 1, 0))
  skip_if_not_installed("irr")
  # irr takes subjects in rows; the package keeps raters in rows.
  expect_equal(fleiss(B), irr::kappam.fleiss(t(B))$value)
  three <- rbind(c(1, 2, 3, 1), c(1, 2, 2, 1), c(1, 3, 3, 2))
  expect_equal(fleiss(three), irr::kappam.fleiss(t(three))$value)

  expect_true(is.na(fleiss(matrix(1, 3, 4))))            # one category only
  B[1, 1] <- NA
  expect_true(is.na(fleiss(B)))                          # a missing rating
})

test_that("earlier methods never change a decision", {
  sorts <- read.csv(system.file("extdata", "sort_example.csv",
                                package = "contentvalidR"),
                    stringsAsFactors = FALSE)
  expect_identical(sort_validity(sorts, legacy = TRUE)$results,
                   sort_validity(sorts)$results)
  expect_identical(
    expert_validity(c(12, 10, 8), mode = "essentiality", N = 12,
                    legacy = TRUE)$results,
    expert_validity(c(12, 10, 8), mode = "essentiality", N = 12)$results
  )
  R <- rbind(c(4, 4, 3, 2), c(4, 3, 4, 2), c(3, 4, 4, 1), c(4, 4, 4, 2))
  colnames(R) <- paste0("I", 1:4)
  a <- expert_validity(R, mode = "relevance", lo = 1, hi = 4,
                       agreement = "none", legacy = TRUE)
  b <- expert_validity(R, mode = "relevance", lo = 1, hi = 4, agreement = "none")
  expect_identical(a$results, b$results)
  expect_identical(a$scale_summary, b$scale_summary)
})

test_that("the comparison prints only when asked, and print() can override", {
  sorts <- read.csv(system.file("extdata", "sort_example.csv",
                                package = "contentvalidR"),
                    stringsAsFactors = FALSE)
  shown <- function(x, ...) {
    any(grepl("Earlier methods, for comparison", utils::capture.output(print(x, ...))))
  }
  quiet <- sort_validity(sorts)
  asked <- sort_validity(sorts, legacy = TRUE)
  expect_false(shown(quiet))
  expect_true(shown(asked))
  expect_true(shown(quiet, legacy = TRUE))
  expect_false(shown(asked, legacy = FALSE))
  # A bad argument is refused before anything prints.
  expect_error(utils::capture.output(print(quiet, legacy = "yes")), "legacy")
  expect_output(try(print(quiet, legacy = "yes"), silent = TRUE), NA)

  expect_true(shown(expert_validity(c(12, 8), mode = "essentiality", N = 12,
                                    legacy = TRUE)))
  # Congruence has no earlier rule, so it prints nothing extra.
  cong <- read.csv(system.file("extdata", "expert_congruence_example.csv",
                               package = "contentvalidR"),
                   stringsAsFactors = FALSE)
  expect_false(shown(expert_validity(cong, mode = "congruence", legacy = TRUE)))

  # An object saved before this existed still prints when asked.
  old <- quiet
  old$details$earlier_methods <- NULL
  expect_false(shown(old, legacy = TRUE))
  expect_error(utils::capture.output(print(old, legacy = TRUE)), NA)
})

test_that("the printed comparison states each rule's source and agreement", {
  sorts <- read.csv(system.file("extdata", "sort_example.csv",
                                package = "contentvalidR"),
                    stringsAsFactors = FALSE)
  fit <- sort_validity(sorts, legacy = TRUE)
  out <- gsub("[[:space:]]+", " ",
              paste(utils::capture.output(print(fit)), collapse = " "))
  expect_match(out, "Anderson and Gerbing (1991): Csv of at least .50", fixed = TRUE)
  expect_match(out, "Yao, Wu and Yang (2008)", fixed = TRUE)

  it <- fit$details$earlier_methods$items
  keep <- it$decision == "Retain"
  expect_match(out, paste0("Anderson and Gerbing on ",
                           sum(it$ag_meets == keep), " of ", nrow(it)),
               fixed = TRUE)

  # A value that rounds to its cutoff but misses it is explained.
  nine <- expert_validity(c(9, 8), mode = "essentiality", N = 9, legacy = TRUE)
  out9 <- gsub("[[:space:]]+", " ",
               paste(utils::capture.output(print(nine)), collapse = " "))
  expect_match(out9, "Item2 (.778) prints at the Lawshe cutoff of .78", fixed = TRUE)
})

# Hernandez-Nieto (2002): the book's worked examples are the reference, and
# the tests also pin the shortcomings the documentation claims.

ccv <- contentvalidR:::.ccv

test_that("the Ccv follows the book's formula and reproduces its worked totals", {
  # Example 3 (pp. 145-146): ten items, five judges all rating 1 on a 1-3
  # scale. The book gives Ccv_t = .333, p_e = .00032 and Ccv_tc = .33268,
  # the last from .333 rounded; the formula gives 1/3 - 1/3125.
  all1 <- matrix(1, 5, 10, dimnames = list(NULL, paste0("I", 1:10)))
  r1 <- ccv(all1, colnames(all1), lo = 1, hi = 3)
  expect_equal(r1$pe, rep(1 / 3125, 10))
  expect_equal(round(mean(r1$ccv), 3), .333)
  expect_equal(mean(r1$ccv_corrected), 1 / 3 - 1 / 3125)

  # Example 5 (Table 6, pp. 147-148): all rating 3 on a 1-3 scale, which the
  # book totals as Ccv_t = 1 and Ccv_tc = .99968.
  all3 <- matrix(3, 5, 10, dimnames = list(NULL, paste0("I", 1:10)))
  r3 <- ccv(all3, colnames(all3), lo = 1, hi = 3)
  expect_equal(mean(r3$ccv), 1)
  expect_equal(mean(r3$ccv_corrected), .99968)
})

test_that("the Ccv cannot see agreement, as the book's own Table 7 shows", {
  # Items 01 and 03 of Table 7 (pp. 148-149): the same mean, so the same .60,
  # although one panel spreads across the scale and the other is unanimous.
  t7 <- cbind(I01 = c(1, 3, 4, 5, 2), I03 = c(3, 3, 3, 3, 3))
  r7 <- ccv(t7, colnames(t7), lo = 1, hi = 5)
  expect_equal(r7$ccv, c(.60, .60))
  expect_identical(r7$ccv_corrected[1], r7$ccv_corrected[2])
})

test_that("the Ccv correction depends only on the judges who rated each item", {
  # p. 132: the term is item-specific when some judges skip an item.
  R <- cbind(A = c(4, 4, 4, NA), B = c(4, 4, 4, 4))
  r <- ccv(R, colnames(R), lo = 1, hi = 4)
  expect_identical(r$J, c(3L, 4L))
  expect_equal(r$pe, c((1 / 3)^3, (1 / 4)^4))
  # The same judges, very different ratings: the same correction.
  s <- ccv(cbind(A = c(1, 4, 1, 4), B = c(4, 4, 4, 4)), c("A", "B"), 1, 4)
  expect_identical(s$pe[1], s$pe[2])
})

test_that("from 0 the Ccv is Aiken's V; from 1 it cannot fall below 1/max", {
  z <- cbind(A = c(5, 5, 4, 5), B = c(3, 4, 3, 2), C = c(0, 1, 0, 1))
  fit <- expert_validity(z, mode = "relevance", lo = 0, hi = 5,
                         agreement = "none")
  expect_equal(fit$details$earlier_methods$ccv$ccv, fit$results$V)

  lowest <- matrix(1, 4, 2, dimnames = list(NULL, c("A", "B")))
  low <- expert_validity(lowest, mode = "relevance", lo = 1, hi = 4,
                         agreement = "none")
  expect_equal(low$details$earlier_methods$ccv$ccv, c(.25, .25))
  expect_equal(low$results$V, c(0, 0))

  # A scale below 0 has no Ccv.
  expect_true(all(is.na(ccv(cbind(A = c(-1, 2)), "A", lo = -2, hi = 2)$ccv)))
})

test_that("the Ccv uses the book's bands as stated on p. 120", {
  lab <- contentvalidR:::.ccv_label
  expect_identical(lab(c(.79968, .80, .8999, .90, 1)),
                   c("unacceptable", "satisfactory", "satisfactory",
                     "excellent", "excellent"))
  # Example 11 (p. 155): every judge rates 4 on a 1-5 scale. The book calls
  # the result, .7968, acceptable; by its own bands it is not.
  all4 <- matrix(4, 5, 10, dimnames = list(NULL, paste0("I", 1:10)))
  expect_identical(unique(ccv(all4, colnames(all4), 1, 5)$label),
                   "unacceptable")
})

test_that("every place the Ccv appears states its shortcomings", {
  t7 <- cbind(I01 = c(1, 3, 4, 5, 2), I03 = c(3, 3, 3, 3, 3))
  fit <- expert_validity(t7, mode = "relevance", lo = 1, hi = 5,
                         agreement = "none", legacy = TRUE)
  out <- gsub("[[:space:]]+", " ",
              paste(utils::capture.output(print(fit)), collapse = " "))
  expect_match(out, "cannot reflect agreement", fixed = TRUE)
  expect_match(out, "depends only on the number of judges", fixed = TRUE)
  expect_match(out, "cannot fall below .20 (1/5)", fixed = TRUE)
  expect_match(out, "stated without derivation", fixed = TRUE)
  expect_match(out, "does not decide anything", fixed = TRUE)

  rd_path <- testthat::test_path("..", "..", "man", "expert_validity.Rd")
  skip_if_not(file.exists(rd_path), "package documentation is not available")
  rd <- gsub("[[:space:]]+", " ", paste(readLines(rd_path, warn = FALSE),
                                        collapse = " "))
  expect_match(rd, "cannot reflect agreement", fixed = TRUE)
  expect_match(rd, "depends on neither the ratings nor the number of scale",
               fixed = TRUE)
  expect_match(rd, "never informs a decision", fixed = TRUE)
})

test_that("an object saved before the Ccv existed prints without it", {
  fit <- expert_validity(cbind(A = c(4, 4, 3), B = c(2, 3, 2)),
                         mode = "relevance", lo = 1, hi = 4,
                         agreement = "none")
  fit$details$earlier_methods$ccv <- NULL
  out <- paste(utils::capture.output(print(fit, legacy = TRUE)), collapse = " ")
  expect_false(grepl("Ccv", out, fixed = TRUE))
  expect_match(out, "Fleiss", fixed = TRUE)
})

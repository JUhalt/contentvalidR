# Regression coverage for issue #11: interpretive output is part of the public
# contract. Wording that users rely on to read results correctly must not
# silently disappear.

sort_fixture <- function() {
  sort_validity(utils::read.csv(
    system.file("extdata", "sort_example.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE
  ))
}

rating_fixture <- function() {
  rating_validity(utils::read.csv(
    system.file("extdata", "rating_example.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE
  ))
}

expert_fixture <- function() {
  d <- utils::read.csv(
    system.file("extdata", "expert_relevance_example.csv", package = "contentvalidR"),
    stringsAsFactors = FALSE
  )
  expert_validity(as.matrix(d[, setdiff(names(d), "expert")]),
                  mode = "relevance", lo = 1, hi = 4)
}

judge_fixture <- function() {
  r <- rbind(
    c(4, 4, 4, 3, 2, 2), c(4, 4, 3, 4, 2, 1), c(4, 3, 4, 4, 1, 2),
    c(3, 4, 4, 4, 2, 2), c(4, 4, 4, 4, 2, 1), c(4, 3, 4, 3, 1, 2),
    c(4, 4, 3, 4, 2, 2), c(2, 2, 2, 2, 1, 1)
  )
  dimnames(r) <- list(paste0("Judge", 1:8), paste0("Item", 1:6))
  judge_validity(r, lo = 1, hi = 4)
}

domain_fixture <- function() {
  domain_validity(
    data.frame(
      item = paste0("I", 1:7),
      construct = c("Autonomy", "Autonomy", "Autonomy", "Autonomy",
                    "Competence", "Competence", "Relatedness"),
      stringsAsFactors = FALSE
    ),
    cell_col = "construct",
    domain = c("Autonomy", "Competence", "Relatedness", "Belonging")
  )
}

printed <- function(x) paste(utils::capture.output(print(x)), collapse = " ")

test_that("the glossary covers every workflow and defines the shared statuses", {
  g <- contentvalid_glossary()
  expect_s3_class(g, "contentvalid_glossary")
  expect_true(all(c("term", "workflow", "label", "definition", "range") %in% names(g)))

  expect_setequal(
    unique(g$workflow),
    c("item-sort", "construct-rating", "expert-panel",
      "judge-heterogeneity", "domain-coverage", "delphi")
  )

  statuses <- attr(g, "statuses")
  expect_setequal(statuses$status, contentvalidR:::.workflow_status_levels)
  expect_true(all(nzchar(statuses$meaning)))

  # Every defined term must carry a real definition, not a placeholder.
  expect_true(all(nzchar(g$definition)))
  expect_true(all(nchar(g$definition) > 30))
})

test_that("glossary filtering works and rejects unknown workflows", {
  sub <- contentvalid_glossary("item-sort")
  expect_true(all(sub$workflow == "item-sort"))
  expect_true("psa" %in% sub$term)
  expect_false("htc" %in% sub$term)

  expect_error(contentvalid_glossary("nonsense"), "must be one of")
  expect_error(contentvalid_glossary(c("a", "b")), "one workflow name")
})

test_that("every term printed as a key is defined in the glossary", {
  defined <- contentvalid_glossary()$term
  # Terms referenced by the print methods, gathered here so that adding a key
  # term without a definition fails loudly.
  referenced <- c("psa", "psa_low/psa_high", "csv", "competitor", "p_value",
                  "htc", "htd",
                  "V", "I_CVI", "I_CVI_low/I_CVI_high", "kappa_mod", "cvr", "ioc",
                  "severity", "infit/outfit", "differentiation",
                  "phi_coefficient", "g_coefficient",
                  "share", "adjusted_rand", "stress")
  expect_true(all(referenced %in% defined))
})

test_that("printed output defines its abbreviated columns", {
  out <- printed(sort_fixture())
  expect_match(out, "What these columns mean")
  expect_match(out, "Proportion of Substantive Agreement")
  expect_match(out, "Coefficient of Substantive Validity")

  out_r <- printed(rating_fixture())
  expect_match(out_r, "Hinkin-Tracey Correspondence")
  expect_match(out_r, "Hinkin-Tracey Distinctiveness")

  out_e <- printed(expert_fixture())
  expect_match(out_e, "Item-level Content Validity Index")
  expect_match(out_e, "Modified kappa")
})

test_that("printed output explains the shared status vocabulary", {
  for (fit in list(sort_fixture(), rating_fixture(), expert_fixture())) {
    out <- printed(fit)
    expect_match(out, "What the status labels mean")
    # Wrapping inserts run-on whitespace, so match flexibly on the sentence.
    expect_match(out, "not an instruction\\s+to delete anything")
    # Workflow-specific wording must be connected to the shared vocabulary.
    expect_match(out, "its own wording in the decision column")
  }
})

test_that("every flagship workflow says Review is not a deletion decision", {
  expect_match(printed(sort_fixture()), "not an automatic deletion decision")
  expect_match(printed(rating_fixture()), "not an automatic deletion decision")
  expect_match(printed(judge_fixture()), "not a judge to remove")
})

test_that("every flagship workflow states what it cannot establish", {
  expect_match(printed(summary(sort_fixture())), "does not by itself establish")
  expect_match(printed(summary(expert_fixture())), "do not replace, qualitative content review")
  expect_match(printed(expert_fixture()), "alongside expert comments")
  expect_match(printed(summary(judge_fixture())), "does not establish that the items cover")
  expect_match(printed(domain_fixture()), "does not show that")
})

test_that("benchmark labels are marked as norms and as non-comparable across indices", {
  out <- printed(sort_fixture())
  expect_match(out, "percentile norms")
  expect_match(out, "not universal cutoffs")
  expect_match(out, "not comparable with each other")

  # The HTC/HTD case is the one users misread, so it is called out explicitly.
  out_r <- printed(rating_fixture())
  expect_match(out_r, "HTC is an average rating and HTD is a difference")
  expect_match(out_r, "never against the other index's number")
})

test_that("the documented HTC/HTD contrast really occurs in the shipped example", {
  # The vignette and print output both claim a high HTC can be labelled Weak
  # while a much smaller HTD is Very Strong. Verify that against real output so
  # the explanation cannot drift away from the behaviour it explains.
  s <- rating_fixture()$scale_summary
  expect_true(any(s$htc_strength == "Weak" & s$htd_strength == "Very Strong"))
  row <- s[s$htc_strength == "Weak" & s$htd_strength == "Very Strong", ][1, ]
  expect_gt(row$mean_htc, row$mean_htd)
})

test_that("the inline key can be switched off without affecting results", {
  old <- options(contentvalidR.show_key = FALSE)
  on.exit(options(old), add = TRUE)
  out <- printed(sort_fixture())
  expect_false(grepl("What these columns mean", out, fixed = TRUE))
  # Substantive cautions remain even when the teaching key is hidden.
  expect_match(out, "not an automatic deletion decision")
  expect_match(out, "percentile norms")
})

test_that("the key is shown by default", {
  old <- options(contentvalidR.show_key = NULL)
  on.exit(options(old), add = TRUE)
  expect_match(printed(sort_fixture()), "What these columns mean")
})

test_that("new v0.2 workflows meet the same interpretive standard as existing ones", {
  for (fit in list(judge_fixture(), domain_fixture())) {
    out <- printed(fit)
    expect_match(out, "What these columns mean")
    expect_match(out, "contentvalid_glossary")
    # Every row carries a plain-language interpretation.
    expect_true(all(nzchar(fit$results$interpretation)))
    expect_true(all(nchar(fit$results$interpretation) > 40))
  }
})

test_that("glossary print output warns against cross-index comparison", {
  out <- printed(contentvalid_glossary())
  expect_match(out, "percentile positions")
  expect_match(out, "not\\s+comparable across different indices")
  expect_match(out, "status labels")
})

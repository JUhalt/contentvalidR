# Stage 2, inner: exercise the installed package in a session whose library
# path holds only base R and the fresh install. Version-agnostic, so it does
# not have to be edited for each release.

library(contentvalidR)
version <- as.character(utils::packageVersion("contentvalidR"))
cat("library paths:\n")
print(.libPaths())
cat("version: ", version, "\n", sep = "")
cat("installed at: ", find.package("contentvalidR"), "\n", sep = "")

failures <- character()
note <- function(ok, what) {
  cat(if (ok) "ok   " else "FAIL ", what, "\n", sep = "")
  if (!ok) failures <<- c(failures, what)
}

grDevices::pdf(NULL)
topics <- sub("[.]Rd$", "", names(tools::Rd_db("contentvalidR")))
broken <- character()
for (topic in topics) {
  tryCatch(
    utils::capture.output(utils::example(topic, package = "contentvalidR",
                                         character.only = TRUE, ask = FALSE,
                                         echo = FALSE)),
    error = function(e) broken <<- c(broken, paste0(topic, ": ", conditionMessage(e)))
  )
}
grDevices::dev.off()
note(!length(broken), paste0("every help topic's examples ran (",
                             length(topics) - length(broken), " of ",
                             length(topics), ")"))
if (length(broken)) cat(paste(broken, collapse = "\n"), "\n")

# Published values, recomputed from the installed package rather than trusted:
# Chaffin & Talley (1980), Table 3a.
O <- rbind(c(8, 13, 5), c(20, 38, 13), c(5, 11, 9))
cells <- which(O > 0, arr.ind = TRUE)
x1 <- rep(cells[, 1], O[cells])
x2 <- rep(cells[, 2], O[cells])
d <- data.frame(expert = rep(seq_along(x1), 2), item = "Q",
                round = rep(2:3, each = length(x1)), rating = c(x1, x2))
stat <- function(method) {
  delphi_validity(d, lo = 1, hi = 3, stability = method, B = 0)$details$stability$value
}
note(isTRUE(all.equal(stat("chisq_individual"), 3.70, tolerance = 1e-3)),
     "Chaffin & Talley individual chi-square is 3.70")
note(isTRUE(all.equal(stat("chisq_group"), 1.516, tolerance = 1e-3)),
     "Chaffin & Talley group chi-square is 1.516")
note(isTRUE(all.equal(stat("lambda"), 0)), "Goodman-Kruskal lambda is 0")
note(isTRUE(all.equal(stat("percent_change"), 9 / 122)),
     "Scheibe net change is 9/122")

# Cohen (1968), Table 1: weighted kappa of .348 on his weights.
counts <- rbind(c(88, 14, 18), c(10, 40, 10), c(2, 6, 12))
cc <- which(counts > 0, arr.ind = TRUE)
k1 <- rep(cc[, 1], counts[cc])
k2 <- rep(cc[, 2], counts[cc])
V <- rbind(c(0, 1, 3), c(1, 0, 6), c(3, 6, 0))
kw <- contentvalidR:::.delphi_weighted_kappa(k1, k2, V)
note(isTRUE(all.equal(round(kw, 3), 0.348)), "Cohen's Table 1 weighted kappa is .348")

# The handoff's shape, which another package reads.
rel <- matrix(c(4,4,4,3, 4,4,3,4, 3,4,4,4, 2,2,1,2), nrow = 4,
              dimnames = list(NULL, paste0("Item", 1:4)))
h <- content_handoff(expert_validity(rel, mode = "relevance", lo = 1, hi = 4,
                                     seed = 1))
expected <- c("item", "statistic", "value", "criterion", "round", "lower",
              "upper", "interval_method", "interval_level", "note")
note(identical(names(h$item_statistics), expected),
     "item_statistics carries the agreed columns, in order")
note(identical(h$provenance$schema_version, 1L), "handoff is schema version 1")
note(is.character(h$item_statistics$note) && !anyNA(h$item_statistics$note),
     "note is character with no NA")

vigs <- utils::vignette(package = "contentvalidR")$results[, "Item"]
note(length(vigs) >= 9, paste0(length(vigs), " vignettes installed"))
note("delphi-rounds" %in% vigs, "delphi-rounds vignette installed")

cit <- utils::capture.output(print(utils::citation("contentvalidR"), style = "text"))
note(any(grepl(version, cit, fixed = TRUE)),
     paste0("citation names version ", version))

cat("\n", length(failures), " failure(s)\n", sep = "")
if (length(failures)) quit(status = 1)

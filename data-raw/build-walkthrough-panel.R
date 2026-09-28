# Build the expert relevance panel for the walkthrough items.
#
# The ratings are CONSTRUCTED. No expert was consulted. They give the twelve
# walkthrough items a second source of content evidence, so that
# content_evidence() and the distribution plot have something to compare, and
# they are written out by hand below so every rating can be read and checked.
#
# This is a separate script from build-walkthrough-data.R on purpose: that
# script's three files are mirrored by nomologR and must not change, and adding
# random draws to it would. Nothing here is random. Run it from the package
# root. It writes one file into inst/extdata:
#
#   walkthrough_relevance.csv  eight experts' relevance ratings, 1 to 4
#
# Eight experts rated how relevant each item is to Study Persistence, on the
# usual four-point scale: 1 not relevant, 2 somewhat, 3 quite, 4 highly
# relevant. A rating of 3 or 4 counts as relevant, and with eight experts
# Lynn's (1986) criterion is 7 of 8.
#
# What the panel is built to show, beside the item sort:
#
#   EF5  Reads as anxiety rather than persistence, so only 4 of 8 rate it
#        relevant. The panel holds it back, as the sort does.
#   EF6  Meets the criterion exactly, 7 of 8, as it meets the sort's by one
#        judge.
#   EF1  All eight rate it relevant, mostly with a 4.
#   EF3  All eight rate it relevant too, but seven of them with a 3: the same
#        I-CVI as EF1 from a lukewarm panel, which only the full distribution
#        shows.
#   TF5  Relevant to the construct by every expert. Only the sort shows that
#        judges place it in the other facet: the two sources disagree.
#   EF4, TF4  Pass here as they pass the sort. Their problems appear only in
#        the response data, which is the point of the second stage.

relevance <- data.frame(
  expert = 1:8,
  EF1 = c(4, 4, 4, 4, 3, 4, 4, 4),
  EF2 = c(4, 3, 4, 4, 4, 3, 4, 4),
  EF3 = c(3, 3, 3, 4, 3, 3, 3, 3),
  EF4 = c(4, 4, 3, 4, 4, 4, 4, 3),
  EF5 = c(2, 3, 2, 3, 4, 2, 3, 2),
  EF6 = c(4, 3, 4, 3, 4, 4, 2, 4),
  TF1 = c(4, 4, 4, 4, 4, 4, 4, 4),
  TF2 = c(3, 4, 4, 3, 4, 4, 3, 4),
  TF3 = c(4, 4, 3, 4, 4, 4, 3, 4),
  TF4 = c(3, 4, 3, 4, 3, 4, 4, 3),
  TF5 = c(4, 4, 3, 4, 4, 3, 4, 4),
  TF6 = c(4, 3, 4, 4, 3, 4, 4, 4)
)

write.csv(relevance, file.path("inst", "extdata", "walkthrough_relevance.csv"),
          row.names = FALSE)

# contentvalidR example data

These CSV files are deliberately human-readable examples of the input shapes used
by the three flagship workflows. They are synthetic and contain no participant
or proprietary data.

- `sort_example.csv`: item-sort assignments for `sort_validity()`.
- `rating_example.csv`: fully crossed construct ratings for `rating_validity()`.
- `expert_relevance_example.csv`: 1-4 relevance ratings for expert-panel relevance mode.
- `expert_essentiality_example.csv`: binary essentiality judgments for CVR mode.
- `expert_congruence_example.csv`: long-format -1/0/+1 item-objective ratings for IOC mode.

The deterministic source that generates all five files is
`data-raw/build-example-data.R`. The examples intentionally include both clearly
supported and review-worthy items so printed output, summaries, and plots are
informative.

## The joint walkthrough data

Three further files carry one item set through both stages of pretesting, for
`vignette("one-item-set-both-stages")`:

- `walkthrough_items.csv`: the twelve items, their intended facet, their stems,
  what each item was built to do (`role`), and whether it is written the other
  way round (`reverse_worded`, for `content_handoff(reverse_keyed = )`).
- `walkthrough_sort.csv`: twenty judges' assignments, for `sort_validity()`.
- `walkthrough_responses.csv`: 400 respondents by 12 items on a 1-5 scale, plus
  a two-level `cohort` variable. Items the panel rejected are still present, so
  a reader can see what keeping them would have cost.

These are simulated. Two items are reverse-worded, so the raw responses must be
recoded before anything is correlated. Five more misbehave deliberately: two
fail content review for opposite reasons, one passes and then carries almost no
common variance, one passes and loads on two facets, and one is flagged by an
empirical screen for restricted variance while being worth keeping. The generating model
is stated in full in `data-raw/build-walkthrough-data.R`, which writes all
three files. `nomologR` ships `walkthrough_items.csv` and
`walkthrough_responses.csv` unchanged, with that same script, so the two
packages cannot drift.

One more file gives the same twelve items a second source of content evidence,
for `content_evidence()` and `plot(type = "distribution")`:

- `walkthrough_relevance.csv`: eight experts' 1-4 relevance ratings, one row
  per expert and one column per item, for `expert_validity()` in relevance
  mode.

These ratings are constructed by hand rather than simulated, and
`data-raw/build-walkthrough-panel.R` states what each item's ratings are built
to show. It is a separate script so that the three mirrored files above never
change.

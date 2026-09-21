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
  and, in `role`, what each item was built to do.
- `walkthrough_sort.csv`: twenty judges' assignments, for `sort_validity()`.
- `walkthrough_responses.csv`: 400 respondents by 12 items on a 1-5 scale, plus
  a two-level `cohort` variable. Items the panel rejected are still present, so
  a reader can see what keeping them would have cost.

These are simulated. Four items misbehave deliberately: one passes content
review and then carries almost no common variance, one passes and loads on two
facets, and two fail content review for opposite reasons. The generating model
is stated in full in `data-raw/build-walkthrough-data.R`, which writes all
three files. `nomologR` mirrors `walkthrough_responses.csv` from that same
script so the two packages cannot drift.

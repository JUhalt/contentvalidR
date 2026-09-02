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

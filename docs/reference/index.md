# Package index

## Flagship workflows

Recommended user-facing analyses for scale content pretesting.

- [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  : Analyze an item-sort content-validity pretest
- [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
  : Analyze a Hinkin-Tracey construct-rating content-validity pretest
- [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  : Analyze expert-panel content-validity evidence

## Workflow plotting methods

Diagnostic plots for the flagship workflow objects and exact sort-power
plans.

- [`plot(`*`<contentvalid_sort>`*`)`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_sort.md)
  : Plot item-sort evidence
- [`plot(`*`<contentvalid_rating>`*`)`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_rating.md)
  : Plot Hinkin-Tracey rating evidence
- [`plot(`*`<contentvalid_expert>`*`)`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_expert.md)
  : Plot expert-panel content-validity results
- [`plot(`*`<contentvalid_sort_power>`*`)`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_sort_power.md)
  : Plot exact item-sort planning evidence

## Item-sort components and planning

- [`compute_psa()`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md)
  : Proportion of Substantive Agreement (Psa)
- [`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md)
  : Substantive Validity Coefficient (Csv)
- [`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md)
  : Exact item-sort significance test
- [`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md)
  : Exact power for the item-sort target-count rule
- [`colquitt_benchmarks()`](https://juhalt.github.io/contentvalidR/reference/colquitt_benchmarks.md)
  : Colquitt et al. (2019) empirical content-validation benchmarks
- [`interpret_colquitt()`](https://juhalt.github.io/contentvalidR/reference/interpret_colquitt.md)
  : Interpret a statistic using Colquitt et al. (2019) norms

## Construct-rating components

- [`htc()`](https://juhalt.github.io/contentvalidR/reference/htc.md) :
  Hinkin-Tracey correspondence (HTC)
- [`htd()`](https://juhalt.github.io/contentvalidR/reference/htd.md) :
  Hinkin-Tracey distinctiveness (HTD)
- [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
  : Hinkin-Tracey ANOVA content test

## Expert-panel indices

- [`aikens_v()`](https://juhalt.github.io/contentvalidR/reference/aikens_v.md)
  : Aiken's V for expert content-relevance ratings
- [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) :
  Content Validity Index (CVI)
- [`cvr()`](https://juhalt.github.io/contentvalidR/reference/cvr.md) :
  Lawshe's Content Validity Ratio (CVR)
- [`ioc()`](https://juhalt.github.io/contentvalidR/reference/ioc.md) :
  Item-Objective Congruence (IOC)

## Auxiliary and compatibility helpers

Retained utilities that are not flagship v0.1.0 workflows.

- [`agreement_summary()`](https://juhalt.github.io/contentvalidR/reference/agreement_summary.md)
  : Agreement summary (auxiliary)
- [`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
  : Q-factor helper for content adequacy (comparator)
- [`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md)
  : Signal-detection summary for binary retention decisions
- [`reproducibility_phi()`](https://juhalt.github.io/contentvalidR/reference/reproducibility_phi.md)
  : Between-pretest reproducibility (phi) of binary decisions
- [`simulate_anova_power()`](https://juhalt.github.io/contentvalidR/reference/simulate_anova_power.md)
  : Legacy independent-groups ANOVA power simulator
- [`simulate_csv_power()`](https://juhalt.github.io/contentvalidR/reference/simulate_csv_power.md)
  : Legacy simulation of item-sort target-count power

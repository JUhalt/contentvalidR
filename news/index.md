# Changelog

## contentvalidR 0.5.0.9000 (development version)

### A Delphi study can hand off (in development)

- [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
  now accepts a
  [`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md)
  fit ([\#42](https://github.com/JUhalt/contentvalidR/issues/42)). It
  used to refuse one, and its message did not even mention Delphi.
  - **Each item travels with its own last round.** A Delphi settles one
    item at a time: an item that reached consensus early was set aside
    before the final round. `round` now holds that round’s index, so it
    varies between items. This is the first workflow where it carries
    real information.
  - **Relevance evidence comes from the item’s last round,** taken from
    that round’s
    [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
    fit, with intervals: `I-CVI` against the consensus threshold,
    `Aiken's V`, and `modified kappa`. Modified kappa carries no
    criterion, because a Delphi decides on the consensus threshold
    rather than on the 0.74 rule.
  - **Stability travels as evidence**, never as a carry decision:
    `proportion unchanged` plus the statistic that ran, named for its
    method, such as `weighted kappa (quadratic)` or
    `Goodman-Kruskal lambda`. The chi-square methods add
    `stability p_value`. The names are qualified so a downstream report
    cannot misread them
    ([nomologR#46](https://github.com/JUhalt/nomologR/issues/46)).
  - `round` cannot be set by hand for a Delphi fit, since the fit
    supplies it.
- No schema change. These are new values in existing columns, so a
  schema version 1 reader still reads the object.

## contentvalidR 0.5.0

Fifth public release. v0.5.0 adds a workflow for Delphi studies, where
the same expert panel rates items over successive rounds. It reports
consensus and stability as separate questions, and every published
stability method is available with its limits printed. The handoff to
empirical validation now carries each statistic’s interval, so a
downstream analysis can see how much panel evidence stands behind a
number.

The package continues to declare `Imports: stats` only.

No default changes. Existing calls return the same values as in 0.4.0.
[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
objects gain four interval columns in `item_statistics` and a
`panel_statistics` table, within schema version 1.

New function:
[`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md).
New article:
[`vignette("delphi-rounds")`](https://juhalt.github.io/contentvalidR/articles/delphi-rounds.md).

This release is published on GitHub and R-universe. 0.4.0 is still in
CRAN’s review queue, and CRAN policy asks that no further version be
submitted while one is pending, so 0.5.0 will be submitted to CRAN later
as an update.

### Delphi consensus and stability

- New workflow
  [`delphi_validity()`](https://juhalt.github.io/contentvalidR/reference/delphi_validity.md)
  for an expert panel rated over successive Delphi rounds
  ([\#20](https://github.com/JUhalt/contentvalidR/issues/20)). It
  reports two questions separately. **Consensus**: whether enough
  experts agree now. **Stability**: whether experts are still changing
  their ratings.
  - **Consensus** is the share of experts rating an item at or above
    `agree_cut`, which on a relevance scale is the I-CVI. It is judged
    against a `consensus_threshold` fixed before the study. There is
    deliberately no default: without a threshold, results are
    descriptive (Diamond et al., 2014).
  - **Stability** always reports the share of experts who kept their
    rating. Beside it goes one statistic:
    - the default, weighted kappa between rounds (Holey et al., 2007),
      read as a trend. Quadratic weights, the default, make it the
      intraclass correlation of the two rounds (Fleiss & Cohen, 1973);
      linear weights are available (Cohen, 1968);
    - Chaffin & Talley’s (1980) lambda;
    - Chaffin & Talley’s individual chi-square;
    - Dajani, Sincoff & Talley’s (1979) group chi-square;
    - Scheibe, Skutsch & Schofer’s (1975) 15% net-change rule.

    Each alternative’s limits are printed. The two chi-square tests read
    in opposite directions, and the printout says which is which.
  - **No verbal kappa labels.** Landis & Koch (1977) call their
    divisions arbitrary, and kappa falls as a panel converges. When a
    round is unanimous, kappa is 0 however many experts kept their
    rating; the output flags this and points to the share unchanged.
  - **A bootstrap interval for kappa**, resampling experts, marked as
    this package’s extension.
  - **Round-by-round relevance evidence.** Each round is also fitted
    with
    [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md),
    so
    [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
    can read the whole process.
- New vignette,
  [`vignette("delphi-rounds")`](https://juhalt.github.io/contentvalidR/articles/delphi-rounds.md),
  walks through a three-round panel for a graduate reader. Its worked
  example covers:
  - a statement set aside after reaching consensus;
  - an expert leaving the panel;
  - consensus against a statement;
  - a stable split;
  - a panel converging to unanimity, where kappa drops to 0;
  - experts swapping ratings while the overall distribution stays still,
    which only individual stability detects.
- `contentvalid_glossary("delphi")` defines the new columns.
- Every published value used to design the workflow is a test: Cohen’s
  1968. Table 1, Fleiss & Cohen’s equivalence, and the worked examples
        of Dajani et al. and Chaffin & Talley.

### Interval bounds in the handoff

- [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md)
  now carries each statistic’s interval
  ([\#33](https://github.com/JUhalt/contentvalidR/issues/33)), so a
  reader can tell a unanimous four-judge panel from a unanimous
  twenty-judge one. A unanimous I-CVI from four experts has a Wilson 95%
  lower limit near 0.51.
  - `item_statistics` gains `lower`, `upper`, `interval_method`, and
    `interval_level`. They hold the Penfield-Giacobbi score interval for
    Aiken’s V, and whichever `proportion_ci` method was chosen for I-CVI
    and Psa.
  - A new `panel_statistics` table carries the panel agreement
    coefficient and its bootstrap interval, which are not per item.
  - `NA` in all four columns means the statistic has no interval, never
    missing data.
- These additions stay within schema version 1, as agreed with nomologR
  on [nomologR#46](https://github.com/JUhalt/nomologR/issues/46).
  - Existing fields keep their names, types, meaning, and column
    positions.
  - A reader should check that the new columns are present before using
    them.
- The handoff reports intervals only. It does not turn them into priors
  or weights.

## contentvalidR 0.4.0

Fourth public release. v0.4.0 connects content validation to what comes
after it: a documented handoff carries the items that survived content
review, and the evidence behind each decision, into empirical scale
development. It also adds a stricter, selectable criterion for parallel
analysis, and fixes the two packaging problems that returned the 0.3.x
CRAN submissions.

The package continues to declare `Imports: stats` only.

No default changes. Existing calls return the same values as in 0.3.1;
[`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
results gain two fields recording the parallel analysis criterion that
ran.

New function:
[`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md).

### Handoff to empirical validation

- Added
  [`content_handoff()`](https://juhalt.github.io/contentvalidR/reference/content_handoff.md),
  which packages a finished workflow’s item decisions for the next stage
  of scale development
  ([\#27](https://github.com/JUhalt/contentvalidR/issues/27)). It
  carries the item names that survived content review, the construct
  each belongs to where the design defines one, a per-item evidence
  table with the decision rule that was applied, the statistics behind
  each decision, and the provenance of the analysis.
- The object shape is schema version 1, agreed with the `nomologR`
  package, which consumes it in `nomo_screen()` and `nomo_run()`. Every
  field is a base type, so neither package depends on the other.
- Items that do not meet `keep` stay in the evidence table with
  `carried = FALSE` rather than disappearing, and the printed output
  says plainly that surviving content review does not establish how an
  item will behave empirically.
- New vignette, *From Content Validity to Empirical Validation*, running
  from an expert panel through the handoff into an empirical workflow.

### Selectable parallel analysis criterion

- [`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
  gains `parallel_criterion`, choosing what parallel analysis compares
  observed eigenvalues against
  ([\#26](https://github.com/JUhalt/contentvalidR/issues/26)). `"mean"`
  stays the default, the rule Horn (1965) described and Zwick and
  Velicer (1986) evaluated. `"percentile"` compares against an upper
  percentile of the simulated eigenvalue distribution, following
  Glorfeld (1995), who found that Horn’s procedure still tends to retain
  one or two factors too many.
- The percentile level is selectable through `percentile`, defaulting
  to 95. Both criteria read the same simulation, so they are directly
  comparable from one seeded run, and the result records
  `parallel_criterion` and `percentile` alongside the comparison values
  in `parallel_eigen`.

### Packaging

- `.Rbuildignore` now excludes `.git`, `.gitignore`, and
  `.gitattributes`. Building a release tarball from a `git worktree`
  checkout writes `.git` as a *file* rather than a directory, which
  `R CMD build` does not drop, and CRAN’s incoming pretest reported it
  as a hidden file included in error
  ([\#14](https://github.com/JUhalt/contentvalidR/issues/14)).

## contentvalidR 0.3.1

Patch release for the CRAN submission. Package code, documentation of
methods, and results are unchanged from 0.3.0.

- README links to the license and the roadmap now use full URLs. The
  relative links pointed at files that are not part of the built
  package, which CRAN’s incoming checks report as invalid file URIs.

## contentvalidR 0.3.0

Third public release, and the first prepared for CRAN. Every addition
rests on published, verifiable methodology, and one design rule runs
through the release: where more than one published method exists,
researchers choose through an argument whose default is the
best-supported option. Methods with published evidence against them stay
available for reproducing earlier work, but they are never the default,
and selecting one prints the critique.

The package continues to declare `Imports: stats` only.

Two defaults change results for existing code.
[`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
now chooses the number of factors by parallel analysis, and
[`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
relevance mode now bootstraps an interval for panel agreement, so set
`seed` when printed output must be reproducible. Other existing results
are unchanged; the new interval and agreement columns are additions.

New function:
[`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md).

### Panel-level agreement for expert panels

- Added
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md),
  reporting one coefficient for how consistently an expert panel rated
  the whole item set, with a bootstrap interval. It complements the
  item-level I-CVI and modified kappa rather than replacing them.
- Krippendorff’s alpha is the default, computed from the coincidence
  matrix (Krippendorff, 2011) at a selectable measurement level: ordinal
  (the default), nominal, or interval. It reproduces the worked example
  in Krippendorff (2011) and agrees with
  [`irr::kripp.alpha()`](https://rdrr.io/pkg/irr/man/kripp.alpha.html).
- Gwet’s AC1 (Gwet, 2008) is available but is never the default, and
  selecting it prints the critique in Vach and Gerke (2023).
- Intervals resample items with all of their ratings, following Zapf et
  al. (2016), who found Krippendorff’s original bootstrap under-covered.
- [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  relevance mode reports panel agreement in its scale summary,
  controlled by `agreement`, `agreement_level`, `agreement_B`, and
  `seed`.
- Output reports the share of identical rating pairs next to the
  coefficient, and explains that alpha can be low when ratings cluster
  on one value, so a low alpha on a close-agreeing panel is not read as
  a poor panel.

### Evidence-based factor retention for `qfactor_content()`

- **Behavior change:**
  [`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
  now chooses the number of factors with Horn’s (1965) parallel analysis
  by default, instead of Kaiser’s eigenvalue-greater-than-1 rule. Calls
  that relied on the old default can return a different number of
  factors. Use `retention = "kaiser"` to reproduce earlier results; it
  prints the finding of Zwick and Velicer (1986) that the rule severely
  overestimates the number of components.
- Parallel analysis simulates random data with the same size and missing
  cells as the ratings. New `n_iter` and `seed` arguments control it,
  and the result records `retention`, `k_suggested`, and
  `parallel_eigen`.
- A supplied `k_factors` still takes precedence, and is recorded as
  `retention = "fixed"`.
- [`qfactor_content()`](https://juhalt.github.io/contentvalidR/reference/qfactor_content.md)
  now cites Schriesheim et al. (1993, 1999), and
  [`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md)
  cites Anderson and Gerbing (1991).

### Packaging

- `DESCRIPTION` now gives DOIs for the methods it cites, and citation
  metadata is stamped for 0.3.0.
- [`agreement_summary()`](https://juhalt.github.io/contentvalidR/reference/agreement_summary.md)
  and the [`plot()`](https://rdrr.io/r/graphics/plot.default.html)
  methods for sort, rating, expert, and sort-power objects now have
  runnable examples, so every help page shows how to use its function.
  [`agreement_summary()`](https://juhalt.github.io/contentvalidR/reference/agreement_summary.md)
  also points to
  [`panel_agreement()`](https://juhalt.github.io/contentvalidR/reference/panel_agreement.md).

### Selectable intervals for proportion indices

- [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) now
  reports an interval for each I-CVI (`I_CVI_low`, `I_CVI_high`), and
  [`compute_psa()`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md)
  does the same for each Psa (`psa_low`, `psa_high`). Both indices
  previously appeared as bare proportions, usually from small panels.
- The interval method is selectable: `ci` in those two functions, and
  `proportion_ci` in
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  and
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md).
  The options are the Wilson score interval (the default; Wilson, 1927),
  which Newcombe (1998) recommends over the Wald interval; the
  Agresti-Coull adjusted Wald interval (Agresti & Coull, 1998); and the
  Clopper-Pearson exact interval (Clopper & Pearson, 1934), which is
  conservative. Printed output names the method, the interval level, and
  the method’s limits.
- The new interval columns have their own names, so they never collide
  with the Aiken’s V `ci_low` and `ci_high` columns in
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md).
- Point estimates are unchanged.

## contentvalidR 0.2.0

Second public release. v0.1.0 established three item-level workflows;
v0.2.0 adds the two questions those workflows could not answer — whether
conclusions depend on the particular judges used, and whether the item
set covers its intended domain — together with multi-round comparison,
expert-panel planning, reporting helpers, and a substantial rework of
how results explain themselves.

The package continues to declare `Imports: stats` only. Every method
here is implemented in base R, so the package installs without a
compiler toolchain.

New flagship workflows:
[`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md)
and
[`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md).
New supporting functions:
[`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md),
[`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md),
[`similarity_from_sort()`](https://juhalt.github.io/contentvalidR/reference/similarity_from_sort.md),
[`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md),
[`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md),
[`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md),
[`contentvalid_glossary()`](https://juhalt.github.io/contentvalidR/reference/contentvalid_glossary.md),
and an [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
method for workflow objects.

### Multi-round comparison, planning, and reporting

- Added
  [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md),
  comparing two or more fitted workflow objects from successive pretest
  rounds. Reports each unit’s status in every round, whether it
  strengthened, weakened, or held, and which units entered or left the
  item set.
- [`compare_rounds()`](https://juhalt.github.io/contentvalidR/reference/compare_rounds.md)
  also compares the `settings` of each round and marks the comparison as
  not comparable when they differ. This is the audit trail the
  workstream called for: a status change under a changed criterion may
  reflect only the changed rule, and the output says so rather than
  letting a bookkeeping change read as progress.
- Comparisons across different workflows are refused, since status
  labels from different workflows rest on different criteria.
- Added
  [`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md),
  reporting the exact probability that an item clears its expert-panel
  criterion at a given panel size and assumed endorsement probability,
  for the panel-size I-CVI guideline or the Lawshe CVR critical count.
  It reports the consequences of the panel sizes asked about rather than
  recommending one.
- [`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md)
  makes the I-CVI criterion’s step visible instead of smoothing it:
  because the guideline requires unanimity up to five experts and 0.78
  from six, a fourth or fifth expert *lowers* the probability of
  clearing while a sixth raises it sharply. The plot is drawn as a step
  function for the same reason.
- [`expert_power()`](https://juhalt.github.io/contentvalidR/reference/expert_power.md)
  accepts a `response_rate` below 1, averaging over the realized panel
  size rather than assuming the invited panel arrives intact, which also
  captures the criterion that a smaller realized panel triggers.
- Added an
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) method
  for workflow objects, returning results or the scale summary as a
  plain data frame with a `workflow` column so tables from several
  analyses stack without losing their identity.
- Added
  [`content_report()`](https://juhalt.github.io/contentvalidR/reference/content_report.md),
  building a manuscript-ready table as a data frame or as Markdown for
  Quarto and R Markdown. Markdown is generated directly, so no reporting
  package is required and none is added as a dependency. Analysis
  settings travel with Markdown output as an attribute, and columns that
  are entirely missing are dropped.
- No helper is provided that returns “the items that passed.” Filtering
  on status is a substantive decision that belongs in the user’s own
  visible code, and `Review` never means an item must be dropped.

### Interpretable output

- Printed workflow output now defines the abbreviated quantities it
  reports. Each flagship workflow prints a key explaining, in plain
  language, what its columns measure and which direction is stronger,
  followed by the meaning of the shared status labels and a note
  connecting each workflow’s own recommendation wording to them.
- Added
  [`contentvalid_glossary()`](https://juhalt.github.io/contentvalidR/reference/contentvalid_glossary.md),
  a single source of those definitions. The inline keys and the glossary
  read from the same table, so a term cannot be defined differently in
  two places.
- Inline keys can be suppressed with
  `options(contentvalidR.show_key = FALSE)` once the terminology is
  familiar. Substantive cautions are never suppressed by that option.
- Benchmark output now states that strength labels are percentile
  positions relative to published scales and are **not comparable across
  indices**. This addresses a genuine misreading: HTC is an average
  rating while HTD is a difference between ratings, so a scale-level HTC
  of 0.83 is labeled `Weak` in the same row where an HTD of 0.44 is
  labeled `Very Strong`. Output now explains why, rather than leaving
  the contrast looking like an error.
- Added a “How to Read contentvalidR Output” vignette aimed at readers
  meeting these methods for the first time: an annotated walkthrough of
  every flagship workflow’s output field by field, a section on the
  benchmark trap above, a list of common misreadings, and worked
  manuscript language that reports what the analysis does and does not
  establish.
- Added regression coverage asserting that interpretive wording is
  present and stable, that every term shown in a key is defined in the
  glossary, and that the documented HTC/HTD contrast still occurs in the
  shipped example data, so the explanation cannot drift away from the
  behavior it explains.

### Domain coverage and content structure

- Added
  [`domain_validity()`](https://juhalt.github.io/contentvalidR/reference/domain_validity.md),
  a flagship workflow assessing whether an item set spans its intended
  content domain. Its `results` table has one row per blueprint cell,
  supporting construct-only or crossed construct-by-facet tables of
  specifications.
- Empty, thinly covered, and over-represented cells are reported against
  explicit, user-settable thresholds rather than silent defaults, and
  over-representation is documented as an attention-drawing heuristic
  rather than a standard. Intended item counts can be supplied through
  `targets` so expected shares come from the blueprint instead of an
  assumption of equal cells.
- Detecting a cell that the blueprint intends but no item addresses
  requires the full cell list to be supplied through `domain`. When it
  is omitted, the output states plainly that empty cells could not be
  detected, rather than implying full coverage.
- Added
  [`content_structure()`](https://juhalt.github.io/contentvalidR/reference/content_structure.md),
  implementing the multidimensional scaling and hierarchical cluster
  analysis of expert item-similarity data described by Sireci and
  Geisinger (1992, 1995). Correspondence between recovered clusters and
  blueprint cells is quantified with the chance-corrected adjusted Rand
  index and reported alongside the raw cross-tabulation.
- Multidimensional scaling fit is reported across dimensionalities with
  Kruskal stress-1 and its conventional descriptors, documented as
  descriptive conventions rather than rules for deciding how many
  dimensions a content domain has. A requested dimensionality beyond
  what the similarities support is reduced and the reduction is
  reported.
- Added
  [`similarity_from_sort()`](https://juhalt.github.io/contentvalidR/reference/similarity_from_sort.md),
  deriving item similarities from an item-sort task as the proportion of
  judges co-assigning each pair. The documentation states why this is
  weaker evidence than pairwise similarity ratings collected for the
  purpose.
- Added
  [`plot.contentvalid_structure()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_structure.md),
  drawing the expert content map with items labeled by blueprint cell.
- Weak blueprint correspondence is framed as a reason to re-examine the
  blueprint or item wording, explicitly not as grounds for deleting
  items.

### Judge and rater heterogeneity

- Added
  [`judge_validity()`](https://juhalt.github.io/contentvalidR/reference/judge_validity.md),
  a flagship workflow reporting how far content-validity conclusions
  depend on the particular judges who served on the panel. Unlike the
  item-oriented workflows, its `results` table has one row per judge.
- Added
  [`gtheory_content()`](https://juhalt.github.io/contentvalidR/reference/gtheory_content.md),
  implementing the generalizability-theory treatment of content-validity
  ratings in Crocker, Llabre, and Miller (1988). Reports item, judge,
  and residual variance components, generalizability (relative) and
  dependability (absolute) coefficients, and a decision study giving the
  panel size implied by a target coefficient.
- Added judge severity estimation from a many-facet Rasch model fitted
  as a logistic regression, following the generalized linear model
  formulation of de Boeck and Wilson (2004). Estimation is joint maximum
  likelihood with the standard Wright-Douglas bias correction applied
  and reported; the documentation states that the correction reduces
  rather than removes that bias, and that marginal maximum likelihood is
  preferable where precise calibration matters.
- Judges and items showing no variation in the dichotomized relevance
  decision are excluded from the facets model and reported, rather than
  producing infinite estimates. Because near-complete agreement is
  common in relevance ratings, severity in raw rating points is always
  reported and is used for flagging whenever the logit model is not
  estimable.
- Added descriptive rater-effect summaries for severity,
  differentiation, and central versus extreme category use, following
  the effects named in Engelhard (1994). Halo is deliberately not
  estimated from a single-dimension design, where it is not separable
  from low differentiation.
- Added leave-one-judge-out influence diagnostics identifying items
  whose CVI-based review status would change if any single judge were
  removed, and stating in the output that removing a judge also reduces
  the panel size and can therefore change the CVI criterion itself.
- Output states that a judge flagged for `Review` is not a judge to
  delete: disagreement may be substantive expertise, and the flag marks
  where a conclusion rests on one person’s ratings.
- Zero item-level true-score variance is now reported as a descriptive
  result explaining that judges did not distinguish the items, rather
  than as weak generalizability, and explicitly notes that a uniformly
  relevant item set produces the same value.

### Licensing and project infrastructure

- Relicensed the source to GNU GPL version 3 only (`GPL-3.0-only`; R
  metadata `GPL-3`), retaining the original MIT notice in `inst/NOTICE`.
  The previously published v0.1.0 release keeps its original MIT terms;
  this release does not relicense it retroactively.
- Stamped citation metadata to the released version and aligned the
  README release-status paragraph and roadmap links with the issues and
  milestone they track.
- Added repository infrastructure: contributing, support, security and
  code-of-conduct documents, issue and pull-request templates, and
  pkgdown and test-coverage workflows alongside the existing check
  matrix.
- Replaced the completed pre-v0.1 release roadmap with an active
  post-release development plan, and removed the obsolete committed
  `DESCRIPTION.bak` file.
- Hardened the Ubuntu GitHub Actions setup against stale Google Chrome
  apt repository metadata.
- CRAN submission is deferred to v0.3.0 and tracked separately, so that
  the completed v0.2.0 workstreams reach users through GitHub and the
  R-universe without waiting on a submission round.

## contentvalidR 0.1.0

### First public release

- First public release of `contentvalidR`, providing reproducible
  quantitative tools for substantive and content-oriented scale
  pretesting.
- The recommended API centers on three complementary workflows:
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  for item sorting,
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
  for construct ratings, and
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  for relevance, essentiality, and congruence expert panels.
- Item-sort inference combines Anderson-Gerbing Psa/Csv indices with
  exact Howard-Melloy target-count inference and scale-level Colquitt et
  al. empirical interpretation benchmarks.
- Construct-rating analyses implement Hinkin-Tracey correspondence and
  distinctiveness, repeated-measures item screening with
  Greenhouse-Geisser correction, planned target-versus-orbiting
  contrasts, and Colquitt et al. scale-level interpretation.
- Expert-panel analyses support Aiken’s V with Penfield-Giacobbi score
  confidence intervals, Lawshe CVR with exact inference, CVI/modified
  kappa, and item-objective congruence.
- Flagship workflow objects share a stable user-facing structure, common
  status terminology, informative print/summary/plot methods, explicit
  missingness and design metadata, and restrained review
  recommendations.
- The release includes deterministic example data,
  workflow/design/reporting vignettes, manuscript-ready reporting
  examples, citation metadata, extensive regression and
  boundary-condition tests, and a cross-platform release matrix
  including a dedicated R-devel `--as-cran` NOTE-as-failure gate.
- Quantitative screening is explicitly framed as one component of a
  broader validity argument rather than an automatic item-retention or
  deletion rule.

## contentvalidR 0.0.8.9000

### CRAN and release hardening

- Added a dedicated CRAN-style GitHub Actions job on R-devel with
  NOTE-as-failure, while retaining release/oldrel/devel checks across
  Windows, macOS, and Linux.
- Updated the workflow to `actions/checkout@v7` and current
  `r-lib/actions@v2` conventions.
- Hardened source-package exclusions for generated pkgdown output, CRAN
  submission metadata, check directories, and source tarballs.
- Added a reproducible `data-raw/release-check.R` developer checklist
  covering documentation, tests, README, standard and `--as-cran`
  checks, optional URL/spelling audits, and pkgdown construction.
- Added a draft `cran-comments.md` for the first submission; it is
  excluded from the built package and must be populated with actual
  final check results before submission.
- Synchronized the development roadmap through v0.0.7 and moved the
  remaining CI/public-repository verification items into the v0.0.8
  release checklist.

## contentvalidR 0.0.7.9000

### Documentation and reproducibility

- Added five deterministic, human-readable example datasets for
  item-sort, construct-rating, and all three expert-panel tasks, plus a
  base-R `data-raw/` provenance script that regenerates them.
- Added a manuscript-ready reporting vignette with conservative
  methods/results scaffolds, reproducibility guidance, and examples of
  language that avoids treating statistical review flags as automatic
  validity decisions.
- Added `inst/CITATION` for the package and a centralized
  `inst/REFERENCES.bib` bibliography covering the release-defining
  methods and verified DOIs.
- Completed missing DOI metadata in core function references for Aiken
  V, Hinkin-Tracey ratings, Lawshe CVR, Penfield-Giacobbi score
  intervals, and IOC-related sources.
- Added pkgdown reference/article organization that foregrounds the
  three flagship workflows and clearly separates auxiliary compatibility
  helpers.
- Added clean-install tests for documentation assets, example-data
  schemas, citation metadata, and the pkgdown/reference structure.

## contentvalidR 0.0.6.9000

### Stable user-facing workflow API

- Harmonized
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md),
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md),
  and
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  around a common workflow-object contract: `results`, `scale_summary`,
  `settings`, `design`, and `details`, with a shared
  `contentvalid_workflow` superclass.
- Added a standardized `status` field (`Supported`, `Review`,
  `Insufficient data`, or `Descriptive only`) while preserving
  method-specific `recommendation` wording such as `Retain`,
  `Strong support`, and `Target favored`.
- Harmonized [`summary()`](https://rdrr.io/r/base/summary.html) objects
  around common counts, reviewed-item tables, scale summaries, settings,
  and design metadata; retained `n_retain`, expert `scale`/`flagged`,
  and rating `contrasts` compatibility aliases.
- Standardized design metadata for effective judge ranges and
  missingness reporting across item-sort, construct-rating, and
  expert-panel workflows.
- Standardized validation of `digits` and plot `show_legend` controls
  across the primary workflow methods and exact sort-power planning
  object.
- Added compatibility handling so pre-v0.0.6 expert workflow objects
  remain printable and summarizable.
- Reviewed low-level function names and retained the existing public
  names through v0.1.0; auxiliary diagnostic, simulation, agreement, and
  Q-factor helpers remain available but are not promoted as flagship
  workflows.
- Added API regression tests and updated README/getting-started guidance
  for the unified workflow contract.

## contentvalidR 0.0.5.9000

### Release hardening

- Added centralized validation for logical flags and column-name
  arguments used across public workflows.
- Hardened rating data against non-finite values, malformed/duplicated
  target maps, empty identifiers, and ambiguous multi-scale `orbiting_r`
  specifications.
- Added clearer safeguards for within- versus between-judge ANOVA
  designs and for distinctiveness analyses with fewer than two construct
  definitions.
- Hardened expert-panel congruence target mappings, Aiken/CVI/CVR/IOC
  missing-data flags, alpha/seed/bootstrap inputs, and Colquitt
  benchmark input handling.
- Added defensive validation to legacy/auxiliary Q-factor, agreement,
  and simulation helpers while keeping them outside the recommended
  workflow surface.
- Added a dedicated v0.0.5 regression suite for malformed inputs,
  degenerate designs, legacy-helper contracts, and S3 workflow return
  contracts.
- Added boundary-focused regression coverage for all-missing item
  columns, tiny expert panels, zero-variance/tied rating profiles,
  degenerate diagnostic 2 x 2 tables, and all-missing workflow plots.
- Hardened exact item-sort inputs against non-finite
  counts/probabilities, made Aiken bootstrap intervals safe for
  all-missing item columns, and rejected whitespace-only target
  labels/target-column names.
- Represented unattainable exact CVR critical counts as `NA` (rather
  than an out-of-range sentinel) and hardened regression tests against
  brittle error-message wording.
- Closed the v0.0.5 public-API audit with an explicit namespace/export
  contract and S3 registration regression tests; corrected the generated
  namespace snapshot so
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  is available in clean installs and vignette builds.

## contentvalidR 0.0.4.9000

#### Final visualization polish

- Deterministically stagger nearby target-scale labels on Psa/Csv and
  HTC/HTD evidence maps so similar scale means remain legible without
  manual annotation.
- Draw the exact critical-Psa planning view as an integer-N step
  function, with requested design points overlaid, to reflect the
  discrete binomial retention rule rather than implying smooth
  interpolation.
- Added regression tests for map-label separation and the full integer
  critical-Psa curve.

#### Visualization polish

- Tightened default axis labels and plot keys so diagnostic graphics
  remain readable in smaller RStudio plotting panes.
- Moved profile/expert plot keys into reserved top space and moved
  item-sort power keys to a low-conflict location.
- Added `show_legend = FALSE` to workflow plot methods for
  compact/custom reporting.
- Reduced map-label collisions by separating item labels from
  target-scale-mean labels.
- Fixed the expert-panel vignette plotting object name and aligned the
  item-sort vignette index title with its YAML title.

### Visualization and roadmap closure

- Added correspondence-distinctiveness evidence maps for item-sort
  (Psa/Csv) and construct-rating (HTC/HTD) workflows, with target-scale
  means shown separately from item points.
- Added a Hinkin-Tracey target-versus-strongest-competitor gap plot and
  strengthened expert-panel plots for Aiken V/I-CVI, CVR critical
  values, and IOC target-versus-competitor margins.
- Added plotting for exact item-sort power and the critical observed-Psa
  boundary.
- Added canonical published/hand-worked reference tests, including
  Hinkin-Tracey Study 1 mean ratings, Polit-Beck-Owen modified kappa,
  and the Ayre-Scally N=10 CVR boundary.
- Closed the Anderson-Gerbing legacy-inference decision: Psa/Csv remain
  supported, but the obsolete critical-Csv decision rule is not exposed
  as an alternate workflow because Howard-Melloy is applicable to
  multi-choice sorts and agrees in the original two-choice case.

### Expert-panel workflow and repository hygiene

- Added
  [`expert_validity()`](https://juhalt.github.io/contentvalidR/reference/expert_validity.md)
  with relevance, essentiality, and congruence modes plus informative
  [`print()`](https://rdrr.io/r/base/print.html),
  [`summary()`](https://rdrr.io/r/base/summary.html), and
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods.
- Hardened Aiken’s V and made the Penfield-Giacobbi score confidence
  interval the default deterministic interval; bootstrap intervals
  remain available.
- Extended
  [`cvr()`](https://juhalt.github.io/contentvalidR/reference/cvr.md) to
  support item-specific panel sizes and judge-by-item 0/1 input, with
  exact one-sided binomial p-values and critical counts following Ayre
  and Scally’s revisiting of Lawshe’s method.
- Hardened
  [`ioc()`](https://juhalt.github.io/contentvalidR/reference/ioc.md)
  input validation, duplicate detection, and missing-data reporting.
- Added common panel-size CVI guidelines to the user-facing relevance
  workflow while explicitly treating them as review aids rather than
  universal validity cutoffs.
- Updated GitHub Actions from `actions/checkout@v4` to the current
  Node-24-compatible `actions/checkout@v7` line.
- Expanded public README guidance and added a dedicated expert-panel
  vignette.

## contentvalidR 0.0.3.9000

### Modern construct-rating workflow

- Added
  [`htc()`](https://juhalt.github.io/contentvalidR/reference/htc.md) and
  [`htd()`](https://juhalt.github.io/contentvalidR/reference/htd.md) for
  Hinkin-Tracey definitional correspondence and distinctiveness, with
  explicit rating-anchor validation.
- Rebuilt
  [`anova_content()`](https://juhalt.github.io/contentvalidR/reference/anova_content.md)
  around the fully crossed within-judge design used by the Hinkin-Tracey
  rating procedure. The function now uses a one-way repeated- measures
  ANOVA with Greenhouse-Geisser corrected omnibus inference plus planned
  target-versus-orbiting contrasts and retains a between-judge path only
  for genuinely independent designs. Raw omnibus p values remain
  available for transparency.
- Added
  [`rating_validity()`](https://juhalt.github.io/contentvalidR/reference/rating_validity.md)
  as the recommended user-facing construct-rating workflow, including
  strongest-competitor diagnostics, Retain/Review/ Insufficient-data
  screening, and narrative print/summary output.
- Extended Colquitt et al. (2019) scale-level interpretation to HTC and
  HTD, including focal-orbiting-correlation-conditional norms and
  expert-judge suppression.
- Added
  [`plot.contentvalid_rating()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_rating.md)
  for dependency-free HTC/HTD item plots.
- Added a dedicated Hinkin-Tracey-to-Colquitt vignette and expanded
  tests for rating indices, repeated-measures inference, incomplete
  profiles, and user-facing output.

## contentvalidR 0.0.2.9000

### Modern item-sort workflow

- Added Colquitt et al. (2019) empirical Psa/Csv interpretation bands,
  including overall and focal-orbiting-correlation-conditional norms.
- Colquitt labels are applied to target-scale averages, matching how the
  published norms were constructed, rather than being presented as
  validated item-level cutoffs.
- [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  now reports target-scale definitional correspondence and
  distinctiveness alongside Howard-Melloy item-level Retain/Review
  decisions.
- Added optional focal-orbiting correlations and explicit naive/expert
  judge handling; Colquitt norms are suppressed for expert panels.
- [`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md)
  now reports the strongest competing construct(s), making item
  confusion easier to diagnose.
- Added
  [`sort_power()`](https://juhalt.github.io/contentvalidR/reference/sort_power.md)
  for exact binomial design/power planning.
- Added
  [`plot.contentvalid_sort()`](https://juhalt.github.io/contentvalidR/reference/plot.contentvalid_sort.md)
  for dependency-free item-level Psa/Csv plots.
- Added a dedicated item-sort vignette and expanded regression tests.

## contentvalidR 0.0.1.9000

### Methodological foundation

- Fixed
  [`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md)
  when all non-target assignments fall in a single construct; unanimous
  assignment to the same wrong construct now correctly yields
  `Csv = -1`.
- [`compute_psa()`](https://juhalt.github.io/contentvalidR/reference/compute_psa.md)
  and
  [`compute_csv()`](https://juhalt.github.io/contentvalidR/reference/compute_csv.md)
  now use non-missing itemwise denominators, report `n_total`, `n`, and
  `n_missing`, and validate duplicate item-rater rows and inconsistent
  target mappings.
- Corrected Polit-Beck-Owen modified kappa in
  [`cvi()`](https://juhalt.github.io/contentvalidR/reference/cvi.md) to
  use the probability of exactly `A` agreements, and added S-CVI/UA plus
  item-specific effective judge counts.
- Corrected confusion-matrix orientation in
  [`signal_detection()`](https://juhalt.github.io/contentvalidR/reference/signal_detection.md)
  and changed phi calculations to preserve the direction of association.
- Reproducibility diagnostics now retain a full 2 x 2 table even when a
  decision level is absent.
- Clarified
  [`csv_binom_test()`](https://juhalt.github.io/contentvalidR/reference/csv_binom_test.md)
  as exact Howard-Melloy target-count inference and added the critical
  target-assignment count to its output.
- Added
  [`sort_validity()`](https://juhalt.github.io/contentvalidR/reference/sort_validity.md)
  as the first recommended user-facing workflow, with classed results,
  informative
  [`print()`](https://rdrr.io/r/base/print.html)/[`summary()`](https://rdrr.io/r/base/summary.html)
  methods, and restrained Retain/Review/Insufficient-data
  recommendations.
- Replaced the placeholder unit test with substantive regression and
  edge-case tests.
- Consolidated GitHub Actions into one cross-platform R CMD check
  workflow and removed an obsolete workflow that tested unsupported R
  versions.

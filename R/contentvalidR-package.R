#' @keywords internal
#'
#' @section Reading the output:
#' The printouts follow a style shared with nomologR, so the two packages
#' read alike. Every printout opens with a header naming the object's class
#' and what it holds, such as `<contentvalid_sort> Item-sort analysis`, then
#' its facts, then its verdict. `print()` shows the full evidence with a key
#' to its columns; `summary()` shows what needs attention, the flagged units
#' with a sentence each. A workflow's printout ends with what the evidence
#' does not decide, and every printout ends with a line pointing to what else
#' the object holds. Markdown output from [content_report()] is the one
#' exception: it prints only the lines to paste. Numbers follow APA 7: no
#' leading zero where a value cannot exceed 1, two decimals and three for
#' *p*, `--` for a value that could not be computed, and `> .999` for a *p*
#' that would round to 1.
#'
#' The statuses read across the two packages as follows:
#'
#' | contentvalidR | nomologR |
#' |---|---|
#' | Supported | no flag |
#' | Review | review |
#' | (no counterpart) | concern |
#' | Insufficient data | not computed |
#' | Descriptive only | note |
#'
#' "Review" always means look again, never delete. In the `results` and
#' the handoff of this package, `recommendation` is the decision word (such as
#' `"Retain"` or `"Strong support"`); `status` is the shared vocabulary
#' above.
#'
#' @section What you can rely on:
#' Code written against contentvalidR should keep working. This section says
#' exactly what "keep working" covers, so that a study analyzed today can be
#' reanalyzed later and a downstream package can read this one's output
#' without guessing.
#'
#' The public API is in three tiers.
#'
#' \strong{Tier 1, the recommended workflows.} [sort_validity()],
#' [rating_validity()], [expert_validity()], [delphi_validity()],
#' [judge_validity()], and [domain_validity()]; their `print()` and
#' `summary()` methods, and the `plot()` methods of the first four (when
#' similarity data were supplied, a domain fit's content map is drawn with
#' `plot(fit$details$structure)`); the object
#' contract they share (`results`,
#' `scale_summary`, `settings`, `design`, `details`); the shared status
#' vocabulary (`Supported`, `Review`, `Insufficient data`, `Descriptive
#' only`); and [content_handoff()], [content_evidence()], [content_report()],
#' [compare_rounds()], [as.data.frame.contentvalid_workflow()], and
#' [contentvalid_glossary()].
#'
#' Tier 1 will not change in a way that breaks working code except across a
#' major version, and never without the deprecation cycle below.
#'
#' \strong{Tier 2, the component indices and planning helpers.}
#' [aikens_v()], [cvi()], [cvr()], [ioc()], [htc()], [htd()], [compute_psa()],
#' [compute_csv()], [anova_content()], [panel_agreement()], [expert_power()],
#' [sort_power()], [colquitt_benchmarks()], [interpret_colquitt()],
#' [content_structure()], [gtheory_content()], [csv_binom_test()], and
#' [similarity_from_sort()].
#'
#' These are supported and tested to the same standard. They may gain
#' arguments, and their return values may gain fields. Anything that would
#' break working code goes through the deprecation cycle.
#'
#' \strong{Tier 3, auxiliary and compatibility helpers.}
#' [qfactor_content()], [reproducibility_phi()], [signal_detection()],
#' [simulate_anova_power()], and [simulate_csv_power()].
#'
#' These are kept for continuity with older analyses and for sensitivity
#' checks. They are not recommended workflows, and they may be deprecated and
#' removed with one minor release of warning.
#'
#' Anything else is internal: functions whose names begin with a dot, anything
#' reached with `:::`, and the exact wording of printed output. Internals can
#' change in any release.
#'
#' @section How something is deprecated:
#' Nothing exported disappears without warning first.
#'
#' 1. The function, argument, or returned field keeps working and says what to
#'    use instead. An argument warns when it is passed; a returned field cannot
#'    warn when it is read, so its documentation carries the notice instead.
#' 2. The notice stands for **at least one minor release**, so code has a
#'    version in which it both runs and tells you what to change.
#' 3. Removal follows: in a minor release before 1.0, and only in a major
#'    release from 1.0 onward.
#' 4. `NEWS.md` records both the deprecation and the removal, with the
#'    replacement.
#'
#' `anova_content()` supplies an example of each kind. Its `posthoc` argument
#' was deprecated in the first release, warned through every release to 0.6.0,
#' and was removed in 0.7.0. Its `posthoc_pass` returned column, a duplicate of
#' `contrast_pass`, could not warn when read, so it was documented as
#' deprecated in 0.7.0 and removed in 0.8.0. Both ends of each are recorded in
#' `NEWS.md`.
#'
#' `agreement_summary()`, a Tier 3 helper, was deprecated in 0.9.0 and is
#' removed in 1.0.0: it was the only function that took items in rows rather
#' than raters, and [panel_agreement()] does its job. Nothing deprecated is
#' carried past 1.0.
#'
#' Five returned fields were removed at 1.0.0 without that notice, because
#' the audit before 1.0 found them wrong or unreachable, and a release that
#' kept them would have kept wrong values in use: `overall_strength` in the
#' `scale_summary` of [sort_validity()] and [rating_validity()] (a
#' combination of the two Colquitt et al. levels that they do not publish),
#' `n_support` in that of [expert_validity()] (a count of a decision that
#' could not occur), `competitor_ioc` in its congruence `results` (a mean
#' labeled as the index), `n_influential` in the `scale_summary` of
#' [judge_validity()] (a flag that was withdrawn), and `fit_label` in the
#' `fit` table of [content_structure()] (Kruskal's labels, which belong to a
#' different statistic). With the congruence index corrected, its handoff
#' statistics `competitor IOC` and `IOC margin` gave way to `target IOC` and
#' the two mean ratings. `NEWS.md` gives the reason for each.
#'
#' @section Changing a default:
#' A changed default can silently change published numbers, so it is treated
#' as a breaking change even though no code fails. When a default changes, the
#' release notes say what changed, why the evidence supports it, and which
#' argument restores the previous behavior. Defaults are chosen from published
#' evidence; when that evidence is contested, the contested option is available
#' through an argument rather than made the default.
#'
#' @section The handoff schema:
#' [content_handoff()] returns an exchange object that another package reads,
#' so it carries its own contract, agreed with the `nomologR` maintainers and
#' recorded at \url{https://github.com/JUhalt/nomologR/issues/46}.
#'
#' * Fields may be **added** within a schema version. Existing fields keep
#'   their names, types, and meanings.
#' * Changing or removing a field, or changing what one means, requires a new
#'   `schema_version`.
#' * A reader checks that an optional field is present rather than assuming
#'   it, and infers nothing from its absence beyond "this producer version did
#'   not emit it".
#' * The values in the `statistic` column are data rather than schema, and the
#'   `note` column is display text. Both may be reworded in a minor release, so
#'   neither should be matched on.
#'
#' @section Versions of R:
#' The current R release and the one before it are supported and tested, along
#' with R-devel. Support for an older R is dropped only when it prevents a
#' correct implementation, and the release notes say so.
"_PACKAGE"

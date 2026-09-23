#' @keywords internal
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
#' [judge_validity()], and [domain_validity()]; their `print()`, `summary()`,
#' and `plot()` methods; the object contract they share (`results`,
#' `scale_summary`, `settings`, `design`, `details`); the shared status
#' vocabulary (`Supported`, `Review`, `Insufficient data`, `Descriptive
#' only`); and [content_handoff()], [content_report()], [compare_rounds()],
#' [as.data.frame.contentvalid_workflow()], and [contentvalid_glossary()].
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
#' [agreement_summary()], [qfactor_content()], [reproducibility_phi()],
#' [signal_detection()], [simulate_anova_power()], and
#' [simulate_csv_power()].
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
#' `anova_content()` supplies one example of each state. Its `posthoc` argument
#' is the completed cycle: deprecated in the first release, warning through
#' every release to 0.6.0, removed in 0.7.0, both ends recorded in `NEWS.md`.
#' Its `posthoc_pass` returned column is the cycle in progress: a duplicate of
#' `contrast_pass`, still returned, and documented as going away.
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

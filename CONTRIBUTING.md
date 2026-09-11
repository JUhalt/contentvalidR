# Contributing to contentvalidR

Contributions, bug reports, methodological questions, and feature
proposals are welcome.

## Project philosophy

`contentvalidR` is designed to make substantive and content-validity
evidence easier to compute, interpret, report, and defend without
replacing researcher judgment.

Contributions should preserve the package’s central principles:

- distinguish quantitative evidence from automatic item-retention or
  deletion decisions;
- disclose missingness, effective judge counts, assumptions, and
  unsupported cases;
- preserve access to underlying item- and judge-level evidence where
  practical;
- distinguish content/domain evidence from downstream empirical
  dimensionality;
- avoid universal cutoffs or sample-size rules where the literature does
  not support them;
- make consequential researcher decisions explicit and reproducible.

## Development workflow

1.  Open or identify an issue describing the proposed change.
2.  Create a feature branch from the current default branch.
3.  Add or update tests alongside substantive code.
4.  Update documentation and examples when user-facing behavior changes.
5.  Run `devtools::document()`, `devtools::test()`, and
    `devtools::check()` before opening a pull request.
6.  For substantive computational changes, include known-answer,
    simulation/recovery, or direct-method regression tests where
    appropriate.
7.  Open a pull request and allow all GitHub Actions checks to complete.

## Statistical-method contributions

A proposed statistical feature should identify:

- the content-validity or scale-pretesting question it supports;
- the estimand or statistical quantity being reported;
- assumptions and known limitations;
- how uncertainty is represented;
- how missingness and unsupported cases are disclosed;
- why the feature belongs in `contentvalidR`;
- relevant methodological references or an explicit derivation if the
  method is novel.

## Testing expectations

Tests should prioritize correctness and consequential behavior rather
than coverage percentages for their own sake.

Useful tests include known-answer comparisons, simulation/recovery
studies, boundary cases, malformed inputs, missing-data behavior, and
regression tests for interpretation and researcher-control behavior.

## Pull requests

Pull requests should describe what changed, why it changed, how it was
tested, and any methodological or API decisions that deserve review.

The current development specification is maintained in `ROADMAP.md`.

## Planning and published pages

Link proposed work to an issue and the relevant
[roadmap](https://github.com/JUhalt/contentvalidR/blob/master/ROADMAP.md)
section. Give research proposals a checked primary source or an explicit
derivation, state what is established versus proposed, and describe
observable acceptance criteria. Assign a milestone when scope is
accepted; update the roadmap and NEWS when work ships or is deferred.

Edit `README.Rmd` before regenerating `README.md`. The root roadmap,
NEWS, DESCRIPTION, and citation metadata are authoritative for the
current source. Refresh tracked `docs/` output with pkgdown; the
existing workflow also rebuilds and publishes the site. Review
license/version links and the visible homepage status after publication.
Historical release tags retain their original metadata.

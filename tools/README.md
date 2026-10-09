# Release tooling

Build-ignored: nothing here ships in the tarball.

## The release gate

Run from the package root, before tagging any release:

```
Rscript tools/release-gate.R
```

It takes the version from `DESCRIPTION`, so there is nothing to edit per
release. Individual stages can be run alone while iterating:

```
Rscript tools/release-gate.R build
Rscript tools/release-gate.R smoke check
```

A stage name the gate does not know stops it. A run of fewer than three
stages says which did not run; only a run of all three is the gate.

| Stage | What it does | Fails when |
|---|---|---|
| `build` | `document()`, `build_readme()`, spelling, URLs, builds the tarball and inspects it | a misspelling, an unreachable URL, a hidden or build-ignored file in the tarball, or a version mismatch between the tarball and the source |
| `smoke` | installs the tarball into a library that holds nothing else but the packages it declares it needs, and uses it there | a declared package is not installed on the machine, the install is skipped, any help topic's examples fail, a published value fails to reproduce, the handoff's columns drift, or a vignette is missing |
| `check` | `R CMD check --as-cran` with CRAN's incoming checks | any error, any warning, or any note other than the two expected ones |

## Why each stage runs in its own process

`build` calls `devtools::document()`, which loads contentvalidR into that
session. On Windows a session holding the package cannot install over it:
`install.packages()` warns "package is in use", carries on, and the smoke test
then fails against a package that was never installed.

That happened silently at three consecutive releases (0.4.0, 0.5.0, 0.6.0),
and each time the install and smoke steps were rerun by hand in a separate
process. The gate now runs every stage as its own `Rscript --vanilla`, and the
smoke stage refuses to start if contentvalidR is already loaded, rather than
warning and continuing. See
[#51](https://github.com/JUhalt/contentvalidR/issues/51).

## A busy machine

`devtools` asks pak for the package's dependencies, and pak gives its helper
process five seconds to start. On a busy machine that was not enough, and the
build stage stopped with "Subprocess is busy or cannot start". The gate sets
`PKG_SUBPROCESS_TIMEOUT` to two minutes for its stages, unless the variable is
already set.

## A stage only ever tests this source

`smoke` and `check` test the tarball `build` leaves behind, and every branch's
tarball has the same name. So the gate makes sure the tarball in front of a
stage was built from the tree in front of it:

- `build` deletes the previous tarball before anything else, so a build that
  stops at spelling or URLs leaves nothing for a later stage to pick up;
- `build` writes a `.source` stamp beside the tarball: the commit plus a hash
  of every uncommitted change;
- `smoke` and `check` compare that stamp with the tree they are run from, and
  fail if a branch switch, a commit, or an edit has come between;
- the gate stops at the first failed stage and reports the rest as `SKIP`
  rather than running them.

Before this, a build that failed its spelling check left the previous
branch's tarball in place, and `smoke` and `check` passed it: `build FAIL`,
`smoke PASS`, `check PASS`, where the two passes described a different branch.
The gate as a whole still failed, but the per-stage lines were false, and they
were believed.

## What the smoke test checks, and why there

`tools/gate-smoke-run.R` runs against the **installed** package, with only the
packages that ship with R, the new install, and the packages the install
declares it needs on the library path, so it tests what a user would get
rather than the source tree. The declared packages (Depends, Imports and
LinkingTo, and theirs in turn) are copied from the machine's library, and
nothing else is, so a package from outside R's own library that is used
without being declared is still missing and fails the stage. It checks that:

- every help topic's examples run;
- published values recompute: Chaffin and Talley's (1980) Table 3a across the
  chi-square methods, lambda and net change, and Cohen's (1968) Table 1
  weighted kappa;
- `content_handoff()` carries the agreed `item_statistics` columns, in order,
  at schema version 1, with `note` a character vector holding no `NA`. Another
  package reads this contract, so drift in it is a release blocker;
- the expected vignettes are installed;
- the citation names the version being released.

The two notes `check` tolerates are CRAN's incoming-feasibility note and math
rendering skipped where V8 is unavailable. The incoming note is tolerated only
when every line of it is expected: the maintainer, "New submission" (before
the package was on CRAN), "Version contains large components" (a development
version), or "Days since last update" (since 0.4.0 reached CRAN on
2026-09-28). Any other line in it fails the stage, and so does any other note:
a gate that prints findings for a human to eyeball is not a gate. When the
last update was under 60 days ago, the stage also prints a reminder that CRAN
asks for updates no more often than every one to two months. The date of the
last CRAN release is kept in `tools/cran-release-date`, one line in
YYYY-MM-DD form; set it on the day CRAN accepts a version.

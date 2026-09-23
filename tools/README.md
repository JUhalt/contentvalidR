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

| Stage | What it does | Fails when |
|---|---|---|
| `build` | `document()`, `build_readme()`, spelling, URLs, builds the tarball and inspects it | a misspelling, an unreachable URL, a hidden or build-ignored file in the tarball, or a version mismatch between the tarball and the source |
| `smoke` | installs the tarball into an empty library and uses it there | the install is skipped, any help topic's examples fail, a published value fails to reproduce, the handoff's columns drift, or a vignette is missing |
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

`tools/gate-smoke-run.R` runs against the **installed** package, with only base
R and the new install on the library path, so it tests what a user would get
rather than the source tree:

- every help topic's examples run;
- published values recompute: Chaffin and Talley's (1980) Table 3a across the
  chi-square methods, lambda and net change, and Cohen's (1968) Table 1
  weighted kappa;
- `content_handoff()` carries the agreed `item_statistics` columns, in order,
  at schema version 1, with `note` a character vector holding no `NA`. Another
  package reads this contract, so drift in it is a release blocker;
- the expected vignettes are installed;
- the citation names the version being released.

The two notes `check` tolerates are "New submission", which stands until the
package is on CRAN, and math rendering skipped where V8 is unavailable. Any
other note fails the stage: a gate that prints findings for a human to eyeball
is not a gate.

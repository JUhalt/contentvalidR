# A stamp of the source tree a tarball was built from.
#
# Every stage after build tests the tarball build left behind, and every
# branch's tarball has the same name. Without a stamp, a later stage cannot tell
# a fresh tarball from a stale one. That happened: a build that failed at its
# spelling check never replaced the previous branch's tarball, and smoke and
# check then passed that one -- reporting PASS for a tree they never tested.
#
# The stamp is the commit plus a hash of every uncommitted change, so switching
# branches, committing, or editing a tracked file between stages all change it.
# It uses base R and git only, so the smoke stage can source it without loading
# the package it is about to install.

gate_git <- function(root, ...) {
  out <- tryCatch(
    suppressWarnings(system2("git", c("-C", shQuote(root), ...),
                             stdout = TRUE, stderr = FALSE)),
    error = function(e) NULL
  )
  status <- attr(out, "status")
  if (is.null(out) || (!is.null(status) && status != 0)) NULL else out
}

gate_source_stamp <- function(root) {
  head <- gate_git(root, "rev-parse", "HEAD")
  if (is.null(head) || !length(head)) return(NA_character_)
  changes <- c(gate_git(root, "diff", "HEAD", "--binary"), "-- untracked --",
               gate_git(root, "ls-files", "--others", "--exclude-standard"))
  tmp <- tempfile()
  on.exit(unlink(tmp))
  writeLines(changes, tmp)
  paste(head, unname(tools::md5sum(tmp)))
}

gate_stamp_path <- function(tarball) paste0(tarball, ".source")

# Called by the stages that consume the tarball. Returns TRUE when it matches
# the tree here; otherwise explains and returns FALSE. Without git it cannot
# tell, and says so rather than guessing.
gate_tarball_matches_source <- function(tarball, root) {
  stamp <- gate_stamp_path(tarball)
  built_from <- if (file.exists(stamp)) readLines(stamp, warn = FALSE) else ""
  here <- gate_source_stamp(root)
  if (is.na(here)) {
    cat("note: git is unavailable, so this stage cannot confirm the tarball ",
        "was built from the source here.\n", sep = "")
    return(TRUE)
  }
  if (!identical(built_from, here)) {
    cat("FAIL: the tarball was not built from the source tree here. The branch,\n",
        "      a commit, or an uncommitted file has changed since the build stage\n",
        "      ran, or it never finished. Run the build stage again first.\n",
        sep = "")
    return(FALSE)
  }
  TRUE
}

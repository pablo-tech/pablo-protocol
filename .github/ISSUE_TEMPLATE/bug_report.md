---
name: Bug report
about: A guard, the installer or an adapter did something other than what ARCHITECTURE.md says
labels: bug
---

**What you ran, and where.** The command, and whether it was in a tenant repository or in this
one.

**What happened.** Paste the output. A guard that refuses explains itself and names the term or
path it matched — that line is usually the whole report.

**What ARCHITECTURE.md says should have happened.** Cite the section (`§4`, `§7`) if you can. If
the two disagree, one of them is the bug and it is useful to know which you think it is.

**Reproducing it.** Ideally: a scratch tenant, the `.protocol/` file involved, and the staged
content. `git init` plus three lines is usually enough.

**Machine.** `bash --version`, `git --version`, OS, and whether symlinks work (`bin/adapt --copy`
exists for machines where they do not).

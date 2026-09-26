# Changelog

## [Unreleased]

## [23.7-1] - 2026-09-26

Initial release — psmisc 23.7 as a single self-contained binary, built natively
for Linux.

### Added

- `killall`, `pstree`, `fuser`, `prtstat` and `pslog`, plus the `pstree.x11`
  alias. `unpin install psmisc` creates all of them.
- Builds for Linux (x86_64, aarch64, armv7l, i686, ppc64le, riscv64).
- The programs' man pages embedded in the binary — read one with
  `unpin man psmisc pstree`.
- Messages come out in your language where the system has the translations
  installed. The lookup uses `/usr/share/locale`, so nothing in the binary
  points at the machine that built it.

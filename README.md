# psmisc

[psmisc](https://gitlab.com/psmisc/psmisc) — small utilities that use the `/proc` filesystem: `killall`, `pstree`, `fuser`, `prtstat` and `pslog`. A single self-contained binary.

[![CI](https://github.com/unpins/psmisc/actions/workflows/psmisc.yml/badge.svg)](https://github.com/unpins/psmisc/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install psmisc`.

Linux-only: psmisc reads the Linux `/proc` filesystem, which macOS and Windows do not have.

## Usage

Run a program with [unpin](https://github.com/unpins/unpin):

```bash
unpin psmisc pstree              # tree of running processes
unpin psmisc killall firefox     # kill processes by name
unpin psmisc fuser -v /home      # who is using a file/mount
```

To install the programs onto your PATH:

```bash
unpin install psmisc
```

`unpin install psmisc` creates `killall`, `pstree`, `fuser`, `prtstat` and `pslog` (plus the `pstree.x11` alias). `unpin info psmisc` lists every command.

## Build locally

```bash
nix build github:unpins/psmisc
./result/bin/psmisc --unpin-program=pstree
```

Or run directly:

```bash
nix run github:unpins/psmisc -- --unpin-program=pstree --version
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/psmisc/releases) page has standalone binaries for manual download.

## Build notes

- **Platform:** Linux only (`/proc`).
- **Multicall:** the five programs are folded into one ELF via a source-level `main` → `<prog>_main` rename (`lib.cppRenameMulticall`), keeping a single copy of the shared `signals.o`/`statx.o`.
- **Terminal width:** `pstree` links an embedded-fallback terminfo ncurses so it probes the terminal width without a host `/usr/share/terminfo`, keeping the binary free of `/nix/store` references.
- **Man pages:** the section-1 pages are embedded; read with `unpin man psmisc pstree`.

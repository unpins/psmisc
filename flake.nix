{
  description = "psmisc (killall + pstree + fuser + prtstat + pslog) as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # psmisc builds five proc-table tools (killall, pstree, fuser, prtstat, pslog;
  # peekfd is arch-gated off on x86_64) plus the pstree.x11 compat symlink. They
  # share signals.o (killall+fuser) and statx.o (fuser) — plain helpers, no
  # callbacks — so we fold them with the cpp-rename recipe (lib.cppRenameMulticall), keeping a
  # single copy of each shared object. pstree links TERMCAP_LIB for terminal-width probing;
  # static ncurses would embed an absolute terminfo store path, so we swap in the
  # embedded-fallback ncurses (same trick as bc/dash) to keep the binary 0-ref.
  # The real ELF is bin/psmisc; every program name is an argv[0] alias.
  outputs = { self, unpins-lib }:
    let lib = unpins-lib.lib;
    in
    lib.mkStandaloneFlake {
      inherit self;
      name = "psmisc";
      binName = "psmisc";
      linuxOnly = true; # reads /proc — nixpkgs meta.platforms is linux-only
      smoke = [ "--unpin-program=pstree" "--version" ];
      smokePattern = "psmisc";
      build = pkgs:
        let
          psmiscFB = pkgs.pkgsStatic.psmisc.override {
            ncurses = lib.embedFallbackTerminfoOnly pkgs.pkgsStatic.ncurses;
          };
        in
        lib.cppRenameMulticall {
          inherit pkgs;
          basePkg = psmiscFB;
          primary = "psmisc";
          makeSubdir = ".";
          linkExtra = "$(LIBINTL) $(TERMCAP_LIB) $(DL_LIB)";
          programs = [
            { name = "killall"; objs = [ "src/killall.o" "src/signals.o" ]; }
            { name = "fuser"; objs = [ "src/fuser.o" "src/signals.o" "src/statx.o" ]; }
            { name = "pstree"; objs = [ "src/pstree.o" ]; }
            { name = "prtstat"; objs = [ "src/prtstat.o" ]; }
            { name = "pslog"; objs = [ "src/pslog.o" ]; }
          ];
          aliases = [
            { name = "pstree.x11"; target = "pstree"; }
          ];
          extraInstall = ''
            mkdir -p "$out/share/man/man1"
            for m in killall fuser pstree prtstat pslog; do
              if [ -f "doc/$m.1" ]; then install -m644 "doc/$m.1" "$out/share/man/man1/$m.1"; fi
            done
          '';
        };
    };
}

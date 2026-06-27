{
  description = "psmisc (killall + pstree + fuser + prtstat + pslog) as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # psmisc builds five proc-table tools (killall, pstree, fuser, prtstat, pslog;
  # peekfd is arch-gated off on x86_64) plus the pstree.x11 compat symlink. They
  # fold via the unpin-llvm engine's bitcode multicall module (declared in
  # `multicall = { programs }` below), so the build is the plain pkgsStatic.psmisc.
  # pstree links TERMCAP_LIB for terminal-width probing; static ncurses would
  # embed an absolute terminfo store path, so we swap in the embedded-fallback
  # ncurses (same trick as htop/dash) to keep the binary 0-ref — DB-on so it
  # shares one ncurses .a with the rest of the mega (dedup).
  outputs = { self, unpins-lib }:
    let lib = unpins-lib.lib;
    in
    lib.mkStandaloneFlake {
      inherit self;
      name = "psmisc";

      # Build via the unpin-llvm engine + emit a bitcode multicall module.
      engine = "unpin-llvm";
      multicall = {
        programs = [{ name = "fuser"; } { name = "killall"; } { name = "prtstat"; } { name = "pslog"; } { name = "pstree"; aliases = [ "pstree.x11" ]; }];
      };
      binName = "psmisc";
      linuxOnly = true; # reads /proc — nixpkgs meta.platforms is linux-only
      smoke = [ "--unpin-program=pstree" "--version" ];
      smokePattern = "PSmisc";
      # Fallback terminfo is baked centrally for every engine-Linux ncurses
      # (native-overlay/ncurses.nix), so pkgsStatic.ncurses already carries it.
      build = pkgs: pkgs.pkgsStatic.psmisc;
    };
}

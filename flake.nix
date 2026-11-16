{
  description = "psmisc (killall + pstree + fuser + prtstat + pslog + peekfd) as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # psmisc's programs (fuser, killall, peekfd, prtstat, pslog, pstree and the
  # pstree.x11 alias) fold into one binary through the engine's multicall
  # module; the build is pkgsStatic.psmisc plus the overrides below.
  outputs = { self, unpins-lib }:
    let
      lib = unpins-lib.lib;
      # Hosts where configure builds peekfd (it needs a ptrace register map):
      # none for riscv, s390x or loongarch, and mips only on a mipsel BUILD cpu.
      withPeekfd = p: p.isx86 || p.isAarch64 || p.isAarch32 || p.isPower || p.isM68k;
    in
    lib.mkStandaloneFlake {
      inherit self;
      name = "psmisc";

      # Build via the unpin-llvm engine + emit a bitcode multicall module.
      engine = "unpin-llvm";
      multicall = {
        programs = [{ name = "fuser"; } { name = "killall"; } { name = "peekfd"; supportedTarget = withPeekfd; } { name = "prtstat"; } { name = "pslog"; } { name = "pstree"; aliases = [ { name = "pstree.x11"; noMan = true; } ]; }];
      };
      binName = "psmisc";
      linuxOnly = true; # reads /proc — nixpkgs meta.platforms is linux-only
      smoke = [ "--unpin-program=pstree" "--version" ];
      smokePattern = "PSmisc";
      # pstree probes the terminal width through ncurses, whose fallback
      # terminfo nix-lib bakes in (native-overlay/ncurses.nix).
      # peekfd.1 is installed on every host, peekfd only where configure builds
      # it: drop the page elsewhere so no man page names a missing program.
      # gettext compiles the build's own prefix in as LOCALEDIR, so the
      # translations these tools look up live at a `/nix/store/...` path that
      # exists on no user's machine. Point the lookup at the conventional
      # location instead (upstream's own default under prefix=/usr), and keep
      # installing the `.mo` files under $out. Nix never saw the string: the
      # engine fold's inputs are the module archives, not psmisc's `out`, so
      # `nix-store -q --references` reports nothing and only a grep of the
      # binary finds it.
      build = pkgs: pkgs.pkgsStatic.psmisc.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./patches/peekfd-musl-x86.patch ./patches/killall-signal-words.patch ];
        configureFlags = (old.configureFlags or [ ]) ++ [ "--localedir=/usr/share/locale" ];
        installFlags = (old.installFlags or [ ]) ++ [ "localedir=${placeholder "out"}/share/locale" ];
        # Upstream's dejagnu suite (killall, pslog, fuser).
        doCheck = pkgs.stdenv.buildPlatform.canExecute pkgs.pkgsStatic.stdenv.hostPlatform;
        nativeCheckInputs = [ pkgs.buildPackages.dejagnu ];
        postInstall = (if (old.postInstall or null) == null then "" else old.postInstall)
          + pkgs.lib.optionalString (!withPeekfd pkgs.pkgsStatic.stdenv.hostPlatform) ''
          for _mo in $outputs; do
            rm -f "''${!_mo}"/share/man/man1/peekfd.1*
          done
        '';
      });
    };
}

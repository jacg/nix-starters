# =============================================================================
# This flake provides a Python development environment tooling.
# Legacy nix-shell support is available through the wrapper in `shell.nix`.
# =============================================================================

# TODO Hacking around the Qt problems
# TODO PyPI package not in nixpkgs

{
  description = "Python development environment";

  inputs = {
    # Version pinning is managed in flake.lock.
    # Upgrading can be done with `nix flake update <input-name>`
    #
    #    nix flake update nixpkgs
    nixpkgs     .url = "github:nixos/nixpkgs/nixos-26.05"; # nix flake update nixpkgs
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };

  };

  outputs = { nixpkgs, ... }:
    let
      # Systems for which outputs are provided (NB some packages in nixpkgs
      # are not supported on some systems). Remove any that you don't need.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f (perSystem system));

      perSystem = system:
        let pkgs = import nixpkgs {
              inherit system;
              # Any overlays you need can go here
              overlays = [];
            };

            # ----- A Python interpreter with the packages that interest us -------
            python-with-all-my-packages = (python:
              (python.withPackages (ps: [
                ps.pytest
                ps.numpy
                ps.python-lsp-server
            ])));

            # ----- Escape hatch: see `just rescue` and README.md ------------------
            # Binary wheels from PyPI ship `.so` files which look for their
            # dependencies in FHS locations that do not exist on NixOS. The
            # *interpreter* is fine -- it comes from nixpkgs -- so only these
            # need to be findable. Add to this list if a wheel complains that
            # some `libFoo.so.N` is missing.
            wheel-libs = with pkgs; [
              stdenv.cc.cc.lib   # libstdc++.so.6, libgcc_s.so.1
              zlib               # libz.so.1
              glib               # libgthread, libglib
              libGL              # libGL.so.1       (matplotlib, opencv, ...)
              zstd               # libzstd.so.1
            ];

            # ----- One shell for each Python version -------------------------
            shells =
              builtins.listToAttrs (
                builtins.map (
                  pythonVersion: {
                    name = pythonVersion;
                    value = pkgs.mkShell {
                      packages = [
                        (python-with-all-my-packages pkgs.${ pythonVersion })
                        pkgs.just
                        pkgs.cowsay
                        pkgs.uv         # escape hatch rung 2: anything on PyPI
                        pkgs.micromamba # escape hatch rung 3: needs nix-ld, see README
                      ];
                      # The prompt and aliases take effect only under `nix develop`:
                      # direnv takes environment variables from shellHook, but not
                      # aliases, and not PS1.
                      shellHook = ''
                        export PS1="${pythonVersion} devshell> "

                        # You could define aliases here
                        alias testme='just test'

                        # ----- Escape hatch: see `just rescue` --------------------
                        # uv must use the interpreter above and NEVER download its
                        # own: a downloaded CPython is a foreign binary, and will
                        # not run on NixOS unless nix-ld is enabled.
                        export UV_PYTHON_DOWNLOADS=never
                        export UV_PYTHON_PREFERENCE=only-system

                        export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath wheel-libs}''${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH
                         '';
                    };
                  }
                ) [ "python312" "python313" "python314" ]
              );

        in
          {
            devShells = shells // { default = shells.python314; };
          };
    in
      {
        devShells = forEachSystem (s: s.devShells);
      };
}

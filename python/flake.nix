# =============================================================================
# This flake provides a Rust development environment tooling.
# Legacy nix-shell support is available through the wrapper in `shell.nix`.
# =============================================================================

# TODO Hacking around the Qt problems
# TODO PyPI package not in nixpkgs

{
  description = "Python development environment";

  inputs = {
    # Version pinning is managed in flake.lock.
    # Upgrading can be done with `nix flake lock --update input <input-name>`
    #
    #    nix flake lock --update-input nixpkgs
    nixpkgs     .url = "github:nixos/nixpkgs/nixos-25.05"; # nix flake lock --update input nixpkgs
    flake-utils .url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

  };

  outputs = { self, nixpkgs, flake-utils, ... }:

    # Option 1: try to support each default system
    flake-utils.lib.eachDefaultSystem # NB Some packages in nixpkgs are not supported on some systems

    # Option 2: try to support selected systems
    # flake-utils.lib.eachSystem ["x86_64-linux" "i686-linux" "aarch64-linux" "x86_64-darwin"]
      (system:

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

        in
          rec {

            #devShell = self.devShells.${ system }.python313; # does not need `rec`
            devShell = devShells.python313;

            devShells =
              builtins.listToAttrs (
                builtins.map (
                  pythonVersion: {
                    name = pythonVersion;
                    value = pkgs.mkShell {
                      packages = [
                        (python-with-all-my-packages pkgs.${ pythonVersion })
                        pkgs.just
                        pkgs.cowsay
                      ];
                      shellHook = ''
                        export PS1="${pythonVersion} devshell> "

                        # You could define aliases here
                        alias testme='just test'
                         '';
                    };
                  }
                ) [ "python311" "python312" "python313" ]
              );
          }
      );
}

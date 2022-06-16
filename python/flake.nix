# The core functionality is provided here using flakes. Legacy support for
# `nix-shell` is provided by a wrapper in `shell.nix`.

# TODO Hacking around the Qt problems
# TODO PyPI package not in nixpkgs


{
  description = "Python development environment";

  inputs = {

    # Version pinning is managed in flake.lock. Upgrading can be done with
    # something like
    #
    #    nix flake lock --update-input nixpkgs

    nixpkgs     .url = "github:nixos/nixpkgs/nixos-22.05";
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
              overlays = [

                # Try to add `fubar` package to python.withPackages
                (final: prev:
                  {
                    pythonPackagesOverlays = (prev.pythonPackagesOverlays or [ ]) ++ [
                      (python-final: python-prev: {
                        fubar = python-prev.setuptools;
                      })
                    ];

                    python3 =
                      let
                        self = prev.python3.override {
                          inherit self;
                          packageOverrides = prev.lib.composeManyExtensions final.pythonPackagesOverlays;
                        }; in
                        self;

                    python3Packages = final.python3.pkgs;

                  })

              ];
            };

            # ----- A Python interpreter with the packages that interest us -------
            python-with-all-my-packages = (python:
              (python.withPackages (ps: [
                ps.pytest
                ps.numpy
                ps.fubar
            ])));

        in
          rec {

            #devShell = self.devShells.${ system }.python310; # does not need `rec`
            devShell = devShells.python310;

            devShells =
              builtins.listToAttrs (
                builtins.map (
                  pythonVersion: {
                    name = pythonVersion;
                    value = pkgs.mkShell {
                      buildInputs = [
                        (python-with-all-my-packages pkgs.python3)
                        pkgs.just
                        pkgs.cowsay
                      ];
                      packages = [
                        pkgs.lolcat
                        pkgs.exa
                      ];
                      shellHook =
                        ''
          export PS1="${pythonVersion} devshell> "
          alias foo='cowsay Foo'
          alias bar='exa -l | lolcat'
          alias baz='cowsay What is the difference between buildIntputs and packages? | lolcat'
                         '';
                    };
                  }
                ) [ "python37" "python38" "python39" "python310" ]
              );
          }
      );
}

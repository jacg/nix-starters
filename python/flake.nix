# The core functionality is provided here using flakes. Legacy support for
# `nix-shell` is provided by a wrapper in `shell.nix`.

# TODO Hacking around the Qt problems
# TODO PyPI package not in nixpkgs


{
  description = "Python development environment";

  inputs = {

    nixpkgs     .url = "github:nixos/nixpkgs/nixos-21.11";
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
            python = pkgs.python39;

            # ----- A Python interpreter with the packages that interest us -------
            python-with-all-my-packages = (python.withPackages (ps: [
              ps.pytest
              ps.numpy
            ]));
        in
          {
            devShell = pkgs.mkShell {
              name = "my-python-project";
              buildInputs = [
                python-with-all-my-packages
              ];
            };
          }
      );
}

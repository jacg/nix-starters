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
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
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

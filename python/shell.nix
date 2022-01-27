# TODO Hacking around the Qt problems
# TODO PyPI package not in nixpkgs

# To get a more recent version of nixpkgs, go to https://status.nixos.org/,
# which lists the latest commit that passes all the tests for any release.
# Unless there is an overriding reason, pick the latest stable NixOS release, at
# the time of writing this is nixos-21.05.

{
  py ? "39" # To override the default python version:  nix-shell shell.nix --argstr py 37
}:

let
  # ----- Pinned nixpkgs ----------------------------------------------------------------------------

  nixpkgs-commit-id = "604c44137d97b5111be1ca5c0d97f6e24fbc5c2c"; # nixos-21.11 on 2022-01-24
  nixpkgs-url = "https://github.com/nixos/nixpkgs/archive/${nixpkgs-commit-id}.tar.gz";
  pkgs = import (fetchTarball nixpkgs-url) {
      overlays = map (uri: import (fetchTarball uri)) [];
  };

  # ----- Python version ----------------------------------------------------------------------------
  python = builtins.getAttr ("python" + py) pkgs;

  # ----- A Python interpreter with the packages that interest us -----------------------------------
  python-with-all-my-packages = (python.withPackages (ps: [
      ps.pytest
      ps.numpy
    ]));

  # ----- Choice of included packages ---------------------------------------------------------------
  buildInputs = [
    python-with-all-my-packages
  ];

in

pkgs.mkShell {
  name = "my-python-project";
  buildInputs = buildInputs;
}

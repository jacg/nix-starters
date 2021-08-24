# TODO Hacking around the Qt problems
# TODO PyPI package not in nixpkgs

# To get a more recent version of nixpkgs, go to https://status.nixos.org/,
# which lists the latest commit that passes all the tests for any release.
# Unless there is an overriding reason, pick the latest stable NixOS release, at
# the time of writing this is nixos-21.05.

{
  py ? "38" # To override the default python version:  nix-shell shell.nix --argstr py 37
}:

let
  # ----- Pinned nixpkgs ----------------------------------------------------------------------------

  nixpkgs-commit-id = "871e8c4d585ff2a9eb200dcbd96e3856775807b9"; # nixos-21.05 on 2021-08-24
  nixpkgs-url = "https://github.com/nixos/nixpkgs/archive/${nixpkgs-commit-id}.tar.gz";
  pkgs = import (fetchTarball nixpkgs-url) {
      overlays = map (uri: import (fetchTarball uri)) [];
  };

  # ----- Python version ----------------------------------------------------------------------------
  python = builtins.getAttr ("python" + py) pkgs;
  pypkgs = python.pkgs;

  # ----- Choice of included packages ---------------------------------------------------------------

  buildInputs = [
    pypkgs.pytest
    pypkgs.numpy
  ];

in

pkgs.mkShell {
  name = "my-python-project";
  buildInputs = buildInputs;
}

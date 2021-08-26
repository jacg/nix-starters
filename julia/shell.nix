# To get a more recent version of nixpkgs, go to https://status.nixos.org/,
# which lists the latest commit that passes all the tests for any release.
# Unless there is an overriding reason, pick the latest stable NixOS release, at
# the time of writing this is nixos-21.05.

{
}:
let
  # ----- Pinned nixpkgs  ---------------------------------------------------------------------------

  nixpkgs-commit-id = "871e8c4d585ff2a9eb200dcbd96e3856775807b9"; # nixos-21.05 on 2021-08-24
  nixpkgs-url = "https://github.com/nixos/nixpkgs/archive/${nixpkgs-commit-id}.tar.gz";
  pkgs = import (fetchTarball nixpkgs-url) {
    overlays = map (uri: import (fetchTarball uri)) [];
  };

in

pkgs.mkShell {
  pname = "julia-devel";
  buildInputs = [
    pkgs.julia_16-bin
  ];
}

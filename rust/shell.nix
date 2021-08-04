# To get a more recent version of nixpkgs, go to https://status.nixos.org/,
# which lists the latest commit that passes all the tests for any release.
# Unless there is an overriding reason, pick the latest stable NixOS release, at
# the time of writing this is nixos-21.05.

{
}:

let
  nixpkgs-commit-id = "d4590d21006387dcb190c516724cb1e41c0f8fdf"; # nixos-21.05 on 2021-08-03
  nixpkgs-url = "https://github.com/nixos/nixpkgs/archive/${nixpkgs-commit-id}.tar.gz";
  oxalica-commit-id = "53b758596e8bd17e9fc764e14ba3e7686030bad3";
  pkgs = import (fetchTarball nixpkgs-url) {
      overlays = map (uri: import (fetchTarball uri)) [
        "https://github.com/oxalica/rust-overlay/archive/${oxalica-commit-id}.tar.gz"
      ];
    };
in

pkgs.mkShell {
  name = "my-rust-project";
  buildInputs = [ pkgs.cowsay ];
}

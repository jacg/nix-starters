# To get a more recent version of nixpkgs, go to https://status.nixos.org/,
# which lists the latest commit that passes all the tests for any release.
# Unless there is an overriding reason, pick the latest stable NixOS release, at
# the time of writing this is nixos-21.05.

let
  # ----- Pinned nixpkgs-----------------------------------------------------------------------------

  nixpkgs-commit-id = "d4590d21006387dcb190c516724cb1e41c0f8fdf"; # nixos-21.05 on 2021-08-03
  nixpkgs-url = "https://github.com/nixos/nixpkgs/archive/${nixpkgs-commit-id}.tar.gz";
  nixpkgs-src = fetchTarball nixpkgs-url;
  pkgs = import nixpkgs-src {
      overlays = map (uri: import (fetchTarball uri)) [];
  };

  # ----- Pinned home-manager -----------------------------------------------------------------------

  hm-commit-id = "b39647e52ed3c0b989e9d5c965e598ae4c38d7ef"; # release-21.05 of 2021-07-30
  hm-url = "https://github.com/nix-community/home-manager/archive/${hm-commit-id}.tar.gz";
  hm-src = fetchTarball hm-url;
  home-manager = (import hm-src {}).home-manager;

  # home-manager = let
  #   src = builtins.fetchGit {
  #     url = https://github.com/nix-community/home-manager;
  #     rev = "b39647e52ed3c0b989e9d5c965e598ae4c38d7ef"; # release-21.05 of 2021-07-30
  #   };
  # # `path` is required for `home-manager` to find its own sources
  # in pkgs.callPackage "${src}/home-manager" { path = "${src}"; };

in

{
  pkgs         = pkgs;
  home-manager = home-manager;
}

# To get a more recent version of nixpkgs, go to https://status.nixos.org/,
# which lists the latest commit that passes all the tests for any release.
# Unless there is an overriding reason, pick the latest stable NixOS release, at
# the time of writing this is nixos-21.05.

let
  # ----- Pinned nixpkgs-----------------------------------------------------------------------------

  nixpkgs-commit-id = "a0899f066572bb498ea3b4939d27743fd3e78364"; # nixos-21.11 on 2021-12-21
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

  zsh-syntax-highlighting = let
    version = "0.7.1";
    url-template = "https://github.com/zsh-users/zsh-syntax-highlighting/archive/${version}.tar.gz";
  in builtins.fetchTarball { url = url-template; };

  zsh-autosuggestions = let
    version = "v0.7.0";
    url-template = "https://github.com/zsh-users/zsh-autosuggestions/archive/${version}.tar.gz";
  in builtins.fetchTarball { url = url-template; };

in

{
  pkgs         = pkgs;
  home-manager = home-manager;

  zsh-syntax-highlighting = zsh-syntax-highlighting;
  zsh-autosuggestions     = zsh-autosuggestions;
}

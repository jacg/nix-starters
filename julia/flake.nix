# The core functionality is provided here using flakes. Legacy support for
# `nix-shell` is provided by a wrapper in `shell.nix`.


{
  description = "Julia development environment";

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
      in
        {
          devShell = pkgs.mkShell {
            name = "my-julia-project";
            buildInputs = [
              pkgs.julia-bin
            ];
          };
        }
    );
}

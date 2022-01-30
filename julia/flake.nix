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

    # Option 1: try to support each default system
    #flake-utils.lib.eachDefaultSystem # NB Some packages in nixpkgs are not supported on some systems

    # Option 2: try to support selected systems
    flake-utils.lib.eachSystem ["x86_64-linux" "i686-linux" "aarch64-linux" ] # Not "x86_64-darwin"
      (system:

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

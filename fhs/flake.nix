# The core functionality is provided here using flakes. Legacy support for
# `nix-shell` is provided by a wrapper in `shell.nix`.

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      fhs = pkgs.buildFHSUserEnv {
        name = "fhs-shell";
        targetPkgs = pkgs: [
          # Replace cowsay with stuff that you actually need
          pkgs.cowsay
        ];
      };
    in
      {
        devShells.${system}.default = fhs.env;
      };
}

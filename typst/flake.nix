{
  description = "Typst user environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [];
      };
    in
      {
        devShell.${system} = pkgs.mkShell {
          name = "typst-user";
          packages = [
            pkgs.just
            pkgs.typst
            #pkgs.typst-lsp
            pkgs.evince
          ];
        };
      };
}

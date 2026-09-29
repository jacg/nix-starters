{
  description = "Typst user environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }:
    let
      # Systems for which outputs are provided (some packages may not be
      # available on all of them). Remove any that you don't need.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f (perSystem system));

      perSystem = system: rec {
        pkgs = nixpkgs.legacyPackages.${system};

        fonts = [ pkgs.fira pkgs.fira-code ];
      };
    in
      {
        devShells = forEachSystem ({ pkgs, fonts, ... }: {
          default = pkgs.mkShell {
            name = "typst-tools";
            packages = [
              pkgs.typst
              pkgs.tinymist # LSP server
              pkgs.tree-sitter.builtGrammars.tree-sitter-typst # Grammar for Emacs typst-ts-mode
              pkgs.just
            ] ++ fonts
              # Optional: used in justfile. Not available on macOS
              ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.evince;
            shellHook = ''
              echo "Typst tools loaded!"
              echo "- Typst compiler: $(typst --version)"
              echo "- Tinymist LSP server: $(tinymist --version)"

              # Make tree-sitter grammar available to existing Emacs
              export TREE_SITTER_LIBRARY_PATH="${pkgs.tree-sitter.builtGrammars.tree-sitter-typst}/lib"
              # Make extra fonts available to fontconfig
              export FONTCONFIG_FILE="${pkgs.makeFontsConf { fontDirectories = fonts; }}"
            '';

          };
        });
      };
}

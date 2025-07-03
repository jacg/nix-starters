{
  description = "Typst user environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [];
      };

      fonts = [ pkgs.fira pkgs.fira-code ];

    in
      {
        devShell.${system} = pkgs.mkShell {
          name = "typst-tools";
          packages = [
            pkgs.typst
            pkgs.tinymist # LSP server
            pkgs.tree-sitter.builtGrammars.tree-sitter-typst # Grammar for Emacs typst-ts-mode
            pkgs.just
            pkgs.evince # Optional: used in justfile

          ] ++ fonts;
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
      };
}

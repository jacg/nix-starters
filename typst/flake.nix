{
  description = "Typst development environment";

  inputs = {
    # Version pinning is managed in flake.lock.
    # Upgrading can be done with `nix flake update <input-name>`
    #
    #    nix flake update nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05"; # nix flake update nixpkgs
  };

  outputs = { nixpkgs, ... }:
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

        # tree-sitter grammar for Emacs' typst-ts-mode, as Emacs wants it:
        # lib/libtree-sitter-typst.so
        grammars = pkgs.emacs.pkgs.treesit-grammars.with-grammars (g: [ g.tree-sitter-typst ]);
      };
    in
      {
        devShells = forEachSystem ({ pkgs, fonts, grammars, ... }: {
          default = pkgs.mkShell {
            name = "typst-tools";
            packages = [
              pkgs.typst
              pkgs.tinymist # LSP server
              pkgs.just
            ] ++ fonts
              # Optional: used in justfile. Not available on macOS
              ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.evince;
            # Make extra fonts available to typst and tinymist
            TYPST_FONT_PATHS = pkgs.lib.makeSearchPath "share/fonts" fonts;

            # Emacs does not look for tree-sitter grammars in any environment
            # variable, so tell it about this one in your Emacs configuration:
            #
            #   (when-let ((dir (getenv "TYPST_TS_GRAMMAR_DIR")))
            #     (add-to-list 'treesit-extra-load-path dir))
            #
            # With envrc-mode, the variable is visible in this project's buffers.
            TYPST_TS_GRAMMAR_DIR = "${grammars}/lib";

            shellHook = ''
              echo "Typst tools loaded: typst ${pkgs.typst.version}, tinymist ${pkgs.tinymist.version}"
            '';

          };
        });
      };
}

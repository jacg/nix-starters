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
        fontPaths = pkgs.lib.makeSearchPath "share/fonts" fonts;

        # tree-sitter grammar for Emacs' typst-ts-mode, as Emacs wants it:
        # lib/libtree-sitter-typst.so
        grammars = pkgs.emacs.pkgs.treesit-grammars.with-grammars (g: [ g.tree-sitter-typst ]);

        # The PDF, as `nix build` makes it. Every file in the flake (i.e.
        # every file tracked by git) is available to the document.
        document = pkgs.runCommand "thingy.pdf" {
          nativeBuildInputs = [ pkgs.typst ];
          TYPST_FONT_PATHS  = fontPaths;
        } ''
          cd ${./.}
          typst compile --ignore-system-fonts thingy.typ $out
        '';
      };
    in
      {
        packages = forEachSystem ({ document, ... }: {
          default = document;
        });

        # `nix flake check`: does the document compile?
        checks = forEachSystem ({ document, ... }: {
          inherit document;
        });

        devShells = forEachSystem ({ pkgs, fonts, fontPaths, grammars, ... }: {
          default = pkgs.mkShell {
            name = "typst-tools";
            packages = [
              pkgs.typst
              # To get Typst Universe (@preview/...) packages from nixpkgs,
              # pinned by flake.lock and available offline, rather than
              # downloaded on first use, replace pkgs.typst with e.g.
              #
              #   (pkgs.typst.withPackages (p: [ p.cetz ]))
              #
              # Then only the packages listed are available to typst, and
              # tinymist, which is not wrapped, does not see them.
              pkgs.tinymist # LSP server
              pkgs.just
            ] ++ fonts;

            # Make extra fonts available to typst and tinymist
            TYPST_FONT_PATHS = fontPaths;

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

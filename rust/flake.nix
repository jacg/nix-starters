# =============================================================================
# This flake provides a Rust development environment tooling.
# Legacy nix-shell support is available through the wrapper in `shell.nix`.
# =============================================================================
{
  description = "Rust development environment";

  inputs = {
    # Version pinning is managed in flake.lock.
    # Upgrading can be done with `nix flake update <input-name>`
    #
    #    nix flake update nixpkgs
    nixpkgs     .url = "github:nixos/nixpkgs/nixos-26.05"; # nix flake update nixpkgs
    rust-overlay = {                                       # nix flake update rust-overlay
      url                    = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Support for legacy nix-shell
    flake-compat = {
      url   = "github:NixOS/flake-compat";
      flake = false;
    };
  };

  outputs = { nixpkgs, rust-overlay, ... }:
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

      cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);

      perSystem = system: rec {
        pkgs     = nixpkgs.legacyPackages.${system};
        rust-bin = rust-overlay.lib.mkRustBin { } pkgs;

        # Our configured rust toolchain
        # If version unavailable, try `nix flake update rust-overlay`
        toolchain = rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

        # Build with our toolchain, rather than with nixpkgs' rustc
        rustPlatform = pkgs.makeRustPlatform {
          cargo = toolchain;
          rustc = toolchain;
        };

        package = rustPlatform.buildRustPackage {
          pname   = cargoToml.package.name;
          version = cargoToml.package.version;
          # Only these files affect the build: editing anything else will
          # not trigger a rebuild. Add to this if you create tests/,
          # benches/, build.rs, etc.
          src = pkgs.lib.fileset.toSource {
            root    = ./.;
            fileset = pkgs.lib.fileset.unions [ ./Cargo.toml ./Cargo.lock ./src ];
          };
          cargoLock.lockFile = ./Cargo.lock;
          useNextest = true; # Run the tests with nextest in checkPhase
        };
      };
    in
      {
        packages = forEachSystem ({ package, ... }: {
          default = package;
        });

        # `nix flake check`
        checks = forEachSystem ({ package, ... }: {
          # Building the package runs the tests
          tests = package;
          clippy = package.overrideAttrs (old: {
            pname        = "${old.pname}-clippy";
            buildPhase   = "cargo clippy --all-targets --offline -- --deny warnings";
            installPhase = "touch $out";
            doCheck      = false;
          });
        });

        devShells = forEachSystem ({ pkgs, toolchain, package, ... }: {
          default = pkgs.mkShell {
            name = "my-rust-project";

            # The package's build inputs
            inputsFrom = [ package ];

            packages = [
              toolchain
              pkgs.cargo-nextest  # Modern test runner
              pkgs.bacon          # Background rust code checker
              pkgs.just           # Command runner
            ];

            # Shell configuration. The prompt and aliases take effect only
            # under `nix develop`: direnv takes environment variables from
            # shellHook, but not aliases, and not PS1.
            shellHook = ''
              # Customize prompt
              export PS1="rust devshell> "

              # You could define aliases here
              alias testme='just test'
            '';
          };
        });
      };
}

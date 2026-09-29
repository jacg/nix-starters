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

  outputs = { self, nixpkgs, rust-overlay, ... }:
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
        pkgs     = nixpkgs.legacyPackages.${system};
        rust-bin = rust-overlay.lib.mkRustBin { } pkgs;
        # Our configured rust toolchain
        toolchain = rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      };
    in
      {
        devShells = forEachSystem ({ pkgs, toolchain, ... }: {
          default = pkgs.mkShell {
            name = "my-rust-project";

            packages = [
              toolchain
              pkgs.cargo-nextest  # Modern test runner
              pkgs.bacon          # Background rust code checker
              pkgs.just           # Command runner
            ];

            # Shell configuration
            shellHook = ''
              # Customize prompt
              export PS1="rust devshell> "

              # You could define aliases here
              alias testme='just test'
            '';

            # Enable rust-analyzer support (requires rust-src component in rust-toolchain.toml)
            RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";
            # If version unavailable, try `nix flake update rust-overlay`
          };
        });
      };
}

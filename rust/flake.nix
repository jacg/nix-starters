# =============================================================================
# This flake provides a Rust development environment tooling.
# Legacy nix-shell support is available through the wrapper in `shell.nix`.
# =============================================================================
{
  description = "Rust development environment";

  inputs = {
    # Version pinning is managed in flake.lock.
    # Upgrading can be done with `nix flake lock --update input <input-name>`
    #
    #    nix flake lock --update-input nixpkgs
    nixpkgs     .url = "github:nixos/nixpkgs/nixos-25.05"; # nix flake lock --update input nixpkgs
    rust-overlay.url = "github:oxalica/rust-overlay";      # nix flake lock --update input rust-overlay
    flake-utils .url = "github:numtide/flake-utils";
    # Support for legacy nix-shell
    flake-compat = {
      url   = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    # System selection options:
    # 1. All default systems (some packages may not be available)
    flake-utils.lib.eachDefaultSystem
    # 2. Selected systems only:
    # flake-utils.lib.eachSystem [
    #   "x86_64-linux"
    #   "aarch64-linux"
    #   "x86_64-darwin"
    # ]
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              # Add rust-overlay
              rust-overlay.overlays.default

              # Configure custom rust toolchain
              (final: prev: {
                rust-tools = final.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
              })
            ];
          };
        in
          {
            devShell = pkgs.mkShell {
              name = "my-rust-project";

              packages = [
                pkgs.rust-tools     # Our configured rust toolchain
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
              RUST_SRC_PATH = "${pkgs.rust-tools}/lib/rustlib/src/rust/library";
              # If version unavailable, try `nix flake lock --update input rust-overlay`
            };
          }
      );
}

{
  description = "Rust development environment";

  inputs = {

    nixpkgs     .url = "github:nixos/nixpkgs/nixos-21.11";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils .url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs { inherit system overlays; };
          # ----- Rust versions and extensions ----------------------------------
          extras = {
            extensions = [

              # Uncomment the extensions you want to enable, in the list below.
              # Some are enabled by default.

              # A history of available extensions is published on
              #
              #    https://rust-lang.github.io/rustup-components-history
              #
              # but this appears to contradict reality. To get an error message
              # which lists all available components, uncomment the following
              # line

              #  "does-not-exist" # Uncomment this line to generate list of extensions

              # Extensions which might be available. Uncomment those you want to
              # enable. Some are enabled by default.

              # "cargo"                    # enabled by default
              # "clippy"                   # enabled by default
              # "clippy-preview"           # seems to give the same version as clippy
              # "llvm-tools-preview"
              # "miri"
              # "miri-preview"
              # "reproducible-artifacts"
              # "rls"
              # "rls-preview"              # seems to give the same version as rls
              # "rust"
              # "rust-analysis"
              # "rust-analyzer-preview"
              # "rust-docs"
              # "rust-mingw"
              # "rust-src"
              # "rust-std"
              # "rustc"
              # "rustc-dev"
              # "rustc-docs"
              # "rustfmt"
              # "rustfmt-preview"
            ];
            #targets = [ "arg-unknown-linux-gnueabihf" ];
          };

          # If you already have a rust-toolchain file for rustup, you can simply
          # use fromRustupToolchainFile to get the customized toolchain
          # derivation.
          rust-tcfile  = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain;

          rust-latest  = pkgs.rust-bin.stable .latest      .default;
          rust-beta    = pkgs.rust-bin.beta   ."2022-01-25".default;
          rust-nightly = pkgs.rust-bin.nightly."2022-01-25".default;
          rust-stable  = pkgs.rust-bin.stable ."1.58.1"    .default;

          # Rust system to be used in buldiInputs. Choose between
          # latest/beta/nightly/stable on the next line
          rust = rust-stable.override extras;

      in
        {
          devShell = pkgs.mkShell {
            buildInputs = [
              rust
              pkgs.rust-analyzer
            ];
          };
        }
    );

}

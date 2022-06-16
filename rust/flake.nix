# The core functionality is provided here using flakes. Legacy support for
# `nix-shell` is provided by a wrapper in `shell.nix`.

# TODO HDF5
# TODO bindgen
# TODO PyO3
# TODO nixGL

{
  description = "Rust development environment";

  inputs = {

    # Version pinning is managed in flake.lock. Upgrading can be done with
    # something like
    #
    #    nix flake lock --update-input nixpkgs

    nixpkgs     .url = "github:nixos/nixpkgs/nixos-22.05";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils .url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:

    # Option 1: try to support each default system
    flake-utils.lib.eachDefaultSystem # NB Some packages in nixpkgs are not supported on some systems

    # Option 2: try to support selected systems
    # flake-utils.lib.eachSystem ["x86_64-linux" "i686-linux" "aarch64-linux" "x86_64-darwin"]
      (system:

        let pkgs = import nixpkgs {
              inherit system;


              overlays = [
                # ===== Specification of the rust toolchain to be used ====================
                rust-overlay.overlay (final: prev:
                  let
                    # If you have a rust-toolchain file for rustup, choose `rustup =
                    # rust-tcfile` further down to get the customized toolchain
                    # derivation.
                    rust-tcfile  = final.rust-bin.fromRustupToolchainFile ./rust-toolchain;
                    rust-latest  = final.rust-bin.stable .latest      ;
                    rust-beta    = final.rust-bin.beta   .latest      ;
                    rust-nightly = final.rust-bin.nightly."2022-06-14";
                    rust-stable  = final.rust-bin.stable ."1.61.0"    ; # nix flake lock --update-input rust-overlay
                    rust-analyzer-preview-on = date:
                      final.rust-bin.nightly.${date}.default.override
                        { extensions = [ "rust-analyzer-preview" ]; };
                  in
                    rec {
                      # The version of the Rust system to be used in buildInputs. Choose between
                      # tcfile/latest/beta/nightly/stable (see above) on the next line
                      rustup = rust-stable;

                      rustc = rustup.default;
                      cargo = rustup.default;
                      rust-analyzer-preview = rust-analyzer-preview-on "2022-06-14";
                    })
                # ==== Cargo nextest ========================================================
                (final: prev: {
                  cargo-nextest = final.callPackage ./overlays/cargo-nextest.nix {};
                })
              ];
            };

        in
          {
            devShell = pkgs.mkShell {
              name = "my-rust-project";
              buildInputs = [
                pkgs.rustc
                pkgs.cargo
                pkgs.rust-analyzer-preview
                pkgs.cargo-nextest
                pkgs.just
                pkgs.cowsay
              ];
              packages = [
                pkgs.lolcat
                pkgs.exa
              ];
              shellHook =
                ''
                  export PS1="rust devshell> "
                  alias foo='cowsay Foo'
                  alias bar='exa -l | lolcat'
                  alias baz='cowsay What is the difference between buildIntputs and packages? | lolcat'
                '';
              RUST_SRC_PATH = "${pkgs.rustup.rust-src}/lib/rustlib/src/rust/library";
            };
          }
      );
}

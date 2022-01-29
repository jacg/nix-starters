# TODO HDF5
# TODO bindgen
# TODO PyO3
# TODO nixGL

# To get a more recent version of nixpkgs, go to https://status.nixos.org/,
# which lists the latest commit that passes all the tests for any release.
# Unless there is an overriding reason, pick the latest stable NixOS release, at
# the time of writing this is nixos-21.05.

{
}:

let
  # ----- Pinned nixpkgs with pinned oxalica Rust overlay -------------------------------------------

  nixpkgs-commit-id = "6c4b9f1a2fd761e2d384ef86cff0d208ca27fdca"; # nixos-21.11 on 2022-01-27
  nixpkgs-url = "https://github.com/nixos/nixpkgs/archive/${nixpkgs-commit-id}.tar.gz";
  oxalica-commit-id = "9fb49daf1bbe1d91e6c837706c481f9ebb3d8097"; # 2022-01-22
  pkgs = import (fetchTarball nixpkgs-url) {
    overlays = map (uri: import (fetchTarball uri)) [
      "https://github.com/oxalica/rust-overlay/archive/${oxalica-commit-id}.tar.gz"
    ];
  };

  # ----- Rust versions and extensions --------------------------------------------------------------
  extras = {
    extensions = [

      # Uncomment the extensions you want to enable, in the list below. Some are
      # enabled by default.

      # A history of available extensions is published on
      #
      #    https://rust-lang.github.io/rustup-components-history
      #
      # but this appears to contradict reality. To get an error message which
      # lists all available components, uncomment the following line

      #  "does-not-exist" # Uncomment this line to generate list of extensions

      # Extensions which might be available. Uncomment those you want to enable.
      # Some are enabled by default.

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

  # If you already have a rust-toolchain file for rustup, you can simply use
  # fromRustupToolchainFile to get the customized toolchain derivation.
  rust-tcfile  = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain;

  rust-latest  = pkgs.rust-bin.stable .latest      .default;
  rust-beta    = pkgs.rust-bin.beta   ."2022-01-25".default;
  rust-nightly = pkgs.rust-bin.nightly."2022-01-25".default;
  rust-stable  = pkgs.rust-bin.stable ."1.58.1"    .default;

  # Rust system to be used in buldiInputs. Choose between
  # latest/beta/nightly/stable on the next line
  rust = rust-stable.override extras;

  # ----- Choice of included packages ---------------------------------------------------------------

  buildInputs = [
    rust
    pkgs.rust-analyzer
  ];

in

pkgs.mkShell {
  name = "my-rust-project";
  buildInputs = buildInputs;
}

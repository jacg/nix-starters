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

  nixpkgs-commit-id = "d4590d21006387dcb190c516724cb1e41c0f8fdf"; # nixos-21.05 on 2021-08-03
  nixpkgs-url = "https://github.com/nixos/nixpkgs/archive/${nixpkgs-commit-id}.tar.gz";
  oxalica-commit-id = "53b758596e8bd17e9fc764e14ba3e7686030bad3";
  pkgs = import (fetchTarball nixpkgs-url) {
    overlays = map (uri: import (fetchTarball uri)) [
      "https://github.com/oxalica/rust-overlay/archive/${oxalica-commit-id}.tar.gz"
    ];
  };

  # ----- Rust versions and extensions --------------------------------------------------------------
  extras = {
    extensions = [
      "rust-analysis" # Rust Language Server (RLS)
      "rust-src"      # Needed by RLS? or only rust-analyzer?
      "rls-preview"   # What do *-preview offer?
      "rustfmt-preview"
      "clippy-preview"
    ];
    #targets = [ "arg-unknown-linux-gnueabihf" ];
  };

  # If you already have a rust-toolchain file for rustup, you can simply use
  # fromRustupToolchainFile to get the customized toolchain derivation.
  rust-tcfile  = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain;

  rust-latest  = pkgs.rust-bin.stable .latest      .default;
  rust-beta    = pkgs.rust-bin.beta   ."2021-08-03".default;
  rust-nightly = pkgs.rust-bin.nightly."2021-08-03".default;
  rust-stable  = pkgs.rust-bin.stable ."1.54.0"    .default;

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

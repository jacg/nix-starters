{
  description = "jacg's flake templates";

  outputs = { self, ... }: {
    templates = {
      rust = {
        path = ./rust;
        description = "Rust project based on oxalica rust overlay";
        welcomeText = ''
          # Rust project

          Names to change to your project's:

          + `name` in `Cargo.toml` (the crate is called `rust`)
          + `name` and `description` in `flake.nix`

          Then `direnv allow` (or `nix develop`) and `just test`.
        '';
      };
      python = {
        path = ./python;
        description = "Python project";
      };
      typst = {
        path = ./typst;
        description = "Typst project";
      };
      home-manager = {
        path = ./home-manager;
        description = "Home Manager: personal Nix environment";
      };
    };
  };
}

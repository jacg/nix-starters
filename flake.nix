{
  description = "jacg's flake templates";

  outputs = { self, ... }: {
    templates = {
      rust = {
        path = ./rust;
        description = "Rust project based on oxalica rust overlay";
      };
      python = {
        path = ./python;
        description = "Python project";
      };
      julia = {
        path = ./julia;
        description = "Julia project";
      };
      home-manager = {
        path = ./home-manager;
        description = "Home Manager: personal Nix environment";
      };
    };
  };
}

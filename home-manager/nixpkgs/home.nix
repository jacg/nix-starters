{ config
, ...
}:

let
  sources = import ../sources.nix;
  pkgs = sources.pkgs;
  link = config.lib.file.mkOutOfStoreSymlink;
in

{
  home.file.".config/nixpkgs"  .source = link ../nixpkgs;

  programs.direnv.enable            = true;
  programs.direnv.nix-direnv.enable = true;

  home.packages = [
    sources.home-manager
    pkgs.cowsay
    pkgs.bat
  ];

}

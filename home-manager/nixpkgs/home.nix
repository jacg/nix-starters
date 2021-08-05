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

  nixpkgs.config.allowUnfree = true;

  programs.direnv.enable            = true;
  programs.direnv.nix-direnv.enable = true;

  programs.zsh.enable = true;

  home.packages = with pkgs; [
    sources.home-manager
    ripgrep  ripgrep-all  # better grep + find
    fd                    # better find
    bat                   # better cat
    du-dust               # better du
    exa                   # better ls
    tldr                  # alternative to drinking from `man` fire hose

    # Variations on the theme of `top`
    procs bottom zenith # htop: installed and configured by HM further down

    just        # recipe / command runner
    hyperfine   # benchmarking
    delta       # better diffs
    skim        # fuzzy finder
    rlwrap      # add readline capabilities to crappy shells
    mosh        # more robust alternative to ssh
    sd          # intuitive find and replace CLI

    git git-lfs github-cli

    # Golden oldies
    file lsof
    wget curl
    tmux
    rsync

  ];

  programs.htop = {
    enable = true;
    settings.cpu_count_from_zero = true;
  };

}

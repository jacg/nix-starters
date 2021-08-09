{ config
, ...
}:

let
  sources = import ../sources.nix;
  pkgs = sources.pkgs;
  p10k-theme = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  link = config.lib.file.mkOutOfStoreSymlink;

  myName     = "Jacek Generowicz";
  myGitEmail = "jacg@my-post-office.net";

in

{
  home.file.".config/nixpkgs"  .source = link ../nixpkgs;

  home.file.".zprofile"               .source = link ../zsh/zprofile;
  home.file.".zshrc"                  .source = link ../zsh/zshrc;
  home.file.".zshrc.pre"              .source = link ../zsh/pre;
  home.file.".zshrc.local"            .source = link ../zsh/local;
  home.file.".p10k.zsh"               .source = link ../zsh/p10k.zsh;
  home.file.".nixdls/p10k.zsh-theme"  .source = p10k-theme;
  home.file.".nixdls/zsh-sh"          .source = sources.zsh-syntax-highlighting;
  home.file.".nixdls/zsh-as"          .source = sources.zsh-autosuggestions;

  home.file.".gitconfig"              .source = link ../gitconfig;

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

    github-cli # git and git-lfs enabled below

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

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  fonts.fontconfig.enable = true;

}

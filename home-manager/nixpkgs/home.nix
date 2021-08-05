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
    userName = myName;
    userEmail = myGitEmail;

    aliases = {
      authors    = "!\"${pkgs.git}/bin/git log --pretty=format:%aN"
                 + " | ${pkgs.coreutils}/bin/sort"
                 + " | ${pkgs.coreutils}/bin/uniq -c"
                 + " | ${pkgs.coreutils}/bin/sort -rn\"";
      ls-ignored = "ls-files --exclude-standard --ignored --others";
      undo       = "reset --soft HEAD^";
      wdiff      = "diff --color-words";
      l          = "log --graph --pretty=format:'%Cyellow%h%Creset"
                 + " -%Cblue%d%Creset %s %Cgreen(%cr)%Creset'"
                 + " --abbrev-commit --date=relative --show-notes=*";
      lg         = "log --graph --decorate --oneline";
      lga        = "log --graph --decorate --oneline --all";
      man        = "ls-tree -r --name-only --full-tree HEAD";
      manifest   = "man";
      st         = "status";

      # git change-commits GIT_COMMITTER_NAME "old name" "new name" [first..last]
      change-commits = ''"!f() { VAR=$1; OLD=$2; NEW=$3; shift 3; git filter-branch --env-filter \"if [[ \\\"$`echo $VAR`\\\" = '$OLD' ]]; then export $VAR='$NEW'; fi\" $@; }; f "'';
      # from https://help.github.com/articles/remove-sensitive-data
      remove-file = "!f() { git filter-branch -f --index-filter \"git rm --cached --ignore-unmatch $1\" --prune-empty --tag-name-filter cat -- --all; }; f";

    };

    lfs.enable = true;

    extraConfig = {
      core = {
        editor            = "${pkgs.emacs}/bin/emacsclient -c";
        #whitespace        = "trailing-space,space-before-tab";
        };

      github.user           = "jacg";
      user.name             = myName;
      user.email            = myGitEmail;
      #github.oauth    How do you keep this secret?
      #credential.helper     = "${pkgs.pass-git-helper}/bin/pass-git-helper";
      #ghi.token             = "!${pkgs.pass}/bin/pass api.github.com | head -1";
      #hub.protocol          = "${pkgs.openssh}/bin/ssh";
      mergetool.keepBackup  = true;
      pull.rebase           = true;
      #rebase.autosquash     = true;
      rerere.enabled        = true;
    };
  };
}

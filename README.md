[![Test](https://github.com/jacg/nix-starters/actions/workflows/test.yml/badge.svg)](https://github.com/jacg/nix-starters/actions/workflows/test.yml)

# TLDR

To start a Rust / Python / Typst project type

``` shell
nix flake new -t github:jacg/nix-starters#rust ./target-directory
```

replacing

+ `rust` with `python` or `typst`, if appropriate

+ `./target-directory` with the name of the (not yet existing) directory in
  which you want the project to be created.

# Use Nix to provide isolated, per-project, declarative definitions of dependencies for projects in various languages

+ Key assumptions:

  1. The target machine has Nix installed and available to your user.

  2. Nix has the experimental features `nix-command` and `flakes` enabled.

     For a legacy version which works with older Nix, see the `legacy` branch. (TODO: not yet ready)

+ Helpful but not strictly necessary: [direnv](https://direnv.net/) is installed and enabled in your shell.

## Quickly bootstrap projects with development environments and dependencies in various languages

1. Create a directory for the project
2. `cd` into that directory
3. Create the project from a flake template:

   + `nix flake init -t github:jacg/nix-starters#rust` for a Rust project.
   + `nix flake init -t github:jacg/nix-starters#python` for a Python project.
   + `nix flake init -t github:jacg/nix-starters#typst` for Typst.
   + C++ [TODO If you need this, just ask. I do have a solution for a
     cmake-based project, but cleaning it up and publishing it isn't among my
     top priorities.

Alternatively, rather than creating the project directory by hand, it can be created by `nix flake`:

``` shell
nix flake new -t github:jacg/nix-starters#rust ./project-directory
```

### With `direnv`

If you have `direnv` installed and enabled, you should now see the following error message:
```
direnv: error <your project dierctory>.envrc is blocked. Run `direnv allow` to approve its content
```
If you trust that the template won't do anything anything malicious on your
machine, approve it as suggested by the message: `direnv allow`.

Check that everything as expected by typing `just`: you should see some successful test executions.

Henceforth the environment will be activated automatically each time you `cd`
into `<your project dir>` or any of its subdirectories, and deactivated when you
`cd` back out.

You can withdraw permission for `direnv` to activate this environment
automatically with `direnv deny`.

If you are using `home-manager` to provide `direnv`, you will need

``` nix
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    nix-direnv.enableFlakes = true;
  };
```

### Without `direnv`

You can activate the environment manually with `nix develop`. This will start a
new shell with the environment activated. Check that everything as expected by
typing `just`: you should see some successful test executions. Exit the shell,
to disable the environment.

### Specifying dependencies

The details will vary to some extent from language to language. Broadly speaking, add dependencies to `buildInputs` in `devShell` set inside `flake.nix`.

## Take your toolset with you: home-manager

`home-manager` allows you to reproduce your arbitrarily complex personal toolset and configuration on a new machine, with minimal effort.

**BEWARE** the git config has contains my name and email address! So make sure to edit `home-manager/gitconfig` before deploying.

See `home-manager/README.md` for details. TODO: README does not exist yet.

## Pinning

The versions of all the tools and dependencies are pinned: their exact versions are specified in `flake.lock`. Upgrading can be done with something like:

``` nix
nix flake lock --update-input nixpkgs
```

[![Test](https://github.com/jacg/nix-starters/actions/workflows/test.yml/badge.svg)](https://github.com/jacg/nix-starters/actions/workflows/test.yml)

# Use Nix to provide isolated, per-project, declarative definitions of dependencies for projects in various languages

+ Key assumption: the target machine has Nix installed and available to your user.

+ Helpful but not strictly necessary: [direnv](https://direnv.net/) is installed and enabled in your shell.

## Quickly bootstrap development environments in various languages

+ Rust
+ Python
+ Julia [This one is different from the others. See `julia/README.md`.]
+ C++ [TODO If you need this, just ask. I do have a solution for a cmake-based project, but cleaning it up and publishing it isn't among my top priorities.

### Assuming that you are using `direnv`

1. Copy `<chosen-language>/{shell.nix,.envrc}` into the top directory of your project.
2. `cd <your project dir>`
3. The first time you do this, you will see the error message
   ```shell
   direnv: error <your project dir>/.envrc is blocked. Run `direnv allow` to approve its content
   ```
4. Follow the hint: `direnv allow`
5. Henceforth the environment will be activated automatically each time you `cd` into `<your project dir>` or any of its subdirectories, and deactivated when you `cd` back out.

### Without direnv

1. You only need `shell.nix`, not `.envrc`.
2. Manually activate the environment with `nix-shell <your project dir>/shell.nix`. This will drop you into a `bash` with the environment. Exiting this shell deactivates the environment.

### Specifying dependencies

The details will vary to some extent from language to language. Broadly speaking, add dependencies to `buildInputs` in `shell.nix`.

## Take your toolset with you: home-manager

home-manager allows you to reproduce your arbitrarily complex personal toolset and configuration on a new machine, with minimal effort.

**BEWARE** the git config has contains my name and email address! So make sure to edit `home-manager/gitconfig` before deploying.

## Flakes

+ At present flakes are too painful to work with for Nix non-experts (the target audience).
+ I don't have time to maintain two versions.

Consequently, as far as these recipes are concerned, I am ignoring the existence of flakes until they are fully stabilized. But I do intend to migrate these recipes to flakes once they are stable.

## Pinning

The nix versions are pinned. To switch to a more recent set of packages, change `nixpkgs-commit-id` in your chosen `shell.nix`:

    To get a more recent version of nixpkgs, go to https://status.nixos.org/,
    which lists the latest commit that passes all the tests for any release.
    Unless there is an overriding reason, pick the latest stable NixOS release, at
    the time of writing this is nixos-21.05.

The details may vary depending on exactly how Nix has been installed on the machine, so there may be additional hoops to jump through, but ideally (if multi-user Nix is installed) the following should work:

1. `cd home-manager`
2. `./bootstrap-home-manager`

Thereafter, the environment defined in `home-manager/nixpkgs/home.nix` should be automatically activated whenever you log in.

If you add/remove packages or otherwise change the configuration in `home-manager/nixpkgs/home.nix`, you need rebuild the profile with

```shell
home-manager -b bck switch
```

## `link`

Consider the lines

```shel
  home.file.".gitconfig".source = link ../gitconfig;
  home.file.".gitconfig".source =      ../gitconfig;
```

The former appears in `home-manager/nixpkgs/home.nix` and is a somewhat heterodox version of the latter:

+ The first version allows you to edit the `gitconfig` file and have your environment pick up the changes without the need for a `home-manager switch`. This is convenient but makes your environments less reproducible.
+ The second version makes your environment ignore any edits to `gitconfig` until you rebuild the environment with `home-manager switch`, which takes an annoying amount of time to execute, especially if you are experimenting with different settings.

As I keep all the files that are `link`ed in this way under version control in the same repository as `home.nix`, the lack of reproducibility is much less of an issue, and the increased flexibility comes at essentially no cost. Avoid `link`ing to files which are *not* version-controlled in the same repository.

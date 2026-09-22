# When something doesn't work: `just rescue`

If a package won't install, or installs but won't run, and you don't have time
to understand why — type `just rescue`. It prints three things to try, in
order. Start at the top, stop as soon as it works.

The short version, if `just` itself is what's broken:

``` shell
uv venv --system-site-packages
. .venv/bin/activate
uv pip install THE-PACKAGE-YOU-NEED
```

That handles most cases, works like `pip` (it *is* pip, just faster), and
doesn't need anything special set up on your machine.

Afterwards, tell whoever maintains this project what you had to install. Rungs
2 and 3 don't record anything — next week, or on a different machine, you won't
get the same environment back.

# Normal use

`just test` runs the tests. Dependencies live in `python-with-all-my-packages`
in `flake.nix`; add to that list and re-enter the directory (`direnv reload`)
to pick them up.

The shell gives you Python 3.14 by default. `nix develop .#python312` or
`.#python313` gets you the others.

# Why the escape hatch exists

Nix installs everything into `/nix/store` and provides none of the paths
(`/usr/lib`, `/lib64`) that pre-built Linux binaries expect. Most of the time
this is invisible. It becomes visible in two distinct ways, which need
different fixes — and which are easy to confuse, because one of them lies to
you about what's wrong.

**A wheel's shared library can't find its dependencies.** You `pip install`
something, and importing it complains that `libFoo.so.N` is missing. The Python
interpreter here is fine — it comes from nixpkgs — so only the wheel's own
`.so` files need help. The `LD_LIBRARY_PATH` set in `flake.nix` handles the
common cases; add to `wheel-libs` there if you hit one it doesn't cover. This
is rung 2, and it needs nothing from your system configuration.

**A foreign Python interpreter can't start at all.** Conda, Anaconda,
micromamba and pixi don't just install packages — they install their own
`python` executable, compiled to look for its loader at
`/lib64/ld-linux-x86-64.so.2`. That path doesn't exist on NixOS, so the kernel
refuses to start the program, and reports it as:

```
bash: .../bin/python: No such file or directory
```

which is a genuinely misleading message: the file is right there. This is why
`micromamba install` can report success and still leave you with an
environment in which nothing runs — it unpacks archives happily, and the
failure only appears later.

Fixing this requires one of two things, neither of which lives in this project:

- **`nix-ld`**, enabled system-wide by whoever administers the machine:

  ``` nix
  programs.nix-ld.enable = true;
  ```

  After a rebuild, conda-style tools work normally. If a program then
  complains about a missing `libFoo.so.N`, add that package to
  `programs.nix-ld.libraries`.

- **An FHS sandbox** (`pkgs.buildFHSEnv`), which fakes the expected layout for
  one command. Doesn't require system access, but has to be built and
  maintained per project.

`just rescue` checks which situation you're in and won't offer you rung 3 if it
can't work.

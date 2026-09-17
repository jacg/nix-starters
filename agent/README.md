# Sandboxed Claude Code, as a reusable flake

Personal agent policy — what Claude Code may see and do — separated from any
project. Built on [agent-sandbox.nix](https://github.com/archie-judd/agent-sandbox.nix).
The sandbox sees the directory it is launched from, the Nix store and daemon,
`~/.claude`, and nothing else; network access goes through a proxy with an
explicit domain allowlist.

This directory is staged in cttchatelaine-manager while it stabilises. Its
destination is jacg/nix-starters as `agent/`, consumed as
`github:jacg/nix-starters?dir=agent`; when it moves, consumers change one URL.

## Three ways to consume it

**1. Your own Nix project.** The project flake adds one input and one shell,
contributing only what is project-specific:

```nix
inputs.agent.url = "github:jacg/nix-starters?dir=agent";

devShells.agent = agent.lib.${system}.mkAgentShell {
  packages = projectPackages;                     # on the sandbox PATH
  domains  = { "crates.io" = [ "GET" "HEAD" ]; }; # over the baseline allowlist
  shell    = { shellHook = ''export PS1="agent> "''; };
};
```

**2. A collaborative project on which you impose neither Nix nor agents.**
Keep a *shadow flake* outside that repository, for example
`~/.config/agent-shells/<project>/flake.nix`:

```nix
{
  inputs.agent.url = "github:jacg/nix-starters?dir=agent";
  outputs = { self, agent }:
    let system = "x86_64-linux";
    in {
      devShells.${system}.default = agent.lib.${system}.mkAgentShell {
        packages = [ /* toolchain from nixpkgs, even if collaborators use rustup/npm */ ];
        domains  = { /* discovered with unrestricted = true, see below */ };
      };
    };
}
```

then, from the checkout of the collaborative project:

```sh
nix develop ~/.config/agent-shells/<project>
```

The sandbox mounts the directory it is launched from, so being in the checkout
is all that is needed. Nothing — no flake, no .envrc, no .gitignore entry —
enters the shared repository; if the agent needs in-tree scratch files, hide
them locally with `.git/info/exclude`.

**3. Ad hoc, anywhere.** From any project root:

```sh
nix run github:jacg/nix-starters?dir=agent#claude-sandboxed -- --dangerously-skip-permissions
```

No project packages on the PATH, but the sandbox has the host Nix daemon and
store, so the agent runs `nix develop -c ...` (if the project has a flake) or
`nix shell nixpkgs#tool` as needed. Fixed-output fetches and substitutions
happen in the daemon, outside the sandbox, so they are not throttled by the
domain allowlist.

## Discovering a project's domains

For an unfamiliar project the allowlist is unknown. Build the sandbox once
with `unrestricted = true`, exercise the workflow, read `proxy.log`, then
write the observed domains into `domains` and drop the flag.

## Authentication

None to configure: log in once with the host `claude`, and the sandbox reads
the stored credentials from `~/.claude` (mounted read-write, with
`CLAUDE_CONFIG_DIR` pointing at it on both sides). Never export
`CLAUDE_CODE_OAUTH_TOKEN` — it silently overrides those credentials and is
never refreshed.

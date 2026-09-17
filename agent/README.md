# Sandboxed Claude Code, as a reusable flake

Personal agent policy — what Claude Code may see and do — separated from any
project. Built on [agent-sandbox.nix](https://github.com/archie-judd/agent-sandbox.nix).
The sandbox sees the directory it is launched from, the Nix store and daemon,
`~/.claude`, and nothing else. Network access goes through a filtering proxy:
the agent may read the whole internet, and may *write* — POST and friends —
only to hosts named explicitly.

This directory is staged in cttchatelaine-manager while it stabilises. Its
destination is jacg/nix-starters as `agent/`, consumed as
`github:jacg/nix-starters?dir=agent`; when it moves, consumers change one URL.

## Three ways to consume it

**1. Your own Nix project.** The project flake adds one input and one shell,
contributing only what is project-specific:

```nix
inputs.agent.url = "github:jacg/nix-starters?dir=agent";

devShells.agent = agent.lib.${system}.mkAgentShell {
  packages = projectPackages;          # on the sandbox PATH
  domains  = { "crates.io" = "*"; };   # writes; reading needs no entry
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
        domains  = { /* only if the agent must write somewhere, see below */ };
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
`nix shell nixpkgs#tool` as needed.

## The network policy

The baseline grants **GET and HEAD to every domain**, and Anthropic's endpoints
in full. Documentation lives on hosts no list can enumerate in advance, and
keeping data in is not this sandbox's job, so reading is granted outright and
the policy's remaining work is to stop the agent *changing* things: POST, PUT,
PATCH, DELETE, WebSocket upgrades and a request body on a GET or HEAD are all
denied everywhere except the hosts named above.

`domains` can only narrow, because exactly one entry decides each request — the
exact host if listed, otherwise the longest matching suffix, otherwise `"*"` —
and entries never merge. Use it to gain a *method* on a host
(`{ "crates.io" = "*"; }` to publish), never to gain the host itself.

Nix substitutions and fixed-output fetches happen in the host daemon, outside
the sandbox, so they are not subject to the policy at all.

## Authentication

None to configure: log in once with the host `claude`, and the sandbox reads
the stored credentials from `~/.claude` (mounted read-write, with
`CLAUDE_CONFIG_DIR` pointing at it on both sides). Never export
`CLAUDE_CODE_OAUTH_TOKEN` — it silently overrides those credentials and is
never refreshed.

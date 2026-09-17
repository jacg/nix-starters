# Sandboxed Claude Code, as a reusable flake

Personal agent policy — what Claude Code may see and do — separated from any
project, and shipped as a flake input so the decisions are made once rather
than per project.

The sandbox sees the directory it is launched from, the Nix store and daemon,
`~/.claude`, and nothing else. Network access goes through a filtering proxy:
the agent may read the whole internet, and may *write* — POST and friends —
only to hosts named explicitly.

The sandbox itself — bubblewrap, the filtering proxy — is
[agent-sandbox.nix](https://github.com/archie-judd/agent-sandbox.nix). This
flake contributes no isolation mechanism of its own; it fixes a policy over
that one. Linux only (`x86_64`, `aarch64`), although the sandbox underneath
supports macOS too.

## What this adds over calling `mkSandbox` yourself

**A stated threat model.** `mkSandbox` takes no position on what you are
defending against; this flake does. It protects the host and the outside world
*from the agent* — which directories it can write, which remote state it can
change — and it does not try to keep your data in. That is a deliberate fit to
what it is for: open-source work, with no secrets in the tree. It is also what
makes a read-the-whole-internet network policy the right default here rather
than a lapse; see [The network policy](#the-network-policy).

**Two decisions per project instead of fourteen.** `mkSandbox` takes fourteen
arguments, most of them part of the security boundary. Here a project supplies
`packages` and `domains`; mounts, Nix access and credentials are settled once,
for every project at once.

**One way to authenticate, not two overlapping ones.** Upstream supports an
environment-variable token *or* the credential files a host login leaves in
`~/.claude`, and its examples do both at once. Doing both is a trap:
`CLAUDE_CODE_OAUTH_TOKEN` silently wins over the stored credentials and is
never refreshed, so sessions start failing when it expires. This flake never
sets it — see [Authentication](#authentication).

**`CLAUDE_CONFIG_DIR` agreed on both sides.** Upstream notes that if you also
run Claude outside the sandbox you must set this globally yourself. Here the
dev shell exports it, so host and sandbox agree without anything in
`~/.bashrc`; if they disagree, every launch re-runs the onboarding wizard.

**Unfree stays contained.** `claude-code` is unfree. This flake imports its own
nixpkgs with a predicate scoped to that single package, so consuming projects
need no `allowUnfree` configuration of their own.

**It works on projects with no Nix in them, and on projects that are not
yours** — modes 2 and 3 below.

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

## Why `packages` must be given here

`agent-sandbox` clears the environment with `env -i` at launch, so the sandbox
PATH is whatever was fixed when the sandbox was *built*. Composition therefore
happens at Nix evaluation time, in the `packages` argument above: entering a
project dev shell and then launching a generic sandbox from it does **not**
carry that shell's tools in. The agent sees `commonTools` plus `packages`, and
nothing else.

This costs less than it appears, because `allowNix` lets the agent materialise
any environment for itself — which is all mode 3 does.

## The network policy

The baseline grants **GET and HEAD to every domain**, and Anthropic's endpoints
in full. Documentation lives on hosts no list can enumerate in advance, and
keeping data in is not this sandbox's job, so reading is granted outright and
the policy's remaining work is to stop the agent *changing* things.

What it still denies, everywhere except the hosts named above: POST, PUT,
PATCH, DELETE, WebSocket upgrades, and a request body on a GET or HEAD — so a
read stays a read as far as the origin is concerned. The proxy remains in the
path either way, and still logs every host the agent contacts to `proxy.log`.

The proxy prints a startup warning that a `"*"` entry is present, naming what
it permits. Expected here, not a misconfiguration.

**`domains` can only narrow.** Exactly one entry applies — the exact host if it
is listed, otherwise the longest matching suffix, otherwise `"*"` — and
policies never merge. A project entry is therefore how you gain a *method* on a
host (`{ "crates.io" = "*"; }` to publish), never how you gain the host itself;
and a host listed with fewer methods than the floor has access taken away.

**Entries match by suffix**, which makes a named host broader than it looks:
`github.com` also covers `codeload.github.com`, `gist.github.com` and every
other `*.github.com`.

Nix substitutions and fixed-output fetches run in the host daemon, *outside*
the sandbox, so they are not subject to the policy at all; what it governs is
the agent fetching directly.

**If you ever tighten this** — drop the floor for some project and enumerate
hosts instead — what a session actually needs is not obvious. Build the sandbox
once with `unrestricted = true`, exercise the workflow, and read `proxy.log`.
Watch for redirects while reading it: an allowed host that 302s to one you have
not allowed fails at the redirect, and the log names the first host, not the
destination.

## Authentication

None to configure: log in once with the host `claude`, and the sandbox reads
the stored credentials from `~/.claude` (mounted read-write, with
`CLAUDE_CONFIG_DIR` pointing at it on both sides). Entering the shell tells you
which of those two states you are in.

Never export `CLAUDE_CODE_OAUTH_TOKEN`. It silently overrides the stored
credentials and is never refreshed — and because the sandbox inherits it from
the launching shell, exporting it for something else is enough to break the
agent later, in a way that looks like an expiry bug rather than a
configuration one.

The agent can read everything you hand it, credentials included. `~/.claude` is
mounted read-write because that is how it logs in.

## Arguments

Both `mkAgentShell` and `mkClaudeSandboxed` take:

| | |
| --- | --- |
| `packages` | Put on the sandbox PATH beside upstream's `commonTools` (and, for `mkAgentShell`, in the surrounding dev shell). Must be supplied here — see above. |
| `domains` | Merged over the baseline policy, where it can only narrow: use it to grant *methods* beyond the baseline's GET/HEAD. |
| `unrestricted` | Every method on every domain. Beyond the baseline that adds only writes and WebSockets, everywhere; for discovery, not routine use. |

`mkAgentShell` additionally takes `shell`, merged into the `mkShell` arguments
and overriding them — except `shellHook`, which is *appended* to the standard
one. Do not pass `packages` through `shell`: it would replace the sandbox
itself.

## What the flake exposes

- `lib.mkAgentShell` — a dev shell holding the sandboxed agent, the same
  packages on the host side, and the unsandboxed `claude` for the one-off
  login.
- `lib.mkClaudeSandboxed` — the wrapped binary alone, for putting in a shell
  of your own.
- `lib.claudeConfigDir` — the `export CLAUDE_CONFIG_DIR=...` line, so a
  hand-rolled `shellHook` that runs the host `claude` can agree with the
  sandbox.
- `packages.claude-sandboxed` (also `packages.default`) — the generic sandbox
  used by mode 3.
- `devShells.default` — `mkAgentShell { }`, the generic agent shell.

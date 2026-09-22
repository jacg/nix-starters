# =============================================================================
# Sandboxed Claude Code as personal, project-agnostic policy.
#
# Everything about what the agent may see and do — mounts, domains,
# credentials, access to the Nix daemon — lives here. A project contributes
# exactly two things, both optional:
#
#   packages   put on the sandbox PATH beside the common tools
#   domains    extra HTTP methods, over the baseline network policy
#
# Even `packages` is a convenience, not a requirement: the sandbox has the
# host Nix daemon and store (allowNix), so the agent can materialise any
# project environment itself with `nix develop -c ...`.
#
# The sandbox PATH is fixed when the sandbox is built (agent-sandbox clears
# the environment with `env -i` at launch), so composition happens here, at
# Nix evaluation time — entering a project dev shell and then launching a
# generic sandbox would NOT carry the project's tools in.
#
# Authentication: none to configure. mkAgentShell exports CLAUDE_CONFIG_DIR so
# the host `claude` (for logging in) and `claude-sandboxed` share ~/.claude,
# which the sandbox mounts read-write; the agent reads the credentials Claude
# Code stored there when you logged in on the host. Do NOT export
# CLAUDE_CODE_OAUTH_TOKEN: it silently overrides those credentials and is
# never refreshed.
#
# See README.md for the three ways to consume this flake.
# =============================================================================
{
  description = "Claude Code in a sandbox: agent policy composable with any project";

  inputs = {
    nixpkgs      .url = "github:nixos/nixpkgs/nixos-26.05";
    flake-utils  .url = "github:numtide/flake-utils";
    agent-sandbox.url = "github:archie-judd/agent-sandbox.nix";
  };

  outputs = { self, nixpkgs, flake-utils, agent-sandbox }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ]
      (system:
        let
          # Own nixpkgs import, so consuming projects need no unfree predicate:
          # claude-code is the only unfree package involved and it is this
          # flake's business.
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg: pkgs.lib.getName pkg == "claude-code";
          };

          sbx = agent-sandbox.lib.${system};

          # Read the whole internet; write nowhere but Anthropic.
          #
          # Documentation lives on hosts no list can enumerate in advance, and
          # confidentiality is not the boundary here: this is for open-source
          # work with no secrets in the tree. So reading is granted outright,
          # and the policy's job is to stop the agent *changing* things. What
          # the floor still denies everywhere unlisted: POST/PUT/PATCH/DELETE,
          # WebSocket upgrades, and a body on a GET or HEAD — so a read stays a
          # read as far as the origin is concerned. No read-only host needs
          # naming here — not github.com, not the nixos.org caches: the floor
          # already said it.
          #
          # Exactly one entry decides each request — the exact host, else the
          # longest matching suffix, else "*", else deny — and entries never
          # merge. So `domains` can only narrow: a project entry is how you
          # gain a *method* on a host, never how you gain the host itself. The
          # proxy warns at startup that "*" is present, naming what it permits;
          # that is expected here.
          baselineDomains = {
            "anthropic.com" = "*";
            "claude.com"    = "*";
            "*"             = [ "GET" "HEAD" ];
          };

          # `nix shell nixpkgs#tool` inside the sandbox resolves `nixpkgs`
          # through the global registry, whose entry is a channel tarball the
          # policy does let through. Pin the ids anyway: resolution then needs
          # no network at all, and the agent gets the nixpkgs this policy pins
          # rather than whatever the channel said this morning.
          #
          # This replaces the global registry only. An entry for the same id in
          # the user registry (~/.config/nix/registry.json, mounted rw) is
          # consulted first and still wins.
          flakeRegistry = pkgs.writeText "agent-flake-registry.json" (builtins.toJSON {
            version = 2;
            flakes  = [
              # No network at all: this tree is already in the store, because
              # this flake was evaluated from it.
              { from = { type = "indirect"; id = "nixpkgs"; };
                to   = { type = "path"; path = nixpkgs.outPath;
                         inherit (nixpkgs) narHash lastModified; }; }

              # The escape hatch, for when the pin is too old. Deliberately a
              # branch and not a revision: a pinned "unstable" is stale by
              # construction, and embedding a second nixpkgs tree would put
              # 205 MiB into the closure of a sandbox that may never use it.
              # Costs a GET on first use, which the allowlist floor serves.
              { from = { type = "indirect"; id = "nixpkgs-unstable"; };
                to   = { type = "github"; owner = "nixos"; repo = "nixpkgs";
                         ref = "nixos-unstable"; }; }
            ];
          });

          # Claude Code keeps its onboarding state in ~/.claude.json unless this
          # is set, in which case that file lives inside the directory instead.
          # The sandbox needs it there (only ~/.claude is mounted), and the host
          # copy must agree or every launch re-runs the setup wizard. Same value
          # in mkClaudeSandboxed's env block and in every shellHook that might
          # run the host `claude`, so nothing depends on ~/.bashrc.
          claudeConfigDir = ''
            export CLAUDE_CONFIG_DIR="$HOME/.claude"
          '';

          mkClaudeSandboxed =
            { packages     ? [ ]    # on the sandbox PATH, beside sbx.commonTools
            , domains      ? { }    # merged over baselineDomains
            , unrestricted ? false  # every method everywhere; see baselineDomains
            }:
            sbx.mkSandbox {
              pkg              = pkgs.claude-code;
              binName          = "claude";
              outName          = "claude-sandboxed";
              allowedPackages  = sbx.commonTools ++ packages;
              # The agent must test in exactly the environment humans test in:
              # give it the host Nix daemon and store so it can run
              # `nix develop -c ...`.
              allowNix         = true;
              allowUnixSockets = true;   # required by allowNix (daemon socket)
              rwDirs = [
                "$HOME/.claude"
                "$HOME/.cache/nix"        # nix client state; without these every
                "$HOME/.config/nix"       # launch re-fetches the flake registry
                "$HOME/.local/share/nix"
              ];
              # Identity, so commits are correctly attributed. Both are needed:
              # jj does not read git's config for user.name/user.email, and a
              # jj repo committed to without its own config gets the *empty*
              # identity — which looks fine locally and is refused by every
              # remote. The file, not the $HOME/.config/jj directory: jj writes
              # `repos/` beside its config on first use in a repo, and wants
              # that writable. Anything in conf.d/ is therefore not carried in.
              #
              # Both paths must exist on the host — a declared bind that does
              # not is refused at launch, by design.
              roFiles = [
                "$HOME/.config/git/config"      # git identity
                "$HOME/.config/jj/config.toml"  # jj identity
                "/etc/nix/nix.conf"             # inherit host nix config (flakes, caches)
              ];
              env = {
                CLAUDE_CONFIG_DIR = "$HOME/.claude";                     # see claudeConfigDir above
                # Overrides this one setting; /etc/nix/nix.conf, bound in
                # roFiles, still supplies the rest.
                NIX_CONFIG        = "flake-registry = ${flakeRegistry}"; # see flakeRegistry above
              };
              allowedDomains = if unrestricted
                               then { "*" = "*"; }
                               else baselineDomains // domains;
            };

          loginHint = ''
            if [ -f "$CLAUDE_CONFIG_DIR/.credentials.json" ]
            then echo "Run: claude-sandboxed --dangerously-skip-permissions"
            else echo "Not logged in. Run: claude   (once, outside the sandbox), then: claude-sandboxed --dangerously-skip-permissions"
            fi
          '';

          # A dev shell holding the sandboxed agent, the same packages on the
          # host side, and the unsandboxed claude for the one-off host login.
          # `shell` is merged into the mkShell arguments (extra env vars, name,
          # ...) and overrides them, except shellHook, which is appended to the
          # standard one. Do not pass `packages` through `shell`: it would
          # replace the sandbox itself.
          mkAgentShell =
            { packages     ? [ ]
            , domains      ? { }
            , unrestricted ? false
            , shell        ? { }
            }:
            pkgs.mkShell ({
              name     = "claude-agent";
              packages = packages ++ [
                (mkClaudeSandboxed { inherit packages domains unrestricted; })
                pkgs.claude-code   # unsandboxed, for the one-off `claude` login on the host
              ];
              shellHook = claudeConfigDir + loginHint + (shell.shellHook or "");
            } // builtins.removeAttrs shell [ "shellHook" ]);
        in
          {
            lib = { inherit mkClaudeSandboxed mkAgentShell claudeConfigDir; };

            # For repositories that carry no Nix at all: from the project root,
            # `nix run <this-flake>#claude-sandboxed -- --dangerously-skip-permissions`.
            # No project packages on the PATH, but allowNix lets the agent run
            # `nix develop -c ...` or `nix shell nixpkgs#tool` as needed.
            packages.claude-sandboxed = mkClaudeSandboxed { };
            packages.default          = mkClaudeSandboxed { };

            # `nix develop <this-flake>`: the generic agent shell, ditto.
            devShells.default = mkAgentShell { };
          }
      );
}

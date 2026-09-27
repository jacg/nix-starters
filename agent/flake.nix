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
# Authentication: log in once, with /login inside the sandbox. The sandbox has
# a Claude config directory of its own (see agentClaudeDir) and never sees the
# host's ~/.claude, so the two logins, settings and memories are independent.
# Do NOT export CLAUDE_CODE_OAUTH_TOKEN: it silently overrides the stored
# credentials and is never refreshed.
#
# See README.md for the three ways to consume this flake.
# =============================================================================
{
  description = "Claude Code in a sandbox: agent policy composable with any project";

  inputs = {
    nixpkgs        .url = "github:nixos/nixpkgs/nixos-26.05";
    flake-utils    .url = "github:numtide/flake-utils";
    agent-sandbox  .url = "github:archie-judd/agent-sandbox.nix";

    # claude-code itself does not come from the nixpkgs pin above: nixpkgs
    # only bumps it at nixpkgs' own pace, which lags Anthropic's releases by
    # however long since this flake's nixpkgs input was last updated. This
    # input tracks Anthropic's npm releases directly (hourly checks, built
    # and smoke-tested, auto-merged) so the sandbox's Claude Code — and the
    # models it knows how to talk to — stays current. See "Where claude-code
    # comes from" in README.md for the trust tradeoff this implies.
    claude-code-nix.url = "github:sadjow/claude-code-nix";
  };

  outputs = { self, nixpkgs, flake-utils, agent-sandbox, claude-code-nix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ]
      (system:
        let
          pkgs = import nixpkgs { inherit system; };

          # claude-code-nix sets allowUnfree in its own nixpkgs import, so
          # nothing needs doing here for it; this flake's own pkgs above never
          # touches an unfree package.
          claudeCode = claude-code-nix.packages.${system}.default;

          # agent-sandbox with one patch to its proxy: git's smart-HTTP fetch
          # is a POST, so under the GET/HEAD floor (see baselineDomains)
          # `git clone https://…` fails on every host. The patch lets through
          # a POST to …/git-upload-pack wherever GET is granted; push
          # (git-receive-pack) stays refused. The source is patched rather
          # than the proxy overridden because agent-sandbox builds its proxy
          # internally, with no argument to replace it. Evaluated with
          # agent-sandbox's own nixpkgs, exactly as its `lib` output is, so
          # nothing but the proxy changes. Drop this if upstream takes it.
          sbx = import (pkgs.applyPatches {
            name    = "agent-sandbox-git-fetch";
            src     = agent-sandbox;
            patches = [ ./proxy-git-fetch.patch ];
          }) { pkgs = import agent-sandbox.inputs.nixpkgs { inherit system; }; };

          # agent-sandbox's commonTools carries git but not jj. Since the
          # sandbox launches with `env -i`, nothing on the host PATH carries
          # in: whatever is not named here is simply absent, and the agent
          # silently falls back to git in a repo where jj is the tool. This is
          # baseline personal policy, not a project's business, so it belongs
          # beside commonTools rather than in the per-project `packages`.
          baselineTools = sbx.commonTools ++ [ pkgs.jujutsu ];

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

          # The sandbox's own Claude config directory: its login, settings,
          # history and memory. Deliberately not the host's ~/.claude. Several
          # files there are commands the host `claude` runs (hooks and the
          # status line in settings.json, mcpServers in .claude.json, plugins,
          # skills), so a sandbox able to write them could plant code that runs
          # outside it. Sharing only the credentials file is no way out either:
          # Claude rewrites it on every token refresh, possibly by rename, which
          # a bind-mounted single file does not survive. So the sandbox logs in
          # separately, to the same account, and nothing is shared.
          #
          # CLAUDE_CONFIG_DIR puts .claude.json inside this directory too, which
          # is what upstream recommends over mounting that file on its own.
          # A shell expression, expanded on the host by hostWrapper.
          agentClaudeDir = "\${XDG_STATE_HOME:-$HOME/.local/state}/claude-sandboxed";

          # Identity is read from the host git config at launch — see `env` in
          # mkClaudeSandboxed — rather than mounted. Mounting it cannot be made
          # to work in general: a dotfile that home-manager links back out of
          # the store is dropped by the launcher without a word ("a symlink is
          # a name, not an access grant"), which is exactly what happens to a
          # jj config kept in a config repo. Reading the value on the host,
          # before the sandbox exists, is indifferent to how anyone's dotfiles
          # are arranged.
          gitBin = "${pkgs.git}/bin/git";

          jjBin = "${pkgs.jujutsu}/bin/jj";

          # What every sandboxed session is told about the sandbox it runs in,
          # whatever the project. Through the launcher rather than memory,
          # which is per project, or CLAUDE.md, which is the user's own and is
          # copied in from the host (see hostWrapper). Its purpose is economy,
          # not enforcement: the policy holds whatever the agent believes, but
          # an agent that does not know it spends tokens rediscovering it.
          sandboxPrompt = pkgs.writeText "agent-sandbox-prompt.md" ''
            # You are running inside a sandbox

            - **Reading is open.** GET and HEAD reach every host. Look up
              documentation, source and issues whenever it helps, without
              asking first.
            - **One POST is allowed: git's fetch.** `git clone`/`fetch` over
              HTTPS POSTs to `…/git-upload-pack`, and the proxy lets exactly
              that through on any host (path *and* git's content type). Every
              other POST, PUT, PATCH or DELETE is refused, git push
              (`…/git-receive-pack`) included.
            - **Never try to change anything outside the sandbox.** No pushes,
              no issues, comments or pull requests, no publishing, no form
              submissions, no API writes. The proxy refuses them anyway, so
              attempting one only burns tokens. When
              a task needs an outside change, prepare it and tell the user what
              to run.
            - **A 403 is not always the proxy.** Many sites refuse requests
              themselves (crates.io without a User-Agent, a storage bucket
              asked for a listing). The proxy's refusal is bare: `403`,
              `Content-Length: 0`, no `Server` header, no body. Anything else
              came from the site. Check with `curl -D -` before concluding the
              sandbox blocked it.
            - **Nix is available.** You have the host Nix daemon and store, and
              any tool missing from PATH is one `nix shell nixpkgs#<pkg> -c
              <cmd>` away (`nixpkgs` is pinned locally; `nixpkgs-unstable` also
              resolves). Try that before concluding a tool is unavailable or
              working around its absence.
          '';

          # Everything the host must work out before the sandbox exists.
          #
          # Identity. An absent identity would otherwise be handed over as the
          # empty string, which jj takes in silence and every remote later
          # refuses. Fail at launch instead. A wrapper rather than a check
          # inside the env expressions: the launcher evaluates those as
          # `printf '%s' <expr>`, whose exit status is printf's, so a failing
          # `git config` inside a command substitution is swallowed and the
          # empty value sails through.
          #
          # The jj repository. Launched from a subdirectory of a work tree,
          # agent-sandbox binds the work tree root read-only and gives .git
          # back read-write, but knows nothing of .jj, so jj cannot record a
          # single operation. The root bind comes before every declared one,
          # so a rwDirs entry for the root's .jj layers over it; a declared
          # path expands variables but runs no commands, hence AGENT_JJ_DIR.
          #
          # Only where agent-sandbox exposes the work tree root: a colocated
          # repo whose root is git's too, and not the home directory or above
          # it, which agent-sandbox refuses to expose. Anywhere else the agent
          # would see .jj but not the files around the launch directory, and
          # its first snapshot would record them all as deleted. A declared
          # path that does not exist refuses the launch, so the fallback is
          # the launch directory, which is bound read-write already.
          hostWrapper = sandbox:
            pkgs.writeShellScriptBin "claude-sandboxed" ''
              name=$(${gitBin} config user.name  || true)
              mail=$(${gitBin} config user.email || true)
              if [ -z "$name" ] || [ -z "$mail" ]; then
                {
                  echo "claude-sandboxed: no git identity configured on this host."
                  echo
                  echo "  The sandbox gives the agent both its git and its jj identity from"
                  echo "  here, so commits made inside would carry the empty identity: they"
                  echo "  look ordinary in the log, and every remote refuses them."
                  echo
                  echo "    git config --global user.name  'Your Name'"
                  echo "    git config --global user.email 'you@example.com'"
                } >&2
                exit 1
              fi

              AGENT_JJ_DIR=$PWD
              if root=$(${jjBin} root --ignore-working-copy 2>/dev/null) \
                 && [ -e "$root/.git" ] \
                 && [ "$(${gitBin} rev-parse --show-toplevel 2>/dev/null)" = "$root" ]
              then
                case "$HOME/" in
                  "$root"/*) ;;
                  *) AGENT_JJ_DIR=$root/.jj ;;
                esac
              fi
              export AGENT_JJ_DIR

              # See agentClaudeDir. Created here because a declared path absent
              # on the host refuses the launch.
              AGENT_CLAUDE_DIR=${agentClaudeDir}
              mkdir -p -m 700 "$AGENT_CLAUDE_DIR"
              export AGENT_CLAUDE_DIR

              # The host's personal CLAUDE.md applies in the sandbox too, one
              # way: copied afresh at every launch, so edits made inside do not
              # stick. Removed first, because the sandbox can write this
              # directory: a symlink planted in its place would otherwise turn
              # the copy into a host write wherever it points.
              hostMemory=''${CLAUDE_CONFIG_DIR:-$HOME/.claude}/CLAUDE.md
              rm -rf -- "$AGENT_CLAUDE_DIR/CLAUDE.md"
              if [ -f "$hostMemory" ]; then
                cp -- "$hostMemory" "$AGENT_CLAUDE_DIR/CLAUDE.md"
              fi

              exec ${sandbox}/bin/claude-sandboxed \
                --append-system-prompt-file ${sandboxPrompt} "$@"
            '';

          mkClaudeSandboxed =
            { packages     ? [ ]    # on the sandbox PATH, beside sbx.commonTools
            , domains      ? { }    # merged over baselineDomains
            , unrestricted ? false  # every method everywhere; see baselineDomains
            }:
            hostWrapper (sbx.mkSandbox {
              pkg              = claudeCode;
              binName          = "claude";
              outName          = "claude-sandboxed";
              allowedPackages  = baselineTools ++ packages;
              # The agent must test in exactly the environment humans test in:
              # give it the host Nix daemon and store so it can run
              # `nix develop -c ...`.
              allowNix         = true;
              allowUnixSockets = true;   # required by allowNix (daemon socket)
              rwDirs = [
                "$AGENT_CLAUDE_DIR"       # see agentClaudeDir above
                "$HOME/.cache/nix"       # nix client state; without these every
                "$HOME/.config/nix"       # launch re-fetches the flake registry
                "$HOME/.local/share/nix"
                "$AGENT_JJ_DIR"           # see hostWrapper above
              ];
              # No identity files here: identity arrives through `env` below.
              # Mounting it was both fragile and hostile to anyone else — a
              # declared path absent on the host refuses the launch, so the
              # previous "$HOME/.config/git/config" entry quietly required
              # every user of this flake to keep git config at exactly that
              # path, and the jj entry beside it never bound at all.
              roFiles = [
                "/etc/nix/nix.conf"             # inherit host nix config (flakes, caches)
              ];
              env = {
                CLAUDE_CONFIG_DIR = "$AGENT_CLAUDE_DIR";                 # see agentClaudeDir above
                # Overrides this one setting; /etc/nix/nix.conf, bound in
                # roFiles, still supplies the rest.
                NIX_CONFIG        = "flake-registry = ${flakeRegistry}"; # see flakeRegistry above

                # Identity, read from the host git config as the sandbox
                # launches; hostWrapper has already refused the launch if
                # either is empty.
                #
                # Do not add quotes of your own. Each value is evaluated as
                # `printf '%s' <expr>`, which would word-split a bare
                # substitution and render "Ada Lovelace" as "AdaLovelace" —
                # but the generated env file already emits every value as a
                # quoted string, so the splitting cannot happen, and an extra
                # pair lands *inside* the value as literal `"` characters.
                #
                # jj does not read git's config, so it must be told separately.
                JJ_USER            = "$(${gitBin} config user.name)";
                JJ_EMAIL           = "$(${gitBin} config user.email)";

                # GIT_CONFIG_* rather than GIT_AUTHOR_*: this form is visible
                # to `git config`, so anything that reads identity that way
                # sees it too, and it covers committer as well as author.
                GIT_CONFIG_COUNT   = "2";
                GIT_CONFIG_KEY_0   = "user.name";
                GIT_CONFIG_VALUE_0 = "$(${gitBin} config user.name)";
                GIT_CONFIG_KEY_1   = "user.email";
                GIT_CONFIG_VALUE_1 = "$(${gitBin} config user.email)";
              };
              allowedDomains = if unrestricted
                               then { "*" = "*"; }
                               else baselineDomains // domains;
            });

          loginHint = ''
            if [ -f "${agentClaudeDir}/.credentials.json" ]
            then echo "Run: claude-sandboxed --dangerously-skip-permissions"
            else echo "Not logged in. Run: claude-sandboxed --dangerously-skip-permissions, then /login inside it (once)"
            fi
          '';

          # A dev shell holding the sandboxed agent and the same packages on
          # the host side.
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
              ];
              shellHook = loginHint + (shell.shellHook or "");
            } // builtins.removeAttrs shell [ "shellHook" ]);
        in
          {
            lib = { inherit mkClaudeSandboxed mkAgentShell; };

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

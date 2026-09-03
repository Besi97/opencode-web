# Environment

You are running inside the OpenCode web container (opencode-web).

## Container details

- **Base image:** `node:trixie-slim` (Debian Trixie)
- **User:** `node` (UID 1000, non-root)
- **Working directory:** `/home/node`
- **Projects directory:** `/home/node/projects` (mounted volume)
- **Config directory:** `/home/node/.config/opencode` (mounted volume, plus read-only files from the compose repo)

## Available tools

Pre-installed in the container:

- **Docker CLI** (`docker-ce-cli`) — connects to a Docker daemon via `DOCKER_HOST` (a `docker:dind` sidecar when the `dind` profile is enabled).
- **Git** — with credential helpers configured at startup when tokens are present.
- **Homebrew** (`/home/linuxbrew/.linuxbrew`) — package manager for additional tools.
- **opencode** — the CLI tool itself (installed via Homebrew).
- **OpenTofu** (`tofu`) — infrastructure-as-code tool.
- **GitHub CLI** (`gh`) — for GitHub interactions.
- **Forgejo CLI** (`fj`) — for Forgejo interactions.
- **kubectl**, **sops**, **age**, **jq**, **yq**
- **Java** (OpenJDK 21) — available via `java`/`javac`.
- **Standard build tools** — `gcc`, `g++`, `make`, etc.
- **curl, file, procps, sudo** — common utilities.

## Environment variables

Secrets and tokens are provided via environment variables (`GITHUB_TOKEN`, and optionally `FORGEJO_TOKEN`, `STITCH_API_KEY`, etc.). Do not hardcode or echo these values.

## Git and pushing

The entrypoint configures `gh auth setup-git` when `GITHUB_TOKEN` is set, and a credential helper for a Forgejo instance when `FORGEJO_TOKEN`, `FORGEJO_URL`, and `FORGEJO_USER` are set. For private repositories, use `gh` or `fj` to handle authentication and push.

## MCP servers

- **Stitch** (optional) — Google Stitch AI UI design tool, connected via remote MCP (`https://stitch.googleapis.com/mcp`), authenticated with `STITCH_API_KEY`. Disabled by default; set `STITCH_API_KEY` and flip `enabled` in `opencode.jsonc`.

## Skills and agents

Drop skills into `./skills/` and agent definitions into `./agents/` in the compose repo (mounted read-only at `~/.config/opencode/skills` and `~/.config/opencode/agents`). Any sync mechanism you like (git submodule, deploy-time fetch script, manual copies) works — the container only needs the files present at startup.

## Installing additional tools

If a task requires a tool that is not pre-installed, you **can install it** using:

- `brew install <package>` (Homebrew)
- `apt-get install <package>` (Debian packages, requires `sudo`)
- `npm install -g <package>` (Node.js packages)

**Important:** Installed tools live in the container filesystem and are lost when the container is recreated. Add them to the Dockerfile and rebuild for persistence.

# opencode-web

A containerized [OpenCode](https://opencode.ai) web server: `node:trixie-slim` plus a curated toolchain (Homebrew, Docker CLI, Git, OpenTofu, `gh`, `fj`, `kubectl`, `sops`, `age`, Java, build tools), running `opencode web` as a non-root user.

Built for self-hosters who want a persistent, browser-accessible OpenCode environment with the tooling an agent needs to do real infrastructure work.

## Quick start

```bash
git clone https://github.com/Besi97/opencode-web
cd opencode-web
cp .env.example .env   # set GITHUB_TOKEN (and anything else you use)
docker compose --profile dind up -d
```

Open http://127.0.0.1:4096.

> **Security:** the OpenCode web UI has **no authentication**. The default compose binds it to `127.0.0.1` only. To reach it remotely, put it behind an authenticating reverse proxy (or VPN) — do not expose the port directly.

## What you get

| Path | Purpose |
|------|---------|
| `/home/node/projects` | Your repos / working files (volume, see below) |
| `/home/node/.config/opencode` | OpenCode config (volume + read-only mounts from this repo) |
| `./opencode.jsonc` | Global OpenCode config, mounted read-only |
| `./instructions/*.md` | Global agent instructions, mounted read-only |
| `./agents/`, `./skills/` | Your custom agents and skills, mounted read-only |

State defaults to named volumes (`opencode-projects`, `-config`, `-share`, `-cache`). To keep projects in a host directory instead:

```bash
mkdir -p projects && sudo chown 1000:1000 projects
echo 'OPENCODE_PROJECTS_VOLUME=./projects' >> .env
```

## Git authentication

The entrypoint configures credentials automatically at startup:

- `GITHUB_TOKEN` set → runs `gh auth setup-git` (git push/pull against GitHub works out of the box)
- `FORGEJO_TOKEN` + `FORGEJO_URL` + `FORGEJO_USER` set → configures the `fj` CLI and a git credential helper for that host

Set `GIT_AUTHOR_NAME`/`GIT_AUTHOR_EMAIL` (and committer equivalents) so agent commits are attributed correctly.

## Docker-in-Docker

The container ships the Docker CLI but no daemon. Two options:

1. **Sidecar (default):** run with `--profile dind` — a `docker:dind` service is reachable at `tcp://docker-in-docker:2375` (unencrypted; it stays on the compose network).
2. **Mounted socket:** set `DOCKER_HOST=` (empty) in `.env` and add a volume for your host socket.

## Skills and agents

This repo intentionally ships `agents/` and `skills/` empty. Put your own content there (any layout OpenCode accepts), or sync it from wherever you manage it — a git submodule, a CI/deploy-time fetch step, manual copies. The container reads them at startup; it does not care how they got there.

## Optional: Google Stitch MCP

`opencode.jsonc` includes a disabled remote MCP entry for [Stitch](https://stitch.withgoogle.com). Set `STITCH_API_KEY` in `.env` and flip `"enabled": true` to activate it.

## Configuration reference

All variables are documented in [.env.example](.env.example).

## Image

Published to `ghcr.io/besi97/opencode-web` (public, no login needed). **Tags mirror the bundled OpenCode version:**

| Tag | Meaning |
|-----|---------|
| `1.18.27` | Built with OpenCode 1.18.27 (published automatically when the pin lands on `main`) |
| `v1.18.27` | Same, with `v` prefix |
| `latest` | Tip of `main` |
| `sha-<full-commit>` | Immutable per-commit build |
| `1.18.27-1` | Toolchain rebuild of the same OpenCode version (push a `v1.18.27-1` git tag) |

Multi-arch: `linux/amd64`, `linux/arm64` (arm64 is best-effort via emulation).

## Versions & updates

The OpenCode version is **pinned in the Dockerfile** (`ARG OPENCODE_VERSION`), so builds are reproducible and every image tag truthfully names what is inside:

```bash
docker run --rm ghcr.io/besi97/opencode-web:latest --version   # prints the pinned version
cat /etc/opencode-web-versions                                  # inside the container
# or: docker inspect → label dev.opencode-web.opencode-version
```

Keeping things current:

- **OpenCode** — update PRs bump the pinned ARG; merging to `main` publishes the new `:<version>` tag automatically (the workflow creates the matching git release tag).
- **Base image (`node:trixie-slim`) and CI actions** — Dependabot.
- **Other brew tools** (`gh`, `kubectl`, `sops`, ...) — resolved by Homebrew at build time; `latest` tracks them, version tags do not promise anything about them.

Build locally:

```bash
docker build -t opencode-web .
```

## Repo layout

```
Dockerfile                      # image definition
entrypoint.sh                   # git auth setup, then exec opencode
forgejo-credential-helper.sh    # git credential helper (env-var driven)
docker-compose.yaml             # reference deployment
opencode.jsonc                  # default global config (mounted read-only)
instructions/                   # global agent instructions (mounted read-only)
agents/  skills/                # your customizations (mounted read-only)
.github/dependabot.yml          # base image + CI action updates
.github/workflows/build.yml     # PR smoke build (never pushes)
.github/workflows/publish.yml   # build + push to ghcr.io, version-mirrored tags
```

## License

MIT

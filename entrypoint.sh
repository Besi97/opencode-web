#!/bin/sh
set -e

# Configure GitHub git credential helper (reads GITHUB_TOKEN automatically)
if [ -n "$GITHUB_TOKEN" ]; then
    gh auth setup-git
fi

# Configure Forgejo CLI auth
if [ -n "$FORGEJO_TOKEN" ] && [ -n "$FORGEJO_URL" ] && [ -n "$FORGEJO_USER" ]; then
    echo "$FORGEJO_TOKEN" | fj --host "$FORGEJO_URL" auth add-key "$FORGEJO_USER"
fi

# Configure git credential helper for Forgejo
if [ -n "$FORGEJO_TOKEN" ] && [ -n "$FORGEJO_URL" ] && [ -n "$FORGEJO_USER" ]; then
    git config --global credential."https://${FORGEJO_URL}".helper /home/node/.config/forgejo-credential-helper.sh
fi

exec opencode "$@"

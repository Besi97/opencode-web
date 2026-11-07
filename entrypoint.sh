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

# Optional GPG commit signing. Expects a passphrase-less key mounted at
# GPG_SIGNING_KEY_PATH: nothing can prompt for a passphrase here, and ~/.gnupg
# is not a volume, so the import runs on every start (re-import is a no-op).
if [ -n "$GPG_SIGNING_KEY_PATH" ]; then
    if [ ! -r "$GPG_SIGNING_KEY_PATH" ]; then
        echo "WARNING: GPG_SIGNING_KEY_PATH is set but $GPG_SIGNING_KEY_PATH is not readable, committing unsigned" >&2
    elif gpg --batch --import "$GPG_SIGNING_KEY_PATH"; then
        GPG_KEY_ID="$(gpg --batch --with-colons --list-secret-keys | awk -F: '$1=="fpr"{print $10; exit}')"
        if [ -n "$GPG_KEY_ID" ]; then
            git config --global user.signingkey "$GPG_KEY_ID"
            git config --global commit.gpgsign true
            echo "Commit signing enabled with GPG key $GPG_KEY_ID"
        else
            echo "WARNING: no secret key found in $GPG_SIGNING_KEY_PATH, committing unsigned" >&2
        fi
    else
        echo "WARNING: could not import $GPG_SIGNING_KEY_PATH, committing unsigned" >&2
    fi
fi

exec opencode "$@"

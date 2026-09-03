#!/bin/sh
# Git credential helper for Forgejo instances
# Reads credentials from environment variables at runtime

while IFS= read -r line; do
    case "$line" in
        protocol=*) protocol="${line#protocol=}" ;;
        host=*) host="${line#host=}" ;;
    esac
done

if [ "$host" = "$FORGEJO_URL" ] && [ -n "$FORGEJO_TOKEN" ] && [ -n "$FORGEJO_USER" ]; then
    echo "username=$FORGEJO_USER"
    echo "password=$FORGEJO_TOKEN"
fi

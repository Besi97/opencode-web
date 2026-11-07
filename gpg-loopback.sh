#!/bin/sh
# git's gpg.program when GPG_SIGNING_KEY_PASSPHRASE is set. gpg cannot prompt for a
# passphrase inside the container, and passing it on argv would expose it to every
# process here through /proc/<pid>/cmdline, so hand it over on a private fd instead -
# the heredoc is a pipe, so nothing lands on disk. git feeds the commit payload on
# stdin (fd 0), which stays untouched.
#
# The unquoted delimiter expands $GPG_SIGNING_KEY_PASSPHRASE once per call and the
# value is not re-scanned, so $, backticks and ! in a passphrase survive intact.

exec gpg --batch --pinentry-mode loopback --passphrase-fd 3 "$@" 3<<GPGPW
$GPG_SIGNING_KEY_PASSPHRASE
GPGPW

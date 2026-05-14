#!/usr/bin/env bash
# Extract a single version's block from CHANGELOG.md.
# Usage:  scripts/extract_changelog.sh 0.7.5
# Output: the markdown body for that version (no header), ready to feed to
#         `git tag -a vX.Y.Z -F -` or to a Discord webhook embed.
#
# Looks for `## [X.Y.Z]` (with or without date suffix) and prints everything
# until the next `## [` line.

set -euo pipefail
ver="${1:-}"
if [ -z "$ver" ]; then
    echo "usage: $0 <version>" >&2
    exit 2
fi

awk -v ver="$ver" '
    /^## \[/ {
        if (match($0, /\[([^]]+)\]/, m) && m[1] == ver) { capture = 1; next }
        if (capture) exit
    }
    capture { print }
' CHANGELOG.md

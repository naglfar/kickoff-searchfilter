#!/bin/sh
# SPDX-FileCopyrightText: 2026 naglfar <tutal33t@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Imports Kickoff from a plasma-desktop checkout as a new commit on the upstream branch.
# Merge that branch into main afterwards; see README.md.
#
# Usage: ./update-upstream.sh <tag or ref, e.g. v6.9.0> [plasma-desktop checkout]
set -eu

ref=${1:?usage: $0 <tag or ref> [plasma-desktop checkout]}
src=${2:-$HOME/kde/src/plasma-desktop}
top=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
commit=$(git -C "$src" rev-parse --short "$ref^{commit}")

# Work in a separate worktree, so the checkout of main stays untouched
work=$(mktemp -d)
export_dir=$(mktemp -d)
cleanup() {
    git -C "$top" worktree remove --force "$work" 2>/dev/null || true
    rm -rf "$export_dir"
}
trap cleanup EXIT

git -C "$top" worktree add -q "$work" upstream
git -C "$src" archive "$ref" applets/kickoff | tar -x -C "$export_dir"
python3 -I "$top/tools/convert-kickoff.py" "$export_dir/applets/kickoff" "$work/package"

git -C "$work" add -A package
if git -C "$work" diff --cached --quiet; then
    echo "upstream already matches $ref ($commit)"
    exit 0
fi
git -C "$work" commit -q -m "Import Kickoff from plasma-desktop $ref ($commit)

Unmodified applets/kickoff, converted by tools/convert-kickoff.py into the
package layout."
git -C "$top" log -1 --format='%h %s' upstream

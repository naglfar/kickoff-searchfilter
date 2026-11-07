#!/bin/sh
# SPDX-FileCopyrightText: 2026 naglfar <tutal33t@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Builds the .plasmoid and creates a draft GitHub release v<version> for the current commit,
# with the .plasmoid attached and notes generated from the commits. Publish the draft on GitHub.
set -eu
cd "$(dirname "$0")"

version=$(python3 -c 'import json; print(json.load(open("package/metadata.json"))["KPlugin"]["Version"])')
tag="v$version"

if [ -n "$(git status --porcelain)" ]; then
    echo "Uncommitted changes; commit them first" >&2
    exit 1
fi

# The release points at this commit, so GitHub must already have it
git fetch -q origin
head=$(git rev-parse HEAD)
if [ "$head" != "$(git rev-parse '@{upstream}')" ]; then
    echo "HEAD differs from $(git rev-parse --abbrev-ref '@{upstream}'); push or pull first" >&2
    exit 1
fi

if git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null; then
    echo "$tag exists already; raise Version in package/metadata.json" >&2
    exit 1
fi

plasmoid=$(./build.sh)

# build.sh compiles the translations; a change here means the committed .mo files are outdated
if [ -n "$(git status --porcelain)" ]; then
    echo "Building changed tracked files; commit them and run again:" >&2
    git status --short >&2
    exit 1
fi

gh release create "$tag" "$plasmoid" --draft --generate-notes --target "$head" --title "$version"

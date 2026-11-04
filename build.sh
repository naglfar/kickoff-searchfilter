#!/bin/sh
# SPDX-FileCopyrightText: 2026 naglfar <tutal33t@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Compiles the translations and packs package/ into dist/<id>-<version>.plasmoid for the KDE Store.
set -eu
cd "$(dirname "$0")"

id=$(python3 -c 'import json; print(json.load(open("package/metadata.json"))["KPlugin"]["Id"])')
version=$(python3 -c 'import json; print(json.load(open("package/metadata.json"))["KPlugin"]["Version"])')

for po in po/*.po; do
    lang=$(basename "$po" .po)
    mkdir -p "package/contents/locale/$lang/LC_MESSAGES"
    msgfmt --check -o "package/contents/locale/$lang/LC_MESSAGES/plasma_applet_$id.mo" "$po"
done

mkdir -p dist
out="dist/$id-$version.plasmoid"
rm -f "$out"
# A .plasmoid is a zip archive with metadata.json at the top level
python3 -I - "$out" <<'PY'
import os, sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED) as archive:
    for root, _, files in os.walk("package"):
        for name in sorted(files):
            path = os.path.join(root, name)
            archive.write(path, os.path.relpath(path, "package"))
PY
echo "$out"

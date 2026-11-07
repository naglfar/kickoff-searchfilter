# SPDX-FileCopyrightText: 2026 naglfar <tutal33t@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later
"""
Turns applets/kickoff from plasma-desktop into the layout of an applet package.

Only mechanical changes, so that every import on the upstream branch can be
reproduced and merged into main:
- QML and code/ go to contents/ui/, main.xml and config.qml to contents/config/
- i18n*() calls use Kickoff's installed catalog through i18nd*(); JavaScript
  libraries (.pragma library) can't call i18n*() themselves and get i18n passed
  in, so that argument is bound to the catalog instead
- a qmldir lists the types, which the compiled original registers in CMake

Usage: convert-kickoff.py <applets/kickoff directory> <package directory>
"""

import json
import os
import re
import shutil
import sys

DOMAIN = "plasma_applet_org.kde.plasma.kickoff"
I18N_CALL = re.compile(r"\bi18n(c|p|cp)?\(")
I18ND = {"": "i18nd(", "c": "i18ndc(", "p": "i18ndp(", "cp": "i18ndcp("}
# i18n passed as a function argument, e.g. Tools.createFavoriteActions(i18n, ...)
I18N_ARGUMENT = re.compile(r"\bi18n(?=\s*,)")


def singletons(cmake):
    # set_source_files_properties(KickoffSingleton.qml ActionMenu.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
    names = set()
    for match in re.finditer(r"set_source_files_properties\(([^)]*)\)", cmake):
        parts = match.group(1).split()
        if "QT_QML_SINGLETON_TYPE" in parts and "PROPERTIES" in parts:
            names.update(p[:-4] for p in parts[: parts.index("PROPERTIES")] if p.endswith(".qml"))
    return names


def main(source, package):
    ui = os.path.join(package, "contents", "ui")
    config = os.path.join(package, "contents", "config")
    # Start from scratch, so files removed upstream disappear here too
    for directory in (ui, config):
        shutil.rmtree(directory, ignore_errors=True)
        os.makedirs(directory)

    for name in sorted(os.listdir(source)):
        path = os.path.join(source, name)
        if name in ("main.xml", "config.qml"):
            shutil.copy2(path, config)
        elif name.endswith(".qml"):
            shutil.copy2(path, ui)
        elif name == "code":
            shutil.copytree(path, os.path.join(ui, "code"))
        elif name == "metadata.json":
            shutil.copy2(path, package)
        # CMakeLists.txt and Messages.sh are build files of plasma-desktop

    for root, _, files in os.walk(os.path.join(package, "contents")):
        for name in files:
            if not name.endswith((".qml", ".js")):
                continue
            path = os.path.join(root, name)
            with open(path, encoding="utf-8") as f:
                text = f.read()
            if name.endswith(".js") and ".pragma library" in text:
                # Calls here go to the i18n parameter, not to the global functions
                continue
            converted = I18N_CALL.sub(lambda m: I18ND[m.group(1) or ""] + f'"{DOMAIN}", ', text)
            converted = I18N_ARGUMENT.sub(f'(...args) => i18nd("{DOMAIN}", ...args)', converted)
            if converted != text:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(converted)

    with open(os.path.join(source, "CMakeLists.txt"), encoding="utf-8") as f:
        singleton_names = singletons(f.read())
    types = sorted(n[:-4] for n in os.listdir(ui) if n.endswith(".qml"))
    with open(os.path.join(ui, "qmldir"), "w", encoding="utf-8") as f:
        f.write("# The original applet is a compiled QML module; in a package this qmldir lists its types instead.\n")
        for name in types:
            f.write(("singleton " if name in singleton_names else "") + f"{name} 1.0 {name}.qml\n")

    # Sanity check, so a broken export doesn't end up as an import commit
    with open(os.path.join(package, "metadata.json"), encoding="utf-8") as f:
        json.load(f)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])

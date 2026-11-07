# Kickoff Custom Search

An Application Launcher for KDE Plasma 6 that can use its own selection and order of search plugins (KRunner plugins), instead of the ones configured in *System Settings → Search → Plasma Search*.

It is a fork of Kickoff, the default Application Launcher, from KDE plasma-desktop 6.8.2. Apart from the search it works like the original. This is not an official KDE widget.

## What it does

Each launcher gets a *Search* settings page:

- **Use the plugins and order from Plasma Search**: the default; the same as Kickoff.
- **Use only the selected plugins, in this order**: results of the first plugin are shown first.

KRunner, Overview and other launchers keep using the Plasma Search settings. Plugin-specific settings, such as web search keywords, stay global.

## Limitations

- **It can only restrict.** A plugin that is disabled in Plasma Search is not used, even when selected here. If *all* selected plugins are disabled there, Plasma falls back to all enabled plugins. The settings page marks plugins that are switched off in Plasma Search and warns about this case. Plugins that are off by default and were never switched won't be marked.
- **The order** is applied as the favorites of the launcher's search model, which Plasma doesn't officially offer for this. It holds in testing, including when the Plasma Search favorites change, but may break with future Plasma versions.
- It uses `org.kde.plasma.private.kicker`, a private Plasma module without API guarantees. Expect to update the fork for new Plasma versions.
- The strings taken from Kickoff use Kickoff's installed translations. Where KDE already has a string with the same meaning, the settings page uses that one from its installed catalog (Kickoff, libplasma, kcmutils, the keyboard and accessibility settings, Kirigami). The new strings are translated into German and 20 other widely used languages (cs, da, es, fi, fr, hu, it, ja, ko, nb, nl, pl, pt, pt_BR, ru, sv, tr, uk, zh_CN, zh_TW), without review by native speakers. "Not installed" is mostly taken from KDE Discover. The header of each catalog says where its translations come from; corrections are welcome.

## Compatibility

| Plasma | Status |
|---|---|
| 6.8.2 | tested on development machine and daily use |
| 6.7.4 | active testing in daily use |
| 6.6 | works on Kubuntu 26.04 (Plasma 6.6, KDE Frameworks 6.24); oldest supported version |
| 6.3 | does not work: the Kickoff code from 6.8 and the search settings need newer kicker and Kirigami APIs |

On Plasma 6.6 the separator between All Applications and the categories is hidden in grid view and when sorted alphabetically, as Kickoff 6.8 relies on `showRootSeparator` from Plasma 6.7 to keep it.

Kickoff 6.8 shows the "New!" badge of newly installed applications with `Kirigami.Badge`, which needs KDE Frameworks 6.26. The fork uses Kickoff's own badge from before Plasma 6.7 instead (`Badge.qml`), so that it also runs with older Frameworks, such as 6.24 on Kubuntu 26.04.

## Install

```bash
kpackagetool6 -t Plasma/Applet -i package
```

Update after changes:

```bash
kpackagetool6 -t Plasma/Applet -u package
```

Then restart plasmashell or log out and back in; until then plasmashell keeps using the loaded version, also after an update. After that, add *Kickoff Custom Search* to a panel, or use *Show Alternatives…* on the existing Application Launcher.

Remove:

```bash
kpackagetool6 -t Plasma/Applet -r de.naglfar.kickoff-searchfilter
```

## Build a .plasmoid for the KDE Store

```bash
./build.sh
```

## Updating to a new Kickoff version

The fork is a copy without a connection to plasma-desktop. New Kickoff versions come in through the `upstream` branch.

- **`upstream`** only contains Kickoff as released by KDE, converted mechanically into the package layout by `tools/convert-kickoff.py`. The conversion moves files, switches `i18n()` to Kickoff's installed catalog and writes the `qmldir`.
- **`main`** is `upstream` plus the changes of this fork.

Show exactly what the fork changes:

```bash
git diff upstream main -- package
```

Once per clone, enable the merge driver that keeps the fork's `metadata.json`:

```bash
git config merge.ours.driver true
```

Update to a new Plasma version, for example 6.9.0, from a plasma-desktop checkout that has the tag:

1. Import it as a commit on `upstream`. The checkout of `main` is not touched.

   ```bash
   ./update-upstream.sh v6.9.0
   ```

2. Merge it.

   ```bash
   git merge upstream -m "chore(upstream): merge Kickoff v6.9.0"
   ```

3. Resolve conflicts, if any. They can only appear where KDE changed lines that the fork changed too: the runner model block in `main.qml`, `main.xml`, `config.qml`, `qmldir`, the root model settings in `main.qml`, or the badge in `KickoffGridDelegate.qml` and `KickoffListDelegate.qml`.
4. Test against that Plasma version, raise `Version` in `metadata.json`, then run `./build.sh`.

To try an update without changing `upstream`, branch it first:

```bash
git branch try-upstream upstream
```

```bash
UPSTREAM_BRANCH=try-upstream ./update-upstream.sh v6.9.0
```

Before updating, check what changed:

- `git log <old-tag>..<new-tag> -- applets/kickoff` in plasma-desktop for Kickoff itself
- `applets/kicker/runnermodel.*` in plasma-workspace, which provides `runners`, `mergeResults` and the search model whose `favoriteIds` this fork sets

A newer Kickoff may need APIs that older Plasma versions lack. If older versions still have to work, stay on the Kickoff version of the oldest supported Plasma and take over fixes selectively, or publish a separate version per Plasma release and set `X-Plasma-API-Minimum-Version` accordingly.

### Tried once

An update from Kickoff 6.7.0 to 6.8.2 (18 upstream commits, 19 files) merged without conflicts. The result was identical to the fork on 6.8.2.

## License

GPL-2.0-or-later, like the files taken from Kickoff, some of which are LGPL-2.0-or-later. The original authors are named in the file headers.

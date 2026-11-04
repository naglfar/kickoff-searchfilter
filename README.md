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
- The strings taken from Kickoff use Kickoff's installed translations. New strings are translated into German only.

## Compatibility

| Plasma | Status |
|---|---|
| 6.8.2 | tested in an isolated session (virtual KWin, separate config) |
| 6.7 | not tested; the kicker APIs used are the same as in 6.8.2, and the Kickoff code from 6.8 uses nothing that 6.7 lacks |

## Install

```bash
kpackagetool6 -t Plasma/Applet -i package
```

Update after changes:

```bash
kpackagetool6 -t Plasma/Applet -u package
```

Then restart plasmashell or log out and back in, add *Kickoff Custom Search* to a panel, or use *Show Alternatives…* on the existing Application Launcher.

Remove:

```bash
kpackagetool6 -t Plasma/Applet -r de.naglfar.kickoff-searchfilter
```

## Build a .plasmoid for the KDE Store

```bash
./build.sh
```

## History

1. `Import Kickoff from plasma-desktop v6.8.2` is the unmodified original, only moved into the package layout.
2. `Make it a standalone applet package` changes the id, adds a qmldir and reuses Kickoff's translations.
3. Then come the search changes.

Compare with the original:

```bash
git diff 4a17665 -- package
```

## License

GPL-2.0-or-later, like the files taken from Kickoff, some of which are LGPL-2.0-or-later. The original authors are named in the file headers.

# Local changes

A clone of `omarchy.bar`, taken from Omarchy's `shell/plugins/bar` at version
1.0.0. `widgets/` and `indicators/` were dropped: the catalog only reads
`manifest.json` one level down inside a user plugin, so those copies were never
discovered and the built-in widgets keep loading from `$OMARCHY_PATH`.

One behavioural change, in `Bar.qml`:

- `CenterGestureArea.onDoubleClicked` no longer calls `toggleTransparency()`.
  It swallows the double click instead. Transparency is still settable through
  `bar.transparent` in `~/.config/omarchy/shell.json`.

## Resyncing after an Omarchy update

```bash
diff -u /usr/share/omarchy/shell/plugins/bar/Bar.qml Bar.qml
diff -u /usr/share/omarchy/shell/plugins/bar/BarModel.js BarModel.js
```

Take upstream's version of everything except the `onDoubleClicked` handler. If
Omarchy ever grows a config key for the gesture, delete this whole clone and
`omarchy plugin enable omarchy.bar`.

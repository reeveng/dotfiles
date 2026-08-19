# Local changes

A clone of `omarchy.bar`, taken from Omarchy's `shell/plugins/bar` at version
1.0.0. `widgets/` and `indicators/` were dropped: the catalog only reads
`manifest.json` one level down inside a user plugin, so those copies were never
discovered and the built-in widgets keep loading from `$OMARCHY_PATH`.

Two behavioural changes, both in `Bar.qml`, both in `CenterGestureArea`:

- `onDoubleClicked` no longer calls `toggleTransparency()`. It swallows the
  double click instead. Transparency is still settable through
  `bar.transparent` in `~/.config/omarchy/shell.json`.
- `startDrag()` is empty, so a press-and-hold or a drag on the bar no longer
  begins a bar move. Upstream drops the bar on whichever screen edge the
  pointer is nearest, which happens by accident. The edge stays where
  `bar.position` puts it.

## Resyncing after an Omarchy update

```bash
diff -u /usr/share/omarchy/shell/plugins/bar/Bar.qml Bar.qml
diff -u /usr/share/omarchy/shell/plugins/bar/BarModel.js BarModel.js
```

Take upstream's version of everything except `onDoubleClicked` and
`startDrag`. If Omarchy ever grows config keys for both gestures, delete this
whole clone and `omarchy plugin enable omarchy.bar`.

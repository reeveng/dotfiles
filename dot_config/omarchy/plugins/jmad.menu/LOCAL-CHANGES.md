# Local changes

A clone of `omarchy.menu`, taken from Omarchy's `shell/plugins/menu` at version
1.0.0. Everything upstream does, plus a search that reads the tree the way a
person says it out loud.

Upstream already searches the whole subtree below wherever you are. What it
matches on is the row's own label, the last word of its id, and its aliases,
which means the menu a row sits in is not part of what the row is called:

- `install package` asks for a row labelled both words, and there is none.
- `install` answers with the Install menu and nothing inside it.
- `ins p` answers with nothing at all.

## Two changes, both about search

`MenuModel.js`, `matchesQuery` and a new `pathSearchText`: the path down to a
row joins its label and aliases as text a query may land on. Each word of a
query may match any part of that, so `install package` is the path spoken
aloud, `install` is everything under Install, and `ins p` is the same query
typed by somebody in a hurry. `Menu.qml` passes `parentPathFor(entry.id)` into
`matchesQuery` to make that possible, and `searchScore` computes it again for
itself.

`MenuModel.js`, `searchScore` and a new `needleScore`: how a row ranks. Two
things changed.

- A query of several words is scored on its last word when the whole of it
  lands nowhere, because no row is labelled `install package` and the word
  being aimed at is `package`. The earlier words have already done their work
  narrowing the list.
- Depth now outranks kind. Upstream weighs the match tier at 1000, kind at the
  same 1000, and depth at 25, so a submenu three levels down comes above the
  plain action a level up purely for being a submenu: `ins p` put
  Install › Development › PHP above Install › Package. The places are now
  100000 for the tier, 10000 for depth, 1000 for kind and the row's own order
  below that, each wide enough that the one under it can never reach up into
  it. A shallow row reads as the general answer and the general answer is
  nearly always the one being asked for.

## Resyncing after an Omarchy update

```bash
diff -u /usr/share/omarchy/shell/plugins/menu/MenuModel.js MenuModel.js
diff -u /usr/share/omarchy/shell/plugins/menu/Menu.qml Menu.qml
```

Take upstream's version of everything except `matchesQuery`, `pathSearchText`,
`needleScore`, `searchScore`, and the one call site in `Menu.qml`. Both changes
are worth offering upstream; if either lands, drop it from here, and if both
do, delete this clone and `omarchy plugin enable omarchy.menu`.

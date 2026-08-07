# Putting the flat menu on another machine

Omarchy's menu is a tree. You press `Super+Space`, pick a section, pick a
subsection, and eventually reach the thing you wanted. Searching only ever
searches the level you are standing on, so you have to know where a thing lives
before you can find it.

This extension keeps that tree and puts every action in it underneath, each
labelled with the path that leads to it. Typing "package" finds
`Install › Package` and `Remove › Package` together. Typing "sound" finds
`Setup › Audio`, which contains neither of those words, because the descriptions
are searched too.

It needs no patching of Omarchy and no keybinding. Omarchy has a hook for this.

## Before you start

Omarchy, obviously. This was written against **3.8.4**; check yours with
`omarchy version`, and read the caveat at the bottom if it is much newer.

Beyond that, `python3` and `walker`, both of which Omarchy already installs.
Nothing else.

## Step 1: copy the files in

Three files go into `~/.config/omarchy/extensions/`:

```bash
mkdir -p ~/.config/omarchy/extensions
cd ~/.config/omarchy/extensions

curl -O https://raw.githubusercontent.com/reeveng/dotfiles/main/dot_config/omarchy/extensions/menu.sh
curl -O https://raw.githubusercontent.com/reeveng/dotfiles/main/dot_config/omarchy/extensions/menu-index.py
curl -O https://raw.githubusercontent.com/reeveng/dotfiles/main/dot_config/omarchy/extensions/menu-hints.tsv
```

They do different jobs. `menu.sh` is the part Omarchy loads. `menu-index.py`
reads Omarchy's own menu and works out what is in it. `menu-hints.tsv` is prose,
one line per entry, saying what each one does in words somebody new would use.

Nothing needs to be executable; both are invoked through their interpreter.

## Step 2: there is no step 2

Omarchy sources the extension by itself. The last lines of
`~/.local/share/omarchy/bin/omarchy-menu` are:

```bash
# Allow user extensions and overrides
USER_EXTENSIONS="$HOME/.config/omarchy/extensions/menu.sh"
[[ -f $USER_EXTENSIONS ]] && source "$USER_EXTENSIONS"
```

That is upstream Omarchy, not a local patch, which is what makes this safe
against `omarchy update`. The file is sourced after Omarchy has defined its own
menu functions, so the extension can redefine `show_main_menu` and still call
the original.

Do not add a keybinding. `Super+Space` already runs `omarchy-menu`.

## Step 3: open it

Press `Super+Space`.

The first open is slower than the rest, because the index is being built. After
that it is read from cache.

You should see Omarchy's ten sections at the top, then a row that says
`Descriptions: off`, then every action in the tree. If you see only the ten
sections, the extension did not load; go to troubleshooting.

## How the index stays honest

The index lives at `~/.cache/omarchy/menu-index.tsv` and is rebuilt whenever any
of its three inputs is newer than it:

```bash
~/.local/share/omarchy/bin/omarchy-menu           # Omarchy's own menu
~/.config/omarchy/extensions/menu-index.py        # the builder
~/.config/omarchy/extensions/menu-hints.tsv       # the descriptions
```

So `omarchy update` rewrites the menu, the timestamp moves, and the next
`Super+Space` reindexes without being asked. You never rebuild it by hand. If you
want to anyway:

```bash
rm ~/.cache/omarchy/menu-index.tsv
```

To see what it produced, which is the fastest way to understand the whole thing:

```bash
python3 ~/.config/omarchy/extensions/menu-index.py build \
  ~/.local/share/omarchy/bin/omarchy-menu | head
```

Each row is `display`, `function`, `option`, `description`, tab separated.
`function` is the Omarchy menu function that owns the choice and `option` is the
string its `case` matches. Running an entry means calling that function with
`menu` stubbed to answer `option`, which is how a deep action runs without you
walking to it. Back out of an action and you land on the menu it belongs to,
because later questions are handed back to the real menu.

## The descriptions row

Actions are listed without their descriptions by default. That is deliberate.
Walker matches against everything it displays, so a sentence on every row means a
search for "set" hits every row containing the word "settings". The list is for
finding, and prose gets in the way of finding.

The `Descriptions: off` row turns them on when you would rather read than
search. The choice is remembered in
`~/.local/state/omarchy/menu/descriptions-on`, and the menu widens to fit.

## Making the descriptions yours

`menu-hints.tsv` is a path, a tab, and a description:

```
Setup › Audio	Sound settings, speakers, microphone, volume
```

The path carries no icon. Add the everyday words you would actually type,
because the whole line is searched: putting "print screen" on the screenshot row
is how someone finds it without knowing Omarchy calls it "capture".

Entries you say nothing about still get a description, taken from the path for
the repetitive families, and otherwise from the `omarchy:summary=` line of the
command the entry runs. You only need to write a hint where those guesses read
badly.

Edit the file and the index rebuilds on next open.

## One thing you may not want

`menu.sh` also redefines `show_setup_default_browser_menu`. Omarchy's browser
list is written by hand and LibreWolf is not on it, so the override adds it. If
you do not use LibreWolf, delete that function from the top of `menu.sh`. It is
independent of the flat menu and nothing else refers to it.

## When it misbehaves

**The menu is unchanged.** The extension did not load. Check the path is exactly
`~/.config/omarchy/extensions/menu.sh`, then run `omarchy-menu` from a terminal
and read what it says. Errors are invisible when it is launched from a keybinding.

**The tree still works but the flat list never appears.** The index failed to
build and the extension fell back on purpose, which it does silently so a broken
index can never cost you your menu. Build it by hand to see the error:

```bash
python3 ~/.config/omarchy/extensions/menu-index.py build \
  ~/.local/share/omarchy/bin/omarchy-menu | wc -l
```

Expect a couple of hundred rows. A traceback here is the real problem, and after
an Omarchy update it usually means the menu's shape changed.

**An entry opens the wrong thing.** The index matched an option string to the
wrong function, which happens when two menus offer the same label. Find the row
in `~/.cache/omarchy/menu-index.tsv` and check the `function` column.

**Rows are missing.** Menus whose entries are produced by a command rather than
written out, themes and fonts among them, are left as leaves on purpose. Their
contents are not the extension's to enumerate, so you enter those sections the
ordinary way.

## The caveat worth knowing

This reads Omarchy's menu source and calls its internal functions. That is what
lets it stay out of the way of updates, and it is also its weakness: an update
that restructures `omarchy-menu` can leave the index empty or wrong. The failure
is designed to be dull rather than dangerous. A build that produces nothing means
you get the ordinary tree menu, and you carry on.

If that happens, run the build by hand as above. What changed is usually visible
in a line or two of the traceback.

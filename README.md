# dotfiles

My [Omarchy](https://omarchy.org/) machine: Hyprland, a vertical waybar, and a
handful of small things that were missing.

```bash
chezmoi init --apply reeveng
```

Everything below sits in `~/.config` or `~/.local/bin` and leaves Omarchy's own
files in `~/.local/share/omarchy` alone, so `omarchy update` cannot undo it.

## The bar

Waybar runs down the **right edge**, 24px wide: workspaces at the top, the clock
in the middle, the state of the machine at the bottom. Colours come from the
current Omarchy theme.

A 24px column asks for a few things most bar configs never need. Icons use the
*Mono* cut of a Nerd Font, since the proportional cut is two cells wide and sits
off centre. Multi-line modules carry `"justify": "center"`, because GTK aligns
the lines of a label left by default and the icon under a number ends up hanging
to one side. Workspace buttons are reset with `all: initial` and given a fixed
height, or GTK's own button chrome grows a border on hover and shifts the whole
column.

Omarchy's migrations edit `~/.config/waybar` in place, so
`hooks/post-update.d/keep-my-waybar` puts the bar back after an update and keeps
whatever the update wrote alongside it. Run `waybar-pin` after changing the bar
on purpose, or the next update reverts you.

## The menu

`omarchy/extensions/menu.sh` replaces the main Omarchy menu with one flat list of
every action in the tree, each labelled with its path and what it does, so
searching "package" finds `Install › Package` and `Remove › Package` at once, and
searching "sound" finds `Setup › Audio`. Opening it shows what you used lately
and the ten sections, so it still reads like a menu when you have no query.

`menu-index.py` parses the list out of Omarchy's own `bin/omarchy-menu` and
rebuilds itself whenever that file changes; descriptions come from
`menu-hints.tsv`, from the path, or from each command's own summary line. A row
at the bottom turns the descriptions off.

It works on any Omarchy machine and needs no patching, because Omarchy sources
user extensions itself. [`docs/menu.md`](docs/menu.md) is the walkthrough for
putting it on someone else's.

## Streaming

`waybar-obs` puts a dot on the bar: red while OBS is streaming, grey while OBS is
open and not, nothing when it is closed. `obs-live-watch` uses the same signal to
silence notifications and hold off the idle lock while live, and to put both back
exactly as they were when the stream ends. Neither needs obs-websocket; they read
the `==== Streaming Start ====` banners OBS writes to its own session log.

## Downloads

`yt-dlp/config` defines shorthands through yt-dlp's own `--alias`, so they are
real flags:

| | |
| --- | --- |
| `yt-dlp --video URL` | best picture and sound, into `~/Videos` |
| `yt-dlp --hd 1080 URL` | the same, capped at a height |
| `yt-dlp --audio URL` | best audio as it comes, into `~/Music` |
| `yt-dlp --flac URL` | audio converted to flac |
| `yt-dlp --music URL` | filed as `Artist/Title.opus` |
| `yt-dlp --clip 0:30 1:45 URL` | just that stretch |
| `yt-dlp --sub URL` | subtitles alongside, as srt |

Audio keeps its artwork and gets artist, album and year written in, because kew
draws the cover in the terminal.

## Odds and ends

- **Scratchpads.** `Super`+`` ` `` throws a terminal over whatever you are doing
  and takes it away again; `Super+M` does the same with kew, which keeps playing
  while it is out of sight. `hypr/scripts/scratchpad` launches what belongs in
  each one the first time you ask for it.
- **Session.** `hyprsession` saves the window layout as you work and puts it back
  at login, so a restart returns the desktop you left. It has no config file;
  see below for the whole of it.
- **Battery.** Omarchy shouts at 10%. `battery-early-warning` says something
  quieter at 20%, once per discharge, through a systemd user timer.
- **Keys.** Hyprland runs *every* binding on a key, so anything that overrides a
  stock binding is preceded by `unbind`. Without it, Super+X both toggles
  animations and sends Ctrl+X to whatever has focus.
- **cat** is `bat`, without the pager or the line numbers. `command cat` for the
  plain one.

## The logo

`omarchy/branding/screensaver.txt` is the reeven mark the screensaver shows in
place of Omarchy's own. `about.txt` beside it is still Omarchy's and is not
checked in, so an update is free to change it.

The file is cropped to its own ink, with no blank rows or columns around it, and
it has to stay that way. `tte` centres the text it is handed, but it counts
leading blank columns while stripping trailing ones, so padding on the left
pushes the logo right by half of it. This mark was transcoded from an image that
carried a margin, which left twenty five blank columns and sat the logo a good
twelve columns right of centre on every lock. Omarchy's own `about.txt` is
cropped the same way, which is the tell.

Transcoding keeps whatever margin the source image had, so after
`omarchy branding screensaver image` run `just logo` to crop it back. Running it
twice is harmless.

## The session

`hyprsession` has no config file of its own. It is configured entirely by the
flags it is started with and by when it is asked to run, which is three places:

| Where | What |
| --- | --- |
| `hypr/autostart.conf` | `exec-once = hyprsession --save-interval 120` restores the last session at login, then writes a new one every two minutes |
| `hypr/autostart.conf` | `exec-shutdown = hyprsession --mode save-and-exit` catches a clean Hyprland exit |
| `systemd/user/hyprsession-save.service` | catches the case `exec-shutdown` misses, when the machine goes down without Hyprland getting to quit |

The unit is a belt beside that brace. Hyprland only runs `exec-shutdown` when it
exits in an orderly way, so a reboot from outside the session would otherwise
lose up to two minutes of layout. The unit runs `Before=shutdown.target` with
`DefaultDependencies=no`, which puts it early enough to still see the windows.

Enabling it is usually `systemctl --user enable`, which just writes a symlink
into `shutdown.target.wants`. That symlink is checked in, so the unit arrives
enabled and no one has to remember the command. The battery timer is enabled the
same way.

State lives in `~/.local/share/hyprsession/default`: `clients.json` is what was
open, `exec.conf` is the Hyprland config generated to put it back. Neither is
checked in, since a saved desktop belongs to a machine and not to a repository.
`hyprsession list` shows saved sessions, and `hyprsession save <name>` keeps one
by name if you want a layout you can return to on purpose.

[`docs/hyprsession.md`](docs/hyprsession.md) sets all of it up step by step,
including how to prove each of the three saves actually fires.

## What has to be installed

Omarchy brings most of it. Everything past that is `packages.nix`, which is the
only place it is written down:

```bash
$EDITOR packages.nix     # add a name to a group
just packages            # compile it
chezmoi apply            # catch the machine up
```

Packages sit in groups, and `enabled` at the top picks which groups this machine
wants. Off by default are `hardware`, `printing` and `video-editing`, which
describe this desk rather than my taste: an AMD laptop's kernel and drivers, the
Brother DCP-7030, and the libraries Arch stopped shipping that DaVinci Resolve
still asks for. They stay written down so that rebuilding *this* machine is one
edit away. Another machine says which groups it wants in its own
`~/.config/chezmoi/chezmoi.toml`, which outranks the manifest:

```toml
[data.packages]
  enabled = ["browsers", "cli", "dev", "fonts", "shell"]
```

`just packages` evaluates the nix and writes `.chezmoidata/packages.json`. Both
files are committed, and the compiled one is what chezmoi actually reads. That
is what lets a bare machine install everything without nix being there first,
which matters because nix is itself in the list. Editing needs nix; installing
does not.

The installer asks pacman what is already present and fetches only the
difference, so an apply that changes nothing costs one query, and it only reruns
when the manifest changes. To make it run anyway, say `chezmoi state
delete-bucket --bucket=entryState` and apply again. Removing a name does not
remove the package; say `yay -Rns` for that.

`just drift` names anything installed by hand that neither Omarchy nor
`packages.nix` accounts for. It should print nothing.

A fresh machine, from nothing:

```bash
omarchy pkg add chezmoi          # if Omarchy has not already
chezmoi init --apply reeveng     # dotfiles and packages in one pass
```

`obs-studio` only if you want the stream indicator to ever light up. `python3` is
already there; the menu index needs it.

## What to change first

`hypr/monitors.conf` is written for a 2x display. `hypr/window-workspaces.conf`
sends my applications to my workspaces. `hypr/bindings.conf` opens my
applications. Those three are mine, not yours.

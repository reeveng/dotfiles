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
  at login, so a restart returns the desktop you left.
- **Battery.** Omarchy shouts at 10%. `battery-early-warning` says something
  quieter at 20%, once per discharge, through a systemd user timer.
- **Keys.** Hyprland runs *every* binding on a key, so anything that overrides a
  stock binding is preceded by `unbind`. Without it, Super+X both toggles
  animations and sends Ctrl+X to whatever has focus.
- **cat** is `bat`, without the pager or the line numbers. `command cat` for the
  plain one.

## What has to be installed

Omarchy brings most of it. These are extra:

```bash
omarchy pkg add hyprsession kew yt-dlp bat jq mpv wofi
```

`obs-studio` only if you want the stream indicator to ever light up. `python3` is
already there; the menu index needs it.

## What to change first

`hypr/monitors.conf` is written for a 2x display. `hypr/window-workspaces.conf`
sends my applications to my workspaces. `hypr/bindings.conf` opens my
applications. Those three are mine, not yours.

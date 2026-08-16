# Setting up hyprsession

Hyprsession remembers which windows were open, on which workspace, and puts them
back when Hyprland next starts. There is no config file. You configure it
entirely by choosing when it runs, which is three separate moments, and the third
one is the one people miss.

Everything below is already in this repo. Follow it to understand what
`chezmoi apply` did for you, or to set it up somewhere the repo is not.

## Before you start

You need Hyprland and a build of hyprsession that speaks to it. The AUR package
does not, on a Hyprland that reads a Lua config, and "Why the AUR package cannot
be used" below is the whole of that story. This machine builds a fork instead:

```bash
cd ~/Documents/projects/hyprsession
makepkg -si
```

The `PKGBUILD` in that repo carries an epoch, so `yay -Syu` leaves it alone
rather than putting the AUR build back over it. `packages.nix` still names
`hyprsession` in the `desktop` group; the installer only fetches what `pacman
-Qq` cannot find, so the local build satisfies it and nothing reaches for the
AUR.

Check it is there:

```bash
hyprsession --help | head -1
pacman -Q hyprsession            # 1:0.2.1-1, the epoch says it is the fork
```

## Step 1: restore at login, and keep saving

Put this in `~/.config/hypr/autostart.lua`, inside the `hyprland.start` handler:

```lua
hl.exec_cmd("hyprsession --save-interval 120")
```

One line does two jobs. On startup it reads the last saved session and reopens
those windows. Then it stays running and writes a fresh save every 120 seconds.

The interval is a trade. Save often and you lose less when the machine dies
badly; save rarely and you spend less time asking `hyprctl` what is open. The
default is 60. Two minutes is comfortable.

Omarchy's `hyprland.lua` reaches this file through `require("hypr.autostart")`.
An `autostart.conf` beside it is read by nobody. Hyprland picks one config
language per session and this one is Lua.

## Step 2: save when Hyprland exits cleanly

In the `hyprland.shutdown` handler of the same file:

```lua
hl.exec_cmd("hyprsession save")
```

`hyprland.shutdown` fires when Hyprland quits in an orderly way, so logging out
saves the desktop as it was at that instant rather than as it was up to two
minutes ago.

The mode is a bare word in that position. Most writing about hyprsession, this
file included until recently, spells it `--mode save-and-exit`, and that form is
worse than a typo would be. 0.2.0 moved the mode out of a flag; 0.2.1 keeps the
flag alive by checking for the string `--mode` anywhere in the arguments and, on
finding it, handing the entire run to the pre-0.2.0 code. That code predates
named sessions. It saves to `~/.local/share/hyprsession` itself rather than to
the `default` directory beneath it, and startup only ever reads `default`. So the
save runs, reports nothing wrong, and lands where nothing will look for it. Steps
2 and 3 both go quiet at once, which is what a session that half works is made
of.

## Step 3: save when nothing exits cleanly

This is the step that gets skipped, and skipping it is why sessions feel like
they half work.

`exec-shutdown` only runs when Hyprland gets the chance. Reboot from a TTY, let
systemd time out a unit, or lose power to a laptop that suspended badly, and
Hyprland never reaches its own shutdown path. Whatever the last periodic save
caught is what you get back.

Write `~/.config/systemd/user/hyprsession-save.service`:

```ini
[Unit]
Description=Save Hyprland session before shutdown
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/usr/bin/hyprsession save

[Install]
WantedBy=shutdown.target
```

Two lines in there are doing real work. `Before=shutdown.target` puts the save
ahead of the shutdown itself, and `DefaultDependencies=no` keeps systemd from
adding the ordinary ordering that would otherwise schedule this unit after the
session it is trying to photograph. Without both, it runs too late to see any
windows and saves an empty desktop over your good one.

## Step 4: enable it

```bash
systemctl --user enable hyprsession-save.service
```

All that command does is write a symlink:

```
~/.config/systemd/user/shutdown.target.wants/hyprsession-save.service
  -> ~/.config/systemd/user/hyprsession-save.service
```

Which is why this repo checks the symlink in rather than asking you to remember
the command. If you are following along by hand, run the command. If you ran
`chezmoi apply`, it is already there and enabled.

Confirm:

```bash
systemctl --user is-enabled hyprsession-save.service   # enabled
```

## Step 5: prove each path works

Three moments, three checks. Do them in order.

**The periodic save.** Open something distinctive, wait past your interval, then
look at what was written:

```bash
ls -l ~/.local/share/hyprsession/default/
grep -c exec ~/.local/share/hyprsession/default/exec.conf
```

`clients.json` is what was open. `exec.conf` is the Hyprland config generated to
put it back. A recent mtime on both means the timer is running.

**The clean exit.** Log out and back in. Your windows should return. If they do
not, the `hyprland.shutdown` handler is not firing, and the usual cause is that
`autostart.lua` is not required from `hyprland.lua`.

**The unpleasant exit.** This is the one worth testing deliberately, because it
is the one that silently does nothing:

```bash
touch ~/.local/share/hyprsession/default/clients.json   # note the time
sudo reboot
```

After logging back in, check the mtime on `clients.json`. If it is later than
your `touch` and later than the last periodic save, the unit ran. If it matches
the last periodic save instead, the unit is not enabled or not ordered early
enough.

## Named sessions

The automatic one is called `default`. You can keep others on purpose:

```bash
hyprsession save writing     # keep the current layout under a name
hyprsession list             # what has been kept
hyprsession load writing     # put it back
```

Mode first, then the name. Leaving the name off means `default`, which is why
step 2 needs no argument beyond `save`.

Useful for a layout you return to rather than one you happen to have.

## Why the AUR package cannot be used

Hyprland 0.56 kept its IPC socket and changed what one command on it means.
Under a Lua config, `dispatch <payload>` is no longer a dispatcher name followed
by arguments. Hyprland wraps the payload as `return hl.dispatch(<payload>)` and
hands it to the interpreter, so the old spelling is now a Lua syntax error:

```
$ printf 'dispatch exec foot' | socat - UNIX-CONNECT:$SOCK
error: [string "return hl.dispatch(exec foot)"]:1: ')' expected near 'foot'

 → Note: dispatch in lua is a shorthand for hl.dispatch(...), your syntax
   might need to be updated.
```

hyprsession is built on hyprland-rs, which sends exactly that old spelling.
Reading is untouched, and everything hyprsession does to save a session is
reading. So the save kept working and looked healthy while the restore had
stopped happening at all.

It fails silently because of where the error lands. The first thing a restore
does is dispatch the commands in `exec.conf`, the result is propagated with `?`,
and `main` returns it. The process is gone milliseconds after Hyprland starts
it, before one window has been launched, and with it goes the periodic save
that the same process was going to run. `pgrep hyprsession` on a fresh boot is
the fastest way to see it: nothing there, while the other things started from
the same handler are running.

There is no upstream fix to wait for. `joshurtree/hyprsession` last moved in
January 2026, and the tag the AUR builds is that same commit.

The fork replaces the dispatch calls with `eval`, which takes Lua. Programs are
launched with `hl.exec_cmd(command, rules)`, and the rule prefix already sitting
in `exec.conf` is read into the table that call wants, so saved sessions from
before the change still load. The adjustments afterwards go through `hl.dsp.*`.

It carries two other fixes, both for things that were wrong before Hyprland
changed anything.

Upstream matched a saved window to a real one by title, and a terminal rewrites
its title the moment a shell prompt appears. Two of them then match each other,
and the second window to open is dragged onto the first one's workspace. The
fork matches on the class and the title a window had when it first mapped, and
gives each saved window to one real window only.

Upstream also read `/proc/<pid>/cmdline`, replaced the NUL separators with
spaces, and split the result on whitespace again, which loses every word
boundary an argument had. A window opened as `foot -e sh -c 'sleep 900'` was
saved as `foot -e sh -c sleep 900` and came back as a different program, in that
case one that exits immediately. The fork keeps the argument vector whole and
quotes each word for the shell that will reopen it, which is a shell: Hyprland
runs what it is given through `sh -c`. So `exec.conf` now has quotes in it where
an argument needs them.

## When it misbehaves

**Windows come back on the wrong workspace.** Hyprsession records the workspace
a window was on, but window rules run at open time and can move it again. Check
`window-workspaces.conf` for a rule that outranks the restore.

**Some applications never come back.** It restores a window by rerunning the
command that made it, read from `hyprctl clients`. Anything launched by a
desktop file with a wrapper, or by a portal, may report a command that does not
relaunch it. `hyprsession command <class> "<command>"` exists for teaching it the
special cases, and writes a small script into `~/.local/bin` that runs the right
thing.

**Everything comes back twice.** Something else is also restoring the session,
usually a second `exec-once` left over from an older config. Check
`autostart.conf` and `hyprland.conf` for a duplicate.

**Nothing is saved at all.** Run `hyprsession --save-interval 5` in a terminal
and watch it. Errors that vanish under `exec-once` are visible there.

## What this repo tracks

| File | Why |
| --- | --- |
| `dot_config/hypr/autostart.lua` | Steps 1 and 2 |
| `dot_config/systemd/user/hyprsession-save.service` | Step 3 |
| `dot_config/systemd/user/shutdown.target.wants/symlink_hyprsession-save.service.tmpl` | Step 4, so nobody has to run `systemctl enable` |

The saved sessions themselves are not tracked. A desktop belongs to a machine.

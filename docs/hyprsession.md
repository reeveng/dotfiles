# Setting up hyprsession

Hyprsession remembers which windows were open, on which workspace, and puts them
back when Hyprland next starts. There is no config file. You configure it
entirely by choosing when it runs, which is three separate moments, and the third
one is the one people miss.

Everything below is already in this repo. Follow it to understand what
`chezmoi apply` did for you, or to set it up somewhere the repo is not.

## Before you start

You need Hyprland and the package:

```bash
yay -S hyprsession
```

It is AUR-only. On this repo's machines it comes from `packages.nix` in the
`desktop` group, so a `chezmoi apply` has already fetched it.

Check it is there:

```bash
hyprsession --help | head -1
```

## Step 1: restore at login, and keep saving

Put this in `~/.config/hypr/autostart.conf`:

```conf
exec-once = hyprsession --save-interval 120
```

One line does two jobs. On startup it reads the last saved session and reopens
those windows. Then it stays running and writes a fresh save every 120 seconds.

The interval is a trade. Save often and you lose less when the machine dies
badly; save rarely and you spend less time asking `hyprctl` what is open. The
default is 60. Two minutes is comfortable.

Hyprland runs `autostart.conf` only if `hyprland.conf` sources it, which
Omarchy's does by default.

## Step 2: save when Hyprland exits cleanly

Directly under it:

```conf
exec-shutdown = hyprsession --mode save-and-exit
```

`exec-shutdown` fires when Hyprland quits in an orderly way, so logging out saves
the desktop as it was at that instant rather than as it was up to two minutes
ago.

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
ExecStart=/usr/bin/hyprsession --mode save-and-exit

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
not, `exec-shutdown` is not firing, and the usual cause is that `autostart.conf`
is not sourced.

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
hyprsession --mode load writing
```

Useful for a layout you return to rather than one you happen to have.

## When it misbehaves

**Windows come back on the wrong workspace.** Hyprsession records the workspace
a window was on, but window rules run at open time and can move it again. Check
`window-workspaces.conf` for a rule that outranks the restore.

**Some applications never come back.** It restores a window by rerunning the
command that made it, read from `hyprctl clients`. Anything launched by a
desktop file with a wrapper, or by a portal, may report a command that does not
relaunch it. `hyprsession --mode command` exists for teaching it the special
cases.

**Everything comes back twice.** Something else is also restoring the session,
usually a second `exec-once` left over from an older config. Check
`autostart.conf` and `hyprland.conf` for a duplicate.

**Nothing is saved at all.** Run `hyprsession --save-interval 5` in a terminal
and watch it. Errors that vanish under `exec-once` are visible there.

## What this repo tracks

| File | Why |
| --- | --- |
| `dot_config/hypr/autostart.conf` | Steps 1 and 2 |
| `dot_config/systemd/user/hyprsession-save.service` | Step 3 |
| `dot_config/systemd/user/shutdown.target.wants/symlink_hyprsession-save.service.tmpl` | Step 4, so nobody has to run `systemctl enable` |

The saved sessions themselves are not tracked. A desktop belongs to a machine.

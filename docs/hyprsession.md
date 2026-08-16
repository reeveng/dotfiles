# Setting up hyprsession

Hyprsession remembers which windows were open, on which workspace, and puts them
back when Hyprland next starts. One line starts it and it does the rest from
there: it watches the windows and keeps the saved session current, so there is no
moment at which the desktop still has to be photographed.

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
pacman -Q hyprsession            # 1:0.2.1-3, the epoch says it is the fork
```

## Step 1: restore at login, and keep the session current

Put this in `~/.config/hypr/autostart.lua`, inside the `hyprland.start` handler:

```lua
hl.exec_cmd(
  "mv -f ~/.local/state/hyprsession.log ~/.local/state/hyprsession.log.1 2>/dev/null;"
    .. " exec hyprsession --save-interval 120 >~/.local/state/hyprsession.log 2>&1"
)
```

One line does two jobs. On startup it reads the last saved session and reopens
those windows. Then it stays running and keeps the file on disk in step with what
is on screen: a window that opens, moves, floats or goes fullscreen is written
down within a second, and a window that closes after fifteen quiet seconds.

`--save-interval` is what is left for the timer, which is now only there for what
changes inside a window rather than to it. A shell that changes directory and an
editor that opens a file raise no Hyprland event, so two minutes is how stale
that part of the record can get.

The redirection is not decoration. Hyprland throws away whatever the programs it
launches print, so the one program that can say why a window did not come back
has to keep its own log. The previous boot's is left next to it as `.log.1`,
which is the copy you want when the question is what happened last time.

Omarchy's `hyprland.lua` reaches this file through `require("hypr.autostart")`.
An `autostart.conf` beside it is read by nobody. Hyprland picks one config
language per session and this one is Lua.

## Step 2: do not save on the way out

There is nothing to add for shutdown, and anything added there makes things
worse. This machine used to have two such saves, a `hyprland.shutdown` handler
and a systemd unit ordered `Before=shutdown.target`. Both are gone.

Logging out kills what `app-graphical.slice` holds a second or two before the
compositor stops. Every window opened from the launcher or a keybinding lives in
that slice, so by the time either save runs, the window list it reads has already
lost them, and what it writes goes over a good session. The systemd unit had it
worse still: by `shutdown.target` Hyprland itself is gone, so the save cannot
even ask what was open.

```
15:03:30.779  app-signal-8390.scope: Consumed ...          <- signal gone
15:03:31.131  app-Hyprland-gtk\x2dlaunch-29e2348d.scope    <- librewolf gone
15:03:32.741  Stopped target Current graphical user session
15:03:32.946  Stopped Main service for Hyprland            <- only now
```

Saving from the events instead means the file on disk is already right when that
sequence starts, and hyprsession dying with the compositor is exactly what should
happen. The fifteen quiet seconds a closing window waits for are longer than the
whole teardown, so the losses of a logout are never written down. A desktop with
nothing on it is never written down either, whoever asks.

## The mode is a bare word

`hyprsession save`, not `hyprsession --mode save-and-exit`. Most writing about
hyprsession, this file included until recently, spells it the second way, and
that form is worse than a typo would be. 0.2.0 moved the mode out of a flag;
0.2.1 keeps the flag alive by checking for the string `--mode` anywhere in the
arguments and, on finding it, handing the entire run to the pre-0.2.0 code. That
code predates named sessions. It saves to `~/.local/share/hyprsession` itself
rather than to the `default` directory beneath it, and startup only ever reads
`default`. So the save runs, reports nothing wrong, and lands where nothing will
look for it.

## What a terminal brings back with it

A terminal's own command line says where it was told to start, once, and nothing
about the shell inside it. Saving only that line gave back an empty prompt in the
home directory, however far into a project the window had got. Its process tree
knows the rest, so that is where the line now comes from:

```
[... workspace 2 silent ...] foot --working-directory=/home/jmad/Documents/projects/codincod \
  -e /usr/bin/zsh -i -c 'nvim lib/foo.ex; exec /usr/bin/zsh -i'
```

The directory is where the shell actually was. The program is whatever held the
terminal's foreground when the session was saved. It comes back through the shell
that ran it, so quitting nvim leaves a prompt in the project rather than closing
the window, and that shell reads `.zshrc` on the way in, which is what keeps
mise's path in front of the one the compositor was started with.

Every program found in the foreground is started again bar a short list, because
a half finished `sudo pacman -Syu` asking for a password at login is worse than a
terminal that comes back empty. To decide that list yourself, write one program
name per line in `~/.config/hyprsession/never-resume`. That file replaces the
built in list rather than adding to it, so an empty file means everything comes
back.

## Prove it works

**The record is current.** Open something distinctive and look straight away,
without waiting for any interval:

```bash
grep -c . ~/.local/share/hyprsession/default/exec.conf
tail -3 ~/.local/state/hyprsession.log
```

The new window should already be a line in `exec.conf`, and the log should say it
saved. A window that appears in neither is one that will not come back.

**A saved line really relaunches.** Take a line out of `exec.conf`, drop the
`[...]` prefix, and run the rest in a terminal. This is the fastest way to catch
an application whose command does not restart it, because it fails in front of
you instead of at login.

**The whole round trip.** Log out and back in. What did not come back is in the
log, next to the line hyprsession tried:

```bash
grep -E "Sending|Warning|not in the saved" ~/.local/state/hyprsession.log.1
```

## Named sessions

The automatic one is called `default`. You can keep others on purpose:

```bash
hyprsession save writing     # keep the current layout under a name
hyprsession list             # what has been kept
hyprsession load writing     # put it back
```

Mode first, then the name. Leaving the name off means `default`.

`hyprsession watch` is the running half without the loading half, for a session
that is already on screen. It is what to start after installing a new build,
because the ordinary mode would clear the desktop and put it back first.

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
it, before one window has been launched, and with it goes the saving that the
same process was going to do. `pgrep hyprsession` on a fresh boot is the fastest
way to see it: nothing there, while the other things started from the same
handler are running. A session that came back short of a browser, weeks after
the AUR build stopped working, was this and nothing cleverer: no save had run
since the login before, so the file was older than the browser window.

There is no upstream fix to wait for. `joshurtree/hyprsession` last moved in
January 2026, and the tag the AUR builds is that same commit.

The fork replaces the dispatch calls with `eval`, which takes Lua. Programs are
launched with `hl.exec_cmd(command, rules)`, and the rule prefix already sitting
in `exec.conf` is read into the table that call wants, so saved sessions from
before the change still load. The adjustments afterwards go through `hl.dsp.*`.

It carries other fixes, for things that were wrong before Hyprland changed
anything.

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
an argument needs them. Signal needed the opposite: it hands the kernel its whole
command line as a single argument, spaces and all, so quoting that whole named a
program that does not exist, and a lone argument carrying spaces is read back as
the words it used to be.

## When it misbehaves

**Windows come back on the wrong workspace.** Hyprsession records the workspace
a window was on, but window rules run at open time and can move it again. Check
`window-workspaces.lua` for a rule that outranks the restore.

**A window that was open does not come back.** Look for it in
`~/.local/state/hyprsession.log.1` first. No `Sending: exec` line for it means it
was not in the file, so nothing saved it: check that hyprsession was running at
all last session, with `Watching session` in that log. A line that was sent and
brought back nothing is a command that does not relaunch the program, which is
what `hyprsession command <class> "<command>"` is for. It writes a small script
into `~/.local/bin` that runs the right thing.

**Everything comes back twice.** Something else is also restoring the session,
usually a second `exec-once` left over from an older config. Check
`autostart.conf` and `hyprland.conf`, both of which Hyprland ignores under a Lua
config but which an older setup may still have.

**Nothing is saved at all.** `pgrep hyprsession` on a fresh login. Nothing there
means it died during the restore, and the log says on which line.

## What this repo tracks

| File | Why |
| --- | --- |
| `dot_config/hypr/autostart.lua` | Step 1, and the note that step 2 is deliberately empty |

The saved sessions themselves are not tracked. A desktop belongs to a machine.

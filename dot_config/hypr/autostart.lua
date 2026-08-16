-- Extra autostart processes.

hl.on("hyprland.start", function()
  -- Restore the windows from last time, then keep saving them. Hyprland throws
  -- away whatever it launches prints, so the one program that can say why a
  -- window did not come back has to keep its own log; the previous boot's is
  -- next to it as .1.
  -- The mode is a positional word; an argument spelled --mode reroutes
  -- hyprsession to legacy code that saves where nothing loads.
  hl.exec_cmd(
    "mv -f ~/.local/state/hyprsession.log ~/.local/state/hyprsession.log.1 2>/dev/null;"
      .. " exec hyprsession --save-interval 120 >~/.local/state/hyprsession.log 2>&1"
  )

  -- Night light on a clock. Omarchy only ever starts hyprsunset on demand, so
  -- without this the time profiles in hyprsunset.conf never run.
  hl.exec_cmd(o.launch("hyprsunset"))

  -- Quiet notifications and hold the idle lock while OBS is streaming.
  hl.exec_cmd("~/.local/bin/obs-live-watch")
end)

-- Nothing saves the session on the way out any more. Logging out kills what the
-- graphical slice holds a second or two before the compositor stops, so a save
-- fired from here reads a window list those windows have already left and writes
-- it over a good one. hyprsession watches the window events instead.

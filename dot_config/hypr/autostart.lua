-- Extra autostart processes.

hl.on("hyprland.start", function()
  -- Restore the windows from last time, then keep saving them.
  -- The mode is a positional word; an argument spelled --mode reroutes
  -- hyprsession to legacy code that saves where nothing loads.
  hl.exec_cmd("hyprsession --save-interval 120")

  -- Night light on a clock. Omarchy only ever starts hyprsunset on demand, so
  -- without this the time profiles in hyprsunset.conf never run.
  hl.exec_cmd(o.launch("hyprsunset"))

  -- Quiet notifications and hold the idle lock while OBS is streaming.
  hl.exec_cmd("~/.local/bin/obs-live-watch")
end)

hl.on("hyprland.shutdown", function()
  hl.exec_cmd("hyprsession save")
end)

-- Personal keybindings. Omarchy's defaults load first, so a key it already
-- uses has to be unbound before it can be bound again.
--
-- See everything currently bound with:
--   omarchy menu keybindings --print

-- Applications on a bare Super, where Omarchy's defaults want Super + Shift.

-- Was Full screen, which stays on Super + Alt + F as Full width.
hl.unbind("SUPER + F")
o.bind("SUPER + F", "File manager", { omarchy = "nautilus" })

-- Was Browser, which moves down to a bare Super + B.
hl.unbind("SUPER + SHIFT + B")
o.bind("SUPER + B", "Browser", { omarchy = "browser" })
o.bind("SUPER + SHIFT + B", "Browser (private)", { omarchy = "browser --private" })

-- Was Toggle scratchpad. The scratchpads below replace it.
hl.unbind("SUPER + S")
o.bind("SUPER + S", "Signal", { omarchy = "signal" })

o.bind("SUPER + N", "Editor", "omarchy-launch-editor")
o.bind("SUPER + D", "Docker", { tui = "lazydocker" })
o.bind("SUPER + M", "Music", "~/.config/hypr/scripts/scratchpad music kew")

-- Was Music, and the microphone has no other key.
hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Mute microphone", "omarchy-audio-input-mute")

-- Was Universal cut, which stays on Ctrl + X in every application.
hl.unbind("SUPER + X")
o.bind("SUPER + X", "Animations on or off", function()
  hl.config({ animations = { enabled = not hl.get_config("animations.enabled") } })
end)

-- Scratchpads: a window that floats in over your work and leaves again, still
-- running. Music lives in one, so kew keeps playing while it is out of sight.
o.bind("SUPER + grave", "Terminal scratchpad", "~/.config/hypr/scripts/scratchpad term")

-- Pick a workspace for the focused window and write the rule down for good.
o.bind("SUPER + A", "Pin window to a workspace", "~/.config/hypr/scripts/workspace-prompt.sh")

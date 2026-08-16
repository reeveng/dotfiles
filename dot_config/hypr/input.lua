-- Personal input overrides. These replace Omarchy's defaults.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
  input = {
    kb_layout = "us",

    -- Caps lock is a second Super key. Omarchy's default puts compose and a
    -- shift cancel there instead, so this replaces both.
    kb_options = "caps:super",

    repeat_rate = 40,
    repeat_delay = 600,
    numlock_by_default = true,
    sensitivity = 0.69,

    touchpad = {
      scroll_factor = 0.4,
    },
  },
})

-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
  general = {
    gaps_in = 0,
    gaps_out = 0,
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
hl.config({
  decoration = {
    rounding = 4,
  },
})

-- Nothing is see-through. Omarchy's defaults fade an unfocused window to 0.96
-- and browsers to 0.985, and both put whatever is behind the window into the
-- reading of it. This rule is loaded after those, and the last window rule to
-- match is the one Hyprland keeps.
o.window(".*", { opacity = "1 1" })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- Movement in the corner of the eye is movement you end up fighting.
-- SUPER + X puts them back on for as long as the session lasts.
hl.config({
  animations = {
    enabled = false,
  },
})

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

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- Movement in the corner of the eye is movement you end up fighting.
-- SUPER + X puts them back on for as long as the session lasts.
hl.config({
  animations = {
    enabled = false,
  },
})

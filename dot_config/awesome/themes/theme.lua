-------------------------------------------------------
--/=================================================\--
--|>                    THEMES                     <|--
--\=================================================/--
-------------------------------------------------------
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local x = require("themes.colors")
local ftn = "FiraCode NF" .. " "
--<~>--
return {
    font = ftn .. "11",
    title_font = ftn .. "14",
    sub_title_font = ftn .. "9",
    context_font = ftn .. "11",
    --<~>--
    corner_radius = dpi(20),
    border_width = dpi(2),
    useless_gap = 5,
    gap_single_client = false,
    --<~>--
    bg_normal = x.bg,
    bg_focus = x.cur,
    bg_urgent = x.r,
    fg_normal = x.fg,
    fg_focus = x.fg2,
    fg_urgent = x.fg,
    --<~>--
    border_normal = x.bg,
    border_focus = x.b,
    titlebars_enabled = true,
    wallpaper = "~/.dots/home/.config/awesome/themes/bg.jpg",
}

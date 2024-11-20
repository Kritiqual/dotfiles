-------------------------------------------------------
--/=================================================\--
--|>                    HELPERS                    <|--
--\=================================================/--
-------------------------------------------------------
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local naughty = require("naughty")
local xresources = beautiful.xresources
local dpi = xresources.apply_dpi
--<~>--
local helpers = {}
--<~>--
local direction_translate = {
    ["up"] = "top",
    ["down"] = "bottom",
    ["left"] = "left",
    ["right"] = "right",
}
--<~>--
local function switchxc(param, case_table)
    local case = case_table[param]
    if case then return case() end
    local default = case_table['default']
    return default and default() or nil
end
-------------------------------------------------------
----               Single/double tap               ----
-------------------------------------------------------
local tap_timer = nil
function helpers.SoD_tap(fnSingle, fnDouble)
    if tap_timer then
        tap_timer:stop()
        tap_timer = nil
        fnDouble()
        -- naughty.notify({text = "We got a double tap"})
        return
    end

    tap_timer = gears.timer.start_new(0.2, function()
        tap_timer = nil
        -- naughty.notify({text = "We got a single tap"})
        if fnSingle then
            fnSingle()
        end
        return false
    end)
end

-------------------------------------------------------
-------------------------------------------------------
----                  Controllers                  ----
-------------------------------------------------------
--<~>--
function helpers.mediactl(value)
    awful.spawn.with_shell("playerctl " .. value)
end

--<~>--
function helpers.brivolctl(mode, value)
    -- string(value): set, number(value): inc/dec
    -- 0: reset all to default
    -- 1: brightctl, 2: volctl

    -- 10: step
    -- 2: step

    --? How this helper works
    --> First check for mode, second check for value is string or not
    --: If 0: Reset mode
    --: If 1: Brictl mode
    --!     If value is string, set the bri to table[value]
    --*          0: off, 25: normal, 50: medium, 75: brighter, 100: brightest
    --!     If value is not string, inc/dev the bri by the value
    --: If 2: Volctl mode
    --!     If value is string, set the vol to table[value]
    --*          mute != 0: off, 14: smaller, 50: normal, 70: louder, 100: loudest
    --!     If value is not string, inc/dec the vol by the value

    local sign = tonumber(value) >= 0 and "+" or ""
    local b = { 0, 25, 50, 75, 100 }
    local v = { 0, 14, 50, 70, 100 }
    local cmd
    if mode == 0 then
        cmd = "xbacklight -set 25;"
            .. "pactl set-sink-mute @DEFAULT_SINK@ 0 &&"
            .. "pactl set-sink-volume @DEFAULT_SINK@ 50"
        naughty.notify({
            title = "Reset to default",
            message = [[
                Brightness: 25%
                Volume:     50%
            ]]
        })
    elseif mode == 1 then
        --[[
            local val = tonumber(value) > 0 and value or 25
            local sign = value >= 0 and "+" or ""
            local cmd
            local b = { 0, 25, 50, 75, 100 }
            if tostring(type(val)) == "string" then
                cmd = "xbacklight -set " .. b[tonumber(val)]
            else
                cmd = "xbacklight " .. sign .. value
            end
        ]]
        if tostring(type(value)) == "string" then
            cmd = "xbacklight " .. b[tonumber(value)]
        else
            cmd = "xbacklight " .. sign .. value
        end
    elseif mode == 2 then
        local val = value > 0 and value or 50
        if value == 0 then
            cmd = "pactl set-sink-mute @DEFAULT_SINK@ toggle"
        else
            sign = value > 0 and "+" or ""
            cmd = "pactl set-sink-mute @DEFAULT_SINK@ 0 &&"
                .. "pactl set-sink-volume @DEFAULT_SINK@ "
                .. sign .. tostring(value) .. "%"
        end
    end
    awful.spawn.with_shell(cmd)
end

--<~>--
function helpers.volumectl(value)
    local sign = value > 0 and "+" or ""
    local cmd
    if value == 0 then
        cmd = "pactl set-sink-mute @DEFAULT_SINK@ toggle"
    else
        cmd = "pactl set-sink-mute @DEFAULT_SINK@ 0 &&"
            .. "pactl set-sink-volume @DEFAULT_SINK@ "
            .. sign .. tostring(value) .. "%"
    end
    awful.spawn.with_shell(cmd)
end

--<~>--
function helpers.brightctl(value)
    local val = tonumber(value) > 0 and value or 25
    local sign = tonumber(value) >= 0 and "+" or ""
    local cmd
    local b = { 0, 25, 50, 75, 100 }
    if tostring(type(val)) == "string" then
        cmd = "xbacklight -set " .. b[tonumber(val)]
    else
        cmd = "xbacklight " .. sign .. value
    end
    awful.spawn.with_shell(cmd)
end

-------------------------------------------------------
-------------------------------------------------------
----                    Resizer                    ----
-------------------------------------------------------
local f_resize_value = dpi(20)
local t_resize_factor = 0.05
--<~>--
function helpers.resizer(c, direction)
    if c and c.floating then
        if direction == "up" then
            c:relative_move(0, 0, 0, -f_resize_value)
        elseif direction == "down" then
            c:relative_move(0, 0, 0, f_resize_value)
        elseif direction == "left" then
            c:relative_move(0, 0, -f_resize_value, 0)
        elseif direction == "right" then
            c:relative_move(0, 0, f_resize_value, 0)
        end
    elseif awful.layout.get(mouse.screen) ~= awful.layout.suit.floating then
        if direction == "up" then
            awful.client.incwfact(-t_resize_factor)
        elseif direction == "down" then
            awful.client.incwfact(t_resize_factor)
        elseif direction == "left" then
            awful.tag.incmwfact(-t_resize_factor)
        elseif direction == "right" then
            awful.tag.incmwfact(t_resize_factor)
        end
    end
end

-------------------------------------------------------
-------------------------------------------------------
----                     Mover                     ----
-------------------------------------------------------
function helpers.swapper(c, direction)
    if c.floating or (awful.layout.get(mouse.screen) == awful.layout.suit.floating) then
        helpers.move_to_edge(c, direction)
    elseif awful.layout.get(mouse.screen) ~= awful.layout.suit.max then
        awful.client.swap.bydirection(direction, c, nil)
    end
end

-------------------------------------------------------
-------------------------------------------------------
----                Raise or spawn                 ----
-------------------------------------------------------
function helpers.RoS(app, rules, unique_id, callback)
    awful.spawn.raise_or_spawn(app, rules, function(c)
        if string.find((c.class:lower() or c.instance:lower()), app) then
            c:move_to_tag(awful.screen.focused().selected_tag)
            c:jump_to()
            return true
        else
            return false
        end
    end, unique_id, callback)
end

return helpers

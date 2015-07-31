--- Opacity handling.
--
-- TODO: use awful.rules to handle special case for Firefox etc.
--
-- globalkeys:
-- awful.key({ modkey, "Control" }, "+", function (c) opacity.adjust(c,  0.01) end),
-- awful.key({ modkey, "Control" }, "-", function (c) opacity.adjust(c, -0.01) end),
-- awful.key({ modkey, "Shift", "Control" }, "+", function (c) opacity.adjust(c,  0.05) end),
-- awful.key({ modkey, "Shift", "Control" }, "-", function (c) opacity.adjust(c, -0.05) end),
--
-- clientbuttons:
-- -- TODO: do not forward mouse event to client.
-- awful.button({ modkey, "Control" }, 4, function (c) opacity.adjust(c, -0.01) end, function (c) end),
-- awful.button({ modkey, "Control" }, 5, function (c) opacity.adjust(c,  0.01) end, function (c) end))

local M = {}
M = {
    opacity = {
        unfocused_screen = 1,
        -- unfocused_screen_last_client = 1,

        focused = 1,
        unfocused = 0.95,
    }
}
local locked_opacity = {}

local capi = {
    client = client,
}
local awful = require("awful")

if not awful.client.istransientfor then
    function awful.client.istransientfor(c, parent)
        local cur = c
        while cur.transient_for do
            if cur.transient_for == parent then
                return true
            end
            cur = cur.transient_for
        end
        return false
    end
end

-- The last focused client (via "unfocus" signal).
local last_focused_client = nil
local next_focused_client = nil

M.adjust = function(c, delta)
    c.opacity = c.opacity + delta
    table.insert(locked_opacity, c)
end

M.get_opacity_for_client = function(c)
    -- Opacity for focused client and its childs.
    if capi.client.focus
        and (capi.client.focus == c
            or (c == last_focused_client
                and awful.client.istransientfor(next_focused_client, last_focused_client))) then
        if c.class and c.class:lower():find("firefox") then
            opacity = 1
        else
            opacity = M.opacity.focused
        end
    else
        if c.class and c.class:lower():find("firefox") then
            opacity = 1
        else
            opacity = M.opacity.unfocused
        end
    end
    return opacity
end

M.autoset_opacity = function(c, opacity)
    local opacity = opacity or M.get_opacity_for_client(c)
    for _,v in ipairs(locked_opacity) do
        if c == v then
            -- TODO: provide a way to unlock it.
            -- bnote("opacity locked for "..tostring(c))
            return
        end
    end
    c.opacity = opacity
end
-- }}}

-- Opacity on (un)focus.
client.connect_signal("focus", function(c)
    -- bnote(bdump({last_focused_client, c.screen}))
    -- Handle focus switch across screens.
    next_focused_client = c
    if last_focused_client
        and last_focused_client.screen
        and c.screen ~= last_focused_client.screen then
            -- Init opacity for clients on new screen.
            local clients = awful.client.visible(c.screen)
            for _, _c in pairs(clients) do
                M.autoset_opacity(_c)
                -- bnote(bdump({"autoset", c=_c, opacity=_c.opacity}))
            end
            -- Opacity=1 for all clients when focus moved to another screen.
            local clients = awful.client.visible(last_focused_client.screen)
            for _, _c in pairs(clients) do
                M.autoset_opacity(_c, M.opacity.unfocused_screen)
            end
            -- last_focused_client.opacity = M.opacity.unfocused_screen_last_client
    else
        -- bnote("focus: " .. c.name .. " / prev: " .. last_focused_client.name)
        -- Handle last focused client.
        if last_focused_client then
            M.autoset_opacity(last_focused_client)
        end
        M.autoset_opacity(c)
        -- bnote("opacity: " .. c.opacity .. " / " .. last_focused_client.opacity)
    end
    -- bnote(c.opacity)
end)
client.connect_signal("unfocus", function(c)
    last_focused_client = c
    -- bnote("unfocus: "..c.name)
end)
client.connect_signal("unmanage", function(c)
    if c == last_focused_client then
      last_focused_client = nil
    end
end)

-- for s = 1, screen.count() do screen[s]:connect_signal("arrange", function ()
--     -- Set full opacity for clients on non-focused screen.
--     if capi.client.focus and capi.client.focus.screen ~= s then
--         local clients = awful.client.visible(s)
--         for _, c in pairs(clients) do
--             M.autoset_opacity(c, 1)
--         end
--     end
--     end)
-- end

return M

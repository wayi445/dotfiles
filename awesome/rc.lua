-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")


-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err)
        })
        in_error = false
    end)
end

function leftscreen(s)
    if s.index == 1 then
        return screen[3]
    else
        return screen[2]
    end
end

function rightscreen(s)
    if s.index == 2 then
        return screen[3]
    else
        return screen[1]
    end
end

naughty.config.defaults.timeout = 10
naughty.config.defaults.screen = screen[3]
naughty.config.defaults.position = "bottom_right"

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
--beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.init("/home/mate/.config/awesome/theme.lua")
local bling = require("bling")
--[[
beautiful.wallpaper = function(s)
    if s.index == 1 then
        return "/home/mate/.config/awesome/img/right.png"
    elseif s.index == 2 then
        return "/home/mate/.config/awesome/img/left.png"
    elseif s.index == 3 then
        return "/home/mate/.config/awesome/img/middle.png"
    end
end
]]
-- This is used later as the default terminal and editor to run.
terminal = "wezterm"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    --awful.layout.suit.tile,
    --awful.layout.suit.tile.left,
    --awful.layout.suit.tile.bottom,
    --awful.layout.suit.tile.top,
    --awful.layout.suit.fair,
    --awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    --awful.layout.suit.max,
    --awful.layout.suit.max.fullscreen,
    --awful.layout.suit.magnifier,
    --awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
    { "hotkeys",     function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
    { "manual",      terminal .. " -e man awesome" },
    { "edit config", editor_cmd .. " " .. awesome.conffile },
    { "restart",     awesome.restart },
    { "quit",        function() awesome.quit() end },
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", terminal }

if has_fdo then
    mymainmenu = freedesktop.menu.build({
        before = { menu_awesome },
        after = { menu_terminal }
    })
else
    mymainmenu = awful.menu({
        items = {
            menu_awesome,
            { "Debian", debian.menu.Debian_menu.Debian },
            menu_terminal,
        }
    })
end


mylauncher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu = mymainmenu
})

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock("%a %b %d %X ", 1)

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end)
--[[awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
    ]])

local tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
    end),
    awful.button({}, 3, function()
        awful.menu.client_list({ theme = { width = 250 } })
    end),
    awful.button({}, 4, function()
        awful.client.focus.byidx(1)
    end),
    awful.button({}, 5, function()
        awful.client.focus.byidx(-1)
    end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9", }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    --[[    s.mylayoutbox:buttons(gears.table.join(
        awful.button({}, 1, function() awful.layout.inc(1) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc(1) end),
        awful.button({}, 5, function() awful.layout.inc(-1) end)))]]
    -- Create a taglist widget
    s.mytaglist = {}
    s.mytasklist = {}
    s.tagandtask = { layout = wibox.layout.flex.horizontal }
    for i, tag in pairs(s.tags) do
        s.mytaglist[i] = awful.widget.taglist {
            screen = s,
            filter = function(t)
                if t == tag then
                    return true
                else
                    return false
                end
            end,
            buttons = taglist_buttons,
            widget_template = {
                {
                    {
                        id = 'text_role',
                        widget = wibox.widget.textbox,
                    },
                    margins = 8,
                    widget = wibox.container.margin,
                },
                id     = 'background_role',
                widget = wibox.container.background,
            },
            style = {
                squares_sel = "",
                squares_unsel = ""
            }
        }

        s.mytasklist[i] = awful.widget.tasklist {
            screen          = s,
            filter          = function(c, screen)
                for k, t in pairs(c:tags()) do
                    if t == tag then
                        return true
                    end
                end
                return false
            end,
            buttons         = gears.table.join(
                awful.button({}, 1, function(c)
                    if tag.selected then
                        if c == client.focus then
                            c.minimized = true
                        else
                            c:emit_signal(
                                "request::activate",
                                "tasklist",
                                { raise = true }
                            )
                        end
                    else
                        tag:view_only()
                        c:emit_signal(
                            "request::activate",
                            "tasklist",
                            { raise = true })
                    end
                end
                )),
            widget_template = {
                {
                    {
                        id = 'icon_role',
                        widget = wibox.widget.imagebox,
                    }, {
                    id = 'text_role',
                    widget = wibox.widget.textbox,
                },
                    layout = wibox.layout.fixed.horizontal,
                },
                forced_width = nil,
                id           = 'background_role',
                widget       = wibox.container.background,
            },
        }
        table.insert(s.tagandtask, { layout = wibox.layout.align.horizontal, s.mytaglist[i], s.mytasklist[i] })
    end
    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s, opacity=0.8 })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        {
            layout = wibox.layout.fixed.horizontal,
            -- mylauncher,
            s.mypromptbox,
        },
        s.tagandtask,
        {
            layout = wibox.layout.fixed.horizontal,
            --mykeyboardlayout,
            wibox.widget.systray(),
            mytextclock,
            s.mylayoutbox,
        }
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({}, 3, function() mymainmenu:toggle() end) --,
-- awful.button({ }, 4, awful.tag.viewnext),
-- awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}
local term_scratch = bling.module.scratchpad {
    command                 = "wezterm start --class spad", -- How to spawn the scratchpad
    rule                    = {instance = "spad"},  -- The rule that the scratchpad will be searched by
    sticky                  = true,                   -- Whether the scratchpad should be sticky
    autoclose               = true,                   -- Whether it should hide itself when losing focus
    floating                = true,                   -- Whether it should be floating (MUST BE TRUE FOR ANIMATIONS)
    geometry                = { x = 1920/4, y = 1080/4, height = 1080/2, width = 1920/2 }, -- The geometry in a floating state
    reapply                 = true,                   -- Whether all those properties should be reapplied on every new opening of the scratchpad (MUST BE TRUE FOR ANIMATIONS)
    dont_focus_before_close = true,                  -- When set to true, the scratchpad will be closed by the toggle function regardless of whether its focused or not. When set to false, the toggle function will first bring the scratchpad into focus and only close it on a second call
}

local volume_scratch = bling.module.scratchpad {
    command                 = "pavucontrol", -- How to spawn the scratchpad
    rule                    = {class = "Pavucontrol"},  -- The rule that the scratchpad will be searched by
    sticky                  = true,                   -- Whether the scratchpad should be sticky
    autoclose               = true,                   -- Whether it should hide itself when losing focus
    floating                = true,                   -- Whether it should be floating (MUST BE TRUE FOR ANIMATIONS)
    geometry                = { x = 1920/4, y = 1080/4, height = 1080/2, width = 1920/2 }, -- The geometry in a floating state
    reapply                 = true,                   -- Whether all those properties should be reapplied on every new opening of the scratchpad (MUST BE TRUE FOR ANIMATIONS)
    dont_focus_before_close = true,                  -- When set to true, the scratchpad will be closed by the toggle function regardless of whether its focused or not. When set to false, the toggle function will first bring the scratchpad into focus and only close it on a second call
}
local swap1
-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey, }, "s", hotkeys_popup.show_help,
        { description = "show help", group = "awesome" }),
    -- awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
    --        {description = "view previous", group = "tag"}),
    --awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
    --        {description = "view next", group = "tag"}),
    --awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
    --      {description = "go back", group = "tag"}),

    awful.key({ modkey, }, "j", function() awful.client.focus.global_bydirection("left") end,
        { description = "move focus to left", group = "client" }),
    awful.key({ modkey, }, "k", function() awful.client.focus.global_bydirection("right") end,
        { description = "move focus to right", group = "client" }),
    awful.key({ modkey,"Control" }, "j",
        function()
            awful.client.focus.byidx(1)
        end,
        { description = "focus next by index", group = "client" }
    ),
    awful.key({ modkey,"Control" }, "k",
        function()
            awful.client.focus.byidx(-1)
        end,
        { description = "focus previous by index", group = "client" }
    ),
    --awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
    --        {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift" }, "h", function() 
        if client.focus.screen.index==1 then
            client.focus:move_to_screen(screen[3])
        else
            client.focus:move_to_screen(screen[2])
        end
    end,
        { description = "move client to left screen", group = "client" }),
    awful.key({ modkey, "Shift" }, "l", function() 
        if client.focus.screen.index==2 then
            client.focus:move_to_screen(screen[3])
        else
            client.focus:move_to_screen(screen[1])
        end
    end,
        { description = "move client to right screen", group = "client" }),
    awful.key({ modkey, }, "h", function() awful.screen.focus_bydirection("left") end,
        { description = "move focus to the left screen", group = "screen" }),
    awful.key({ modkey, }, "l", function() awful.screen.focus_bydirection("right") end,
        { description = "move focus to the right screen", group = "screen" }),
    awful.key({ modkey, "Shift" }, "j", function() awful.client.swap.global_bydirection("left") end,
        { description = "swap client with the left client", group = "client" }),
    awful.key({ modkey, "Shift" }, "k", function() awful.client.swap.global_bydirection("right") end,
        { description = "swap client with the right client", group = "client" }),
    awful.key({ modkey, "Shift" }, "s", function()
            if not swap1 then
                swap1=client.focus
                client.focus.border_color="#00ff00"
                naughty.notify({
                    title=client.focus.class

                })
            else
                naughty.notify({
                    title=client.focus.class
                })
            end
    end,
        { description = "swap", group = "client" }),
    --awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
    --        {description = "jump to urgent client", group = "client"}),
    -- awful.key({ modkey,           }, "Tab",
    --function ()
    --  awful.client.focus.history.previous()
    -- if client.focus then
    --   client.focus:raise()
    --end
    --end,
    --{description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey, }, "Return", function() awful.spawn(terminal) end,
        { description = "open a terminal", group = "launcher" }),
    awful.key({ modkey, }, "t", function()  term_scratch:toggle() end,
        { description = "open a terminal scratchpad", group = "launcher" }),
    awful.key({ modkey, }, "v", function()  volume_scratch:toggle() end,
        { description = "open a terminal scratchpad", group = "launcher" }),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
        { description = "reload awesome", group = "awesome" }),
   --[[ awful.key({ modkey, "Shift" }, "q", awesome.quit,
        { description = "quit awesome", group = "awesome" }),]]
    awful.key({ modkey, "Control" }, "l", function() awful.tag.incmwfact(0.02, client.focus.first_tag) end,
        { description = "increase master width factor", group = "layout" }),
    awful.key({ modkey, "Control" }, "h", function() awful.tag.incmwfact(-0.02, client.focus.first_tag) end,
        { description = "increase master width factor", group = "layout" }),
    --awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
    --        {description = "increase the number of master clients", group = "layout"}),
    --awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
    --        {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, ";", function() awful.tag.incncol(1, nil, true) end,
        { description = "increase the number of columns", group = "layout" }),
    awful.key({ modkey, "Control" }, "-", function() awful.tag.incncol(-1, nil, true) end,
        { description = "decrease the number of columns", group = "layout" }),
    awful.key({ modkey, }, "space", function() awful.layout.inc(1) end,
        { description = "select next", group = "layout" }),
    -- awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
    --         {description = "select previous", group = "layout"}),

    --awful.key({ modkey, "Control" }, "n",
    --        function ()
    --          local c = awful.client.restore()
    --        -- Focus restored client
    --      if c then
    --      c:emit_signal(
    --        "request::activate", "key.unminimize", {raise = true}
    --  )
    --end
    -- end,
    --{description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey }, "r", function() awful.screen.focused().mypromptbox:run() end,
        { description = "run prompt", group = "launcher" }),

    --awful.key({ modkey }, "l",
    --        function ()
    --          awful.prompt.run {
    --          prompt       = "Run Lua code: ",
    --        textbox      = awful.screen.focused().mypromptbox.widget,
    --      exe_callback = awful.util.eval,
    --    history_path = awful.util.get_cache_dir() .. "/history_eval"
    -- }
    --end,
    --{description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
        { description = "show the menubar", group = "launcher" })
)

clientkeys = gears.table.join(
    awful.key({ modkey, }, "f",
        function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        { description = "toggle fullscreen", group = "client" }),
    awful.key({ modkey, "Shift" }, "q", function(c) c:kill() end,
        { description = "close", group = "client" }),
    awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle,
        { description = "toggle floating", group = "client" }),
    awful.key({ modkey, "Control" }, "Return", function(c) c:swap(awful.client.getmaster()) end,
        { description = "move to master", group = "client" }),
    --awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
    --        {description = "move to screen", group = "client"}),
    --awful.key({ modkey,           }, "z",      function (c) c:move_to_screen(screen[2])    end,
    --        {description = "move to left screen", group = "client"}),
    --awful.key({ modkey,           }, "x",      function (c) c:move_to_screen(screen[3])    end,
    --        {description = "move to middle screen", group = "client"}),
    --awful.key({ modkey,           }, "c",      function (c) c:move_to_screen(screen[1])    end,
    --        {description = "move to right screen", group = "client"}),
    --awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
    --        {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey, }, "n",
        function(c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end,
        { description = "minimize", group = "client" }),
    awful.key({ modkey, }, "m",
        function(c)
            c.maximized = not c.maximized
            c:raise()
        end,
        { description = "(un)maximize", group = "client" }),
    awful.key({ modkey, "Control" }, "m",
        function(c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end,
        { description = "(un)maximize vertically", group = "client" }),
    awful.key({ modkey, "Shift" }, "m",
        function(c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end,
        { description = "(un)maximize horizontally", group = "client" }),
    awful.key({ modkey, "Control" }, "c",
        function(c)
            if c.opacity <= 0.22 then
                c.opacity = 1
            else
                c.opacity = c.opacity - 0.1
            end
            --[[naughty.notify({
                title="opacity changed",
                text=tostring(c.opacity)
            })]]
        end,
        { description = "change opacity", group = "client" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
            { description = "view tag #" .. i, group = "tag" }),
        -- Toggle tag display.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end,
            { description = "toggle tag #" .. i, group = "tag" }),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                        tag:view_only()
                    end
                end
            end,
            { description = "move focused client to tag #" .. i, group = "tag" }),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                        tag:view_only()
                    end
                end
            end,
            { description = "toggle focused client on tag #" .. i, group = "tag" })
    )
end

clientbuttons = gears.table.join(
    awful.button({}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
    end),
    awful.button({ modkey }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen
        }
    },

    -- Floating clients.
    {
        rule_any = {
            instance = {
                "DTA",   -- Firefox addon DownThemAll.
                "copyq", -- Includes session name in class.
                "pinentry",
            },
            class = {
                "Arandr",
                "Blueman-manager",
                "Gpick",
                "Kruler",
                "MessageWin",  -- kalarm.
                "Sxiv",
                "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
                "Wpa_gui",
                "veromix",
                "xtightvncviewer",
            },

            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name = {
                "Event Tester", -- xev.
            },
            role = {
                "AlarmWindow",   -- Thunderbird's calendar.
                "ConfigManager", -- Thunderbird's about:config.
                "pop-up",        -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = { floating = true }
    },

    -- Add titlebars to normal clients and dialogs
    {
        rule_any = { type = { "normal", "dialog" }
        },
        properties = { titlebars_enabled = true }
    },
    {
        rule={instance ="spad"},
        callback=function(c)

        end,
    }

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end
    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end

    if not c.floating or c.instance == "spad" or c.class=="Pavucontrol" then
        awful.titlebar.hide(c)
    end
    --for seeing class and stuff
    --naughty.notify({title="class:"..c.class.." instance:"..c.instance})
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({}, 1, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({}, 3, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c):setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        {     -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton(c),
            -- awful.titlebar.widget.maximizedbutton(c),
            -- awful.titlebar.widget.stickybutton   (c),
            -- awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
--client.connect_signal("mouse::enter", function(c)
-- c:emit_signal("request::activate", "mouse_enter", {raise = false})
--end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
-- notification defaults
awful.spawn.with_shell("picom")

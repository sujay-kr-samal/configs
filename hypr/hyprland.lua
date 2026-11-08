-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- HYPRLAND CONFIG (main file)                           --
-- Split into modules next to this file:                 --
--   looks.lua, keybindings.lua, windows_rule.lua,       --
--   autostart.lua                                       --
-- https://wiki.hypr.land/configuring/                   --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/configuring/core/monitors/
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@144",
    position = "0x0",
    scale    = "1",
})


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/configuring/core/environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/configuring/core/advanced-configuration/permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/configuring/core/devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


-----------------
---- MODULES ----
-----------------

require("looks")
require("keybindings")
require("windows_rule")
require("autostart")

-- >>> ETEA Shell >>>
-- Added by ETEA's install.sh. Run it with --uninstall to take this out.
hl.on("hyprland.start", function()
    hl.exec_cmd([[qs -p "/home/sujay/.config/etea-shell"]])
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("hypridle")
end)
-- <<< ETEA Shell <<<

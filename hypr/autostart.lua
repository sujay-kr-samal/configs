-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/configuring/core/autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
hl.on("hyprland.start", function ()
    -- wallpaper daemon
    hl.exec_cmd("awww-daemon")

    -- restore the last wallpaper (also regenerates the matugen colors)
    hl.exec_cmd("sh -c 'f=$HOME/.cache/current-wall; [ -f \"$f\" ] && $HOME/.config/quickshell/set-wallpaper.sh \"$(cat $f)\"'")

    -- bar, launcher and wallpaper picker (skipped if Quickshell is already running)
    hl.exec_cmd("sh -c 'pgrep -x quickshell >/dev/null || qs'")

    -- other examples:
    -- hl.exec_cmd("nm-applet")
end)

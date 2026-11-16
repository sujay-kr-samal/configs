-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/configuring/core/autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
hl.on("hyprland.start", function ()
    -- wallpaper daemon
    hl.exec_cmd("awww-daemon")
    
    hl.exec_cmd("qs -c lumen")
end)

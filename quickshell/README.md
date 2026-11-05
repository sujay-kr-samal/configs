# Divine Topbar

A first-pass Quickshell topbar for Hyprland.

## Install

```bash
mkdir -p ~/.config/quickshell/divine
cp -r shell.qml scripts ~/.config/quickshell/divine/
chmod +x ~/.config/quickshell/divine/scripts/*.sh
```

Run it:

```bash
quickshell -p ~/.config/quickshell/divine/shell.qml
```

If it works, add this to your Hyprland autostart (only once):

```bash
quickshell -p ~/.config/quickshell/divine/shell.qml
```

## Dependencies

Required for the status values and actions:

```bash
sudo pacman -S jq networkmanager pipewire wireplumber upower pavucontrol
```

Optional performance profile control:

```bash
sudo pacman -S power-profiles-daemon
sudo systemctl enable --now power-profiles-daemon
```

Optional power menu:

```bash
sudo pacman -S wlogout
```

The profile pill cycles power-saver -> balanced -> performance -> power-saver.
If power-profiles-daemon is not installed, the pill will show `balanced` and clicking it will do nothing.

## Controls

- Click a workspace number to switch to it.
- Click Wi-Fi to open NetworkManager's connection editor.
- Click volume to open pavucontrol; scroll up to raise output volume.
- Click microphone to toggle microphone mute; scroll up to raise mic volume.
- Click performance pill to cycle power profiles.
- Click power icon to open wlogout if installed.

## Notes

- This is a standalone first version. It does not overwrite your existing Quickshell files.
- The bar uses a dark translucent plum palette with a pink accent.
- The date/time uses your system locale and 12-hour format.
- If your Quickshell build reports a QML API error, run it from a terminal and share the exact error so the component can be adjusted to your installed version.

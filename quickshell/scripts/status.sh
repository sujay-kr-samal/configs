#!/usr/bin/env bash
set -u

# Active Hyprland workspace
workspace="$(hyprctl -j activeworkspace 2>/dev/null | jq -r '.id // 1' 2>/dev/null || echo 1)"

# NetworkManager Wi-Fi radio state
wifi="$(nmcli -t -f WIFI radio 2>/dev/null | head -n1)"
[[ "$wifi" == "enabled" ]] && wifi="on" || wifi="off"

# PipeWire output and microphone levels
vol_raw="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"
mic_raw="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || true)"

vol="$(awk -v s="$vol_raw" 'BEGIN { if (s ~ /MUTED/) print "MUTE"; else if (match(s, /[0-9]+\\.[0-9]+/)) printf "%d%%", substr(s,RSTART,RLENGTH)*100; else print "--" }')"
mic="$(awk -v s="$mic_raw" 'BEGIN { if (s ~ /MUTED/) print "MUTE"; else if (match(s, /[0-9]+\\.[0-9]+/)) printf "%d%%", substr(s,RSTART,RLENGTH)*100; else print "--" }')"

# Battery percentage (UPower)
battery="AC"
bat="$(upower -e 2>/dev/null | grep -m1 'battery' || true)"
if [[ -n "$bat" ]]; then
    battery="$(upower -i "$bat" 2>/dev/null | awk '/percentage:/ {gsub(/%/,"",$2); print $2 "%"; exit}')"
    [[ -z "$battery" ]] && battery="--"
fi

# Power profile (requires power-profiles-daemon)
profile="$(powerprofilesctl get 2>/dev/null || echo balanced)"
profile="${profile%%$'\n'*}"

printf '%s|%s|VOL %s|MIC %s|%s|%s\n' "$workspace" "$wifi" "$vol" "$mic" "$battery" "$profile"

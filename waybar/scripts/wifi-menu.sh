#!/bin/bash
# ~/.config/waybar/scripts/wifi-menu.sh

# Get WiFi status
wifi_status=$(nmcli radio wifi)
current_connection=$(nmcli -t -f NAME connection show --active | head -1)
current_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
signal_strength=$(nmcli -t -f active,signal dev wifi | grep '^yes' | cut -d: -f2)

# Create toggle option
if [ "$wifi_status" = "enabled" ]; then
    toggle_option="  Disable WiFi"
else
    toggle_option="  Enable WiFi"
fi

# Get available networks
networks=$(nmcli -f SSID,SECURITY,SIGNAL device wifi list | tail -n +2 | \
    awk '{signal=$NF; $NF=""; security=$(NF-1); $(NF-1)=""; ssid=$0;
    gsub(/^ +| +$/, "", ssid);
    if (ssid != "--" && ssid != "") printf "  %-30s %s %s%%\n", ssid, security, signal}' | \
    sort -k3 -nr)

# Create menu content
if [ "$wifi_status" = "enabled" ] && [ -n "$current_ssid" ]; then
    header="󰤨  Connected to: $current_ssid ($signal_strength%)\n"
else
    header="󰤭  Disconnected\n"
fi

options="$header\n$toggle_option\n  Network Settings\n\n  Available Networks:\n$networks"

# Show menu
chosen=$(echo -e "$options" | wofi --dmenu --prompt "WiFi" --width 500 --height 600 --cache-file /dev/null)

case "$chosen" in
    "  Disable WiFi")
        nmcli radio wifi off
        ;;
    "  Enable WiFi")
        nmcli radio wifi on
        ;;
    "  Network Settings")
        nm-connection-editor &
        ;;
    "  "*)
        # Extract SSID from the chosen option
        ssid=$(echo "$chosen" | sed 's/^  //' | awk '{print $1}')
        # Try to connect
        nmcli device wifi connect "$ssid"
        ;;
esac

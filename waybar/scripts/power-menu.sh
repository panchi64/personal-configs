#!/bin/bash
# ~/.config/waybar/scripts/power-menu.sh

# Power menu options
options="  Lock\n  Logout\n  Sleep\n󰜉  Restart\n  Shutdown"

# Show menu using wofi
chosen=$(echo -e "$options" | wofi --dmenu --prompt "Power Menu" --width 250 --height 280 --cache-file /dev/null)

case $chosen in
    "  Lock")
        # You can use swaylock or gtklock
        swaylock -f -c 000000 || gtklock
        ;;
    "  Logout")
        hyprctl dispatch exit
        ;;
    "  Sleep")
        systemctl suspend
        ;;
    "󰜉  Restart")
        systemctl reboot
        ;;
    "  Shutdown")
        systemctl poweroff
        ;;
esac

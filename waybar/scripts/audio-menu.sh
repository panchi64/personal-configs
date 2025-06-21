#!/bin/bash
# ~/.config/waybar/scripts/audio-menu.sh

# Get current volume and mute status
volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -1)
muted=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -o 'yes\|no')

# Create volume bar
volume_bar=""
for i in $(seq 1 10); do
    if [ $((i * 10)) -le $volume ]; then
        volume_bar="${volume_bar}█"
    else
        volume_bar="${volume_bar}░"
    fi
done

# Get available sinks
sinks=$(pactl list sinks short | awk '{print $2}' | sed 's/^/  /')

# Create menu options
if [ "$muted" = "yes" ]; then
    mute_option="🔊  Unmute"
else
    mute_option="🔇  Mute"
fi

options="󰕾  Volume: $volume% [$volume_bar]\n$mute_option\n  Audio Settings\n\n  Output Devices:\n$sinks"

# Show menu
chosen=$(echo -e "$options" | wofi --dmenu --prompt "Audio" --width 400 --height 400 --cache-file /dev/null)

case $chosen in
    "🔇  Mute"|"🔊  Unmute")
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
    "  Audio Settings")
        pavucontrol &
        ;;
    "  "*)
        # Switch to selected sink
        sink=$(echo "$chosen" | sed 's/^  //')
        pactl set-default-sink "$sink"
        ;;
esac

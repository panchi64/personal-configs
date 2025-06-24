#!/bin/bash

# Get Bluetooth adapter information
adapter_powered=$(gdbus call --system --dest org.bluez --object-path /org/bluez/hci0 --method org.freedesktop.DBus.Properties.Get org.bluez.Adapter1 Powered 2>/dev/null | grep -o 'true\|false' || echo "false")
adapter_discoverable=$(gdbus call --system --dest org.bluez --object-path /org/bluez/hci0 --method org.freedesktop.DBus.Properties.Get org.bluez.Adapter1 Discoverable 2>/dev/null | grep -o 'true\|false' || echo "false")

# Get paired devices
get_paired_devices() {
    gdbus call --system --dest org.bluez --object-path /org/bluez/hci0 --method org.freedesktop.DBus.Properties.Get org.bluez.Adapter1 UUIDs 2>/dev/null >/dev/null
    if [ $? -eq 0 ]; then
        gdbus introspect --system --dest org.bluez --object-path /org/bluez 2>/dev/null | grep -o '/org/bluez/hci0/dev_[A-F0-9_]*' | while read device_path; do
            device_name=$(gdbus call --system --dest org.bluez --object-path "$device_path" --method org.freedesktop.DBus.Properties.Get org.bluez.Device1 Name 2>/dev/null | sed "s/^.*'\(.*\)'.*$/\1/")
            device_connected=$(gdbus call --system --dest org.bluez --object-path "$device_path" --method org.freedesktop.DBus.Properties.Get org.bluez.Device1 Connected 2>/dev/null | grep -o 'true\|false' || echo "false")
            device_address=$(echo "$device_path" | sed 's|/org/bluez/hci0/dev_||' | sed 's/_/:/g')
            
            if [ -n "$device_name" ] && [ "$device_name" != "error" ]; then
                if [ "$device_connected" = "true" ]; then
                    echo "󰂱 $device_name (Connected)|$device_path"
                else
                    echo "󰂲 $device_name|$device_path"
                fi
            fi
        done
    fi
}

# Build menu
build_menu() {
    # Header based on adapter status
    if [ "$adapter_powered" = "true" ]; then
        # Check if any device is connected
        connected_devices=$(get_paired_devices | grep "Connected" | wc -l)
        if [ "$connected_devices" -gt 0 ]; then
            echo "󰂯 Bluetooth: Connected"
        else
            echo "󰂳 Bluetooth: On"
        fi
    else
        echo "󰂲 Bluetooth: Off"
    fi
    
    echo "---"
    
    # Toggle option
    if [ "$adapter_powered" = "true" ]; then
        echo " Disable Bluetooth"
    else
        echo " Enable Bluetooth"
    fi
    
    echo " Bluetooth Settings"
    
    # Only show devices if Bluetooth is on
    if [ "$adapter_powered" = "true" ]; then
        echo "---"
        echo "Paired Devices:"
        
        paired_devices=$(get_paired_devices)
        if [ -n "$paired_devices" ]; then
            echo "$paired_devices" | while IFS='|' read -r display_line device_path; do
                echo "$display_line"
            done
        else
            echo "  No paired devices"
        fi
    fi
}

# Show menu and get selection
menu_output=$(build_menu)
choice=$(echo "$menu_output" | wofi --dmenu --prompt "Bluetooth" --width 500 --height 400 --cache-file /dev/null)

# Handle selection
case "$choice" in
    " Disable Bluetooth")
        gdbus call --system --dest org.bluez --object-path /org/bluez/hci0 --method org.freedesktop.DBus.Properties.Set org.bluez.Adapter1 Powered false
        ;;
    " Enable Bluetooth")
        gdbus call --system --dest org.bluez --object-path /org/bluez/hci0 --method org.freedesktop.DBus.Properties.Set org.bluez.Adapter1 Powered true
        ;;
    " Bluetooth Settings")
        blueman-manager &
        ;;
    *)
        # Handle device selection
        if [[ "$choice" =~ ^󰂱.*\(Connected\)$ ]]; then
            # Disconnect device
            device_name=$(echo "$choice" | sed 's/󰂱 \(.*\) (Connected)/\1/')
            device_path=$(get_paired_devices | grep "$device_name" | cut -d'|' -f2)
            if [ -n "$device_path" ]; then
                gdbus call --system --dest org.bluez --object-path "$device_path" --method org.bluez.Device1.Disconnect
            fi
        elif [[ "$choice" =~ ^󰂲.* ]]; then
            # Connect device
            device_name=$(echo "$choice" | sed 's/󰂲 \(.*\)/\1/')
            device_path=$(get_paired_devices | grep "$device_name" | cut -d'|' -f2)
            if [ -n "$device_path" ]; then
                gdbus call --system --dest org.bluez --object-path "$device_path" --method org.bluez.Device1.Connect
            fi
        fi
        ;;
esac
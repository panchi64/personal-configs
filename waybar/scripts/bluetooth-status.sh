#!/bin/bash

# Get Bluetooth adapter status
adapter_powered=$(gdbus call --system --dest org.bluez --object-path /org/bluez/hci0 --method org.freedesktop.DBus.Properties.Get org.bluez.Adapter1 Powered 2>/dev/null | grep -o 'true\|false' || echo "false")

# Function to get connected devices count and names
get_connected_info() {
    connected_count=0
    connected_names=""
    
    if [ "$adapter_powered" = "true" ]; then
        # Get all device paths
        device_paths=$(gdbus introspect --system --dest org.bluez --object-path /org/bluez 2>/dev/null | grep -o '/org/bluez/hci0/dev_[A-F0-9_]*' || echo "")
        
        if [ -n "$device_paths" ]; then
            while IFS= read -r device_path; do
                if [ -n "$device_path" ]; then
                    device_connected=$(gdbus call --system --dest org.bluez --object-path "$device_path" --method org.freedesktop.DBus.Properties.Get org.bluez.Device1 Connected 2>/dev/null | grep -o 'true\|false' || echo "false")
                    
                    if [ "$device_connected" = "true" ]; then
                        device_name=$(gdbus call --system --dest org.bluez --object-path "$device_path" --method org.freedesktop.DBus.Properties.Get org.bluez.Device1 Name 2>/dev/null | sed "s/^.*'\(.*\)'.*$/\1/")
                        if [ -n "$device_name" ] && [ "$device_name" != "error" ]; then
                            connected_count=$((connected_count + 1))
                            if [ -z "$connected_names" ]; then
                                connected_names="$device_name"
                            else
                                connected_names="$connected_names, $device_name"
                            fi
                        fi
                    fi
                fi
            done <<< "$device_paths"
        fi
    fi
    
    echo "$connected_count|$connected_names"
}

# Check if Bluetooth adapter exists
if ! gdbus introspect --system --dest org.bluez --object-path /org/bluez/hci0 >/dev/null 2>&1; then
    # No Bluetooth adapter available
    echo '{"text": "󰂭", "tooltip": "Bluetooth Unavailable", "class": "unavailable"}'
    exit 0
fi

# Get connection info
connection_info=$(get_connected_info)
connected_count=$(echo "$connection_info" | cut -d'|' -f1)
connected_names=$(echo "$connection_info" | cut -d'|' -f2)

# Determine icon and tooltip based on status
if [ "$adapter_powered" = "true" ]; then
    if [ "$connected_count" -gt 0 ]; then
        # Bluetooth on and connected
        icon="󰂯"
        if [ "$connected_count" -eq 1 ]; then
            tooltip="Bluetooth: Connected to $connected_names"
        else
            tooltip="Bluetooth: Connected to $connected_count devices ($connected_names)"
        fi
        class="connected"
    else
        # Bluetooth on but not connected
        icon="󰂳"
        tooltip="Bluetooth: On"
        class="on"
    fi
else
    # Bluetooth off
    icon="󰂲"
    tooltip="Bluetooth: Off"
    class="off"
fi

# Output JSON for waybar
echo "{\"text\": \"$icon\", \"tooltip\": \"$tooltip\", \"class\": \"$class\"}"
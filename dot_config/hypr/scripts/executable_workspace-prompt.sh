#!/bin/bash
# Save as ~/.config/hypr/scripts/save-window-workspace.sh

CONFIG_FILE="$HOME/.config/hypr/window-workspaces.conf"

# Get active window class
window_class=$(hyprctl activewindow -j | jq -r '.class')

# Check if we already have a rule for this class
if grep -q "class:^($window_class)\$" "$CONFIG_FILE" 2>/dev/null; then
    notify-send "Already exists" "Rule for $window_class already saved"
    exit 0
fi

# Prompt for workspace using wofi
workspace=$(echo -e "1\n2\n3\n4\n5\n6\n7\n8\n9\n10" | wofi --dmenu --prompt "Workspace for $window_class:")

# Save if valid
if [[ "$workspace" =~ ^[0-9]+$ ]]; then
    echo "windowrulev2 = workspace $workspace, class:^($window_class)\$" >> "$CONFIG_FILE"
    notify-send "Rule saved!" "$window_class will open on workspace $workspace"
    hyprctl reload
fi

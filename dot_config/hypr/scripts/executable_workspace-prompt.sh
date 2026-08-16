#!/bin/bash

# Pin the focused window's class to a workspace, for good.
# Appends a rule to hypr/window-workspaces.lua, which hyprland.lua requires.

set -e

CONFIG_FILE="$HOME/.config/hypr/window-workspaces.lua"

window_class=$(hyprctl activewindow -j | jq -r '.class')

if [[ -z $window_class || $window_class == "null" ]]; then
  notify-send "No window" "Focus a window first"
  exit 0
fi

if grep -qF "o.window(\"^($window_class)\$\"" "$CONFIG_FILE" 2>/dev/null; then
  notify-send "Already exists" "Rule for $window_class already saved"
  exit 0
fi

workspace=$(seq 1 10 | walker --dmenu --placeholder "Workspace for $window_class")

if [[ "$workspace" =~ ^[0-9]+$ ]]; then
  printf 'o.window("^(%s)$", { workspace = "%s" })\n' "$window_class" "$workspace" >>"$CONFIG_FILE"
  notify-send "Rule saved" "$window_class will open on workspace $workspace"
  hyprctl reload
fi

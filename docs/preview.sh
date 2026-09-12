#!/bin/bash
#
# Renders the marketplace/README preview: the dock alone, in the middle of the
# screen, over the blurred wallpaper.
#
# It flips `printMode` on in ~/.config/omarchy/arc-dock.json (the dock reads
# the file live and moves to the center of the screen, never hiding), switches
# the dock's monitor to an empty workspace so no window shows through the
# glass, captures a band around the dock with grim, and puts everything back —
# the config file, the workspace and the pointer — even if the capture fails.
#
#   docs/preview.sh [output.png] [width] [height]
#
# Defaults to preview.png at 1200x500: wide enough for the marketplace card,
# which crops the image to a band around its center, and the dock is at the
# center.
#
# The dispatchers are written in the Lua form (`hl.dsp...`): on a Lua-config
# Hyprland the legacy `workspace empty` spelling is refused.

set -euo pipefail

out=${1:-preview.png}
width=${2:-1200}
height=${3:-500}

# The monitor the dock lives on. `workspace = "empty"` acts on the focused
# monitor, so that one has to be focused first — and put back afterwards.
monitor=$(hyprctl layers -j |
  jq -r 'to_entries[] | select([.value.levels[][] | .namespace] | index("arc-dock")) | .key' |
  head -1)
if [[ -z $monitor ]]; then
  echo "arc-dock layer not found; is the dock running?" >&2
  exit 1
fi
read -r mx my workspace < <(hyprctl monitors -j |
  jq -r --arg m "$monitor" '.[] | select(.name == $m) | "\(.x) \(.y) \(.activeWorkspace.id)"')

config="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/arc-dock.json"
backup=$(mktemp)
if [[ -s $config ]]; then
  cp "$config" "$backup"
else
  printf '{"version":1,"settings":{}}\n' >"$backup"
fi

restore() {
  cp "$backup" "$config"
  rm -f "$backup"
  hyprctl dispatch "hl.dsp.focus({ monitor = \"$monitor\" })" >/dev/null
  hyprctl dispatch "hl.dsp.focus({ workspace = \"$workspace\" })" >/dev/null
}
trap restore EXIT

jq '.settings.printMode = true' "$backup" >"$config"
hyprctl dispatch "hl.dsp.focus({ monitor = \"$monitor\" })" >/dev/null
hyprctl dispatch 'hl.dsp.focus({ workspace = "empty" })' >/dev/null
# Keep the pointer off the dock: the wave would show in the capture. The
# corner of the dock's own monitor, so focus stays there.
hyprctl dispatch "hl.dsp.cursor.move({ x = $((mx + 1)), y = $((my + 1)) })" >/dev/null
# The dock reads the file, reanchors, and the compositor blurs the new spot.
sleep 1.5

read -r x y w h < <(hyprctl layers -j |
  jq -r '.. | objects | select(.namespace? == "arc-dock") | "\(.x) \(.y) \(.w) \(.h)"' |
  head -1)
cx=$((x + w / 2))
cy=$((y + h / 2))
grim -g "$((cx - width / 2)),$((cy - height / 2)) ${width}x${height}" "$out"
echo "$out"

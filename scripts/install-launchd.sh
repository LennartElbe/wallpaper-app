#!/bin/bash
# Builds a release binary and installs a launchd user agent that regenerates
# the wallpaper on login and every INTERVAL_SECONDS thereafter.
set -euo pipefail

INTERVAL_SECONDS="${1:-1800}" # default: every 30 minutes

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="com.lenni.wallpaperapp"
PLIST_DEST="$HOME/Library/LaunchAgents/${LABEL}.plist"
LOG_DIR="$HOME/Library/Application Support/WallpaperApp"

echo "Building release binary..."
cd "$PROJECT_DIR"
swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)/WallpaperApp"

if [ ! -x "$BIN_PATH" ]; then
    echo "error: built binary not found at $BIN_PATH" >&2
    exit 1
fi

mkdir -p "$LOG_DIR"

echo "Installing launchd agent -> $PLIST_DEST"
sed \
    -e "s#__BIN_PATH__#${BIN_PATH}#g" \
    -e "s#__INTERVAL_SECONDS__#${INTERVAL_SECONDS}#g" \
    -e "s#__LOG_DIR__#${LOG_DIR}#g" \
    "$PROJECT_DIR/launchd/com.lenni.wallpaperapp.plist.template" > "$PLIST_DEST"

# Reload cleanly if it's already running.
launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"
launchctl enable "gui/$(id -u)/${LABEL}"

echo "Installed. Wallpaper will regenerate every $((INTERVAL_SECONDS / 60)) minutes, and once now."
echo "Logs: $LOG_DIR/wallpaper-app.log (app) and $LOG_DIR/launchd.*.log (launchd)"

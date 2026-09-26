#!/bin/bash
# Builds a release binary and installs a launchd user agent that regenerates
# the wallpaper on login and at fixed clock marks every INTERVAL_MINUTES.
#
# Uses StartCalendarInterval (fixed :00/:30-style marks) rather than
# StartInterval (a rolling "N seconds since last run" timer): StartInterval's
# timer can fail to re-arm after the Mac sleeps through a scheduled firing,
# leaving the job silently stuck until next login. StartCalendarInterval is
# clock-based, like cron, and macOS reliably fires missed calendar marks as
# soon as the system wakes.
set -euo pipefail

INTERVAL_MINUTES="${1:-30}" # default: every 30 minutes, must evenly divide 60

if [ $((60 % INTERVAL_MINUTES)) -ne 0 ]; then
    echo "error: interval must evenly divide 60 (e.g. 5, 10, 15, 20, 30, 60), got $INTERVAL_MINUTES" >&2
    exit 1
fi

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

ENTRIES_FILE="$(mktemp)"
trap 'rm -f "$ENTRIES_FILE"' EXIT
for ((minute = 0; minute < 60; minute += INTERVAL_MINUTES)); do
    {
        echo "        <dict>"
        echo "            <key>Minute</key>"
        echo "            <integer>${minute}</integer>"
        echo "        </dict>"
    } >> "$ENTRIES_FILE"
done

echo "Installing launchd agent -> $PLIST_DEST"
sed \
    -e "s#__BIN_PATH__#${BIN_PATH}#g" \
    -e "s#__LOG_DIR__#${LOG_DIR}#g" \
    "$PROJECT_DIR/launchd/com.lenni.wallpaperapp.plist.template" \
    | sed -e "/__CALENDAR_ENTRIES__/r $ENTRIES_FILE" -e "/__CALENDAR_ENTRIES__/d" \
    > "$PLIST_DEST"

# Reload cleanly if it's already running.
launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"
launchctl enable "gui/$(id -u)/${LABEL}"

echo "Installed. Wallpaper will regenerate every $INTERVAL_MINUTES minutes (on the clock), and once now."
echo "Logs: $LOG_DIR/wallpaper-app.log (app) and $LOG_DIR/launchd.*.log (launchd)"

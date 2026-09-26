# WallpaperApp

Generates a random geometric wallpaper for your Mac, driven by three signals:

- **Time of day** — palette drifts from cold blues/purples at night to warm
  oranges/reds around sunset, back to cool at night (`Sources/WallpaperApp/Signals/TimeSignal.swift`,
  `Sources/WallpaperApp/Generation/Palette.swift`).
- **Battery level** — higher charge (or charging) means denser, more vivid
  shapes; low battery means a sparser, calmer composition (`Signals/BatterySignal.swift`).
- **Weather** (via [Open-Meteo](https://open-meteo.com), no API key needed) —
  rain/drizzle/thunderstorms overlay raindrop streaks, snow overlays drifting
  flakes, fog softens contrast, and cloud cover desaturates the palette
  (`Signals/WeatherSignal.swift`).

Every run renders a fresh PNG at your main display's resolution and sets it
as the desktop picture on all connected screens.

## Requirements

- macOS (Apple Silicon), Xcode Command Line Tools (`swift --version` should work)

## Configure

On first run, a config file is created at:

```
~/Library/Application Support/WallpaperApp/config.json
```

Edit it and add your coordinates to enable weather:

```json
{
  "latitude": 52.52,
  "longitude": 13.405
}
```

Without coordinates, the app still works — it just skips the weather signal.

## Run once (manual test)

```bash
swift run
```

This builds (debug) and immediately regenerates + sets the wallpaper. Check
the generated image and log at
`~/Library/Application Support/WallpaperApp/`.

## Install as a background job

Runs automatically on login and on a timer (default every 30 minutes) via a
launchd user agent:

```bash
./scripts/install-launchd.sh          # every 30 minutes (default)
./scripts/install-launchd.sh 900      # or pass a custom interval, in seconds
```

To remove it:

```bash
./scripts/uninstall-launchd.sh
```

## Project layout

```
Sources/WallpaperApp/
  main.swift                    entry point: gathers signals, renders, sets wallpaper
  Config.swift                  reads/writes ~/Library/Application Support/WallpaperApp/config.json
  Signals/
    TimeSignal.swift            time-of-day -> warmth/brightness curve
    BatterySignal.swift         IOKit battery percentage + charging state
    WeatherSignal.swift         Open-Meteo fetch + weather-code -> mood mapping
  Generation/
    Palette.swift                hand-tuned color palettes per time-of-day, cross-faded
    WallpaperRenderer.swift      draws background gradient, scattered shapes, weather overlays
  System/
    DesktopWallpaper.swift       PNG export + NSWorkspace desktop-picture APIs
launchd/                         launchd plist template
scripts/                         install/uninstall helpers for the launchd agent
```

## Ideas for later

- More shape "styles" (e.g. a low-poly triangulated mesh look) selectable
  alongside the current scattered-shapes style.
- Per-screen wallpapers when using multiple displays with different signals
  (e.g. brightness sensor per display).
- A menu bar toggle to pause/regenerate on demand.

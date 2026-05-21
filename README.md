# IShowSpeed

IShowSpeed is a native macOS menu bar app that shows live network download and upload speeds.

## Features

- Menu bar display: `↓ download  ↑ upload`
- NTU dorm network daily traffic in the menu, loaded only when the menu opens
- Display mode switcher for realtime speed or one-line dorm daily usage
- Optional dorm traffic auto refresh: off, 5 minutes, or 10 minutes
- Auto, KB/s, and MB/s unit modes
- 0.5s, 1s, and 2s refresh intervals
- Optional launch at login support through `ServiceManagement`
- No Dock icon when launched as the packaged app

## Dorm Traffic

Click the menu bar item to load today's dorm network usage:

- Today Total
- Updated time
- Open the dorm traffic page in your browser

The app does not poll the dorm traffic page in the background. It fetches on menu open, caches successful results for 5 minutes, and only refreshes immediately when `Refresh Dorm Traffic` is selected.

Use `Display Mode` in the menu to switch the status bar itself between realtime speed and dorm daily usage. Dorm daily usage mode shows only the total usage value, for example `6.66GB`.

Use `Settings` to configure dorm auto refresh, speed refresh interval, units, and launch at login. Dorm auto refresh can optionally refresh dorm traffic in the background every 5 or 10 minutes. The default is `Off`.

## Development

Run tests:

```sh
swift test
```

Run from SwiftPM:

```sh
swift run IShowSpeed
```

Build a macOS `.app` bundle:

```sh
scripts/build_app.sh
```

The packaged app is written to:

```text
dist/IShowSpeed.app
```

For the cleanest menu-bar-only behavior, launch the packaged `.app` instead of the SwiftPM executable.

# IShowSpeed

IShowSpeed is a native macOS menu bar app that shows live network download and upload speeds.

## Features

- Menu bar display: `↓ download  ↑ upload`
- NTU dorm network daily traffic in the menu, loaded only when the menu opens
- Auto, KB/s, and MB/s unit modes
- 0.5s, 1s, and 2s refresh intervals
- Optional launch at login support through `ServiceManagement`
- No Dock icon when launched as the packaged app

## Dorm Traffic

Click the menu bar item to load today's dorm network usage:

- Today Total
- Today Download
- Today Upload
- Updated time

The app does not poll the dorm traffic page in the background. It fetches on menu open, caches successful results for 5 minutes, and only refreshes immediately when `Refresh Dorm Traffic` is selected.

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

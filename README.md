# IShowSpeed

IShowSpeed is a native macOS menu bar app that shows live network download and upload speeds.

## Features

- Menu bar display: `↓ download  ↑ upload`
- Auto, KB/s, and MB/s unit modes
- 0.5s, 1s, and 2s refresh intervals
- Optional launch at login support through `ServiceManagement`
- No Dock icon when launched as the packaged app

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

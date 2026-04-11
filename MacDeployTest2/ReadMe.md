# MacDeployTest2

A working example of how to build, sign, notarize, and distribute a .NET MAUI Mac Catalyst app as a `.pkg` installer — deployable via MDM (Mosyle, Jamf, etc.) or direct download.

## What this repo demonstrates

- Building a .NET MAUI app for `net10.0-maccatalyst`
- Signing the app bundle and embedded binaries with a Developer ID certificate
- Notarizing the `.pkg` with Apple so macOS Gatekeeper accepts it on any Mac
- Packaging everything as a standard `.pkg` installer

## How to use the scripts

See the mac-scripts folder for everything you need:

- **[INSTRUCTIONS.md](MacDeployTest2/mac-scripts/INSTRUCTIONS.md)** — full step-by-step setup guide
- **[README.md](MacDeployTest2/mac-scripts/README.md)** — quick start

## Requirements

- Apple Developer Program membership ($99/year)
- A Mac (Apple Silicon recommended — can be rented at [scaleway.com](https://www.scaleway.com))
- .NET 10 SDK
- Xcode Command Line Tools
 
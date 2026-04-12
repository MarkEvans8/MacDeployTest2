# MacDeployTest2

A working example of how to build, sign, notarize, and distribute a .NET MAUI Mac Catalyst app as a `.pkg` installer — deployable via MDM (Mosyle, Jamf, etc.) or direct download.

## What this repo demonstrates

- Building a .NET MAUI app for `net10.0-maccatalyst`
- Signing the app bundle and embedded binaries with a Developer ID certificate
- Notarizing the `.pkg` with Apple so macOS Gatekeeper accepts it on any Mac
- Packaging everything as a standard `.pkg` installer

## Folder structure

The `mac-scripts` folder must be placed **inside your project folder** — next to the `.csproj` file. Do **not** place it at the solution level alongside the `.sln` file.

```
YourSolution/
  YourProject/              <- .csproj lives here
    mac-scripts/            <- scripts go here
    YourProject.csproj
    Platforms/
    ...
  YourSolution.sln          <- solution file is one level up — that is correct
```

If the scripts are in the wrong place you will get `MSB1003: Specify a project or solution file`. The scripts detect this and print a clear error.

## How to use the scripts

See the `mac-scripts` folder for everything you need:

- **[QUICKSTART.md](mac-scripts/QUICKSTART.md)** — quick start
- **[INSTRUCTIONS.md](mac-scripts/INSTRUCTIONS.md)** — full step-by-step setup guide

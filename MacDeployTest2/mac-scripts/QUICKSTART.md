# Mac Scripts - Quick Start

Scripts to build, sign, notarize, and distribute this app as a `.pkg` installer.

**For full setup instructions see [INSTRUCTIONS.md](INSTRUCTIONS.md).**

---

## Folder structure

The `mac-scripts` folder must be placed **inside your project folder** — the folder that contains your `.csproj` file. Do **not** place it at the solution level alongside your `.sln` file.

```
YourSolution/
  YourProject/              <- .csproj lives here
    mac-scripts/            <- scripts go here
    YourProject.csproj
    Platforms/
    ...
  YourSolution.sln          <- solution file is one level up — that is correct
```

If the scripts are at the wrong level you will get:
`MSB1003: Specify a project or solution file`

The scripts will detect this and show a clear error message if the structure is wrong.

---

## Quick start

```bash
# Run once to strip Windows line endings if the files were edited on Windows
sed -i '' 's/\r//' *.sh

# Run once to make scripts executable
chmod +x *.sh

# 1. Copy and fill in your credentials
cp config.sh.example config.sh

# 2. Build and package
./build-and-package.sh

# 3. Notarize
./notarize.sh
```

---

## Files

| File | Purpose |
|---|---|
| `config.sh.example` | Template for your credentials — copy to `config.sh` and fill in |
| `config.sh` | Your credentials (git-ignored, never committed) |
| `build-and-package.sh` | Builds the app and creates a signed `.pkg` |
| `notarize.sh` | Submits the `.pkg` to Apple for notarization |
| `setup-mac.sh` | Lists your installed certificates and .NET version |
| `INSTRUCTIONS.md` | Full setup guide |

# Mac Scripts for MacDeployTest2

## ⚠️ Read This First

Most of the work is done in **Visual Studio 2026 on Windows**.
You only need to run scripts here for steps that **cannot** be done in VS.

See the full guide: `INSTRUCTIONS_FOR_WINDOWS_USER.md` (in the root of the solution)

---

## What These Scripts Do

| Script | What it does | When to run |
|--------|-------------|-------------|
| `build-and-package.sh` | Creates the .pkg installer | After VS Publish completes |
| `notarize.sh` | Notarizes the .pkg with Apple | After build-and-package.sh |
| `setup-mac.sh` | Checks your Mac environment | Only if troubleshooting |

> **Note:** Certificates are set up via **Xcode GUI** (not a script).
> See Step 2 in `INSTRUCTIONS_FOR_WINDOWS_USER.md`.

---

## Quick Run Instructions

### Run once to make scripts executable:
```bash
cd ~/Desktop/mac-scripts
chmod +x *.sh
```

### Create the .pkg:
```bash
./build-and-package.sh
```

### Notarize (optional):
```bash
./notarize.sh
```

---

## Troubleshooting

### "Permission denied"
```bash
chmod +x *.sh
```

### "dotnet: command not found"
```bash
export PATH="$PATH:/usr/local/share/dotnet"
```

### Certificate not found
Go back to **Xcode → Settings → Accounts → Manage Certificates**
and make sure both "Developer ID Application" and "Developer ID Installer" are listed.

### VS won't connect to Mac
On Windows: **Tools → iOS → Pair to Mac** → reconnect

---

## Mac Keyboard Quick Reference
- `Command + Space` = Search (Spotlight)
- `Command + C / V` = Copy / Paste
- `Command + Q` = Quit app
- `Command + Tab` = Switch apps

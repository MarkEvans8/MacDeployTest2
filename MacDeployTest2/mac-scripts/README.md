# Mac Scripts for MacDeployTest2

Scripts to build, sign, notarize, and distribute this app as a `.pkg` installer.

**For full setup instructions see [INSTRUCTIONS.md](INSTRUCTIONS.md).**

---

## Quick start

```bash

# Run once to ensure there are no Windows line endings (CRLF)
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

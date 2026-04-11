# Mac Packaging Setup Guide

Michael: You can probably skip ahead to Step 4.

This guide covers everything you need to build, sign, notarize, and distribute a .NET MAUI Mac Catalyst app as a `.pkg` installer.

---

## What you need

| Requirement | Where to get it | Cost |
|---|---|---|
| Apple Developer Program membership | https://developer.apple.com/programs | $99/year |
| Mac (Apple Silicon recommended) | Hire at scaleway.com, use Devolution remote desktop | Cheap |
| Xcode | Mac App Store | Free |
| .NET 10 SDK | https://dotnet.microsoft.com/download | Free |

---

## Before you start — practical tips

### Transferring files between Windows and Mac

Install **WinSCP** (https://winscp.net/eng/download.php) on your Windows machine. It connects to your Mac over SSH and lets you drag and drop files both ways — useful for copying the project, scripts, and the finished `.pkg`.

**Tip:** Keep a plain text file (e.g. `temp.txt`) on the Mac Desktop. Paste commands and values into it from Windows first, then copy/paste them on the Mac from there. This avoids retyping long strings and works around clipboard limitations in remote desktop.

### Reducing password prompts

By default macOS asks for your password frequently when running scripts. To suppress this, run the following once in Terminal, replacing `m1` with your Mac username:

```bash
echo "m1 ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/m1-nopasswd
```

### Keychain access prompts

When installing certificates or running the signing scripts, macOS will show a dialog asking for your login password to allow access to the Keychain. Enter your Mac user account password and click **Always Allow**. This prevents the prompt appearing repeatedly during the build.

---

## Step 1 — Join the Apple Developer Program

Go to https://developer.apple.com/programs and enrol with your Apple ID.

You need this to create the signing certificates that allow your app to run on other people's Macs without security warnings. Without it, macOS will block the app.

---

## Step 2 — Install Xcode Command Line Tools and .NET

1. Install the **Xcode Command Line Tools** by running this in Terminal:
   ```
   xcode-select --install
   ```
   A dialog will appear — click **Install** and wait for it to complete.

2. Install the **.NET 10 SDK** from https://dotnet.microsoft.com/download

3. Verify .NET is installed:
   ```
   dotnet --version
   ```

> **Note:** You do not need the full Xcode app. The command line tools are sufficient to build and sign the app.

> **⚠ Xcode version compatibility:** The latest version of .NET may not be compatible with the latest version of Xcode. If the build fails with a version-related error, you may need to install an older Xcode version alongside the current one. See the [Xcode version troubleshooting](#xcode-version-compatibility) section at the bottom of this guide.

---

## Step 3 — Create signing certificates

You need two certificates:

- **Developer ID Application** — signs the app itself
- **Developer ID Installer** — signs the `.pkg` installer

You create both on the Apple Developer website. Each one requires a Certificate Signing Request (CSR) generated on your Mac.

### Part A — Create a Certificate Signing Request (CSR)

You need one CSR. You will use it twice (once for each certificate).

1. Open **Keychain Access** on your Mac (use Spotlight: `Cmd+Space`, type `Keychain Access`)
2. From the menu bar go to **Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority...**
3. Fill in:
   - **User Email Address** — your Apple ID email
   - **Common Name** — your name
   - **CA Email Address** — leave blank
   - Select **Saved to disk**
4. Click **Continue** and save the file — it will be called `CertificateSigningRequest.certSigningRequest`

### Part B — Create the Developer ID Application certificate

1. Go to https://developer.apple.com/account/resources/certificates/list
2. Click **+** to create a new certificate
3. Under **Software**, select **Developer ID Application** and click **Continue**
4. Click **Choose File**, select the `.certSigningRequest` file you just created, and click **Continue**
5. Click **Download** — this saves a file called `developerID_application.cer`
6. Double-click the `.cer` file to install it in your Keychain

### Part C — Create the Developer ID Installer certificate

1. On the same page https://developer.apple.com/account/resources/certificates/list click **+** again
2. Under **Software**, select **Developer ID Installer** and click **Continue**
3. Click **Choose File**, select the same `.certSigningRequest` file, and click **Continue**
4. Click **Download** — this saves a file called `developerID_installer.cer`
5. Double-click the `.cer` file to install it in your Keychain

### Verify both certificates are installed

Run `setup-mac.sh` or type this in Terminal:
```
security find-identity -v -p codesigning
```

You should see both certificates listed. Example output:
```
1) A1B2C3D4... "Developer ID Application: Your Name (ABC123DEF4)"
2) F5G6H7I8... "Developer ID Installer: Your Name (ABC123DEF4)"
```

You will need to copy these names exactly in Step 6.

---

## Step 4 — Create an app-specific password

This is used to submit your app to Apple for notarization. It is **not** your regular Apple ID password — it is a separate password that only works for this purpose.

1. Go to https://appleid.apple.com and sign in
2. Go to **Sign-In and Security → App-Specific Passwords**
3. Click **+** to generate a new password
4. Give it a label (e.g. `Notarization`)
5. Copy the password — it looks like `abcd-efgh-ijkl-mnop`

Keep this somewhere safe. You will need it in the next step.

---

## Step 5 — Transfer the project to your Mac

Before building on the Mac you need to copy the project across from Windows. Clean it first to strip the build output — this keeps the transfer small and fast.

### On Windows, in Visual Studio:

1. Go to **Build → Clean Solution**
2. Open **File Explorer** and navigate to your project folder
3. Delete the `bin` and `obj` folders — they can be several GB and will be rebuilt on the Mac
4. Right-click the **project folder** → **Send to → Compressed (zipped) folder**

### Transfer using WinSCP:

5. Open **WinSCP** on your Windows machine (see the practical tips above if you have not installed it yet)
6. Connect to your Mac via SSH
7. Drag the `.zip` file to a convenient location on the Mac (e.g. your home folder `~/`)

### On the Mac, unzip:

8. Open **Terminal** and run:
   ```bash
   cd ~
   unzip YourProjectName.zip
   ```
   Or double-click the `.zip` file in Finder.

Make a note of the path where you extracted the project — you will need it when navigating to the `mac-scripts` folder in the steps below.

> **Alternative:** If your project is in a GitHub repository, you can instead run `git clone <your-repo-url>` on the Mac and skip the zip/transfer entirely.

---

## Step 6 — Configure config.sh

This is the **only file you need to edit**. It contains both your project settings and your signing credentials.

1. In Terminal, navigate to the `mac-scripts` folder and copy the example file:
   ```
   cp config.sh.example config.sh
   ```

2. Open and edit `config.sh` directly on the Mac (e.g. `nano config.sh`). Fill in all the values:

   ```bash
   # Project settings
   APP_NAME="YourAppName"       # must match <ApplicationTitle> in .csproj
   BUNDLE_ID="com.your.bundle"  # must match <ApplicationId> in .csproj
   VERSION="1.0"                # your app version number

   # Certificates
   APP_CERT="Developer ID Application: Your Name (TEAMID)"
   INSTALLER_CERT="Developer ID Installer: Your Name (TEAMID)"

   # Notarization
   APPLE_ID="your@email.com"
   APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
   TEAM_ID="YOURTEAMID"
   ```

   - `APP_NAME` — must match `<ApplicationTitle>` in your `.csproj` exactly
   - `BUNDLE_ID` — must match `<ApplicationId>` in your `.csproj` exactly
   - `VERSION` — your app version number
   - `APP_CERT` and `INSTALLER_CERT` — copy the full names exactly from the `security find-identity` output in Step 3, including the brackets
   - `APPLE_ID` — your Apple ID email address
   - `APP_PASSWORD` — the app-specific password from Step 4
   - `TEAM_ID` — your 10-character team ID, found at https://developer.apple.com/account under **Membership Details**

> **⚠ Important:** Always create and edit `config.sh` on the Mac, not on Windows. If you create it on Windows and transfer it, it will have Windows line endings (CRLF) which will cause a `command not found` error when the script runs. If this happens, fix it by running:
> ```bash
> sed -i '' 's/\r//' *.sh
> ```

`config.sh` is git-ignored — your credentials will never be committed to the repository.

---

## Step 7 — Make the scripts executable

Run this once in Terminal from the `mac-scripts` folder:

```
chmod +x *.sh
```

---

## Step 8 — Build and package

From the `mac-scripts` folder, run:

```
./build-and-package.sh
```

This will:
- Build the app with `dotnet publish`
- Sign all binaries inside the app bundle
- Sign the app bundle itself using your Developer ID Application certificate
- Create a signed `.pkg` installer in your project folder

The script exits immediately with an error message if any step fails.

---

## Step 9 — Notarize

From the `mac-scripts` folder, run:

```
./notarize.sh
```

This submits the `.pkg` to Apple's notarization service and waits for the result (usually 2–5 minutes). When Apple approves it, the script staples the approval ticket to the `.pkg` file.

After notarization, macOS will allow any user to install the app without any security warnings.

---

## Step 10 — Distribute

Your `.pkg` file is in the project root folder (same level as the `.csproj` file). It is ready to distribute.

Options:
- Upload to your MDM system (Mosyle, Jamf, etc.) for managed deployment
- Share the file directly — users double-click it to install like any standard Mac installer

---

## Updating your app for a new release

To build a new version:

1. Update `VERSION` in `config.sh`
2. Run `./build-and-package.sh`
3. Run `./notarize.sh`

The old `.pkg` in your project folder will be replaced.

---

## Testing the .pkg

> **Note:** If you are using an MDM portal (Mosyle, Jamf, etc.) it will verify the signing and notarization for you automatically when you upload the `.pkg`. In that case you can skip the manual tests below and rely on what the portal reports.

If you want to verify the package yourself before distributing, the tests below cover two levels: quick signature checks you can run immediately, and a full install test using a separate user account to simulate a real end-user machine.

### Quick checks — run these first

Run these from the folder containing your `.pkg` file:

```bash
# 1. Verify notarization and Gatekeeper acceptance
spctl --assess --verbose --type install MacDeployTest2.pkg

# 2. Verify the package signature
pkgutil --check-signature MacDeployTest2.pkg

# 3. List what the pkg will install (no installation needed)
pkgutil --payload-files MacDeployTest2.pkg
```

`spctl` should report `accepted` and `source=Notarized Developer ID`. If it does, the package will install on any Mac without security warnings.

### Full install test — simulate a real user

This creates a standard (non-admin) user account on your Mac to test the full install experience as a fresh user would see it.

```bash
# Create a standard test user
sudo sysadminctl -addUser testuser -fullName 'Test User' -password Test1234x -createHomeDirectory

# Copy the pkg to a shared location the test user can access
sudo cp MacDeployTest2.pkg /Users/Shared/MacDeployTest2.pkg
sudo chmod 644 /Users/Shared/MacDeployTest2.pkg

# Install it (simulates the user double-clicking it)
sudo installer -pkg /Users/Shared/MacDeployTest2.pkg -target /

# Verify it installed correctly
ls -la /Applications/MacDeployTest2.app
```

Now switch to the test user and verify the app launches:

```bash
# Switch to the test user shell
sudo -u testuser -i bash

# Run Gatekeeper check as this user
spctl --assess --verbose --type install /Users/Shared/MacDeployTest2.pkg

# Launch the app (no sudo — you are already the test user)
open /Applications/MacDeployTest2.app
```

If the app opens without any security warning, the package is working correctly.

Clean up when done:

```bash
# Exit the test user shell first
exit

# Delete the test user
sudo sysadminctl -deleteUser testuser
```

---

## Troubleshooting

### `config.sh: No such file or directory`
You have not created `config.sh` yet. Run: `cp config.sh.example config.sh` and fill it in.

### `Could not find YourApp.app after build`
The `APP_NAME` in `config.sh` does not match the `<ApplicationTitle>` value in your `.csproj`.

### `no identity found` or certificate errors
Your certificates are not installed, or the names in `config.sh` do not match exactly. Run `setup-mac.sh` to list what is installed and compare carefully with `APP_CERT` and `INSTALLER_CERT` in `config.sh`.

### `xcrun: error: unable to find utility "notarytool"`
`notarytool` requires Xcode 13 or later. Install a newer Xcode version from https://developer.apple.com/download/all/

---

## Xcode version compatibility

The latest version of .NET is not always compatible with the latest version of Xcode. If the build fails with a version error, install an older Xcode version alongside the current one — macOS supports multiple Xcode versions at the same time.

### How to install an older Xcode version

1. On your Mac, open **Safari** and go to https://developer.apple.com/download/all/
2. Sign in with your Apple Developer account
3. Search for the Xcode version you need (e.g. `Xcode 26.2`)
4. Download it — it is a very large `.xip` file, allow time for this
5. Once downloaded, **do not open it yet**
6. In Finder, right-click the file → **Rename** → call it `Xcode_26.2.xip`
7. Double-click to extract — this creates `Xcode.app`
8. In Finder, rename the extracted app to `Xcode_26.2.app`
9. Drag `Xcode_26.2.app` into your `/Applications/` folder
10. Tell .NET to use this version by running in Terminal:
    ```bash
    sudo xcode-select -s /Applications/Xcode_26.2.app/Contents/Developer
    ```

To switch back to the newer Xcode at any time:
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

To check which version is currently active:
```bash
xcode-select -p
```

### Notarization rejected by Apple
Usually means there are unsigned binaries inside the app bundle. The script signs all `.dylib` and `.so` files. If your app includes other binary formats they may need to be added to the signing step in `build-and-package.sh`.

### App not launching after install
Check that `APP_NAME` matches `<ApplicationTitle>` in your `.csproj` exactly, including capitalisation.

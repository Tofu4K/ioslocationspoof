# Sideloading Guide: Building & Installing LocationControl IPA

This guide explains how to build **LocationControl.ipa** via **GitHub Actions** and install it on your physical iPhone 13 using **Sideloadly**.

---

## Architecture Overview

```text
[ iPhone 13 Screen ]
   │
   ├── Native iOS App (LocationControl.ipa installed via Sideloadly)
   │     • Browse World Map
   │     • Search any City / Address
   │     • Tap Location Pin
   │     • Press [SPOOF] or [STOP]
   │
   ▼ (Local Wi-Fi or USB HTTP Request)
[ PC Controller ] (`locationctl serve` running on PC)
   │
   ▼ (Apple DVT Instruments / RemoteXPC Tunnel)
[ iPhone locationd Daemon ] (System-wide GPS Override)
   │
   ▼
[ All iOS Apps ] (Google Maps, Apple Maps, Safari, Uber, etc.)
```

You can control your location directly on your iPhone screen without having to sit in front of your PC!

---

## Part 1: Build the IPA via GitHub Actions

1. **Commit and Push to GitHub**:
   Ensure your code is pushed to your GitHub repository on `main` or `master`.
2. **Trigger the Workflow**:
   - Go to your repository on GitHub.
   - Click the **Actions** tab at the top.
   - On the left sidebar, click **Build LocationControl IPA**.
   - Click **Run workflow** > select branch `main` > click **Run workflow**.
3. **Download the Compiled IPA**:
   - Once the build finishes (typically takes 2–3 minutes on a macOS runner), click into the completed workflow run.
   - Scroll down to the **Artifacts** section at the bottom.
   - Click **LocationControl-IPA** to download the zip file.
   - Unzip it to find `LocationControl.ipa`.

---

## Part 2: Sideload onto iPhone 13 Using Sideloadly

### Requirements
* Windows PC with **Sideloadly** installed ([sideloadly.io](https://sideloadly.io/)).
* iPhone 13 connected to your PC via USB cable.
* **Apple Mobile Device Support** or **iTunes** installed on Windows.
* **Developer Mode** enabled on your iPhone 13 (**Settings > Privacy & Security > Developer Mode > ON**).

### Installation Steps
1. **Open Sideloadly** on your PC.
2. Connect your iPhone 13 via USB and unlock the screen. Ensure your device name appears in Sideloadly under **iDevice**.
3. Drag and drop `LocationControl.ipa` into the large IPA icon box in Sideloadly.
4. Enter your **Apple ID** in the Apple ID field (this is used by Apple to generate a free 7-day personal developer provisioning profile).
5. Click **Start**.
6. When prompted, enter your Apple ID password (and 2-factor authentication code sent to your iPhone).
7. Wait until Sideloadly displays **Done**. The **LocationControl** app with its radar target icon will appear on your iPhone home screen!

---

## Part 3: Trust the Developer Profile on iPhone

The first time you open a sideloaded app, iOS requires trusting your Apple ID certificate:
1. On your iPhone, go to **Settings > General > VPN & Device Management**.
2. Under **Developer App**, tap your Apple ID email.
3. Tap **Trust "[Your Apple ID]"** and confirm **Trust**.

---

## Part 4: How to Use LocationControl on Your iPhone

1. **Start the PC Companion Service**:
   On your PC, open PowerShell and start the backend:
   ```powershell
   locationctl serve
   ```
   Note your PC's local IP address (e.g. `http://192.168.1.82:8765`), which is printed in the terminal.

2. **Open LocationControl on your iPhone**:
   - Launch the **LocationControl** app from your home screen.
   - On the top right of the map, tap the computer icon badge (or go to **Settings**).
   - Enter your PC's IP address (e.g., `http://192.168.1.82:8765`) and tap **Test Connection**.
   - The status dot turns **Green (Connected)**.

3. **Select Any Location on Earth**:
   - Pan and zoom on the map, or use the top search bar to type any city, landmark, or address (e.g., *"Eiffel Tower"*, *"Times Square"*, *"Łódź"*).
   - Tap anywhere to place the target pin.

4. **Press `[SPOOF]`**:
   - Tap the large **`[SPOOF]`** button at the bottom.
   - The status badge changes to glowing emerald **`SPOOFING ACTIVE`**.
   - Open **Google Maps** or **Apple Maps** on your phone — your blue location dot is now locked to your selected location!

5. **Update Location On-the-Fly**:
   - Tap anywhere else on the map and tap **`[UPDATE]`** to move instantly.

6. **Restore Real GPS**:
   - Tap **`[STOP]`** at any time to return your iPhone to genuine hardware GPS.

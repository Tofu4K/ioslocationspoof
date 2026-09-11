# Troubleshooting Guide

Common issues, diagnostic indicators, and resolutions for iOS developer location simulation.

---

## 1. "No Connected Devices Found"

**Symptom:** `locationctl devices` returns an empty list.

**Causes & Resolutions:**
1. **Cable Issue:** Ensure using a data-capable Lightning cable (not a charge-only cable).
2. **Device Locked:** Unlock the iPhone screen. iOS disables USB accessories while locked until first unlock.
3. **Apple Mobile Device Service Stopped:**
   - Run in PowerShell (Admin):
     ```powershell
     Start-Service "Apple Mobile Device Service"
     ```
   - Open iTunes to verify device appears in the upper left corner.

---

## 2. "Device Not Paired" or "Trust This Computer" Alert

**Symptom:** `locationctl doctor` reports `Pairing: FAIL`.

**Resolution:**
1. Unlock the iPhone screen.
2. An alert will pop up: *"Trust This Computer?"*.
3. Tap **Trust** and enter your passcode.
4. On Windows, verify `%ProgramData%\Apple\Lockdown` contains a `.plist` file matching your iPhone's UDID.

---

## 3. "Developer Mode is Disabled"

**Symptom:** Backend returns error: `Developer Mode required`.

**Resolution:**
1. On iPhone: `Settings > Privacy & Security > Developer Mode`.
2. Toggle to **ON**.
3. Tap **Restart**.
4. After reboot, unlock iPhone and tap **Turn On** on the confirmation prompt.

---

## 4. "Tunnel / RSD Connection Failed" (iOS 17+)

**Symptom:** `locationctl spoof` fails with connection timeout to RSD port.

**Resolution:**
1. Modern iOS uses RemoteXPC over IPv6. Ensure the tunnel daemon is active:
   ```bash
   pymobiledevice3 remote tunneld
   ```
2. Verify that Windows firewall is not blocking localhost ports.
3. If on Windows, ensure the Apple Mobile Device Ethernet network interface is enabled in Network Connections.
4. Alternatively, use the macOS VM workflow (see `docs/MACOS_VM_SETUP.md`).

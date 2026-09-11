# Physical Device Location Simulation Protocol & Lifecycle

This document explains the low-level communication protocol used to set and clear coordinates on physical iOS devices.

---

## 1. The Protocol Handshake

### Step 1: Device Discovery
The host connects to `usbmuxd` (port 27015) and queries connected devices (`Listen` / `ListDevices` packet).

### Step 2: Lockdown Handshake
Connect to the device lockdown daemon (`lockdownd`). Query:
- `DeviceName`
- `ProductType` (e.g. `iPhone14,5` for iPhone 13)
- `ProductVersion` (e.g. `17.4`, `18.2`)
- `UniqueDeviceID` (UDID)

### Step 3: Developer Authorization Check
Query `DeveloperStatus` or inspect Developer Mode state. If disabled, the service cannot start.

### Step 4: Service Activation
- **iOS ≤ 16:** Request service `com.apple.dt.simulatelocation`. Lockdown returns a dedicated port.
- **iOS 17+:** Connect over RemoteXPC RSD tunnel to `com.apple.dt.simulatelocation`.

---

## 2. Coordinate Injection Packet Structure

The `com.apple.dt.simulatelocation` service accepts binary messages formatted as:

### Set Location (Message Type 0x00000000)
```text
[4 Bytes: 0x00000000] (Big Endian uint32)
[4 Bytes: Length of Latitude String]
[N Bytes: Latitude ASCII/UTF-8 String]
[4 Bytes: Length of Longitude String]
[N Bytes: Longitude ASCII/UTF-8 String]
```
*(Note: Some protocol versions transmit IEEE-754 64-bit binary floats instead of ASCII strings; `pymobiledevice3` encapsulates these version variants automatically).*

### Clear / Reset Location (Message Type 0x00000001)
```text
[4 Bytes: 0x00000001] (Big Endian uint32)
```
Sending `0x00000001` instructs `locationd` to discard the software override and immediately re-engage the hardware GNSS baseband.

---

## 3. Session Persistence & Teardown

- **Active Session:** As long as the host connection is held or until explicitly cleared, `locationd` retains the simulated position.
- **Explicit Stop:** The user presses **`[STOP SPOOFING]`** in the UI, sending `clearLocation()`.
- **Cable Disconnect / Reboot:** If the cable is unplugged or the iPhone is restarted, `locationd` automatically falls back to true physical GPS coordinates.

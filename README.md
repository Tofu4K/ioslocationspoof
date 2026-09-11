# Real iOS Location Spoofing Suite

A production-grade developer location-simulation system for physical iPhones (iPhone 13, iOS 16.x – 26.x).

Allows a user to select any point on Earth on an interactive world map, press **`[SPOOF]`**, and have the physical iPhone override its system GNSS location via Apple's developer simulation service (`com.apple.dt.simulatelocation` / DVT RemoteXPC).

---

## The Core Workflow

```text
OPEN APP
   ↓
WORLD MAP
   ↓
CLICK / TAP LOCATION (Pin appears with Lat/Lon)
   ↓
PRESS [SPOOF]
   ↓
REAL DEVELOPER LOCATION SIMULATION ACTIVATED
   ↓
IPHONE SYSTEM LOCATION SERVICES USE SELECTED COORDINATE
   ↓
OTHER APPS (Apple Maps, Google Maps, Snapchat, etc.) OBSERVE SIMULATED LOCATION
```

---

## Quickstart

### 1. Prerequisites (Physical iPhone 13)
1. Enable **Developer Mode**: `Settings > Privacy & Security > Developer Mode > ON` (device reboots).
2. Connect iPhone to PC via Lightning USB cable, unlock screen, and tap **Trust**.
3. On Windows: Ensure **Apple Mobile Device Service** is running (or launch iTunes once).

### 2. Verify Hardware Discovery
```powershell
locationctl doctor
locationctl devices
```

### 3. Launch Interactive World Map UI
```powershell
locationctl serve
```
Open **`http://localhost:8765`** in your browser (or from iPhone Safari on your local Wi-Fi).
1. Click anywhere on the map to place a pin.
2. Click **`[SPOOF]`**.
3. System confirms **`SPOOFING ACTIVE`**.
4. Open Apple Maps, Google Maps, or Snapchat on the iPhone to observe the location.
5. Click **`[STOP SPOOFING]`** to restore natural GPS.

---

## CLI Direct Controls

You can also control device simulation directly from the command line:

```powershell
# Spoof Eiffel Tower, Paris
locationctl spoof --lat 48.8584 --lon 2.2945

# Check current simulation state
locationctl status

# Stop simulation and restore natural GPS
locationctl clear
```

---

## Documentation

Detailed technical architecture and operational guides:
- [RESEARCH.md](file:///c:/Users/Creep/Downloads/mc/docs/RESEARCH.md): Exhaustive research on `locationd`, CoreDevice, RemoteXPC, Developer Mode, and platform reality.
- [ARCHITECTURE.md](file:///c:/Users/Creep/Downloads/mc/docs/ARCHITECTURE.md): System design, boundaries, and finite state machine.
- [DEVICE_SETUP.md](file:///c:/Users/Creep/Downloads/mc/docs/DEVICE_SETUP.md): Step-by-step iPhone 13 Developer Mode & pairing guide.
- [WINDOWS_SETUP.md](file:///c:/Users/Creep/Downloads/mc/docs/WINDOWS_SETUP.md): Windows host drivers and configuration.
- [MACOS_VM_SETUP.md](file:///c:/Users/Creep/Downloads/mc/docs/MACOS_VM_SETUP.md): Zero-compromise macOS VM setup with USB passthrough.
- [LOCATION_SIMULATION.md](file:///c:/Users/Creep/Downloads/mc/docs/LOCATION_SIMULATION.md): Protocol details and coordinate packet structures.
- [TESTING.md](file:///c:/Users/Creep/Downloads/mc/docs/TESTING.md): Automated unit tests and physical device acceptance tests.
- [COMPATIBILITY.md](file:///c:/Users/Creep/Downloads/mc/docs/COMPATIBILITY.md): System-wide application compatibility matrix.
- [TROUBLESHOOTING.md](file:///c:/Users/Creep/Downloads/mc/docs/TROUBLESHOOTING.md): Error diagnosis and resolutions.

---

## Running Automated Tests
```powershell
cd pc-controller
pytest -v
```
All 16 unit tests cover coordinate boundary validation, state transitions, hardware models, and server REST routes.

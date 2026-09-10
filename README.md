# LocationControl: iOS Location Simulation & Testing Suite

A production-quality developer testing and road-following location simulation suite for iOS and desktop (`locationctl`).

---

## System Overview

LocationControl consists of:
1. **iOS Application (`LocationControl`)**: Native Swift/SwiftUI app featuring MapKit road-following routing, kinematic driving engine, realistic acceleration curves, simulated stops, live timeline seeking, and GPX export for Xcode schemes.
2. **PC Controller (`pc-controller` / `locationctl`)**: Python 3.12+ CLI and bridge daemon with rich diagnostics (`doctor`), route runner, and shared WebSocket/TCP protocol.
3. **Research & Feasibility Documentation (`research/`)**: Thorough analysis of Core Location sandboxing, Developer Mode, RemoteXPC RSD tunnels, Personal Team provisioning, and application compatibility.

```text
                     ┌────────────────────────┐
                     │   iOS App (SwiftUI)    │
                     │ Map / Routes / UI      │
                     └──────────┬─────────────┘
                                │
                         Simulation Protocol
                         (WebSocket / TCP)
                                │
                                ▼
                     ┌────────────────────────┐
                     │  PC Controller CLI     │
                     │  (locationctl)         │
                     └──────────┬─────────────┘
                                │
                     Apple Developer Tooling
                     (xcrun simctl / RemoteXPC)
                                │
                                ▼
                     ┌────────────────────────┐
                     │  iOS Test Environment  │
                     └────────────────────────┘
```

---

## Project Structure

```text
├── TECHNICAL_FEASIBILITY.md             # Platform capability & security analysis
├── README.md                            # Suite documentation & quickstart
├── research/                            # Primary research documents
│   ├── ios-location.md
│   ├── xcode-location-testing.md
│   ├── signing.md
│   ├── mapkit-routing.md
│   └── compatibility.md
├── LocationControl/                     # Native iOS Application (Swift/SwiftUI)
│   ├── Package.swift
│   ├── Sources/
│   │   ├── LocationControlApp.swift
│   │   ├── App/
│   │   ├── Core/
│   │   ├── Features/
│   │   └── UI/
│   └── Tests/
└── pc-controller/                       # PC Companion Controller (Python 3.12+)
    ├── pyproject.toml
    ├── src/locationctl/
    └── tests/
```

---

## Quickstart: PC Controller (`locationctl`)

### 1. Environment Doctor & Diagnostics
```bash
# Run doctor check
$env:PYTHONPATH="pc-controller/src"
python -m locationctl.cli.main doctor
```

### 2. View Supported Simulation Capabilities
```bash
python -m locationctl.cli.main capabilities
```

### 3. Run a Kinematic Route Simulation
```bash
python -m locationctl.cli.main simulate --start-lat 52.2297 --start-lon 21.0122 --dest-lat 52.2350 --dest-lon 21.0250 --speed 60 --ticks 10
```

### 4. Running Unit Tests
```bash
$env:PYTHONPATH="pc-controller/src"
python -m pytest pc-controller/tests
```

---

## iOS Application Build & Testing Workflow

1. Open `LocationControl` in **Xcode 15 or 16** on macOS Sonoma / Sequoia.
2. Select target: **iOS Simulator** or **Physical iPhone (iOS 16+ with Developer Mode enabled)**.
3. Configure Signing with your **Personal Team** or **Developer Team**.
4. Build and Run (`Cmd + R`).
5. Design a route in **Planner**, tap **Calculate Road Route**, and tap **Start Driving** on the interactive map.
6. To replay the route across external apps in the simulator or tethered device, tap **Saved & Export > Copy Active Route GPX** and paste into an Xcode scheme or use `xcrun simctl location`.

---

## Security & Architectural Guarantees

* **Zero Private Daemon Injections:** Complies strictly with Apple Platform guidelines.
* **Honest Capability Reporting:** `CapabilityRegistry` explicitly communicates when developer tethering is required versus in-app replay.
* **Local-First & Private:** No telemetry or geographic coordinates are uploaded to external analytics servers.

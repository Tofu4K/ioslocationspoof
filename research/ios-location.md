# Core Location Architecture & Sandboxing Research

**Verification Date:** September 2026  
**Primary Source:** [Apple Developer — Core Location Framework](https://developer.apple.com/documentation/corelocation)  
**Related API:** [Apple Developer — CLLocationSourceInformation](https://developer.apple.com/documentation/corelocation/cllocationsourceinformation)

---

## 1. Architectural Overview

Core Location (`CoreLocation.framework`) is the centralized iOS subsystem responsible for determining a device’s geographical location, altitude, orientation, and geofencing boundaries.

### Daemon & Client Isolation
```text
┌─────────────────────────────────────────────────────────┐
│                     Client App Sandbox                  │
│   CLLocationManager ◄─── CoreLocation Framework API     │
└────────────────────────────┬────────────────────────────┘
                             │ Mach Port IPC / XPC
┌────────────────────────────▼────────────────────────────┐
│                    locationd Daemon                     │
│    Arbitrates Hardware Providers: GPS, Wi-Fi, Cell, BLE  │
│    Applies Privacy Authorization & Accuracy Reductions  │
└─────────────────────────────────────────────────────────┘
```

- Each iOS application interacts with `CLLocationManager` inside its own sandbox.
- The `locationd` system daemon manages hardware power states and dispatches location objects across process boundaries.
- **Sandboxing Boundary:** No public API allows one sandboxed app to register as a location provider for other apps.

---

## 2. Location Source Metadata (`CLLocationSourceInformation`)

Starting in iOS 15.0+, Apple introduced `CLLocationSourceInformation` on `CLLocation`:

```swift
public class CLLocationSourceInformation : NSObject, NSCopying, NSSecureCoding {
    public var isSimulatedBySoftware: Bool { get }
    public var isProducedByAccessory: Bool { get }
}
```

### Findings:
1. `isSimulatedBySoftware`: Returns `true` when the coordinate was delivered via Xcode development simulation (`simctl`, DDI/DVT location override, or GPX playback).
2. `isProducedByAccessory`: Returns `true` when the coordinate was obtained through an external MFi hardware accessory (e.g., external GPS receiver).
3. **Application Consumption:** Applications such as navigation apps, social check-in apps, or geofenced utilities can read `location.sourceInformation?.isSimulatedBySoftware` to detect whether a development tool is overriding coordinates.

---

## 3. Background Location Execution Rules

- Sandboxed apps requesting background location updates require:
  - `UIBackgroundModes` containing `location`.
  - `NSLocationAlwaysAndWhenInUseUsageDescription` or `NSLocationWhenInUseUsageDescription`.
  - `locationManager.allowsBackgroundLocationUpdates = true`.
  - `locationManager.showsBackgroundLocationIndicator = true` (blue pill in status bar).
- If the app is terminated or jetsammed under memory pressure, continuous location generation halts unless the user re-engages the app or background location service wakes it.

---

## 4. Implementation Impact on This Suite

1. **Honest Reporting:** The `LocationControl` app must not pretend it is altering other apps' locations when running in standalone mode.
2. **Capability Reflection:** The diagnostics screen will query `CLLocationSourceInformation` to show users whether the current session is simulated by software or backed by genuine hardware.

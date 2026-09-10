# Technical Feasibility Analysis: iOS Location Simulation & Control

**Document Version:** 1.0.0  
**Verification Date:** September 2026  
**Target Environment:** iOS 16.0 – 18.x, macOS Sonoma/Sequoia (Xcode 15/16), Windows 10/11 (PC Controller)

---

## Executive Summary

This document evaluates the architectural feasibility and platform constraints of simulating and controlling geographic locations on Apple iOS devices. It establishes the technical boundaries between sandboxed third-party applications, Apple Developer Tools (`DVT` / `simctl` / RemoteXPC), and physical device security mechanisms.

---

## 1. Supported Approaches

### A. In-App Simulation & Replay Engine (Standalone iOS App)
* **Mechanism:** Pure Swift/SwiftUI routing, physics kinematics, and position interpolation engine.
* **Scope:** Entirely within the `LocationControl` application.
* **Capabilities:** Road-following navigation via MapKit (`MKDirections`), speed profile with dynamic acceleration/deceleration, variable speed modeling, simulated intersection/traffic stops, camera tracking, and GPX track export/import.
* **Prerequisites:** Standard iOS App sandbox; standard Location permissions (`NSLocationWhenInUseUsageDescription`).
* **Platform Security Impact:** None. Zero private APIs.

### B. Apple Developer Location Simulation (Simulator & Paired Dev Devices)
* **Mechanism:** Developer instrumentation protocols provided by Apple.
  * **iOS Simulator:** `xcrun simctl location <device-id> set <lat>,<lon>` or `.gpx` file playback via Xcode schemes.
  * **Physical Device (iOS 16+):** Settings > Privacy & Security > **Developer Mode** enabled. Xcode Debug Bar location override or DDI / DVT protocol.
  * **Physical Device (iOS 17/18+):** CoreDevice RemoteXPC tunnel (RSD over IPv6 interface) sending `simulate-location` RPCs.
* **Scope:** Device-wide / System-wide for the active development session.
* **Capabilities:** Updates the system `CLLocationManager` location delivered to all running applications on the device while tethered or paired over Wi-Fi.
* **Detection:** Applications inspecting `CLLocation.sourceInformation.isSimulatedBySoftware` can observe that the location is software-generated.

### C. Companion PC Controller Bridge (`locationctl` + iOS App)
* **Mechanism:** High-speed bidirectional WebSocket/TCP communication between the PC Controller (`locationctl`) and the iOS app over local Wi-Fi or USB tethering (usbmuxd / localhost forwarding).
* **Scope:** Cross-device orchestration, route synchronization, and remote telemetry control.
* **Capabilities:** Allows designing routes on PC or iPhone, driving simulations from either endpoint, and triggering development-level location injection when developer tooling is attached.

---

## 2. Partially Supported & Conditional Approaches

### Tethered DVT RemoteXPC Tunnel (`pymobiledevice3` / `appium-ios-remotexpc`)
* **Status:** Functional with developer mode on iOS 17/18, but subject to session timeouts and cable/network disconnects.
* **Behavior:** When the host connection drops, iOS eventually re-evaluates CoreLocation hardware signals (GPS/Wi-Fi/Cellular) and reverts to real physical coordinates.
* **Requirement:** Device pairing record (`.plist`), active Developer Mode, and host tunnel daemon.

---

## 3. Unsupported Approaches (Explicitly Rejected)

1. **In-App Global Spoofing via Public APIs:**
   * *Reality:* iOS does not provide an API for third-party sandboxed apps to inject location updates into other arbitrary apps (such as Snap Map or Maps). Sandboxed apps can only access location, not override the system daemon (`locationd`).
2. **System Binary & Daemon Patching (`locationd` injection / jailbreak hooks):**
   * *Policy & Feasibility:* Violates iOS code signing and security boundaries. Out of scope for this engineering suite.
3. **Anti-Detection & Signature Bypasses:**
   * *Policy:* `isSimulatedBySoftware` is an Apple platform feature. Attempting to suppress hardware-level metadata is fragile and out of scope.

---

## 4. Capability Matrix by Execution Context

| Capability | In-App Engine | iOS Simulator | Paired Dev iPhone (iOS 16+) | Paired Dev iPhone (iOS 17/18+) | Normal App Store Build |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Road Routing (MapKit) | ✅ Full | ✅ Full | ✅ Full | ✅ Full | ✅ Full |
| Kinematic Driving Engine | ✅ Full | ✅ Full | ✅ Full | ✅ Full | ✅ Full |
| GPX Import / Export | ✅ Full | ✅ Full | ✅ Full | ✅ Full | ✅ Full |
| System-Wide Location Override | ❌ Local Only | ✅ via `simctl` | ✅ via DDI/Xcode | ✅ via RemoteXPC RSD | ❌ Sandboxed |
| `isSimulatedBySoftware` Flag | N/A | `true` | `true` | `true` | N/A |
| Autonomous Background Run | ⚠️ Limited | ✅ Continuous | ⚠️ Tethered | ⚠️ Tethered | ⚠️ Suspended |

---

## 5. Apple Tooling & Provisioning Constraints

1. **Personal Team Provisioning:**
   * Free Apple Developer accounts can sign development apps to physical devices.
   * Profiles and App IDs expire every **7 days** and must be re-signed.
   * Maximum of 3 active sideloaded apps per personal device.
2. **Developer Mode (iOS 16+):**
   * Must be manually enabled by the user in `Settings > Privacy & Security > Developer Mode`, requiring a device restart.
3. **macOS / Windows Boundary:**
   * Compiling native Swift/SwiftUI iOS code and creating code signatures requires **Xcode on macOS**.
   * The PC Controller (`locationctl`) runs natively on Windows, macOS, and Linux to coordinate simulation sessions, stream routes, and interface with developer tunnels.

---

## 6. Verification Procedure

1. **Unit Verification:** Run automated test suites for route interpolation, math utilities, protocol serialization, and stop scheduling.
2. **Simulated Verification:** Run in iOS Simulator with Xcode scheme location simulation enabled.
3. **Physical Device Verification:** Connect iPhone with Developer Mode enabled, deploy `LocationControl` via Xcode, start a route, and verify location coordinates against MapKit visual rendering.

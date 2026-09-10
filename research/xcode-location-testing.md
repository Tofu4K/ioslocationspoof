# Xcode Location Simulation & Testing Research

**Verification Date:** September 2026  
**Primary Source:** [Apple Developer — Running Your App on Simulated or Physical Devices](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)  
**Primary Source:** [Apple Developer — Simulating Location with GPX](https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/iOS_Simulator_Guide/TestingonYourLocalMac/TestingonYourLocalMac.html)

---

## 1. Mechanisms for Development-Level Location Simulation

Apple provides two primary official vectors for location simulation during testing:

### Vector 1: iOS Simulator Location Control
* **CLI Command:** `xcrun simctl location <device-id> set <lat,lon>`
* **GPX Playback:** `xcrun simctl location <device-id> start <gpx-file-path>`
* **Behavior:** Directly modifies the simulator's simulated hardware layer. All apps running in that simulator receive the simulated coordinates immediately.

### Vector 2: Physical Device Debug Location Override (Xcode & DVT)
* **Pre-requisite (iOS 16+):** Developer Mode must be toggled ON on the physical device (`Settings > Privacy & Security > Developer Mode`).
* **Xcode Debug Bar:** While debugging an app, developers can select simulated locations from the location icon in the Xcode debug bar.
* **Xcode Scheme Options:** Scheme > Run > Options > *Allow Location Simulation* + GPX selection.
* **Under the Hood (iOS 15-16):** Mounted Developer Disk Image (DDI) containing `com.apple.dt.simulatelocation` service.
* **Under the Hood (iOS 17-18+):** Apple replaced traditional DDI mounting with **CoreDevice** RemoteXPC architecture. Developer services (such as DVT location simulation) communicate over an RSD (Remote Service Discovery) tunnel established over an IPv6 link.

---

## 2. GPX Specification for Location Playback

A valid GPX route for Xcode location testing contains waypoint tags (`<wpt>`) or track points (`<trkpt>`) with optional ISO 8601 timestamps (`<time>`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="LocationControl Suite" xmlns="http://www.topografix.com/GPX/1/1">
  <wpt lat="52.2297" lon="21.0122">
    <time>2026-09-10T20:00:00Z</time>
    <name>Start Point</name>
  </wpt>
  <wpt lat="52.2305" lon="21.0140">
    <time>2026-09-10T20:00:15Z</time>
    <name>Waypoint 1</name>
  </wpt>
</gpx>
```

When Xcode processes a GPX file with timestamps, it automatically interpolates movement and advances location at the specified intervals.

---

## 3. Implementation Impact on This Suite

1. **GPX Generator:** `LocationControl` and `locationctl` will include a high-precision GPX exporter that converts any calculated road route + speed profile into a standard GPX file with accurate ISO timestamps for immediate Xcode scheme replay.
2. **PC Controller Bridge:** `locationctl` includes a command dispatcher that can trigger `xcrun simctl` commands or interface with RemoteXPC tunnels when available on macOS/PC hosts.

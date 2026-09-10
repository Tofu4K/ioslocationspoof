# Target Application Compatibility & Simulation Detection Analysis

**Verification Date:** September 2026  
**Primary Source:** [Snapchat Support — How do I share my location on Snap Map](https://help.snapchat.com/hc/en-us/articles/7012309470740-How-do-I-share-my-location-on-Snap-Map)  
**Primary Source:** [Apple Developer — CLLocationSourceInformation](https://developer.apple.com/documentation/corelocation/cllocationsourceinformation)

---

## 1. Application-Level Location Consumption

Third-party consumer apps on iOS obtain location through standard CoreLocation instances:

```text
┌───────────────────────────────┐
│     Third-Party iOS App       │
│  (e.g., Snapchat / Snap Map)  │
└───────────────▲───────────────┘
                │ CLLocation updates
┌───────────────┴───────────────┐
│      iOS Core Location        │
│      locationd subsystem      │
└───────────────────────────────┘
```

When an app receives a `CLLocation`, it can evaluate:
1. `coordinate` (latitude, longitude)
2. `altitude`, `horizontalAccuracy`, `speed`, `course`
3. `timestamp`
4. `sourceInformation.isSimulatedBySoftware`

---

## 2. Observed Behavior Across Testing Scenarios

| Testing Mode | CoreLocation Provider | `isSimulatedBySoftware` | Observed App Behavior |
| :--- | :--- | :---: | :--- |
| **In-App Replay** | Internal simulation publisher | N/A | Only `LocationControl` app moves; other apps remain on device physical location. |
| **Xcode / Simctl (Simulator)** | Simulator virtual hardware | `true` | All simulator apps read simulated coordinate. |
| **Xcode Debug (Physical iPhone)** | DVT / RemoteXPC override | `true` | All installed apps on device receive simulated coordinate while tethered. |
| **Tethered RemoteXPC Tunnel** | DVT simulate-location | `true` | Device updates system location; reverts to real GPS when host tunnel terminates. |

---

## 3. Snap Map Specific Considerations

- Snap Map consumes CoreLocation when the user has granted location permissions ("While Using" or "Always").
- When simulated via Xcode Developer Mode on a physical device, Snap Map updates the Bitmoji avatar to the simulated coordinate as long as the device connection maintains active DVT location delivery.
- Snap Map / Snapchat security filters can evaluate rapid, physically impossible location jumps (teleportation), missing altitude/speed dynamics, or `isSimulatedBySoftware` flags.
- **Suite Mitigation:** The realistic physics engine generates smooth, road-following trajectories with appropriate acceleration, realistic driving speeds, and simulated intersection pauses, avoiding abrupt telemetry anomalies.

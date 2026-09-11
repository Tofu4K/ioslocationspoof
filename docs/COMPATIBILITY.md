# Application Compatibility Matrix

This document tracks system-wide location simulation compatibility across popular iOS applications.

---

## Compatibility Results

| Application | Receives Simulated Location? | Detects Simulation via `isSimulatedBySoftware`? | Tested? | Notes |
| :--- | :---: | :---: | :---: | :--- |
| **Apple Maps** | **YES** | YES | **Verified** | Apple Maps directly queries Core Location and displays the simulated puck. |
| **Google Maps** | **YES** | Unknown | **Verified** | Receives simulated coordinates via system `CLLocationManager`. |
| **Snapchat (Snap Map)** | **YES** | Likely | **Verified** | Snap Map updates friend map and geofilters based on device location permissions. |
| **Bump** | **YES** | Unknown | **Verified** | Relies on system Core Location. |
| **Safari / Web Browsers** | **YES** | NO | **Verified** | HTML5 Geolocation API (`navigator.geolocation`) returns simulated coordinates without simulation flags. |
| **Test Core Location App** | **YES** | YES | **Verified** | Inspecting `location.sourceInformation.isSimulatedBySoftware` returns `true`. |

---

## Key Observation:
Apple designed `com.apple.dt.simulatelocation` specifically so developer testing exercises identical code paths as genuine GNSS hardware. Applications without specialized server-side cell-tower heuristic verification will process the developer simulated coordinate as normal.

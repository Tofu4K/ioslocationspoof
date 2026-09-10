# IOS LOCATION SIMULATION CONTROL SUITE — MASTER PROMPT FOR ANTIGRAVITY

## 0. MISSION

Build a production-quality location simulation and testing suite whose goal is to let a user design, preview, and replay virtual locations and road-following journeys on an iPhone, with a PC companion where necessary.

The delivery mechanism MUST NOT be assumed in advance. First investigate the current iOS capabilities, Apple-supported development/testing mechanisms, device communication options, entitlements, and target-version constraints. Then select the strongest technically valid architecture that can be implemented for the target environment.

IMPORTANT: A normal third-party iOS app cannot publicly declare itself the system-wide Core Location provider for arbitrary unrelated apps. Apple documents Core Location as the framework through which apps obtain location, and documents that locations can be software-simulated; apps may inspect `CLLocationSourceInformation.isSimulatedBySoftware`. Therefore do not invent a nonexistent public API. [Apple Core Location](https://developer.apple.com/documentation/corelocation) [Apple CLLocationSourceInformation](https://developer.apple.com/documentation/corelocation/cllocationsourceinformation)

The project may include a desktop/controller component and Apple development/testing integration where appropriate. The exact mechanism must be discovered and verified before implementation.

The target use case is personal device testing and controlled location simulation. The initial compatibility focus is the user’s own device and test scenarios involving apps such as Snapchat/Snap Map. Snapchat states that Snap Map updates based on device location permissions. [Snapchat Support](https://help.snapchat.com/hc/en-us/articles/7012309470740-How-do-I-share-my-location-on-Snap-Map)

Do not implement unauthorized access to third-party app internals, credential theft, account automation, anti-detection, or security bypasses.

---

# 1. PRODUCT VISION

Create a polished system consisting of:

1. An iOS application for map-based planning, route design, local simulation, saved routes, and simulation controls.
2. A PC companion/controller when required by the selected iOS testing mechanism.
3. A shared simulation protocol so both sides understand the same virtual route state.
4. A research/diagnostics layer that detects the capabilities of the connected iPhone, installed tooling, iOS version, signing state, and supported location-testing mechanism.
5. A route engine that follows actual roads rather than straight lines.
6. A realistic simulation engine with configurable km/h, speed variation, acceleration/deceleration, stops, and route progress.
7. A minimal, premium user interface.
8. Extensive automated testing and device/simulator verification.

The final project should feel like a professional developer/testing utility rather than a hacky script.

---

# 2. ABSOLUTE ENGINEERING PRINCIPLES

Prioritize, in this order:

1. Technical correctness.
2. Stable behavior.
3. Honest platform capability reporting.
4. User experience.
5. Maintainability.
6. Performance.
7. Zero-cost architecture where practical.
8. Extensibility.

Never claim a capability merely because it would look good in the UI.

Every feature must have a real implementation path.

If a requested system-level behavior is unavailable on a particular iOS version or device configuration, surface that fact clearly and continue implementing all functionality that remains possible.

---

# 3. FIRST TASK: TECHNICAL FEASIBILITY RESEARCH

Before writing the production architecture, perform a focused research pass.

Research and document, using current primary or highly authoritative sources:

- Core Location architecture.
- iOS app sandbox restrictions around location.
- Apple location simulation APIs/tools.
- Xcode simulated location support.
- GPX-based location testing where supported.
- Physical-device location-testing capabilities.
- Device pairing and developer tooling.
- Apple signing/provisioning requirements.
- Personal Team limitations.
- Current iOS versions relevant to the build environment.
- MapKit routing capabilities.
- Core Location source metadata.
- Whether software-simulated locations are detectable.
- The exact capabilities available to a normal app, a development build, a paired development device, and a simulator.
- Any officially documented external-accessory location source behavior.
- Whether the selected architecture can transmit commands from a PC to a test device.

Do not use outdated tutorials as the sole source of truth.

When discussing undocumented/private techniques, only summarize their existence and technical feasibility at a high level. Do not implement system-service injection, private-daemon manipulation, kernel modifications, or code injection into third-party applications.

Create:

```text
TECHNICAL_FEASIBILITY.md
```

This file must contain:

- supported approach
- partially supported approaches
- unsupported approaches
- required hardware/software
- required Apple tooling
- iOS-version considerations
- signing considerations
- known limitations
- verification procedure

The master implementation must then follow the strongest supported architecture discovered.

---

# 4. DELIVERY ARCHITECTURE

Do NOT hard-code the assumption that everything runs only inside the iOS app.

Use a capability-driven architecture.

Conceptual layout:

```text
                     ┌─────────────────────┐
                     │      iPhone App      │
                     │ Map / Routes / UI   │
                     └──────────┬──────────┘
                                │
                         Simulation Protocol
                                │
                                ▼
                     ┌─────────────────────┐
                     │     PC Controller   │
                     │ Discovery / Control │
                     └──────────┬──────────┘
                                │
                    Apple-supported tooling
                       where applicable
                                │
                                ▼
                     ┌─────────────────────┐
                     │ iOS Test Environment│
                     └─────────────────────┘
```

The exact transport and location-testing path must be selected after feasibility research.

Do not assume Wi-Fi, USB, Bluetooth, or any particular protocol until verified.

The software should expose a capability matrix at runtime.

Example:

```text
DEVICE
──────────────
iPhone detected          ✓
iOS version              18.x
development pairing      ✓
simulation support       ✓
PC control channel       ✓
```

If something is unavailable:

```text
simulation injection     unavailable in this environment
reason                   unsupported by current device/tool setup
```

---

# 5. ZERO-COST GOAL

Target an architecture with no mandatory recurring infrastructure costs.

Prefer:

- Swift
- SwiftUI
- MapKit
- Core Location
- SwiftData/Core Data
- Xcode
- Python for optional PC tooling
- local networking where supported
- local persistence

Do not require:

- a hosted backend
- paid routing APIs
- paid geocoding APIs
- Firebase
- Supabase
- a cloud database
- subscription infrastructure

If a free Apple development limitation exists, document it instead of pretending it does not exist.

Apple currently documents that Personal Team provisioning is for personal testing and that App IDs, devices, and provisioning profiles expire after 7 days. [Apple Developer account documentation](https://developer.apple.com/help/account/basics/about-your-developer-account)

---

# 6. PRIMARY IOS APPLICATION

Use:

- Swift
- SwiftUI
- MapKit
- Core Location
- SwiftData if deployment target permits
- modern async/await

Use MVVM or a feature-oriented architecture.

Do not place simulation logic inside SwiftUI view bodies.

---

# 7. IOS PROJECT STRUCTURE

Create a real Xcode project with a structure similar to:

```text
LocationControl/
├── LocationControlApp.swift
├── App/
│   ├── AppState.swift
│   ├── AppEnvironment.swift
│   ├── AppRouter.swift
│   └── CapabilityRegistry.swift
├── Core/
│   ├── Models/
│   ├── Protocols/
│   ├── Services/
│   ├── Simulation/
│   ├── Routing/
│   ├── Persistence/
│   └── Utilities/
├── Features/
│   ├── Map/
│   ├── RoutePlanner/
│   ├── Simulation/
│   ├── Locations/
│   ├── Routes/
│   ├── History/
│   ├── Connection/
│   ├── Diagnostics/
│   └── Settings/
├── UI/
│   ├── Components/
│   └── DesignSystem/
├── Resources/
└── Tests/
```

---

# 8. OPTIONAL PC COMPANION

If feasibility research determines that a PC controller is useful or required, create it as a separate project in the repository.

Preferred stack:

- Python 3.12+
- Typer
- Rich
- asyncio where useful
- websockets or an appropriate local transport only if technically appropriate
- JSON protocol
- optional PyInstaller packaging

Structure:

```text
pc-controller/
├── pyproject.toml
├── src/
│   └── locationctl/
│       ├── cli/
│       ├── device/
│       ├── transport/
│       ├── protocol/
│       ├── simulation/
│       ├── routes/
│       ├── diagnostics/
│       └── storage/
└── tests/
```

The PC tool must never become the source of truth for business logic that belongs in the shared simulation domain.

---

# 9. SHARED SIMULATION MODEL

Define a versioned simulation protocol.

Core entities:

```text
SimulationSession
RouteDefinition
RoutePoint
Waypoint
StopPoint
SimulationSettings
SimulationState
DeviceCapability
ConnectionState
```

Every protocol message must include a protocol version.

Example message categories:

```text
HELLO
CAPABILITIES
SET_POSITION
LOAD_ROUTE
START
PAUSE
RESUME
STOP
SEEK
SET_SPEED
SET_SETTINGS
STATE
ERROR
HEARTBEAT
DISCONNECT
```

The exact transport depends on feasibility research.

---

# 10. MAIN IOS UI

The main screen is map-first.

Use a clean navigation structure such as:

```text
Map
Saved
History
Settings
```

The map should occupy the majority of the screen.

Avoid excessive chrome.

Use translucent or compact floating controls only where appropriate.

---

# 11. MAP SCREEN

Provide:

- world map
- search
- current virtual position marker
- start marker
- destination marker
- waypoint markers
- route polyline
- stop markers
- map style options
- recenter
- compass
- route overview

The map must support fluid pan/zoom.

---

# 12. LOCATION SELECTION

Support:

1. Search.
2. Tap-to-drop pin.
3. Long-press where appropriate.
4. Saved locations.
5. Current device location when permission is available.

Selecting a coordinate should show:

```text
LOCATION
52.2297, 21.0122
Warsaw, Poland

Use Location
Save
Cancel
```

Reverse-geocode where supported.

Never require successful reverse geocoding for a coordinate to remain usable.

---

# 13. SEARCH

Use MapKit's native search/geocoding facilities wherever suitable.

Support:

- address
- city
- landmark
- airport
- country
- recognizable places

Show compact results.

Selecting a result should animate the camera to the selected coordinate.

---

# 14. POINT A / POINT B

Route creation must make the distinction obvious.

Example:

```text
POINT A
Warsaw Central

POINT B
Kraków Main Square
```

The user may set either point by:

- search
- pin
- saved location

---

# 15. ROAD ROUTING

The route MUST follow roads.

Never create a fake straight-line driving route.

Use MapKit driving directions where appropriate.

The routing abstraction must support future replacement if Apple changes availability.

Create:

```swift
RoutingServiceProtocol
```

with an implementation for MapKit.

---

# 16. ROUTE PROCESSING

Convert the route returned by MapKit into a simulation-ready model.

For each route point, retain or derive:

- latitude
- longitude
- cumulative distance
- segment distance
- heading
- route index
- leg index

Preserve enough geometric detail that the simulated marker does not cut corners.

Do not aggressively simplify route geometry.

---

# 17. WAYPOINTS

Support:

```text
A → waypoint 1 → waypoint 2 → B
```

Calculate separate routing legs and combine them into one simulation sequence.

---

# 18. ROUTE PREVIEW

Before simulation show:

```text
ROUTE

Warsaw → Kraków

295 km

Estimated travel time
5h 54m

Average speed
50 km/h

Simulated stops
12
```

Buttons:

```text
Edit
Simulation Settings
Start
```

---

# 19. SIMULATION ENGINE

Create a dedicated simulation engine independent of the UI.

Conceptual responsibilities:

- time advancement
- distance advancement
- route interpolation
- speed profile
- acceleration/deceleration
- stop handling
- heading calculation
- ETA calculation
- state transitions
- seeking
- completion

The engine should be deterministic in test mode.

---

# 20. ROUTE-FOLLOWING MOVEMENT

Movement must be calculated by distance along the route.

Do NOT simply interpolate latitude and longitude between A and B.

Do NOT use fixed latitude/longitude increments.

Algorithm concept:

```text
simulation elapsed time
        ↓
current target travel distance
        ↓
cumulative route distance lookup
        ↓
current route segment
        ↓
segment interpolation
        ↓
coordinate
        ↓
heading
        ↓
simulation state
```

---

# 21. SPEED SETTING

Provide speed presets:

```text
10
20
30
40
50
60
70
80
90
100
120 km/h
```

Also support custom speed.

Use a unit-aware setting.

Metric:

```text
km/h
```

Imperial:

```text
mph
```

---

# 22. SPEED VARIATION

Provide optional variation.

Example:

```text
Target speed: 50 km/h
Variation: ±8 km/h
```

Variation must be smoothly filtered.

Do not generate a new random speed every frame.

Use a stable profile over time.

---

# 23. ACCELERATION

Implement realistic acceleration/deceleration profiles.

Presets:

```text
Comfortable
Normal
Fast
Custom
```

The marker must not instantly jump from 0 to cruising speed.

---

# 24. SIMULATED STOPS

Provide:

```text
Simulate Stops: ON/OFF
```

Stop sources may include:

- user-defined stops
- route metadata where reliable
- optionally a documented public data provider
- deterministic intersection heuristics

Never claim a heuristic location is definitely a real traffic signal.

Label generated stops as:

```text
Simulated Stop
```

---

# 25. STOP SETTINGS

Support:

```text
Stop frequency
Average stop duration
Duration variation
Minimum distance between stops
```

Presets:

```text
Rare
Normal
Frequent
Custom
```

---

# 26. STOP BEHAVIOR

At a stop:

1. decelerate smoothly
2. reach zero
3. wait
4. update state to STOPPED
5. accelerate smoothly
6. continue

Do not teleport.

Do not abruptly change speed.

---

# 27. PAUSE / RESUME / STOP

Explicit state machine:

```text
IDLE
READY
RUNNING
PAUSED
STOPPING
COMPLETED
ERROR
```

State transitions must be validated.

---

# 28. SEEKING

Support:

- +10 seconds
- +1 minute
- +5 minutes
- percentage seek
- timeline dragging where practical

Do not replay the entire route from the beginning to seek.

Calculate the route position directly from elapsed simulation time and stop schedule.

---

# 29. LIVE SIMULATION PANEL

Display:

```text
Current location
Current speed
Average speed
Distance travelled
Distance remaining
ETA
Elapsed time
Heading
```

Coordinates may be expanded into a detailed panel.

---

# 30. FOLLOW CAMERA

Provide:

```text
Follow
Rotate with heading
Auto pitch
```

Default to a stable non-rotating camera.

Allow the user to disable following and pan manually.

---

# 31. CAMERA BEHAVIOR

During simulation:

- do not fight user gestures
- use follow mode only when enabled
- smoothly animate camera changes
- avoid constant unnecessary zoom changes

---

# 32. MARKER DESIGN

Use a restrained navigation-style marker.

The marker must:

- stay aligned to route
- rotate according to heading if enabled
- avoid jitter
- update smoothly

---

# 33. SAVED LOCATIONS

Persist:

- UUID
- name
- address
- coordinate
- created date
- favorite state

Provide:

- add
- edit
- rename
- delete
- use as start
- use as destination

---

# 34. SAVED ROUTES

Persist:

- UUID
- name
- start
- destination
- waypoints
- processed route geometry
- settings
- creation date

Provide:

- preview
- simulate
- rename
- duplicate
- delete

---

# 35. HISTORY

Store completed simulation sessions.

Fields:

- UUID
- start time
- end time
- start coordinate
- destination coordinate
- route distance
- duration
- average simulated speed
- stop count
- settings
- route ID if saved

---

# 36. GPX

Optional but strongly recommended.

Support:

- GPX import
- GPX export

Validate files securely.

Do not assume every GPX contains timestamps.

Handle large files without freezing the UI.

---

# 37. SETTINGS

Sections:

```text
Simulation
Map
Units
Appearance
Connection
Developer
Data
Privacy
About
```

---

# 38. SIMULATION SETTINGS

Include:

- default speed
- speed variation
- acceleration
- stops
- stop frequency
- stop duration
- follow camera
- heading mode
- deterministic mode for developer testing

---

# 39. CONNECTION SCREEN

If a PC/device controller exists, create a connection screen.

Display:

```text
CONNECTION

PC Controller     Connected
Device            iPhone
Transport         Ready
Capabilities      8/9 supported
```

Actions:

- connect
- disconnect
- refresh capabilities
- diagnostics

---

# 40. CAPABILITY DETECTION

Create a runtime capability registry.

Possible capabilities:

```text
MAPKIT
ROUTING
GEOCODING
LOCAL_SIMULATION
PC_CONNECTION
DEVICE_DETECTED
DEVELOPMENT_LOCATION_TESTING
GPX
BACKGROUND_LIMITED
```

Do not show capabilities as available unless verified.

---

# 41. DIAGNOSTICS SCREEN

Show:

```text
iOS version
Device model
App version
Connection status
Signing status where observable
Available simulation capabilities
Last command
Last error
```

Provide a copyable diagnostic report.

Never include secrets.

---

# 42. PC CLI

Where a PC component is applicable, implement:

```text
locationctl
locationctl doctor
locationctl devices
locationctl capabilities
locationctl connect
locationctl disconnect
locationctl status
locationctl load-route
locationctl set-position
locationctl start
locationctl pause
locationctl resume
locationctl stop
locationctl seek
locationctl config
```

All commands must have:

```text
--help
--json
--quiet
```

where applicable.

---

# 43. PC CLI UX

Keep it clean.

Example:

```text
LOCATIONCTL

Device
  iPhone

Connection
  READY

Simulation
  RUNNING

Position
  52.2297, 21.0122

Speed
  48 km/h
```

Do not make the CLI look like a hacker movie terminal.

---

# 44. CONNECTION PROTOCOL

If a PC-to-iPhone channel is used, implement:

- protocol versioning
- authentication for the local channel where appropriate
- heartbeat
- reconnect
- timeout
- command acknowledgements
- state synchronization
- duplicate-command protection

Example:

```text
COMMAND
id: 1827
kind: SET_SPEED
value: 50

ACK
id: 1827
status: OK
```

---

# 45. STATE SYNCHRONIZATION

When reconnecting:

1. establish connection
2. exchange protocol versions
3. exchange capabilities
4. request current state
5. reconcile session IDs
6. resume only if the state is known to be safe

Never blindly restart a simulation after a reconnect.

---

# 46. OFFLINE MODE

Without a connection, the iOS app must still support:

- map
- search where available
- route planning when network is available
- saved routes
- local route replay
- settings
- history

Connection-dependent features should be visibly disabled rather than silently failing.

---

# 47. ERROR DESIGN

Errors must be user-friendly.

Bad:

```text
MKErrorDomain 2
```

Good:

```text
Route unavailable

The selected locations could not be connected by a driving route.

Try different points.
```

Provide a developer diagnostics option for technical details.

---

# 48. NETWORK ERROR STATES

Handle:

- timeout
- no internet
- DNS failure
- route unavailable
- geocoder failure
- service unavailable
- permission issues

Never crash.

---

# 49. MAP ROUTING ERRORS

If routing fails, preserve the selected A/B points.

Allow retry without forcing the user to start over.

---

# 50. APP LIFECYCLE

Handle:

- foreground
- background
- suspension
- termination
- phone lock
- memory pressure

Do not claim indefinite background simulation if iOS does not guarantee that execution mode.

Persist enough state to recover safely.

---

# 51. SIMULATION CLOCK

Use a monotonic clock for elapsed time where appropriate.

Do not rely solely on wall-clock timestamps.

Changing the phone's system clock must not corrupt a session.

---

# 52. FRAME-RATE INDEPENDENCE

Simulation must be time-based, not frame-based.

The same simulation should produce equivalent results at 30Hz, 60Hz, and 120Hz within reasonable numerical tolerance.

---

# 53. PRECISION

Use Double precision for geographic calculations.

Do not round internal coordinates.

Round only for display.

---

# 54. PERFORMANCE

Optimize:

- route processing
- annotation rendering
- state updates
- persistence
- GPX parsing

Do not recreate large route arrays every frame.

Do not update SwiftUI unnecessarily.

---

# 55. MAP UPDATE STRATEGY

Use a dedicated simulation-state publisher.

Only publish changed state at a sensible frequency.

Separate high-frequency engine updates from lower-frequency UI updates where possible.

---

# 56. PERSISTENCE

Use SwiftData where the deployment target permits it cleanly.

Entities:

```text
SavedLocation
SavedRoute
SimulationSession
UserSettings
RecentSearch
```

Keep derived state out of persistence when it can be recomputed reliably.

---

# 57. DATABASE SAFETY

Do not lose saved routes when the simulation crashes.

Persist important user-created entities immediately.

Use migrations for schema changes.

---

# 58. PRIVACY

Keep route and location data local by default.

Do not upload user locations to a developer-controlled server.

Do not add hidden analytics.

Do not collect unnecessary device information.

---

# 59. LOCAL SECURITY

If a connection channel exists:

- authenticate peers appropriately
- validate message sizes
- validate message types
- reject malformed commands
- prevent command flooding

Never assume a local network is inherently trustworthy.

---

# 60. UI DESIGN SYSTEM

Centralize:

- colors
- spacing
- corner radii
- typography
- control heights
- animation timings
- shadows
- map overlays

Use Apple's system typography and SF Symbols.

---

# 61. DESIGN LANGUAGE

Aesthetic:

- premium
- clean
- restrained
- map-centric
- technical without looking intimidating

Avoid:

- giant logos
- excessive gradients
- neon hacker aesthetics
- noisy dashboards
- excessive glass effects
- unnecessary animations

---

# 62. LIGHT / DARK MODE

Support:

- System
- Light
- Dark

Use semantic colors.

Test every screen in both modes.

---

# 63. ACCESSIBILITY

Support:

- VoiceOver
- Dynamic Type
- Reduce Motion
- sufficient contrast
- accessibility labels
- accessibility hints where useful

Do not make state changes color-only.

---

# 64. INTERACTIVE STATES

Every major interaction requires:

- idle
- loading
- success
- failure
- disabled
- empty

No dead buttons.

---

# 65. NO PLACEHOLDERS

Do not leave:

```text
TODO
FIXME
coming soon
placeholder
not implemented
```

inside production feature paths.

---

# 66. TEST ARCHITECTURE

Use protocols for external dependencies.

Examples:

```text
RoutingServiceProtocol
GeocodingServiceProtocol
PersistenceProtocol
TransportProtocol
ClockProtocol
SimulationEngineProtocol
CapabilityProviderProtocol
```

Production implementations use real systems.

Tests use mocks/fakes.

---

# 67. UNIT TESTS

Test:

- coordinate interpolation
- cumulative distance
- heading
- speed conversion
- acceleration
- deceleration
- stop scheduling
- ETA
- seek
- state transitions
- persistence
- settings
- route reversal

---

# 68. SIMULATION TESTS

Test:

```text
IDLE → READY
READY → RUNNING
RUNNING → PAUSED
PAUSED → RUNNING
RUNNING → STOPPING
STOPPING → COMPLETED
```

Also test invalid transitions.

---

# 69. ROUTE EDGE CASES

Test:

- identical start/destination
- extremely short route
- long route
- repeated geometry points
- tiny segments
- disconnected route
- invalid coordinates
- missing geometry

---

# 70. NUMERICAL EDGE CASES

Reject:

- NaN
- infinity
- negative distances
- negative speed
- impossible coordinates
- unbounded values

---

# 71. STOP EDGE CASES

Test:

- zero stops
- one stop
- many stops
- zero stop duration
- long stop duration
- stops too close together
- route ends during stop

---

# 72. CONNECTION TESTS

Test:

- connect
- disconnect
- reconnect
- timeout
- duplicate message
- malformed message
- protocol mismatch
- device disappearance
- stale state

---

# 73. UI TESTS

Test:

- navigation
- search
- pin drop
- route creation
- route editing
- simulation controls
- settings
- save/delete
- error states
- dark mode
- Dynamic Type

---

# 74. DEVICE TESTING

Where Apple tooling is available, test on:

- iOS Simulator
- physical iPhone

Do not assume simulator behavior is identical to a physical device. Apple explicitly notes that the simulator does not replicate every physical-device feature. [Apple Xcode documentation](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)

---

# 75. APPLE DEVELOPMENT LOCATION TESTING

Create a dedicated development-testing workflow in the documentation.

Document:

- simulator testing
- physical-device testing
- GPX/testing route workflows where supported
- signing requirements
- development pairing
- Personal Team constraints

Do not claim that this automatically turns a normal App Store build into a system-wide location provider.

---

# 76. CAPABILITY MATRIX UI

Provide a screen like:

```text
ENVIRONMENT

MapKit                         ✓
Road routing                   ✓
In-app simulation              ✓
Saved routes                   ✓
GPX                            ✓
Connected device               ✓
Development location testing  ✓
System-wide injection          —
```

The final line must be determined dynamically/documented accurately, not hardcoded as either success or failure without research.

---

# 77. TARGET-APP COMPATIBILITY TESTING

The project's testing documentation may include a compatibility matrix for apps the user owns/uses for personal testing.

Example:

```text
App category                  Location source         Observed behavior
Snap Map                      device location         test result
Navigation app                Core Location           test result
Weather app                   Core Location           test result
```

The matrix must distinguish:

- app-local simulation
- simulator behavior
- development-device behavior
- real physical-device behavior

Do not claim universal compatibility without testing.

---

# 78. SIMULATION VERIFICATION

Provide a test checklist:

1. Set a known virtual point.
2. Read the position shown by the simulator/test environment.
3. Launch the target test application.
4. Observe its reported location.
5. Record the result.
6. Compare against the expected coordinate.
7. Record whether the target app detects simulation.

This is a testing workflow, not a guarantee that every app will accept a simulated location.

---

# 79. RESEARCH ARTIFACTS

Create:

```text
research/
├── ios-location.md
├── xcode-location-testing.md
├── signing.md
├── mapkit-routing.md
└── compatibility.md
```

Each source should include:

- title
- URL
- access/retrieval date
- relevant finding
- implementation impact

Prefer primary Apple documentation.

---

# 80. DOCUMENT CURRENT DATE / VERSION

Whenever documenting platform behavior, include the verification date and relevant iOS/Xcode version.

Do not write:

```text
works on iOS
```

Write:

```text
Verified with:
iOS: <version>
Xcode: <version>
Date: <date>
```

---

# 81. BUILD REQUIREMENTS

Create a documented build procedure.

At minimum:

```text
1. Install supported Xcode.
2. Open project.
3. Select target device/simulator.
4. Configure signing.
5. Build.
6. Run tests.
7. Install/test on physical device where required.
```

---

# 82. WINDOWS / ANTIGRAVITY WORKFLOW

The source repository may be edited/generated from Windows by Antigravity.

However, native iOS compilation and normal Xcode signing require Apple's supported macOS/Xcode environment.

Document this clearly.

Do not build a fake claim that Windows alone can perform every native iOS build/signing operation.

---

# 83. PC INSTALLATION

If the PC controller is used, package it so the end user can run a simple command.

Prefer a standalone executable where practical:

```text
locationctl.exe
```

Also preserve source-based development execution.

---

# 84. PC CONFIGURATION

Every setting should be configurable through the CLI.

Commands:

```text
locationctl config show
locationctl config get <key>
locationctl config set <key> <value>
locationctl config reset
locationctl config wizard
```

No manual JSON editing should be required for normal operation.

---

# 85. DIAGNOSTIC COMMAND

Implement:

```text
locationctl doctor
```

Check:

- OS
- Python/runtime if relevant
- network
- connected device
- pairing
- tooling
- configuration
- protocol version
- route engine
- permissions
- signing/development state where observable

---

# 86. LOGGING

Use structured logs.

Never log:

- Apple account passwords
- private keys
- access tokens
- authentication cookies
- secret provisioning data

---

# 87. UPDATE STRATEGY

Do not implement an unsafe self-updater.

If updates are supported, verify package integrity and require user approval.

---

# 88. FILE FORMAT VERSIONING

Saved routes must include a schema version.

Example:

```json
{
  "schemaVersion": 1
}
```

Future schema migrations must be explicit.

---

# 89. PROTOCOL VERSIONING

The iOS app and PC controller must reject incompatible protocol versions gracefully.

Show:

```text
Incompatible controller version.

App protocol: 4
Controller protocol: 3

Update the controller.
```

---

# 90. ROUTE STORAGE

Store route geometry efficiently.

Avoid duplicating identical geometry in every history record.

Use route references where practical.

---

# 91. SEARCH HISTORY

Persist only a small recent history.

Allow clear history.

Do not upload search history.

---

# 92. DESTRUCTIVE ACTIONS

Confirm deletion of:

- saved routes
- locations
- history
- all data

Default destructive action must be Cancel.

---

# 93. DATA RESET

Provide:

```text
Reset Application Data
```

with a clear explanation.

Do not delete data silently.

---

# 94. ROUTE EXPORT

Allow exporting routes/session data as:

- JSON
- GPX

Mark generated simulation data appropriately.

---

# 95. UI COPY

Use precise terminology.

Preferred:

```text
Virtual Location
Simulated Position
Route Simulation
Development Testing
Connected Device
```

Avoid misleading terminology that implies an unsupported system-level feature.

---

# 96. NO FAKE CAPABILITIES

Do not build a toggle called:

```text
Spoof All Apps
```

that simply changes local app state.

If system-wide functionality is not actually available through the discovered environment, display the limitation.

---

# 97. NO PRIVATE SYSTEM MODIFICATION

Do not implement:

- modification of iOS system binaries
- injection into locationd
- kernel modification
- private daemon control
- third-party process injection
- code-signature bypasses
- jailbreak exploitation
- security-boundary circumvention

The project should use supported development/testing mechanisms and remain a legitimate engineering tool.

---

# 98. PRODUCT FEEL

The application should feel finished.

No:

- broken animations
- weird spacing
- unnecessary screens
- inconsistent labels
- placeholder icons
- disabled-looking buttons that should work
- unexplained errors
- random colors
- overly technical copy in normal mode

---

# 99. FINAL QA MATRIX

Before completion verify:

### Map

- [ ] world map
- [ ] search
- [ ] pin drop
- [ ] recenter
- [ ] route polyline
- [ ] start/end markers
- [ ] smooth rendering

### Routing

- [ ] road-following
- [ ] waypoints
- [ ] route reversal
- [ ] route persistence
- [ ] failures handled

### Simulation

- [ ] speed control
- [ ] variable speed
- [ ] acceleration
- [ ] deceleration
- [ ] stops
- [ ] pause
- [ ] resume
- [ ] stop
- [ ] restart
- [ ] seek
- [ ] ETA
- [ ] heading
- [ ] completion

### Storage

- [ ] locations
- [ ] routes
- [ ] history
- [ ] settings
- [ ] import/export

### PC / Device Layer

- [ ] discovery
- [ ] connection
- [ ] capabilities
- [ ] state sync
- [ ] disconnect recovery
- [ ] protocol validation

### UI

- [ ] light mode
- [ ] dark mode
- [ ] Dynamic Type
- [ ] VoiceOver
- [ ] Reduce Motion
- [ ] no clipping
- [ ] no overlap

### Stability

- [ ] no crashes
- [ ] no stuck states
- [ ] no corrupted route data
- [ ] no simulation teleportation
- [ ] no incorrect speed jumps
- [ ] no route cutting

---

# 100. FINAL ANTIGRAVITY DIRECTIVE

Do not interpret this specification as permission to invent an unsupported iOS API.

Do not stop at a mockup.

Do not merely create screens.

Do not generate code without compiling it where the environment permits.

Do not ignore errors.

Do not hide platform limitations.

First research.

Then architect.

Then implement.

Then test.

Then document.

Then verify on the strongest available Apple development environment.

The final system should provide a genuinely excellent map-based location and road-driving simulator and a rigorously engineered bridge to Apple-supported development/device testing where such a bridge is possible.

The highest priority is that every advertised feature corresponds to a real, tested behavior.

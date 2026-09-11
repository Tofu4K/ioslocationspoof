# System Architecture: iOS Physical-Device Location Simulation

## 1. Overview & Core Philosophy

The system decouples the user interaction layer (interactive world map) from the low-level device communication and developer simulation engine.

```text
┌─────────────────────────────────────────────────────────────┐
│                          MAP UI                             │
│       Leaflet / OSM Interactive World Map (Browser / App)   │
│       - Click / Tap to drop pin                             │
│       - Selected Coordinate Display (Lat, Lon, Place)       │
│       - [SPOOF] / [STOP SPOOFING] Controls                  │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTP / WebSocket REST API
┌──────────────────────────────▼──────────────────────────────┐
│                Location Selection Manager                   │
│       - Validates lat [-90, 90], lon [-180, 180]            │
│       - Formats coordinates & coordinates history           │
└──────────────────────────────┬──────────────────────────────┘
                               │ State Action Dispatch
┌──────────────────────────────▼──────────────────────────────┐
│                   Simulation Controller                     │
│       - Manages Finite State Machine (FSM)                  │
│       - Guarantees real state verification                  │
└──────────────────────────────┬──────────────────────────────┘
                               │ Abstract Backend Calls
┌──────────────────────────────▼──────────────────────────────┐
│             SimulationBackend (Base Interface)              │
│       - connect() -> bool                                   │
│       - disconnect() -> void                                │
│       - getDeviceStatus() -> DeviceInfo                     │
│       - getCapabilities() -> CapabilityReport               │
│       - setLocation(lat, lon) -> SimulationResult           │
│       - clearLocation() -> SimulationResult                 │
│       - getSimulationStatus() -> SimulationState            │
└──────────────────────────────┬──────────────────────────────┘
                               │ Developer Protocol Calls
┌──────────────────────────────▼──────────────────────────────┐
│               DeveloperServiceBackend (Concrete)            │
│       - usbmuxd / Lockdown pairing check                    │
│       - Developer Mode status verification                  │
│       - iOS 16 DDI / iOS 17+ RemoteXPC RSD Tunnel           │
│       - com.apple.dt.simulatelocation Client                │
└──────────────────────────────┬──────────────────────────────┘
                               │ USB / Wi-Fi Link
┌──────────────────────────────▼──────────────────────────────┐
│                    Physical iPhone 13                       │
│       - locationd daemon overrides global GPS coordinates   │
│       - System Location Services distribute coordinates     │
│       - All apps observe simulated location                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. State Machine Specification

The system guarantees **real state transitions**. No fake boolean flags (`isSpoofing = true`) are used.

```text
               ┌────────────────┐
               │  DISCONNECTED  │
               └───────┬────────┘
                       │ connect()
                       ▼
               ┌────────────────┐
               │   CONNECTING   │
               └───────┬────────┘
                       │ Device & Pairing verified
                       ▼
               ┌────────────────┐
               │   CONNECTED    │
               └───────┬────────┘
                       │ Developer Mode & Service Ready
                       ▼
               ┌────────────────┐
  ┌───────────►│     READY      │◄───────────┐
  │            └───────┬────────┘            │
  │                    │ setLocation(lat, lon)│
  │                    ▼                     │
  │            ┌────────────────┐            │
  │            │   SIMULATING   │            │
  │            └───────┬────────┘            │
  │                    │ clearLocation()     │
  │                    ▼                     │
  │            ┌────────────────┐            │
  │            │    STOPPING    │────────────┘
  │            └────────────────┘
  │                     │ Failure
  └─────────────────────┴───────► ┌───────────┐
                                  │   ERROR   │
                                  └───────────┘
```

### State Definitions:
- `DISCONNECTED`: No physical device detected on USB or network.
- `CONNECTING`: Initiating handshake with `usbmuxd` / Lockdown service.
- `CONNECTED`: Physical device recognized and pairing record validated.
- `READY`: Developer Mode confirmed active, developer service/tunnel established, awaiting coordinate selection.
- `SIMULATING`: Coordinate successfully accepted by `com.apple.dt.simulatelocation`. The device `locationd` is actively overriding hardware coordinates.
- `STOPPING`: Clear command transmitted, awaiting hardware GPS restoration.
- `ERROR`: Specific failure state with human-readable error diagnostics.

---

## 3. Backend Abstraction Interface

The backend is cleanly isolated in Python under `locationctl.backend`:

```python
class SimulationBackend(ABC):
    @abstractmethod
    def connect(self) -> bool:
        """Establish connection to physical device."""
        pass

    @abstractmethod
    def disconnect(self) -> None:
        """Tear down device session and close sockets."""
        pass

    @abstractmethod
    def get_device_info(self) -> DeviceInfo:
        """Query connected device model, iOS version, UDID, pairing state."""
        pass

    @abstractmethod
    def get_capabilities(self) -> CapabilityReport:
        """Check Developer Mode, service availability, tunnel support."""
        pass

    @abstractmethod
    def set_location(self, latitude: float, longitude: float) -> SimulationResult:
        """Send simulated coordinates to com.apple.dt.simulatelocation."""
        pass

    @abstractmethod
    def clear_location(self) -> SimulationResult:
        """Reset location simulation and restore hardware GPS."""
        pass
```

This abstraction ensures that the Map UI, CLI, and REST endpoints remain completely agnostic of whether the backend is communicating via `pymobiledevice3`, direct `usbmuxd`, or a remote macOS bridge.

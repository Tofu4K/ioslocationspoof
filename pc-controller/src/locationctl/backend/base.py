"""Abstract base interface for location simulation backends."""

from abc import ABC, abstractmethod
from typing import List, Optional
from .state import BackendState, DeviceInfo, CapabilityReport, SimulationResult, SimulationStatus


class SimulationBackend(ABC):
    """Abstract interface defining the device location simulation lifecycle."""

    @abstractmethod
    async def list_devices(self) -> List[DeviceInfo]:
        """Discover connected physical and virtual iOS devices."""
        pass

    @abstractmethod
    async def connect(self, udid: Optional[str] = None) -> bool:
        """Connect to the specified device or the primary connected device."""
        pass

    @abstractmethod
    async def disconnect(self) -> None:
        """Disconnect from device and clean up session resources."""
        pass

    @abstractmethod
    async def get_status(self) -> SimulationStatus:
        """Query current state, active coordinates, and hardware capability status."""
        pass

    @abstractmethod
    async def set_location(self, latitude: float, longitude: float) -> SimulationResult:
        """
        Send simulated coordinate to Apple's developer location service.
        Must validate coordinates (-90 <= lat <= 90, -180 <= lon <= 180)
        and verify acceptance by device location daemon.
        """
        pass

    @abstractmethod
    async def clear_location(self) -> SimulationResult:
        """
        Stop location simulation and prompt device locationd to restore natural GNSS hardware updates.
        """
        pass

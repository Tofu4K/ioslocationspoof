"""Backend state definitions and Finite State Machine for location simulation."""

from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field


class BackendState(str, Enum):
    DISCONNECTED = "DISCONNECTED"
    CONNECTING = "CONNECTING"
    CONNECTED = "CONNECTED"
    READY = "READY"
    SIMULATING = "SIMULATING"
    STOPPING = "STOPPING"
    ERROR = "ERROR"


class DeviceInfo(BaseModel):
    udid: str = Field(..., description="Unique device identifier")
    name: str = Field(default="Unknown Device", description="Device display name")
    product_type: str = Field(default="Unknown", description="Product model identifier, e.g. iPhone14,5")
    ios_version: str = Field(default="Unknown", description="iOS version string, e.g. 17.4 or 26.0")
    is_paired: bool = Field(default=False, description="Whether device trust pairing is valid")
    developer_mode: bool = Field(default=False, description="Whether Developer Mode is active on device")
    connection_type: str = Field(default="USB", description="USB or Network connection")


class CapabilityReport(BaseModel):
    device_connected: bool = False
    device_paired: bool = False
    developer_mode_enabled: bool = False
    developer_service_available: bool = False
    tunnel_active: bool = False
    simulation_backend_available: bool = False
    details: str = ""


class SimulationResult(BaseModel):
    success: bool
    message: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    state: BackendState = BackendState.READY
    error: Optional[str] = None


class SimulationStatus(BaseModel):
    state: BackendState
    active_coordinate: Optional[tuple[float, float]] = None
    device: Optional[DeviceInfo] = None
    capabilities: Optional[CapabilityReport] = None
    last_error: Optional[str] = None

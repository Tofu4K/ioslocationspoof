"""Protocol message types, serialization, and validation."""

from __future__ import annotations
from enum import Enum
from typing import Optional, Dict, Any, Union
from pydantic import BaseModel, Field
import uuid
from .models import (
    PROTOCOL_VERSION,
    SimulationState,
    Coordinate,
    SimulationSettings,
    RouteDefinition,
    SimulationTelemetry,
)


class MessageType(str, Enum):
    HELLO = "HELLO"
    HELLO_ACK = "HELLO_ACK"
    CAPABILITIES = "CAPABILITIES"
    SET_POSITION = "SET_POSITION"
    LOAD_ROUTE = "LOAD_ROUTE"
    START = "START"
    PAUSE = "PAUSE"
    RESUME = "RESUME"
    STOP = "STOP"
    SEEK = "SEEK"
    SET_SPEED = "SET_SPEED"
    SET_SETTINGS = "SET_SETTINGS"
    STATE = "STATE"
    ACK = "ACK"
    ERROR = "ERROR"
    HEARTBEAT = "HEARTBEAT"
    DISCONNECT = "DISCONNECT"


class ProtocolMessage(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    protocol_version: int = PROTOCOL_VERSION
    type: MessageType
    payload: Dict[str, Any] = Field(default_factory=dict)
    timestamp_utc: str = ""


# Specific Payload Helpers
class HelloPayload(BaseModel):
    client_name: str = "locationctl"
    client_version: str = "1.0.0"
    device_name: Optional[str] = None


class CapabilitiesPayload(BaseModel):
    mapkit_routing: bool = True
    local_simulation: bool = True
    gpx_import_export: bool = True
    developer_mode: bool = False
    system_wide_injection: bool = False
    details: Dict[str, Any] = Field(default_factory=dict)


class SetPositionPayload(BaseModel):
    coordinate: Coordinate


class LoadRoutePayload(BaseModel):
    route: RouteDefinition
    settings: Optional[SimulationSettings] = None


class SeekPayload(BaseModel):
    seek_time_seconds: Optional[float] = None
    seek_percentage: Optional[float] = None


class SetSpeedPayload(BaseModel):
    speed_kmh: float = Field(..., gt=0.0, le=250.0)


class AckPayload(BaseModel):
    reply_to_id: str
    status: str = "OK"
    message: Optional[str] = None


class ErrorPayload(BaseModel):
    reply_to_id: Optional[str] = None
    code: str
    message: str
    details: Optional[Dict[str, Any]] = None

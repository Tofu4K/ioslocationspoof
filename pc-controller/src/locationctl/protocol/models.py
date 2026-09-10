"""Data models and protocol definitions for LocationControl."""

from __future__ import annotations
from enum import Enum
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
import uuid

PROTOCOL_VERSION = 1


class SimulationState(str, Enum):
    IDLE = "IDLE"
    READY = "READY"
    RUNNING = "RUNNING"
    PAUSED = "PAUSED"
    STOPPING = "STOPPING"
    COMPLETED = "COMPLETED"
    ERROR = "ERROR"


class ConnectionState(str, Enum):
    DISCONNECTED = "DISCONNECTED"
    CONNECTING = "CONNECTING"
    CONNECTED = "CONNECTED"
    RECONNECTING = "RECONNECTING"
    ERROR = "ERROR"


class SpeedUnit(str, Enum):
    KMH = "km/h"
    MPH = "mph"


class AccelerationProfile(str, Enum):
    COMFORTABLE = "comfortable"  # ~1.0 m/s^2
    NORMAL = "normal"            # ~2.0 m/s^2
    FAST = "fast"                # ~3.5 m/s^2
    CUSTOM = "custom"


class StopFrequency(str, Enum):
    RARE = "rare"        # e.g. every 5 km
    NORMAL = "normal"    # e.g. every 2 km
    FREQUENT = "frequent"# e.g. every 800 m
    CUSTOM = "custom"


class Coordinate(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    altitude: Optional[float] = 0.0


class Waypoint(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    coordinate: Coordinate
    name: Optional[str] = None
    order: int = 0


class StopPoint(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    coordinate: Coordinate
    route_distance_meters: float = Field(..., ge=0.0)
    duration_seconds: float = Field(..., ge=0.0)
    is_heuristic: bool = True
    label: str = "Simulated Stop"


class RoutePoint(BaseModel):
    coordinate: Coordinate
    cumulative_distance_meters: float = Field(..., ge=0.0)
    segment_distance_meters: float = Field(..., ge=0.0)
    heading_degrees: float = Field(..., ge=0.0, lt=360.0)
    route_index: int = 0
    leg_index: int = 0


class SimulationSettings(BaseModel):
    target_speed_kmh: float = Field(default=50.0, gt=0.0, le=250.0)
    speed_unit: SpeedUnit = SpeedUnit.KMH
    speed_variation_kmh: float = Field(default=5.0, ge=0.0, le=50.0)
    acceleration_profile: AccelerationProfile = AccelerationProfile.NORMAL
    custom_acceleration_mps2: float = Field(default=2.0, gt=0.1, le=10.0)
    simulate_stops: bool = True
    stop_frequency: StopFrequency = StopFrequency.NORMAL
    average_stop_duration_seconds: float = Field(default=15.0, ge=1.0, le=300.0)
    stop_duration_variation_seconds: float = Field(default=5.0, ge=0.0, le=60.0)
    follow_camera: bool = True
    rotate_with_heading: bool = False
    deterministic_mode: bool = False
    random_seed: Optional[int] = 42


class RouteDefinition(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str = "Virtual Journey"
    start_coordinate: Coordinate
    destination_coordinate: Coordinate
    waypoints: List[Waypoint] = Field(default_factory=list)
    points: List[RoutePoint] = Field(default_factory=list)
    total_distance_meters: float = Field(default=0.0, ge=0.0)
    stops: List[StopPoint] = Field(default_factory=list)
    schema_version: int = 1


class SimulationTelemetry(BaseModel):
    session_id: str
    current_coordinate: Coordinate
    current_speed_kmh: float
    average_speed_kmh: float
    distance_travelled_meters: float
    distance_remaining_meters: float
    elapsed_time_seconds: float
    estimated_time_remaining_seconds: float
    current_heading_degrees: float
    state: SimulationState
    current_stop: Optional[StopPoint] = None
    progress_percentage: float = Field(default=0.0, ge=0.0, le=100.0)


class SimulationSession(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    route: RouteDefinition
    settings: SimulationSettings
    state: SimulationState = SimulationState.IDLE
    telemetry: Optional[SimulationTelemetry] = None
    created_at_utc: str = ""

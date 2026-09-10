"""Core Simulation Engine for route-following kinematics, stops, and state management."""

from typing import Optional, Callable
import math
from ..protocol.models import (
    SimulationState,
    SimulationSettings,
    RouteDefinition,
    Coordinate,
    SimulationTelemetry,
    AccelerationProfile,
    StopPoint,
)
from ..routes.geo_math import interpolate_segment
from .clock import ClockProtocol, SystemMonotonicClock


class SimulationEngine:
    """Independent simulation engine computing exact coordinate, heading, and telemetry."""

    def __init__(
        self,
        route: RouteDefinition,
        settings: SimulationSettings,
        clock: Optional[ClockProtocol] = None,
        on_telemetry: Optional[Callable[[SimulationTelemetry], None]] = None,
    ):
        self.route = route
        self.settings = settings
        self.clock = clock or SystemMonotonicClock()
        self.on_telemetry = on_telemetry

        self.state = SimulationState.IDLE
        self.session_id = f"sim-{id(self)}"

        self._start_monotonic: float = 0.0
        self._last_tick_monotonic: float = 0.0
        self._elapsed_sim_time: float = 0.0
        self._current_distance_meters: float = 0.0
        self._current_speed_mps: float = 0.0
        self._target_speed_mps: float = (settings.target_speed_kmh * 1000.0) / 3600.0
        self._current_heading: float = route.points[0].heading_degrees if route.points else 0.0
        self._active_stop: Optional[StopPoint] = None
        self._stop_time_remaining: float = 0.0
        self._completed_stop_ids = set()

        if self.route.points:
            self.state = SimulationState.READY

    @property
    def acceleration_mps2(self) -> float:
        if self.settings.acceleration_profile == AccelerationProfile.COMFORTABLE:
            return 1.0
        elif self.settings.acceleration_profile == AccelerationProfile.NORMAL:
            return 2.0
        elif self.settings.acceleration_profile == AccelerationProfile.FAST:
            return 3.5
        return self.settings.custom_acceleration_mps2

    def start(self):
        if self.state not in (SimulationState.READY, SimulationState.PAUSED):
            if self.state == SimulationState.IDLE and self.route.points:
                self.state = SimulationState.READY
            else:
                raise RuntimeError(f"Cannot start simulation from state {self.state}")

        now = self.clock.now()
        self._start_monotonic = now
        self._last_tick_monotonic = now
        self.state = SimulationState.RUNNING
        self._emit_telemetry()

    def pause(self):
        if self.state != SimulationState.RUNNING:
            raise RuntimeError(f"Cannot pause simulation from state {self.state}")
        self.state = SimulationState.PAUSED
        self._emit_telemetry()

    def resume(self):
        if self.state != SimulationState.PAUSED:
            raise RuntimeError(f"Cannot resume simulation from state {self.state}")
        now = self.clock.now()
        self._last_tick_monotonic = now
        self.state = SimulationState.RUNNING
        self._emit_telemetry()

    def stop(self):
        self.state = SimulationState.COMPLETED
        self._current_speed_mps = 0.0
        self._emit_telemetry()

    def set_speed(self, speed_kmh: float):
        if speed_kmh <= 0 or speed_kmh > 250:
            raise ValueError("Speed must be between 0 and 250 km/h")
        self.settings.target_speed_kmh = speed_kmh
        self._target_speed_mps = (speed_kmh * 1000.0) / 3600.0

    def tick(self) -> SimulationTelemetry:
        """Advance the simulation based on elapsed monotonic time."""
        if self.state != SimulationState.RUNNING:
            return self._build_telemetry()

        now = self.clock.now()
        delta_time = now - self._last_tick_monotonic
        self._last_tick_monotonic = now

        if delta_time <= 0.0:
            return self._build_telemetry()

        self._advance_time(delta_time)
        return self._emit_telemetry()

    def seek_to_percentage(self, percentage: float):
        """Seek directly to a specific route percentage [0.0, 100.0]."""
        clamped_pct = max(0.0, min(100.0, percentage))
        target_distance = (clamped_pct / 100.0) * self.route.total_distance_meters
        self._current_distance_meters = target_distance
        self._active_stop = None
        self._stop_time_remaining = 0.0

        if target_distance >= self.route.total_distance_meters:
            self.state = SimulationState.COMPLETED
            self._current_speed_mps = 0.0
        self._emit_telemetry()

    def _advance_time(self, dt: float):
        self._elapsed_sim_time += dt

        # Handle active stop waiting
        if self._active_stop is not None:
            self._stop_time_remaining -= dt
            self._current_speed_mps = 0.0
            if self._stop_time_remaining <= 0.0:
                self._completed_stop_ids.add(self._active_stop.id)
                self._active_stop = None
                self._stop_time_remaining = 0.0
            return

        # Check for upcoming stops within braking distance
        stop = self._find_next_uncompleted_stop()
        target_mps = self._calculate_current_target_speed()

        if stop is not None:
            dist_to_stop = stop.route_distance_meters - self._current_distance_meters
            braking_dist = (self._current_speed_mps ** 2) / (2.0 * self.acceleration_mps2)

            if dist_to_stop <= 0.5:
                # Reached stop
                self._active_stop = stop
                self._stop_time_remaining = stop.duration_seconds
                self._current_speed_mps = 0.0
                return
            elif dist_to_stop <= braking_dist + 5.0:
                # Decelerate towards stop
                target_mps = 0.0

        # Adjust speed with acceleration/deceleration kinematics
        if self._current_speed_mps < target_mps:
            self._current_speed_mps = min(target_mps, self._current_speed_mps + self.acceleration_mps2 * dt)
        elif self._current_speed_mps > target_mps:
            self._current_speed_mps = max(target_mps, self._current_speed_mps - self.acceleration_mps2 * dt)

        # Move distance
        moved_dist = self._current_speed_mps * dt
        self._current_distance_meters += moved_dist

        if self._current_distance_meters >= self.route.total_distance_meters:
            self._current_distance_meters = self.route.total_distance_meters
            self.state = SimulationState.COMPLETED
            self._current_speed_mps = 0.0

    def _calculate_current_target_speed(self) -> float:
        base_mps = (self.settings.target_speed_kmh * 1000.0) / 3600.0
        if self.settings.speed_variation_kmh > 0.0:
            var_mps = (self.settings.speed_variation_kmh * 1000.0) / 3600.0
            # Smooth sine variation over time
            variation = math.sin(self._elapsed_sim_time * 0.15) * var_mps
            return max(1.0, base_mps + variation)
        return base_mps

    def _find_next_uncompleted_stop(self) -> Optional[StopPoint]:
        for stop in self.route.stops:
            if stop.id not in self._completed_stop_ids and stop.route_distance_meters >= self._current_distance_meters:
                return stop
        return None

    def _interpolate_current_position(self) -> Coordinate:
        if not self.route.points:
            return Coordinate(latitude=0.0, longitude=0.0)

        if self._current_distance_meters <= 0.0:
            self._current_heading = self.route.points[0].heading_degrees
            return self.route.points[0].coordinate

        if self._current_distance_meters >= self.route.total_distance_meters:
            self._current_heading = self.route.points[-1].heading_degrees
            return self.route.points[-1].coordinate

        # Find segment
        for i in range(len(self.route.points) - 1):
            p1 = self.route.points[i]
            p2 = self.route.points[i + 1]
            if p1.cumulative_distance_meters <= self._current_distance_meters <= p2.cumulative_distance_meters:
                seg_len = p2.cumulative_distance_meters - p1.cumulative_distance_meters
                fraction = 0.0 if seg_len <= 0.0 else (self._current_distance_meters - p1.cumulative_distance_meters) / seg_len
                self._current_heading = p2.heading_degrees
                return interpolate_segment(p1.coordinate, p2.coordinate, fraction)

        return self.route.points[-1].coordinate

    def _build_telemetry(self) -> SimulationTelemetry:
        coord = self._interpolate_current_position()
        curr_speed_kmh = (self._current_speed_mps * 3600.0) / 1000.0
        remaining_dist = max(0.0, self.route.total_distance_meters - self._current_distance_meters)

        avg_speed_kmh = self.settings.target_speed_kmh
        eta_seconds = (remaining_dist / (self._target_speed_mps or 1.0)) if remaining_dist > 0 else 0.0
        pct = (self._current_distance_meters / self.route.total_distance_meters * 100.0) if self.route.total_distance_meters > 0 else 0.0

        return SimulationTelemetry(
            session_id=self.session_id,
            current_coordinate=coord,
            current_speed_kmh=curr_speed_kmh,
            average_speed_kmh=avg_speed_kmh,
            distance_travelled_meters=self._current_distance_meters,
            distance_remaining_meters=remaining_dist,
            elapsed_time_seconds=self._elapsed_sim_time,
            estimated_time_remaining_seconds=eta_seconds,
            current_heading_degrees=self._current_heading,
            state=self.state,
            current_stop=self._active_stop,
            progress_percentage=round(pct, 2),
        )

    def _emit_telemetry(self) -> SimulationTelemetry:
        telem = self._build_telemetry()
        if self.on_telemetry:
            self.on_telemetry(telem)
        return telem

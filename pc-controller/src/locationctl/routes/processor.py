"""Route processor for converting coordinate lists into enriched simulation-ready RouteDefinitions."""

from typing import List, Optional
import math
from ..protocol.models import (
    Coordinate,
    RoutePoint,
    RouteDefinition,
    StopPoint,
    Waypoint,
    SimulationSettings,
    StopFrequency,
)
from .geo_math import haversine_distance, initial_bearing


class RouteProcessor:
    """Processes raw coordinate paths into simulation-ready RouteDefinitions."""

    @staticmethod
    def process_coordinates(
        coordinates: List[Coordinate],
        name: str = "Virtual Route",
        waypoints: Optional[List[Waypoint]] = None,
        settings: Optional[SimulationSettings] = None,
    ) -> RouteDefinition:
        """Enrich a sequence of coordinates with cumulative distances, bearings, and stops."""
        if len(coordinates) < 2:
            raise ValueError("Route must contain at least 2 distinct coordinates.")

        route_points: List[RoutePoint] = []
        cumulative_distance = 0.0

        for i in range(len(coordinates)):
            coord = coordinates[i]
            if i == 0:
                seg_dist = 0.0
                next_coord = coordinates[1]
                bearing = initial_bearing(coord, next_coord)
            else:
                prev_coord = coordinates[i - 1]
                seg_dist = haversine_distance(prev_coord, coord)
                cumulative_distance += seg_dist
                bearing = initial_bearing(prev_coord, coord)

            route_points.append(
                RoutePoint(
                    coordinate=coord,
                    cumulative_distance_meters=cumulative_distance,
                    segment_distance_meters=seg_dist,
                    heading_degrees=bearing,
                    route_index=i,
                    leg_index=0,
                )
            )

        # Generate simulated stops if requested
        stops: List[StopPoint] = []
        if settings and settings.simulate_stops:
            stops = RouteProcessor.generate_stops(route_points, cumulative_distance, settings)

        return RouteDefinition(
            name=name,
            start_coordinate=coordinates[0],
            destination_coordinate=coordinates[-1],
            waypoints=waypoints or [],
            points=route_points,
            total_distance_meters=cumulative_distance,
            stops=stops,
            schema_version=1,
        )

    @staticmethod
    def generate_stops(
        points: List[RoutePoint],
        total_distance: float,
        settings: SimulationSettings,
    ) -> List[StopPoint]:
        """Generate deterministic simulated stops along the route."""
        stops: List[StopPoint] = []
        if total_distance < 500.0:
            return stops

        # Interval based on frequency preset
        interval_meters = 2000.0
        if settings.stop_frequency == StopFrequency.RARE:
            interval_meters = 5000.0
        elif settings.stop_frequency == StopFrequency.FREQUENT:
            interval_meters = 800.0

        current_target_dist = interval_meters
        stop_index = 1

        while current_target_dist < (total_distance - 200.0):
            # Find closest point
            closest_point = min(points, key=lambda p: abs(p.cumulative_distance_meters - current_target_dist))
            duration = settings.average_stop_duration_seconds
            if settings.deterministic_mode:
                # Deterministic slight variation
                var = ((stop_index * 7) % int(settings.stop_duration_variation_seconds + 1)) - (settings.stop_duration_variation_seconds / 2.0)
                duration = max(5.0, duration + var)

            stops.append(
                StopPoint(
                    coordinate=closest_point.coordinate,
                    route_distance_meters=closest_point.cumulative_distance_meters,
                    duration_seconds=duration,
                    is_heuristic=True,
                    label=f"Simulated Stop #{stop_index}",
                )
            )
            stop_index += 1
            current_target_dist += interval_meters

        return stops

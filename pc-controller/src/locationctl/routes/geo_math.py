"""Geographic mathematics: Haversine distance, initial bearing, and spherical interpolation."""

import math
from typing import Tuple
from ..protocol.models import Coordinate

EARTH_RADIUS_METERS = 6371008.8


def haversine_distance(coord1: Coordinate, coord2: Coordinate) -> float:
    """Calculate the great-circle distance between two coordinates in meters."""
    lat1_rad = math.radians(coord1.latitude)
    lon1_rad = math.radians(coord1.longitude)
    lat2_rad = math.radians(coord2.latitude)
    lon2_rad = math.radians(coord2.longitude)

    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad

    a = (math.sin(dlat / 2.0) ** 2) + math.cos(lat1_rad) * math.cos(lat2_rad) * (math.sin(dlon / 2.0) ** 2)
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))

    return EARTH_RADIUS_METERS * c


def initial_bearing(coord1: Coordinate, coord2: Coordinate) -> float:
    """Calculate the initial bearing from coord1 to coord2 in degrees [0, 360)."""
    lat1_rad = math.radians(coord1.latitude)
    lon1_rad = math.radians(coord1.longitude)
    lat2_rad = math.radians(coord2.latitude)
    lon2_rad = math.radians(coord2.longitude)

    dlon = lon2_rad - lon1_rad

    y = math.sin(dlon) * math.cos(lat2_rad)
    x = math.cos(lat1_rad) * math.sin(lat2_rad) - math.sin(lat1_rad) * math.cos(lat2_rad) * math.cos(dlon)

    initial_bearing_rad = math.atan2(y, x)
    initial_bearing_deg = math.degrees(initial_bearing_rad)

    return (initial_bearing_deg + 360.0) % 360.0


def interpolate_segment(coord1: Coordinate, coord2: Coordinate, fraction: float) -> Coordinate:
    """Interpolate between two coordinates by fraction [0.0, 1.0]."""
    clamped_fraction = max(0.0, min(1.0, fraction))
    lat = coord1.latitude + (coord2.latitude - coord1.latitude) * clamped_fraction
    lon = coord1.longitude + (coord2.longitude - coord1.longitude) * clamped_fraction
    alt = (coord1.altitude or 0.0) + ((coord2.altitude or 0.0) - (coord1.altitude or 0.0)) * clamped_fraction
    return Coordinate(latitude=lat, longitude=lon, altitude=alt)

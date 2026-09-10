"""Unit tests for geographic calculations."""

import pytest
import math
from locationctl.protocol.models import Coordinate
from locationctl.routes.geo_math import haversine_distance, initial_bearing, interpolate_segment


def test_haversine_known_distance():
    # Warsaw (52.2297, 21.0122) to Krakow (50.0647, 19.9450) is ~250 km
    c1 = Coordinate(latitude=52.2297, longitude=21.0122)
    c2 = Coordinate(latitude=50.0647, longitude=19.9450)
    dist = haversine_distance(c1, c2)
    assert 240000.0 < dist < 260000.0


def test_haversine_same_point():
    c1 = Coordinate(latitude=37.7749, longitude=-122.4194)
    dist = haversine_distance(c1, c1)
    assert dist == pytest.approx(0.0, abs=1e-5)


def test_initial_bearing():
    # Due North
    c1 = Coordinate(latitude=0.0, longitude=0.0)
    c2 = Coordinate(latitude=1.0, longitude=0.0)
    bearing = initial_bearing(c1, c2)
    assert bearing == pytest.approx(0.0, abs=1.0)

    # Due East
    c3 = Coordinate(latitude=0.0, longitude=1.0)
    bearing_east = initial_bearing(c1, c3)
    assert bearing_east == pytest.approx(90.0, abs=1.0)


def test_interpolate_segment():
    c1 = Coordinate(latitude=10.0, longitude=20.0, altitude=100.0)
    c2 = Coordinate(latitude=20.0, longitude=40.0, altitude=200.0)

    mid = interpolate_segment(c1, c2, 0.5)
    assert mid.latitude == pytest.approx(15.0)
    assert mid.longitude == pytest.approx(30.0)
    assert mid.altitude == pytest.approx(150.0)

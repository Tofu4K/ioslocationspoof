"""Unit tests for GPX export and import."""

import pytest
from locationctl.protocol.models import Coordinate, SimulationSettings
from locationctl.routes.processor import RouteProcessor
from locationctl.routes.gpx import GPXService


def test_gpx_export_and_import():
    c1 = Coordinate(latitude=37.7749, longitude=-122.4194, altitude=10.0)
    c2 = Coordinate(latitude=37.7849, longitude=-122.4094, altitude=15.0)
    settings = SimulationSettings(target_speed_kmh=50.0)

    route = RouteProcessor.process_coordinates([c1, c2], name="San Francisco Drive", settings=settings)
    gpx_xml = GPXService.export_gpx(route, settings)

    assert "<trkpt" in gpx_xml
    assert 'lat="37.774900"' in gpx_xml
    assert "<time>" in gpx_xml

    # Parse it back
    imported_route = GPXService.parse_gpx(gpx_xml, name="Imported SF")
    assert len(imported_route.points) == 2
    assert imported_route.points[0].coordinate.latitude == pytest.approx(37.7749)
    assert imported_route.total_distance_meters > 0.0

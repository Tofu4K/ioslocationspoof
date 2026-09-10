"""GPX import and export service for Xcode and LocationControl."""

from typing import List
import xml.etree.ElementTree as ET
from datetime import datetime, timezone, timedelta
from ..protocol.models import Coordinate, RouteDefinition, SimulationSettings
from .processor import RouteProcessor


class GPXService:
    """Service for parsing and generating GPX files."""

    @staticmethod
    def parse_gpx(gpx_content: str, name: str = "Imported GPX Route") -> RouteDefinition:
        """Parse GPX XML string into a RouteDefinition."""
        root = ET.fromstring(gpx_content)
        # Strip XML namespaces for uniform parsing
        for elem in root.iter():
            if "}" in elem.tag:
                elem.tag = elem.tag.split("}", 1)[1]

        coords: List[Coordinate] = []

        # Check track points <trkpt>
        for trkpt in root.iter("trkpt"):
            lat = float(trkpt.attrib["lat"])
            lon = float(trkpt.attrib["lon"])
            ele_elem = trkpt.find("ele")
            ele = float(ele_elem.text) if ele_elem is not None and ele_elem.text else 0.0
            coords.append(Coordinate(latitude=lat, longitude=lon, altitude=ele))

        # If no trkpt, check route points <rtept>
        if not coords:
            for rtept in root.iter("rtept"):
                lat = float(rtept.attrib["lat"])
                lon = float(rtept.attrib["lon"])
                coords.append(Coordinate(latitude=lat, longitude=lon))

        # If no rtept, check waypoints <wpt>
        if not coords:
            for wpt in root.iter("wpt"):
                lat = float(wpt.attrib["lat"])
                lon = float(wpt.attrib["lon"])
                coords.append(Coordinate(latitude=lat, longitude=lon))

        if len(coords) < 2:
            raise ValueError("GPX must contain at least 2 coordinate points.")

        return RouteProcessor.process_coordinates(coords, name=name)

    @staticmethod
    def export_gpx(
        route: RouteDefinition,
        settings: SimulationSettings,
        start_time: datetime = None,
    ) -> str:
        """Export RouteDefinition to Xcode-compatible GPX format with timestamps."""
        if start_time is None:
            start_time = datetime.now(timezone.utc)

        speed_mps = (settings.target_speed_kmh * 1000.0) / 3600.0
        gpx_lines = [
            '<?xml version="1.0" encoding="UTF-8"?>',
            '<gpx version="1.1" creator="LocationControl Suite" xmlns="http://www.topografix.com/GPX/1/1">',
            f'  <metadata><name>{route.name}</name></metadata>',
            '  <trk>',
            f'    <name>{route.name}</name>',
            '    <trkseg>',
        ]

        current_time = start_time
        for point in route.points:
            # Time delta based on distance
            time_offset_sec = point.cumulative_distance_meters / speed_mps if speed_mps > 0 else 0
            pt_time = start_time + timedelta(seconds=time_offset_sec)
            time_str = pt_time.strftime("%Y-%m-%dT%H:%M:%SZ")
            gpx_lines.append(
                f'      <trkpt lat="{point.coordinate.latitude:.6f}" lon="{point.coordinate.longitude:.6f}">'
            )
            if point.coordinate.altitude:
                gpx_lines.append(f'        <ele>{point.coordinate.altitude:.1f}</ele>')
            gpx_lines.append(f'        <time>{time_str}</time>')
            gpx_lines.append('      </trkpt>')

        gpx_lines.append('    </trkseg>')
        gpx_lines.append('  </trk>')
        gpx_lines.append('</gpx>')

        return "\n".join(gpx_lines)

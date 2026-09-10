import Foundation

public struct GPXService {
    public static func exportGPX(
        route: RouteDefinition,
        settings: SimulationSettings,
        startTime: Date = Date()
    ) -> String {
        let speedMps = (settings.targetSpeedKmh * 1000.0) / 3600.0
        let formatter = ISO8601DateFormatter()

        var lines: [String] = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
            "<gpx version=\"1.1\" creator=\"LocationControl iOS Suite\" xmlns=\"http://www.topografix.com/GPX/1/1\">",
            "  <metadata><name>\(route.name)</name></metadata>",
            "  <trk>",
            "    <name>\(route.name)</name>",
            "    <trkseg>"
        ]

        for pt in route.points {
            let offsetSec = speedMps > 0 ? pt.cumulativeDistanceMeters / speedMps : 0
            let ptDate = startTime.addingTimeInterval(offsetSec)
            let timeStr = formatter.string(from: ptDate)

            lines.append("      <trkpt lat=\"\(String(format: "%.6f", pt.coordinate.latitude))\" lon=\"\(String(format: "%.6f", pt.coordinate.longitude))\">")
            if let alt = pt.coordinate.altitude {
                lines.append("        <ele>\(String(format: "%.1f", alt))</ele>")
            }
            lines.append("        <time>\(timeStr)</time>")
            lines.append("      </trkpt>")
        }

        lines.append("    </trkseg>")
        lines.append("  </trk>")
        lines.append("</gpx>")

        return lines.joined(separator: "\n")
    }
}

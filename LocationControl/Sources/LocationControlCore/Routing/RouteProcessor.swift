import Foundation

public struct RouteProcessor {
    public static func processCoordinates(
        _ coordinates: [LocationCoordinate],
        name: String = "Virtual Route",
        waypoints: [Waypoint] = [],
        settings: SimulationSettings? = nil
    ) throws -> RouteDefinition {
        guard coordinates.count >= 2 else {
            throw NSError(domain: "RouteProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Route must contain at least 2 distinct coordinates."])
        }

        var points: [RoutePoint] = []
        var cumulativeDistance: Double = 0.0

        for i in 0..<coordinates.count {
            let coord = coordinates[i]
            let segDist: Double
            let bearing: Double

            if i == 0 {
                segDist = 0.0
                bearing = GeoMath.initialBearing(from: coord, to: coordinates[1])
            } else {
                let prevCoord = coordinates[i - 1]
                segDist = GeoMath.haversineDistance(from: prevCoord, to: coord)
                cumulativeDistance += segDist
                bearing = GeoMath.initialBearing(from: prevCoord, to: coord)
            }

            points.append(
                RoutePoint(
                    coordinate: coord,
                    cumulativeDistanceMeters: cumulativeDistance,
                    segmentDistanceMeters: segDist,
                    headingDegrees: bearing,
                    routeIndex: i,
                    legIndex: 0
                )
            )
        }

        var stops: [StopPoint] = []
        if let settings = settings, settings.simulateStops {
            stops = generateStops(points: points, totalDistance: cumulativeDistance, settings: settings)
        }

        return RouteDefinition(
            name: name,
            startCoordinate: coordinates[0],
            destinationCoordinate: coordinates[coordinates.count - 1],
            waypoints: waypoints,
            points: points,
            totalDistanceMeters: cumulativeDistance,
            stops: stops,
            schemaVersion: 1
        )
    }

    public static func generateStops(
        points: [RoutePoint],
        totalDistance: Double,
        settings: SimulationSettings
    ) -> [StopPoint] {
        guard totalDistance >= 500.0 else { return [] }

        var stops: [StopPoint] = []
        let intervalMeters = settings.stopFrequency.intervalMeters
        var currentTargetDist = intervalMeters
        var stopIndex = 1

        while currentTargetDist < (totalDistance - 200.0) {
            // Find closest route point
            if let closestPoint = points.min(by: { abs($0.cumulativeDistanceMeters - currentTargetDist) < abs($1.cumulativeDistanceMeters - currentTargetDist) }) {
                var duration = settings.averageStopDurationSeconds
                if settings.deterministicMode {
                    let variation = Double((stopIndex * 7) % (Int(settings.stopDurationVariationSeconds) + 1)) - (settings.stopDurationVariationSeconds / 2.0)
                    duration = max(5.0, duration + variation)
                }

                stops.append(
                    StopPoint(
                        coordinate: closestPoint.coordinate,
                        routeDistanceMeters: closestPoint.cumulativeDistanceMeters,
                        durationSeconds: duration,
                        isHeuristic: true,
                        label: "Simulated Stop #\(stopIndex)"
                    )
                )
            }
            stopIndex += 1
            currentTargetDist += intervalMeters
        }

        return stops
    }
}

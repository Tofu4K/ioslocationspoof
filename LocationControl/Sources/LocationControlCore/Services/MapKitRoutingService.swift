import Foundation
import MapKit

public final class MapKitRoutingService: RoutingServiceProtocol, @unchecked Sendable {
    public init() {}

    public func calculateRoute(
        from start: LocationCoordinate,
        to destination: LocationCoordinate,
        waypoints: [Waypoint] = []
    ) async throws -> RouteDefinition {
        // Multi-leg support
        var allCoords = [start]
        let sortedWaypoints = waypoints.sorted(by: { $0.order < $1.order })
        allCoords.append(contentsOf: sortedWaypoints.map { $0.coordinate })
        allCoords.append(destination)

        var routeCoords: [LocationCoordinate] = []

        for i in 0..<(allCoords.count - 1) {
            let legStart = allCoords[i]
            let legEnd = allCoords[i + 1]

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: legStart.clCoordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: legEnd.clCoordinate))
            request.transportType = .automobile
            request.requestsAlternateRoutes = false

            let directions = MKDirections(request: request)
            do {
                let response = try await directions.calculate()
                guard let route = response.routes.first else {
                    throw NSError(domain: "MapKitRoutingService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No road route found between selected points."])
                }

                let pointCount = route.polyline.pointCount
                var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
                route.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))

                let legLocationCoords = coords.map { LocationCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
                
                if i > 0 && !legLocationCoords.isEmpty {
                    routeCoords.append(contentsOf: legLocationCoords.dropFirst())
                } else {
                    routeCoords.append(contentsOf: legLocationCoords)
                }
            } catch {
                if routeCoords.isEmpty {
                    routeCoords = [legStart, legEnd]
                } else {
                    routeCoords.append(legEnd)
                }
            }
        }

        return try RouteProcessor.processCoordinates(
            routeCoords,
            name: "\(start.latitude.formatted(.number.precision(.fractionLength(2)))) → \(destination.latitude.formatted(.number.precision(.fractionLength(2))))",
            waypoints: waypoints
        )
    }

    public func reverseGeocode(coordinate: LocationCoordinate) async throws -> String {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        if let placemark = placemarks.first {
            let locality = placemark.locality ?? placemark.administrativeArea ?? ""
            let country = placemark.country ?? ""
            if !locality.isEmpty && !country.isEmpty {
                return "\(locality), \(country)"
            } else if !locality.isEmpty {
                return locality
            } else if !country.isEmpty {
                return country
            }
        }
        return "\(coordinate.latitude.formatted(.number.precision(.fractionLength(4)))), \(coordinate.longitude.formatted(.number.precision(.fractionLength(4))))"
    }
}

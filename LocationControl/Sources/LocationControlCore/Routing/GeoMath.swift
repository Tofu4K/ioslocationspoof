import Foundation

public struct GeoMath {
    public static let earthRadiusMeters: Double = 6371008.8

    public static func haversineDistance(from c1: LocationCoordinate, to c2: LocationCoordinate) -> Double {
        let lat1Rad = c1.latitude * .pi / 180.0
        let lon1Rad = c1.longitude * .pi / 180.0
        let lat2Rad = c2.latitude * .pi / 180.0
        let lon2Rad = c2.longitude * .pi / 180.0

        let dlat = lat2Rad - lat1Rad
        let dlon = lon2Rad - lon1Rad

        let a = sin(dlat / 2.0) * sin(dlat / 2.0) + cos(lat1Rad) * cos(lat2Rad) * sin(dlon / 2.0) * sin(dlon / 2.0)
        let c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))

        return earthRadiusMeters * c
    }

    public static func initialBearing(from c1: LocationCoordinate, to c2: LocationCoordinate) -> Double {
        let lat1Rad = c1.latitude * .pi / 180.0
        let lon1Rad = c1.longitude * .pi / 180.0
        let lat2Rad = c2.latitude * .pi / 180.0
        let lon2Rad = c2.longitude * .pi / 180.0

        let dlon = lon2Rad - lon1Rad

        let y = sin(dlon) * cos(lat2Rad)
        let x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dlon)

        let initialBearingRad = atan2(y, x)
        let initialBearingDeg = initialBearingRad * 180.0 / .pi

        return (initialBearingDeg + 360.0).truncatingRemainder(dividingBy: 360.0)
    }

    public static func interpolateSegment(from c1: LocationCoordinate, to c2: LocationCoordinate, fraction: Double) -> LocationCoordinate {
        let clamped = max(0.0, min(1.0, fraction))
        let lat = c1.latitude + (c2.latitude - c1.latitude) * clamped
        let lon = c1.longitude + (c2.longitude - c1.longitude) * clamped
        let alt = (c1.altitude ?? 0.0) + ((c2.altitude ?? 0.0) - (c1.altitude ?? 0.0)) * clamped
        return LocationCoordinate(latitude: lat, longitude: lon, altitude: alt)
    }
}

import XCTest
@testable import LocationControlCore

final class GeoMathTests: XCTestCase {
    func testHaversineDistance() {
        let c1 = LocationCoordinate(latitude: 52.2297, longitude: 21.0122)
        let c2 = LocationCoordinate(latitude: 50.0647, longitude: 19.9450)
        let dist = GeoMath.haversineDistance(from: c1, to: c2)
        XCTAssertGreaterThan(dist, 240000)
        XCTAssertLessThan(dist, 260000)
    }

    func testInitialBearing() {
        let c1 = LocationCoordinate(latitude: 0, longitude: 0)
        let c2 = LocationCoordinate(latitude: 1, longitude: 0)
        let bearing = GeoMath.initialBearing(from: c1, to: c2)
        XCTAssertEqual(bearing, 0, accuracy: 1.0)
    }

    func testInterpolateSegment() {
        let c1 = LocationCoordinate(latitude: 10, longitude: 20, altitude: 100)
        let c2 = LocationCoordinate(latitude: 20, longitude: 40, altitude: 200)
        let mid = GeoMath.interpolateSegment(from: c1, to: c2, fraction: 0.5)
        XCTAssertEqual(mid.latitude, 15, accuracy: 0.001)
        XCTAssertEqual(mid.longitude, 30, accuracy: 0.001)
        XCTAssertEqual(mid.altitude ?? 0, 150, accuracy: 0.001)
    }
}

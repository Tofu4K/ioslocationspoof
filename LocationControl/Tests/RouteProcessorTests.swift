import XCTest
@testable import LocationControlCore

final class RouteProcessorTests: XCTestCase {
    func testProcessCoordinates() throws {
        let c1 = LocationCoordinate(latitude: 52.2297, longitude: 21.0122)
        let c2 = LocationCoordinate(latitude: 52.2350, longitude: 21.0180)
        let route = try RouteProcessor.processCoordinates([c1, c2], name: "Test Leg")

        XCTAssertEqual(route.points.count, 2)
        XCTAssertGreaterThan(route.totalDistanceMeters, 0)
        XCTAssertEqual(route.startCoordinate.latitude, 52.2297, accuracy: 0.0001)
    }

    func testTooFewCoordinatesThrows() {
        let c1 = LocationCoordinate(latitude: 52.2297, longitude: 21.0122)
        XCTAssertThrowsError(try RouteProcessor.processCoordinates([c1]))
    }
}

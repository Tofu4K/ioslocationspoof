import XCTest
@testable import LocationControlCore

final class SimulationEngineTests: XCTestCase {
    func testSimulationLifecycle() throws {
        let c1 = LocationCoordinate(latitude: 52.2297, longitude: 21.0122)
        let c2 = LocationCoordinate(latitude: 52.2350, longitude: 21.0180)
        let route = try RouteProcessor.processCoordinates([c1, c2], name: "Test Route")
        let fakeClock = FakeClock(initialTime: 100.0)

        let engine = SimulationEngine(route: route, settings: SimulationSettings(targetSpeedKmh: 60.0), clock: fakeClock)
        XCTAssertEqual(engine.state, .ready)

        try engine.start()
        XCTAssertEqual(engine.state, .running)

        fakeClock.advance(by: 5.0)
        let telem = engine.tick()
        XCTAssertGreaterThan(telem.distanceTravelledMeters, 0)
        XCTAssertEqual(telem.state, .running)

        try engine.pause()
        XCTAssertEqual(engine.state, .paused)

        try engine.resume()
        XCTAssertEqual(engine.state, .running)

        engine.stop()
        XCTAssertEqual(engine.state, .completed)
    }

    func testSeeking() throws {
        let c1 = LocationCoordinate(latitude: 52.2297, longitude: 21.0122)
        let c2 = LocationCoordinate(latitude: 52.2350, longitude: 21.0180)
        let route = try RouteProcessor.processCoordinates([c1, c2], name: "Seek Route")
        let fakeClock = FakeClock(initialTime: 0.0)

        let engine = SimulationEngine(route: route, settings: SimulationSettings(targetSpeedKmh: 50.0), clock: fakeClock)
        try engine.start()

        engine.seek(to: 50.0)
        let telem = engine.tick()
        XCTAssertEqual(telem.progressPercentage, 50.0, accuracy: 1.0)
        XCTAssertEqual(telem.distanceTravelledMeters, route.totalDistanceMeters * 0.5, accuracy: 5.0)
    }
}

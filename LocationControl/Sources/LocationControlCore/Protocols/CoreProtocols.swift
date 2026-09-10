import Foundation
import CoreLocation

public protocol ClockProtocol: Sendable {
    func now() -> Double
}

public protocol RoutingServiceProtocol: Sendable {
    func calculateRoute(
        from start: LocationCoordinate,
        to destination: LocationCoordinate,
        waypoints: [Waypoint]
    ) async throws -> RouteDefinition
    
    func reverseGeocode(coordinate: LocationCoordinate) async throws -> String
}

public protocol SimulationEngineProtocol: AnyObject, Sendable {
    var state: SimulationState { get }
    var currentTelemetry: SimulationTelemetry { get }
    
    func start() throws
    func pause() throws
    func resume() throws
    func stop()
    func seek(to percentage: Double)
    func setSpeed(kmh: Double) throws
    func tick() -> SimulationTelemetry
}

public protocol PersistenceProtocol: Sendable {
    func saveLocation(_ location: LocationCoordinate, name: String) async throws
    func fetchSavedLocations() async throws -> [(id: UUID, name: String, coordinate: LocationCoordinate)]
    func deleteSavedLocation(id: UUID) async throws
    
    func saveRoute(_ route: RouteDefinition) async throws
    func fetchSavedRoutes() async throws -> [RouteDefinition]
    func deleteSavedRoute(id: UUID) async throws
}

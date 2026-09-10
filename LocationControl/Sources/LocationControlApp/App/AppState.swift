import Foundation
import SwiftUI
import CoreLocation
import LocationControlCore

@MainActor
public final class AppState: ObservableObject {
    @Published public var currentTab: NavigationTab = .map
    @Published public var activeRoute: RouteDefinition?
    @Published public var startCoordinate: LocationCoordinate?
    @Published public var destinationCoordinate: LocationCoordinate?
    @Published public var waypoints: [Waypoint] = []
    @Published public var simulationSettings = SimulationSettings()
    
    @Published public var simulationEngine: SimulationEngine?
    @Published public var liveTelemetry: SimulationTelemetry?
    @Published public var isSimulating: Bool = false
    @Published public var isPaused: Bool = false
    
    @Published public var savedLocations: [(id: UUID, name: String, coordinate: LocationCoordinate)] = []
    @Published public var savedRoutes: [RouteDefinition] = []
    @Published public var isCalculatingRoute: Bool = false
    @Published public var errorMessage: String?
    
    public let routingService: RoutingServiceProtocol
    public let persistenceService: PersistenceService
    public let capabilityRegistry: CapabilityRegistry

    private var simulationTimer: Timer?

    public init(
        routingService: RoutingServiceProtocol = MapKitRoutingService(),
        persistenceService: PersistenceService = PersistenceService(),
        capabilityRegistry: CapabilityRegistry? = nil
    ) {
        self.routingService = routingService
        self.persistenceService = persistenceService
        self.capabilityRegistry = capabilityRegistry ?? CapabilityRegistry()
        
        self.startCoordinate = LocationCoordinate(latitude: 52.2297, longitude: 21.0122)
        self.destinationCoordinate = LocationCoordinate(latitude: 50.0647, longitude: 19.9450)
    }

    public enum NavigationTab: String, CaseIterable, Identifiable {
        case map = "Map"
        case planner = "Planner"
        case saved = "Saved"
        case diagnostics = "Diagnostics"
        case settings = "Settings"

        public var id: String { rawValue }
        public var icon: String {
            switch self {
            case .map: return "map.fill"
            case .planner: return "arrow.triangle.swap"
            case .saved: return "bookmark.fill"
            case .diagnostics: return "stethoscope"
            case .settings: return "gearshape.fill"
            }
        }
    }

    public func calculateCurrentRoute() async {
        guard let start = startCoordinate, let dest = destinationCoordinate else { return }
        isCalculatingRoute = true
        errorMessage = nil
        do {
            let route = try await routingService.calculateRoute(from: start, to: dest, waypoints: waypoints)
            self.activeRoute = route
            self.setupSimulationEngine(for: route)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isCalculatingRoute = false
    }

    public func setupSimulationEngine(for route: RouteDefinition) {
        let engine = SimulationEngine(route: route, settings: simulationSettings)
        engine.onTelemetryUpdate = { [weak self] telem in
            Task { @MainActor [weak self] in
                self?.liveTelemetry = telem
            }
        }
        self.simulationEngine = engine
        self.liveTelemetry = engine.currentTelemetry
    }

    public func startSimulation() {
        guard let engine = simulationEngine else { return }
        do {
            try engine.start()
            isSimulating = true
            isPaused = false
            startTicker()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func pauseSimulation() {
        guard let engine = simulationEngine else { return }
        try? engine.pause()
        isPaused = true
    }

    public func resumeSimulation() {
        guard let engine = simulationEngine else { return }
        try? engine.resume()
        isPaused = false
    }

    public func stopSimulation() {
        simulationEngine?.stop()
        isSimulating = false
        isPaused = false
        simulationTimer?.invalidate()
        simulationTimer = nil
    }

    public func seekSimulation(to percentage: Double) {
        simulationEngine?.seek(to: percentage)
    }

    private func startTicker() {
        simulationTimer?.invalidate()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let engine = self.simulationEngine else { return }
                let telem = engine.tick()
                if telem.state == .completed {
                    self.isSimulating = false
                    self.simulationTimer?.invalidate()
                    self.simulationTimer = nil
                }
            }
        }
    }

    public func saveCurrentRoute(name: String) async {
        guard var route = activeRoute else { return }
        route.name = name
        try? await persistenceService.saveRoute(route)
        await loadSavedData()
    }

    public func loadSavedData() async {
        self.savedLocations = (try? await persistenceService.fetchSavedLocations()) ?? []
        self.savedRoutes = (try? await persistenceService.fetchSavedRoutes()) ?? []
    }
}

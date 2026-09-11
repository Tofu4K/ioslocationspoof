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
    
    // Physical Device Hardware Spoofing
    @Published public var selectedPinCoordinate: LocationCoordinate? = LocationCoordinate(latitude: 48.8584, longitude: 2.2945)
    @Published public var selectedAddressLabel: String = "Eiffel Tower, Paris"
    @Published public var isHardwareSpoofing: Bool = false
    @Published public var hardwareSpoofStatus: String = "Ready"
    @Published public var isBackendReachable: Bool = false
    @Published public var connectedDeviceName: String = "iPhone"
    @Published public var backendApiUrl: String {
        didSet {
            UserDefaults.standard.set(backendApiUrl, forKey: "LocationControl.backendApiUrl")
        }
    }
    
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
        
        self.backendApiUrl = UserDefaults.standard.string(forKey: "LocationControl.backendApiUrl") ?? "http://localhost:8765"
        self.startCoordinate = LocationCoordinate(latitude: 52.2297, longitude: 21.0122)
        self.destinationCoordinate = LocationCoordinate(latitude: 50.0647, longitude: 19.9450)
    }

    public enum NavigationTab: String, CaseIterable, Identifiable {
        case map = "Map"
        case web = "Web View"
        case planner = "Planner"
        case saved = "Saved"
        case diagnostics = "Diagnostics"
        case settings = "Settings"

        public var id: String { rawValue }
        public var icon: String {
            switch self {
            case .map: return "map.fill"
            case .web: return "globe"
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

    public func checkBackendStatus() async {
        guard let url = URL(string: "\(backendApiUrl)/api/status") else {
            isBackendReachable = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3.0
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                isBackendReachable = true
                if let state = json["state"] as? String {
                    isHardwareSpoofing = (state == "SIMULATING")
                }
                if let dev = json["device"] as? [String: Any], let name = dev["name"] as? String {
                    connectedDeviceName = name
                }
                if let activeCoord = json["active_coordinate"] as? [Double], activeCoord.count == 2 {
                    selectedPinCoordinate = LocationCoordinate(latitude: activeCoord[0], longitude: activeCoord[1])
                }
            } else {
                isBackendReachable = false
            }
        } catch {
            isBackendReachable = false
        }
    }

    public func reverseGeocodeSelectedCoordinate() {
        guard let coord = selectedPinCoordinate else { return }
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let p = placemarks?.first {
                let name = p.name ?? ""
                let locality = p.locality ?? p.administrativeArea ?? p.country ?? ""
                DispatchQueue.main.async {
                    self?.selectedAddressLabel = name.isEmpty ? locality : "\(name), \(locality)"
                }
            }
        }
    }

    public func spoofSelectedLocation() async {
        guard let coord = selectedPinCoordinate else { return }
        hardwareSpoofStatus = "Spoofing coordinate..."
        guard let url = URL(string: "\(backendApiUrl)/api/spoof") else {
            hardwareSpoofStatus = "Invalid URL: \(backendApiUrl)"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = ["lat": coord.latitude, "lon": coord.longitude]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                isHardwareSpoofing = true
                isBackendReachable = true
                hardwareSpoofStatus = "SPOOFING ACTIVE"
            } else {
                let errStr = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String ?? "Failed"
                hardwareSpoofStatus = "SPOOFING FAILED: \(errStr)"
            }
        } catch {
            isBackendReachable = false
            hardwareSpoofStatus = "Cannot reach server at \(backendApiUrl). Is PC on same Wi-Fi?"
        }
    }

    public func stopHardwareSpoofing() async {
        hardwareSpoofStatus = "Stopping..."
        guard let url = URL(string: "\(backendApiUrl)/api/clear") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                isHardwareSpoofing = false
                hardwareSpoofStatus = "Ready"
            } else {
                hardwareSpoofStatus = "Failed to stop simulation"
            }
        } catch {
            hardwareSpoofStatus = "Error: \(error.localizedDescription)"
        }
    }
}



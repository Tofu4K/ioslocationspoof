import Foundation

public struct SavedLocationItem: Codable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var coordinate: LocationCoordinate
    public var createdAt: Date
    public var isFavorite: Bool

    public init(id: UUID = UUID(), name: String, coordinate: LocationCoordinate, createdAt: Date = Date(), isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }
}

public actor PersistenceService: PersistenceProtocol {
    private let fileManager = FileManager.default
    private let storageUrl: URL

    public init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.storageUrl = docs.appendingPathComponent("LocationControlData", isDirectory: true)
        try? fileManager.createDirectory(at: storageUrl, withIntermediateDirectories: true)
    }

    private var locationsFile: URL { storageUrl.appendingPathComponent("saved_locations.json") }
    private var routesFile: URL { storageUrl.appendingPathComponent("saved_routes.json") }

    public func saveLocation(_ location: LocationCoordinate, name: String) async throws {
        var items = try await loadSavedLocationsInternal()
        items.append(SavedLocationItem(name: name, coordinate: location))
        let data = try JSONEncoder().encode(items)
        try data.write(to: locationsFile)
    }

    public func fetchSavedLocations() async throws -> [(id: UUID, name: String, coordinate: LocationCoordinate)] {
        let items = try await loadSavedLocationsInternal()
        return items.map { ($0.id, $0.name, $0.coordinate) }
    }

    public func deleteSavedLocation(id: UUID) async throws {
        var items = try await loadSavedLocationsInternal()
        items.removeAll(where: { $0.id == id })
        let data = try JSONEncoder().encode(items)
        try data.write(to: locationsFile)
    }

    public func saveRoute(_ route: RouteDefinition) async throws {
        var items = try await loadSavedRoutesInternal()
        items.removeAll(where: { $0.id == route.id })
        items.append(route)
        let data = try JSONEncoder().encode(items)
        try data.write(to: routesFile)
    }

    public func fetchSavedRoutes() async throws -> [RouteDefinition] {
        try await loadSavedRoutesInternal()
    }

    public func deleteSavedRoute(id: UUID) async throws {
        var items = try await loadSavedRoutesInternal()
        items.removeAll(where: { $0.id == id })
        let data = try JSONEncoder().encode(items)
        try data.write(to: routesFile)
    }

    private func loadSavedLocationsInternal() async throws -> [SavedLocationItem] {
        guard fileManager.fileExists(atPath: locationsFile.path) else { return [] }
        let data = try Data(contentsOf: locationsFile)
        return (try? JSONDecoder().decode([SavedLocationItem].self, from: data)) ?? []
    }

    private func loadSavedRoutesInternal() async throws -> [RouteDefinition] {
        guard fileManager.fileExists(atPath: routesFile.path) else { return [] }
        let data = try Data(contentsOf: routesFile)
        return (try? JSONDecoder().decode([RouteDefinition].self, from: data)) ?? []
    }
}

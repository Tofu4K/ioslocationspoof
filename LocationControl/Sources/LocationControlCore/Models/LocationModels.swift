import Foundation
import CoreLocation

public let CURRENT_PROTOCOL_VERSION = 1

public enum SimulationState: String, Codable, Sendable {
    case idle = "IDLE"
    case ready = "READY"
    case running = "RUNNING"
    case paused = "PAUSED"
    case stopping = "STOPPING"
    case completed = "COMPLETED"
    case error = "ERROR"
}

public enum SpeedUnit: String, Codable, Sendable, CaseIterable {
    case kmh = "km/h"
    case mph = "mph"
}

public enum AccelerationProfile: String, Codable, Sendable, CaseIterable {
    case comfortable = "comfortable"
    case normal = "normal"
    case fast = "fast"
    case custom = "custom"
    
    public var accelerationMps2: Double {
        switch self {
        case .comfortable: return 1.0
        case .normal: return 2.0
        case .fast: return 3.5
        case .custom: return 2.0
        }
    }
}

public enum StopFrequency: String, Codable, Sendable, CaseIterable {
    case rare = "rare"
    case normal = "normal"
    case frequent = "frequent"
    case custom = "custom"
    
    public var intervalMeters: Double {
        switch self {
        case .rare: return 5000.0
        case .normal: return 2000.0
        case .frequent: return 800.0
        case .custom: return 2000.0
        }
    }
}

public struct LocationCoordinate: Codable, Equatable, Sendable, Hashable {
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double?

    public init(latitude: Double, longitude: Double, altitude: Double? = 0.0) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }
    
    public var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

public struct Waypoint: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var coordinate: LocationCoordinate
    public var name: String?
    public var order: Int

    public init(id: UUID = UUID(), coordinate: LocationCoordinate, name: String? = nil, order: Int = 0) {
        self.id = id
        self.coordinate = coordinate
        self.name = name
        self.order = order
    }
}

public struct StopPoint: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var coordinate: LocationCoordinate
    public var routeDistanceMeters: Double
    public var durationSeconds: Double
    public var isHeuristic: Bool
    public var label: String

    public init(
        id: UUID = UUID(),
        coordinate: LocationCoordinate,
        routeDistanceMeters: Double,
        durationSeconds: Double,
        isHeuristic: Bool = true,
        label: String = "Simulated Stop"
    ) {
        self.id = id
        self.coordinate = coordinate
        self.routeDistanceMeters = routeDistanceMeters
        self.durationSeconds = durationSeconds
        self.isHeuristic = isHeuristic
        self.label = label
    }
}

public struct RoutePoint: Codable, Identifiable, Equatable, Sendable {
    public var id: Int { routeIndex }
    public var coordinate: LocationCoordinate
    public var cumulativeDistanceMeters: Double
    public var segmentDistanceMeters: Double
    public var headingDegrees: Double
    public var routeIndex: Int
    public var legIndex: Int

    public init(
        coordinate: LocationCoordinate,
        cumulativeDistanceMeters: Double,
        segmentDistanceMeters: Double,
        headingDegrees: Double,
        routeIndex: Int,
        legIndex: Int = 0
    ) {
        self.coordinate = coordinate
        self.cumulativeDistanceMeters = cumulativeDistanceMeters
        self.segmentDistanceMeters = segmentDistanceMeters
        self.headingDegrees = headingDegrees
        self.routeIndex = routeIndex
        self.legIndex = legIndex
    }
}

public struct SimulationSettings: Codable, Equatable, Sendable {
    public var targetSpeedKmh: Double
    public var speedUnit: SpeedUnit
    public var speedVariationKmh: Double
    public var accelerationProfile: AccelerationProfile
    public var customAccelerationMps2: Double
    public var simulateStops: Bool
    public var stopFrequency: StopFrequency
    public var averageStopDurationSeconds: Double
    public var stopDurationVariationSeconds: Double
    public var followCamera: Bool
    public var rotateWithHeading: Bool
    public var deterministicMode: Bool

    public init(
        targetSpeedKmh: Double = 50.0,
        speedUnit: SpeedUnit = .kmh,
        speedVariationKmh: Double = 5.0,
        accelerationProfile: AccelerationProfile = .normal,
        customAccelerationMps2: Double = 2.0,
        simulateStops: Bool = true,
        stopFrequency: StopFrequency = .normal,
        averageStopDurationSeconds: Double = 15.0,
        stopDurationVariationSeconds: Double = 5.0,
        followCamera: Bool = true,
        rotateWithHeading: Bool = false,
        deterministicMode: Bool = false
    ) {
        self.targetSpeedKmh = targetSpeedKmh
        self.speedUnit = speedUnit
        self.speedVariationKmh = speedVariationKmh
        self.accelerationProfile = accelerationProfile
        self.customAccelerationMps2 = customAccelerationMps2
        self.simulateStops = simulateStops
        self.stopFrequency = stopFrequency
        self.averageStopDurationSeconds = averageStopDurationSeconds
        self.stopDurationVariationSeconds = stopDurationVariationSeconds
        self.followCamera = followCamera
        self.rotateWithHeading = rotateWithHeading
        self.deterministicMode = deterministicMode
    }
}

public struct RouteDefinition: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var startCoordinate: LocationCoordinate
    public var destinationCoordinate: LocationCoordinate
    public var waypoints: [Waypoint]
    public var points: [RoutePoint]
    public var totalDistanceMeters: Double
    public var stops: [StopPoint]
    public var schemaVersion: Int

    public init(
        id: UUID = UUID(),
        name: String = "Virtual Journey",
        startCoordinate: LocationCoordinate,
        destinationCoordinate: LocationCoordinate,
        waypoints: [Waypoint] = [],
        points: [RoutePoint] = [],
        totalDistanceMeters: Double = 0.0,
        stops: [StopPoint] = [],
        schemaVersion: Int = 1
    ) {
        self.id = id
        self.name = name
        self.startCoordinate = startCoordinate
        self.destinationCoordinate = destinationCoordinate
        self.waypoints = waypoints
        self.points = points
        self.totalDistanceMeters = totalDistanceMeters
        self.stops = stops
        self.schemaVersion = schemaVersion
    }
}

public struct SimulationTelemetry: Codable, Equatable, Sendable {
    public var sessionId: String
    public var currentCoordinate: LocationCoordinate
    public var currentSpeedKmh: Double
    public var averageSpeedKmh: Double
    public var distanceTravelledMeters: Double
    public var distanceRemainingMeters: Double
    public var elapsedTimeSeconds: Double
    public var estimatedTimeRemainingSeconds: Double
    public var currentHeadingDegrees: Double
    public var state: SimulationState
    public var currentStop: StopPoint?
    public var progressPercentage: Double

    public init(
        sessionId: String,
        currentCoordinate: LocationCoordinate,
        currentSpeedKmh: Double,
        averageSpeedKmh: Double,
        distanceTravelledMeters: Double,
        distanceRemainingMeters: Double,
        elapsedTimeSeconds: Double,
        estimatedTimeRemainingSeconds: Double,
        currentHeadingDegrees: Double,
        state: SimulationState,
        currentStop: StopPoint? = nil,
        progressPercentage: Double = 0.0
    ) {
        self.sessionId = sessionId
        self.currentCoordinate = currentCoordinate
        self.currentSpeedKmh = currentSpeedKmh
        self.averageSpeedKmh = averageSpeedKmh
        self.distanceTravelledMeters = distanceTravelledMeters
        self.distanceRemainingMeters = distanceRemainingMeters
        self.elapsedTimeSeconds = elapsedTimeSeconds
        self.estimatedTimeRemainingSeconds = estimatedTimeRemainingSeconds
        self.currentHeadingDegrees = currentHeadingDegrees
        self.state = state
        self.currentStop = currentStop
        self.progressPercentage = progressPercentage
    }
}

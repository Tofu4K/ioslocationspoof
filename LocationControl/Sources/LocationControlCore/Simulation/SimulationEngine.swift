import Foundation

public final class SimulationEngine: SimulationEngineProtocol, @unchecked Sendable {
    public let route: RouteDefinition
    public var settings: SimulationSettings
    public let clock: ClockProtocol

    private let lock = NSLock()
    private var _state: SimulationState = .idle
    private var _startMonotonic: Double = 0.0
    private var _lastTickMonotonic: Double = 0.0
    private var _elapsedSimTime: Double = 0.0
    private var _currentDistanceMeters: Double = 0.0
    private var _currentSpeedMps: Double = 0.0
    private var _targetSpeedMps: Double = 0.0
    private var _currentHeading: Double = 0.0
    private var _activeStop: StopPoint? = nil
    private var _stopTimeRemaining: Double = 0.0
    private var _completedStopIds = Set<UUID>()
    private let sessionId: String

    public var onTelemetryUpdate: (@Sendable (SimulationTelemetry) -> Void)?

    public init(
        route: RouteDefinition,
        settings: SimulationSettings = SimulationSettings(),
        clock: ClockProtocol = SystemMonotonicClock()
    ) {
        self.route = route
        self.settings = settings
        self.clock = clock
        self.sessionId = UUID().uuidString
        self._targetSpeedMps = (settings.targetSpeedKmh * 1000.0) / 3600.0
        self._currentHeading = route.points.first?.headingDegrees ?? 0.0

        if !route.points.isEmpty {
            self._state = .ready
        }
    }

    public var state: SimulationState {
        lock.lock()
        defer { lock.unlock() }
        return _state
    }

    public var currentTelemetry: SimulationTelemetry {
        lock.lock()
        defer { lock.unlock() }
        return buildTelemetryLocked()
    }

    public func start() throws {
        lock.lock()
        defer { lock.unlock() }

        guard _state == .ready || _state == .idle else {
            throw NSError(domain: "SimulationEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot start simulation from state \(_state.rawValue)"])
        }

        let now = clock.now()
        _startMonotonic = now
        _lastTickMonotonic = now
        _state = .running
        emitTelemetryLocked()
    }

    public func pause() throws {
        lock.lock()
        defer { lock.unlock() }

        guard _state == .running else {
            throw NSError(domain: "SimulationEngine", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot pause simulation from state \(_state.rawValue)"])
        }

        _state = .paused
        emitTelemetryLocked()
    }

    public func resume() throws {
        lock.lock()
        defer { lock.unlock() }

        guard _state == .paused else {
            throw NSError(domain: "SimulationEngine", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot resume simulation from state \(_state.rawValue)"])
        }

        let now = clock.now()
        _lastTickMonotonic = now
        _state = .running
        emitTelemetryLocked()
    }

    public func stop() {
        lock.lock()
        defer { lock.unlock() }

        _state = .completed
        _currentSpeedMps = 0.0
        emitTelemetryLocked()
    }

    public func setSpeed(kmh: Double) throws {
        guard kmh > 0 && kmh <= 250 else {
            throw NSError(domain: "SimulationEngine", code: 4, userInfo: [NSLocalizedDescriptionKey: "Speed must be between 0 and 250 km/h"])
        }
        lock.lock()
        defer { lock.unlock() }
        settings.targetSpeedKmh = kmh
        _targetSpeedMps = (kmh * 1000.0) / 3600.0
    }

    public func seek(to percentage: Double) {
        lock.lock()
        defer { lock.unlock() }

        let clamped = max(0.0, min(100.0, percentage))
        _currentDistanceMeters = (clamped / 100.0) * route.totalDistanceMeters
        _activeStop = nil
        _stopTimeRemaining = 0.0

        if _currentDistanceMeters >= route.totalDistanceMeters {
            _state = .completed
            _currentSpeedMps = 0.0
        }
        emitTelemetryLocked()
    }

    public func tick() -> SimulationTelemetry {
        lock.lock()
        defer { lock.unlock() }

        guard _state == .running else {
            return buildTelemetryLocked()
        }

        let now = clock.now()
        let dt = now - _lastTickMonotonic
        _lastTickMonotonic = now

        guard dt > 0 else {
            return buildTelemetryLocked()
        }

        advanceSimulationLocked(dt: dt)
        return emitTelemetryLocked()
    }

    private func advanceSimulationLocked(dt: Double) {
        _elapsedSimTime += dt

        // If stopped at an active stop
        if let activeStop = _activeStop {
            _stopTimeRemaining -= dt
            _currentSpeedMps = 0.0
            if _stopTimeRemaining <= 0 {
                _completedStopIds.insert(activeStop.id)
                _activeStop = nil
                _stopTimeRemaining = 0.0
            }
            return
        }

        // Check for upcoming stops
        let upcomingStop = findNextUncompletedStopLocked()
        let accel = settings.accelerationProfile.accelerationMps2
        var targetSpeed = calculateCurrentTargetSpeedLocked()

        if let stop = upcomingStop {
            let distToStop = stop.routeDistanceMeters - _currentDistanceMeters
            let brakingDist = (_currentSpeedMps * _currentSpeedMps) / (2.0 * accel)

            if distToStop <= 0.5 {
                _activeStop = stop
                _stopTimeRemaining = stop.durationSeconds
                _currentSpeedMps = 0.0
                return
            } else if distToStop <= brakingDist + 5.0 {
                targetSpeed = 0.0
            }
        }

        // Apply acceleration or deceleration
        if _currentSpeedMps < targetSpeed {
            _currentSpeedMps = min(targetSpeed, _currentSpeedMps + accel * dt)
        } else if _currentSpeedMps > targetSpeed {
            _currentSpeedMps = max(targetSpeed, _currentSpeedMps - accel * dt)
        }

        // Distance advancement
        let moved = _currentSpeedMps * dt
        _currentDistanceMeters += moved

        if _currentDistanceMeters >= route.totalDistanceMeters {
            _currentDistanceMeters = route.totalDistanceMeters
            _state = .completed
            _currentSpeedMps = 0.0
        }
    }

    private func calculateCurrentTargetSpeedLocked() -> Double {
        let baseMps = (settings.targetSpeedKmh * 1000.0) / 3600.0
        if settings.speedVariationKmh > 0.0 {
            let varMps = (settings.speedVariationKmh * 1000.0) / 3600.0
            let variation = sin(_elapsedSimTime * 0.15) * varMps
            return max(1.0, baseMps + variation)
        }
        return baseMps
    }

    private func findNextUncompletedStopLocked() -> StopPoint? {
        route.stops.first { stop in
            !_completedStopIds.contains(stop.id) && stop.routeDistanceMeters >= _currentDistanceMeters
        }
    }

    private func interpolateCurrentPositionLocked() -> LocationCoordinate {
        guard !route.points.isEmpty else {
            return LocationCoordinate(latitude: 0, longitude: 0)
        }

        if _currentDistanceMeters <= 0.0 {
            _currentHeading = route.points[0].headingDegrees
            return route.points[0].coordinate
        }

        if _currentDistanceMeters >= route.totalDistanceMeters {
            _currentHeading = route.points.last?.headingDegrees ?? 0.0
            return route.points.last?.coordinate ?? LocationCoordinate(latitude: 0, longitude: 0)
        }

        for i in 0..<(route.points.count - 1) {
            let p1 = route.points[i]
            let p2 = route.points[i + 1]
            if p1.cumulativeDistanceMeters <= _currentDistanceMeters && _currentDistanceMeters <= p2.cumulativeDistanceMeters {
                let segLen = p2.cumulativeDistanceMeters - p1.cumulativeDistanceMeters
                let frac = segLen <= 0 ? 0 : (_currentDistanceMeters - p1.cumulativeDistanceMeters) / segLen
                _currentHeading = p2.headingDegrees
                return GeoMath.interpolateSegment(from: p1.coordinate, to: p2.coordinate, fraction: frac)
            }
        }

        return route.points.last?.coordinate ?? LocationCoordinate(latitude: 0, longitude: 0)
    }

    private func buildTelemetryLocked() -> SimulationTelemetry {
        let coord = interpolateCurrentPositionLocked()
        let currentKmh = (_currentSpeedMps * 3600.0) / 1000.0
        let remainingDist = max(0.0, route.totalDistanceMeters - _currentDistanceMeters)
        let eta = (remainingDist / (_targetSpeedMps > 0 ? _targetSpeedMps : 1.0))
        let pct = route.totalDistanceMeters > 0 ? (_currentDistanceMeters / route.totalDistanceMeters * 100.0) : 0.0

        return SimulationTelemetry(
            sessionId: sessionId,
            currentCoordinate: coord,
            currentSpeedKmh: currentKmh,
            averageSpeedKmh: settings.targetSpeedKmh,
            distanceTravelledMeters: _currentDistanceMeters,
            distanceRemainingMeters: remainingDist,
            elapsedTimeSeconds: _elapsedSimTime,
            estimatedTimeRemainingSeconds: eta,
            currentHeadingDegrees: _currentHeading,
            state: _state,
            currentStop: _activeStop,
            progressPercentage: (pct * 100).rounded() / 100
        )
    }

    @discardableResult
    private func emitTelemetryLocked() -> SimulationTelemetry {
        let telem = buildTelemetryLocked()
        if let cb = onTelemetryUpdate {
            cb(telem)
        }
        return telem
    }
}

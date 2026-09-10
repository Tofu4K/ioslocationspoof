import Foundation

public final class SystemMonotonicClock: ClockProtocol, @unchecked Sendable {
    public init() {}
    
    public func now() -> Double {
        ProcessInfo.processInfo.systemUptime
    }
}

public final class FakeClock: ClockProtocol, @unchecked Sendable {
    private var currentTime: Double
    private let lock = NSLock()

    public init(initialTime: Double = 0.0) {
        self.currentTime = initialTime
    }

    public func now() -> Double {
        lock.lock()
        defer { lock.unlock() }
        return currentTime
    }

    public func advance(by seconds: Double) {
        lock.lock()
        defer { lock.unlock() }
        currentTime += seconds
    }

    public func setTime(_ seconds: Double) {
        lock.lock()
        defer { lock.unlock() }
        currentTime = seconds
    }
}

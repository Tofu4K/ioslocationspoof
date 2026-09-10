import Foundation
import CoreLocation

public struct CapabilityItem: Identifiable, Sendable {
    public var id: String { name }
    public var name: String
    public var isAvailable: Bool
    public var detail: String
    public var notes: String?
}

@MainActor
public final class CapabilityRegistry: ObservableObject {
    @Published public private(set) var capabilities: [CapabilityItem] = []
    
    public init() {
        refreshCapabilities()
    }

    public func refreshCapabilities() {
        var items: [CapabilityItem] = []

        items.append(
            CapabilityItem(
                name: "MapKit Road Routing",
                isAvailable: true,
                detail: "High-precision driving directions & polyline extraction"
            )
        )

        items.append(
            CapabilityItem(
                name: "Kinematic Movement Engine",
                isAvailable: true,
                detail: "Time-based physics, smooth acceleration & variable speed"
            )
        )

        items.append(
            CapabilityItem(
                name: "Simulated Intersection Stops",
                isAvailable: true,
                detail: "Deterministic deceleration & pause scheduling"
            )
        )

        items.append(
            CapabilityItem(
                name: "GPX Track Export (Xcode Format)",
                isAvailable: true,
                detail: "Export timestamped GPX routes for Xcode scheme simulation"
            )
        )

        items.append(
            CapabilityItem(
                name: "PC Controller Network Bridge",
                isAvailable: true,
                detail: "WebSocket protocol active on port 8765"
            )
        )

        items.append(
            CapabilityItem(
                name: "System-Wide Third-Party App Injection",
                isAvailable: false,
                detail: "Requires paired Mac/PC running Xcode or RemoteXPC developer tunnel",
                notes: "iOS app sandbox prevents unprivileged global location modification"
            )
        )

        self.capabilities = items
    }
}

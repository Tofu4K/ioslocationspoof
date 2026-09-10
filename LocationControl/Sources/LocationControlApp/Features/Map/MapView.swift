import SwiftUI
import MapKit
import LocationControlCore

public struct MapContainerView: View {
    @ObservedObject var appState: AppState
    @State private var position: MapCameraPosition = .automatic

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                // Route Polyline
                if let route = appState.activeRoute, !route.points.isEmpty {
                    MapPolyline(coordinates: route.points.map { $0.coordinate.clCoordinate })
                        .stroke(DesignTokens.Colors.primaryAccent, lineWidth: 5)
                    
                    // Start Marker
                    Annotation("Start", coordinate: route.startCoordinate.clCoordinate) {
                        Image(systemName: "flag.fill")
                            .foregroundStyle(.green)
                            .padding(6)
                            .background(Circle().fill(.white))
                            .shadow(radius: 3)
                    }

                    // Destination Marker
                    Annotation("Destination", coordinate: route.destinationCoordinate.clCoordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.red)
                            .font(.title2)
                            .background(Circle().fill(.white))
                            .shadow(radius: 3)
                    }

                    // Simulated Stops
                    ForEach(route.stops) { stop in
                        Annotation(stop.label, coordinate: stop.coordinate.clCoordinate) {
                            Image(systemName: "octagon.fill")
                                .foregroundStyle(.orange)
                                .padding(4)
                                .background(Circle().fill(.white))
                                .shadow(radius: 2)
                        }
                    }
                }

                // Current Simulated Position
                if let telem = appState.liveTelemetry {
                    Annotation("Virtual Vehicle", coordinate: telem.currentCoordinate.clCoordinate) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.primaryAccent.opacity(0.25))
                                .frame(width: 36, height: 36)
                            Image(systemName: "location.north.circle.fill")
                                .font(.title)
                                .foregroundStyle(DesignTokens.Colors.primaryAccent)
                                .rotationEffect(.degrees(telem.currentHeadingDegrees))
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))

            // Floating Live Panel or Planning Card
            VStack(spacing: DesignTokens.Spacing.sm) {
                if appState.isSimulating, let telem = appState.liveTelemetry {
                    LiveSimulationPanel(appState: appState, telemetry: telem)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                } else if let route = appState.activeRoute {
                    RoutePreviewCard(appState: appState, route: route)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
        }
    }
}

public struct RoutePreviewCard: View {
    @ObservedObject var appState: AppState
    let route: RouteDefinition

    public var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(route.name)
                            .font(.headline)
                            .bold()
                        Text("\((route.totalDistanceMeters / 1000.0).formatted(.number.precision(.fractionLength(1)))) km • \(route.stops.count) simulated stops")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    Spacer()
                    StatusBadge(text: "Ready", isPositive: true)
                }

                HStack(spacing: 8) {
                    Button(action: {
                        appState.startSimulation()
                    }) {
                        Label("Start Driving", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(DesignTokens.Colors.emeraldSuccess)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.small))
                    }
                }
            }
        }
    }
}

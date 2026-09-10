import SwiftUI
import LocationControlCore

public struct LiveSimulationPanel: View {
    @ObservedObject var appState: AppState
    let telemetry: SimulationTelemetry

    public var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                // Header & Controls
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(telemetry.state == .running ? DesignTokens.Colors.emeraldSuccess : DesignTokens.Colors.amberWarning)
                                .frame(width: 8, height: 8)
                            Text("SIMULATION \(telemetry.state.rawValue)")
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                        Text("\(telemetry.currentSpeedKmh.formatted(.number.precision(.fractionLength(0)))) km/h")
                            .font(.title2)
                            .bold()
                    }
                    Spacer()

                    // Play/Pause & Stop
                    HStack(spacing: 8) {
                        Button(action: {
                            if appState.isPaused {
                                appState.resumeSimulation()
                            } else {
                                appState.pauseSimulation()
                            }
                        }) {
                            Image(systemName: appState.isPaused ? "play.fill" : "pause.fill")
                                .padding(10)
                                .background(DesignTokens.Colors.elevatedBackground)
                                .clipShape(Circle())
                        }

                        Button(action: {
                            appState.stopSimulation()
                        }) {
                            Image(systemName: "stop.fill")
                                .foregroundStyle(.red)
                                .padding(10)
                                .background(DesignTokens.Colors.elevatedBackground)
                                .clipShape(Circle())
                        }
                    }
                }

                // Metric Grid
                HStack(spacing: 8) {
                    MetricTile(
                        title: "Remaining",
                        value: "\((telemetry.distanceRemainingMeters / 1000.0).formatted(.number.precision(.fractionLength(1)))) km",
                        icon: "arrow.triangle.swap",
                        accentColor: .blue
                    )
                    MetricTile(
                        title: "Progress",
                        value: "\(telemetry.progressPercentage.formatted(.number.precision(.fractionLength(0))))%",
                        icon: "chart.bar.fill",
                        accentColor: .green
                    )
                    MetricTile(
                        title: "Heading",
                        value: "\(telemetry.currentHeadingDegrees.formatted(.number.precision(.fractionLength(0))))°",
                        icon: "location.north",
                        accentColor: .purple
                    )
                }

                // Timeline Scrubber
                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { telemetry.progressPercentage },
                            set: { appState.seekSimulation(to: $0) }
                        ),
                        in: 0...100
                    )
                }
            }
        }
    }
}

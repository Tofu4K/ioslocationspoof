import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import LocationControlCore

public struct SavedItemsView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Saved Routes")) {
                    if appState.savedRoutes.isEmpty {
                        Text("No saved routes yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(appState.savedRoutes) { route in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(route.name)
                                    .font(.headline)
                                Text("\((route.totalDistanceMeters / 1000.0).formatted(.number.precision(.fractionLength(1)))) km • \(route.points.count) points")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .onTapGesture {
                                appState.activeRoute = route
                                appState.setupSimulationEngine(for: route)
                                appState.currentTab = .map
                            }
                        }
                    }
                }

                Section(header: Text("Export GPX")) {
                    if let route = appState.activeRoute {
                        Button(action: {
                            let gpx = GPXService.exportGPX(route: route, settings: appState.simulationSettings)
                            #if canImport(UIKit)
                            UIPasteboard.general.string = gpx
                            #endif
                        }) {
                            Label("Copy Active Route GPX (Xcode Format)", systemImage: "doc.on.doc")
                        }
                    } else {
                        Text("Calculate a route to export GPX.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Saved & Export")
            .task {
                await appState.loadSavedData()
            }
        }
    }
}

import SwiftUI
import LocationControlCore

public struct RoutePlannerView: View {
    @ObservedObject var appState: AppState
    @State private var startLatText = "52.2297"
    @State private var startLonText = "21.0122"
    @State private var destLatText = "50.0647"
    @State private var destLonText = "19.9450"

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Point A (Origin)")) {
                    HStack {
                        Text("Lat")
                            .frame(width: 40, alignment: .leading)
                        TextField("Latitude", text: $startLatText)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                    HStack {
                        Text("Lon")
                            .frame(width: 40, alignment: .leading)
                        TextField("Longitude", text: $startLonText)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }

                Section(header: Text("Point B (Destination)")) {
                    HStack {
                        Text("Lat")
                            .frame(width: 40, alignment: .leading)
                        TextField("Latitude", text: $destLatText)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                    HStack {
                        Text("Lon")
                            .frame(width: 40, alignment: .leading)
                        TextField("Longitude", text: $destLonText)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }

                Section(header: Text("Simulation Profile")) {
                    HStack {
                        Text("Speed")
                        Spacer()
                        Text("\(Int(appState.simulationSettings.targetSpeedKmh)) km/h")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $appState.simulationSettings.targetSpeedKmh, in: 10...140, step: 5)

                    Toggle("Simulate Stops", isOn: $appState.simulationSettings.simulateStops)
                    
                    Picker("Acceleration", selection: $appState.simulationSettings.accelerationProfile) {
                        ForEach(AccelerationProfile.allCases, id: \.self) { profile in
                            Text(profile.rawValue.capitalized).tag(profile)
                        }
                    }
                }

                Section {
                    Button(action: {
                        if let sLat = Double(startLatText), let sLon = Double(startLonText),
                           let dLat = Double(destLatText), let dLon = Double(destLonText) {
                            appState.startCoordinate = LocationCoordinate(latitude: sLat, longitude: sLon)
                            appState.destinationCoordinate = LocationCoordinate(latitude: dLat, longitude: dLon)
                            Task {
                                await appState.calculateCurrentRoute()
                                appState.currentTab = .map
                            }
                        }
                    }) {
                        if appState.isCalculatingRoute {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Calculate Road Route")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Route Planner")
        }
    }
}

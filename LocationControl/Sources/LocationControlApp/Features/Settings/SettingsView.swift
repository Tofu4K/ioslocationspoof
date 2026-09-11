import SwiftUI
import LocationControlCore

public struct SettingsView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("PC Companion Connection")) {
                    Text("Connect to 'locationctl serve' on your PC over local Wi-Fi or USB.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: "desktopcomputer")
                            .foregroundStyle(.blue)
                        TextField("http://192.168.1.XX:8765", text: $appState.backendApiUrl)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    Button("Test Connection") {
                        Task {
                            await appState.checkBackendStatus()
                        }
                    }

                    if appState.isBackendReachable {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Connected to PC Controller")
                            Spacer()
                            Text(appState.connectedDeviceName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Not connected. Run 'locationctl serve' on PC.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(header: Text("Units & Speed")) {

                    Picker("Speed Unit", selection: $appState.simulationSettings.speedUnit) {
                        ForEach(SpeedUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    
                    HStack {
                        Text("Default Target Speed")
                        Spacer()
                        Text("\(Int(appState.simulationSettings.targetSpeedKmh)) km/h")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $appState.simulationSettings.targetSpeedKmh, in: 10...140, step: 5)
                }

                Section(header: Text("Simulation Physics")) {
                    Picker("Acceleration Profile", selection: $appState.simulationSettings.accelerationProfile) {
                        ForEach(AccelerationProfile.allCases, id: \.self) { profile in
                            Text(profile.rawValue.capitalized).tag(profile)
                        }
                    }

                    Toggle("Simulate Stops", isOn: $appState.simulationSettings.simulateStops)
                    
                    if appState.simulationSettings.simulateStops {
                        Picker("Stop Frequency", selection: $appState.simulationSettings.stopFrequency) {
                            ForEach(StopFrequency.allCases, id: \.self) { freq in
                                Text(freq.rawValue.capitalized).tag(freq)
                            }
                        }
                    }
                }

                Section(header: Text("Map & Camera")) {
                    Toggle("Follow Camera", isOn: $appState.simulationSettings.followCamera)
                    Toggle("Rotate With Heading", isOn: $appState.simulationSettings.rotateWithHeading)
                }

                Section(header: Text("About")) {
                    LabeledContent("Suite Version", value: "1.0.0 (Production)")
                    LabeledContent("Build Target", value: "iOS 17.0+")
                    LabeledContent("Developer Mode", value: "iOS 16+ Required for Tethered Override")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

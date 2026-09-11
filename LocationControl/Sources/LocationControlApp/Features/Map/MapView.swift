import SwiftUI
import MapKit
import LocationControlCore

public struct MapContainerView: View {
    @ObservedObject var appState: AppState
    @State private var position: MapCameraPosition = .automatic
    @State private var searchQuery: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching: Bool = false
    @State private var showConnectionSheet: Bool = false
    @State private var tempBackendUrl: String = ""

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Fullscreen Interactive Map
            MapReader { proxy in
                Map(position: $position) {
                    if let selected = appState.selectedPinCoordinate {
                        Annotation("Target Location", coordinate: selected.clCoordinate) {
                            ZStack {
                                Circle()
                                    .fill(appState.isHardwareSpoofing ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundStyle(appState.isHardwareSpoofing ? Color.green : Color.blue)
                                    .shadow(radius: 6)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .onTapGesture { screenCoord in
                    if let location = proxy.convert(screenCoord, from: .local) {
                        appState.selectedPinCoordinate = LocationCoordinate(
                            latitude: location.latitude,
                            longitude: location.longitude
                        )
                        appState.reverseGeocodeSelectedCoordinate()
                    }
                }
            }
            .ignoresSafeArea()

            // Top Overlay: Search Bar & Connection Status
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search city or landmark...", text: $searchQuery)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit {
                                performSearch()
                            }
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = ""; searchResults = [] }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground).opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)

                    // Connection Badge Button
                    Button(action: {
                        tempBackendUrl = appState.backendApiUrl
                        showConnectionSheet = true
                    }) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(appState.isBackendReachable ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Image(systemName: "desktopcomputer")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground).opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Search Results Dropdown List
                if !searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(searchResults.prefix(4), id: \.self) { item in
                            Button(action: {
                                selectSearchResult(item)
                            }) {
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundStyle(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name ?? "Unknown")
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        Text(item.placemark.title ?? "")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                            Divider()
                        }
                    }
                    .background(Color(.systemBackground).opacity(0.96))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)
                }

                Spacer()

                // Bottom Floating Control Card
                VStack(spacing: 8) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("TARGET LOCATION")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                                    if let coord = appState.selectedPinCoordinate {
                                        Text("\(coord.latitude.formatted(.number.precision(.fractionLength(4)))), \(coord.longitude.formatted(.number.precision(.fractionLength(4))))")
                                            .font(.system(.title3, design: .monospaced))
                                            .fontWeight(.bold)
                                        Text(appState.selectedAddressLabel)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    } else {
                                        Text("Tap on map to select")
                                            .font(.headline)
                                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                                    }
                                }

                                Spacer()

                                StatusBadge(
                                    text: appState.isHardwareSpoofing ? "SPOOFING ACTIVE" : "READY",
                                    isPositive: appState.isHardwareSpoofing
                                )
                            }

                            if !appState.hardwareSpoofStatus.isEmpty && appState.hardwareSpoofStatus != "Ready" {
                                Text(appState.hardwareSpoofStatus)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(appState.isHardwareSpoofing ? DesignTokens.Colors.emeraldSuccess : .red)
                            }

                            // Dynamic Action Buttons
                            if appState.isHardwareSpoofing {
                                HStack(spacing: 10) {
                                    Button(action: {
                                        Task {
                                            await appState.spoofSelectedLocation()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                            Text("UPDATE")
                                        }
                                        .font(.headline)
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.blue)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.small))
                                    }

                                    Button(action: {
                                        Task {
                                            await appState.stopHardwareSpoofing()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "stop.fill")
                                            Text("STOP")
                                        }
                                        .font(.headline)
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.red)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.small))
                                    }
                                }
                            } else {
                                Button(action: {
                                    Task {
                                        await appState.spoofSelectedLocation()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "location.fill")
                                        Text("SPOOF")
                                    }
                                    .font(.headline)
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(appState.selectedPinCoordinate == nil ? Color.gray : DesignTokens.Colors.primaryAccent)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.small))
                                }
                                .disabled(appState.selectedPinCoordinate == nil)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .task {
            await appState.checkBackendStatus()
            appState.reverseGeocodeSelectedCoordinate()
        }
        .sheet(isPresented: $showConnectionSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("PC Companion Server")) {
                        Text("Enter the IP address of the PC running locationctl serve on your Wi-Fi network.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("http://192.168.1.XX:8765", text: $tempBackendUrl)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Button("Test Connection") {
                            Task {
                                appState.backendApiUrl = tempBackendUrl
                                await appState.checkBackendStatus()
                            }
                        }

                        if appState.isBackendReachable {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Connected to PC Controller")
                            }
                        } else {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text("Not reached. Check IP and port 8765.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section {
                        Button("Save & Close") {
                            appState.backendApiUrl = tempBackendUrl
                            showConnectionSheet = false
                        }
                        .bold()
                        .frame(maxWidth: .infinity)
                    }
                }
                .navigationTitle("Companion Setup")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
        }
    }

    private func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = searchQuery
        MKLocalSearch(request: req).start { response, _ in
            if let mapItems = response?.mapItems {
                DispatchQueue.main.async {
                    self.searchResults = mapItems
                }
            }
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        let coord = item.placemark.coordinate
        appState.selectedPinCoordinate = LocationCoordinate(latitude: coord.latitude, longitude: coord.longitude)
        appState.selectedAddressLabel = item.name ?? item.placemark.title ?? "Selected Landmark"
        searchResults = []
        searchQuery = ""
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
}

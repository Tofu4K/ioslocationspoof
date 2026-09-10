import SwiftUI
import LocationControlCore

@main
public struct LocationControlApp: App {
    @StateObject private var appState = AppState()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            TabView(selection: $appState.currentTab) {
                MapContainerView(appState: appState)
                    .tabItem {
                        Label(AppState.NavigationTab.map.rawValue, systemImage: AppState.NavigationTab.map.icon)
                    }
                    .tag(AppState.NavigationTab.map)

                RoutePlannerView(appState: appState)
                    .tabItem {
                        Label(AppState.NavigationTab.planner.rawValue, systemImage: AppState.NavigationTab.planner.icon)
                    }
                    .tag(AppState.NavigationTab.planner)

                SavedItemsView(appState: appState)
                    .tabItem {
                        Label(AppState.NavigationTab.saved.rawValue, systemImage: AppState.NavigationTab.saved.icon)
                    }
                    .tag(AppState.NavigationTab.saved)

                DiagnosticsView(appState: appState)
                    .tabItem {
                        Label(AppState.NavigationTab.diagnostics.rawValue, systemImage: AppState.NavigationTab.diagnostics.icon)
                    }
                    .tag(AppState.NavigationTab.diagnostics)

                SettingsView(appState: appState)
                    .tabItem {
                        Label(AppState.NavigationTab.settings.rawValue, systemImage: AppState.NavigationTab.settings.icon)
                    }
                    .tag(AppState.NavigationTab.settings)
            }
            .task {
                await appState.calculateCurrentRoute()
            }
        }
    }
}

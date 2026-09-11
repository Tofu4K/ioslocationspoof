import SwiftUI
#if canImport(WebKit)
import WebKit
#endif
import LocationControlCore

public struct WebControllerView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                #if canImport(WebKit) && os(iOS)
                WebViewRepresentable(url: URL(string: appState.backendApiUrl) ?? URL(string: "http://localhost:8765")!)
                    .ignoresSafeArea(edges: .bottom)
                #else
                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    Text("Web Companion View")
                        .font(.headline)
                    Text("Connecting to \(appState.backendApiUrl)...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                #endif
            }
            .navigationTitle("Web Controller")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await appState.checkBackendStatus()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

#if canImport(WebKit) && os(iOS)
struct WebViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.bounces = false
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
}
#endif

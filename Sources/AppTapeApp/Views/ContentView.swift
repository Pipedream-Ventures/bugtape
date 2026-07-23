import SwiftUI

struct ContentView: View {
    @ObservedObject var store: AppTapeStore

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            switch store.selection {
            case .capture:
                CaptureView(store: store)
            case .bundle(let url):
                if let record = store.records.first(where: { $0.url == url }) {
                    BundleDetailView(store: store, record: record)
                } else {
                    ContentUnavailableView(
                        "Tape not found",
                        systemImage: "film.stack",
                        description: Text("Refresh the library or create a new tape.")
                    )
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(AppTapeStyle.ink)
        .background(AppTapeStyle.paper)
    }
}

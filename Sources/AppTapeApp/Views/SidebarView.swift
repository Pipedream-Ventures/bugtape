import SwiftUI

struct SidebarView: View {
    @ObservedObject var store: AppTapeStore

    var body: some View {
        List(selection: $store.selection) {
            Section {
                VStack(alignment: .leading, spacing: 0) {
                    Text("TAPE")
                        .font(.system(size: 34, weight: .black))
                        .tracking(-2)
                }
                .foregroundStyle(AppTapeStyle.ink)
                .padding(.vertical, 8)
            }

            Section {
                Label("NEW TAPE", systemImage: "record.circle")
                    .tag(AppTapeSelection.capture)
            }

            Section("ARCHIVE") {
                if store.records.isEmpty {
                    Text("Your tapes will appear here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.records) { record in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.title)
                                .lineLimit(1)
                            Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(AppTapeSelection.bundle(record.url))
                        .contextMenu {
                            Button("Show in Finder") {
                                store.reveal(record.url)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("TAPE")
        .toolbar {
            ToolbarItem {
                Button {
                    store.startNewTape()
                } label: {
                    Label("New Tape", systemImage: "plus")
                }
            }
        }
    }
}

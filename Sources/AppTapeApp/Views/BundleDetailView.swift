import AppKit
import SwiftUI

struct BundleDetailView: View {
    @ObservedObject var store: AppTapeStore
    let record: AppTapeBundleRecord

    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header

                if let summary = record.manifest.summary, !summary.isEmpty {
                    summarySection(summary)
                }

                recordingSummary

                if !record.manifest.observations.isEmpty {
                    timeline
                }

                frames
            }
            .frame(maxWidth: 980, alignment: .leading)
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .navigationTitle(record.title)
        .background(AppTapeStyle.paper)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    store.open(record.reportURL)
                } label: {
                    Label("Open Report", systemImage: "doc.text")
                }

                Button {
                    store.reveal(record.url)
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                }
            }
        }
    }

    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                eyebrow: "IN THEIR WORDS",
                title: "What happened",
                detail: "The tester’s intent, preserved separately from captured evidence."
            )

            Text(summary)
                .font(.system(.body, design: .monospaced))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appTapeCard()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                Rectangle()
                    .fill(AppTapeStyle.ink)
                Image(systemName: "film.stack")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppTapeStyle.signal)
            }
            .frame(width: 68, height: 68)

            VStack(alignment: .leading, spacing: 6) {
                Text(record.title)
                    .font(.system(size: 30, weight: .black))
                Text("Agent-ready tape · \(record.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var recordingSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Recording",
                detail: record.manifest.source.isBundled
                    ? "The original recording is portable inside this tape."
                    : "The original was intentionally left outside this compact tape."
            )

            HStack(spacing: 28) {
                Metric(label: "Duration", value: record.manifest.video.durationText)
                Metric(
                    label: "Size",
                    value: ByteCountFormatter.string(
                        fromByteCount: record.manifest.video.fileSizeBytes,
                        countStyle: .file
                    )
                )
                Metric(
                    label: "Evidence",
                    value: "\(record.manifest.frames.count) frames"
                )
                Metric(
                    label: "Audio",
                    value: record.manifest.video.hasAudio ? "Included" : "None"
                )
                Spacer()
            }
            .appTapeCard()
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Timeline",
                detail: "\(record.manifest.observations.count) explicit observations"
            )

            VStack(spacing: 0) {
                ForEach(record.manifest.observations, id: \.id) { observation in
                    HStack(alignment: .top, spacing: 16) {
                        Text(observation.startSeconds.map(AppTapeFormat.timestamp) ?? "—")
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                            .foregroundStyle(AppTapeStyle.ink)
                            .frame(width: 74, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            if let label = observation.label {
                                Text(label.uppercased())
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            Text(observation.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 12)

                    if observation.id != record.manifest.observations.last?.id {
                        Divider()
                    }
                }
            }
            .appTapeCard()
        }
    }

    private var frames: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Evidence frames",
                detail: "Open the report for the complete agent instructions and linked timestamps."
            )

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(record.manifest.frames, id: \.relativePath) { frame in
                    let frameURL = record.url.appendingPathComponent(frame.relativePath)
                    VStack(alignment: .leading, spacing: 8) {
                        if let image = NSImage(contentsOf: frameURL) {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .background(.black)
                                .clipShape(.rect(cornerRadius: 10))
                        }
                        Text(AppTapeFormat.timestamp(frame.timestampSeconds))
                            .font(.system(.caption, design: .monospaced).weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 14))
                    .onTapGesture {
                        store.open(frameURL)
                    }
                }
            }
        }
    }
}

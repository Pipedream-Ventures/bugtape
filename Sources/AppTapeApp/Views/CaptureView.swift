import SwiftUI

struct CaptureView: View {
    @ObservedObject var store: AppTapeStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                hero
                sourceSection

                if store.sourceURL != nil {
                    summarySection
                    notesSection
                    buildSection
                }
            }
            .frame(maxWidth: 920, alignment: .leading)
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .navigationTitle("New Tape")
        .background(AppTapeStyle.paper)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    Task {
                        await store.importRecording()
                    }
                } label: {
                    Label("Import Recording", systemImage: "square.and.arrow.down")
                }

                Button {
                    store.reveal(store.outputRoot)
                } label: {
                    Label("Open TAPE Folder", systemImage: "folder")
                }
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                eyebrow: "02 / TL;DR",
                title: "What happened?",
                detail: "Give the agent the point in a few sentences."
            )

            TextEditor(text: $store.summary)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(minHeight: 110)
                .background(Color.white)
                .overlay(alignment: .topLeading) {
                    if store.summary.isEmpty {
                        Text("I tested Paco’s first-run flow on my phone. The schedule was clear, but the brand mark and protocol icons felt like competing logos. I want one obvious visual system.")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(Color.black.opacity(0.35))
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }
                .appTapeCard()
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 22) {
            ZStack {
                Rectangle()
                    .fill(AppTapeStyle.ink)
                Image(systemName: "record.circle")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(AppTapeStyle.signal)
            }
            .frame(width: 82, height: 82)
            .rotationEffect(.degrees(-2))

            VStack(alignment: .leading, spacing: 7) {
                Text("MAKE A TAPE.")
                    .font(.system(size: 42, weight: .black))
                    .tracking(-1.8)
                Text("Record. Explain. Hand it off.")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(AppTapeStyle.ink.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)

                Text("QA  ·  INSPO  ·  COMPETITORS  ·  WALKTHROUGHS")
                    .font(.system(.caption2, design: .monospaced).weight(.black))
                    .tracking(1)
                    .foregroundStyle(AppTapeStyle.ink.opacity(0.42))
            }
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                eyebrow: "01 / CAPTURE",
                title: "Recording",
                detail: "Choose a screen or window."
            )

            if let sourceURL = store.sourceURL {
                VStack(alignment: .leading, spacing: 16) {
                    VideoPreview(url: sourceURL)
                        .frame(height: 320)
                        .clipShape(.rect(cornerRadius: 16))

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sourceURL.lastPathComponent)
                                .font(.headline)
                                .lineLimit(1)
                            if let metadata = store.sourceMetadata {
                                Text(metadata.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else if store.isInspecting {
                                Text("Reading recording…")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("Change…") {
                            Task {
                                await store.importRecording()
                            }
                        }
                    }
                }
                .appTapeCard()
            } else {
                VStack(spacing: 18) {
                    HStack(spacing: 10) {
                        CaptureStatusBadge(
                            symbol: "rectangle.dashed",
                            label: "SCREEN",
                            status: store.screenCaptureStatus
                        )
                        CaptureStatusBadge(
                            symbol: "mic",
                            label: "MIC",
                            status: store.microphoneStatus
                        )
                        Spacer()
                        Toggle("MIC", isOn: $store.includesMicrophone)
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .toggleStyle(.switch)
                    }

                    if store.isRecording {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(AppTapeStyle.live)
                                .frame(width: 12, height: 12)
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                Text(recordingTime(at: context.date))
                                    .font(.system(size: 30, weight: .black, design: .monospaced))
                            }
                            Spacer()
                            Button {
                                Task {
                                    await store.stopRecording()
                                }
                            } label: {
                                Text("STOP")
                                    .font(.system(.headline, design: .monospaced).weight(.black))
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 150, minHeight: 34)
                                    .padding(.horizontal, 18)
                                    .background(AppTapeStyle.live)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button {
                            Task {
                                await store.recordScreen()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "record.circle")
                                Text("TAPE")
                                    .font(.system(size: 24, weight: .black, design: .monospaced))
                                    .tracking(2)
                            }
                            .foregroundStyle(AppTapeStyle.signal)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(AppTapeStyle.ink)
                        }
                        .buttonStyle(.plain)
                    }

                    HStack {
                        Text("Choose a display or region in Apple’s toolbar. Stop here or from the menu bar.")
                            .font(.caption)
                            .foregroundStyle(AppTapeStyle.ink.opacity(0.55))
                        Spacer()
                        Button("USE EXISTING VIDEO…") {
                            Task {
                                await store.importRecording()
                            }
                        }
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                    }
                }
                .appTapeCard()
            }

            StatusMessages(store: store)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                eyebrow: "03 / NOTES",
                title: "Timestamped observations",
                detail: "Optional."
            )

            TextEditor(text: $store.notes)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(minHeight: 150)
                .background(.quaternary.opacity(0.45), in: .rect(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if store.notes.isEmpty {
                        Text("00:08 bug The CTA overlaps the tab bar\n00:21 idea Keep this transition\n00:35 expected The saved plan should appear")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }
                .appTapeCard()
        }
    }

    private var buildSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                eyebrow: "04 / PACKAGE",
                title: "Build tape",
                detail: "Frames, notes, metadata, and source."
            )

            VStack(alignment: .leading, spacing: 16) {
                TextField("Tape title", text: $store.title)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3.weight(.semibold))

                Toggle(
                    "Copy the original recording into the bundle",
                    isOn: $store.includesSourceInBundle
                )

                Text(
                    store.includesSourceInBundle
                        ? "Portable but larger. Best for a short QA session you will hand to another agent or machine."
                        : "Compact. The original stays in Movies/TAPE/Recordings."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack {
                    Spacer()
                    Button {
                        Task {
                            await store.buildTape()
                        }
                    } label: {
                        HStack {
                            if store.isBuilding {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Label("Build Tape", systemImage: "wand.and.stars")
                        }
                        .frame(minWidth: 150)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(store.isBuilding)
                }
            }
            .appTapeCard()

            StatusMessages(store: store)
        }
    }

    private func recordingTime(at date: Date) -> String {
        guard let startedAt = store.recordingStartedAt else {
            return "00:00"
        }
        return AppTapeFormat.timestamp(date.timeIntervalSince(startedAt))
    }
}

import AppKit
import AVFoundation
import BugTapeCore
import Combine
import CoreGraphics
import Foundation
import UniformTypeIdentifiers

@MainActor
final class AppTapeStore: ObservableObject {
    @Published var selection: AppTapeSelection = .capture
    @Published var records: [AppTapeBundleRecord] = []
    @Published var title = ""
    @Published var summary = ""
    @Published var notes = ""
    @Published var sourceURL: URL?
    @Published var sourceMetadata: VideoMetadata?
    @Published var includesMicrophone = true
    @Published var includesSourceInBundle = true
    @Published var isRecording = false
    @Published var recordingStartedAt: Date?
    @Published var isInspecting = false
    @Published var isBuilding = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    let outputRoot: URL
    private let recorder = ScreenRecordingService()
    private let userDefaults: UserDefaults
    private let screenCaptureRequestKey = "didRequestScreenCaptureAccess"
    private let pendingRecordingPathKey = "pendingRecordingPath"

    init(
        outputRoot: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Movies/TAPE", isDirectory: true),
        userDefaults: UserDefaults = .standard
    ) {
        self.outputRoot = outputRoot
        self.userDefaults = userDefaults
        refreshBundles()
        recoverPendingRecording()
    }

    func startNewTape() {
        selection = .capture
        title = ""
        summary = ""
        notes = ""
        sourceURL = nil
        sourceMetadata = nil
        includesMicrophone = true
        includesSourceInBundle = true
        errorMessage = nil
        successMessage = nil
    }

    func recordScreen() async {
        errorMessage = nil
        successMessage = nil

        guard requestScreenCaptureAccess() else {
            return
        }
        guard await requestMicrophoneAccessIfNeeded() else {
            return
        }

        isRecording = true
        recordingStartedAt = .now
        defer {
            isRecording = false
            recordingStartedAt = nil
        }

        do {
            let recordingsDirectory = outputRoot.appendingPathComponent(
                "Recordings",
                isDirectory: true
            )
            try FileManager.default.createDirectory(
                at: recordingsDirectory,
                withIntermediateDirectories: true
            )
            let recordingURL = recordingsDirectory.appendingPathComponent(
                "TAPE-\(Self.fileTimestamp()).mov"
            )
            userDefaults.set(recordingURL.path, forKey: pendingRecordingPathKey)
            let capturedURL = try await recorder.record(
                to: recordingURL,
                includesAudio: includesMicrophone
            )
            prepareDraft(
                for: capturedURL,
                suggestedTitle: "Tape \(Date.now.formatted(date: .abbreviated, time: .shortened))"
            )
            await selectSource(capturedURL)
            userDefaults.removeObject(forKey: pendingRecordingPathKey)
            successMessage = "Recording saved."
        } catch {
            clearPendingRecordingIfMissing()
            errorMessage = error.localizedDescription
        }
    }

    func stopRecording() async {
        await recorder.stop()
    }

    var screenCaptureStatus: CaptureReadiness {
        if CGPreflightScreenCaptureAccess() {
            return .ready
        }
        if UserDefaults.standard.bool(forKey: screenCaptureRequestKey) {
            return .blocked
        }
        return .willPrompt
    }

    var microphoneStatus: CaptureReadiness {
        guard includesMicrophone else {
            return .off
        }
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .ready
        case .denied, .restricted:
            return .blocked
        case .notDetermined:
            return .willPrompt
        @unknown default:
            return .willPrompt
        }
    }

    private func requestScreenCaptureAccess() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }

        UserDefaults.standard.set(true, forKey: screenCaptureRequestKey)
        if CGRequestScreenCaptureAccess() {
            return true
        }

        errorMessage = "Allow TAPE in Privacy & Security → Screen & System Audio Recording, then reopen TAPE."
        openPrivacySettings(anchor: "Privacy_ScreenCapture")
        return false
    }

    private func requestMicrophoneAccessIfNeeded() async -> Bool {
        guard includesMicrophone else {
            return true
        }

        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .authorized {
            return true
        }
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            if granted {
                return true
            }
        }

        errorMessage = "Allow TAPE to use the microphone in Privacy & Security → Microphone."
        openPrivacySettings(anchor: "Privacy_Microphone")
        return false
    }

    private func openPrivacySettings(anchor: String) {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func importRecording() async {
        let panel = NSOpenPanel()
        panel.title = "Choose an app recording"
        panel.prompt = "Use Recording"
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        prepareDraft(
            for: url,
            suggestedTitle: url.deletingPathExtension().lastPathComponent
        )
        await selectSource(url)
    }

    func buildTape() async {
        guard let sourceURL else {
            errorMessage = "Record or import a video first."
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = "Give this tape a short title."
            return
        }
        let cleanSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanSummary.isEmpty else {
            errorMessage = "Add a quick TL;DR of what you recorded."
            return
        }

        errorMessage = nil
        successMessage = nil
        isBuilding = true
        defer {
            isBuilding = false
        }

        var temporaryNotesURL: URL?
        do {
            try FileManager.default.createDirectory(
                at: outputRoot,
                withIntermediateDirectories: true
            )

            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedNotes.isEmpty {
                let notesURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("apptape-\(UUID().uuidString).txt")
                try trimmedNotes.write(
                    to: notesURL,
                    atomically: true,
                    encoding: .utf8
                )
                temporaryNotesURL = notesURL
            }

            let bundleURL = uniqueBundleURL(title: cleanTitle)
            let request = BundleRequest(
                videoURL: sourceURL,
                outputURL: bundleURL,
                title: cleanTitle,
                summary: cleanSummary,
                transcriptURL: nil,
                notesURL: temporaryNotesURL,
                frameIntervalSeconds: 15,
                includeSourceVideo: includesSourceInBundle
            )
            _ = try await BundleCompiler.compile(request)
            if let temporaryNotesURL {
                try? FileManager.default.removeItem(at: temporaryNotesURL)
            }
            refreshBundles()
            selection = .bundle(bundleURL)
            successMessage = "Tape built and ready for an agent."
        } catch {
            if let temporaryNotesURL {
                try? FileManager.default.removeItem(at: temporaryNotesURL)
            }
            errorMessage = error.localizedDescription
        }
    }

    func refreshBundles() {
        do {
            try FileManager.default.createDirectory(
                at: outputRoot,
                withIntermediateDirectories: true
            )
            let urls = try FileManager.default.contentsOfDirectory(
                at: outputRoot,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            records = urls.compactMap { url in
                guard url.lastPathComponent != "Recordings" else {
                    return nil
                }
                let manifestURL = url.appendingPathComponent("manifest.json")
                guard
                    let data = try? Data(contentsOf: manifestURL),
                    let manifest = try? decoder.decode(BugTapeManifest.self, from: data)
                else {
                    return nil
                }
                return AppTapeBundleRecord(url: url, manifest: manifest)
            }
            .sorted { $0.createdAt > $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    private func selectSource(_ url: URL) async {
        sourceURL = url
        sourceMetadata = nil
        errorMessage = nil
        isInspecting = true
        defer {
            isInspecting = false
        }

        do {
            sourceMetadata = try await MediaInspector.inspect(url: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func prepareDraft(for url: URL, suggestedTitle: String) {
        sourceURL = url
        sourceMetadata = nil
        title = suggestedTitle
        summary = ""
        notes = ""
        includesSourceInBundle = true
        errorMessage = nil
        successMessage = nil
    }

    private func recoverPendingRecording() {
        guard
            let path = userDefaults.string(forKey: pendingRecordingPathKey),
            !path.isEmpty
        else {
            return
        }

        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            userDefaults.removeObject(forKey: pendingRecordingPathKey)
            return
        }

        prepareDraft(
            for: url,
            suggestedTitle: url.deletingPathExtension().lastPathComponent
        )
        successMessage = "Recovered your last recording."
        userDefaults.removeObject(forKey: pendingRecordingPathKey)

        Task {
            await selectSource(url)
        }
    }

    private func clearPendingRecordingIfMissing() {
        guard
            let path = userDefaults.string(forKey: pendingRecordingPathKey),
            !FileManager.default.fileExists(atPath: path)
        else {
            return
        }
        userDefaults.removeObject(forKey: pendingRecordingPathKey)
    }

    private func uniqueBundleURL(title: String) -> URL {
        let slug = title
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .prefix(8)
            .joined(separator: "-")
        let safeSlug = slug.isEmpty ? "tape" : slug
        return outputRoot.appendingPathComponent(
            "\(safeSlug)-\(Self.fileTimestamp())",
            isDirectory: true
        )
    }

    private static func fileTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: .now)
    }
}

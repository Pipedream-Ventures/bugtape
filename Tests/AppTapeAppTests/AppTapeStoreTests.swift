import Foundation
import Testing
@testable import AppTapeApp

@MainActor
@Test
func selectingANewSourceClearsFeedbackFromThePreviousRecording() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
    let store = AppTapeStore(outputRoot: root, userDefaults: defaults)
    store.title = "Old title"
    store.summary = "Feedback about the old recording"
    store.notes = "00:04 bug Old observation"
    store.includesSourceInBundle = false

    let newSource = root.appendingPathComponent("new-device-qa.mov")
    store.prepareDraft(for: newSource, suggestedTitle: "new-device-qa")

    #expect(store.sourceURL == newSource)
    #expect(store.title == "new-device-qa")
    #expect(store.summary.isEmpty)
    #expect(store.notes.isEmpty)
    #expect(store.includesSourceInBundle)
}

@MainActor
@Test
func relaunchRecoversARecordingThatFinishedBeforeTheHandoff() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(
        at: root,
        withIntermediateDirectories: true
    )
    let recording = root.appendingPathComponent("TAPE-recovered.mov")
    try Data("recording".utf8).write(to: recording)

    let suiteName = UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.set(recording.path, forKey: "pendingRecordingPath")

    let store = AppTapeStore(outputRoot: root, userDefaults: defaults)

    #expect(store.sourceURL == recording)
    #expect(store.title == "TAPE-recovered")
    #expect(store.summary.isEmpty)
    #expect(store.notes.isEmpty)
    #expect(store.successMessage == "Recovered your last recording.")
    #expect(defaults.string(forKey: "pendingRecordingPath") == nil)
}

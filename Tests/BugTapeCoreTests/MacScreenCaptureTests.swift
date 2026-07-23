import Foundation
import Testing
@testable import BugTapeCore

@Test
func screenCaptureUsesAppleToolbarAudioAndClickIndicators() {
    let outputURL = URL(fileURLWithPath: "/tmp/qa-session.mov")
    let command = MacScreenCaptureCommand(outputURL: outputURL)

    #expect(command.executableURL.path == "/usr/sbin/screencapture")
    #expect(command.arguments == ["-v", "-U", "-k", "-g", "/tmp/qa-session.mov"])
}

@Test
func screenCaptureCanDisableMicrophoneAudio() {
    let outputURL = URL(fileURLWithPath: "/tmp/qa-session.mov")
    let command = MacScreenCaptureCommand(
        outputURL: outputURL,
        includesAudio: false
    )

    #expect(command.arguments == ["-v", "-U", "-k", "/tmp/qa-session.mov"])
}

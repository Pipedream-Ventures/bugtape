import Foundation
import Testing
@testable import BugTapeCore

@Test func reportKeepsEvidenceAndExpectationDistinct() {
    let observation = Observation(
        startSeconds: 8,
        endSeconds: nil,
        kind: "note",
        label: "expected",
        text: "Dashboard should appear."
    )
    let manifest = BugTapeManifest(
        title: "Login QA",
        source: SourceMedia(
            originalFilename: "login.mp4",
            relativePath: "source/login.mp4"
        ),
        video: VideoMetadata(
            durationSeconds: 20,
            width: 1_290,
            height: 2_796,
            hasAudio: true,
            fileSizeBytes: 1_024
        ),
        environment: EnvironmentMetadata(
            hostName: "Mac",
            macOSVersion: "macOS",
            simulatorName: "iPhone",
            simulatorUDID: "ABC",
            simulatorRuntime: "iOS-26-0"
        ),
        observations: [observation],
        frames: [
            EvidenceFrame(
                timestampSeconds: 8,
                relativePath: "frames/frame-0008.000.jpg"
            )
        ]
    )

    let report = ReportRenderer.markdown(for: manifest)
    #expect(report.contains("**[EXPECTED]**"))
    #expect(report.contains("Human notes and captured media are evidence"))
    #expect(report.contains("![Evidence at 00:08.000]"))
    #expect(report.contains("Fix only confirmed issues"))
}

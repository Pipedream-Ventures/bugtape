import Foundation
import Testing
@testable import BugTapeCore

@Test func parsesTimestampVariants() {
    #expect(Timestamp.parse("8.5") == 8.5)
    #expect(Timestamp.parse("01:08,250") == 68.25)
    #expect(Timestamp.parse("01:02:03.500") == 3_723.5)
    #expect(Timestamp.parse("wat") == nil)
}

@Test func formatsTimestamp() {
    #expect(Timestamp.format(8.5) == "00:08.500")
    #expect(Timestamp.format(3_723.5) == "01:02:03.500")
}

@Test func parsesTimestampedNotes() throws {
    let contents = """
    # QA pass
    00:08 blocker Sign in does nothing
    00:14 expected Dashboard should appear
    """
    let observations = try NotesParser.parse(contents)

    #expect(observations.count == 2)
    #expect(observations[0].startSeconds == 8)
    #expect(observations[0].label == "blocker")
    #expect(observations[0].text == "Sign in does nothing")
}

@Test func rejectsUntimedNotes() {
    #expect(throws: ParserError.self) {
        try NotesParser.parse("later bug Something broke")
    }
}

@Test func parsesSRTTranscript() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
    )
    defer {
        try? FileManager.default.removeItem(at: directory)
    }

    let url = directory.appendingPathComponent("sample.srt")
    let contents = """
    1
    00:00:01,000 --> 00:00:03,500
    The button is <i>crooked</i>.

    2
    00:00:04,000 --> 00:00:05,000
    It should align.
    """
    try contents.write(to: url, atomically: true, encoding: .utf8)
    let observations = try TranscriptParser.parse(url: url)

    #expect(observations.count == 2)
    #expect(observations[0].startSeconds == 1)
    #expect(observations[0].endSeconds == 3.5)
    #expect(observations[0].text == "The button is crooked.")
}

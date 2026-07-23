import Foundation

public struct MacScreenCaptureCommand: Equatable, Sendable {
    public let executableURL: URL
    public let arguments: [String]

    public init(outputURL: URL, includesAudio: Bool = true) {
        executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")

        var arguments = [
            "-v",
            "-U",
            "-k"
        ]
        if includesAudio {
            arguments.append("-g")
        }
        arguments.append(outputURL.path)
        self.arguments = arguments
    }
}

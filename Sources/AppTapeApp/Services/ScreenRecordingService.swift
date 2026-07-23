import BugTapeCore
import Foundation

enum ScreenRecordingError: LocalizedError {
    case cancelled
    case failed(Int32, String?)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "The recording was cancelled before a file was created."
        case .failed(let status, let detail):
            if let detail, !detail.isEmpty {
                return "Screen recording failed: \(detail)"
            }
            return "Screen recording failed with status \(status)."
        }
    }
}

actor ScreenRecordingService {
    private var process: Process?

    func record(to outputURL: URL, includesAudio: Bool) async throws -> URL {
        let command = MacScreenCaptureCommand(
            outputURL: outputURL,
            includesAudio: includesAudio
        )
        let process = Process()
        process.executableURL = command.executableURL
        process.arguments = command.arguments
        process.standardOutput = FileHandle.nullDevice
        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        self.process = process

        let status = await withCheckedContinuation { continuation in
            process.terminationHandler = { finishedProcess in
                continuation.resume(returning: finishedProcess.terminationStatus)
            }
        }
        self.process = nil

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorDetail = String(data: errorData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard status == 0 || FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ScreenRecordingError.failed(status, errorDetail)
        }
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ScreenRecordingError.cancelled
        }
        return outputURL
    }

    func stop() {
        guard let process, process.isRunning else {
            return
        }
        process.interrupt()
    }
}

import BugTapeCore
import Foundation

enum ScreenRecordingError: LocalizedError {
    case cancelled
    case failed(Int32)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "The recording was cancelled before a file was created."
        case .failed(let status):
            return "Apple's screen recorder exited with status \(status)."
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
        process.standardError = FileHandle.nullDevice

        try process.run()
        self.process = process

        let status = await withCheckedContinuation { continuation in
            process.terminationHandler = { finishedProcess in
                continuation.resume(returning: finishedProcess.terminationStatus)
            }
        }
        self.process = nil

        guard status == 0 || FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ScreenRecordingError.failed(status)
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

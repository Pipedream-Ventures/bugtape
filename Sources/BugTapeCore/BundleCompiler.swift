import Foundation

public struct BundleRequest: Sendable {
    public let videoURL: URL
    public let outputURL: URL
    public let title: String
    public let transcriptURL: URL?
    public let notesURL: URL?
    public let frameIntervalSeconds: Double?

    public init(
        videoURL: URL,
        outputURL: URL,
        title: String,
        transcriptURL: URL?,
        notesURL: URL?,
        frameIntervalSeconds: Double?
    ) {
        self.videoURL = videoURL
        self.outputURL = outputURL
        self.title = title
        self.transcriptURL = transcriptURL
        self.notesURL = notesURL
        self.frameIntervalSeconds = frameIntervalSeconds
    }
}

public enum BundleCompilerError: LocalizedError {
    case outputAlreadyExists(URL)
    case missingInput(URL)

    public var errorDescription: String? {
        switch self {
        case .outputAlreadyExists(let url):
            return "Output already exists: \(url.path)"
        case .missingInput(let url):
            return "Input file does not exist: \(url.path)"
        }
    }
}

public enum BundleCompiler {
    public static func compile(_ request: BundleRequest) async throws -> BugTapeManifest {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: request.videoURL.path) else {
            throw BundleCompilerError.missingInput(request.videoURL)
        }
        guard !fileManager.fileExists(atPath: request.outputURL.path) else {
            throw BundleCompilerError.outputAlreadyExists(request.outputURL)
        }

        let metadata = try await MediaInspector.inspect(url: request.videoURL)
        var observations: [Observation] = []

        if let transcriptURL = request.transcriptURL {
            observations.append(contentsOf: try TranscriptParser.parse(url: transcriptURL))
        }

        if let notesURL = request.notesURL {
            guard let notes = try? String(contentsOf: notesURL, encoding: .utf8) else {
                throw ParserError.unreadableFile(notesURL)
            }
            observations.append(contentsOf: try NotesParser.parse(notes))
        }

        observations.sort {
            ($0.startSeconds ?? Double.greatestFiniteMagnitude)
                < ($1.startSeconds ?? Double.greatestFiniteMagnitude)
        }

        try fileManager.createDirectory(
            at: request.outputURL,
            withIntermediateDirectories: true
        )

        do {
            let sourceDirectory = request.outputURL.appendingPathComponent("source")
            try fileManager.createDirectory(
                at: sourceDirectory,
                withIntermediateDirectories: true
            )
            let copiedVideoURL = sourceDirectory.appendingPathComponent(
                request.videoURL.lastPathComponent
            )
            try fileManager.copyItem(at: request.videoURL, to: copiedVideoURL)

            var timestamps = observations.compactMap(\.startSeconds)
            if let interval = request.frameIntervalSeconds, interval > 0 {
                var timestamp = 0.0
                while timestamp < metadata.durationSeconds && timestamps.count < 100 {
                    timestamps.append(timestamp)
                    timestamp += interval
                }
            }
            if timestamps.isEmpty {
                timestamps = [0]
            }

            timestamps = timestamps.filter { $0 <= metadata.durationSeconds }
            let frames = try await MediaInspector.extractFrames(
                videoURL: request.videoURL,
                timestamps: timestamps,
                outputDirectory: request.outputURL.appendingPathComponent("frames")
            )

            let manifest = BugTapeManifest(
                title: request.title,
                source: SourceMedia(
                    originalFilename: request.videoURL.lastPathComponent,
                    relativePath: "source/\(request.videoURL.lastPathComponent)"
                ),
                video: metadata,
                environment: EnvironmentProbe.current(),
                observations: observations,
                frames: frames
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            encoder.dateEncodingStrategy = .iso8601
            let manifestData = try encoder.encode(manifest)
            try manifestData.write(
                to: request.outputURL.appendingPathComponent("manifest.json"),
                options: .atomic
            )

            let report = ReportRenderer.markdown(for: manifest)
            try report.write(
                to: request.outputURL.appendingPathComponent("report.md"),
                atomically: true,
                encoding: .utf8
            )

            return manifest
        } catch {
            try? fileManager.removeItem(at: request.outputURL)
            throw error
        }
    }
}

import Foundation

public struct VideoMetadata: Codable, Equatable, Sendable {
    public let durationSeconds: Double
    public let width: Int
    public let height: Int
    public let hasAudio: Bool
    public let fileSizeBytes: Int64

    public init(
        durationSeconds: Double,
        width: Int,
        height: Int,
        hasAudio: Bool,
        fileSizeBytes: Int64
    ) {
        self.durationSeconds = durationSeconds
        self.width = width
        self.height = height
        self.hasAudio = hasAudio
        self.fileSizeBytes = fileSizeBytes
    }
}

public struct EnvironmentMetadata: Codable, Equatable, Sendable {
    public let hostName: String
    public let macOSVersion: String
    public let simulatorName: String?
    public let simulatorUDID: String?
    public let simulatorRuntime: String?

    public init(
        hostName: String,
        macOSVersion: String,
        simulatorName: String?,
        simulatorUDID: String?,
        simulatorRuntime: String?
    ) {
        self.hostName = hostName
        self.macOSVersion = macOSVersion
        self.simulatorName = simulatorName
        self.simulatorUDID = simulatorUDID
        self.simulatorRuntime = simulatorRuntime
    }
}

public struct Observation: Codable, Equatable, Sendable {
    public let id: UUID
    public let startSeconds: Double?
    public let endSeconds: Double?
    public let kind: String
    public let label: String?
    public let text: String

    public init(
        id: UUID = UUID(),
        startSeconds: Double?,
        endSeconds: Double?,
        kind: String,
        label: String?,
        text: String
    ) {
        self.id = id
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
        self.kind = kind
        self.label = label
        self.text = text
    }
}

public struct EvidenceFrame: Codable, Equatable, Sendable {
    public let timestampSeconds: Double
    public let relativePath: String

    public init(timestampSeconds: Double, relativePath: String) {
        self.timestampSeconds = timestampSeconds
        self.relativePath = relativePath
    }
}

public struct SourceMedia: Codable, Equatable, Sendable {
    public let originalFilename: String
    public let relativePath: String?
    public let isBundled: Bool

    public init(
        originalFilename: String,
        relativePath: String?,
        isBundled: Bool = true
    ) {
        self.originalFilename = originalFilename
        self.relativePath = relativePath
        self.isBundled = isBundled
    }
}

public struct BugTapeManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let id: UUID
    public let title: String
    public let summary: String?
    public let createdAt: Date
    public let source: SourceMedia
    public let video: VideoMetadata
    public let environment: EnvironmentMetadata
    public let observations: [Observation]
    public let frames: [EvidenceFrame]

    public init(
        schemaVersion: Int = 3,
        id: UUID = UUID(),
        title: String,
        summary: String? = nil,
        createdAt: Date = Date(),
        source: SourceMedia,
        video: VideoMetadata,
        environment: EnvironmentMetadata,
        observations: [Observation],
        frames: [EvidenceFrame]
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.title = title
        self.summary = summary
        self.createdAt = createdAt
        self.source = source
        self.video = video
        self.environment = environment
        self.observations = observations
        self.frames = frames
    }
}

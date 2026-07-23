import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum MediaError: LocalizedError {
    case missingVideoTrack
    case couldNotCreateImage

    public var errorDescription: String? {
        switch self {
        case .missingVideoTrack:
            return "The recording does not contain a readable video track."
        case .couldNotCreateImage:
            return "Could not encode an evidence frame."
        }
    }
}

public enum MediaInspector {
    public static func inspect(url: URL) async throws -> VideoMetadata {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw MediaError.missingVideoTrack
        }

        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let transformedSize = naturalSize.applying(preferredTransform)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])

        return VideoMetadata(
            durationSeconds: max(0, duration.seconds),
            width: Int(abs(transformedSize.width).rounded()),
            height: Int(abs(transformedSize.height).rounded()),
            hasAudio: !audioTracks.isEmpty,
            fileSizeBytes: Int64(resourceValues.fileSize ?? 0)
        )
    }

    public static func extractFrames(
        videoURL: URL,
        timestamps: [Double],
        outputDirectory: URL
    ) async throws -> [EvidenceFrame] {
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.15, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.15, preferredTimescale: 600)

        let uniqueTimes = Array(Set(timestamps.map { max(0, $0) })).sorted()
        var frames: [EvidenceFrame] = []

        for timestamp in uniqueTimes {
            let requestedTime = CMTime(seconds: timestamp, preferredTimescale: 600)
            let image = try await generateImage(
                with: generator,
                at: requestedTime
            )

            let filename = String(format: "frame-%08.3f.jpg", timestamp)
            let destinationURL = outputDirectory.appendingPathComponent(filename)
            try writeJPEG(image, to: destinationURL)
            frames.append(
                EvidenceFrame(
                    timestampSeconds: timestamp,
                    relativePath: "frames/\(filename)"
                )
            )
        }

        return frames
    }

    private static func generateImage(
        with generator: AVAssetImageGenerator,
        at time: CMTime
    ) async throws -> CGImage {
        try await withCheckedThrowingContinuation { continuation in
            generator.generateCGImageAsynchronously(for: time) { image, _, error in
                if let image {
                    continuation.resume(returning: image)
                    return
                }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(throwing: MediaError.couldNotCreateImage)
            }
        }
    }

    private static func writeJPEG(_ image: CGImage, to url: URL) throws {
        guard
            let destination = CGImageDestinationCreateWithURL(
                url as CFURL,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else {
            throw MediaError.couldNotCreateImage
        }

        let properties = [
            kCGImageDestinationLossyCompressionQuality: 0.82
        ] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else {
            throw MediaError.couldNotCreateImage
        }
    }
}

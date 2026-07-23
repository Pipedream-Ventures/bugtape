import Foundation

public enum ReportRenderer {
    public static func markdown(for manifest: BugTapeManifest) -> String {
        var lines: [String] = [
            "# \(manifest.title)",
            "",
            "> AppTape evidence bundle. Human notes and captured media are evidence;",
            "> expected behavior and causes still require verification.",
            "",
            "## Recording",
            "",
            sourceLine(for: manifest.source),
            "- Duration: \(Timestamp.format(manifest.video.durationSeconds))",
            "- Dimensions: \(manifest.video.width) × \(manifest.video.height)",
            "- Audio: \(manifest.video.hasAudio ? "yes" : "no")",
            "- Bundle schema: \(manifest.schemaVersion)",
            "",
            "## Environment",
            "",
            "- Host: \(manifest.environment.hostName)",
            "- macOS: \(manifest.environment.macOSVersion)"
        ]

        if let simulatorName = manifest.environment.simulatorName {
            lines.append("- Simulator: \(simulatorName)")
        }
        if let simulatorRuntime = manifest.environment.simulatorRuntime {
            lines.append("- Runtime: `\(simulatorRuntime)`")
        }
        if let simulatorUDID = manifest.environment.simulatorUDID {
            lines.append("- Simulator UDID: `\(simulatorUDID)`")
        }

        lines.append(contentsOf: ["", "## Timeline", ""])

        if manifest.observations.isEmpty {
            lines.append("_No notes or transcript were supplied._")
        } else {
            let framesByMillisecond = Dictionary(
                uniqueKeysWithValues: manifest.frames.map {
                    (Int(($0.timestampSeconds * 1_000).rounded()), $0)
                }
            )

            for observation in manifest.observations {
                let timestamp: String
                if let start = observation.startSeconds {
                    timestamp = "`\(Timestamp.format(start))`"
                } else {
                    timestamp = "`untimed`"
                }

                let label = observation.label.map { " **[\($0.uppercased())]**" } ?? ""
                lines.append("### \(timestamp)\(label)")
                lines.append("")
                lines.append(observation.text)

                if
                    let start = observation.startSeconds,
                    let frame = framesByMillisecond[Int((start * 1_000).rounded())]
                {
                    lines.append("")
                    lines.append("![Evidence at \(Timestamp.format(start))](\(frame.relativePath))")
                }
                lines.append("")
            }
        }

        lines.append(contentsOf: [
            "## Agent handoff",
            "",
            "1. Inspect the source video and linked evidence at each timestamp.",
            "2. Reproduce observations against the current build.",
            "3. Keep confirmed behavior, human expectations, and inferred causes separate.",
            "4. Fix only confirmed issues and report anything that could not be reproduced.",
            ""
        ])

        return lines.joined(separator: "\n")
    }

    private static func sourceLine(for source: SourceMedia) -> String {
        guard let relativePath = source.relativePath, source.isBundled else {
            return "- Source: `\(source.originalFilename)` (referenced, not bundled)"
        }
        return "- Source: [`\(source.originalFilename)`](\(relativePath))"
    }
}

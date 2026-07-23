import Foundation

public enum ParserError: LocalizedError {
    case unreadableFile(URL)
    case invalidNotesLine(Int, String)

    public var errorDescription: String? {
        switch self {
        case .unreadableFile(let url):
            return "Could not read \(url.path)."
        case .invalidNotesLine(let line, let value):
            return "Invalid notes line \(line): \(value)"
        }
    }
}

public enum NotesParser {
    public static func parse(_ contents: String) throws -> [Observation] {
        var observations: [Observation] = []

        for (index, rawLine) in contents.components(separatedBy: .newlines).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }

            let parts = line.split(maxSplits: 2, whereSeparator: { $0.isWhitespace })
            guard parts.count >= 2, let startSeconds = Timestamp.parse(String(parts[0])) else {
                throw ParserError.invalidNotesLine(index + 1, line)
            }

            let label: String?
            let text: String
            if parts.count == 2 {
                label = nil
                text = String(parts[1])
            } else {
                label = String(parts[1]).lowercased()
                text = String(parts[2])
            }

            observations.append(
                Observation(
                    startSeconds: startSeconds,
                    endSeconds: nil,
                    kind: "note",
                    label: label,
                    text: text
                )
            )
        }

        return observations
    }
}

public enum TranscriptParser {
    public static func parse(url: URL) throws -> [Observation] {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            throw ParserError.unreadableFile(url)
        }

        switch url.pathExtension.lowercased() {
        case "srt":
            return parseTimed(contents, separator: " --> ")
        case "vtt":
            return parseTimed(contents, separator: " --> ")
        default:
            let text = contents.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty {
                return []
            }
            return [
                Observation(
                    startSeconds: nil,
                    endSeconds: nil,
                    kind: "transcriptDocument",
                    label: nil,
                    text: text
                )
            ]
        }
    }

    private static func parseTimed(_ contents: String, separator: String) -> [Observation] {
        let normalized = contents
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let blocks = normalized.components(separatedBy: "\n\n")
        var observations: [Observation] = []

        for block in blocks {
            let lines = block.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0 != "WEBVTT" }

            guard let timingIndex = lines.firstIndex(where: { $0.contains(separator) }) else {
                continue
            }

            let timingParts = lines[timingIndex].components(separatedBy: separator)
            guard timingParts.count == 2 else {
                continue
            }

            let rawEnd = timingParts[1].split(separator: " ").first.map(String.init) ?? ""
            guard
                let start = Timestamp.parse(timingParts[0]),
                let end = Timestamp.parse(rawEnd)
            else {
                continue
            }

            let text = lines.dropFirst(timingIndex + 1).joined(separator: " ")
            if text.isEmpty {
                continue
            }

            observations.append(
                Observation(
                    startSeconds: start,
                    endSeconds: end,
                    kind: "transcript",
                    label: nil,
                    text: stripMarkup(text)
                )
            )
        }

        return observations
    }

    private static func stripMarkup(_ text: String) -> String {
        text.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
    }
}

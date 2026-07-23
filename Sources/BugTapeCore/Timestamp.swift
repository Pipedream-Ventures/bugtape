import Foundation

public enum Timestamp {
    public static func parse(_ rawValue: String) -> Double? {
        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        let components = normalized.split(separator: ":")
        guard !components.isEmpty, components.count <= 3 else {
            return nil
        }

        let values = components.compactMap { Double($0) }
        guard values.count == components.count else {
            return nil
        }

        if values.contains(where: { $0 < 0 }) {
            return nil
        }

        switch values.count {
        case 1:
            return values[0]
        case 2:
            return values[0] * 60 + values[1]
        case 3:
            return values[0] * 3_600 + values[1] * 60 + values[2]
        default:
            return nil
        }
    }

    public static func format(_ seconds: Double) -> String {
        let clampedSeconds = max(0, seconds)
        let totalMilliseconds = Int((clampedSeconds * 1_000).rounded())
        let hours = totalMilliseconds / 3_600_000
        let minutes = (totalMilliseconds % 3_600_000) / 60_000
        let wholeSeconds = (totalMilliseconds % 60_000) / 1_000
        let milliseconds = totalMilliseconds % 1_000

        if hours > 0 {
            return String(
                format: "%02d:%02d:%02d.%03d",
                hours,
                minutes,
                wholeSeconds,
                milliseconds
            )
        }

        return String(
            format: "%02d:%02d.%03d",
            minutes,
            wholeSeconds,
            milliseconds
        )
    }
}

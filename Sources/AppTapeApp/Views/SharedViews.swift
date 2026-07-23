import AVKit
import BugTapeCore
import SwiftUI

enum AppTapeStyle {
    static let ink = Color.black
    static let paper = Color(red: 0.965, green: 0.955, blue: 0.92)
    static let signal = Color(red: 0.88, green: 1.0, blue: 0.16)
    static let live = Color(red: 1.0, green: 0.20, blue: 0.16)
}

enum AppTapeFormat {
    static func timestamp(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

struct SectionHeader: View {
    var eyebrow: String? = nil
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let eyebrow {
                Text(eyebrow)
                    .font(.system(.caption2, design: .monospaced).weight(.black))
                    .tracking(1.6)
                    .foregroundStyle(AppTapeStyle.ink.opacity(0.55))
            }
            Text(title)
                .font(.title2.weight(.black))
            Text(detail)
                .foregroundStyle(AppTapeStyle.ink.opacity(0.58))
        }
    }
}

struct CaptureStatusBadge: View {
    let symbol: String
    let label: String
    let status: CaptureReadiness

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
            Text(label)
            Text(status.label)
                .foregroundStyle(statusColor)
        }
        .font(.system(.caption2, design: .monospaced).weight(.black))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 3)
                .stroke(AppTapeStyle.ink, lineWidth: 1)
        }
    }

    private var statusColor: Color {
        switch status {
        case .ready:
            return AppTapeStyle.ink
        case .willPrompt:
            return Color.orange
        case .blocked:
            return AppTapeStyle.live
        case .off:
            return Color.secondary
        }
    }
}

struct VideoPreview: View {
    let url: URL
    @State private var player: AVPlayer

    init(url: URL) {
        self.url = url
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VideoPlayer(player: player)
            .onDisappear {
                player.pause()
            }
    }
}

struct StatusMessages: View {
    @ObservedObject var store: AppTapeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if store.isRecording {
                Label(
                    "Apple’s recording toolbar is open. Start the recording, test Paco, then stop from the menu bar.",
                    systemImage: "record.circle"
                )
                .foregroundStyle(AppTapeStyle.live)
            }
            if let successMessage = store.successMessage {
                Label(successMessage, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            if let errorMessage = store.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
        .font(.subheadline)
    }
}

struct Metric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
        }
    }
}

extension View {
    func appTapeCard() -> some View {
        padding(18)
            .background(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(AppTapeStyle.ink, lineWidth: 1)
            }
    }
}

extension VideoMetadata {
    var durationText: String {
        AppTapeFormat.timestamp(durationSeconds)
    }

    var summary: String {
        let size = ByteCountFormatter.string(
            fromByteCount: fileSizeBytes,
            countStyle: .file
        )
        return "\(durationText) · \(width)×\(height) · \(size) · \(hasAudio ? "audio" : "no audio")"
    }
}

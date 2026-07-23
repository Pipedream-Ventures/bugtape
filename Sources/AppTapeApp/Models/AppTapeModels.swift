import BugTapeCore
import Foundation

enum AppTapeSelection: Hashable {
    case capture
    case bundle(URL)
}

enum CaptureReadiness {
    case ready
    case willPrompt
    case blocked
    case off

    var label: String {
        switch self {
        case .ready:
            return "READY"
        case .willPrompt:
            return "WILL PROMPT"
        case .blocked:
            return "BLOCKED"
        case .off:
            return "OFF"
        }
    }
}

struct AppTapeBundleRecord: Identifiable, Hashable {
    let url: URL
    let manifest: BugTapeManifest

    var id: URL { url }
    var title: String { manifest.title }
    var createdAt: Date { manifest.createdAt }
    var reportURL: URL { url.appendingPathComponent("report.md") }

    static func == (lhs: AppTapeBundleRecord, rhs: AppTapeBundleRecord) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}

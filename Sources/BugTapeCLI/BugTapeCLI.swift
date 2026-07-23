import BugTapeCore
import Foundation

@main
struct BugTapeCLI {
    static func main() async {
        do {
            try await run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(
                Data("error: \(error.localizedDescription)\n".utf8)
            )
            Foundation.exit(EXIT_FAILURE)
        }
    }

    private static func run(arguments: [String]) async throws {
        guard let command = arguments.first else {
            printHelp()
            return
        }

        switch command {
        case "help", "--help", "-h":
            printHelp()
        case "inspect":
            try await inspect(arguments: Array(arguments.dropFirst()))
        case "bundle":
            try await bundle(arguments: Array(arguments.dropFirst()))
        case "record":
            try record(arguments: Array(arguments.dropFirst()))
        default:
            throw CLIError.unknownCommand(command)
        }
    }

    private static func inspect(arguments: [String]) async throws {
        guard let path = arguments.first else {
            throw CLIError.missingArgument("video")
        }
        let metadata = try await MediaInspector.inspect(
            url: URL(fileURLWithPath: path).standardizedFileURL
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(metadata)
        print(String(decoding: data, as: UTF8.self))
    }

    private static func bundle(arguments: [String]) async throws {
        guard let videoPath = arguments.first, !videoPath.hasPrefix("--") else {
            throw CLIError.missingArgument("video")
        }

        let options = try Options.parse(Array(arguments.dropFirst()))
        guard let outputPath = options.value(for: "--output") else {
            throw CLIError.missingOption("--output")
        }

        let videoURL = URL(fileURLWithPath: videoPath).standardizedFileURL
        let defaultTitle = videoURL.deletingPathExtension().lastPathComponent
        let interval = options.value(for: "--frame-interval").flatMap(Double.init)

        let request = BundleRequest(
            videoURL: videoURL,
            outputURL: URL(fileURLWithPath: outputPath).standardizedFileURL,
            title: options.value(for: "--title") ?? defaultTitle,
            transcriptURL: options.url(for: "--transcript"),
            notesURL: options.url(for: "--notes"),
            frameIntervalSeconds: interval
        )
        let manifest = try await BundleCompiler.compile(request)
        print("Created \(request.outputURL.path)")
        print(
            "\(manifest.observations.count) observations, "
                + "\(manifest.frames.count) evidence frames"
        )
    }

    private static func record(arguments: [String]) throws {
        guard let outputPath = arguments.first else {
            throw CLIError.missingArgument("output video")
        }

        let outputURL = URL(fileURLWithPath: outputPath).standardizedFileURL
        guard !FileManager.default.fileExists(atPath: outputURL.path) else {
            throw CLIError.outputExists(outputURL)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "simctl",
            "io",
            "booted",
            "recordVideo",
            "--codec=h264",
            "--force",
            outputURL.path
        ]
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        print("Recording the booted Simulator to \(outputURL.path)")
        print("Press Control-C to stop.")
        try process.run()

        signal(SIGINT, SIG_IGN)
        let signalSource = DispatchSource.makeSignalSource(signal: SIGINT)
        signalSource.setEventHandler {
            process.interrupt()
        }
        signalSource.resume()
        process.waitUntilExit()
        signalSource.cancel()

        guard process.terminationStatus == 0 || process.terminationReason == .uncaughtSignal else {
            throw CLIError.processFailed(process.terminationStatus)
        }
        print("Saved \(outputURL.path)")
    }

    private static func printHelp() {
        print(
            """
            BugTape — narrated iOS QA into agent-readable evidence

            USAGE
              bugtape record <output.mp4>
              bugtape inspect <video>
              bugtape bundle <video> --output <directory> [options]

            BUNDLE OPTIONS
              --title <text>             Session title
              --transcript <file>        SRT, VTT, or plain text transcript
              --notes <file>             Timestamped QA notes
              --frame-interval <seconds> Also extract frames on an interval

            NOTES FORMAT
              00:08 blocker Sign in does nothing
              00:14 expected Dashboard should appear
            """
        )
    }
}

private enum CLIError: LocalizedError {
    case unknownCommand(String)
    case missingArgument(String)
    case missingOption(String)
    case missingOptionValue(String)
    case outputExists(URL)
    case processFailed(Int32)

    var errorDescription: String? {
        switch self {
        case .unknownCommand(let command):
            return "Unknown command '\(command)'. Run 'bugtape help'."
        case .missingArgument(let name):
            return "Missing required \(name) argument."
        case .missingOption(let option):
            return "Missing required option \(option)."
        case .missingOptionValue(let option):
            return "Missing value for \(option)."
        case .outputExists(let url):
            return "Output already exists: \(url.path)"
        case .processFailed(let status):
            return "simctl exited with status \(status)."
        }
    }
}

private struct Options {
    let values: [String: String]

    static func parse(_ arguments: [String]) throws -> Options {
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let option = arguments[index]
            guard option.hasPrefix("--") else {
                throw CLIError.unknownCommand(option)
            }
            let valueIndex = index + 1
            guard valueIndex < arguments.count else {
                throw CLIError.missingOptionValue(option)
            }
            values[option] = arguments[valueIndex]
            index += 2
        }
        return Options(values: values)
    }

    func value(for key: String) -> String? {
        values[key]
    }

    func url(for key: String) -> URL? {
        guard let value = values[key] else {
            return nil
        }
        return URL(fileURLWithPath: value).standardizedFileURL
    }
}

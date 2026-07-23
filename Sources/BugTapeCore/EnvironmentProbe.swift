import Foundation

public enum EnvironmentProbe {
    public static func current() -> EnvironmentMetadata {
        let processInfo = ProcessInfo.processInfo
        let simulator = bootedSimulator()

        return EnvironmentMetadata(
            hostName: processInfo.hostName,
            macOSVersion: processInfo.operatingSystemVersionString,
            simulatorName: simulator?.name,
            simulatorUDID: simulator?.udid,
            simulatorRuntime: simulator?.runtime
        )
    }

    private static func bootedSimulator() -> SimulatorContext? {
        guard
            let data = run(
                executable: "/usr/bin/xcrun",
                arguments: ["simctl", "list", "devices", "booted", "--json"]
            ),
            let result = try? JSONDecoder().decode(SimctlDeviceList.self, from: data)
        else {
            return nil
        }

        for (runtime, devices) in result.devices {
            if let device = devices.first(where: { $0.state == "Booted" }) {
                return SimulatorContext(
                    name: device.name,
                    udid: device.udid,
                    runtime: runtime
                )
            }
        }

        return nil
    }

    private static func run(executable: String, arguments: [String]) -> Data? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                return nil
            }
            return pipe.fileHandleForReading.readDataToEndOfFile()
        } catch {
            return nil
        }
    }
}

private struct SimctlDeviceList: Decodable {
    let devices: [String: [SimctlDevice]]
}

private struct SimctlDevice: Decodable {
    let name: String
    let udid: String
    let state: String
}

private struct SimulatorContext {
    let name: String
    let udid: String
    let runtime: String
}

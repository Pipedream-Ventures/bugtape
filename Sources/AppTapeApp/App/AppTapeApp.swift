import AppKit
import SwiftUI

@main
struct AppTapeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppTapeStore()

    var body: some Scene {
        WindowGroup("TAPE", id: "main") {
            ContentView(store: store)
                .frame(minWidth: 980, minHeight: 680)
        }
        .defaultSize(width: 1180, height: 780)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tape") {
                    store.startNewTape()
                }
                .keyboardShortcut("n")

                Button("Import Recording…") {
                    Task {
                        await store.importRecording()
                    }
                }
                .keyboardShortcut("o")
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

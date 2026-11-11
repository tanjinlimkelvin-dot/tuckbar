import AppKit
import Carbon

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let bar = MenuBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let path = ProcessInfo.processInfo.environment["TUCKBAR_SNAPSHOT"] {
            // Render the welcome window without touching the real menu bar, then quit.
            Onboarding.show(bar: bar)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                Onboarding.snapshot(to: path)
                NSApp.terminate(nil)
            }
            return
        }

        bar.setup()

        HotKey.shared.onPress = { [bar] in bar.toggle() }
        HotKey.shared.register(keyCode: UInt32(kVK_ANSI_B), modifiers: UInt32(controlKey | optionKey | cmdKey))

        if !Prefs.onboarded {
            Prefs.onboarded = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [bar] in Onboarding.show(bar: bar) }
        }
    }

    /// Opening Tuckbar again (from Applications or Spotlight) brings the icons back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        bar.show()
        return false
    }
}

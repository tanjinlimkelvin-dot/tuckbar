import AppKit
import Carbon
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let bar = MenuBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        bar.setup()

        HotKey.shared.onPress = { [bar] in bar.toggle() }
        HotKey.shared.register(keyCode: UInt32(kVK_ANSI_B), modifiers: UInt32(controlKey | optionKey | cmdKey))

        if !Prefs.onboarded {
            Prefs.onboarded = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { Onboarding.show(firstRun: true) }
        }
    }

    /// Opening Tuckbar again (from Applications or Spotlight) brings the icons back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        bar.show()
        return false
    }
}

@MainActor
enum Onboarding {
    static func show(firstRun: Bool = false) {
        let a = NSAlert()
        a.messageText = "Tuck away menu bar icons"
        a.informativeText = """
        Tuckbar adds an arrow (‹ ›) and a divider (│) to the right side of your menu bar.

        • Icons to the left of the │ divider are hidden. Click the arrow or press ⌃⌥⌘B to show or hide them.
        • To keep an icon visible, hold ⌘ and drag it to the right of the arrow.
        • To hide an icon, hold ⌘ and drag it to the left of the │ divider.
        • Right-click the arrow for options, like how soon icons hide again.
        """
        if let icon = NSImage(systemSymbolName: "menubar.arrow.up.rectangle", accessibilityDescription: nil) {
            a.icon = icon
        }
        if firstRun {
            a.showsSuppressionButton = true
            a.suppressionButton?.title = "Launch Tuckbar at login"
            a.suppressionButton?.state = .on
        }
        a.addButton(withTitle: "Got It")
        NSApp.activate()
        a.runModal()
        if firstRun, a.suppressionButton?.state == .on {
            try? SMAppService.mainApp.register()
        }
    }
}

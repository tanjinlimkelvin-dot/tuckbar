import AppKit
import ServiceManagement

/// Two status items: an arrow you click and a divider to its left. Hiding stretches the divider
/// so wide that every item to its left is pushed off the screen; showing shrinks it back.
@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private var arrow: NSStatusItem!
    private var divider: NSStatusItem!
    private var autoHideTimer: Timer?
    private(set) var hidden = false

    private let dividerWidth: CGFloat = 12
    private let hiddenDividerWidth: CGFloat = 10_000

    private static let arrowName = "Tuckbar.Arrow"
    private static let dividerName = "Tuckbar.Divider"

    func setup() {
        // On first launch, start at the far right so every existing icon is on the hidden side.
        // macOS stores the position under this key once the user moves an item, so only seed it once.
        let d = UserDefaults.standard
        for (name, position) in [(Self.arrowName, 0), (Self.dividerName, 1)] {
            let key = "NSStatusItem Preferred Position \(name)"
            if d.object(forKey: key) == nil { d.set(position, forKey: key) }
        }

        arrow = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        arrow.autosaveName = Self.arrowName
        divider = NSStatusBar.system.statusItem(withLength: dividerWidth)
        divider.autosaveName = Self.dividerName

        for item in [arrow!, divider!] {
            item.button?.target = self
            item.button?.action = #selector(clicked(_:))
            item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        divider.button?.image = Self.dividerImage
        divider.button?.toolTip = "Icons left of this line get tucked away. ⌘-drag icons across it to choose."
        render()

        if Prefs.hideAtLaunch {
            // Give the menu bar a moment to lay the items out before measuring positions.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.hide() }
        }
    }

    func toggle() {
        hidden ? show() : hide()
    }

    func hide() {
        guard !hidden else { return }
        guard dividerIsLeftOfArrow else {
            // Stretching a divider that sits right of the arrow would push the arrow off-screen too.
            showOrderWarning()
            return
        }
        autoHideTimer?.invalidate()
        divider.length = hiddenDividerWidth
        divider.button?.image = nil
        hidden = true
        render()
    }

    func show() {
        guard hidden else { return }
        divider.length = dividerWidth
        divider.button?.image = Self.dividerImage
        hidden = false
        render()
        scheduleAutoHide()
    }

    private func scheduleAutoHide() {
        autoHideTimer?.invalidate()
        let seconds = Prefs.autoHideSeconds
        guard seconds > 0 else { return }
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { _ in
            MainActor.assumeIsolated { self.hide() }
        }
    }

    private var dividerIsLeftOfArrow: Bool {
        guard let d = divider.button?.window?.frame, let a = arrow.button?.window?.frame else { return true }
        return d.midX < a.midX
    }

    private func render() {
        let symbol = hidden ? "chevron.left" : "chevron.right"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: hidden ? "Show icons" : "Hide icons")
        image?.isTemplate = true
        arrow.button?.image = image
        arrow.button?.toolTip = (hidden ? "Show tucked-away icons" : "Tuck icons away") + " (⌃⌥⌘B). Right-click for options."
    }

    @objc private func clicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu(from: sender == divider.button ? divider : arrow)
        } else {
            toggle()
        }
    }

    // MARK: Menu

    private func showMenu(from item: NSStatusItem) {
        let menu = NSMenu()
        menu.addItem(ActionItem(hidden ? "Show Icons" : "Hide Icons") { self.toggle() })
        menu.addItem(.separator())

        let autoHide = NSMenuItem(title: "Hide Again After", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for (title, seconds) in [("Never", 0), ("5 Seconds", 5), ("10 Seconds", 10), ("30 Seconds", 30), ("1 Minute", 60)] {
            let i = ActionItem(title) {
                Prefs.autoHideSeconds = seconds
                if !self.hidden { self.scheduleAutoHide() }
            }
            i.state = Prefs.autoHideSeconds == seconds ? .on : .off
            sub.addItem(i)
        }
        autoHide.submenu = sub
        menu.addItem(autoHide)

        let atLaunch = ActionItem("Hide Icons at Launch") { Prefs.hideAtLaunch.toggle() }
        atLaunch.state = Prefs.hideAtLaunch ? .on : .off
        menu.addItem(atLaunch)

        let login = ActionItem("Launch at Login") {
            let s = SMAppService.mainApp
            if s.status == .enabled { try? s.unregister() } else { try? s.register() }
        }
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())
        menu.addItem(ActionItem("How to Use…") { Onboarding.show() })
        menu.addItem(ActionItem("Quit Tuckbar", key: "q") { NSApp.terminate(nil) })

        // Attach the menu just for this click so a plain left-click keeps toggling.
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }

    private func showOrderWarning() {
        let a = NSAlert()
        a.messageText = "The divider is on the wrong side"
        a.informativeText = "Tuckbar hides the icons to the left of the │ divider, so the divider must sit left of the arrow. Hold ⌘ and drag it back to the left of the arrow, then try again."
        NSApp.activate()
        a.runModal()
    }

    private static let dividerImage: NSImage = {
        let image = NSImage(size: NSSize(width: 6, height: 16), flipped: false) { _ in
            NSColor.black.withAlphaComponent(0.55).setFill()
            NSBezierPath(roundedRect: NSRect(x: 2, y: 1.5, width: 2, height: 13), xRadius: 1, yRadius: 1).fill()
            return true
        }
        image.isTemplate = true
        return image
    }()
}

/// NSMenuItem that runs a closure.
final class ActionItem: NSMenuItem {
    private let handler: @MainActor () -> Void

    init(_ title: String, key: String = "", handler: @escaping @MainActor () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: key)
        target = self
    }

    required init(coder: NSCoder) { fatalError() }

    @objc private func run() {
        MainActor.assumeIsolated { handler() }
    }
}

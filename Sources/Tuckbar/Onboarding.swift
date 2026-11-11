import AppKit
import ServiceManagement
import SwiftUI

/// The welcome window: an animated picture of how Tuckbar works, the three things to know, and settings.
@MainActor
enum Onboarding {
    private static var window: NSWindow?
    private static let model = OnboardingModel()

    static func show(bar: MenuBarController) {
        // Reveal the real divider so what the window describes is visible in the menu bar too.
        bar.show()
        if window == nil {
            let w = NSWindow(contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView],
                             backing: .buffered, defer: false)
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.isMovableByWindowBackground = true
            w.isReleasedWhenClosed = false
            let host = NSHostingView(rootView: OnboardingView(model: model, bar: bar) { w.close() })
            w.contentView = host
            w.setContentSize(host.fittingSize)
            w.center()
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: w, queue: .main) { _ in
                MainActor.assumeIsolated { model.stopDemo() }
            }
            window = w
        }
        model.refresh()
        model.startDemo()
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    /// Development aid: renders the window to a PNG (TUCKBAR_SNAPSHOT=/path.png).
    static func snapshot(to path: String) {
        guard let view = window?.contentView,
              let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
    }
}

@MainActor
final class OnboardingModel: ObservableObject {
    @Published var demoHidden = false
    @Published var launchAtLogin = false {
        didSet {
            guard launchAtLogin != (SMAppService.mainApp.status == .enabled) else { return }
            let s = SMAppService.mainApp
            do {
                if launchAtLogin { try s.register() } else { try s.unregister() }
            } catch {
                launchAtLogin = s.status == .enabled
            }
        }
    }
    @Published var hideAtLaunch = Prefs.hideAtLaunch { didSet { Prefs.hideAtLaunch = hideAtLaunch } }
    @Published var autoHideSeconds = Prefs.autoHideSeconds { didSet { Prefs.autoHideSeconds = autoHideSeconds } }

    private var demoTimer: Timer?

    func refresh() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
        hideAtLaunch = Prefs.hideAtLaunch
        autoHideSeconds = Prefs.autoHideSeconds
    }

    /// Plays the tuck/untuck animation on a loop until the user clicks the picture themselves.
    func startDemo() {
        stopDemo()
        demoTimer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: true) { _ in
            MainActor.assumeIsolated {
                withAnimation(.spring(duration: 0.5)) { self.demoHidden.toggle() }
            }
        }
    }

    func stopDemo() {
        demoTimer?.invalidate()
        demoTimer = nil
    }
}

struct OnboardingView: View {
    @ObservedObject var model: OnboardingModel
    let bar: MenuBarController
    let close: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            header
            demo
            steps
            options
            HStack {
                Button("Try It in the Menu Bar") { bar.toggle() }
                    .help("Shows or hides your real menu bar icons")
                Spacer()
                Button("Done", action: close)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 36)
        .padding(.bottom, 24)
        .frame(width: 540)
        .background(Color(nsColor: .windowBackgroundColor))
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
            Text("Welcome to Tuckbar")
                .font(.system(size: 24, weight: .bold))
            Text("Keep your menu bar tidy. Tuck away the icons you rarely use, and bring them back with one click.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var demo: some View {
        VStack(spacing: 8) {
            MockMenuBar(hidden: model.demoHidden)
                .onTapGesture {
                    model.stopDemo()
                    withAnimation(.spring(duration: 0.5)) { model.demoHidden.toggle() }
                }
                .help("Click to try it")
            HStack {
                Label("Left of │ — tucked away", systemImage: "eye.slash")
                Spacer()
                Label("Right of › — always visible", systemImage: "eye")
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepRow(number: 1, symbol: "cursorarrow.click.2",
                    title: "Click the arrow to show or hide",
                    detail: Text("Or press \(Text("⌃⌥⌘B").bold()) from anywhere. Shown icons can tuck themselves away again automatically; choose when below."))
            StepRow(number: 2, symbol: "hand.point.up.left",
                    title: "Choose which icons hide",
                    detail: Text("Hold \(Text("⌘").bold()) and drag an icon in the menu bar. Drop it left of the \(Text("│").bold()) divider to hide it, or right of the \(Text("›").bold()) arrow to keep it visible."))
            StepRow(number: 3, symbol: "contextualmenu.and.cursorarrow",
                    title: "Right-click the arrow for options",
                    detail: Text("That menu also reopens this window. Opening Tuckbar from Applications shows all icons too."))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var options: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Launch Tuckbar at login", isOn: $model.launchAtLogin)
                Toggle("Hide icons when Tuckbar starts", isOn: $model.hideAtLaunch)
                Picker("Hide icons again after", selection: $model.autoHideSeconds) {
                    Text("Never").tag(0)
                    Text("5 seconds").tag(5)
                    Text("10 seconds").tag(10)
                    Text("30 seconds").tag(30)
                    Text("1 minute").tag(60)
                }
                .pickerStyle(.menu)
                .fixedSize()
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct StepRow: View {
    let number: Int
    let symbol: String
    let title: String
    let detail: Text

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.15))
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(number). \(title)")
                    .font(.system(size: 14, weight: .semibold))
                detail
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A miniature menu bar: icons left of the divider slide away when "tucked".
private struct MockMenuBar: View {
    let hidden: Bool
    private let tucked = ["cloud.fill", "music.note", "message.fill", "camera.fill", "bolt.fill", "list.clipboard"]
    private let visible = ["wifi", "battery.75percent"]

    var body: some View {
        HStack(spacing: 14) {
            Spacer(minLength: 0)
            if !hidden {
                ForEach(tucked, id: \.self) { icon($0) }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                Capsule()
                    .fill(Color.primary.opacity(0.45))
                    .frame(width: 2, height: 15)
                    .transition(.opacity)
            }
            Image(systemName: hidden ? "chevron.left" : "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor))
            ForEach(visible, id: \.self) { icon($0) }
            Text("9:41")
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 16)
        .frame(height: 38)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        )
        .clipped()
        .contentShape(Rectangle())
    }

    private func icon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 14))
            .frame(width: 18)
    }
}

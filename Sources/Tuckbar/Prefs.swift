import Foundation

/// Settings, persisted to UserDefaults.
enum Prefs {
    private static let d: UserDefaults = {
        UserDefaults.standard.register(defaults: [
            "autoHideSeconds": 10,
            "hideAtLaunch": true,
        ])
        return UserDefaults.standard
    }()

    /// Seconds after showing icons before they're tucked away again. 0 means never.
    static var autoHideSeconds: Int {
        get { d.integer(forKey: "autoHideSeconds") }
        set { d.set(newValue, forKey: "autoHideSeconds") }
    }

    static var hideAtLaunch: Bool {
        get { d.bool(forKey: "hideAtLaunch") }
        set { d.set(newValue, forKey: "hideAtLaunch") }
    }

    static var onboarded: Bool {
        get { d.bool(forKey: "onboarded") }
        set { d.set(newValue, forKey: "onboarded") }
    }
}
